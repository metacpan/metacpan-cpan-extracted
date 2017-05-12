package Mason::ApacheTest;

use strict;
use warnings;

use Apache::test qw( have_httpd have_module );
use File::Basename qw( dirname );
use File::Path qw( mkpath rmtree );
use File::Spec;
use Module::Build;
use Test::More;

use lib 'inc';

use base 'Exporter';
our @EXPORT_OK = qw( require_libapreq require_cgi require_apache_filter chmod_data_dir );


my $TestConfig;

INIT
{
    $TestConfig = Module::Build->current()->notes()->{apache_test_conf};

    unless ( $TestConfig
             && defined $TestConfig->{apache_dir}
             && -d $TestConfig->{apache_dir} )
    {
        plan skip_all =>
            '$TestConfig->{is_maintainer} is not true or '
            . '$TestConfig->{apache_dir} is not a directory';
    }

    unless ( have_httpd() )
    {
        plan skip_all => 'Apache::test::have_httpd() returned a false value';
    }
}

sub require_libapreq
{
    my $version = _apache_version();

    my $module = $version == 1 ? 'Apache::Request' : 'Apache2::Request';

    unless ( eval "use $module; 1" )
    {
        plan skip_all => "These tests require the $module module.";
    }
}

sub require_cgi
{
    unless ( eval 'use CGI 3.08; 1' )
    {
        plan skip_all => 'These tests required CGI.pm 3.08 or greater.';
    }
}

sub require_apache_filter
{
    my $version = _apache_version();

    unless ( eval 'use Apache::Filter; 1' && $version == 1 )
    {
        plan skip_all => 'These tests required Apache::Filter and mod_perl 1.';
    }
}

sub _apache_version
{
    my $apache_bin = _apache_bin();

    my ($version) = `$apache_bin -v` =~ m{version: Apache/(\d)};

    die "Could not determine Apache version"
        unless $version;

    return $version;
}

sub _apache_bin
{
    return File::Spec->catfile( $TestConfig->{apache_dir}, 'httpd' );
}

sub chmod_data_dir
{
    # This is a hack but otherwise the multi-conf tests fail if the
    # Apache server runs as any user other than root.  In real life, a
    # user using the multi-config option with httpd.conf must handle
    # the file permissions manually.
    if ( $> == 0 || $< == 0 )
    {
        chmod 0777, File::Spec->catdir( $TestConfig->{apache_dir}, 'data' );
    }
}

sub run_tests
{
    my $class = shift;
    my %p     = @_;

    # Needed for Apache::test->fetch() to work
    local $ENV{PORT} = $TestConfig->{port};

    _write_test_comps();

    my @tests = $class->_tests(%p);

    my $count = 0;
    $count++ for grep { $_->{expect} || $_->{regex} } @tests;
    $count++ for map { $_->{extra} ? @{ $_->{extra} } : () } @tests;

    plan tests => $count;

    _kill_httpd();

    _start_httpd( $p{apache_define} );

    _cleanup_data_dir();

    _run_test( \%p, $_ ) for @tests;

    _kill_httpd();
}

