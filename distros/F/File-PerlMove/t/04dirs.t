#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('File::PerlMove');
}

-d "t" && chdir("t");

require_ok("./00common.pl");

our $sz = create_testfile(our $tf = "04dirs.dat");

{ my $warn;
  local $SIG{__WARN__} = sub { $warn = "@_"; };
  is(File::PerlMove::pmv('s;^;04dirs/;', [ $tf ], { errno => 1 }), 0, "move1");
  like($warn, qr/: 2/, "move1 warning");
}

$tf = "04dirs.dat";
is(File::PerlMove::pmv('s;^;04dirs/;', [ $tf ], { createdirs => 1 }), 1, "move2");
$tf = verify("04dirs/$tf", "move2");

cleanup();

rmdir("04dirs");
