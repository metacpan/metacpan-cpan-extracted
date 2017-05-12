use strict;
use warnings;
use Test::More tests => 12;
use lib 'lib';
use Forward::Routes;



#############################################################################
# bridge with namespace inheritance
my $root = Forward::Routes->new->namespace('Root');
$root->bridge('hi')->to('One#two')->namespace('My::Bridges')
  ->add_route('there')->to('Three#four');

my $m = $root->match(get => '/hi/there');
is $m->[0]->namespace, 'My::Bridges';
is $m->[1]->namespace, 'My::Bridges';
is $m->[0]->class, 'My::Bridges::One';
is $m->[0]->action, 'two';
is $m->[1]->class, 'My::Bridges::Three';
is $m->[1]->action, 'four';


$root = Forward::Routes->new->namespace('Root');
$root->bridge('hi')->to('One#two')
  ->add_route('here')->to('Three#four')->namespace('My::Bridges');

$m = $root->match(get => '/hi/here');
is $m->[0]->namespace, 'Root';
is $m->[1]->namespace, 'My::Bridges';
is $m->[0]->class, 'Root::One';
is $m->[0]->action, 'two';
is $m->[1]->class, 'My::Bridges::Three';
is $m->[1]->action, 'four';
