#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 40;

require_ok('Medical::Growth::NHANES_2000');

package Testme::Collector;

use Module::Pluggable
  require     => 0,
  inner       => 0,
  search_path => 'Medical::Growth::NHANES_2000',
  except      => 'Medical::Growth::NHANES_2000::Base';

package main;

# Simple handle
my $h = Medical::Growth::NHANES_2000->new;

is_deeply(
    [ sort Testme::Collector->plugins ],
    [ sort $h->measure_classes ],
    'all measure classes'
);

foreach my $t (
    [ 'BMI_for_Age', 'Child',  'Male',   'BMI_for_Age::Child::Male' ],
    [ 'BMIAge',      'Child',  'Female', 'BMI_for_Age::Child::Female' ],
    [ 'HC by Age',   'Infant', 'Male',   'HC_for_Age::Infant::Male' ],
    [
        'Head Circumference for Age', 'Infant',
        'Male',                       'HC_for_Age::Infant::Male'
    ],
    [ 'OFCAge',        'Infant', 'Female', 'HC_for_Age::Infant::Female' ],
    [ 'HtAge',         'Infant', 'Female', 'Length_for_Age::Infant::Female' ],
    [ 'Height by Age', 'Infant', 2,        'Length_for_Age::Infant::Female' ],
    [ 'Height for Age', 'Adolescent', 'Male', 'Height_for_Age::Child::Male' ],
    [ 'HgtAge',     'Child',     'Girls',  'Height_for_Age::Child::Female' ],
    [ 'HtAge',      'Recumbent', 'Female', 'Length_for_Age::Infant::Female' ],
    [ 'LenAge',     'Neonatal',  'Female', 'Length_for_Age::Infant::Female' ],
    [ 'Length Age', 'Infant',    'Boys',   'Length_for_Age::Infant::Male' ],
    [ 'Weight Length', 'Infant', 'Boys', 'Weight_for_Length::Infant::Male' ],
    [ 'Weight for Height', 'Child', 'Boys', 'Weight_for_Height::Child::Male' ],
    [ 'Length for Age', 'School-age', 1,      'Height_for_Age::Child::Male' ],
    [ 'Weight for Age', 'Child',      'Male', 'Weight_for_Age::Child::Male' ],
    [ 'WgtAge',    'Child',  'Female', 'Weight_for_Age::Child::Female' ],
    [ 'WeightAge', 'Infant', 'Male',   'Weight_for_Age::Infant::Male' ],
    [ 'WtAge',     'Infant', 'Female', 'Weight_for_Age::Infant::Female' ]
  )
{
    my ( $meas, $ag, $sex, $suffix ) = @$t;
    my $rslt = $suffix ? qr/^Medical::Growth::NHANES_2000::$suffix/ : undef;
    like(
        eval {
            $h->measure_class_for(
                measure   => $meas,
                age_group => $ag,
                sex       => $sex
            );
        }
          || $@,
        $rslt,
        "measure_class_for: $meas, $ag, $sex"
    );
}

is(
    $h->measure_class_name_for(
        measure   => 'BMIAge',
        age_group => 'Infant',
        sex       => 'Male'
    ),
    'Medical::Growth::NHANES_2000::BMI_for_Age::Infant::Male',
    'name ok for non-existent class'
);

is(
    $h->measure_class_name_for(
        measure => 'BMIAge',
        age     => 42.5,
        sex     => 'Male'
    ),
    'Medical::Growth::NHANES_2000::BMI_for_Age::Child::Male',
    'age substitutes for age_group'
);

is(
    $h->measure_class_name_for(
        measure => 'BMIAge',
        age     => 0,
        sex     => 'Male'
    ),
    'Medical::Growth::NHANES_2000::BMI_for_Age::Infant::Male',
    'age of 0 OK'
);

my $rslt = eval {
    $h->measure_class_name_for(
        measure   => 'No_Measure',
        age_group => 'Infant',
        sex       => 'Male'
    );
};
my $err = $@;
ok( !$rslt, 'exception for non-existent measure' );
like(
    $err,
    qr/Don't understand measure spec 'No_Measure'/,
    'error message - non-existent measure'
);

$rslt = eval {
    $h->measure_class_name_for(
        measure   => 'BMI_for_Grade',
        age_group => 'Child',
        sex       => 'Male'
    );
};
$err = $@;
ok( !$rslt, 'exception for non-existent norm' );
like(
    $err,
    qr/Don't understand norm name in 'BMI_for_Grade'/,
    'error message - non-existent norm'
);

$rslt = eval {
    $h->measure_class_name_for(
        measure   => 'BMIAge',
        age_group => 'Adult',
        sex       => 'Male'
    );
};
$err = $@;
ok( !$rslt, 'exception for non-existent age group' );
like(
    $err,
    qr/Don't understand age group 'Adult'/,
    'error message - non-existent age group'
);

$rslt = eval {
    $h->measure_class_name_for(
        measure   => 'BMIAge',
        age_group => 'Infant',
        sex       => 'Unknown'
    );
};
$err = $@;
ok( !$rslt, 'exception for non-existent sex' );
like(
    $err,
    qr/Don't understand sex 'Unknown'/,
    'error message - non-existent sex'
);

$rslt =
  eval { $h->measure_class_name_for( measure => 'BMIAge', sex => 'Unknown' ); };
$err = $@;
ok( !$rslt, 'exception for missing age_group' );
like(
    $err,
    qr/Need to specify measure, age_group, and sex/,
    'error message - missing age_group'
);

$rslt = eval {
    $h->measure_class_name_for(
        measure   => 'BMIAge',
        age_group => 'Infant'
    );
};
$err = $@;
ok( !$rslt, 'exception for missing sex' );
like(
    $err,
    qr/Need to specify measure, age_group, and sex/,
    'error message - missing sex'
);

$rslt = eval {
    $h->measure_class_name_for(
        age_group => 'Infant',
        sex       => 'Unknown'
    );
};
$err = $@;
ok( !$rslt, 'exception for missing measure' );
like(
    $err,
    qr/Need to specify measure, age_group, and sex/,
    'error message - missing measure'
);

ok(
    $h->have_measure_class_for(
        measure   => 'BMIAge',
        age_group => 'Child',
        sex       => 'Male'
    ),
    'test load of class we have'
);

ok(
    !$h->have_measure_class_for(
        measure   => 'BMIAge',
        age_group => 'Infant',
        sex       => 'Male'
    ),
    "test load of class we don't have"
);

