use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::DB;
use Cwd;
$Metadata::DB::Object::DEBUG = 1; # ?
use Smart::Comments '###';

require Cwd;
my $abs_db = Cwd::cwd().'/t/test_3.db';



my $dbh = _get_new_handle();

ok $dbh or die;

my $o = Metadata::DB->new({ DBH => $dbh });
ok( $o->table_metadata_reset, "reset $abs_db");


$Metadata::DB::Base::DEBUG = 0;


# premake some records
# DO NOT CHANGE THESE VALUES - they are tested against later
my @record = (
   { age => 20, weight => 270, name => 'james' },
   { age => 20, weight => 130, name => 'linda' },
   { age => 20, weight => 132, name => 'lana' },
   { age => 20, weight => 270, name => 'maria' },
   { age => 20, weight => 270, name => 'gustav' },
   { age => 20, weight => 120, name => 'gia' },
   { age => 22, weight => 139, name => 'miranda' },
   { age => 20, weight => 270, name => ['laetitia','maria'], married => '1' },
   { age => 20, weight => 270, name => 'vanna' },
);


for my $href ( @record ){ 
   ## $href

   my $m = Metadata::DB->new({ DBH => $dbh });

   

   $m->add( %$href );
   $m->save;
   my $id = $m->id;
   ok( $id, "saved $id");
   undef $m; # need to commit etc?????
}

# make some more bogus ones..
for ( 22 .. 105 ){
   my $r = Metadata::DB->new({ DBH => $dbh });
   $r->add( %{$record[0]} );
   $r->set( age => $_ + 1 );
   $r->save;
   my $id = $r->id;
   ok( $id, "ok, made bogus $id");
   
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


