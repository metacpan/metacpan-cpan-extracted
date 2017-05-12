#!perl -T

use Test::More tests => 3;
use strict;
use warnings;

use_ok('HTML::GUI::text');
use_ok('HTML::GUI::screen');
my $widget = HTML::GUI::widget->new({
				type		=> 'text',
				id			=> "bla",
				constraints => ['integer','required'],
				value=> 'je vais vous manger !! éàüù"',
		});
isa_ok($widget, 'HTML::GUI::widget');
