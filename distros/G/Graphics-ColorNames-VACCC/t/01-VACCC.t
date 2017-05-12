use Test;

BEGIN { plan tests => 1407, todo => [ ] }

use strict;
use Carp;

use Graphics::ColorNames::VACCC 1.01;
ok(1);

my %table = %{Graphics::ColorNames::VACCC->NamesRgbTable()};
ok(1);

ok(keys %table, 700);

my $count = 0;
foreach my $name (keys %table) {
  ok($table{$name} =~ /^\d+$/);
}

use Graphics::ColorNames 1.01, qw( hex2tuple tuple2hex );
ok(1);

tie my %colors, 'Graphics::ColorNames', 'VACCC';
ok(1);

ok(keys %colors, 700); #

$count = 0;
foreach my $name (keys %colors)
  {
  ok($colors{$name} =~ /^[\da-f]+$/);
    if ($colors{$name} !~ /^[0-9a-f]+$/) {
      print STDERR "\x23 ", $name, "\t", $colors{$name}, "\n";
    }
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if (tuple2hex(@RGB) eq $colors{$name} );
  }
ok($count, keys %colors);
