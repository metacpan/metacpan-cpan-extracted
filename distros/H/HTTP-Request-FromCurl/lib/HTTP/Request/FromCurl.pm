package HTTP::Request::FromCurl;
use strict;
use warnings;
use HTTP::Request;
use HTTP::Request::Common;
use URI;
use Getopt::Long;
use File::Spec::Unix;
use HTTP::Request::CurlParameters;
use HTTP::Request::Generator 'generate_requests';
use PerlX::Maybe;
use MIME::Base64 'encode_base64';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.14';

=head1 NAME

HTTP::Request::FromCurl - create a HTTP::Request from a curl command line

=head1 SYNOPSIS

    my $req = HTTP::Request::FromCurl->new(
        # Note - curl itself may not appear
        argv => ['https://example.com'],
    );

    my $req = HTTP::Request::FromCurl->new(
        command => 'https://example.com',
    );

    my $req = HTTP::Request::FromCurl->new(
        command_curl => 'curl -A mycurl/1.0 https://example.com',
    );

    my @requests = HTTP::Request::FromCurl->new(
        command_curl => 'curl -A mycurl/1.0 https://example.com https://www.example.com',
    );
    # Send the requests
    for my $r (@requests) {
        $ua->request( $r->as_request )
    }

=head1 METHODS

=head2 C<< ->new >>

    my $req = HTTP::Request::FromCurl->new(
        # Note - curl itself may not appear
        argv => ['--agent', 'myscript/1.0', 'https://example.com'],
    );

    my $req = HTTP::Request::FromCurl->new(
        # Note - curl itself may not appear
        command => '--agent myscript/1.0 https://example.com',
    );

The constructor returns one or more L<HTTP::Request::CurlParameters> objects
that encapsulate the parameters. If the command generates multiple requests,
they will be returned in list context. In scalar context, only the first request
will be returned.

    my $req = HTTP::Request::FromCurl->new(
        command => '--data-binary @/etc/passwd https://example.com',
        read_files => 1,
    );

=head3 Options

=over 4

=item B<argv>

An arrayref of commands as could be given in C< @ARGV >.

=item B<command>

A scalar in a command line, excluding the C<curl> command

=item B<command_curl>

A scalar in a command line, including the C<curl> command

=item B<read_files>

Do read in the content of files specified with (for example)
C<< --data=@/etc/passwd >>. The default is to not read the contents of files
specified this way.

=back

=head2 C<< ->squash_uri( $uri ) >>

    my $uri = HTTP::Request::FromCurl->squash_uri(
        URI->new( 'https://example.com/foo/bar/..' )
    );
    # https://example.com/foo/

Helper method to clean up relative path elements from the URI the same way
that curl does.

=head1 GLOBAL VARIABLES

=head2 C<< %default_headers >>

Contains the default headers added to every request

=cut

our %default_headers = (
    'Accept'     => '*/*',
    'User-Agent' => 'curl/7.55.1',
);

=head2 C<< @option_spec >>

Contains the L<Getopt::Long> specification of the recognized command line
parameters.

The following C<curl> options are recognized but ignored:

=over 4

=item C< --dump-header >

=item C< --include >

=item C< --location >

=item C< --progress-bar >

=item C< --silent >

=item C< --verbose >

=back

=cut

our @option_spec = (
    'agent|A=s',
    'verbose|v',
    'silent|s',
    'buffer!',
    'compressed',
    'cookie|b=s',
    'cookie-jar|c=s',
    'data|d=s@',
    'data-binary=s@',
    'dump-header|D=s',   # ignored
    'referrer|e=s',
    'form|F=s@',
    'get|G',
    'globoff|g',
    'head|I',
    'header|H=s@',
    'include|i',         # ignored
    'insecure|k',
    'location|L',        # ignored, we always follow redirects
    'max-time|m=s',
    'keepalive!',
    'request|X=s',
    'oauth2-bearer=s',
    'output|o=s',
    'progress-bar|#',    # ignored
    'user|u=s',
);

