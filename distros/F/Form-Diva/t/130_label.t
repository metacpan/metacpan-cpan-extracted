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
            id    => 'phonefieldid',
        },
        {qw / n email t email l Email c form-email placeholder doormat/},
        {   name    => 'our_id',
            type    => 'number',
            extra   => 'disabled',
            default => 57,
        },
        {   name    => 'label_over',
            type    => 'text',
            label_class => 'not_that_class we_can_override_label_class',
            label   => 'Label Over-Ride',
        },

    ],
);

my $diva2 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        {   n => 'radiotest',
            t => 'radio',
            v => [qw /American English Canadian/]
        },
        { qw/ n secret t hidden /},
    ],
);

my @fields      = @{ $diva1->{FormMap} };
my @radiofields = @{ $diva2->{FormMap} };
foreach my $test (
    [   $diva1->_label( $fields[0] ),
        '<LABEL for="formdiva_fullname" id="formdiva_fullname_label" class="testclass">Full Name</LABEL>'
    ],
    [   $diva1->_label( $fields[1] ),
        '<LABEL for="phonefieldid" id="phonefieldid_label" class="testclass">Phone</LABEL>'
    ],
    [   $diva1->_label( $fields[2] ),
        '<LABEL for="formdiva_email" id="formdiva_email_label" class="testclass">Email</LABEL>'
    ],
    [   $diva1->_label( $fields[3] ),
        '<LABEL for="formdiva_our_id" id="formdiva_our_id_label" class="testclass">Our_id</LABEL>'
    ],
    [   $diva1->_label( $fields[4] ),
        '<LABEL for="formdiva_label_over" id="formdiva_label_over_label" class="not_that_class we_can_override_label_class">Label Over-Ride</LABEL>'
    ],    
    [   $diva2->_label( $radiofields[0] ),
        '<LABEL for="formdiva_radiotest" id="formdiva_radiotest_label" class="testclass">Radiotest</LABEL>'
    ],
    )
{
    is( $test->[0], $test->[1], "$test->[1]" );
}

done_testing;
