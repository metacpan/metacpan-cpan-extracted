use strict;
use warnings;
use Test::More tests => 32;
use lib 'lib';
use Forward::Routes;



#############################################################################
### resources and namespaces

# just app namespace
my $r = Forward::Routes->new->app_namespace('My');
my $ads = $r->add_resources('magazines');

my $m = $r->match(get => 'magazines');
is $m->[0]->name, 'magazines_index';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'My::Magazines';



# add namespace in resource
$r = Forward::Routes->new->app_namespace('My');
$ads = $r->add_resources('magazines' => -namespace => 'Admin');

$m = $r->match(get => 'magazines');
is $m->[0]->name, 'admin_magazines_index';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, 'Admin';
is $m->[0]->class, 'My::Admin::Magazines';



# nested resources, just app namespace
$r = Forward::Routes->new->app_namespace('My');
$ads = $r->add_resources('magazines')
  ->add_resources('ads');

$m = $r->match(get => 'magazines/4');
is $m->[0]->name, 'magazines_show';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'My::Magazines';

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'magazines_ads_create_form';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, undef;
is $m->[0]->class, 'My::Ads';



# nested resources, app namespace and namespace
$r = Forward::Routes->new->app_namespace('My');
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads');

$m = $r->match(get => 'magazines/4');
is $m->[0]->name, 'admin_magazines_show';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, 'Admin';
is $m->[0]->class, 'My::Admin::Magazines';

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_ads_create_form';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, 'Admin';
is $m->[0]->class, 'My::Admin::Ads';



# nested resources, app namespace and namespace in different format
$r = Forward::Routes->new->app_namespace('My');
$ads = $r
  ->add_route->namespace('Admin')
    ->add_resources('magazines')
      ->add_resources('ads');

$m = $r->match(get => 'magazines/4');
is $m->[0]->name, 'admin_magazines_show';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, 'Admin';
is $m->[0]->class, 'My::Admin::Magazines';

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_ads_create_form';
is $m->[0]->app_namespace, 'My';
is $m->[0]->namespace, 'Admin';
is $m->[0]->class, 'My::Admin::Ads';
