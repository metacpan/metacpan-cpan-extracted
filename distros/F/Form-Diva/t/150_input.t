#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'fullname', t => 'text', p => 'Your Name', l => 'Full Name' },
        {   name  => 'phone',
            type  => 'tel',
            extra => 'required',
            id    => 'not name',
        },
        {qw / n email t email l Email c form-email placeholder doormat/},
        {   name    => 'our_id',
            type    => 'number',
            extra   => 'disabled',
            default => 57,
        },
        {   n           => 'longtext',
            type        => 'TextArea',
            placeholder => 'Type some stuff here',
        },
        { name => 'trivial', class => 'ignorable' },
    ],
);

my @fields = @{ $diva1->{FormMap} };
my $data1  = {
    fullname => 'Baloney',
    phone    => '232-432-2744',
};
my $data2 = {
    name     => 'Salami',
    email    => 'salami@yapc.org',
    our_id   => 91,
    longtext => 'I typed things in here!',
    secret   => 'I won&rsquo;t tell',
};

my $name_no_data_tr = $diva1->_input( $fields[0], undef );

# There seems like extra space in some of the qr//, this is deliberate
# to ensure that there is space between elements.
# note("Input Element for name_no_data_tr\n$name_no_data_tr");
like(
    $name_no_data_tr,
    qr/^<INPUT type="text"/,
    'begins with: <input type="text"'
);
like( $name_no_data_tr, qr/>$/,       'ends with >' );
like( $name_no_data_tr, qr/value=""/, 'Empty Value: value="" ' );
like( $name_no_data_tr, qr/name="fullname"/,
    'has fieldname: name="fullname"' );
like(
    $name_no_data_tr,
    qr/ placeholder="Your Name"/,
    'PlaceHolder is set: placeholder="Your Name"'
);
unlike( $name_no_data_tr, qr/placeholder="placeholder/,
    'Bug Test: this should not be: placeholder="placeholder' );
unlike( $name_no_data_tr, qr/"\w""/,
    'Bug Test: should never see two quotes like this: "\w""' );

my $name_data1_tr = $diva1->_input( $fields[0], $data1 );
#note("Input Element for name_data1_tr: $name_data1_tr");
like( $name_data1_tr, qr/ value="Baloney"/, 'Value set: value="Baloney" ' );

my $ourid_no_data_tr = $diva1->_input( $fields[3] );
#note("Input Element for Our_ID no Data $ourid_no_data_tr");
like( $ourid_no_data_tr, qr/ type="number" /, 'input type is number' );
like( $ourid_no_data_tr, qr/value="57"/,      'Value defaulted: value="57"' );
like( $ourid_no_data_tr, qr/disabled/,        'Extra specified disabled' );

my $ourid_no_data2_tr = $diva1->_input( $fields[3], $data2 );
#note("Input Element for Our_ID Data2 $ourid_no_data2_tr");
like( $ourid_no_data2_tr, qr/value="91"/,
    'Value is not default but actual value: value="91"' );

my $textarea_tr = $diva1->_input( $fields[4], );
#note("Input Element for textarea $textarea_tr");
like( $textarea_tr, qr/^<TEXTAREA/, 'tag is TEXTAREA' );
my $textarea_data2_tr = $diva1->_input( $fields[4], $data2 );
#note("Input Element for textarea with data2 $textarea_data2_tr");
like(
    $textarea_data2_tr,
    qr/>I typed things in here!<\/TEXTAREA>/,
    'TextArea has value and closing tag'
);
unlike( $textarea_data2_tr, qr/"\w""/,
    'Bug Test: textarea should never have two quotes like this: "\w""' );

note('Test a field where we only provided a name.');
my $trivial_tr = $diva1->_input( $fields[5], );
like( $trivial_tr, qr/name="trivial"/, 'Input has field name' );
like( $trivial_tr, qr/type="text"/,    'Input is a text field' );
like( $trivial_tr, qr/class="ignorable"/,
    'class over-ride set class to ignorable' );
unlike( $trivial_tr, qr/form-control/,
    'the default class isnt in the input' );

done_testing;

