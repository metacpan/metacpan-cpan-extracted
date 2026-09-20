######################################################################
#
# t/0003-static.t - Tests for serve_static.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec ();

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }
sub like { my ($g, $re, $n) = @_; $T++; defined($g) && ($g =~ $re) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

use HTTPS::Handy;

# Build a temporary document root.  Including $$ in the name avoids
# collisions when tests run in parallel.
my $dir  = File::Spec->tmpdir;
my $root = File::Spec->catdir($dir, "https_handy_test_$$");

# Remove all test files on exit.
END {
    if (defined $root && -d $root) {
        unlink File::Spec->catfile($root, $_)
            for qw(index.html style.css data.ltsv img.png file.xyz);
        unlink File::Spec->catfile(File::Spec->catdir($root, 'sub'), 'index.html');
        rmdir  File::Spec->catdir($root, 'sub');
        rmdir  $root;
    }
}

mkdir $root,                            0777 or die "mkdir $root: $!";
mkdir File::Spec->catdir($root, 'sub'), 0777 or die "mkdir sub: $!";

# Write a file under directory $d with name $f and content $c.
# Uses the two-arg open form with a bareword handle for Perl 5.5.3
# compatibility (three-arg open and "open my $fh" require Perl 5.6+).
sub _write {
    my ($d, $f, $c) = @_;
    my $p = File::Spec->catfile($d, $f);
    local *FH;
    open FH, ">$p" or die "open $p: $!";
    binmode FH;
    print FH $c;
    close FH;
}

_write($root,                            'index.html', '<html><body>index</body></html>');
_write($root,                            'style.css',  'body { color: red; }');
_write($root,                            'data.ltsv',  "host:web01\tport:80\n");
_write($root,                            'img.png',    "\x89PNG\r\n\x1a\n");
_write(File::Spec->catdir($root, 'sub'), 'index.html', 'sub index');

# Build a minimal PSGI $env with the given PATH_INFO.
sub make_env { my $p = shift; return { PATH_INFO => $p } }

# --- Normal file serving --------------------------------------------------

my ($res, %h);

$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root);
ok($res->[0] == 200,                    'serve_static: 200 for index.html');
%h = @{$res->[1]};
like($h{'Content-Type'}, qr{text/html}, 'serve_static: CT html');
like($res->[2][0], qr{index},           'serve_static: body');

$res = HTTPS::Handy->serve_static(make_env('/style.css'), $root);
ok($res->[0] == 200,                     'serve_static: 200 for css');
%h = @{$res->[1]};
is($h{'Content-Type'}, 'text/css',       'serve_static: CT css');

$res = HTTPS::Handy->serve_static(make_env('/data.ltsv'), $root);
ok($res->[0] == 200,                         'serve_static: 200 for ltsv');
%h = @{$res->[1]};
like($h{'Content-Type'}, qr{text/plain},     'serve_static: CT ltsv');

$res = HTTPS::Handy->serve_static(make_env('/img.png'), $root);
ok($res->[0] == 200,                     'serve_static: 200 for png');
%h = @{$res->[1]};
is($h{'Content-Type'}, 'image/png',      'serve_static: CT png');

# --- Content-Length --------------------------------------------------------
# Content-Length must equal the actual byte length of the body.
$res = HTTPS::Handy->serve_static(make_env('/style.css'), $root);
%h = @{$res->[1]};
ok($h{'Content-Length'} == length($res->[2][0]), 'serve_static: Content-Length');

# --- Directory falls back to index.html ------------------------------------

$res = HTTPS::Handy->serve_static(make_env('/'), $root);
ok($res->[0] == 200,          'serve_static: / -> index.html');
like($res->[2][0], qr{index}, 'serve_static: / body');

$res = HTTPS::Handy->serve_static(make_env('/sub/'), $root);
ok($res->[0] == 200,              'serve_static: sub/ -> index.html');
is($res->[2][0], 'sub index',     'serve_static: sub index body');

$res = HTTPS::Handy->serve_static(make_env('/sub'), $root);
ok($res->[0] == 200,              'serve_static: sub (no trailing slash) -> index.html');
is($res->[2][0], 'sub index',     'serve_static: sub (no trailing slash) body');

# --- 404 for missing file ---------------------------------------------------
$res = HTTPS::Handy->serve_static(make_env('/no-such-file.html'), $root);
ok($res->[0] == 404, 'serve_static: 404');

# --- Path traversal blocked with 403 ----------------------------------------

$res = HTTPS::Handy->serve_static(make_env('/../etc/passwd'), $root);
ok($res->[0] == 403, 'serve_static: 403 for ..');

$res = HTTPS::Handy->serve_static(make_env('/foo/../../etc/passwd'), $root);
ok($res->[0] == 403, 'serve_static: 403 nested ..');

# --- Unknown extension falls back to octet-stream ---------------------------
_write($root, 'file.xyz', 'binary');
$res = HTTPS::Handy->serve_static(make_env('/file.xyz'), $root);
ok($res->[0] == 200, 'serve_static: 200 unknown ext');
%h = @{$res->[1]};
is($h{'Content-Type'}, 'application/octet-stream', 'serve_static: octet-stream');

# --- Trailing slash on docroot is normalized --------------------------------
$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root . '/');
ok($res->[0] == 200, 'serve_static: trailing slash on docroot');

# --- Default docroot is current directory -----------------------------------
{
    require Cwd;
    my $orig = Cwd::cwd();
    chdir $root;
    $res = HTTPS::Handy->serve_static(make_env('/index.html'));
    ok($res->[0] == 200, 'serve_static: default docroot');
    chdir $orig;
}

# --- Response structure is a valid PSGI arrayref ----------------------------
$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root);
ok(ref($res)      eq 'ARRAY', 'serve_static: returns arrayref');
ok(ref($res->[1]) eq 'ARRAY', 'serve_static: headers arrayref');
ok(ref($res->[2]) eq 'ARRAY', 'serve_static: body arrayref');

# --- Cache-Control header ----------------------------------------------------

$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'no-cache', 'serve_static: default Cache-Control no-cache');

$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 3600);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'public, max-age=3600', 'serve_static: cache_max_age 3600');

$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 0);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'no-cache', 'serve_static: cache_max_age 0 -> no-cache');

$res = HTTPS::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 86400);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'public, max-age=86400', 'serve_static: cache_max_age 86400');

$res = HTTPS::Handy->serve_static(make_env('/no-such-file.html'), $root);
%h = @{$res->[1]};
ok(!defined $h{'Cache-Control'}, 'serve_static: no Cache-Control on 404');

$res = HTTPS::Handy->serve_static(make_env('/../etc/passwd'), $root);
%h = @{$res->[1]};
ok(!defined $h{'Cache-Control'}, 'serve_static: no Cache-Control on 403');

print "1..$T\n";
exit($FAIL ? 1 : 0);
