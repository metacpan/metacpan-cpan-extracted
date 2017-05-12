#!perl -T

use Test::More tests => 1;
use Test::Exception;

use HTML::FormHandlerX::Form::Login;

my $form;

lives_ok {
	$form = HTML::FormHandlerX::Form::Login->new();
} "Constructed ok";


