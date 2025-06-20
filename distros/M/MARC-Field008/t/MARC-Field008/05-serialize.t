use strict;
use warnings;

use MARC::Leader;
use MARC::Field008;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
## cnb000000096
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Field008->new(
	'leader' => $leader,
);
my $field_008 = '830304s1982    xr a         u0|0 | cze';
my $data = $obj->parse($field_008);
my $ret = $obj->serialize($data);
is($ret, $field_008.'  ', 'Get serialized string (book - "'.$field_008.'  ").');

# Test.
## cnb000208289
$leader = MARC::Leader->new->parse('01720cmm a2200373 a 4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '971107s1997    xr         m        cze  ';
$data = $obj->parse($field_008);
$ret = $obj->serialize($data);
is($ret, $field_008, 'Get serialized string (computer file - "'.$field_008.'").');

# Test.
## cnb000002514
$leader = MARC::Leader->new->parse('01220nas a2200337   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '830725d19811987xr zr        u0    |cze  ';
$data = $obj->parse($field_008);
$ret = $obj->serialize($data);
is($ret, $field_008, 'Get serialized string (continuing resource - "'.$field_008.'").');

# Test.
$leader = MARC::Leader->new->parse('02117cem a2200541 i 4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '830210s1982    xr z      e     1   cze  ';
$data = $obj->parse($field_008);
$ret = $obj->serialize($data);
is($ret, $field_008, 'Get serialized string (map - "'.$field_008.'").');

# Test.
diag('mixed material');
# TODO

# Test.
$leader = MARC::Leader->new->parse('01860ncm a2200493   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '860418s1985    xr sgz g       nn   cze  ';
$data = $obj->parse($field_008);
$ret = $obj->serialize($data);
is($ret, $field_008, 'Get serialized string (music - "'.$field_008.'").');

# Test.
$leader = MARC::Leader->new->parse('01298ckm a2200385   4500');
$obj = MARC::Field008->new(
	'leader' => $leader,
);
$field_008 = '951020s1984    xr nnn g          kncze  ';
$data = $obj->parse($field_008);
$ret = $obj->serialize($data);
is($ret, $field_008, 'Get serialized string (music - "'.$field_008.'").');
