#!perl -T

use Test::More tests => 15;
use strict;
use warnings;

use_ok('HTML::GUI::log::event');
use_ok('HTML::GUI::log::error');
use_ok('HTML::GUI::log::eventList');
use_ok('HTML::GUI::text');

#First test an error for a particular widget
my $widget = HTML::GUI::text->new({
		id			=> "myUnikId",
		constraints => ['integer','required'],
		value=> 'je vais vous manger !! éàüù"',
		label => 'The test label of my input'
});

ok($widget,"check the test widget");

my $eventError = new HTML::GUI::log::error({visibility => 'pub',
				'error-type' =>'constraint',
				'constraint-info' => {widgetLabel => "L'âge du capitaine!",
																 'constraint-name' => 'required'},
				widgetSrc => $widget,
				message => 'blabla error'});

ok($eventError,"Can create an error object");

isa_ok($eventError, 'HTML::GUI::log::event');
isa_ok($eventError, 'HTML::GUI::log::error');

is($eventError->getDtHtml(),'<dt>The test label of my input</dt>' );
is($eventError->getDdHtml(),"<dd>The input &quot;L'âge du capitaine!&quot; is mandatory.<a href=\"#myUnikId\">Fix it.</a></dd>" );

#Second test an error without a particular widget

my $eventError2 = new HTML::GUI::log::error({visibility => 'pub',
								'error-type' => 'internal',
								message => 'My custom error message'});

is($eventError2->getDtHtml(),'<dt>General</dt>' );
is($eventError2->getDdHtml(),"<dd>My custom error message</dd>" );

#now we test a list of error
my $eventList = HTML::GUI::log::eventList->new();
is($eventList->getHtml(),'');

$eventList->addEvent($eventError2);
is($eventList->getHtml(),'<div class="errorList"><h2 class="errorList">Some errors occured.</h2><dl class="errorList"><dt>General</dt><dd>My custom error message</dd></dl></div>');

$eventList->addEvent($eventError);
is($eventList->getHtml(),'<div class="errorList"><h2 class="errorList">Some errors occured.</h2><dl class="errorList"><dt>General</dt><dd>My custom error message</dd><dt>The test label of my input</dt><dd>The input &quot;L\'âge du capitaine!&quot; is mandatory.<a href="#myUnikId">Fix it.</a></dd></dl></div>');
