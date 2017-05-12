#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

=pod Test radio buttons and checkboxes

Reminder when writing/modifying tests involving _option_input:

%id_uq needs to be cleared before each test invoking _option_input.
normally generate would do this but when we're testing 
private methods this isn't happening.

=cut

my $radio1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'radiotest', t => 'radio', 
        v => [ qw /American English Canadian/ ] },
    ],
);

my $check1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { name => 'checktest', type => 'checkbox', 
        values => [ qw /French Irish Russian/ ] },
    ],
);

my $labels1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { name => 'withlabels', type => 'radio', default => 1,
        values => [ 
        	"1:Peruvian Music", 
        	"2:Argentinian Dance",
        	"3:Cuban" ] },
    ],
);

my ($newform) = $radio1->_expandshortcuts( $radio1->{form} );

my $testradio1values = $newform->[0]{values};
is( $newform->[0]{type}, 'radio', 
		'input is radio');
is( $testradio1values->[2], 'Canadian', 'Test _expandshortcuts for values' );

my $radio_nodata_expected =<< 'RNDX' ;
<input type="radio" class="form-control"  name="radiotest" id="formdiva_radiotest_american" value="American" >American<br>
<input type="radio" class="form-control"  name="radiotest" id="formdiva_radiotest_english" value="English" >English<br>
<input type="radio" class="form-control"  name="radiotest" id="formdiva_radiotest_canadian" value="Canadian" >Canadian<br>
RNDX

my $radio1_data_expected =<< 'RDX' ;
<input type="radio" class="form-control" name="radiotest" id="formdiva_radiotest_american" value="American">American<br>
<input type="radio" class="form-control" name="radiotest" id="formdiva_radiotest_english" value="English">English<br>
<input type="radio" class="form-control" name="radiotest" id="formdiva_radiotest_canadian" value="Canadian" checked="checked">Canadian<br>
RDX

my $check_nodata_expected =<< 'CNDX' ;
<input type="checkbox" class="form-control" name="checktest" id="formdiva_checktest_french" value="French">French<br>
<input type="checkbox" class="form-control" name="checktest" id="formdiva_checktest_irish" value="Irish">Irish<br>
<input type="checkbox" class="form-control" name="checktest" id="formdiva_checktest_russian" value="Russian">Russian<br>
CNDX

my $labels1_nodata_expected =<< 'NDDX';
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_1" value="1" checked="checked">Peruvian Music<br>
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_2" value="2">Argentinian Dance<br>
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_3" value="3">Cuban<br>
NDDX

my $labels1_data_expected =<< 'NDDX1';
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_1" value="1">Peruvian Music<br>
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_2" value="2" checked="checked">Argentinian Dance<br>
<input type="radio" class="form-control" name="withlabels" id="formdiva_withlabels_3" value="3">Cuban<br>
NDDX1

$radio1->_clear_id_uq;
my $radio1_nodata = $radio1->_option_input( $radio1->{form}[0] );
is( $radio1_nodata, $radio_nodata_expected, 'generated as 3 radio buttons.');

my @radio1_data = @{ $radio1->generate( { radiotest => 'Canadian' })} ;
is( $radio1_data[0]->{input}, $radio1_data_expected, 'Set Radio1 with Canadian Checked');
my @check1_nodata = @{ $check1->generate };
is( $check1_nodata[0]->{input}, $check_nodata_expected, 'generated as 3 checkboxes.');

my @labels1_nodata = @{ $labels1->generate} ;
is( $labels1_nodata[0]->{input}, $labels1_nodata_expected , 
	'Default checked is Peruvian Music');
my @labels1_data = @{ $labels1->generate( { withlabels => 2 })} ;
is( $labels1_data[0]->{input}, $labels1_data_expected , 
    'With Data check Argentinian Dance instead.');

my $classoverride1 = Form::Diva->new(
    form_name   => 'override',
    label_class => 'testclass',
    input_class => 'form-control',
    form        => [
        { n => 'radiotest', t => 'radio', c => 'not-default', extra =>'disabled',
        v => [ qw /American English Canadian/ ] },
    ],
);

like( $labels1_nodata[0]->{input}, qr/class="form-control"/ ,
		"The default class is being used." );
my @classoverridden = @{$classoverride1->generate};
like( $classoverridden[0]->{input}, qr/class="not-default"/ ,
		"The default class has been overridden." );
like( $classoverridden[0]->{input}, qr/disabled/ ,
		"Check the extra field, we set value to disabled." );

my $over_ride_checkbox = $classoverride1->generate( 
    { radiotest => 'Venus' }, { radiotest => [ qw / Mars Venus Earth Jupiter /] } );
like( $over_ride_checkbox->[0]{input} , qr/value="Venus" checked="checked">Venus/,
    'overridden checkbox Venus is selected');
unlike( $over_ride_checkbox->[0]{input} , qr/Canadian/, 'overridden value is not present' );
done_testing();
