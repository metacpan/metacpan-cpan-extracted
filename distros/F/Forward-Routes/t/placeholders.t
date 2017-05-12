use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use Forward::Routes;



#############################################################################
### basic test

my $r = Forward::Routes->new;
$r->add_route(':foo/:bar')->name('test');

my $m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

is $r->build_path('test', foo => 'hello', bar => 'there')->{path}, 'hello/there';



#############################################################################
### make sure that params with empty values behave like undef params

$r = Forward::Routes->new;
$r->add_route(':foo/:bar')->name('test');

$m = $r->match(get => 'hello/');
is $m, undef;

my $e = eval {$r->build_path('test', foo => 'hello', bar => '')->{path} };
like $@ => qr/Required param 'bar' was not passed when building a path/;

