use Test::Simple 'no_plan';
use strict;
use lib './lib';
use lib './t';
use warnings;
use constant DEBUG => 1;
use LEOCHARRE::PMInspect;
use LEOCHARRE::Test;

print STDERR " - $0 started\n" if DEBUG;

ok_part('via instance');


use Bogus;
my $instance = Bogus->new();

my $i = LEOCHARRE::PMInspect->new({
   pm_instance => $instance,
});

ok($i, 'instanced');

my $class = $i->pm_class;
ok( $class eq 'Bogus', " class is $class") or die;


ok($i->minfo, 'module info instanced');

my $path = $i->pm_path;
ok($path, "pm_path() is $path");

print STDERR $i->output;






ok_part('VIA NAMESPACE');

my $n = LEOCHARRE::PMInspect->new({
   pm_class => 'Bogus',
  });

ok($n->pm_instance, 'can get instance') or die;

my $path2 = $n->pm_path;
ok($path2. "pm path 2 $path2");

#print STDERR $n->output;

exit;



