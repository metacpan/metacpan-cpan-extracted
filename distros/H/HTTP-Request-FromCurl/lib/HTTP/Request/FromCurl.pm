package HTTP::Request::FromCurl;
use strict;
use warnings;
use File::Basename 'basename';
use HTTP::Request;
use HTTP::Request::Common;
use URI;
use URI::Escape;
use Getopt::Long;
use File::Spec::Unix;
use HTTP::Request::CurlParameters;
use HTTP::Request::Generator 'generate_requests';
use PerlX::Maybe;
use MIME::Base64 'encode_base64';
use File::Basename 'basename';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.41';

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

=head1 RATIONALE

C<curl> command lines are found everywhere in documentation. The Firefox
developer tools can also copy network requests as C<curl> command lines from
the network panel. This module enables converting these to Perl code.

=head1 METHODS

=head2 C<< ->new >>

    my $req = HTTP::Request::FromCurl->new(
        # Note - curl itself may not appear
        argv => ['--user-agent', 'myscript/1.0', 'https://example.com'],
    );

    my $req = HTTP::Request::FromCurl->new(
        # Note - curl itself may not appear
        command => '--user-agent myscript/1.0 https://example.com',
    );

The constructor returns one or more L<HTTP::Request::CurlParameters> objects
that encapsulate the parameters. If the command generates multiple requests,
they will be returned in list context. In scalar context, only the first request
will be returned. Note that the order of URLs between C<--url> and unadorned URLs will be changed in the sense that all unadorned URLs will be handled first.

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

The following C<curl> options are recognized but largely ignored:

=over 4

=item C< --dump-header >

=item C< --include >

=item C< --location >

=item C< --progress-bar >

=item C< --show-error >

=item C< --fail >

=item C< --silent >

=item C< --verbose >

=item C< --junk-session-cookies >

If you want to keep session cookies between subsequent requests, you need to
provide a cookie jar in your user agent.

=item C<--next>

Resetting the UA between requests is something you need to handle yourself

=item C<--parallel>

=item C<--parallel-immediate>

=item C<--parallel-max>

Parallel requests is something you need to handle in the UA

=back

=cut

our @option_spec = (
    'user-agent|A=s',
    'verbose|v',         # ignored
    'show-error|S',      # ignored
    'fail|f',            # ignored
    'silent|s',          # ignored
    'anyauth',           # ignored
    'basic',
    'buffer!',
    'compressed',
    'cookie|b=s',
    'cookie-jar|c=s',
    'data|d=s@',
    'data-ascii=s@',
    'data-binary=s@',
    'data-raw=s@',
    'data-urlencode=s@',
    'digest',
    'dump-header|D=s',   # ignored
    'referrer|e=s',
    'form|F=s@',
    'form-string=s@',
    'get|G',
    'globoff|g',
    'head|I',
    'header|H=s@',
    'include|i',         # ignored
    'insecure|k',
    'location|L',        # ignored, we always follow redirects
    'max-time|m=s',
    'ntlm',
    'keepalive!',
    'request|X=s',
    'oauth2-bearer=s',
    'output|o=s',
    'progress-bar|#',    # ignored
    'user|u=s',
    'next',                      # ignored
    'parallel|Z',                # ignored
    'parallel-immediate',        # ignored
    'parallel-max',              # ignored
    'junk-session-cookies|j',    # ignored, must be set in code using the HTTP request
    'unix-socket=s',
    'url=s@',
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

    for (@$cmd) {
        $_ = '--next'
            if $_ eq '-:'; # GetOptions does not like "next|:" as specification
    };

    my $p = Getopt::Long::Parser->new(
        config => [ 'bundling', 'no_auto_abbrev', 'no_ignore_case_always' ],
    );
    $p->getoptionsfromarray( $cmd,
        \my %curl_options,
        @option_spec,
    ) or return;
    my @urls = (@$cmd, @{ $curl_options{ url } || [] });

    return
        wantarray ? map { $class->_build_request( $_, \%curl_options, %options ) } @urls
                  :       ($class->_build_request( $urls[0], \%curl_options, %options ))[0]
                  ;
}

=head1 METHODS

=head2 C<< ->squash_uri( $uri ) >>

    my $uri = HTTP::Request::FromCurl->squash_uri(
        URI->new( 'https://example.com/foo/bar/..' )
    );
    # https://example.com/foo/

Helper method to clean up relative path elements from the URI the same way
that curl does.

=cut

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

sub _maybe_read_data_file( $self, $read_files, $data ) {
    my $res;
    if( $read_files ) {
        if( $data =~ /^\@(.*)/ ) {
            open my $fh, '<', $1
                or die "$1: $!";
            local $/; # / for Filter::Simple
            binmode $fh;
            $res = <$fh>
        } else {
            $res = $data
        }
    } else {
        $res = ($data =~ /^\@(.*)/)
             ? "... contents of $1 ..."
             : $data
    }
    return $res
}

sub _maybe_read_upload_file( $self, $read_files, $data ) {
    my $res;
    if( $read_files ) {
        if( $data =~ /^<(.*)/ ) {
            open my $fh, '<', $1
                or die "$1: $!";
            local $/; # / for Filter::Simple
            binmode $fh;
            $res = <$fh>
        } elsif( $data =~ /^\@(.*)/ ) {
            # Upload the file
            $res = [ $1 => basename($1), Content_Type => 'application/octet-stream' ];
        } else {
            $res = $data
        }
    } else {
        if( $data =~ /^[<@](.*)/ ) {
            $res = [ undef,  basename($1), Content_Type => 'application/octet-stream', Content => "... contents of $1 ..." ],
        } else {
            $res = $data
        }
    }
    return $res
}

