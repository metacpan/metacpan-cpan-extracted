package Rdb::DB::Object;

use Rdb::DB;

use base qw(Rose::DB::Object);
my $h;
sub init_db { 
	my $rdb = Rdb::DB->new(); 
	$h = $rdb->dbh;
	# Rdb::DB->default_domain('dev');
	return $rdb;
}

sub get_handler{ return $h;}
1;
