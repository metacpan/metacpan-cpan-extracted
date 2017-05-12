use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use Forward::Routes;



#############################################################################
### resources with multiple customizations


my $r = Forward::Routes->new;
$r->add_resources(
    'users',
    'pictures' => -constraints => {id => qr/\d{6}/}, -as => 'photos',
      -namespace => 'Admin',
    'tags'
);

my $m = $r->match(get => '/pictures/123456');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 123456};
is $m->[0]->class, 'Admin::Photos';

is $r->build_path('admin_photos_show', id => 123456)->{path} => 'pictures/123456';

# constraint works
$m = $r->match(get => '/pictures/123');
is $m, undef;

