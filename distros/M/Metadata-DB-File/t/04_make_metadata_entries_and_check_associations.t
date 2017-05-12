use strict;
use lib './lib';
BEGIN { require './t/test.pl'; }
use Metadata::DB::File;
use Metadata::DB::File::Base;
use Smart::Comments '###';
$Metadata::DB::File::DEBUG = 1;
#$Metadata::DB::File::Base::DEBUG = 1;



_reset_db();

my $dbh = _get_new_handle_mysql();
ok($dbh,'got dbh') or die;


ok(1,'# SAVE SOME META #');

ok( abs_tmps_make() ,"made abs tmps\n\n\n");


$dbh->{AutoCommit} = 0;


# try saving meta
for my $abs ( abs_tmps()){

   my $f = Metadata::DB::File->new({ 
      DBH => $dbh, 
      abs_path => $abs,
   })or die;
   
   $f->set( client => 'Joe Piscoppo' );
   $f->set( type => 'FPE');
   
   ok($f->save,"saved for $abs");
}

$dbh->commit;

$dbh->{AutoCommit} = 1;




ok(1, "\n\n'# NOW CHECK IT\n\n");

# now load it and test it
for my $abs ( abs_tmps()){

   my $f = Metadata::DB::File->new({ 
      DBH => $dbh, 
      abs_path => $abs,
   }) or die;
   ok( $f->load, 'loaded');

  # my $metadata = $f->get_all;
   #printf STDERR "metadata: %s \n", Data::Dumper::Dumper($metadata);
      
   ok( $f->get('client') eq 'Joe Piscoppo', 'client is Joe Piscoppo') or die;
   ok( $f->get( 'type' ) eq 'FPE', 'type is FPE') or die;   

   my $all;
   ok( $all = $f->get_all, 'get all returns')  or die;
   ok( $all->{client}->[0] eq 'Joe Piscoppo', 'first element of client is joe piscoppo' )or die;
   ok( ref $all eq 'HASH', 'get all returns  hash ref') or die;
}


#$dbh->commit;
#undef $dbh;

#$dbh = _get_new_handle_mysql();


# test that we can retrieve with just the id






# show whats in there
my $d = Metadata::DB::File::Base->new({ DBH => $dbh });

use Smart::Comments '###';
my @got = $d->_filesystem_args_get(4);
### @got


my $dump2 = $d->table_metadata_dump;
print STDERR " # dump for meta:\n $dump2\n\n";


my $ct = $d->table_files_count;
ok($ct, "total count of files table entries: $ct");



# test get all

my $o = Metadata::DB::File->new({ DBH => $dbh , id => 1});
$o->load;
my $__meta = $o->get_all;
### $__meta


exit;




