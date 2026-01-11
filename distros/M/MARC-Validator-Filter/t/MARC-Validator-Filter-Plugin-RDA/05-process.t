use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Filter::Plugin::RDA;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Filter::Plugin::RDA->new;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb000000168-rda.xml')->s)->next;
my $ret = $obj->process($marc_record);
is($ret, 'rda', 'Get filter string (rda).');

# Test.
$obj = MARC::Validator::Filter::Plugin::RDA->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000000204-aacr2.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, undef, 'Get filter string (undef - no rda record).');

# Test.
$obj = MARC::Validator::Filter::Plugin::RDA->new;
$marc_record = MARC::File::XML->in($data_dir->file('fake1-incorrect_leader.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, undef, 'Get filter string (undef - incorrect leader).');

# Test.
$obj = MARC::Validator::Filter::Plugin::RDA->new;
$marc_record = MARC::File::XML->in($data_dir->file('fake2-040e.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, undef, 'Get filter string (undef - field 040 e different than rda).');
