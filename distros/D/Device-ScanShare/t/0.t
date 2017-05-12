use Test::Simple 'no_plan';
use lib './lib';
use Device::ScanShare;
use Cwd;
use Smart::Comments '###';

my $cwd = cwd();
my $abs_userdirs = "$cwd/t/USERDIRS.TXT";
unlink $abs_userdirs;

no warnings;
$ARGV[0] ||= 0;


$Device::ScanShare::DEBUG = 1 if ($ARGV[0] eq '-d');

my $s = new Device::ScanShare({
	userdirs_abs_path => $abs_userdirs,
	server => '192.168.0.150',
	default_host => 'Dyer05',
});

ok $s, 'instanced';

ok( $s->base_path,'base_path()' );
ok( $s->userdirs_abs_path,'userdirs_abs_path()');

ok( ! -f $abs_userdirs,"the file is not on disk yet: $abs_userdirs") or die;

ok(!$s->exists,'userdirs does not exist') or die($s->errstr);

ok($s->create,'userdirs created') or die($s->errstr);

ok( -f $abs_userdirs, "have abs userdirs on disk now '$abs_userdirs'");
ok( $s->exists, 'now it exists') or die;
print STDERR " - ABS USERDIRS:\n - $abs_userdirs\n\n\n";



ok_part();


ok( !(scalar @{$s->get_users}), 'get_users returns 0');

mkdir cwd().'/t/userx';
mkdir cwd().'/t/usery';
mkdir cwd().'/t/userz';
mkdir cwd().'/t/userx/incoming';
mkdir cwd().'/t/usery/incoming';
mkdir cwd().'/t/userz/incoming';

-d  cwd().'/t/usery/incoming' ;


ok_part('add 1');
ok($s->user_add({ label => 'User X', path => "$cwd/t/userx/incoming" }), 'user_add() userx')
   or die($s->errstr);


ok_part('add 2');

ok( ! $s->user_add({ label => 'User X', path => "$cwd/t/usery/incoming" }),
   'user_add() adding diff path with same label fails') 
   or die($s->errstr);


ok_part('working now?');
ok($s->user_add({ label => 'User Y', path => "$cwd/t/usery/incoming" }), 'user_add() USER Y')
   or die('because ::: ' .$s->errstr);

ok_part();
ok($s->user_add({ label => 'User Z', path => "$cwd/t/userz/incoming" }), 'user_add() userz')
   or die('because ::: ' .$s->errstr);


ok_part();


ok(
  !  $s->user_add({ label => 'User Bogus', path => cwd().'/t/userq/incoming' }), 
      'user_add() fails on bogus path') or die($s->errstr);
warn("\n\n");

ok( (scalar @{$s->get_users}) ==3, 'get_users now returns 3');


ok($s->user_delete(cwd().'/t/userx/incoming'),'remove user X');

ok( (scalar @{$s->get_users}) ==2, 'get_users now returns 2');



my $userz = $s->get_user(cwd().'/t/userz/');

### $userz






ok( $s->save,'userdirs saved');


my $u = $s->get_users;
### $u

ok_part("NEW PATH METHODS");
ok( $s->base_path ) or exit;
ok( $s->userdirs_abs_path ) or exit;


for my $href ( @{$s->get_users} ){
   
   my $windowspath = $href->{path};
   ok($windowspath) or die;
   
   
   warn("winpath : $windowspath\n");
   my $abs_unix = $s->to_abs_unixpath($windowspath);
      
   my $rel_unix = $s->to_rel_unixpath($windowspath);
   warn("abs unix: $abs_unix\nrel unix: $rel_unix\n\n");

   
   

}




my $part =0;
sub ok_part {
   printf STDERR
      "\n\n-----------------------------------------------------------------------%s @_\n\n",
      $part++; 
}

