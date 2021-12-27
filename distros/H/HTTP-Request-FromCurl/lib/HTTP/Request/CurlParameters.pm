package HTTP::Request::CurlParameters;
use strict;
use warnings;
use HTTP::Request;
use HTTP::Request::Common;
use URI;
use File::Spec::Unix;
use List::Util 'pairmap';
use PerlX::Maybe;
use Carp 'croak';

use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.37';

=head1 NAME

HTTP::Request::CurlParameters - container for a Curl-like HTTP request

=head1 SYNOPSIS

  my $ua = LWP::UserAgent->new;
  my $params = HTTP::Request::CurlParameters->new(argv => \@ARGV);
  my $response = $ua->request($params->as_request);

=head1 DESCRIPTION

Objects of this class are mostly created from L<HTTP::Request::FromCurl>. Most
likely you want to use that module instead:

  my $ua = LWP::UserAgent->new;
  my $params = HTTP::Request::FromCurl->new(command_curl => $cmd);
  my $response = $ua->request($params->as_request);

=head1 METHODS

=head2 C<< ->new >>

Options:

=over 4

=item *

C<method>

    method => 'GET'

The HTTP method to use.

=cut

has method => (
    is => 'ro',
    default => 'GET',
);

=item *

C<uri>

    uri => 'https://example.com'

The URI of the request.

=cut

has uri => (
    is => 'ro',
    default => 'https://example.com',
);

=item *

C<headers>

    headers => {
        'Content-Type' => 'text/json',
        'X-Secret' => ['value-1', 'value-2'],
    }

The headers of the request. Multiple headers with the same
name can be passed as an arrayref to the header key.

=cut

has headers => (
    is => 'ro',
    default => sub { {} },
);

=item *

C<cookie_jar>

The cookie jar to use.

=cut

has cookie_jar => (
    is => 'ro',
);

=item *

C<cookie_jar_options>

Options for the constructor of the cookie jar.

=cut

has cookie_jar_options => (
    is => 'ro',
    default => sub { {} },
);

=item *

C<credentials>

    credentials => 'hunter2:secret'

The credentials to use for basic authentication.

=cut

has credentials => (
    is => 'ro',
);

=item *

C<post_data>

    post_data => ['A string','across multiple','scalars']

The POST body to use.

=cut

has post_data => (
    is => 'ro',
    default => sub { [] },
);

=item *

C<body>

    body => '{"greeting":"Hello"}'

The body of the request.

=cut

has body => (
    is => 'ro',
);

=item *

C<timeout>

    timeout => 50

The timeout for the request

=cut

has timeout => (
    is => 'ro',
);

=item *

C<form_args>

The HTML form parameters. These get converted into
a body.

=cut

has form_args => (
    is => 'ro',
    default => sub { [] },
);

=item *

C<insecure>

    insecure => 1

Disable SSL certificate verification

=cut

has insecure => (
    is => 'ro',
);

=item *

C<output>

Name of the output file

=cut

has output => (
    is => 'ro',
);

=item *

C<show_error>

    show_error => 0

Show error message on HTTP errors

=cut

has show_error => (
    is => 'ro',
);

=item *

C<fail>

    fail => 1

Let the Perl code C<die> on error

=back

=cut

has fail => (
    is => 'ro',
);

