use lib qw( ./lib ../lib );
use Test::More tests => 6;

BEGIN {
	use_ok 'Egg::Release::DBI';
	use_ok 'Egg::Model::DBI';
	use_ok 'Egg::Model::DBI::Base';
	use_ok 'Egg::Model::DBI::dbh';
	use_ok 'Egg::Mod::EasyDBI';
	use_ok 'Egg::Plugin::EasyDBI';
	};