sub _write_test_comps
{
    _write_comp( 'basic', <<'EOF',
Basic test.
2 + 2 = <% 2 + 2 %>.
uri = <% $r->uri =~ /basic$/ ? '/basic' : $r->uri %>.
method = <% $r->method %>.


EOF
              );

    _write_comp( 'headers', <<'EOF',


% $r->headers_out->{'X-Mason-Test'} = 'New value 2';
Blah blah
blah
% $r->headers_out->{'X-Mason-Test'} = 'New value 3';
<%init>
$r->headers_out->{'X-Mason-Test'} = 'New value 1';
$m->abort if $blank;
</%init>
<%args>
$blank=>0
</%args>
EOF
              );

    _write_comp( 'cgi_object', <<'EOF',
<% UNIVERSAL::isa(eval { $m->cgi_object } || undef, 'CGI') ? 'CGI' : 'NO CGI' %><% $@ || '' %>
EOF
              );

    _write_comp( 'params', <<'EOF',
% foreach (sort keys %ARGS) {
<% $_ %>: <% ref $ARGS{$_} ? join ', ', sort @{ $ARGS{$_} }, 'array' : $ARGS{$_} %>
% }
EOF
              );

    _write_comp( '_underscore', <<'EOF',
I am underscore.
EOF
              );

    _write_comp( 'die', <<'EOF',
% die 'Mine heart is pierced';
EOF
              );

    _write_comp( 'apache_request', <<'EOF',
% if ($r->isa('Apache::Request') || $r->isa('Apache2::Request')) {
Apache::Request
% }
EOF
                  );

    _write_comp( 'multiconf1/foo', <<'EOF',
I am foo in multiconf1
comp root is <% $m->interp->comp_root =~ m,/comps/multiconf1$, ? 'multiconf1' : $m->interp->comp_root %>
EOF
              );

    _write_comp( 'multiconf1/autohandler', <<'EOF'
<& $m->fetch_next, autohandler => 'present' &>
EOF
              );

    _write_comp( 'multiconf1/autohandler_test', <<'EOF'
<%args>
$autohandler => 'misnamed'
</%args>
autohandler is <% $autohandler %>
EOF
              );


    _write_comp( 'multiconf2/foo', <<'EOF',
I am foo in multiconf2
comp root is <% $m->interp->comp_root =~ m,/comps/multiconf2$, ? 'multiconf2' : $m->interp->comp_root %>
EOF
              );

    _write_comp( 'multiconf2/dhandler', <<'EOF',
This should not work
EOF
              );

    _write_comp( 'allow_globals', <<'EOF',
% $foo = 1;
% @bar = ( qw( a b c ) );
$foo is <% $foo %>
@bar is <% @bar %>
EOF
              );

    _write_comp( 'decline_dirs', <<'EOF',
decline_dirs is <% $m->ah->decline_dirs %>
EOF
              );

    _write_comp( 'with_dhandler/dhandler', <<'EOF',
% $r->content_type('text/html');
with a dhandler
EOF
              );

    _write_comp( 'with_dhandler_no_ct/dhandler', <<'EOF',
with a dhandler, no content type
EOF
              );

    _write_comp( 'print', <<'EOF',
This is first.
% print "This is second.\n";
This is third.
EOF
              );

    _write_comp( 'r_print', <<'EOF',
This is first.
% $r->print("This is second.\n");
This is third.
EOF
              );

    _write_comp( 'flush_buffer', <<'EOF',
% $m->print("foo\n");
% $m->flush_buffer;
bar
EOF
              );

    _write_comp( 'head_request', <<'EOF',
<%init>
my $x = 1;
foreach (sort keys %ARGS) {
  $r->headers_out->{'X-Mason-HEAD-Test' . $x++} = "$_: " . (ref $ARGS{$_} ? 'is a ref' : 'not a ref' );
}
</%init>
We should never see this.
EOF
              );

    _write_comp( 'redirect', <<'EOF',
% $m->print("\n");  # leading whitespace

<%perl>
$m->scomp('foo');
$m->redirect('/comps/basic');
</%perl>
<%def foo>
fum
</%def>
EOF
              );

    _write_comp( 'internal_redirect', <<'EOF',
<%init>
if ($mod_perl2::VERSION >= 1.99) { require Apache2::SubRequest; }
$r->internal_redirect('/comps/internal_redirect_target?foo=17');
$m->auto_send_headers(0);
$m->clear_buffer;
$m->abort;
</%init>
EOF
              );

    _write_comp( 'subrequest', <<'EOF',
<%init>
# tests can run under various comp_root settings
my $comp_root = $m->interp->comp_root;
$comp_root = $$comp_root[0][1] if ref $comp_root;
my $comp = $comp_root =~ m/comps/ ? '/internal_redirect_target' : '/comps/internal_redirect_target';

$m->clear_buffer;
my $sub = $m->make_subrequest(comp => $comp, args=> [ foo => 17 ]);
$sub->exec;
$m->flush_buffer;
$m->abort(200);
</%init>
EOF
              );

    _write_comp( 'internal_redirect_target', <<'EOF',
The number is <% $foo %>.
<%args>
$foo
</%args>
EOF
              );

    _write_comp( 'error_as_html', <<'EOF',
% my $x = 
EOF
              );

    _write_comp( 'interp_class', <<'EOF',
Interp class: <% ref $m->interp %>
EOF
              );

    _write_comp( 'old_html_escape', <<'EOF',
<% '<>' | old_h %>
EOF
              );

    _write_comp( 'old_html_escape2', <<'EOF',
<% '<>' | old_h2 %>
EOF
              );

    _write_comp( 'uc_escape', <<'EOF',
<% 'upper case' | uc %>
EOF
              );

    _write_comp( 'data_cache_defaults', <<'EOF',
is memory: <% $m->cache->isa('Cache::MemoryCache') ? 1 : 0 %>
namespace: <% $m->cache->get_namespace %>
EOF
              );

    _write_comp( 'test_code_param', <<'EOF',
preprocess changes lc fooquux to FOOQUUX
EOF
              );

    _write_comp( 'explicitly_send_header', <<'EOF',
Sending headers in this comp.
<%perl>
$r->send_http_header() if $r->can('send_http_header');
</%perl>
EOF
              );

    _write_comp( 'cgi_foo_param', <<'EOF',
CGI foo param is <% $r->query->param('foo') %>
EOF
              );

    _write_comp( 'abort_with_ok', <<'EOF',
All is well
% $m->abort(200);
Will not be seen
EOF
              );

    _write_comp( 'abort_with_not_ok', <<'EOF',
All is well
% $m->abort(500);
Will not be seen
EOF
              );

    _write_comp( 'cgi_dh/dhandler', <<'EOF' );
dhandler
dhandler_arg = <% $m->dhandler_arg %>
EOF

    _write_comp( 'cgi_dh/file', <<'EOF' );
file
dhandler_arg = <% $m->dhandler_arg %>
path_info = <% $ENV{PATH_INFO} %>
EOF

    _write_comp( 'cgi_dh/dir/file', '' );
}

