package IPsonar;

use strict;
use warnings;

use version;
our $VERSION;
$VERSION = "0.32";

use Net::SSLeay qw(make_headers get_https);
use URI;
use XML::Simple qw(:strict);
use Data::Dumper;
use MIME::Base64;
use LWP::UserAgent;
use Carp;
use constant {
    HTTPS_TCP_PORT    => 443,
    DEFAULT_PAGE_SIZE => 100,
};

# "IPsonar" and "Lumeta" are both registered marks of the Lumeta Corporation.

=head1 NAME

IPsonar - Wrapper to interact with the Lumeta IPsonar API

=head1 VERSION

Version 0.32
(Mercurial Revision ID: 8cc8c5b56c62+)

=cut

=head1 SYNOPSIS

This module wraps the IPsonar RESTful API.
It handles the paging and https stuff so you can concentrate on extracting
information from reports.

"Lumeta" and "IPsonar" are both registered trademarks of the Lumeta Coporation

=head1 EXAMPLE

    # Script to get all the IP address for all the devices that have
    # port 23 open:

    my $rsn = IPsonar->new('rsn_address_or_name','username','password');
    my $test_report = 23;

    my $results = $rsn->query('detail.devices',
        {
            'q.f.report.id'                 =>  $test_report,
            'q.f.servicediscovery.ports'    =>  23
        }) or die "Problem ".$rsn->error;

    while (my $x = $rsn->next_result) {
       print "IP: $x->{ip}\n";
    }


=head1 CONSTRUCTORS

=cut

#-----------------------------------------------------------
# new(rsn, username, password)

=over 8

=item B<new (rsn, username, password)>

=back

Setup a connection to a report server using username / password 
Note:  This doesn't actually initiate a connection until you issue
a query.  The I<rsn> can either be a hostname or IP address.  The I<username> 
and I<password> are for one of the GUI users.

=cut

sub new {
    my $class    = shift;
    my $rsn      = shift;
    my $username = shift;
    my $password = shift;
    my $self     = {};
    $self->{request} = sub {    #request(query, parameters)
        my $query  = shift;
        my $params = shift;
        _request_using_password( $rsn, $query, $params, $username, $password );
    };
    bless $self, $class;
    return $self;
}

#-----------------------------------------------------------

=over 8

=item B<new_with_cert (rsn, path_to_cert, password)>

=back

Setup a connection to a report server using SSL certificate
Note:  This doesn't actually initiate a connection until you issue
a query.  The I<rsn> can either be a hostname or IP address.  The 
I<password> is the password required to unlock your certificate (as required).

=cut

sub new_with_cert {
    my $class     = shift;
    my $self      = {};
    my $rsn       = shift;
    my $cert_path = shift;
    my $password  = shift;
    $self->{request} = sub {    #request(query, parameters)
        my $query  = shift;
        my $params = shift;
        _request_using_certificate( $rsn, $query, $params, $cert_path,
            $password );
    };
    bless $self, $class;
    return $self;
}

# This function is to allow us to run unit tests without having
# access to a live RSN or the exact same reports I originally tested
# against.  We're reading from a file with pre-canned requests and data.
sub _new_with_file {    # _new_with_file(file)
    my $class = shift;
    my $file  = shift;
    my $self  = {};
    $self->{pages} = {};

    # Fill in $self->{pages}
    open my $testfile, "<", $file or croak "Couldn't open $file";
    my $page = q{};
    my $request;
    while (<$testfile>) {
        if (/^URL: (.*)$/) {
            $self->{pages}->{$request} = $page if $page;
            $request                   = _normalize_path($1);
            $page                      = q{};
        }
        else {
            $page .= $_;
        }
    }
    $self->{pages}->{$request} = $page;

    $self->{request} = sub {    #request(query, parameters)
        my $query  = shift;
        my $params = shift;
        my $path   = _normalize_path( _get_path( $query, $params ) );
        return $self->{pages}->{"$path"}
          || croak "Couldn't find $path in file";
    };
    bless $self, $class;
    return $self;
}

