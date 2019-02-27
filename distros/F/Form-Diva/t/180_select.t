#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use_ok('Form::Diva');
# use Carp::Always;

=pod Test Select Inputs

Reminder when writing/modifying tests involving _option_input:

%id_uq needs to be cleared before each test invoking _option_input.
normally generate would do this but when we're testing 
private methods this isn't happening.

=cut

my $select1 = Form::Diva->new(
    form_name   => 'SELECT1',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        {   n => 'selecttest',
            t => 'select',
            v => [qw /usa:American uk:English can:Canadian/],
        },
    ],
);

my $select2 = Form::Diva->new(
    form_name   => 'SELECT2',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        {   n => 'empty',
            t => 'select',
            v => [],
        },
    ],
);

my $select3 = Form::Diva->new(
    form_name   => 'SELECT3',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        {   name    => 'checktest',
            type    => 'select',
            default => 'French',
            id      => 'checktest',
            values  => [
                qw /Argentinian American English Canadian French Irish Russian/
            ]
        },
    ],
);

my ($newform) = $select1->_expandshortcuts( $select1->{form} );

is( $newform->[0]{type}, 'select', 'check _expandshortcuts type is select' );

my $input_select3_default = 
 q |<SELECT name="checktest" id="checktest"  class="form-control">
 <option value="Argentinian" id="checktest_argentinian" >Argentinian</option>
 <option value="American" id="checktest_american" >American</option>
 <option value="English" id="checktest_english" >English</option>
 <option value="Canadian" id="checktest_canadian" >Canadian</option>
 <option value="French" id="checktest_french" selected >French</option>
 <option value="Irish" id="checktest_irish" >Irish</option>
 <option value="Russian" id="checktest_russian" >Russian</option>
</SELECT>|;

$select1->_clear_id_uq ; 
unlike( $select1->_option_input( $select1->{form}[0], undef ),
    qr/selected/,
    'select1 does not have a default, with no data nothing is selected' );

$select1->_clear_id_uq ; 

my $uk_selected = $select1->_option_input( 
    $select1->{FormHash}{selecttest}, 
        { selecttest => 'uk' });

like(
    $uk_selected,
    qr/uk" selected/,
    'select1 with uk as data English is now selected'
);
like(
    $uk_selected,
    qr/usa" >American/,
    'select1 with uk as data "usa">American has tag and not selected'
);

my $empty_input_nodata = 
    qq|<SELECT name="empty" id="formdiva_empty"  class="form-control">\n</SELECT>|;

$select2->_clear_id_uq();    
is( $select2->_option_input( $select2->{form}[0] ) ,
    $empty_input_nodata ,
    'select2 has no values provided and returns with no option elements');
my $select2_no_data = $select2->generate ;
is( $select2_no_data->[0]{label}, 
    '<LABEL for="formdiva_empty" id="formdiva_empty_label" class="testclass">Empty</LABEL>',
    'Check the label on the empty one');
# remove extra space because generate does.
$empty_input_nodata =~ s/\s//g;
my $generated_empty_input = $select2_no_data->[0]{input};
$generated_empty_input =~ s/\s//g;
is( $generated_empty_input, 
    $empty_input_nodata,
    'Generate returned input of a few tests ago, with some space removed' );

$select3->_clear_id_uq;
my $input3a = $select3->_option_input( $select3->{form}[0], undef, );
is( $input3a, $input_select3_default, 
    'A select with different labels than values.' );

$select2->_clear_id_uq;
my $over_ride2 = $select2->_option_input( 
    $select2->{form}[0], undef, [ qw / yellow orange red / ] );
like( $over_ride2, qr/red/, 
    'Empty Select with Override now has one of the new vaues' )   ;
unlike( $over_ride2, qr/selected/, 
    'Empty Select with Override has no selected because it was given undef' )   ;

$select3->_clear_id_uq;
my $over_ride3 = $select3->_option_input( 
    $select3->{form}[0], 
    { checktest => 'pear' }, 
    [ qw / apple orange pear / ] );
unlike ( $over_ride3, qr/French/, 
    'Select with Override does not contain an original option value');
like( $over_ride3, qr/apple/, 
    'Select with Override does contain one of the new values' )   ;
like( $over_ride3, qr/<option value="pear" id="checktest_pear" selected >/,
    'pear is selected in the Override select');

my $over_ride4 = $select3->generate( 
    { checktest  => 'banana' , pet => 'poodle' },
    { checktest => [ qw / banana grape peach plum / ] } );

like( $over_ride4->[0]{input} , qr/banana/,
    'banana is in the new list from generate');
unlike( $over_ride4->[0]{input} , qr/Canadian/, 'Canadian has been removed' );


done_testing();