sub _write_comp
{
    my $name = shift;
    my $comp = shift;

    my $file = File::Spec->catfile( $TestConfig->{apache_dir}, 'comps', $name );
    my $dir = dirname($file);
    mkpath( $dir, 0, 0755 ) unless -d $dir;

    open my $fh, '>',$file
        or die "Can't write to '$file': $!";

    print $fh $comp;

    close $fh;
}

sub _start_httpd
{
    my $def = shift;
    $def = "-D$def" if $def;

    my $httpd = _apache_bin();
    my $conf_file = File::Spec->catfile( $TestConfig->{apache_dir}, 'conf', 'httpd.conf' );
    my $pid_file = File::Spec->catfile( $TestConfig->{apache_dir}, 'logs', 'httpd.pid' );

    my $cmd ="$httpd $def -f $conf_file";

    diag( "Executing $cmd" );

    system ($cmd)
        and die "Can't start httpd server as '$cmd': $!";

    diag( "Waiting 10 seconds for httpd to start." );

    my $x = 0;
    until ( -e $pid_file )
    {
        sleep (1);
        $x++;
        if ( $x > 10 )
        {
            die "No $pid_file file has appeared after 10 seconds.  ",
                "There is probably a problem with the configuration file that was generated for these tests.";
        }
    }
}

sub _kill_httpd
{
    my $pid_file = File::Spec->catfile( $TestConfig->{apache_dir}, 'logs', 'httpd.pid' );

    return unless -e $pid_file;
    my $pid = _get_pid();

    diag( "Killing httpd process ($pid)" );

    my $result = kill 'TERM', $pid;
    if ( ! $result and $! =~ /no such (?:file|proc)/i )
    {
        # Looks like apache wasn't running, so we're done
        unlink $pid_file
            or warn "Couldn't remove $pid_file: $!";
        return;
    }

    die "Can't kill process $pid: $!" unless $result;

    diag( "Waiting up to 10 seconds for httpd to shut down" );

    my $x = 0;
    while ( -e $pid_file )
    {
        sleep (1);

        $x++;
        if ( $x > 1 )
        {
            $result = kill 'TERM', $pid;
            if ( ! $result and $! =~ /no such (?:file|proc)/i )
            {
                # Looks like apache wasn't running, so we're done
                if ( -e $pid_file )
                {
                    unlink $pid_file
                        or warn "Couldn't remove $pid_file: $!";
                }
                return;
            }
        }

        die "$pid_file file still exists after 10 seconds.  Exiting."
            if $x > 10;
    }
}

