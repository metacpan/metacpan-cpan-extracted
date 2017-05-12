use strict;
use warnings;
use Test::More tests => 73;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested resources

my $r = Forward::Routes->new;

my $ads = $r->add_resources('magazines')->add_resources('ads');

$ads->add_member_route('test_member');
$ads->add_collection_route('test_collection');

# magazine routes work
my $m = $r->match(get => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'index'};

$m = $r->match(get => 'magazines/new');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create_form'};

$m = $r->match(post => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create'};

$m = $r->match(get => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'show', id => 1};

$m = $r->match(get => 'magazines/1/edit');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update_form', id => 1};

$m = $r->match(get => 'magazines/1/delete');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete_form', id => 1};

$m = $r->match(put => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update', id => 1};

$m = $r->match(delete => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete', id => 1};

is $ads->name, 'magazines_ads';

ok $r->find_route('magazines_ads_test_member');
ok $r->find_route('magazines_ads_test_collection');

# nested ads routes work
$m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'index', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create_form', magazine_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'show', magazine_id => 1, id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'update_form', magazine_id => 1, id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'update', magazine_id => 1, id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'delete', magazine_id => 0, id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'delete_form', magazine_id => 11, id => 12};

$m = $r->match(post => 'magazines/1.2/ads');
is $m, undef;



# build path
is $r->build_path('magazines_ads_index', magazine_id => 3)->{path} => 'magazines/3/ads';
is $r->build_path('magazines_ads_index', magazine_id => 3)->{method} => 'get';

is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{path} => 'magazines/4/ads/new';
is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_create', magazine_id => 5)->{path} => 'magazines/5/ads';
is $r->build_path('magazines_ads_create', magazine_id => 5)->{method} => 'post';

is $r->build_path('magazines_ads_show', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4';
is $r->build_path('magazines_ads_show', magazine_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_update', magazine_id => 0, id => 4)->{path} => 'magazines/0/ads/4';
is $r->build_path('magazines_ads_update', magazine_id => 0, id => 4)->{method} => 'put';

is $r->build_path('magazines_ads_delete', magazine_id => 4, id => 0)->{path} => 'magazines/4/ads/0';
is $r->build_path('magazines_ads_delete', magazine_id => 4, id => 0)->{method} => 'delete';

is $r->build_path('magazines_ads_update_form', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4/edit';
is $r->build_path('magazines_ads_update_form', magazine_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_delete_form', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4/delete';
is $r->build_path('magazines_ads_delete_form', magazine_id => 3, id => 4)->{method} => 'get';


my $e = eval {$r->build_path('magazines_ads_index')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show', magazine_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_delete_form', magazine_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;



#############################################################################
### deeper nesting
$r = Forward::Routes->new;

my $stats = $r->add_resources('magazines')->add_resources('ads')->add_resources('stats');

$m = $r->match(get => 'magazines/1/ads/4/stats/7');
is_deeply $m->[0]->params => {controller => 'Stats', action => 'show', magazine_id => 1, ad_id => 4, id => 7};
is $m->[0]->name, 'magazines_ads_stats_show';


is $r->build_path('magazines_ads_stats_show', magazine_id => 3, ad_id => 4, id => 5)->{path} => 'magazines/3/ads/4/stats/5';
is $r->build_path('magazines_ads_stats_show', magazine_id => 3, ad_id => 4, id => 5)->{method} => 'get';

is $stats->name, 'magazines_ads_stats';

# magazines resource still works
$m = $r->match(get => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'index'};

$m = $r->match(get => 'magazines/new');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create_form'};

$m = $r->match(post => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create'};

$m = $r->match(get => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'show', id => 1};

$m = $r->match(get => 'magazines/1/edit');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update_form', id => 1};

$m = $r->match(get => 'magazines/1/delete');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete_form', id => 1};

$m = $r->match(put => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update', id => 1};

$m = $r->match(delete => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete', id => 1};



# ads resource still works
$m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'index', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create_form', magazine_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'show', magazine_id => 1, id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'update_form', magazine_id => 1, id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'update', magazine_id => 1, id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'delete', magazine_id => 0, id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'delete_form', magazine_id => 11, id => 12};

$m = $r->match(post => 'magazines/1.2/ads');
is $m, undef;



# constraint for parent id
$r = Forward::Routes->new;

$ads = $r->add_resources('magazines' => -constraints => {id => qr/[\d]{2}/})
  ->add_resources('ads');

$m = $r->match(get => 'magazines/1');
is $m, undef;

$m = $r->match(get => 'magazines/22');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'show', id => 22};

$m = $r->match(get => 'magazines/1/ads/4');
is $m, undef;

$m = $r->match(get => 'magazines/22/ads/4');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'show', magazine_id => 22, id => 4};


#############################################################################
### with -as option

$r = Forward::Routes->new;
$r->add_resources('magazines')->add_resources('advertising', -as => 'ads');


$m = $r->match(get => 'magazines/1/advertising/new');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create_form', magazine_id => 1};

$m = $r->match(post => 'magazines/1/advertising');
is_deeply $m->[0]->params => {controller => 'Ads', action => 'create', magazine_id => 1};


is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{path} => 'magazines/4/advertising/new';
is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_create', magazine_id => 5)->{path} => 'magazines/5/advertising';
is $r->build_path('magazines_ads_create', magazine_id => 5)->{method} => 'post';


$e = eval {$r->build_path('magazines_ads_index')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;

