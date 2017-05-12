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
    hidden =>
        [ { n => 'secret' }, 
        { n => 'hush', default => 'very secret' }, ],    
);

my @fields = @{ $diva1->{HiddenMap} };
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

my $secret_nodata = [ 
    $diva1->_input_hidden( $fields[0], undef ),
    q|<INPUT type="hidden" name="secret" id="formdiva_secret" value="">| ];

my $secret_data   = [ 
    $diva1->_input_hidden( $fields[0], $data2 ),
    q|<INPUT type="hidden" name="secret" id="formdiva_secret" value="I won&rsquo;t tell">| ];
my $hush_nodata = [
    $diva1->_input_hidden( $fields[1], undef ),
    q|<INPUT type="hidden" name="hush" id="formdiva_hush" value="very secret">|] ;
my $hush_data   = [
    $diva1->_input_hidden( $fields[1], $data2 ),
    q|<INPUT type="hidden" name="hush" id="formdiva_hush" value="">| ];

foreach my $test ( 
    $secret_nodata, $secret_data, $hush_nodata, $hush_data ) {
     is( $test->[0], $test->[1], substr( $test->[1], 0, 60 ) );
}

done_testing;