sub _get_pid
{
    my $pid_file = File::Spec->catfile( $TestConfig->{apache_dir}, 'logs', 'httpd.pid' );

    open my $fh, '<', $pid_file
        or die "Can't open $pid_file: $!";

    my $pid = <$fh>;
    close $fh;

    chomp $pid;

    return $pid;
}

# by wiping out the subdirectories here we can catch permissions
# issues if some of the tests can't write to the data dir.
sub _cleanup_data_dir
{
    return if $ENV{MASON_NO_CLEANUP};

    my $dir = File::Spec->catdir( $TestConfig->{apache_dir}, 'data' );

    opendir my $dh, $dir
        or die "Can't open $dir dir: $!";

    foreach ( grep { -d File::Spec->catdir( $dir, $_ ) && $_ !~ /^\./ } readdir $dh )
    {
        rmtree( File::Spec->catdir( $TestConfig->{apache_dir}, 'data', $_ ) );
    }

    closedir $dh;
}

sub _tests
{
    my $class = shift;
    my %p     = @_;

    my @sets = @{ $p{test_sets} };

    my @tests;
    for my $set (@sets)
    {
        my $meth = q{_} . $set . '_tests';
        push @tests, $class->$meth(%p);

        my $addl_meth =
              $p{with_handler}
            ? q{_} . $set . '_with_handler_tests'
            : q{_} . $set . '_no_handler_tests';

        push @tests, $class->$addl_meth(%p)
            if $class->can($addl_meth);
    }

    return @tests;
}

sub _standard_tests
{
    shift;
    my %p = @_;

    my @tests =
        ( { path => '/comps/basic',
            expect => <<'EOF',
X-Mason-Test: Initial value
Basic test.
2 + 2 = 4.
uri = /basic.
method = GET.


Status code: 0
EOF
            extra =>
            [ sub { my $response = shift;
                    unlike( $response->content, qr{HTTP/1\.1},
                            'the response for a good component should not contain headers in the body' ); },
            ],
          },
          { path => '/comps/headers',
            expect => <<'EOF',
X-Mason-Test: New value 3


Blah blah
blah
Status code: 0
EOF
          },
          { path => '/comps/headers?blank=1',
            expect => <<'EOF',
X-Mason-Test: New value 1
Status code: 0
EOF
          },
          { path => '/comps/_underscore',
            expect => <<'EOF',
X-Mason-Test: Initial value
I am underscore.
Status code: 0
EOF
          },
          { path  => '/comps/die',
            regex => qr{error.*Mine heart is pierced}s,
          },
          { path => '/comps/params?qs1=foo&qs2=bar&foo=A&foo=B',
            expect => <<'EOF',
X-Mason-Test: Initial value
foo: A, B, array
qs1: foo
qs2: bar
Status code: 0
EOF
          },
          { path => '/comps/params',
            post => { post1 => 'foo',
                      post2 => 'bar',
                      foo   => [ 'A', 'B' ],
                    },
            expect => <<'EOF',
X-Mason-Test: Initial value
foo: A, B, array
post1: foo
post2: bar
Status code: 0
EOF
          },

          { path => '/comps/params?qs1=foo&qs2=bar&mixed=A',
            post => { post1 => 'a',
                      post2 => 'b',
                      mixed => 'B',
                    },
            expect => <<'EOF',
X-Mason-Test: Initial value
mixed: A, B, array
post1: a
post2: b
qs1: foo
qs2: bar
Status code: 0
EOF
          },
          { path => '/comps/print',
            expect => <<'EOF',
X-Mason-Test: Initial value
This is first.
This is second.
This is third.
Status code: 0
EOF
          },
          { path => '/comps/r_print',
            expect => <<'EOF',
X-Mason-Test: Initial value
This is first.
This is second.
This is third.
Status code: 0
EOF
          },
          { path => '/comps/flush_buffer',
            expect => <<'EOF',
X-Mason-Test: Initial value
foo
bar
Status code: 0
EOF
          },
          { path => '/comps/redirect',
            expect => <<'EOF',
X-Mason-Test: Initial value
Basic test.
2 + 2 = 4.
uri = /basic.
method = GET.


Status code: 0
EOF
          },
          { path => '/comps/internal_redirect',
            expect => <<'EOF',
X-Mason-Test: Initial value
The number is 17.
Status code: 0
EOF
          },
          { path => '/comps/subrequest',
            expect => <<'EOF',
X-Mason-Test: Initial value
The number is 17.
Status code: 0
EOF
          },
          { path => '/comps/error_as_html',
            regex => qr{<b>error:</b>.*Error during compilation}s,
            extra =>
            [ sub { my $response = shift;
                    unlike( $response->content, qr{HTTP/1\.1},
                            'the response for a compilation error should not contain headers in the body' ); },
            ],
          },
          { path => '/comps/explicitly_send_header',
            expect => <<'EOF',
X-Mason-Test: Initial value
Sending headers in this comp.
Status code: 0
EOF
          },
        );

    my $expected_class = $p{with_handler} ? 'My::Interp' : 'HTML::Mason::Interp';

    push @tests, { path => '/comps/interp_class',
                   expect => <<"EOF",
X-Mason-Test: Initial value
Interp class: $expected_class
Status code: 0
EOF
                 };

    return @tests;
}

