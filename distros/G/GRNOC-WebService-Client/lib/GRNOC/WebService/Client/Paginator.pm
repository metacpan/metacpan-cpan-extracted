#--------------------------------------------------------------------
#----- GRNOC Web Service Client Paginator
#-----
#----- Copyright(C) 2014 The Trustees of Indiana University
#--------------------------------------------------------------------
#----- $HeadURL: svn+ssh://svn.grnoc.iu.edu/grnoc/perl-lib/GRNOC-WebService-Client/trunk/lib/GRNOC/WebService/Client/Paginator.pm $
#----- $Id: Paginator.pm 30714 2014-05-09 19:10:05Z mrmccrac $
#-----
#----- Library that assists with iterating through a set of paginated
#----- results from GRNOC web services.
#---------------------------------------------------------------------

package GRNOC::WebService::Client::Paginator;

use strict;
use warnings;

use Data::Dumper;

=head1 NAME

GRNOC::WebService::Client::Paginator

=head1 SYNOPSIS

use GRNOC::WebService::Client;

my $websvc = GRNOC::WebService::Client->new( ...,
                                             use_pagination => 1 );

# returns a GRNOC::WebService::Client::Paginator object
my $paginator = $websvc->get_stuff();

while ( $paginator->has_page() ) {

    my $page = $paginator->next_page();

    if ( !$page || $page->{'error'} ) {

      # handle error
    }
}
                                             
=head1 DESCRIPTION

This library acts as an iterator to help properly paginating through
a set of GRNOC WebService results.  It passes the correct limit &
offset values for each iteration after determing the total number of
available results from the first response.  You probably shouldn't
ever instantiate this object yourself directly, but will get an
instance of it from the GRNOC::WebService::Client object when it
has pagination enabled.

=cut

=head1 CONSTRUCTOR

=over 4

=item new ( OPTIONS )

=over 4

=item websvc <GRNOC::WebService::Client> [required]

The B<GRNOC::WebService::Client> object used to issue webservice requests.

=item limit <NUMBER> [optional]

The maximum number of results to return per each iteration.  Defaults to 1000.

=item offset <NUMBER> [optional]

The initial index to offset the results by.  Defaults to 0.

=item method <STRING> [required]

The name of the webservice method to execute.

=item params <HASHREF> [optional]

Any additional parameters/key-value pairs to pass to the webservice method.

=back

=back

=cut

sub new {

    my $class = shift;

    my $self = {'websvc' => undef,
                'total' => undef,
                'limit' => 1000,
                'offset' => 0,
                'method' => undef,
                'params' => {},
		'error' => undef,
                @_};

    bless( $self, $class );

    return $self;
}

=head1 GETTERS/SETTERS

=over 4

=item websvc <GRNOC::WebService::Client>

The B<GRNOC::WebService::Client> object used to issue webservice requests.

=cut

sub websvc {

    my ( $self, $websvc ) = @_;

    $self->{'websvc'} = $websvc if ( defined( $websvc ) );

    return $self->{'websvc'};
}

=item total <NUMBER>

The number of known total results for the entire webservice request (non-paginated).

=cut

sub total {

    my ( $self, $total ) = @_;

    $self->{'total'} = $total if ( defined( $total ) );

    return $self->{'total'};
}

=item limit <NUMBER>

The maximum number of results to return per each iteration.

=cut

sub limit {

    my ( $self, $limit ) = @_;

    $self->{'limit'} = $limit if ( defined( $limit ) );

    return $self->{'limit'};
}

=item offset <NUMBER>

The initial index to offset the results by

=cut

sub offset {

    my ( $self, $offset ) = @_;

    $self->{'offset'} = $offset if ( defined( $offset ) );

    return $self->{'offset'};
}

=item method <STRING>

The name of the webservice method to execute.

=cut

sub method {

    my ( $self, $method ) = @_;

    $self->{'method'} = $method if ( defined( $method ) );

    return $self->{'method'};
}

=item params <HASHREF>

Any additional parameters/key-value pairs to pass to the webservice method.

=back

=cut

sub params {

    my ( $self, $params ) = @_;

    $self->{'params'} = $params if ( defined( $params ) );

    return $self->{'params'};
}

=head1 METHODS

=over 4

=item has_page ()

Returns a true or false value if there are still any pages of results left to return.
This will always return true before the first call to B<next_page()> until it knows
the total number of possible results.

=cut

sub has_page {

    my ( $self ) = @_;

    my $total = $self->total();
    my $offset = $self->offset();

    # we hit an error, dont allow more paging
    return 0 if ( $self->{'error'} );

    # no more pages if our offset has exceeded the known total
    my $no_more_pages = defined( $total ) && defined( $offset ) && $offset >= $total;

    return !$no_more_pages;
}

=item next_page ()

Returns the response from the webservice call for the next set of paginated results.
It will return undef if there was an error attempting to issue the HTTP request.
The offset of the paginator will be increased by the size of the limit for the next
time it is called.

=cut

sub next_page {

    my $self = shift;

    my $method = $self->method();
    my $params = $self->params();

    my $websvc = $self->websvc();

    # grab the last known total, limit, and offset values
    my $total = $self->total();
    my $limit = $self->limit();
    my $offset = $self->offset();

    # we're all done if there are no more pages
    return if ( !$self->has_page() );

    # temporarily disable pagination so that it actually executes the method and doesn't return
    # another paginator object
    $self->websvc()->{'use_pagination'} = 0;

    # issue the original request, but with the proper limit/offset values for pagination
    my $ret = $self->websvc()->$method( %$params,
					limit => $limit,
					offset => $offset );

    # re-enable pagination
    $self->websvc()->{'use_pagination'} = 1;

    # detect error
    if ( !$ret || $ret->{'error'} ) {

	# we hit an error case
	$self->{'error'} = 1;

	# return either undef or the error'd result back to them
	return $ret;
    }

    # the new total and offset values from the request
    $total = $ret->{'total'};
    $offset = $ret->{'offset'};

    # make sure we update the known total if its changed
    $self->total( $total );

    # store proper offset value for next time by the page size
    $self->offset( $offset + $limit );

    return $ret;
}

=back

=cut

1;
