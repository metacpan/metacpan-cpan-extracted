#!/usr/buin/perl

use strict;

use Test::More tests => 4;

use_ok('Graphics::ColorNames', 1.06, qw( hex2tuple tuple2hex ));

tie my %colors, 'Graphics::ColorNames', 'Windows';
ok(tied %colors);

ok(keys %colors == 16);

my $count = 0;
foreach my $name (keys %colors)
  {
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if (tuple2hex(@RGB) eq $colors{$name} );
  }
ok($count == keys %colors);
