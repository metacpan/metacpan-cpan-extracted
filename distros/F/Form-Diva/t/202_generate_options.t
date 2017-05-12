#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

# Test Generate with the option inputs

my $diva = Form::Diva->new(
    form_name   => 'OPTIONS',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        {   n => 'empty',
            t => 'select',
            v => [],
        },
        {   name    => 'checktest',
            type    => 'checkbox',
            default => 'French',
            id      => 'checktest',
            values  => [
                qw /Argentinian American English Canadian French Irish Russian/
            ]
        },
        {
            name => 'radiotest',
            type => 'radio',
            default => 2,
            values => [ '1:This', '2:That', '3:Something Else'],
        },
        { 
            name => 'defaultzero',
            type => 'radio',
            default => 0,
            label => 'Pick A Number',
            values => [ '0:Zero', '1:One', '2:Two', ],
        },
    ],
);

my $basic = $diva->generate;

is( $basic->[0]{label},
    '<LABEL for="formdiva_empty" class="testclass">Empty</LABEL>',
    'Check the label for the select'
    );
is( $basic->[0]{input},
    q|<SELECT name="empty" id="formdiva_empty" class="form-control">
</SELECT>|,
    'Check our select input, it has no elements' );

like( $basic->[1]{input}, qr/name="checktest"/, 
    'input name is checktest');
like( $basic->[1]{input}, qr/type="checkbox"/, 
    'checktest is a checkbox');
like( $basic->[1]{input}, qr/value="French" checked/, 
    'French is checked');
like( $basic->[2]{input}, qr/name="radiotest"/, 
    'input name is radiotest');
like( $basic->[2]{input}, qr/type="radio"/, 
    'radiotest is a radio');
like( $basic->[2]{input}, qr/value="2" checked/, 
    'Value 2 is checked');
like( $basic->[3]{input},
    qr/value="0" checked="checked"/,
    "defaultzero value 0 is checked");

my $data1 = {
    checktest   => 'Canadian',
    radiotest => 1 } ;

note( 'repeat the last generation with some data');
my $basic_data = $diva->generate( $data1 );
unlike( $basic_data->[1]{input}, qr/value="French" checked/, 
    'French is no lnger checked');
like( $basic_data->[1]{input}, qr/value="Canadian" checked/, 
    'Canadian is now checked');
like( $basic_data->[2]{input}, qr/value="1" checked/, 
    'Value 1 is now checked in the radio');
unlike( $basic_data->[3]{input},
    qr/value="0" checked="checked"/,
    "defaultzero value is not checked because there was data for other fields");

note( 'override the empty list in the select');
my $over = $diva->generate( {empty => 'dog'}, { 
    empty => [ qw/ cat mouse dog rabbit deer /] }
    );
like( $over->[0]{input}, qr/rabbit/, 
    'rabbit now has an entry in select');
like( $over->[0]{input}, qr/selected>dog/, 
    'selected dog in the data and dog is now selected');

done_testing();
