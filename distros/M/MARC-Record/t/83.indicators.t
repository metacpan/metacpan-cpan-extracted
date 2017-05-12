#!perl -T

use strict;
use warnings;

use Test::More tests => 25;
use File::Spec;

use_ok( 'MARC::Record' );

my $r = MARC::Record->new();

# alphabetic indicators are legal in some dialects of MARC

$r->append_fields( MARC::Field->new( 245, 'z', 'Z', a => 'foo' ) );
is( $r->field(245)->indicator(1), 'z', 'indicator 1 can be non-numeric' );
is( $r->field(245)->indicator(2), 'Z', 'indicator 2 can be non-numeric' );

# rumor had it that invalid indicators sometimes invalidated other
# valid indicators, so these tests make sure that is not the case

$r->append_fields( MARC::Field->new( 100, 'dk', 2, a=> 'foo' ) );
is( $r->field(100)->indicator(1), ' ', 'invalid indicator squashed to space' );
is( $r->field(100)->indicator(2), 2, 'not disturbed' );
$r->append_fields( MARC::Field->new( 111, 2, '-didk', a=> 'foo' ) );
is ($r->field(111)->indicator(1), 2, 'not disturbed' );
is ($r->field(111)->indicator(2), ' ', 'invalid indicator squashed to space' );

# make sure 
eval {
    my $ind = $r->field(100)->indicator(3);
};
like($@, qr/Indicator number must be 1 or 2/, 'croaked trying to retrieve indicator 3');

## read a file which has an invalid indicator (a hyphen) and make sure it does 
## not affect a valid indicator

use_ok( 'MARC::Batch' );

my $filename = File::Spec->catfile( 't', 'badind.usmarc' );
my $batch = MARC::Batch->new( 'USMARC', $filename );
$batch->strict_off();
$batch->warnings_off();

$r = $batch->next();
my @warnings = $batch->warnings();
is( $warnings[0], 'Invalid indicator "-" forced to blank', 
    'got expected warning message' );

is( $r->field(245)->indicator(1),' ','hyphen forced to blank in indicator 1' );
is( $r->field(245)->indicator(2),'0','indicator 2 undisturbed' );


CONTROLFIELD: {
    my $field;
    
    $field = MARC::Field->new( '003', 'ICrlF' );
    is( scalar($field->warnings()), 0, 'no warnings for field' );
    ok( !defined $field->indicator(1), 'indicator(1) for control field returns undef' );
    is( scalar($field->warnings()), 1, 'indicator(1) for control field generates warning' );

    $field = MARC::Field->new( '003', 'ICrlF' );
    is( scalar($field->warnings()), 0, 'no warnings for field' );
    ok( !defined $field->indicator(2), 'indicator(2) for control field returns undef' );
    is( scalar($field->warnings()), 1, 'indicator(2) for control field generates warning' );
}

# check indicator setting
my $field = MARC::Field->new('245', ' ', '0', a => 'The wind in the wilows' );
is( $field->indicator(1), ' ', 'first indicator starts as blank' );
$field->set_indicator(1, '0' );
is( $field->indicator(1), '0', 'first indicator is now 0' );
is( $field->indicator(2), '0', 'second indicator starts as 0' );
$field->set_indicator(2, '4' );
is( $field->indicator(2), '4', 'second indicator is now 4' );
eval {
    $field->set_indicator(3, 'a');
};
like( $@, qr/Indicator number must be 1 or 2/, 'cannot set indicator value at invalid position' );
eval {
    $field->set_indicator(1, "\n");
};
like( $@, qr/Indicator value is invalid/, 'cannot set indicator to invalid value' );
my $control_field = MARC::Field->new('003', 'abc');
eval {
    $control_field->set_indicator(1, ' ');
};
like( $@, qr/Cannot set indicator for control field/, 'cannot set indicator for control field' );