#-----------------------------------------------------------
# Normalize path exists to force the path we're looking for into
# a specific order.  This fixes the issue I ran into at in perl 5.18
# where hash order is now effectively random (which is a generally
# a good thing but causes my code to fail)
#
# /reporting/api/service/detail.devices?q.f.report.id=23&q.f.servicediscovery.ports=2300&fmt=xml&q.pageSize=100&q.page=0 should become
# /reporting/api/service/detail.devices?fmt=xml&q.f.report.id=23&q.f.servicediscovery.ports=2300&q.pageSize=100&q.page=0
sub _normalize_path {
    my $path = shift;
    my ( $start, $rest ) = $path =~ /^(.+)\?(.*)$/;
    my @params = split /&/, $rest;
    return $start . '?' . join( '&', sort(@params) );
}

#-----------------------------------------------------------

=over 8

=item B<new_localhost>

=back

Setup a connection to the report server you're on

=cut

sub new_localhost {
    my $class = shift;
    my $self  = {};
    $self->{request} = sub {    #request(query, parameters)
        my $query  = shift;
        my $params = shift;
        _request_localhost( $query, $params );
    };
    bless $self, $class;
    return $self;
}

#-----------------------------------------------------------

=head1 METHODS

=over 8

=item B<$rsn-E<gt>query ( method, hashref_of_parameters)>

=back

Issue a query (get results for non-paged queries).
If you're getting back paged data we'll return the number of items
available in the query.  If we're getting back a single result we
return a hashref to those results.

If the query fails we'll leave the reason in $rsn->error

=cut

sub query {
    my $self = shift;
    $self->{query}  = shift;
    $self->{params} = shift;

    # Set default parameters (over-riding fmt, it must be XML).
    $self->{params}->{'q.page'} ||= 0;

    if ( !defined( $self->{params}->{'q.pageSize'} ) ) {
        $self->{params}->{'q.pageSize'} = DEFAULT_PAGE_SIZE;
    }

    $self->{params}->{fmt} = 'xml';

    #-----------------------------------------------------------
    # instance variables
    #
    # total     The total number of items we could iterate over
    # request   A funcref to the underlying function that gets
    #           our XML back from the server.  It's a funcref
    #           because it can either be password or PKI authentication
    # query     The API call we're making (e.g. "config.reports"
    # params    The API parameters we're passing
    # error     The XML error we got back from IPsonar (if any)
    # page_size The number of items we expect per page
    # paged     Is the result paged (or are we getting a single value)
    # max_page  Maximum page we'll be able to retrieve
    # max_row   Maximum row on this page (0-n).
    #-----------------------------------------------------------

    my $res = $self->{request}( $self->{query}, $self->{params} );

    # KeyAttr => [] because otherwise XML::Simple tries to be clever
    # and hand back a hashref keyed on "id" or "name" instead of an
    # arrayref of items.
    my $xml = XMLin( $res, KeyAttr => [], ForceArray => [] );

    if ( $xml->{status} ne 'SUCCESS' ) {

        print Dumper($xml) . "\n";
        $self->{error} = $xml->{error}->{detail};
        croak $self->{error};
    }

    $self->{xml}      = $xml;
    $self->{page_row} = 0;

    if ( defined( $xml->{total} ) and $xml->{total} == 0 ) {
        $self->{total} = 0;
        $self->{paged} = 1;
        return $xml;
    }

    if ( $xml->{total} && $self->{params}->{'q.pageSize'} ) {    # Paged Data
        $self->{total} = $xml->{total};
        my $page_size = $self->{params}->{'q.pageSize'};

        # Figure out what the key to the array data is
        my $temp = XMLin( $res, NoAttr => 1, KeyAttr => [], ForceArray => 1 );
        my $key = ( keys %{$temp} )[0];
        $self->{pagedata} = $self->{xml}->{$key};
        warn "Key = $key, Self = " . Dumper($self) if !$self->{xml}->{$key};

        # Setup paging information
        #TODO this is a honking mess, too many special conditions.
        $self->{paged} = 1;
        $self->{max_page} = int( ( $self->{total} - 1 ) / $page_size );

        $self->{max_row} =
            $self->{params}->{'q.page'} < $self->{max_page}
          ? $page_size - 1
          : ( ( $self->{total} % $page_size ) || $page_size ) - 1;

        # There's only one page with $self->{total} items
        if ( $self->{params}->{'q.pageSize'} == $self->{total} ) {
            $self->{max_row} = $self->{total} - 1;
        }

        # We're looking at things with pagesize 1
        if ( $self->{params}->{'q.pageSize'} == 1 ) {
            $self->{max_row} = 0;
        }

        return $self->{total};
    }
    else {    # Not paged data
        $self->{total} = 0;
        $self->{paged} = 0;
        delete( $self->{key} );
        return $xml;
    }
}

