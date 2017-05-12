#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Storable qw(dclone);

use_ok('Form::Diva');

# Test some of the smaller pieces that weren't tested earlier

my $diva1 = Form::Diva->new(
    form_name   => 'DIVA1',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        {   name  => 'phone',
            type  => 'tel',
            extra => 'required',
            id    => 'phonefield_setid',
        },
        {qw / n email t email l Email c form-email placeholder doormat/},
        {   name    => 'our_id',
            type    => 'number',
            extra   => 'disabled',
            default => 57,
            class => 'other-class shaded-green',
        },
        {   n => 'longtext',
            type => 'TextArea',
            placeholder => 'Type some stuff here',
        }        
    ],
);

my @fields = @{ $diva1->{FormMap} };
my $data1  = {
    name  => 'Baloney',
    phone => '232-432-2744',
};
my $data2 = {
    name   => 'Salami',
    email  => 'salami@yapc.org',
    our_id => 91,
    longtext => 'I typed things in here!',
};

note( 'testing _class_input');
is( $diva1->_class_input(), 'class="form-control"', 'bare' );
is( $diva1->_class_input( $diva1->{form}[1] ), 'class="form-control"', 
    'with field that uses default class' );
is( $diva1->_class_input( $diva1->{form}[2] ), 'class="form-email"',
    'with field that uses over-ride class' );
note( 'testing that id prefers a set id and defaults to formdiva_%fieldname');
is( $diva1->{FormHash}{email}{id}, 'formdiva_email', 
    'Email field\'s id was created for us by form diva as formdiva_email' );
is( $diva1->{FormHash}{phone}{id}, 'phonefield_setid', 
    'Phone field id is as specified');

note( 'Testing _option_id');

my @testoptionid = ( #  [ id value expected ]
    [ qw / carform pinto carform_pinto / ],
    [ qw / carform volvo carform_volvo / ],
    [ qw / truckform GMC truckform_gmc / ],
    [ qw / carform Pinto carform_pinto2 / ],
    [ 'carform', 'Ford Pinto', 'carform_ford_pinto' ],
    [ qw / truckform Dodge truckform_dodge / ],
    [ qw / carform pinto carform_pinto3 / ],
    );

my %results = ();
$diva1->_clear_id_uq;

foreach my $test ( @testoptionid ) {
    my $formid = $test->[0];
    my $optionvalue = $test->[1];
    my $expected = "id=\"$test->[2]\"";
    my $optid = $diva1->_option_id( $formid, $optionvalue );
    $results{ $optid } = 1 ;
    is( $optid, $expected, "$formid $optionvalue => $expected");
}

is ( scalar( keys %results), scalar( @testoptionid),
    "All ids generated were unique: \n" .
    "The number of unique results is the same as the number of tests: " .
    scalar( @testoptionid) );

note( 'testing _field_once');

is ( $diva1->_field_once, 1, 
    'our test used each field no more than once.' );
my $divaX = $diva1->clone ;
$divaX->{HiddenMap} = dclone $divaX->{FormMap} ;
dies_ok {$divaX->_field_once} 
    'Made HiddenMap identical to FormMap and _field_once died';

done_testing;
