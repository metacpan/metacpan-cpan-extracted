#!/usr/bin/perl

use strict;

use Test::More tests => 54;
use Test::Exception;

use_ok('Graphics::ColorNames', '2.10', qw( hex2tuple tuple2hex all_schemes ));

{
  my %schemes = map { $_=>1, } all_schemes();
  ok((keys %schemes) >= 4); # Windows, Netscape, HTML, and X
  ok($schemes{X});
  ok($schemes{HTML});
  ok($schemes{Windows});
  ok($schemes{Netscape});
}

tie my %colors, 'Graphics::ColorNames';
ok(tied %colors);

my $count = 0;
foreach my $name (keys %colors)
  {
    my @RGB = hex2tuple($colors{$name});
    $count++, if (tuple2hex(@RGB) eq $colors{$name} );
  }
ok($count == keys %colors);

$count = 0;
foreach my $name (keys %colors)
  {
    $count++, if ($colors{lc($name)} eq $colors{uc($name)});
  }
ok($count == keys %colors);


$count = 0;
foreach my $name (keys %colors)
  {
    $count++, if (exists($colors{$name}))
  }
ok($count == keys %colors);

$count = 0;
foreach my $name (keys %colors)
  {
    my $rgb = $colors{$name};
    $count++, if (defined $colors{$rgb});
    $count++, if (defined $colors{"\x23".$rgb});
  }
ok($count == (2*(keys %colors)));

# Test CLEAR, DELETE and STORE as returning errors

dies_ok { undef %colors } "undef %colors";

dies_ok { %colors = (); } "%colors = ()";

dies_ok { $colors{MyCustomColor} = 'FFFFFF'; } "STORE";

dies_ok { delete($colors{MyCustomColor}); } "DELETE";

# Test RGB values being passed through

foreach my $rgb (qw(
    000000 000001 000010 000100 001000 010000 100000
    111111 123abc abc123 123ABC ABC123 abcdef ABCDEF
  )) {
  ok($colors{ "\x23" . $rgb } eq lc($rgb));
  ok($colors{ $rgb } eq lc($rgb));
}

# Test using multiple schemes, with issues in overlapping

tie my %colors2, 'Graphics::ColorNames', qw( X Netscape );

ok(!exists $colors{Silver});         # Silver doesn't exist in X
ok(defined $colors2{Silver}); #      It does in Netscape

# Test precedence

ok($colors{DarkGreen}  eq '006400'); # DarkGreen in X
ok($colors2{DarkGreen} eq '006400'); # DarkGreen in X
ok($colors2{DarkGreen} ne '2f4f2f'); # DarkGreen in Netscape

tie my %colors3, 'Graphics::ColorNames', qw( Netscape X );

ok($colors{Brown}  eq 'a52a2a'); # Brown in X
ok($colors2{Brown} eq 'a52a2a'); # Brown in X (don't try Netscape)
ok($colors3{Brown} eq 'a62a2a'); # Brown in Netscape (don't try X)

# Test handling of non-existent color names

ok(!defined $colors{NonExistentColorName});
ok(!exists  $colors{NonExistentColorName});

# Test dynamic loading of scheme

my $colorobj = tied(%colors);
$colorobj->load_scheme({ nonexistentcolorname => 0x123456 } );
ok($colors{NonExistentColorName} eq '123456');