#-----------------------------------------------------------

=over 8

=item B<$rsn-E<gt>next_result ()>

=back

Get next paged results as a hashref.  Returns 0 when we've got no more
results.

Note:  Currently, we always return a hashref to the same (only) non-paged
results.

=cut

sub next_result {
    my $self = shift;

    #print "page_row: $self->{page_row}, max_row: $self->{max_row}, ".
    #        "page: $self->{params}->{'q.page'}, max_page: $self->{max_page}\n";

    #No results
    return 0 if $self->{total} == 0 && $self->{paged};

    #Not paged data
    return $self->{xml} if !$self->{paged};

    #End of Data
    if (
        $self->{params}->{'q.page'} == $self->{max_page}
        && (
            $self->{page_row} > $self->{max_row}
            || ( ref( $self->{pagedata} ) eq 'ARRAY'
                && !$self->{pagedata}[ $self->{page_row} ] )
        )
      )
    {
        return;
    }

    #End of Page
    # The pagedata of this test handles cases where IPsonar doesn't
    # return all the rows it's supposed to (rare, but it happens)
    if (
        $self->{page_row} > $self->{max_row}
        || ( ref( $self->{pagedata} ) eq 'ARRAY'
            && !$self->{pagedata}[ $self->{page_row} ] )
      )
    {
        $self->{params}->{'q.page'}++;
        $self->query( $self->{query}, $self->{params} );
    }

    #Single item on last page
    if ( $self->{page_row} == 0 and $self->{max_row} == 0 ) {
        $self->{page_row}++;
        return $self->{pagedata};
    }

    return $self->{pagedata}[ $self->{page_row}++ ];

}

#-----------------------------------------------------------

=over 8

=item B<$rsn-E<gt>error>

=back

Get error information

=cut

sub error {
    my $self = shift;
    return $self->{error};
}

#===========================================================
# From API cookbook
###

### These can already be defined in your environment, or you can get
### them from the user on the command line or from stdin.  It's
### probably best to get the password from stdin.

###
### Routine to run a query using authentication via PKI certificate
### Inputs:
###  server - the IPsonar report server
###  method - the method or query name, e.g., getReports
###  params - reference to a hash of parameter name / value pairs
### Output:
###  The page in XML format returned by IPsonar
###
sub _request_using_certificate {
    my ( $server, $method, $params, $cert, $passwd ) = @_;

    my $path = _get_path( $method, $params );    # See "Constructing URLs";
    my $url = "https://${server}${path}";

    local $ENV{HTTPS_PKCS12_FILE}     = $cert;
    local $ENV{HTTPS_PKCS12_PASSWORD} = $passwd;
    my $ua  = LWP::UserAgent->new;
    my $req = HTTP::Request->new( 'GET', $url );
    my $res = $ua->request($req);

    return $res->content;
}

#===========================================================
# From API cookbook
###
### Routine to run a query using authentication via user name and password.
### Inputs:
### server - the IPsonar report server
### method - the method or query name, e.g., initiateScan
### params - reference to a hash of parameter name / value pairs
### uname - the IPsonar user name
### passwd - the IPsonar user's password
### Output:
### The page in XML format returned by IPsonar
###
sub _request_using_password {
    my ( $server, $method, $params, $uname, $passwd ) = @_;
    my $port = HTTPS_TCP_PORT;                   # The usual port for https
    my $path = _get_path( $method, $params );    # See "Constructing URLs"
         #print "URL: https://$server$path\n";

    my $authstring = MIME::Base64::encode( "$uname:$passwd", q() );
    my ( $page, $result, %headers ) =    # we're only interested in $page
      Net::SSLeay::get_https( $server, $port, $path,
        Net::SSLeay::make_headers( Authorization => 'Basic ' . $authstring ) );
    if ( !( $result =~ /OK$/ ) ) {
        croak $result;
    }
    return ($page);
}

