#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('File::PerlMove');
}

-d "t" && chdir("t");

require_ok("./00common.pl");

our $sz = create_testfile(our $tf = "02link.dat");

try_link('s/\.dat$/.tmp/', "02link.tmp", "link1");

{ my $warn;
  local $SIG{__WARN__} = sub { $warn = "@_"; };
  $tf = "02link.dat";
  is(File::PerlMove::pmv('s/\.dat$/.tmp/', [ $tf ], { link => 1 }), 0, "link2");
  like($warn, qr/: exists/, "link2 warning");
}

cleanup();

sub try_link {
    my ($code, $new, $tag) = @_;
    is(File::PerlMove::pmv($code, [ $tf ], { link => 1 }), 1, $tag);
    verify($new, $tag);
    my @st1 = lstat($tf);
    my @st2 = lstat($new);
    is($st1[0], $st2[0], "$tag check dev");
    is($st1[1], $st2[1], "$tag check inode");
    $tf = $new;
}