sub _build_request( $self, $uri, $options, %build_options ) {
    my $body;

    my @headers = @{ $options->{header} || []};
    my $method = $options->{request};
    # Ideally, we shouldn't sort the data but process it in-order
    my @post_read_data = (@{ $options->{'data'} || []},
                          @{ $options->{'data-ascii'} || [] }
                         );
                         ;
    my @post_raw_data = @{ $options->{'data-raw'} || [] },
                    ;
    my @post_urlencode_data = @{ $options->{'data-urlencode'} || [] };
    my @post_binary_data = @{ $options->{'data-binary'} || [] };

    my @form_args;
    if( $options->{form}) {
        # support --form uploaded_file=@myfile
        #     and --form "uploaded_text=<~/texts/content.txt"
        push @form_args, map {   /^([^=]+)=(.*)$/
                                 ? ($1 => $self->_maybe_read_upload_file( $build_options{ read_files }, $2 ))
                                 : () } @{$options->{form}
                             };
    };
    if( $options->{'form-string'}) {
        push @form_args, map {; /^([^=]+)=(.*)$/ ? ($1 => $2) : (); } @{ $options->{'form-string'}};
    };

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
        # Thous should be hoisted out of the loop
        @post_binary_data = map {
            $self->_maybe_read_data_file( $build_options{ read_files }, $_ );
        } @post_binary_data;

        @post_read_data = map {
            my $v = $self->_maybe_read_data_file( $build_options{ read_files }, $_ );
            $v =~ s![\r\n]!!g;
            $v
        } @post_read_data;

        @post_urlencode_data = map {
            m/\A([^@=]*)([=@])?(.*)\z/sm
                or die "This should never happen";
            my ($name, $op, $content) = ($1,$2,$3);
            if(! $op) {
                $content = $name;
            } elsif( $op eq '@' ) {
                $content = "$op$content";
            };
            if( defined $name and length $name ) {
                $name .= '=';
            } else {
                $name = '';
            };
            my $v = $self->_maybe_read_data_file( $build_options{ read_files }, $content );
            $name . uri_escape( $v )
        } @post_urlencode_data;

        my $data;
        if(    @post_read_data
                or @post_binary_data
                or @post_raw_data
                or @post_urlencode_data
        ) {
            $data = join "&",
                @post_read_data,
                @post_binary_data,
                @post_raw_data,
                @post_urlencode_data
                ;
        };

        if( @form_args) {
            $method //= 'POST';

            my $req = HTTP::Request::Common::POST(
                'https://example.com',
                Content_Type => 'form-data',
                Content => \@form_args,
            );
            $body = $req->content;
            $request_default_headers{ 'Content-Type' } = join "; ", $req->headers->content_type;

        } elsif( $options->{ get }) {
            $method = 'GET';
            # Also, append the POST data to the URL
            if( $data ) {
                my $q = $uri->query;
                if( defined $q and length $q ) {
                    $q .= "&";
                } else {
                    $q = "";
                };
                $q .= $data;
                $uri->query( $q );
            };

        } elsif( $options->{ head }) {
            $method = 'HEAD';

        } elsif( defined $data ) {
            $method //= 'POST';
            $body = $data;
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
                || $options->{digest}
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

        if( defined $options->{ 'user-agent' }) {
            $self->_add_header( \%headers, "User-Agent", $options->{ 'user-agent' } );
        };

        if( defined $options->{ referrer }) {
            $self->_add_header( \%headers, "Referer" => $options->{ 'referrer' } );
        };

        # We want to compare the headers case-insensitively
        my %headers_lc = map { lc $_ => 1 } keys %headers;

        for my $k (keys %request_default_headers) {
            if( ! $headers_lc{ lc $k }) {
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

        my $auth;
        for my $kind (qw(basic ntlm negotiate)) {
            if( $options->{$kind}) {
                $auth = $kind;
            }
        };

        push @res, HTTP::Request::CurlParameters->new({
            method => $method,
            uri    => $uri,
            headers => \%headers,
            body   => $body,
            maybe auth => $auth,
            maybe credentials => $options->{ user },
            maybe output => $options->{ output },
            maybe timeout => $options->{ 'max-time' },
            maybe cookie_jar => $options->{'cookie-jar'},
            maybe cookie_jar_options => $options->{'cookie-jar-options'},
            maybe insecure => $options->{'insecure'},
            maybe show_error => $options->{'show-error'},
            maybe fail => $options->{'fail'},
            maybe unix_socket => $options->{'unix-socket'},
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

Mixed data instances

Multiple mixed instances of C<--data>, C<--data-ascii>, C<--data-raw>,
C<--data-binary> or C<--data-raw> are sorted by type first instead of getting
concatenated in the order they appear on the command line.
If the order is important to you, use one type only.

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

The module HTTP::Request::AsCurl likely also implements a much better version
of C<< ->as_curl >> than this module.

L<https://github.com/NickCarneiro/curlconverter> - a converter for multiple
target languages

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/HTTP-Request-FromCurl>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/HTTP-Request-FromCurl/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2018-2022 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
