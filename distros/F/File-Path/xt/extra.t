#! /usr/bin/env perl

#
# Author tests
#
# Run 'setup_tests.pl' as root to setup the directory scenario.
#   setup_tests.pl -i
#
# Run 'setup_tests.pl' as root to clean the directory.
#   setup_tests.pl -r
#

# The directory tree root is 'xt/extra'.


use strict;
use File::Path;
use File::Basename;

use Config;
use File::Spec::Functions;
use Fcntl ':mode';
use Test::More;
use lib 't/';
use FilePathTest;

plan skip_all => 'Symlinks not supported or not setup - see setup_tests.pl'
  if not $Config{d_symlink} or
     not -d dirname(__FILE__) . '/extra';

plan tests => 28;

my $d = dirname(__FILE__) . '/extra';

my ($file, $error, $message, $rv);
my $dir;
my $dir2;



my $extra =  catdir(curdir(), qw($d 1 a));

my ($list, $err);

$dir = catdir( $d, '1' );
rmtree( $dir, { result => \$list,
                error  => \$err } );
is(scalar(@$list), 2, "extra dir $dir and two files removed");
is(scalar(@$err), 1, "no errors encountered");

# root can delete symlink to directory
$dir = catdir( $d, '3', 'N' );
rmtree( $dir, {result => \$list, error => \$err} );
is( @$list, 1, q{remove a symlinked dir} );
is( @$err,  0, q{with no errors} );

$dir = catdir($d, '3', 'S');
rmtree($dir, {error => \$error});
is( scalar(@$error), 1, 'one error for an unreadable dir' );
eval { ($file, $message) = each %{$error->[0]}};
is( $file, $dir, 'unreadable dir reported in error' )
    or diag($message);

$dir = catdir($d, '3', 'T');
rmtree($dir, {error => \$error});
is( scalar(@$error), 1, 'one error for an unreadable dir T' );
eval { ($file, $message) = each %{$error->[0]}};
is( $file, $dir, 'unreadable dir reported in error T' );

$dir = catdir( $d, '4' );
rmtree($dir,  {result => \$list, error => \$err} );
is( scalar(@$list), 0, q{don't follow a symlinked dir} );
is( scalar(@$err),  2, q{two errors when removing a symlink in r/o dir} );
eval { ($file, $message) = each %{$err->[0]} };
is( $file, $dir, 'symlink reported in error' );

$dir  = catdir($d, '3', 'U');
$dir2 = catdir($d, '3', 'V');
rmtree($dir, $dir2, {verbose => 0, error => \$err, result => \$list});
is( scalar(@$list),  1, q{deleted 1 out of 2 directories} );
is( scalar(@$error), 1, q{left behind 1 out of 2 directories} );
eval { ($file, $message) = each %{$err->[0]} };
is( $file, $dir, 'first dir reported in error' );



$dir = catdir($d, '3');

$dir = catdir($d, '3', 'U');
$rv = _run_for_warning( sub { rmtree($dir, {verbose => 0}) } );
like( $rv,
      qr{\Acannot make child directory read-write-exec for [^:]+: .* at \S+ line \d+\.?},
      q(rmtree can't chdir into root dir)
);

$dir = catdir($d, '3');
$rv = _run_for_warning( sub { rmtree( $dir, { } ) } );
like( $rv,
      qr{\Acannot make child directory read-write-exec for [^:]+: .* at (\S+) line (\d+)\.?
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot remove directory for [^:]+: .* at \1 line \2},
    'rmtree with file owned by root'
);

$rv = _run_for_warning( sub { rmtree( $d, { } ) } );
like( $rv,
      qr{\Acannot remove directory for [^:]+: .* at (\S+) line (\d+)
cannot remove directory for [^:]+: .* at \1 line \2
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot remove directory for [^:]+: .* at \1 line \2
cannot unlink file for [^:]+: .* at \1 line \2
cannot restore permissions to \d+ for [^:]+: .* at \1 line \2
cannot make child directory read-write-exec for [^:]+: .* at \1 line \2
cannot remove directory for [^:]+: .* at \1 line \2},
    'rmtree with insufficient privileges'
);

rmtree $d, {safe => 0, error => \$error};
is( scalar(@$error), 10, 'seven deadly sins' ); # well there used to be 7

rmtree $d, {safe => 1, error => \$error};
is( scalar(@$error), 9, 'safe is better' );
for (@$error) {
    ($file, $message) = each %$_;
    if ($file =~  /[123]\z/) {
        is(index($message, 'cannot remove directory: '), 0, "failed to remove $file with rmdir")
            or diag($message);
    }
    else {
        like($message, qr(\Acannot (?:restore permissions to \d+|chdir to child|unlink file): ), "failed to remove $file with unlink")
            or diag($message)
    }
}
