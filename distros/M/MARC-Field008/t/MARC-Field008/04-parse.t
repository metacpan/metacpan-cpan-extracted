use strict;
use warnings;

use MARC::Leader;
use MARC::Field008;
use Test::More 'tests' => 73;
use Test::NoWarnings;

# Test.
diag('book');
## cnb000000096
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Field008->new(
	'leader' => $leader,
);
my $field_008 = '830304s1982    xr a         u0|0 | cze';
my $ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '830304', 'Get date entered on file (830304).');
is($ret->date1, '1982', 'Get date1 (1982).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::Book');
# TODO Material
is($ret->material_type, 'book', 'Get material type (book).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008.'  ', 'Get raw ('.$field_008.'  ).');
is($ret->type_of_date, 's', 'Get type of date (s).');

# Test.
diag('computer file');
## cnb000208289
$leader = MARC::Leader->new->parse('01720cmm a2200373 a 4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '971107s1997    xr         m        cze  ';
$ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '971107', 'Get date entered on file (971107).');
is($ret->date1, '1997', 'Get date1 (1997).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::ComputerFile');
# TODO Material
is($ret->material_type, 'computer_file', 'Get material type (computer_file).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008, 'Get raw ('.$field_008.').');
is($ret->type_of_date, 's', 'Get type of date (s).');

# Test.
diag('continuing resource');
## cnb000002514
$leader = MARC::Leader->new->parse('01220nas a2200337   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '830725d19811987xr zr        u0    |cze  ';
$ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '830725', 'Get date entered on file (830725).');
is($ret->date1, '1981', 'Get date1 (1981).');
is($ret->date2, '1987', 'Get date2 (1987).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::ContinuingResource');
# TODO Material
is($ret->material_type, 'continuing_resource', 'Get material type (continuing_resource).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008, 'Get raw ('.$field_008.').');
is($ret->type_of_date, 'd', 'Get type of date (d).');

# Test.
diag('map');
## cnb000001006
$leader = MARC::Leader->new->parse('02117cem a2200541 i 4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '830210s1982    xr z      e     1   cze  ';
$ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '830210', 'Get date entered on file (830210).');
is($ret->date1, '1982', 'Get date1 (1982).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::Map');
# TODO Material
is($ret->material_type, 'map', 'Get material type (map).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008, 'Get raw ('.$field_008.').');
is($ret->type_of_date, 's', 'Get type of date (s).');

# Test.
diag('mixed material');
## fake record.
# TODO

# Test.
diag('music');
## cnb000012142
$leader = MARC::Leader->new->parse('01860ncm a2200493   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '860418s1985    xr sgz g       nn   cze  ';
$ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '860418', 'Get date entered on file (860418).');
is($ret->date1, '1985', 'Get date1 (1985).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::Music');
# TODO Material
is($ret->material_type, 'music', 'Get material type (music).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008, 'Get raw ('.$field_008.').');
is($ret->type_of_date, 's', 'Get type of date (s).');

# Test.
diag('visual material');
## cnb000027064
$leader = MARC::Leader->new->parse('01298ckm a2200385   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '951020s1984    xr nnn g          kncze  ';
$ret = $obj->parse($field_008);
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '951020', 'Get date entered on file (951020).');
is($ret->date1, '1984', 'Get date1 (1984).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::VisualMaterial');
# TODO Material
is($ret->material_type, 'visual_material', 'Get material type (visual_material).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, $field_008, 'Get raw ('.$field_008.').');
is($ret->type_of_date, 's', 'Get type of date (s).');
