#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   };

my $gen = '../';
$gen = 'perl ..\\' if $^O =~ /MSWin32/i;
$gen .= 'gen_graph';

#############################################################################
# --format=foo tests

test_out ('html', 'usage.html');

test_out ('ascii', 'usage.txt');

# all tests done;

#############################################################################

sub test_out
  {
  # format, outfile
  my ($f,$out) = @_;

  unlink $out; my $rc = `$gen --inc=lib/Test.pm --format=$f --output=$out`;
  ok (-f $out, "$out exists");

  unlink $out; $rc = `$gen --inc=lib/Test.pm --format=$f --output=usage`;
  ok (-f $out, "$out exists");

  unlink $out; $rc = `$gen --inc=lib/Test.pm --format=$f --versions --output=usage`;
  ok (-f $out, "$out exists");

  unlink $out; $rc = `$gen --inc=lib/Test.pm --format=$f --versions --debug --output=usage`;
  ok (-f $out, "$out exists");

  unlink $out; $rc = `$gen --inc=lib/Test.pm --format=$f --versions --debug --output=usage --extension=$f`;
  ok (-f $out, "$out exists");

  unlink $out; $rc = `$gen --inc=lib/Test.pm --format=$f --versions --debug --output=usage --extension=.$f`;
  ok (-f $out, "$out exists");
  }

END
  {
  # clean up
  unlink "usage.html";
  unlink "usage.txt";
  }