sub new( $class, %options ) {
    my $cmd = $options{ argv };

    if( $options{ command }) {
        require Text::ParseWords;
        $cmd = [ Text::ParseWords::shellwords($options{ command }) ];

    } elsif( $options{ command_curl }) {
        require Text::ParseWords;
        $cmd = [ Text::ParseWords::shellwords($options{ command_curl }) ];

        # remove the implicit curl command:
        shift @$cmd;
    };

    my $p = Getopt::Long::Parser->new(
        config => [ 'bundling', 'no_auto_abbrev', 'no_ignore_case_always' ],
    );
    $p->getoptionsfromarray( $cmd,
        \my %curl_options,
        @option_spec,
    ) or return;

    return
        wantarray ? map { $class->_build_request( $_, \%curl_options, %options ) } @$cmd
                  :       ($class->_build_request( $cmd->[0], \%curl_options, %options ))[0]
                  ;
}

sub squash_uri( $class, $uri ) {
    my $u = $uri->clone;
    my @segments = $u->path_segments;

    if( $segments[-1] and ($segments[-1] eq '..' or $segments[-1] eq '.' ) ) {
        push @segments, '';
    };

    @segments = grep { $_ ne '.' } @segments;

    # While we find a pair ( "foo", ".." ) remove that pair
    while( grep { $_ eq '..' } @segments ) {
        my $i = 0;
        while( $i < $#segments ) {
            if( $segments[$i] ne '..' and $segments[$i+1] eq '..') {
                splice @segments, $i, 2;
            } else {
                $i++
            };
        };
    };

    if( @segments < 2 ) {
        @segments = ('','');
    };

    $u->path_segments( @segments );
    return $u
}

sub _add_header( $self, $headers, $h, $value ) {
    if( exists $headers->{ $h }) {
        if (!ref( $headers->{ $h })) {
            $headers->{ $h } = [ $headers->{ $h }];
        }
        push @{ $headers->{ $h } }, $value;
    } else {
        $headers->{ $h } = $value;
    }
}

sub _build_request( $self, $uri, $options, %build_options ) {
    my $body;

    my @headers = @{ $options->{header} || []};
    my $method = $options->{request};
    my @post_data = @{ $options->{data} || $options->{'data-binary'} || []};
    my @form_args = @{ $options->{form} || []};

    # expand the URI here if wanted
    my @uris = ($uri);
    if( ! $options->{ globoff }) {
        @uris = map { $_->{url} } generate_requests( pattern => shift @uris, limit => $build_options{ limit } );
    }

    my @res;
    for my $uri (@uris) {
        $uri = URI->new( $uri );
        $uri = $self->squash_uri( $uri );

        my $host = $uri->can( 'host_port' ) ? $uri->host_port : "$uri";

        # Stuff we use unless nothing else hits
        my %request_default_headers = %default_headers;

        # Sluuuurp
        if( $build_options{ read_files }) {
            @post_data = map {
                /^\@(.*)/ ? do {
                                open my $fh, '<', $1
                                    or die "$1: $!";
                                local $/;
                                binmode $fh;
                                <$fh>
                            }
                        : $_
            } @post_data;
        } else {
            @post_data = map {
                /^\@(.*)/ ? "... contents of $1 ..."
                        : $_
            } @post_data;
        };

        if( @form_args) {
            $method = 'POST';

            my $req = HTTP::Request::Common::POST(
                'https://example.com',
                Content_Type => 'form-data',
                Content => [ map { /^([^=]+)=(.*)$/ ? ($1 => $2) : () } @form_args ],
            );
            $body = $req->content;
            $request_default_headers{ 'Content-Type' } = join "; ", $req->headers->content_type;

        } elsif( $options->{ get }) {
            $method = 'GET';
            # Also, append the POST data to the URL
            if( @post_data ) {
                my $q = $uri->query;
                if( defined $q and length $q ) {
                    $q .= "&";
                } else {
                    $q = "";
                };
                $q .= join "", @post_data;
                $uri->query( $q );
            };

        } elsif( $options->{ head }) {
            $method = 'HEAD';

        } elsif( @post_data ) {
            $method = 'POST';
            $body = join "", @post_data;
            $request_default_headers{ 'Content-Type' } = 'application/x-www-form-urlencoded';

        } else {
            $method ||= 'GET';
        };

        if( defined $body ) {
            $request_default_headers{ 'Content-Length' } = length $body;
        };

        if( $options->{ 'oauth2-bearer' } ) {
            push @headers, sprintf 'Authorization: Bearer %s', $options->{'oauth2-bearer'};
        };

        if( $options->{ 'user' } ) {
            if(    $options->{anyauth}
                || $options->{ntlm}
                || $options->{negotiate}
                ) {
                # Nothing to do here, just let LWP::UserAgent do its thing
                # This means one additional request to fetch the appropriate
                # 401 response asking for credentials, but ...
            } else {
                # $options->{basic} or none at all
                my $info = delete $options->{'user'};
                # We need to bake this into the header here?!
                push @headers, sprintf 'Authorization: Basic %s', encode_base64( $info );
            }
        };

        my %headers;
        for my $kv (
            (map { /^\s*([^:\s]+)\s*:\s*(.*)$/ ? [$1 => $2] : () } @headers),) {
                $self->_add_header( \%headers, @$kv );
        };

        if( defined $options->{ agent }) {
            $self->_add_header( \%headers, "User-Agent", $options->{ 'agent' } );
        };

        if( defined $options->{ referrer }) {
            $self->_add_header( \%headers, "Referer" => $options->{ 'referrer' } );
        };

        for my $k (keys %request_default_headers) {
            if( ! $headers{ $k }) {
                $self->_add_header( \%headers, $k, $request_default_headers{ $k });
            };
        };
        if( ! $headers{ 'Host' }) {
            $self->_add_header( \%headers, 'Host' => $host );
        };

        if( defined $options->{ 'cookie-jar' }) {
                $options->{'cookie-jar-options'}->{ 'write' } = 1;
        };

        if( defined( my $c = $options->{ cookie })) {
            if( $c =~ /=/ ) {
                $headers{ Cookie } = $options->{ 'cookie' };
            } else {
                $options->{'cookie-jar'} = $c;
                $options->{'cookie-jar-options'}->{ 'read' } = 1;
            };
        };

        # Curl 7.61.0 ignores these:
        #if( $options->{ keepalive }) {
        #    $headers{ 'Keep-Alive' } = 1;
        #} elsif( exists $options->{ keepalive }) {
        #    $headers{ 'Keep-Alive' } = 0;
        #};

        if( $options->{ compressed }) {
            my $compressions = HTTP::Message::decodable();
            $self->_add_header( \%headers, 'Accept-Encoding' => $compressions );
        };
        push @res, HTTP::Request::CurlParameters->new({
            method => $method,
            uri    => $uri,
            headers => \%headers,
            body   => $body,
            maybe credentials => $options->{ user },
            maybe output => $options->{ output },
            maybe timeout => $options->{ 'max-time' },
            maybe cookie_jar => $options->{'cookie-jar'},
            maybe cookie_jar_options => $options->{'cookie-jar-options'},
            maybe insecure => $options->{'insecure'},
        });
    }

    return @res
};

