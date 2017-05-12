use strict;
use warnings;
use Test::More tests => 15;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested resources and namespaces


# magazine routes
my $r = Forward::Routes->new;
my $ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => undef);

my $m = $r->match(get => 'magazines');
is $m->[0]->name, 'admin_magazines_index';
is $m->[0]->class, 'Admin::Magazines';



$m = $r->match(get => 'magazines/3');
is_deeply $m->[0]->captures, {id => 3};



$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines__ads_create_form';
is $m->[0]->class, 'Ads';
is $ads->name, 'admin_magazines__ads';


$m = $r->match(get => 'magazines/3/ads/4');
is_deeply $m->[0]->captures, {magazine_id => 3, id => 4};


# nested routes inherit namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_ads_create_form';
is $m->[0]->class, 'Admin::Ads';

is $ads->name, 'admin_magazines_ads';


# nested routes also has namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => 'Admin');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_ads_create_form';
is $m->[0]->class, 'Admin::Ads';


# controller namespace organized exactly as resource nesting
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => 'Admin::Magazines');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_admin_magazines_ads_create_form';
is $m->[0]->class, 'Admin::Magazines::Ads';

is $ads->name, 'admin_magazines_admin_magazines_ads';
