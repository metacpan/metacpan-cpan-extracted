#_ Color _______________________________________________________________
# Test colors
# philiprbrenan@yahoo.com, 2004, Perl License    
#_______________________________________________________________________

use Math::Zap::Color;
use Test::Simple tests=>20;

ok(color('dark red')->normal eq '#8b0000');
ok(color('dark red')->light  eq '#c58080');
ok(color('red')->normal      eq '#ff0000');
ok(color('red')->light       eq '#ff8080');
ok(color('red')->dark        eq '#7f0000');
ok(color('red')->invert      eq '#00ffff');

use Math::Zap::Color color=>'c', invert=>-i;

my $c = c -red;
ok("$c"                  eq '#ff0000');
ok(i(-red)               eq '#00ffff');
ok(c('dark red')->normal eq '#8b0000');
ok(c('dark red')->light  eq '#c58080');
ok($c->normal            eq '#ff0000');
ok($c->light             eq '#ff8080');
ok($c->dark              eq '#7f0000');
ok($c->invert            eq '#00ffff');
ok(c(-green)             eq '#00ff00');
ok(c('ReD')              eq '#ff0000');
ok(c(-red)               eq '#ff0000');
ok(c('#ff0000')          eq '#ff0000');
ok(c('ff0000')           eq '#ff0000');
ok(c('255,0,0')          eq '#ff0000');

