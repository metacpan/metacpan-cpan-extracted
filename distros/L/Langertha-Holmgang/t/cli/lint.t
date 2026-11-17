#!/usr/bin/env perl
# holmgang lint: exactly what loads passes; exit codes and output per case.
# Invented suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use IPC::Open3 ();
use Path::Tiny qw( path );

use Holmgang::CLI qw( cli good_suite bad_suite );

my $root = Path::Tiny->tempdir;

{
  my $dir = good_suite( id => 'lint-good', root => $root );
  my ( $code, $out, $err ) = cli( lint => $dir );
  is( $code, 0, 'a suite that loads: exit 0' );
  like( $out, qr/^ok   lint-good \(1 case\)$/m, '... ok with the case count' );
  like( $out, qr/^  ok c1$/m, '... every case listed' );
  like( $out, qr/^1 suite: 1 ok, 0 refused$/m, '... and the count' );
  is( $err, '', '... nothing on stderr' );
}

{
  my $dir = bad_suite( id => 'lint-bad', root => $root );
  my ( $code, $out ) = cli( lint => $dir );
  is( $code, 1, 'a suite lint refuses: exit 1' );
  like( $out, qr/^FAIL lint-bad$/m, '... FAIL with the suite' );
  like( $out, qr{^  cases/c2\.yaml: wrong_solutions\[0\]: wrong solution "low only" passes$}m,
    '... the refusal names the case file, the field and the reason' );
  unlike( $out, qr/^  ok /m, '... no case is reported ok: the suite does not load' );
}

{
  # a search directory: each suite in it, in name order
  my ( $code, $out ) = cli( lint => "$root" );
  is( $code, 1, 'a search directory with one refused suite: exit 1' );
  like( $out, qr/^FAIL lint-bad\n.*^ok   lint-good/ms, '... both suites, in name order' );
  like( $out, qr/^2 suites: 1 ok, 1 refused$/m, '... and the count' );
}

{
  my ( $code, $out, $err ) = cli( lint => "$root/nothing-here" );
  is( $code, 2, 'a path without a suite: exit 2' );
  like( $err, qr/no suite at or below/, '... said on stderr' );
  is( ( cli('lint') )[0], 2, 'lint without a directory: exit 2' );
  is( ( cli( lint => '--bogus', "$root" ) )[0], 2, 'an unknown option: exit 2' );
}

{
  my ( $code, $out ) = cli('help');
  is( $code, 0, 'help: exit 0' );
  like( $out, qr/usage: holmgang lint/, '... prints the usage' );
  is( ( cli() )[0], 2, 'no command: exit 2' );
  is( ( cli('export-yaml') )[0], 2, 'an unknown command: exit 2' );
}

# the script itself: picked up from bin/, same exit codes
{
  my $bin  = path( $FindBin::Bin, '..', '..', 'bin', 'holmgang' )->realpath;
  my $lib  = path( $FindBin::Bin, '..', '..', 'lib' )->realpath;
  my $good = path( $root, 'lint-good' );
  my $run  = sub {
    my $pid = IPC::Open3::open3( my $in, my $fh, undef, $^X, '-I'.$lib, "$bin", @_ );
    close $in;
    my $text = do { local $/; <$fh> };
    waitpid $pid, 0;
    return ( $? >> 8, $text );
  };
  my ( $code, $text ) = $run->( lint => "$good" );
  is( $code, 0, 'bin/holmgang lint on a good suite: exit 0' ) or diag $text;
  like( $text, qr/^ok   lint-good/m, '... with its output' );
  is( ( $run->( lint => "$root" ) )[0], 1, 'bin/holmgang lint with a refused suite: exit 1' );
  is( ( $run->() )[0], 2, 'bin/holmgang without a command: exit 2' );
}

done_testing;