sub _request_localhost {
    my ( $method, $params ) = @_;
    my $path = _get_path( $method, $params );    # See "Constructing URLs"
    my $url = "http://127.0.0.1:8081${path}";

    my $ua  = LWP::UserAgent->new;
    my $req = HTTP::Request->new( 'GET', $url );
    my $res = $ua->request($req);

    return $res->content;
}

#===========================================================
# From API cookbook
###
### Routine to encode the path part of an API call's URL. The
### path is everything after "https://server".
### Inputs:
###   method - the method or query name, e.g., initiateScan
###   params - reference to a hash of parameter name /value pairs
### Output:
###   The query path with the special characters properly encoded
###
sub _get_path {
    my ( $method, $params ) = @_;
    my $path_start = '/reporting/api/service/';
    my $path = $path_start . $method . q(?);    # all API calls start this way
                                                # Now add parameters
    if ( defined $params ) {
        while ( my ( $p, $v ) = each %{$params} ) {
            if ( $path !~ /[?]$/xms ) {    # ... if this isn't the first param
                $path .= q(&);             # params are separated by &
            }
            $path .= "$p=$v";
        }
    }
    my $encoded = URI->new($path);         # encode the illegal characters
                                           # (eg, space => %20)
    return ( $encoded->as_string );
}

#-----------------------------------------------------------

=head1 METHODS

=over 8

=item B<$rsn-E<gt>reports ()>

=back

Returns an array representing the reports on this RSN.
This array is sorted by ascending report id.
Do not run this while you're iterating through another query as
it will reset its internal state.
Timestamps are converted to epoch time.

An example of how you might use this:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use IPsonar;

    my $rsn = IPsonar->new('s2','username','password');
    my @reports = $rsn->reports;


=cut

sub reports {
    my $self = shift;
    my @reports;
    my $results = $self->query( 'config.reports', {} )
      or croak "Problem " . $self->error;

    while ( my $r = $self->next_result ) {
        $r->{timestamp} = int( $r->{timestamp} / 1000 );
        push @reports, $r;
    }

    @reports = sort { $a->{id} <=> $b->{id} } @reports;
    return @reports;
}
1;

=head1 USAGE

The way I've settled on using this is to build the query I want using
the built-in IPsonar query builder.  Once I've got that fine tuned I
translate the url into a query.

For example, if I build a query to get all the routers from report 49 
(showing port information), I'd wind up with the following URL:

https://s2/reporting/api/service/detail.devices?fmt=xml&q.page=0&q.pageSize=100&q.details=Ports&q.f.report&q.f.report.id=49&q.f.router&q.f.router.router=true

This module takes care of the I<fmt>, I<q.page>, and I<q.pageSize> parameters 
for you (you can specify I<q.pageSize> if you really want).  
I might translate that into the following code:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use IPsonar;
    use Data::Dumper;

    my $rsn = IPsonar->new('s2','username','password');

    my $results = $rsn->query('detail.devices',
        {
            'q.details'                     =>  'Ports',
            'q.f.report.id'                 =>  49,
            'q.f.router.router'             =>  'true',
        }) or die "Problem ".$rsn->error;

    while ( my $x = $rsn->next_result ) {
        print Dumper($x);
        my $ports = $x->{ports}->{closedPorts}->{integer};
        print ref($ports) eq 'ARRAY' ? join ',' , @{$ports} : $ports ;
    }

And get this as a result:

    $VAR1 = {
        'ports' => {
            'openPorts' => {
                'integer' => '23'
            },
            'closedPorts' => {
                'integer' => [
                    '21',
                    '22',
                    '25',
                ]
        }
    },
    'ip' => '10.2.0.2'
    };
    21,23,25

Note that things like ports might come back as an Arrayref or might 
come back as a single item.  I find there's some tweaking involved as you 
figure out how the data is laid out.

=cut
