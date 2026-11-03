use strict;
use warnings;
use Test::More;
use Config;
use Test::InDistDir;
use Capture::Tiny 'capture';
use File::Copy 'copy';
use Path::Tiny;

# xbin/release.pl in a throw-away tree, with a fake twine and a fake python first on PATH: no
# network, no real python. The fakes are shell scripts, so the test needs a shell and a temp dir
# that may run them.
plan skip_all => 'fake twine and python are shell scripts, they do not run on MSWin32'
  if $^O eq 'MSWin32';

my $root = Path::Tiny->tempdir;
$root->child('xbin')->mkpath;
$root->child('python/dist')->mkpath;
$root->child('fakebin')->mkpath;
copy( 'xbin/release.pl', $root->child('xbin/release.pl')->stringify ) or die "copy: $!";
$root->child('python/dist/locale_simple-0.200.tar.gz')->spew('x');
$root->child('python/dist/locale_simple-0.200-py3-none-any.whl')->spew('x');
$root->child('python/locale_simple.py')->spew(qq{__version__ = "0.1"\n});

my $twine = $root->child('fakebin/twine');
$twine->spew("#!/bin/sh\necho \"fake twine: \$*\" >&2\nexit 1\n");
$twine->chmod(0755);

# python stops the credential-pass cases at `python -m build`, whatever python the box has.
my $python = $root->child('fakebin/python');
$python->spew("#!/bin/sh\necho \"fake python: \$*\" >&2\nexit 1\n");
$python->chmod(0755);

# The temp dir may be mounted noexec: run the fake once and skip when it does not answer.
{
    my ( undef, $probe ) = capture { system "$twine", 'probe' };
    plan skip_all => 'no shell script runs from the temp dir (fake twine did not answer)'
      unless $probe =~ /fake twine: probe/;
}

my $home   = Path::Tiny->tempdir;    # no .pypirc
my $script = $root->child('xbin/release.pl')->stringify;
my $path   = join $Config{path_sep}, $root->child('fakebin')->stringify, $ENV{PATH};

# Runs the script with a clean credential environment plus %env.
sub release {
    my ( $args, %env ) = @_;
    local %ENV = ( %ENV, HOME => "$home", PATH => $path );
    delete @ENV{qw( TWINE_USERNAME TWINE_PASSWORD )};
    @ENV{ keys %env } = values %env;
    my ( $out, $err ) = capture { system $^X, $script, @{$args} };
    return ( $out, $err, $? >> 8 );
}

# python-upload: twine fails, the release goes on
my ( $out, $err, $rc ) = release( ['python-upload'] );
is $rc, 0, 'python-upload exits 0 although twine failed';
like $err, qr{fake twine: upload dist/locale_simple-0\.200-py3-none-any\.whl dist/locale_simple-0\.200\.tar\.gz},
  'twine got the dist files';
like $err, qr/PyPI upload FAILED/, 'the failure is announced on STDERR';
like $err,
  qr{cd \Q$root\E && twine upload python/dist/locale_simple-0\.200-py3-none-any\.whl python/dist/locale_simple-0\.200\.tar\.gz},
  'the retry command names the repo root and the exact files';

# python-upload with no dist files is not fatal either
{
    my $empty = Path::Tiny->tempdir;
    $empty->child('xbin')->mkpath;
    $empty->child('python/dist')->mkpath;
    copy( 'xbin/release.pl', $empty->child('xbin/release.pl')->stringify ) or die;
    my ( undef, $e ) = capture { system $^X, $empty->child('xbin/release.pl')->stringify, 'python-upload' };
    is $? >> 8, 0, 'python-upload without dist files exits 0';
    like $e, qr/python -m build && twine upload dist/, 'and names the rebuild and upload';
}

# python-prep: credentials are checked before anything is touched
( $out, $err, $rc ) = release( [ 'python-prep', '0.200' ] );
isnt $rc, 0, 'python-prep stops without PyPI credentials';
like $err, qr/no PyPI credentials/,               'and says so';
like $err, qr/\.pypirc/,                          'it names ~/.pypirc';
like $err, qr/TWINE_USERNAME and TWINE_PASSWORD/, 'and the TWINE variables';
is $root->child('python/locale_simple.py')->slurp, qq{__version__ = "0.1"\n}, 'the version was not bumped';

# Each documented source passes the check (the run then stops at the fake python).
$home->child('.pypirc')->spew("[pypi]\nusername = __token__\npassword = pypi-SECRET\n");
( undef, $err ) = release( [ 'python-prep', '0.200' ] );
unlike $err, qr/no PyPI credentials/, '~/.pypirc [pypi] password is enough';
like $err, qr/fake python: -m build/, 'and the run went on to python -m build, which the fake stopped';
unlike $err, qr/SECRET/,              'no secret is printed';

$home->child('.pypirc')->spew("[testpypi]\npassword = x\n");
( undef, $err ) = release( [ 'python-prep', '0.200' ] );
like $err, qr/no PyPI credentials/, 'a password in another section does not count';

( undef, $err ) = release( [ 'python-prep', '0.200' ], TWINE_USERNAME => 'me', TWINE_PASSWORD => 'hunter2' );
unlike $err, qr/no PyPI credentials/, 'TWINE_USERNAME + TWINE_PASSWORD are enough';
unlike $err, qr/hunter2/,             'the password is not printed';

( undef, $err ) = release( [ 'python-prep', '0.200' ], TWINE_PASSWORD => 'pypi-abc' );
unlike $err, qr/no PyPI credentials/, 'TWINE_PASSWORD with a token is enough';

( undef, $err ) = release( [ 'python-prep', '0.200' ], TWINE_PASSWORD => 'plain' );
like $err, qr/no PyPI credentials/, 'TWINE_PASSWORD alone, neither token nor user, is not';

done_testing;
