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
        [ { n => 'secret', id => 'our_secret' }, 
        { n => 'hush', default => 'very secret' }, ],    
);

my $nodata = $diva1->hidden ;
my $xnodata = '<INPUT type="hidden" name="secret" id="our_secret" value="">
<INPUT type="hidden" name="hush" id="formdiva_hush" value="very secret">
';
my $data = $diva1->hidden( 
    { secret => 'tell no one', hush => 'so secret' }
    );
my $xdata = '<INPUT type="hidden" name="secret" id="our_secret" value="tell no one">
<INPUT type="hidden" name="hush" id="formdiva_hush" value="so secret">
';

is( $nodata, $xnodata, 'generate the hidden block with no data');
is(     $data, $xdata, 'generate the hidden block with data');




done_testing;