use strict;
use warnings;

use Test::More;
use File::Which qw( which );
use Capture::Tiny qw( capture );

my $path = which('objdump');

unless ( ok( $path, "objdump is available") ) {
  done_testing;
  exit 0;
};
{
  my ( $stdout, $stderr, $exit ) = capture { system("objdump --version") };

  cmp_ok( $exit, '==', 0 , "objdump exited with 0");

  my $gotoutput = 0;
  if ( $stderr !~ /^\s*$/ ) {
    diag "STDERR: ---\n" .  $stderr;
    $gotoutput++;
  }
  if ( $stdout !~ /^\s*$/ ) {
    diag "STDOUT: ---\n" . $stdout;
    $gotoutput++;
  }
  ok( $gotoutput , "objdump --version emitted data" );
}
{
  my ( $stdout, $stderr, $exit ) = capture { system("objdump --help") };

  cmp_ok( $exit, '==', 0 , "objdump exited with 0");

  if ( unlike( $stdout, qr/^\s*$/ , "objdump --help emitted data to STDOUT" )  ) {

      my $ok = like( $stdout, qr/-D,\s*--disassemble-all/, "has -D param" );
      $ok = undef unless like( $stdout, qr/-F,\s*--file-offsets/, "has -F param" );

      diag "STDOUT: ---\n" . $stdout unless $ok;
  } elsif ( $stderr !~ /^\s*$/ ) {
      diag "STDERR: ---\n";
  }
}

done_testing;


