package Klonk::Routes 0.01;
use Klonk::pragma;
use Carp qw(croak);
use HTML::Blitz ();
use Klonk::Env ();

our %routes;

fun _parse_route($pattern) {
    my @segments;
    while () {
        $pattern =~ m{\G ( / [^`*]*+ (?: `[`*] [^`*]*+ )*+ ) }xgc
            or croak "Malformed route pattern (must start with '/'): '$pattern'";
        my $raw = $1;
        $raw =~ s/`([`*])/$1/g;
        push @segments, $raw;
        if ($pattern =~ m{\G \z}x) {
            last;
        }
        if ($pattern =~ m{\G `}x) {
            croak "Malformed route pattern ('`' must be followed by '`' or '*'): '$pattern'";
        }
        if ($pattern =~ m{\G (?<= / ) \*\* \z}xgc) {
            push @segments, undef;
            last;
        }
        if ($pattern =~ m{\G (?<= / ) \* }xgc) {
            if ($pattern =~ m{\G \z}x) {
                push @segments, '';
                last;
            }
            $pattern =~ m{\G / }x
                or croak "Malformed route pattern ('*' must be followed by '/'): '$pattern'";
        } else {
            croak "Malformed route pattern ('*' must be preceded by '/') :'$pattern'";
        }
    }
    \@segments
}

my $dispatch_info;

fun mkroute($pattern, %handlers) {
    my (undef, $filename, $line) = caller;
    my $location = [$filename, $line];

    $dispatch_info = undef;
    my $def = $routes{$pattern} //= do {
        my $chunks = _parse_route $pattern;
        my $weight = join('', map chr(defined $_ ? 1 + length : 0), @$chunks) . "\x{7fff_ffff}";
        #say STDERR sprintf "weight(%s): %vd", $pattern, $weight;
        +{
            chunks   => $chunks,
            weight   => $weight,
            resource => {},
        }
    };

    for my $pmethod (sort keys %handlers) {
        my $method = uc $pmethod;
        my $resource = $def->{resource};
        exists $resource->{$method}
            and croak "Redefinition of $method $pattern (previously defined at $resource->{$method}{location}[0] line $resource->{$method}{location}[1])";
        $resource->{$method} = {
            location => $location,
            handler  => $handlers{$pmethod},
        };
    }
}

my $redirect_template = do {
    my $blitz = HTML::Blitz->new(
        { dummy_marker_re => qr/\bXXX\b/ },
        [ 'a[href=URL]' =>
            [ 'set_attribute_var', href => 'url' ],
            [ 'replace_inner_var', 'url' ],
        ],
        [ 'title, h1' =>
            [ 'replace_inner_text', "308 Permanent Redirect" ]
        ],
    );

    my $template = $blitz->apply_to_html(
        '(inline_redirect)',
        '<!doctype html><title>XXX</title><h1>XXX</h1><p>See <a href=URL>XXX</a></p>'
    );

    $template->compile_to_sub
};

fun _routes_prepare() {
    my $gen = 'a';
    my %mapping;
    my $regex = join '|',
        map {
            my @chunks = @{$_->[2]};
            my $rest = defined $chunks[-1] ? 0 : (pop @chunks, 1);
            my $re = join '([^/]*+)', map quotemeta, @chunks;
            $re .= '(.*+)' if $rest;
            $re .= "(*:$gen)";
            $mapping{$gen++} = $_->[0];
            $re
        }
        sort { $b->[1] cmp $a->[1] || $a->[0] cmp $b->[0] }
        map [$_, @{$routes{$_}}{'weight', 'chunks'}],
        keys %routes;
    $regex = '(?!)' if $regex eq '';
    #say STDERR ">>> $regex";
    #use re 'debugcolor';
    [
        qr/\A(?|$regex)\z/s,
        \%mapping,
    ]
}

my %text_types = (
    'css'    => 'text/css',
    'csv'    => 'text/csv',
    'html'   => 'text/html',
    'js'     => 'text/javascript',
    'json'   => 'application/json',
    'jsonld' => 'application/ld+json',
    'text'   => 'text/plain',
);

my %bin_types = (
    'bin'  => 'application/octet-stream',
    'jpeg' => 'image/jpeg',
    'png'  => 'image/png',
    'webp' => 'image/webp',
);

fun _postprocess($ret) {
    my $status = 200;
    if ($ret->[0] =~ /\A\d{3}\z/a) {
        $status = shift @$ret;
    }
    my ($itype, $body, $headers) = @$ret;

    for my $spec (
        [\%text_types, 1],
        [\%bin_types, 0],
    ) {
        my ($type_map, $encode_p) = @$spec;
        if (my $type = $type_map->{$itype}) {
            if ($encode_p) {
                utf8::encode $body unless ref $body;
                $type .= '; charset=utf-8';
            }
            my $length = ref $body
                ? -s $body || undef
                : length $body;
            return [
                $status,
                [
                    'content-type' => $type,
                    defined $length
                        ? ('content-length' => $length)
                        : (),
                    map {
                        my $k = $_;
                        my $v = $headers->{$k};
                        map +($k => $_), ref($v) eq 'ARRAY' ? @$v : $v
                    }
                    keys %{$headers // {}}
                ],
                ref $body ? $body : [ $body ]
            ];
        }
    }
    
    die "Unknown content type: $itype";
}

my $booted;
my @init;

fun on_init($fun) {
    croak "Can't call on_init() after boot()" if $booted;
    push @init, $fun;
}

fun dispatch($env) {
    my $kenv = Klonk::Env->new($env);
    my $req_path   = $env->{PATH_INFO};
    my $req_method = $env->{REQUEST_METHOD};

    $dispatch_info //= _routes_prepare;
    local our $REGMARK;
    if (my @captures = $req_path =~ /$dispatch_info->[0]/) {
        my $pattern = $dispatch_info->[1]{$REGMARK};
        my $meta = $routes{$pattern};
        splice @captures, $#{$meta->{chunks}};
        my $resource = $meta->{resource};
        if (my $info = $resource->{$req_method}) {
            my $handler = $info->{handler};
            return _postprocess $handler->($kenv, @captures);
        }

        if ($req_method eq 'HEAD' && (my $info = $resource->{GET})) {
            my $ret = _postprocess $info->{handler}($kenv, @captures);
            return [ 204, $ret->[1], [] ];
        }

        my $allowed_methods = join ', ', sort keys %$resource;
        if ($req_method eq 'OPTIONS') {
            return [ 204, [ 'allow' => $allowed_methods ], [] ];
        }

        return _postprocess [
            405,
            'html',
            "<!doctype html><title>405 Method Not Allowed</title><h1>405 Method Not Allowed</h1>",
            { allow => $allowed_methods }
        ];
    }

    if ($req_path !~ m{/\z} && "$req_path/" =~ /$dispatch_info->[0]/) {
        my $uri = $env->{REQUEST_URI};
        $uri =~ s{(?=[?#])|\z}{/};
        return _postprocess [
            308,
            'html',
            $redirect_template->({ url => $uri }),
            {
                'location' => $uri,
            },
        ];
    }

    return _postprocess [
        404,
        'html',
        "<!doctype html><title>404 Not Found</title><h1>404 Not Found</h1>",
    ];
}

fun boot() {
    $booted = 1;
    my @fun = splice @init;
    for my $fun (@fun) {
        $fun->();
    }

    \&dispatch
}

1
__END__

=head1 NAME

Klonk::Routes - define routes and dispatch requests

=head1 SYNOPSIS

    use Klonk::Routes;  # no exports

    Klonk::Routes::on_init sub () {
        ...
    };

    Klonk::Routes::mkroute '/widget/*', (
        GET => sub ($env, $arg) {
            ...
        },
    );

    # in your app.psgi
    Klonk::Routes::boot;

=head1 DESCRIPTION

This module lets you define routes and dispatch requests. It is the main module
to use and contains the most serviceable parts. It does not export anything, so
all calls to functions in this module have to use their fully-qualified names.

=head2 Functions

=over

=item C<< Klonk::Routes::on_init $subroutine >>

Arranges for C<$subroutine> (a coderef) to be called once, before any requests
are dispatched. This is useful if you want your application modules to be
preloaded in a separate process, but still perform initialization "globally" in
each worker process. This can be used e.g. to connect to a database outside of
any particular request, but without accidentally sharing a connection handle
across multiple processes.

=item C<< Klonk::Routes::mkroute $pattern, %handlers >>

Defines a resource by specifying a path pattern. This can be a simple path like
C</> or C</app/index.php>, but it can also include wildcards like
C</widget/*/chapter/*>.

Pattern matching details: The C<*> wildcard matches any sequence of non-/
characters in the request path. The C<**> wildcard matches any sequence of any
characters, but can only be used at the end of a pattern. Both wildcards only
match full path components, i.e. they can only be used after (and in the case
of C<*>, followed by) a C</>. It is possible to match a literal C<*> in the
request path by putting C<`*`> in the pattern; similarly, a literal C<`> in the
request path can be specified as C<``>.

The C<%handlers> argument (a hash initializer) maps request methods (or "HTTP
verbs") such as C<GET> or C<POST> to handler functions. Each handler function
is called with the request environment (a L<Klonk::Env> object) as its first
argument followed by all request path segments matched by wildcards in the
pattern.

A C<HEAD> handler (unless explicitly specified) is automatically synthesized
from a C<GET> handler.

Handlers must return a reference to an array of 2 to 4 elements:

    [ $status_opt, $type, $body, $headers_opt ]

=over

=item C<$status_opt>

Optional (detaults to C<200>). If specified, must be a three-digit HTTP
response status code (like C<200> or C<404>).

=item C<$type>

Response type. Must be a text type (C<css>, C<csv>, C<html>, C<js>, C<json>,
C<jsonld>, C<text>), image type (C<jpeg>, C<png>, C<webp>), or the generic
C<bin> binary type (maps to C<application/octet-stream>).

Text types are always encoded as UTF-8.

=item C<$body>

Response body. Must be either a string or an open filehandle.

=item C<$headers_opt>

Optional (defaults to C<{}>). A reference to a hash of additional reponse
headers. Values must be either strings or array references; the latter are
expanded to multiple headers with the same key:

    {
        'Set-Cookie' => ['foo=1', 'bar=2'],
        # sends two response headers:
        #   Set-Cookie: foo=1
        #   Set-Cookie: bar=2
    }

C<Content-Type> and C<Content-Length> headers should not be set here as they
are calculated automatically based on C<$type> and C<$body>.

=back

=item C<< Klonk::Routes::boot >>

This should be called once at the end of your main script. It initializes the
system and returns a L<PSGI application|PSGI/Application> for all routes
previously defined.

=back
