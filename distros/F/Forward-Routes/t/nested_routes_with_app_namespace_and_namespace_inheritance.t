use strict;
use warnings;
use Test::More tests => 38;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested routes with app_namespace and namespace inheritance

# inherit namespace and app namespace
my $root = Forward::Routes->new->app_namespace('Root');
    my $nested1 = $root->add_route('foo')->namespace('Hello::Foo');
         my $nested2 = $nested1->add_route('bar')->to('Controller#action');

is $nested2->{app_namespace}, 'Root';
is $nested2->{namespace}, 'Hello::Foo';
my $m = $root->match(get => 'foo/bar');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, 'Hello::Foo';
is $m->[0]->class, 'Root::Hello::Foo::Controller';
is $m->[0]->action, 'action';



# missing namespace
$root = Forward::Routes->new->app_namespace('Root');
    $root->add_route('biz')->to('Oh#no');

$m = $root->match(post => '/biz');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'Root::Oh';
is $m->[0]->action, 'no';



# missing controller param
$root = Forward::Routes->new->app_namespace('Root');
    $root->add_route('buz')->namespace('Buz');

$m = $root->match(get => '/buz');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, 'Buz';
is $m->[0]->class, undef;
is $m->[0]->action, undef;



# nothing missing, no namespace inheritance, app namespace inheritance
$root = Forward::Routes->new->app_namespace('Root');
    $root->add_route('boz')->namespace('Boz')->to('You#me');

$m = $root->match(get => '/boz');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, 'Boz';
is $m->[0]->class, 'Root::Boz::You';
is $m->[0]->action, 'me';



# overwrite app namespace with undef
$root = Forward::Routes->new->app_namespace('Root');
    $root->add_route('undef_app_namespace')->app_namespace(undef)->to('AA#bb');

$m = $root->match(get => '/undef_app_namespace');
is $m->[0]->app_namespace, undef;
is $m->[0]->namespace, undef;
is $m->[0]->class, 'AA';
is $m->[0]->action, 'bb';



# overwrite app namespace with def value
$root = Forward::Routes->new->app_namespace('Root');
    $root->add_route('undef_app_namespace')->app_namespace('What')->to('AA#bb');

$m = $root->match(get => '/undef_app_namespace');
is $m->[0]->app_namespace, 'What';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'What::AA';
is $m->[0]->action, 'bb';



# overwrite namespace with undef, inheritance
$root = Forward::Routes->new->app_namespace('Root');
    $nested1 = $root->add_route('foo')->namespace('Hello::Foo');
         $nested2 = $nested1->add_route('bar')->to('Controller#action')->namespace(undef);
$m = $root->match(get => 'foo/bar');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'Root::Controller';
is $m->[0]->action, 'action';



# overwrite namespace with def value, inheritance
$root = Forward::Routes->new->app_namespace('Root');
    $nested1 = $root->add_route('foo')->namespace('Hello::Foo');
         $nested2 = $nested1->add_route('bar')->to('Controller#action')->namespace('Boo');
$m = $root->match(get => 'foo/bar');
is $m->[0]->app_namespace, 'Root';
is $m->[0]->namespace, 'Boo';
is $m->[0]->class, 'Root::Boo::Controller';
is $m->[0]->action, 'action';



# overwrite app namespace and namespace
$root = Forward::Routes->new->app_namespace('Root');
    $nested1 = $root->add_route('foo')->namespace('Hello::Foo');
         $nested2 = $nested1->add_route('bar')->to('Controller#action')->app_namespace('Foo')->namespace('Boo');
$m = $root->match(get => 'foo/bar');
is $m->[0]->app_namespace, 'Foo';
is $m->[0]->namespace, 'Boo';
is $m->[0]->class, 'Foo::Boo::Controller';
is $m->[0]->action, 'action';
