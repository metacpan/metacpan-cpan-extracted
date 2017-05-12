package AppThing::Predef;


1;



package AppThing;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;

__PACKAGE__->make_accessor_setget_ondisk_file(
   'abs_conf',
);

__PACKAGE__->make_accessor_setget_ondisk_dir({
     abs_misc => './t/misc',
     abs_tmp => undef,
});
__PACKAGE__->make_method_counter( 'loans' );
1;



use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
sub space { printf STDERR "\n%s\n\n",'-'x60 }

space(); space();
warn("ON DISK DIR\n");
my $o1 = new AppThing;
ok $o1,'new() can instance, but as soon as we ask for the nonexistant dir.. dies:';
ok( ! eval { $o1->abs_misc },'abs_misc() fails');


space();

mkdir './t/misc';
-d './t/misc' or die;
my $o = new AppThing;
ok($o,'new() can instance regardless');





space(); # DIR

ok( !$o->abs_tmp,'abs tmp undef, was not ondisk..');
ok( !$o->abs_tmp('./t/blablabla'), 'setting bogus val returns undef..');

space();
mkdir './t/tmp';
ok( $o->abs_tmp('./t/tmp'),'setting val of existing dir is ok') or exit;

my $r = $o->abs_tmp;
my $c = cwd().'/t/tmp';

ok( $r eq $c,"package resolves to $r eq $c");


space(); space();
warn("ON DISK FILE\n");
# FILE
ok( ! $o->abs_conf,'abs_conf() returns nothing yet' );

my $not_on_disk = './t/tmp.conf';
!-f $not_on_disk or die;
my $r;
ok( ! ($r = $o->abs_conf($not_on_disk)), 
   'abs_conf() cant be set with not on disk arg');
ok( ! defined $r,"abs_conf() with bad arg returns undef");

open(F, '>', $not_on_disk) or die;
print F 'content';
close F;

my $on_disk = $not_on_disk;
ok( $o->abs_conf($on_disk), 'setting val of existing file is ok'); 
$r = $o->abs_conf;
$c = cwd().'/t/tmp.conf';
ok( $r eq $c,"package resolves to $r eq $c") or exit;


space(); space();
warn("# METHOD COUNTER\n");

ok( ! $o->loans,
   'loans()' );
ok( $o->loans(1) == 1,
   'loans(1)');
ok( $o->loans(10) == 11,
   'loans(10)');
ok( $o->loans == 11,
   'loans() == 11');
ok( ! $o->loans(0),
   'loans(0) returns false');


unlink $c;
rmdir './t/misc';
rmdir './t/tmp';
