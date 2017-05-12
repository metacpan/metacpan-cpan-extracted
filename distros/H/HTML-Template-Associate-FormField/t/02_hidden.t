use strict;

use Test::More tests=> 8;
use HTML::Template::Associate::FormField;

my $hash= {
 foo1=> 'ok1',
 foo2=> 'ok2',
 };

my $hidden= HTML::Template::Associate::FormField->hidden_out($hash);

#> 1
ok($hidden->isa('HTML::Template::Associate::FormField::Hidden'));

$hidden->set('foo3', 'ok foo');

#> 2
ok($hidden->get('foo3'));

$hidden->unset('foo3');

#> 3
ok($hidden->exists('foo3') ? 0: 1);

#> 4
{
	my $get= $hidden->get || "";
	my @chk= $get=~/(ok[12])/gs;
	is(@chk, 2);
}

#> 5
{
	$hidden->unset('foo2');
	my $get= $hidden->get || "";
	my @chk= $get=~/(ok[12])/gs;
	is(@chk, 1)
}

#> 6
ok($hidden->exists);

#> 7
ok($hidden->exists('foo1'));

$hidden->clear;

#> 8
ok(! $hidden->exists);

