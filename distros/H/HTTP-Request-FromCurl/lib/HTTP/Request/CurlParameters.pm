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

our $VERSION = '0.48';

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

C<auth>

    auth => 'basic'

The authentication method to use.

=cut

has auth => (
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

C<unix_socket>

    unix_socket => '/var/run/docker/docker.sock'

The timeout for the request

=cut

has unix_socket => (
    is => 'ro',
);

=item *

C<local_address>

    local_address => '192.0.2.116'

The local network address to bind to when making the request

=cut

has local_address => (
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

C<cert>

    cert => '/path/to/certificate',

Use the certificate file for SSL

=cut

has cert => (
    is => 'ro',
);

=item *

C<capath>

    capath => '/path/to/cadir/',

Use the certificate directory for SSL

=cut

has capath => (
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

sub _init_cookie_jar_mojolicious( $self ) {
    if( my $fn = $self->cookie_jar ) {
        my $save = $self->cookie_jar_options->{'write'};
        return {
            preamble => [
            #    "use Path::Tiny;",
                "use Mojo::UserAgent::CookieJar;",
            ],
            code => \"Mojo::UserAgent::CookieJar->new,",
            postamble => [
            #$save ?
            #      ("path('$fn')->spew(\$ua->cookie_jar->dump_cookies())")
            #    : (),
            ],
        };
    }
}

sub _pairlist( $self, $l, $prefix = "    " ) {
    return join ",\n",
        pairmap { my $v = ! ref $b ? qq{'$b'}
                          : ref $b eq 'SCALAR' ? $$b
                          : ref $b eq 'ARRAY'  ? '[' . join( ", ", map {qq{'$_'}} @$b ) . ']'
                          : ref $b eq 'HASH'   ? '{' . $self->_pairlist([ map { $_ => $b->{$_} } sort keys %$b ]) . '}'
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

sub _build_mojolicious_headers( $self, $prefix = "    ", %options ) {
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

    @h = $h->flatten;
    my %h;
    my @order;
    while( @h ) {
        my ($k,$v) = splice(@h,0,2);
        if( ! exists $h{ $k }) {
            # Fresh value
            $h{ $k } = $v;
            push @order, $k;
        } elsif( ! ref $h{$k}) {
            # Second value
            $h{ $k } = [$h{$k}, $v];
        } else {
            # Multiple values
            push @{$h{ $k }}, $v;
        }
    };

    $self->_pairlist([ map { $_ => $h{ $_ } } @order ], $prefix);
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

Type of snippet. Valid values are C<LWP> for L<LWP::UserAgent>,
C<Mojolicious> for L<Mojolicious::UserAgent>
and C<Tiny> for L<HTTP::Tiny>.

=back

=cut

sub as_snippet( $self, %options ) {
    my $type = delete $options{ type } || 'LWP';
    if( 'LWP' eq $type ) {
        $self->as_lwp_snippet( %options )
    } elsif( 'Tiny' eq $type ) {
        $self->as_http_tiny_snippet( %options )
    } elsif( 'Mojolicious' eq $type ) {
        $self->as_mojolicious_snippet( %options )
    } else {
        croak "Unknown type '$type'.";
    }
}

sub as_lwp_snippet( $self, %options ) {
    $options{ prefix } ||= '';
    $options{ implicit_headers } ||= [];

    my @preamble;
    my @postamble;
    my %ssl_options;
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

    if( $self->insecure ) {
        push @preamble, 'use IO::Socket::SSL;';
        $ssl_options{ SSL_verify_mode } = \'IO::Socket::SSL::SSL_VERIFY_NONE';
        $ssl_options{ SSL_hostname    } = '';
        $ssl_options{ verify_hostname } = '';
    };

    if( $self->cert ) {
        push @preamble, 'use IO::Socket::SSL;';
        $ssl_options{ SSL_ca_file } = $self->cert;
    };
    if( $self->capath ) {
        push @preamble, 'use IO::Socket::SSL;';
        $ssl_options{ SSL_ca_path } = $self->capath;
    };
    my $constructor_args = join ",",
                           $self->_pairlist([
                                     send_te => 0,
                               maybe local_address => $self->local_address,
                               maybe timeout       => $self->timeout,
                               maybe cookie_jar    => $init_cookie_jar->{code},
                               maybe SSL_options   => keys %ssl_options ? \%ssl_options : undef,
                           ], '')
                           ;
    if( defined( my $credentials = $self->credentials )) {
        my( $user, $pass ) = split /:/, $credentials, 2;
        my $setup_credentials = sprintf qq{\$ua->credentials("%s","%s");},
            quotemeta $user,
            quotemeta $pass;
        push @setup_ua, $setup_credentials;
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
    my %ssl_options;
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
    if( $self->cert ) {
        push @preamble, 'use IO::Socket::SSL;';
        $ssl_options{ SSL_ca_file } = $self->cert;
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
                               maybe timeout       => $self->timeout,
                               maybe local_address => $self->local_address,
                               maybe cookie_jar    => $init_cookie_jar->{code},
                               maybe SSL_options   => keys %ssl_options ? \%ssl_options : undef,
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

sub as_mojolicious_snippet( $self, %options ) {
    $options{ prefix } ||= '';
    $options{ implicit_headers } ||= [];

    my @preamble;
    my @postamble;
    my %ssl_options;
    push @preamble, @{ $options{ preamble } } if $options{ preamble };
    push @postamble, @{ $options{ postamble } } if $options{ postamble };
    my @setup_ua = ('');

    my $request_args = join ", ",
                                 '$r',
                           $self->_pairlist([
                               maybe ':content_file', $self->output
                           ], '')
                       ;
    my $init_cookie_jar = $self->_init_cookie_jar_mojolicious();
    if( my $p = $init_cookie_jar->{preamble}) {
        push @preamble, @{$p}
    };

    my @ssl;
    if( $self->insecure ) {
        push @ssl, insecure => 1,
    };
    if( $self->cert ) {
        push @ssl, cert => $self->cert,
    };
    if( $self->show_error ) {
        push @postamble,
            '    die $res->message if $res->is_error;',
    } elsif( $self->fail ) {
        push @postamble,
            '    exit 1 if !$res->is_error;',
    };
    my $socket_options = {};
    if( my $host = $self->local_address ) {
        $socket_options->{ LocalAddr } = $host;
    }
    my $constructor_args = join ",",
                           $self->_pairlist([
                                     @ssl,
                                     keys %$socket_options ? $socket_options : (),
                               maybe request_timeout    => $self->timeout,
                               maybe local_address => $self->local_address,
                               maybe cookie_jar    => $init_cookie_jar->{code},
                               maybe SSL_options   => keys %ssl_options ? \%ssl_options : undef,
                           ], '')
                           ;
    if( defined( my $credentials = $self->credentials )) {
        my( $user, $pass ) = split /:/, $credentials, 2;
        my $setup_credentials = sprintf qq{\$ua->userinfo("%s","%s");},
            quotemeta $user,
            quotemeta $pass;
        push @setup_ua, $setup_credentials;
    };

    @setup_ua = ()
        if @setup_ua == 1;

    @preamble = map { "$options{prefix}    $_\n" } @preamble;
    @postamble = map { "$options{prefix}    $_\n" } @postamble;
    @setup_ua = map { "$options{prefix}    $_\n" } @setup_ua;

    my $content = $self->_build_quoted_body();
    #if( $content ) {
    #    $content = qq{"} . quotemeta($content) . qq{"};
    #};

    return <<SNIPPET;
@preamble
    my \$ua = Mojo::UserAgent->new($constructor_args);@setup_ua
    my \$tx = \$ua->build_tx(
        '@{[$self->method]}' => '@{[$self->uri]}',
        {
@{[$self->_build_mojolicious_headers('            ', %options)]}
        },
        $content
    );
    my \$res = \$ua->start(\$tx)->result;
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

Copyright 2018-2023 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
