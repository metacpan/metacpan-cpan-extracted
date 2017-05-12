use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::ByInode;

my $abs_loc = '/tmp';
my $filename = time.'mbi.db';
my $abs_db = $abs_loc.'/'.$filename;
my $ondisk = time;
my $inode = (stat $abs_db)[1]; 


my $m;
ok ( $m = new Metadata::ByInode({ abs_dbfile => $abs_db }),
	'1 object instanced' );

ok($m->dbh, 
	'2 dbh() returns');


ok($inode = Metadata::ByInode::_get_inode($abs_db),
	'3 get inode:'.$inode);

ok($m->set($inode, { abs_loc => $abs_loc, filename => $filename, ondisk => $ondisk }),
	'4 set');

ok( $m->_search_inode($abs_db) == $inode,
	'5 _search_inode() in db by abs path');

ok( ref $m->get_all($inode) eq 'HASH',
	'6 i get all');
ok( $m->get($inode, 'filename') eq $filename,
	'7 i get');
ok( $m->get($inode, 'ondisk') == $ondisk,
	'8 i get');
ok( $m->get($inode, 'abs_loc') eq $abs_loc,
	'9 i get');

ok( ref $m->get_all($abs_db) eq 'HASH',
	'10 d get all');
ok( $m->get($abs_db, 'filename') eq $filename,
	'11 d get');
ok( $m->get($abs_db, 'ondisk') == $ondisk,
	'12 d get');
ok( $m->get($abs_db, 'abs_loc') eq $abs_loc,
	'13 d get');

unlink $abs_db;

