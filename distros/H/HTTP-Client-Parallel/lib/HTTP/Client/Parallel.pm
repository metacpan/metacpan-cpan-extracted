package HTTP::Client::Parallel;

=pod

=head1 NAME

HTTP::Client::Parallel - A HTTP client that fetchs all URIs in parallel

=head1 SYNOPSIS

  # Create the parallising client
  my $client = HTTP::Client::Parallel->new;
  
  # Simple fetching
  my $pages = $client->get(
    'http://www.google.com/',
    'http://www.yapc.org/',
    'http://www.yahoo.com/',
  );
  
  # Mirroring to disk
  my $responses = $client->mirror(
    'http://www.google.com/' => 'mirrors/google.html',
    'http://www.yapc.org/'   => 'mirrors/yapc.html',
    'http://www.yahoo.com/'  => 'mirrors/yahoo.html',
  );

=head1 DESCRIPTION

Fetching a URI is a very common network-bound task in many types of
programming. Fetching more than one URI is also very common, but unless
the fetches are capable of entirely saturating a connection, typically
time is wasted because there is often no logical reason why multiple
requests cannot be made in parallel.

Executing IO-bound and network-bound tasks is extremely easy in any
event-based programming model such as L<POE>, but these event-based
systems normally require complete control of the application and
that the program be written in a very different way.

Thus, the biggest problem preventing running HTTP requests in
parallel is not that it isn't possible, but that mixing procedural
and event programming is difficult.

The few existing mechanisms generally rely on forking or other
platform-specific methods.

B<HTTP::Client::Parallel> is designed to bridge the gap between
typical cross-platform procedural code and typical cross-platform
event-based code.

It allows you to set up a series of HTTP tasks (fetching to memory,
fetching to disk, and mirroring to disk) and then issue a single
method call which will block and execute all of them in parallel.

Behind the scenes HTTP::Client::Parallel will B<temporarily> hand
over control of the process to L<POE> to execute the HTTP tasks.