sub _standard_with_handler_tests
{
    shift;
    my %p = @_;

    return ( { path => '/ah=1/comps/headers',
               expect => <<'EOF',
X-Mason-Test: New value 1


Blah blah
blah
Status code: 0
EOF
             },
             { path => '/ah=1/comps/headers?blank=1',
               expect => <<'EOF',
X-Mason-Test: New value 1
Status code: 0
EOF
             },
             { path => '/ah=3/comps/die',
               # error_mode is fatal so we just get a 500
               regex => qr{500 Internal Server Error},
             },
             { path => '/ah=1/comps/print',
               expect => <<'EOF',
X-Mason-Test: Initial value
This is first.
This is second.
This is third.
Status code: 0
EOF
             },
             { path => '/ah=1/comps/r_print',
               expect => <<'EOF',
X-Mason-Test: Initial value
This is first.
This is second.
This is third.
Status code: 0
EOF
             },
             { path => '/ah=1/comps/flush_buffer',
               expect => <<'EOF',
X-Mason-Test: Initial value
foo
bar
Status code: 0
EOF
             },
           );
}

sub _apache_request_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/apache_request',
               expect => <<'EOF',
X-Mason-Test: Initial value
Apache::Request
Status code: 0
EOF
             },
           );
}

sub _apache_request_with_handler_tests
{
    shift;
    my %p = @_;

    return ( { path => '/ah=4/comps/apache_request',
               expect => <<'EOF',
X-Mason-Test: Initial value
Status code: 0
EOF
             },
           );
}

sub _apache_request_no_handler_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/decline_dirs',
               expect => <<'EOF',
X-Mason-Test: Initial value
decline_dirs is 0
Status code: 0
EOF
             },
             { path => '/comps/old_html_escape',
               expect => <<'EOF',
X-Mason-Test: Initial value
&lt;&gt;
Status code: 0
EOF
             },
             { path => '/comps/old_html_escape2',
               expect => <<'EOF',
X-Mason-Test: Initial value
&lt;&gt;
Status code: 0
EOF
             },
             { path => '/comps/uc_escape',
               expect => <<'EOF',
X-Mason-Test: Initial value
UPPER CASE
Status code: 0
EOF
             },
             { path => '/comps/data_cache_defaults',
               expect => <<'EOF',
X-Mason-Test: Initial value
is memory: 1
namespace: foo
Status code: 0
EOF
             },
             { path => '/comps/test_code_param',
               expect => <<"EOF",
X-Mason-Test: Initial value
preprocess changes lc FOOQUUX to FOOQUUX
Status code: 0
EOF
             },
             { path => '/comps/with_dhandler/',
               expect => <<"EOF",
X-Mason-Test: Initial value
with a dhandler
Status code: 0
EOF
             },
           );
}

sub _cgi_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/cgi_object',
               expect => <<'EOF',
X-Mason-Test: Initial value
CGI
Status code: 0
EOF
             },
             { path   => '/comps/head_request?foo=1&bar=1&bar=2',
               method => 'HEAD',
               expect => <<'EOF',
X-Mason-Test: Initial value
X-Mason-HEAD-Test1: bar: is a ref
X-Mason-HEAD-Test2: foo: not a ref
Status code: 0
EOF
             },
           );
}

