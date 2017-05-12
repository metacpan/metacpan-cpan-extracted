use strict;
use warnings;
use Test::More tests => 6;

use Forward::Routes;


#############################################################################
### method tests

my $m = Forward::Routes::Match->new;

is $m->name, undef;

is $m->_set_name('hello'), $m;
is $m->name, 'hello';

is $m->_set_name('you'), $m;
is $m->name, 'you';


#############################################################################
### nested

my $r = Forward::Routes->new;
my $nested = $r->add_route('articles')->name('one');
$nested->add_route('comments')->name('two');

$m = $r->match(get => 'articles/comments');
is $m->[0]->name, 'two';