sub _build_quoted_body( $self ) {
    if( my $body = $self->body ) {
        $body =~ s!([\x00-\x1f'"\$\@\%\\])!sprintf '\\x%02x', ord $1!ge;
        return sprintf qq{"%s"}, $body

    } else {
        # Sluuuurp
        my @post_data = map {
            /^\@(.*)/ ? do {
                             open my $fh, '<', $1
                                 or die "$1: $!";
                             local $/; # / for Filter::Simple
                             binmode $fh;
                             <$fh>
                           }
                      : $_
        } @{ $self->post_data };
        return join "", @post_data;
    }
};

#    if( @form_args) {
#        $method = 'POST';
#
#        my $req = HTTP::Request::Common::POST(
#            'https://example.com',
#            Content_Type => 'form-data',
#            Content => [ map { /^([^=]+)=(.*)$/ ? ($1 => $2) : () } @form_args ],
#        );
#        $body = $req->content;
#        unshift @headers, 'Content-Type: ' . join "; ", $req->headers->content_type;
#
#    } elsif( $options->{ get }) {
#        $method = 'GET';
#        # Also, append the POST data to the URL
#        if( @post_data ) {
#            my $q = $uri->query;
#            if( defined $q and length $q ) {
#                $q .= "&";
#            } else {
#                $q = "";
#            };
#            $q .= join "", @post_data;
#            $uri->query( $q );
#        };
#
#    } elsif( $options->{ head }) {
#        $method = 'HEAD';
#
#    } elsif( @post_data ) {
#        $method = 'POST';
#        $body = join "", @post_data;
#        unshift @headers, 'Content-Type: application/x-www-form-urlencoded';
#
#    } else {
#        $method ||= 'GET';
#    };

#    if( defined $body ) {
#        unshift @headers, sprintf 'Content-Length: %d', length $body;
#    };

#    my %headers = (
#        %default_headers,
#        'Host' => $uri->host_port,
#        (map { /^\s*([^:\s]+)\s*:\s*(.*)$/ ? ($1 => $2) : () } @headers),
#    );

=head2 C<< ->as_request >>

    $ua->request( $r->as_request );

Returns an equivalent L<HTTP::Request> object

=cut

sub _explode_headers( $self ) {
    my @res =
    map { my $h = $_;
          my $v = $self->headers->{$h};
          ref $v ? (map { $h => $_ } @$v)
                 : ($h => $v)
         } keys %{ $self->headers };
}

=head2 C<< $r->as_request >>

    my $r = $curl->as_request;

Returns a L<HTTP::Request> object that represents
the Curl options.

=cut

sub as_request( $self ) {
    HTTP::Request->new(
        $self->method => $self->uri,
        [ $self->_explode_headers() ],
        $self->body(),
    )
};

sub _fill_snippet( $self, $snippet ) {
    # Doesn't parse parameters, yet
    $snippet =~ s!\$self->(\w+)!$self->$1!ge;
    $snippet
}

sub _init_cookie_jar_lwp( $self ) {
    if( my $fn = $self->cookie_jar ) {
        my $save = $self->cookie_jar_options->{'write'} ? 1 : 0;
        return {
            preamble => [
                "use Path::Tiny;",
                "use HTTP::Cookies;",
            ],
            code => \"HTTP::Cookies->new(\n    file => path('$fn'),\n    autosave => $save,\n)",
            postamble => [
                #"path('$fn')->spew(\$ua->cookie_jar->dump_cookies())",
            ],
        };
    }
}

sub _init_cookie_jar_tiny( $self ) {
    if( my $fn = $self->cookie_jar ) {
        my $save = $self->cookie_jar_options->{'write'};
        return {
            preamble => [
                "use Path::Tiny;",
                "use HTTP::CookieJar;",
            ],
            code => \"HTTP::CookieJar->new->load_cookies(path('$fn')->lines),",
            postamble => [
            $save ?
                  ("path('$fn')->spew(\$ua->cookie_jar->dump_cookies())")
                : (),
            ],
        };
    }
}

sub _pairlist( $self, $l, $prefix = "    " ) {
    return join ",\n",
        pairmap { my $v = ! ref $b ? qq{'$b'}
                          : ref $b eq 'SCALAR' ? $$b
                          : ref $b eq 'ARRAY' ? '[' . join( ", ", map {qq{'$_'}} @$b ) . ']'
                          : die "Unknown type of $b";
                  qq{$prefix'$a' => $v}
                } @$l
}

sub _build_lwp_headers( $self, $prefix = "    ", %options ) {
    # This is so we create the standard header order in our output
    my @h = $self->_explode_headers;
    my $h = HTTP::Headers->new( @h );
    $h->remove_header( @{$options{implicit_headers}} );

    # also skip the Host: header if it derives from $uri
    my $val = $h->header('Host');
    if( $val and ($val eq $self->uri->host_port
                  or $val eq $self->uri->host   )) {
                        # trivial host header
        $h->remove_header('Host');
    };

    $self->_pairlist([ $h->flatten ], $prefix);
}

sub _build_tiny_headers( $self, $prefix = "    ", %options ) {
    delete $self->{headers}->{Host};
    my @result = (%{ $self->headers});
    $self->_pairlist( \@result, $prefix );
}


=head2 C<< $r->as_snippet( %options ) >>

    print $r->as_snippet( type => 'LWP' );

Returns a code snippet that returns code to create an equivalent
L<HTTP::Request> object and to perform the request using L<WWW::Mechanize>.

This is mostly intended as a convenience function for creating Perl demo
snippets from C<curl> examples.

=head3 Options

=over 4

=item B<implicit_headers>

Arrayref of headers that will not be output.

Convenient values are ['Content-Length']

=item B<type>

    type => 'Tiny',

Type of snippet. Valid values are C<LWP> for L<LWP::UserAgent>
and C<Tiny> for L<HTTP::Tiny>.

=back

=cut

sub as_snippet( $self, %options ) {
    my $type = delete $options{ type } || 'LWP';
    if( 'LWP' eq $type ) {
        $self->as_lwp_snippet( %options )
    } elsif( 'Tiny' eq $type ) {
        $self->as_http_tiny_snippet( %options )
    } else {
        croak "Unknown type '$type'.";
    }
}

sub as_lwp_snippet( $self, %options ) {
    $options{ prefix } ||= '';
    $options{ implicit_headers } ||= [];

    my @preamble;
    my @postamble;
    push @preamble, @{ $options{ preamble } } if $options{ preamble };
    push @postamble, @{ $options{ postamble } } if $options{ postamble };
    my @setup_ua = ('');

    my $request_args = join ", ",
                                 '$r',
                           $self->_pairlist([
                               maybe ':content_file', $self->output
                           ], '')
                       ;
    my $init_cookie_jar = $self->_init_cookie_jar_lwp();
    if( my $p = $init_cookie_jar->{preamble}) {
        push @preamble, @{$p}
    };

    my $constructor_args = join ",",
                           $self->_pairlist([
                                        send_te => 0,
                               maybe timeout    => $self->timeout,
                               maybe cookie_jar => $init_cookie_jar->{code},
                           ], '')
                           ;
    if( defined( my $credentials = $self->credentials )) {
        my( $user, $pass ) = split /:/, $credentials, 2;
        my $setup_credentials = sprintf qq{\$ua->credentials("%s","%s");},
            quotemeta $user,
            quotemeta $pass;
        push @setup_ua, $setup_credentials;
    };
    if( $self->insecure ) {
        push @preamble, 'use IO::Socket::SSL;';
        my $setup_insecure = q{$ua->ssl_opts( SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, SSL_hostname => '', verify_hostname => 0 );};
        push @setup_ua, $setup_insecure;
    };

    if( $self->show_error ) {
        push @postamble,
            '    die $res->message if $res->is_error;',
    } elsif( $self->fail ) {
        push @postamble,
            '    exit 1 if !$res->{success};',
    };

    @setup_ua = ()
        if @setup_ua == 1;

    @preamble = map { "$options{prefix}    $_\n" } @preamble;
    @postamble = map { "$options{prefix}    $_\n" } @postamble;
    @setup_ua = map { "$options{prefix}    $_\n" } @setup_ua;

    return <<SNIPPET;
@preamble
    my \$ua = LWP::UserAgent->new($constructor_args);@setup_ua
    my \$r = HTTP::Request->new(
        '@{[$self->method]}' => '@{[$self->uri]}',
        [
@{[$self->_build_lwp_headers('            ', %options)]}
        ],
        @{[$self->_build_quoted_body()]}
    );
    my \$res = \$ua->request( $request_args );
@postamble
SNIPPET
};

sub as_http_tiny_snippet( $self, %options ) {
    $options{ prefix } ||= '';
    $options{ implicit_headers } ||= [];

    push @{ $options{ implicit_headers }}, 'Host'; # HTTP::Tiny dislikes that header

    my @preamble;
    my @postamble;
    push @preamble, @{ $options{ preamble } } if $options{ preamble };
    push @postamble, @{ $options{ postamble } } if $options{ postamble };
    my @setup_ua = ('');

    my $request_args = join ", ",
                                 '$r',
                           $self->_pairlist([
                               maybe ':content_file', $self->output
                           ], '')
                       ;
    my $init_cookie_jar = $self->_init_cookie_jar_tiny();
    if( my $p = $init_cookie_jar->{preamble}) {
        push @preamble, @{$p}
    };

    my @ssl;
    if( $self->insecure ) {
    } else {
        push @ssl, verify_SSL => 1;
    };
    if( $self->show_error ) {
        push @postamble,
            '    die $res->{reason} if !$res->{success};',
    } elsif( $self->fail ) {
        push @postamble,
            '    exit 1 if !$res->{success};',
    };
    my $constructor_args = join ",",
                           $self->_pairlist([
                                     @ssl,
                               maybe timeout => $self->timeout,
                               maybe cookie_jar => $init_cookie_jar->{code},
                           ], '')
                           ;
    if( defined( my $credentials = $self->credentials )) {
        my( $user, $pass ) = split /:/, $credentials, 2;
        my $setup_credentials = sprintf qq{\$ua->credentials("%s","%s");},
            quotemeta $user,
            quotemeta $pass;
        push @setup_ua, $setup_credentials;
    };

    @setup_ua = ()
        if @setup_ua == 1;

    @preamble = map { "$options{prefix}    $_\n" } @preamble;
    @postamble = map { "$options{prefix}    $_\n" } @postamble;
    @setup_ua = map { "$options{prefix}    $_\n" } @setup_ua;

    my @content = $self->_build_quoted_body();
    if( grep {/\S/} @content ) {
        unshift @content, 'content => ',
    };

    return <<SNIPPET;
@preamble
    my \$ua = HTTP::Tiny->new($constructor_args);@setup_ua
    my \$res = \$ua->request(
        '@{[$self->method]}' => '@{[$self->uri]}',
        {
          headers => {
@{[$self->_build_tiny_headers('            ', %options)]}
          },
          @content
        },
    );
@postamble
SNIPPET
};

=head2 C<< $r->as_curl >>

    print $r->as_curl;

Returns a curl command line representing the request

This is convenient if you started out from something else or want a canonical
representation of a curl command line.

=over 4

=item B<curl>

The curl command to be used. Default is C<curl>.

=back

=cut

# These are what curl uses as defaults, not what Perl should use as default!
our %curl_header_defaults = (
    'Accept'          => '*/*',
    #'Accept-Encoding' => 'deflate, gzip',
    # For Perl, use HTTP::Message::decodable() instead of the above list
);

sub as_curl($self,%options) {
    $options{ curl } = 'curl'
        if ! exists $options{ curl };
    $options{ long_options } = 1
        if ! exists $options{ long_options };

    my @request_commands;

    if( $self->method eq 'HEAD' ) {
        push @request_commands,
            $options{ long_options } ? '--head' : '-I';

    } elsif( $self->method ne 'GET' ) {
        push @request_commands,
            $options{ long_options } ? '--request' : '-X',
            $self->method;
    };

    if( scalar keys %{ $self->headers }) {
        for my $h (sort keys %{$self->headers}) {
            my $v = $self->headers->{$h};

            my $default;
            if( exists $curl_header_defaults{ $h }) {
                $default = $curl_header_defaults{ $h };
            };

            if( ! ref $v ) {
                $v = [$v];
            };
            for my $val (@$v) {
                if( !defined $default or $val ne $default ) {

                    # also skip the Host: header if it derives from $uri
                    if( $h eq 'Host' and ($val eq $self->uri->host_port
                                          or $val eq $self->uri->host   )) {
                        # trivial host header
                    } elsif( $h eq 'User-Agent' ) {
                        push @request_commands,
                            $options{ long_options } ? '--user-agent' : '-A',
                            $val;
                    } else {
                        push @request_commands,
                            $options{ long_options } ? '--header' : '-h',
                            "$h: $val";
                    };
                };
            };
        };
    };

    if( my $body = $self->body ) {
        push @request_commands,
            $options{ long_options } ? '--data-raw' : '--data-raw',
            $body;
    };

    push @request_commands, $self->uri;

    return
        #(defined $options{ curl } ? $options{curl} : () ),
        @request_commands;
}

# These are what wget uses as defaults, not what Perl should use as default!
our %wget_header_defaults = (
    'Accept'          => '*/*',
    'Accept-Encoding' => 'identity',
    'User-Agent' => 'Wget/1.21',
    'Connection' => 'Keep-Alive',
);

sub as_wget($self,%options) {
    $options{ wget } = 'wget'
        if ! exists $options{ wget };
    $options{ long_options } = 1
        if ! exists $options{ long_options };

    my @request_commands;

    if( $self->method ne 'GET' ) {
        if( $self->method eq 'POST' and $self->body ) {
            # This is implied by '--post-data', below
        } else {
            push @request_commands,
                '--method' => $self->method;
        };
    };

    if( scalar keys %{ $self->headers }) {
        my %h = %{ $self->headers };

        # "--no-cache" implies two headers, Cache-Control and Pragma
        my $is_cache =    exists $h{ 'Pragma' }
                       && exists $h{ 'Cache-Control' }
                       && $h{ 'Cache-Control' } =~ /^no-cache\b/
                       && $h{ 'Pragma' } eq 'no-cache'
                       ;
        if( $is_cache ) {
            delete $h{ 'Pragma' };
            delete $h{ 'Cache-Control' };
            push @request_commands, '--no-cache';
        };

        for my $name (sort keys %h) {
            my $v = $h{ $name };

            my $default;
            if( exists $wget_header_defaults{ $name }) {
                $default = $wget_header_defaults{ $name };
            };

            if( ! ref $v ) {
                $v = [$v];
            };
            for my $val (@$v) {
                if( !defined $default or $val ne $default ) {
                    # also skip the Host: header if it derives from $uri
                    if( $name eq 'Host' and ($val eq $self->uri->host_port
                                          or $val eq $self->uri->host   )) {
                        # trivial host header, ignore
                    } elsif( $name eq 'User-Agent' ) {
                        push @request_commands,
                            '--user-agent',
                            $val;
                    } else {
                        push @request_commands,
                            '--header',
                            "$name: $val";
                    };
                };
            };
        };
    };

    if( my $body = $self->body ) {
        if( $self->method eq 'POST' ) {
            push @request_commands,
                '--post-data',
                $body;
        } else {
            push @request_commands,
                '--body-data',
                $body;
        };
    };

    push @request_commands, $self->uri;

    return
        #(defined $options{ curl } ? $options{curl} : () ),
        @request_commands;
}


=head2 C<< $r->clone >>

Returns a shallow copy of the object

=cut

sub clone( $self, %options ) {
    (ref $self)->new( %$self, %options )
}

1;

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

Copyright 2018-2021 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
