#!perl 

use Test::More tests => 13;
use strict;
use warnings;

use utf8;
use_ok('HTML::GUI::screen');

#We add a dummy function in the HTML::GUI::widget module
#to test if it's possible to call the closecallback function
sub HTML::GUI::widget::dialogTestCallbackFunction{
		my ($screen,$dialogValues)=@_;
		
		my $newValue = $dialogValues->{testField} ||"";
		$screen->setValue({bla => $newValue});
		return 1;
}

#can we test the openCallBack Function ?
sub HTML::GUI::widget::openTestCallbackFunction{
		my ($screen,$params)=@_;
		$screen->setValue({testField	 => $params->{newValue}});
	
		return 1;
}

#start the tests now
my $screen = HTML::GUI::screen->new({id => "my_screen",
		dialogCallBack=> "HTML::GUI::widget::dialogTestCallbackFunction" });

ok($screen,"Construct a new screen");
$screen->addChild({
				type		=> 'text',
				id			=> "bla",
				value=> '',
		});

my $screenValues = $screen->getValueHash();

is($screenValues->{bla},'',"The screen is created with an empty field");

#bootstrap => define a good root directory
HTML::GUI::widget->setRootDirectory('');
my $screenFileName = $0;
$screenFileName =~ s/12-dialog.t$/12-dialog-screen.yaml/;

#we open a dialog to get the value
$screen->openDialog($screenFileName,{ newValue => 'Romero'});

$screen = $screen->getNextScreen(); #this action is done by the engine

#open the dialog
ok($screen,"It seems we managed to open the dialog");

my $input = $screen->getElementById('testField');

ok($input,"The dialog is opened, We manged to get the input");
is('Romero',$input->getValue(),"The dialog is opened, The openCallback function has set the value of the widget");


$screen->closeDialog($screen->getValueHash());

$screen = $screen->getNextScreen(); #this action is done by the engine

#close the dialog
ok($screen,"it seems we managed to close the dialog");

$screenValues = $screen->getValueHash();

is($screenValues->{bla},"Romero","The value of the dialog arrived in the original screen");


my $screenWithoutCallback = HTML::GUI::screen->new({id => "my_screen", });

ok($screenWithoutCallback,"Construct a new screen with na callbacko");
$screenWithoutCallback->addChild({
				type		=> 'text',
				id			=> "bla",
				value=> 'Original value',
		});

$screenWithoutCallback->openDialog($screenFileName);

$screenWithoutCallback = $screenWithoutCallback->getNextScreen(); #this action is done by the engine

#open the dialog
ok($screenWithoutCallback,"It seems we managed to open the dialog");

 $input = $screenWithoutCallback->getElementById('testField');
ok($input,"The dialog is opened, We manged to get the input");

$input->setValue("My test value");

$screenWithoutCallback->closeDialog($screenWithoutCallback->getValueHash());

$screenWithoutCallback = $screenWithoutCallback->getNextScreen(); #this action is done by the engine

#close the dialog
ok($screenWithoutCallback,"it seems we managed to close the dialog");

is($screenWithoutCallback->getValueHash()->{bla},'Original value',"The original screen didn't change because there is no callback");