1;

=head1 LIVE DEMO

L<https://corion.net/curl2lwp.psgi>

=head1 KNOWN DIFFERENCES

=head2 Incompatible cookie jar formats

Until somebody writes a robust Netscape cookie file parser and proper loading
and storage for L<HTTP::CookieJar>, this module will not be able to load and
save files in the format that Curl uses.

=head2 Loading/saving cookie jars is the job of the UA

You're expected to instruct your UA to load/save cookie jars:

    use Path::Tiny;
    use HTTP::CookieJar::LWP;

    if( my $cookies = $r->cookie_jar ) {
        $ua->cookie_jar( HTTP::CookieJar::LWP->new()->load_cookies(
            path($cookies)->lines
        ));
    };

=head2 Different Content-Length for POST requests

=head2 Different delimiter for form data

The delimiter is built by L<HTTP::Message>, and C<curl> uses a different
mechanism to come up with a unique data delimiter. This results in differences
in the raw body content and the C<Content-Length> header.

=head1 MISSING FUNCTIONALITY

=over 4

=item *

File uploads / content from files

While file uploads and reading POST data from files are supported, the content
is slurped into memory completely. This can be problematic for large files
and little available memory.

=item *

Multiple sets of parameters from the command line

Curl supports the C<< --next >> command line switch which resets
parameters for the next URL.

This is not (yet) supported.

=back

=head1 SEE ALSO

L<LWP::Curl>

L<LWP::Protocol::Net::Curl>

L<LWP::CurlLog>

L<HTTP::Request::AsCurl> - for the inverse function

L<https://github.com/NickCarneiro/curlconverter> - a converter for multiple
target languages

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/HTTP-Request-FromCurl>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Request-FromCurl>
or via mail to L<filter-signatures-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
