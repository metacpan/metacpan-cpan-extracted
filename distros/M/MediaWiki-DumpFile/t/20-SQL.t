use strict;
use warnings;

use Data::Dumper;
use Data::Compare; 

use Storable qw(nstore retrieve);

use Test::Simple tests => 106;

use MediaWiki::DumpFile;

my $test_file = 't/specieswiki-20091204-user_groups.sql';

my $mw = MediaWiki::DumpFile->new;
my $p = $mw->sql($test_file);
test_suite($p);

die "could not open $test_file: $!" unless open(FILE, $test_file);
$p = $mw->sql(\*FILE);
test_suite($p);

sub test_suite {
	my ($p) = @_;
	my $data = retrieve('t/specieswiki-20091204-user_groups.data');
	my @schema = $p->schema;

	ok($p->table_name eq 'user_groups');
	ok($p->table_statement eq table_statement_data());
	
	ok($schema[0][0] eq 'ug_user');
	ok($schema[0][1] eq 'int');
	
	ok($schema[1][0] eq 'ug_group');
	ok($schema[1][1] eq 'varchar');
	
	ok(! defined($schema[2]));

	while(defined(my $row = $p->next)) {
		my $test_against = shift(@$data);
		ok(Compare($test_against, $row));
	}
	
}

sub table_statement_data {
	return "CREATE TABLE `user_groups` (
  `ug_user` int(5) unsigned NOT NULL default '0',
  `ug_group` varchar(16) binary NOT NULL default '',
  PRIMARY KEY  (`ug_user`,`ug_group`),
  KEY `ug_group` (`ug_group`)
) TYPE=InnoDB;
";
}