sub _cgi_no_handler_tests
{
    shift;
    my %p = @_;

    # tests that MasonAllowGlobals works with a list of params
    # (testing a list parameter from httpd.conf)
    return ( { path => '/comps/allow_globals',
               expect => <<'EOF',
X-Mason-Test: Initial value
$foo is 1
@bar is abc
Status code: 0
EOF
             },
           );
}

sub _filter_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/basic',
               expect => <<'EOF',
X-Mason-Test: Initial value
BASIC TEST.
2 + 2 = 4.
URI = /BASIC.
METHOD = GET.


Status code: 0
EOF
             },
           );
}

sub _set_content_type_tests
{
    shift;
    my %p = @_;

    return ( { path  => '/comps/basic',
               extra =>
               [ sub { my $response = shift;
                       is( $response->headers()->header('Content-Type'),
                           'text/html; charset=i-made-this-up',
                           'Content type set by handler is preserved by Mason' ); },
                 sub { my $response = shift;
                       unlike( $response->content(), qr/Content-Type:/i,
                               'response body does not contain a content-type header' ); },
               ],
             },
             { path => '/comps/with_dhandler_no_ct/',
               extra =>
               [ sub { my $response = shift;
                       is( $response->headers()->header('Content-Type'),
                           'text/html; charset=i-made-this-up',
                           'Content type set by handler is preserved by Mason with directory request' ); },
                 sub { my $response = shift;
                       unlike( $response->content(), qr/Content-Type:/i,
                               'response body does not contain a content-type header with directory request' ); },
               ],
             },
           );
}

sub _multi_config_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/multiconf1/foo',
               expect => <<'EOF',
X-Mason-Test: Initial value
I am foo in multiconf1
comp root is multiconf1
Status code: 0
EOF
             },
             { path => '/comps/multiconf1/autohandler_test',
               expect => <<'EOF',
X-Mason-Test: Initial value
autohandler is misnamed
Status code: 0
EOF
             },
             { path => '/comps/multiconf2/foo',
               expect => <<'EOF',
X-Mason-Test: Initial value
I am foo in multiconf2
comp root is multiconf2
Status code: 0
EOF
             },
             { path => '/comps/multiconf2/dhandler_test',
               regex => qr{404 not found}i,
             },
             { path => '/perl-status',
               regex => qr{<a href="/perl-status\?mason0001">HTML::Mason status</a>},
             },
           );
}

sub _cgi_handler_tests
{
    shift;
    my %p = @_;

    return ( { path => '/comps/basic',
               unfiltered_response => 1,
               expect => <<'EOF',
Basic test.
2 + 2 = 4.
uri = /basic.
method = GET.
EOF
             },
             { path => '/comps/print',
               unfiltered_response => 1,
               expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
             },
             { path => '/comps/print/autoflush',
               unfiltered_response => 1,
               expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
             },
             { path => '/comps/print/handle_comp',
               unfiltered_response => 1,
               expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
             },
             { path => '/comps/print/handle_cgi_object',
               unfiltered_response => 1,
               expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
             },
             { path => '/comps/cgi_foo_param/handle_cgi_object',
               unfiltered_response => 1,
               expect => <<'EOF',
CGI foo param is bar
EOF
             },
             { path => '/comps/redirect',
               unfiltered_response => 1,
               expect => <<'EOF',
Basic test.
2 + 2 = 4.
uri = /basic.
method = GET.
EOF
             },
             { path => '/comps/params?qs1=foo&qs2=bar&mixed=A',
               post => { post1 => 'a',
                         post2 => 'b',
                         mixed => 'B',
                       },
               unfiltered_response => 1,
               expect => <<'EOF',
mixed: A, B, array
post1: a
post2: b
qs1: foo
qs2: bar
EOF
             },
             { path => '/comps/error_as_html',
               regex => qr{<b>error:</b>.*Error during compilation}s,
             },
             { path => '/comps/abort_with_ok',
               unfiltered_response => 1,
               expect => <<'EOF',
All is well
EOF
             },
             # XXX - does this test make any sense?
             { path => '/comps/abort_with_not_ok',
               unfiltered_response => 1,
               expect => <<'EOF',
All is well
EOF
             },
             { path => '/comps/foo/will_decline',
               # Having decline generate an error like this is bad,
               # but there's not much else we can do without rewriting
               # more of CGIHandler, which isn't a good idea for
               # stable, methinks.
               regex => qr{could not find component for initial path}is,
             },
             { path => '/comps/cgi_dh/dir/extra/stuff',
               unfiltered_response => 1,
               expect => <<'EOF',
dhandler
dhandler_arg = dir/extra/stuff
EOF
             },
             { path => '/comps/explicitly_send_header',
               unfiltered_response => 1,
               expect => <<'EOF',
Sending headers in this comp.
EOF
             },
           );

    ## CGIHandler.pm does not do this the same as ApacheHandler.pm
    ## but we do not want to rewrite CGIHandler in stable
    #
    #       my $path = '/comps/cgi_dh/file/extra/stuff';
    #        my $response = Apache::test->fetch($path);
    #        expect => <<'EOF',
    #file
    #dhandler_arg = 
    #path_info = /extra/stuff
    #EOF
}

