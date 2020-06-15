package # hide from indexer as it's not really ready
    Future::HTTP::API::HTTPTiny;
use strict;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
require HTTP::Tiny;
require URI;

our $VERSION = '0.14';

=head1 NAME

Future::HTTP::API::HTTPTiny - Future::HTTP with an API like HTTP::Tiny

=cut

sub as_http_tiny( $self, $body, $headers ) {
    # Reformat the AnyEvent style into HTTP::Tiny style
    my $status = delete $headers->{Status};

    my $result = {
        success => ($status =~ /^2../ ? 1 : undef),
        url     => delete $headers->{URL},
        status  => $status,
        reason  => (delete $headers->{Reason}),
        content => $body,
        headers => $headers,
    };

    # Convert the redirects from the recursive structure of AnyEvent to
    # a flat list:
    if( my $r = delete $headers->{Redirect} ) {
        my $previous = $self->as_http_tiny( $r->[0], $r->[1] );
        # Convert previous redirects to a flat array
        my @redirects;
        if( $previous->{redirects}) {
            push @redirects, @{ $previous->{redirects} };
        };
        push @redirects, $r;
        $result->{redirects} = \@redirects;
    };

    $result
}

sub munge_ht_options($self, $url, %options) {
    $options{ on_body } = delete $options{ data_callback }
        if $options{ data_callback };
    $options{ body } = delete $options{ content }
        if $options{ content };
    die "Sorry, (code) references for the 'content' parameter are not yet supported"
        if ref $options{ body };

    my $parsed_url = URI->new( $url );
    my $auth = $parsed_url->userinfo;
    # if we have Basic auth parameters, add them
    if ( length $auth && $auth ne ':' and ! defined $options{headers}->{authorization} ) {
        # Recover percent-encoded stuff from URL
        $auth =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        require MIME::Base64;
        $options{ headers }->{authorization} = 'Basic ' . MIME::Base64::encode_base64($auth, '');
    };

    # Should we convert the case of the headers here?!
    # Add the cookie jar
    # Convert the case of the headers

    %options
}

sub mirror($self, $url, $file, $args) {
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
      or Carp::croak(q/Usage: $http->mirror(URL, FILE, [HASHREF])/ . "\n");
    if ( -e $file and my $mtime = (stat($file))[9] ) {
        $args->{headers}{'if-modified-since'} ||= $self->_http_date($mtime);
    }
    my $tempfile = $file . int(rand(2**31));

    require Fcntl;
    sysopen my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY()
       or Carp::croak(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;
    $args->{data_callback} = sub {  print {$fh} $_[0] };
    my $response = $self->request('GET', $url, $args);

    $response->then(sub( $result ) {
        use Data::Dumper;
        warn Dumper $result;
        close $fh
            or Carp::croak(qq/Error: Caught error closing temporary file '$tempfile': $!\n/);

        if ( $result->{success} ) {
            rename $tempfile, $file
                or Carp::croak(qq/Error replacing '$file' with '$tempfile': $!\n/);
            my $lm = $result->{headers}{'last-modified'};
            if ( $lm and my $mtime = $self->_parse_http_date($lm) ) {
                utime $mtime, $mtime, $file;
            }
        }
        $result->{success} ||= $result->{status} eq '304';
        unlink $tempfile;
    });
}

# Replace HTTP::Tiny::Request, keep all the other methods

no warnings 'once';
*www_form_urlencode = \&HTTP::Tiny::www_form_urlencode;
*_http_date = \&HTTP::Tiny::_http_date;
*_parse_http_date = \&HTTP::Tiny::_parse_http_date;

1;
