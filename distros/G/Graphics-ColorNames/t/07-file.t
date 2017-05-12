#!/usr/bin/perl

use strict;

use Test::More tests => 10;

use_ok('Graphics::ColorNames', 1.10, qw( hex2tuple tuple2hex ));

tie my %colors, 'Graphics::ColorNames', './t/rgb.txt';
ok(tied %colors);

ok(keys %colors == 6); #

my $count = 0;
foreach my $name (keys %colors)
  {
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if (tuple2hex(@RGB) eq $colors{$name} );
  }
ok($count == keys %colors);

foreach my $name (qw( one two three four five six)) {
  ok(exists $colors{$name});
}
