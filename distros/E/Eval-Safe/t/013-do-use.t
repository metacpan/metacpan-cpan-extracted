#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/data";

use Data::Dumper;
use File::Spec::Functions qw(catfile);

plan tests => 12;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    ok($eval->do($FindBin::Bin.'/data/valid_code.pm'), 'do work'.$s);
    is($eval->eval('foo(3,4)'), 7, 'code from do'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    undef $@;
    is($eval->do($FindBin::Bin.'/data/invalid_code.pm'), undef, 'do fail on bad code'.$s);
    like($@, qr/.+/, '$@ is set on bad code do'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    undef $!;
    is($eval->do('file_does_not_exists.pm'), undef, 'do non-existant file'.$s);
    like($!, qr/.+/, '$! is set on non-existant do'.$s);
  }
}
