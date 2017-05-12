use strict;
use warnings;
use Test::More tests => 31;
use MARC::Field;

# Test is_controlfield_tag

foreach my $i (1..9) {
  my $field = MARC::Field->new('00' . $i, 'TestData $i');
  ok($field->is_control_field, "$i identified as control field");
}

# Should not be control fields
foreach my $i (qw(010 011 555 FMT)) {
  my $field = MARC::Field->new($i, 0, 0, 'a', 'Hello');
  ok(!$field->is_control_field, "Non-control showing up as such for $i");
}

# Add the FMT
MARC::Field->allow_controlfield_tags('FMT');

foreach my $i (qw(001 002 003 004 005 FMT)) {
  my $field = MARC::Field->new( $i, "TestData $i");
  ok($field->is_control_field, "$i correctly identified as control field");
  is($field->data, "TestData $i", "Got it back out");
}

# Take it out again

MARC::Field->disallow_controlfield_tags('FMT');

foreach my $i ('FMT') {
  my $field = MARC::Field->new( $i, 0, 0, 'a', 'Test');
  ok(!$field->is_control_field, "$i identified as data field");
  is($field->subfield('a'), 'Test', "Got it back out");
}

# Add the FMT
MARC::Field->allow_controlfield_tags('FMT');

# See if it throws an error trying to make a datafield out of a control field

foreach my $i ('FMT', '001') {
  my $field = MARC::Field->new( $i, 0, 0, 'a', 'Test');
  like(join(' ', $field->warnings), qr/too much data/i, "Caught error trying to make datafield out of controlfield '$i'");
};

# Take it out again

MARC::Field->disallow_controlfield_tags('*');

# See if it throws an error trying to make a control field out of a data field

foreach my $i ('FMT', '010') {
  eval {
    my $field = MARC::Field->new($i, 'Test');
  };
  like($@, qr/must have indicators/, "Correctly got error trying to make control field out of '$i'");
  
}


