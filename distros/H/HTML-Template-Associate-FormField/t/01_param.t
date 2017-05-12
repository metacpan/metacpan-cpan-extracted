use strict;

use Test::More tests => 4;
use HTML::Template::Associate::FormField;

my %hash= (
 foo1=> 'ok1',
 foo2=> 'ok2',
 );

my $form = HTML::Template::Associate::FormField->new(\%hash);
my $query= $form->{query};

ok($query->isa('HTML::Template::Associate::FormField::Param'));
ok($query->param('foo1'));

$query->param('foo1', '');

ok(! $query->param('foo1'));

$query->param('foo1', 'ok1');
$query->param('foo3', 'ok3');

is($query->param, 3);