Once all of the HTTP tasks are completed (using the standard
L<POE::Component::HTTP::Client> module, the POE kernel will shut
down and hand control of the application back to the normal
procedural code, and thus back to your code.

As a result, a developer with no knowledge of L<POE> or event-based
programming can still take advantage of the capabilities of POE and
gain major speed increases in HTTP-based programs with relatively
little work.

=head1 METHODS

TO BE COMPLETED

=cut

use 5.006;
use strict;
use warnings;
use Exporter      ();
use IO::File      ();
use Params::Util  '_INSTANCE';
use HTTP::Date    ();
use HTTP::Request ();
use POE;
use POE::Session;
use POE::Component::Client::HTTP;

use constant HCP                    => __PACKAGE__;
use constant DEFAULT_REDIRECT_DEPTH => 2;
use constant DEFAULT_TIMEOUT        => 60;

use vars qw{$VERSION @ISA @EXPORT_OK};
BEGIN {
    $VERSION   = '0.02';
    @ISA       = 'Exporter';
    @EXPORT_OK = qw{ mirror getstore get };
}

sub new {
    my ( $class, %args )  = @_;
    return bless {
        requests       => {},
        results        => {},
        count          => 0,
        debug          => $args{debug}          || 0,
        http_alias     => $args{http_alias}     || 'ua',
        timeout        => $args{timeout}        || DEFAULT_TIMEOUT,
        redirect_depth => $args{redirect_depth} || DEFAULT_REDIRECT_DEPTH,
    }, $class;
}

sub urls {
    return wantarray ? @{ $_[0]->{urls} } : $_[0]->{urls};
}

sub get {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    $self->_init;
    $self->_set_urls(@_);
    $self->poe_loop;
    my @responses = map { $self->{responses}{$_} } $self->urls;   
    return wantarray ? @responses : \@responses

    # XXX from the pod, this may be the desired behavior
    # my @content = map { $self->{responses}{$_}->content } $self->urls;
    # return wantarray ? @content : \@content
}

sub getstore {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    my %url_file_map = @_;
    $self->_init;
    $self->_set_urls( keys %url_file_map );
    $self->{local_files} = \%url_file_map;
    $self->poe_loop;
    my @responses = values %{ $self->{responses} };
    return wantarray ? @responses : \@responses;
}

sub mirror {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    my %url_file_map = @_;
    $self->_init;
    $self->_set_urls( keys %url_file_map );
    $self->{local_files} = \%url_file_map;
    $self->_build_modified_since( \%url_file_map );
    $self->poe_loop;
    my @responses = values %{ $self->{responses} };
    return wantarray ? @responses : \@responses
}

# cleanup between uses just in case
sub _init {
    my ($self) = @_;
    $self->{count} = 0;
    delete @{$self}{qw(requests responses urls url_count local_files modified_since)};
    return;
}

sub _set_urls {
    my ( $self, @urls ) = @_;
    $self->{urls} = \@urls;
    $self->{url_count} = @urls;
    return;
}

sub _build_modified_since {
    my ( $self, $url_file_map ) = @_;
    for my $url ( keys %$url_file_map ) {
        my $file = $url_file_map->{$url};
        if ( -e $file ) {
            my ($mtime) = ( stat($file) )[9];
            $self->{modified_since}{$url} = HTTP::Date::time2str($mtime) if $mtime;
        }
    }
}

sub _store_local_file {
    my ( $self, $response, $file ) = @_;

    my $tmpfile = "$file-$$";

    open my $tmp_fh, ">", $tmpfile or die "Can't open temp file $tmpfile for writing: $!";
    print $tmp_fh $response->content;
    close $tmp_fh;

    # the following is taken from LWP::UserAgent->mirror
    my $file_length = ( stat($tmpfile) )[7];
    my ($content_length) = $response->header('Content-length');

    if ( defined $content_length and $file_length < $content_length ) {
        unlink($tmpfile);
        die "Transfer truncated: only $file_length out of $content_length bytes received\n";
    }
    elsif ( defined $content_length and $file_length > $content_length ) {
        unlink($tmpfile);
        die "Content-length mismatch: expected $content_length bytes, got $file_length\n";
    }
    else {    # OK
        if ( -e $file ) {
            chmod 0777, $file;    # Some dosish systems fail to rename if the target exists
            unlink $file;
        }
        rename( $tmpfile, $file ) or die "Cannot rename '$tmpfile' to '$file': $!\n";

        if ( my $lm = $response->last_modified ) {
            utime $lm, $lm, $file;    # make sure the file has the same last modification time
        }
    }

    return;
}

# POE 
sub poe_loop {
    my $self = shift;

    POE::Component::Client::HTTP->spawn(
        Alias           => $self->{http_alias} || 'ua',
        Timeout         => $self->{timeout},
        FollowRedirects => $self->{redirect_depth},
    );

    POE::Session->create( object_states => [ 
        $self => [qw( _start _request _response shutdown _stop)] 
    ]);

    POE::Kernel->run;

    return;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_set("$self");
    $kernel->yield( _request => $_ ) for @{ $self->{urls} };;
    return;
}

sub _build_request {
    my ( $self, $url ) = @_;
    
    my $request;
    if ( Scalar::Util::blessed($url) and $url->isa('HTTP::Request') ) {
        $request = $url;
    }
    elsif ( ( Scalar::Util::blessed($url) and $url->isa('URI') ) or !ref $url ) {
        $request = HTTP::Request->new( GET => $url );
    }
    else {
       die "[!!] invalid URI, HTTP::Request or url string: $url\n";
    }

    if ( $self->{modified_since} && $self->{modified_since}{$url} ) {
        $request->header( 'If-Modified-Since' => $self->{modified_since}{$url} );
    }

    return $request;
}

sub _request {
    my ( $self, $kernel, $url ) = @_[ OBJECT, KERNEL, ARG0 ];

    my $request = $self->_build_request($url);
    warn '[' . $request->uri . '] Attempting to fetch' . "\n" if $self->{debug};
    $kernel->post( $self->{http_alias}, 'request', '_response', $request );

    return;
}

sub _response {
    my ( $self, $kernel, $request_packet, $response_packet ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    my $request  = $request_packet->[0];
    my $response = $response_packet->[0];
    $self->{responses}{ $request->uri } = $response;
    $self->{count}++;

    if ( $response->is_success ) {
        warn '[' . $request->uri . "] Fetched\n" if $self->{debug};
        if ( my $local_file = $self->{local_files}{ $request->uri } ) {
            $self->_store_local_file( $response, $local_file );
        }
    }
    elsif ( $response->code == 304 ) {
        warn '[' . $request->uri . "] Not Modified\n" if $self->{debug};
    }
    else {
        warn '[' . $request->uri . "] HTTP Response Code: " . $response->code . "\n"
            if $self->{debug};
    }

    $kernel->call( ua => 'shutdown' ) if $self->{url_count} == $self->{count};

    return;
}

sub shutdown {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_remove( $self->{http_alias} );
    return;
}

sub _stop {
    my $self = $_[OBJECT];
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Client-Parallel>

For other issues, contact the author.

=head1 AUTHORS

Marlon Bailey E<lt>mbailey@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Jeff Bisbee E<lt>jbisbee@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Simple>, L<POE>

=head1 COPYRIGHT

Copyright 2008 Marlon Bailey, Adam Kennedy and Jess Bisbee.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
