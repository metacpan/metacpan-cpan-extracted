# Regression test for bug in 'grow scalar slot into ARRAY'
#   bug occurs when old value is non-ARRAY reference, eg, an object

use lib qw(t);
use Carp;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

my $obj=bless {name=>'I am an object'},'Object';
my $args=new Hash::AutoHash::Args (obj=>$obj);
cmp_deeply($args->obj,$obj,'V1 arg=>one object');
my $args=new Hash::AutoHash::Args (obj=>$obj,obj=>$obj);
cmp_deeply($args->obj,[$obj,$obj],
	   'V1 arg=>two objects: grow single valued slot into ARRAY');
my $args=new Hash::AutoHash::Args (obj=>$obj,obj=>$obj,obj=>$obj);
cmp_deeply($args->obj,[$obj,$obj,$obj],
	   'V1 arg=>three objects: ARRAY slot stays ARRAY');

# do it again for V0
my $obj=bless {name=>'I am an object'},'Object';
my $args=new Hash::AutoHash::Args::V0 (obj=>$obj);
cmp_deeply($args->obj,$obj,'V0 arg=>one object');
my $args=new Hash::AutoHash::Args::V0 (obj=>$obj,obj=>$obj);
cmp_deeply($args->obj,[$obj,$obj],
	   'V0 arg=>two objects: grow single valued slot into ARRAY');
my $args=new Hash::AutoHash::Args::V0 (obj=>$obj,obj=>$obj,obj=>$obj);
cmp_deeply($args->obj,[$obj,$obj,$obj],
	   'V0 arg=>three objects: ARRAY slot stays ARRAY');

done_testing();