sub _run_test
{
    my $p    = shift;
    my $test = shift;

    my $path = $test->{path}
        or die "Test with no path!";

    if ( $p->{with_handler} && $path !~ m{^/ah=\d/} )
    {
        $path = '/ah=0' . $path;
    }

    my %fetch_p = ( uri => $path );
    if ( $test->{post} )
    {
        $fetch_p{method} = 'POST';

        my $uri = URI->new();
        $uri->query_form( $test->{post} );

        $fetch_p{content} = $uri->query();
    }
    elsif ( $test->{method} )
    {
        $fetch_p{method} = $test->{method};
    }

    my $response = Apache::test->fetch( \%fetch_p );

    my $output =
          $test->{unfiltered_response}
        ? $response->content()
        : _filter_response( $response, $p, $test );

    _check_output( $output, $test );

    if ( $test->{extra} )
    {
        $_->($response) for @{ $test->{extra} };
    }
}

# We're not interested in headers that are always going to be
# different (like date or server type).
sub _filter_response
{
    my $response = shift;
    my $p        = shift;
    my $test     = shift;

    my $actual;
    {
        $actual = 'X-Mason-Test: ';

        my $val;

        # This is a nasty hack because some tests using a handler()
        # sub are expected to always return this header, and others
        # are not.
        if ( $p->{with_handler} )
        {
            $val = $response->headers->header('X-Mason-Test');
        }
        else
        {
            $val = ( defined $response->headers->header('X-Mason-Test') ?
                     $response->headers->header('X-Mason-Test') :
                     'Initial value' );
        }

        $actual .= defined $val ? $val : '';
    }

    $actual .= "\n";

    # Any headers starting with X-Mason are added, excluding
    # X-Mason-Test, which is handled above
    my @headers;
    $response->headers->scan( sub { return if $_[0] eq 'X-Mason-Test' || $_[0] !~ /^X-Mason/;
                                    push @headers, [ $_[0], $_[1] ] } );

    foreach my $h ( sort { $a->[0] cmp $b->[0] } @headers )
    {
        $actual .= "$h->[0]: ";
        $actual .= defined $h->[1] ? $h->[1] : '';
        $actual .= "\n";
    }

    my $content = $response->content();
    $actual .= $content if defined $content;

    if ( ( $test->{method} && $test->{method} eq 'HEAD' ) || ! $p->{with_handler} )
    {
        my $code = $response->code() == 200 ? 0 : $response->code();
        $actual .= "Status code: $code";
    }

    return $actual;
}

sub _check_output
{
    my $output = shift;
    my $test   = shift;

    my $desc = $test->{path};
    $desc .= ' (post)' if $test->{post};

    if ( $test->{expect} )
    {
        my $expect = $test->{expect};

        for ( $output, $expect )
        {
            s/\s+$//s;
        }

        is( $output, $expect, $desc );
    }
    elsif ( $test->{regex} )
    {
        like( $output, $test->{regex},
              "Regex test for $desc" );
    }
    elsif ( ! $test->{extra} )
    {
        die "No error, expect, or extra key provided for test ($test->{path})";
    }
}


1;
