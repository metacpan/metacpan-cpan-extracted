use strict;
use warnings;

use File::Object;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator::Filter::Plugin::Material;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = MARC::Validator::Filter::Plugin::Material->new;
my $marc_record = MARC::File::XML->in($data_dir->file('cnb000000204-aacr2.xml')->s)->next;
my $ret = $obj->process($marc_record);
is($ret, 'material_book', 'Get filter string (material_book).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000208289-material_computer_file.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, 'material_computer_file', 'Get filter string (material_computer_file).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000089171-material_continuing_resource.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, 'material_continuing_resource', 'Get filter string (material_continuing_resource).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000002494-material_map.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, 'material_map', 'Get filter string (material_map).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000062676-music.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, 'material_music', 'Get filter string (material_music).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('cnb000096591-visual_material.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, 'material_visual_material', 'Get filter string (material_visual_material).');

# Test.
$obj = MARC::Validator::Filter::Plugin::Material->new;
$marc_record = MARC::File::XML->in($data_dir->file('fake1-incorrect_leader.xml')->s)->next;
$ret = $obj->process($marc_record);
is($ret, undef, 'Get filter string (undef - incorrect leader).');
