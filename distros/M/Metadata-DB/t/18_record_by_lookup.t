use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::DB;
use Cwd;
$Metadata::DB::Object::DEBUG = 1; # ?
use Smart::Comments '###';

require Cwd;
my $abs_db = Cwd::cwd().'/t/test_lookup.db';



my $dbh = _get_new_handle();

ok $dbh or die;

my $o = Metadata::DB->new({ DBH => $dbh });
ok( $o->table_metadata_reset, "reset $abs_db");


$Metadata::DB::Base::DEBUG = 0;


# premake some records
# DO NOT CHANGE THESE VALUES - they are tested against later
my %record = (
   1 => { age => 20, weight => 270, name => 'james' },
   2 => { age => 20, weight => 130, name => 'linda' },
   3 => { age => 20, weight => 132, name => 'lana' },
   4 => { age => 20, weight => 270, name => 'maria' },
   5 => { age => 20, weight => 270, name => 'gustav' },
   6 => { age => 20, weight => 120, name => 'gia' },
   7 => { age => 22, weight => 139, name => 'miranda' },
   8 => { age => 20, weight => 270, name => ['laetitia','maria'], married => '1' },
   9 => { age => 20, weight => 270, name => 'vanna' },

);


while( my($id, $href) = each %record ){
   ## $id
   ## $href

   my $m = Metadata::DB->new({ DBH => $dbh });

   $m->id($id);
   #while( my ($k,$v) = each %$href ){
   #   print STDERR " - $k:$v\n";
   #   $m->set( $k => $v );
   #}

   $m->add( %$href );
   $m->save;
   undef $m; # need to commit etc?????
}






$Metadata::DB::DEBUG = 1;


# try the new lookup() method

ok_part('lookup 1');

ok( ! $o->lookup ,"lookup() fails, errstr is: ".$o->errstr); # should fail cause we have no atts

ok_part('lookup 2');

# set an att
$o->set( age => 20 ); # should cause too many results
ok( ! $o->lookup ,"lookup() fails, errstr is: ".$o->errstr);
ok($o->errstr =~/too many/i,"cause for fail is too many found") or die;

ok_part('lookup 3');

# another..
$o->set( weight => 270 ); # should still cause too many results
ok( ! $o->lookup ,"lookup() fails, errstr is: ".$o->errstr);
ok($o->errstr =~/too many/i,"cause for fail is too many found") or die;

print STDERR "\n\nThis one should work: \n";
$Metadata::DB::DEBUG = 1;


ok_part('lookup 4, should work');

# this one should do it:
$o->set( name => 'vanna' );
ok( $o->lookup , "lookup() works, have enough params") or print STDERR $o->errstr ."\n\n";









ok_part('load one');

my $p = Metadata::DB->new({ DBH => $dbh });

$p->set( name => [ 'laetitia','maria']);
ok(! $p->loaded,"not loaded yet.") or die;


my $p_age = $p->get('age');
ok( ! $p_age,"thus, caling age does not return");




my $p_id = $p->lookup;
ok($p_id, "p id is $p_id") or die;
ok( $p_id == 8, "the id for the record is as expected");

ok $p->get_all;

# that should not load..
ok($p->loaded,"was loaded") or die;


ok(  $p->get('age') == 20," now age is as expected, because we loaded.");
ok(  $p->get('weight') == 270," now weight is as expected, because we loaded.");

ok(  $p->get('married') == 1," now married is as expected, because we loaded.");



# what if we load twice??

my $data_0 = $p->get_all;
### $data_0

$p->load;

my $data_1 = $p->get_all;
### $data_1






# #



sub ok_part { print STDERR uc "\n====================================\n@_\n\n" }



sub _get_new_handle {


   my $dbh = DBI::connect_sqlite($abs_db);
   ok( $dbh,'opened dbh with connect_sqlite()') or die;
   return $dbh;


}


