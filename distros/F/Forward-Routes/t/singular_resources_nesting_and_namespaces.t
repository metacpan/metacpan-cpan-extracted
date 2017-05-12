use strict;
use warnings;
use Test::More tests => 10;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested resources and namespaces

# magazine routes
my $r = Forward::Routes->new;
my $ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager' => -namespace => undef);

my $m = $r->match(get => 'magazines');
is $m->[0]->name, 'admin_magazines_index';
is $m->[0]->class, 'Admin::Magazines';

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines__manager_create_form';
is $m->[0]->class, 'Manager';


# nested routes inherit namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager');

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_manager_create_form';
is $m->[0]->class, 'Admin::Manager';


# nested routes also has namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager' => -namespace => 'Admin');

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_manager_create_form';
is $m->[0]->class, 'Admin::Manager';


# controller namespace organized exactly as resource nesting
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager' => -namespace => 'Admin::Magazines');

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_admin_magazines_manager_create_form';
is $m->[0]->class, 'Admin::Magazines::Manager';
