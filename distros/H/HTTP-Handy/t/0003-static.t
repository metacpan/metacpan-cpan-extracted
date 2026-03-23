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

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

use HTTP::Handy;

print "1..30
";

# Build a temporary document root.  Including $$ in the name avoids
# collisions when tests run in parallel.
my $dir  = File::Spec->tmpdir;
my $root = File::Spec->catdir($dir, "handy_test_$$");

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

# --- Normal file serving (ok 1-9) ---------------------------------------

my ($res, %h);

# ok 1-3: index.html -- status, Content-Type, body
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root);
ok($res->[0] == 200,                    'serve_static: 200 for index.html'); # ok 1
%h = @{$res->[1]};
like($h{'Content-Type'}, qr{text/html}, 'serve_static: CT html');            # ok 2
like($res->[2][0], qr{index},           'serve_static: body');               # ok 3

# ok 4-5: style.css -- status, Content-Type
$res = HTTP::Handy->serve_static(make_env('/style.css'), $root);
ok($res->[0] == 200,                     'serve_static: 200 for css');       # ok 4
%h = @{$res->[1]};
is($h{'Content-Type'}, 'text/css',       'serve_static: CT css');            # ok 5

# ok 6-7: data.ltsv -- status, Content-Type
$res = HTTP::Handy->serve_static(make_env('/data.ltsv'), $root);
ok($res->[0] == 200,                         'serve_static: 200 for ltsv');  # ok 6
%h = @{$res->[1]};
like($h{'Content-Type'}, qr{text/plain},     'serve_static: CT ltsv');       # ok 7

# ok 8-9: img.png -- status, Content-Type
$res = HTTP::Handy->serve_static(make_env('/img.png'), $root);
ok($res->[0] == 200,                     'serve_static: 200 for png');       # ok 8
%h = @{$res->[1]};
is($h{'Content-Type'}, 'image/png',      'serve_static: CT png');            # ok 9

# --- Content-Length (ok 10) ---------------------------------------------
# Content-Length must equal the actual byte length of the body.
$res = HTTP::Handy->serve_static(make_env('/style.css'), $root);
%h = @{$res->[1]};
ok($h{'Content-Length'} == length($res->[2][0]), 'serve_static: Content-Length'); # ok 10

# --- Directory falls back to index.html (ok 11-14) ----------------------

# ok 11-12: root directory /
$res = HTTP::Handy->serve_static(make_env('/'), $root);
ok($res->[0] == 200,          'serve_static: / -> index.html'); # ok 11
like($res->[2][0], qr{index}, 'serve_static: / body');          # ok 12

# ok 13-14: subdirectory /sub/
$res = HTTP::Handy->serve_static(make_env('/sub/'), $root);
ok($res->[0] == 200,              'serve_static: sub/ -> index.html'); # ok 13
is($res->[2][0], 'sub index',     'serve_static: sub index body');     # ok 14

# --- 404 for missing file (ok 15) ---------------------------------------
$res = HTTP::Handy->serve_static(make_env('/no-such-file.html'), $root);
ok($res->[0] == 404, 'serve_static: 404');                             # ok 15

# --- Path traversal blocked with 403 (ok 16-17) -------------------------

# ok 16: simple ../
$res = HTTP::Handy->serve_static(make_env('/../etc/passwd'), $root);
ok($res->[0] == 403, 'serve_static: 403 for ..');                      # ok 16

# ok 17: nested ../../
$res = HTTP::Handy->serve_static(make_env('/foo/../../etc/passwd'), $root);
ok($res->[0] == 403, 'serve_static: 403 nested ..');                   # ok 17

# --- Unknown extension falls back to octet-stream (ok 18-19) -----------
_write($root, 'file.xyz', 'binary');
$res = HTTP::Handy->serve_static(make_env('/file.xyz'), $root);
ok($res->[0] == 200, 'serve_static: 200 unknown ext');                 # ok 18
%h = @{$res->[1]};
is($h{'Content-Type'}, 'application/octet-stream', 'serve_static: octet-stream'); # ok 19

# --- Trailing slash on docroot is normalized (ok 20) --------------------
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root . '/');
ok($res->[0] == 200, 'serve_static: trailing slash on docroot');       # ok 20

# --- Default docroot is current directory (ok 21) -----------------------
{
    require Cwd;
    my $orig = Cwd::cwd();
    chdir $root;
    $res = HTTP::Handy->serve_static(make_env('/index.html'));
    ok($res->[0] == 200, 'serve_static: default docroot');             # ok 21
    chdir $orig;
}

# --- Response structure is a valid PSGI arrayref (ok 22-24) ------------
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root);
ok(ref($res)      eq 'ARRAY', 'serve_static: returns arrayref');       # ok 22
ok(ref($res->[1]) eq 'ARRAY', 'serve_static: headers arrayref');       # ok 23
ok(ref($res->[2]) eq 'ARRAY', 'serve_static: body arrayref');          # ok 24

# --- Cache-Control header (ok 25-30) -----------------------------------

# ok 25: default (no option) -> Cache-Control: no-cache
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'no-cache', 'serve_static: default Cache-Control no-cache'); # ok 25

# ok 26: cache_max_age => 3600 -> Cache-Control: public, max-age=3600
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 3600);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'public, max-age=3600', 'serve_static: cache_max_age 3600'); # ok 26

# ok 27: cache_max_age => 0 -> Cache-Control: no-cache
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 0);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'no-cache', 'serve_static: cache_max_age 0 -> no-cache'); # ok 27

# ok 28: cache_max_age => 86400 (one day)
$res = HTTP::Handy->serve_static(make_env('/index.html'), $root, cache_max_age => 86400);
%h = @{$res->[1]};
is($h{'Cache-Control'}, 'public, max-age=86400', 'serve_static: cache_max_age 86400'); # ok 28

# ok 29: 404 response still has no Cache-Control (Content-Type only)
$res = HTTP::Handy->serve_static(make_env('/no-such-file.html'), $root);
%h = @{$res->[1]};
ok(!defined $h{'Cache-Control'}, 'serve_static: no Cache-Control on 404'); # ok 29

# ok 30: 403 (path traversal) response has no Cache-Control
$res = HTTP::Handy->serve_static(make_env('/../etc/passwd'), $root);
%h = @{$res->[1]};
ok(!defined $h{'Cache-Control'}, 'serve_static: no Cache-Control on 403'); # ok 30

exit($FAIL ? 1 : 0);
