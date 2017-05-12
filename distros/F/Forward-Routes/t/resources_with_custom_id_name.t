use strict;
use warnings;
use Test::More tests => 8;
use lib 'lib';
use Forward::Routes;



#############################################################################
### resources with custom id name (and id constraint)


my $r = Forward::Routes->new;
my $photos = $r->add_resources(
    'photos' => -id_name => 'image_id', -constraints => {image_id => qr/\d{6}/},
);

my $m = $r->match(get => 'photos/123456');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', image_id => 123456};

$m = $r->match(get => 'photos/12345');
is $m, undef;

$m = $r->match(get => 'photos/abc123456');
is $m, undef;



# nested
$r = Forward::Routes->new;
$photos = $r->add_resources(
    'photos' => -id_name => 'image_id', -constraints => {image_id => qr/\d{6}/},
);
$photos->add_resources('comments');

$m = $r->match(get => 'photos/123456/comments/3');
is_deeply $m->[0]->params => {controller => 'Comments', action => 'show', image_id => 123456, id => 3};

$m = $r->match(get => 'photos/12346/comments/3');
is $m, undef;


# nested
$r = Forward::Routes->new;
$photos = $r->add_resources(
    'photos' => -id_name => 'image_id', -constraints => {image_id => qr/\d{6}/},
);
$photos->add_resources('comments', -id_name => 'test', -constraints => {test => qr/\d{3}/});

$m = $r->match(get => 'photos/123456/comments/333');
is_deeply $m->[0]->params => {controller => 'Comments', action => 'show', image_id => 123456, test => 333};

$m = $r->match(get => 'photos/12346/comments/333');
is $m, undef;

$m = $r->match(get => 'photos/123456/comments/33');
is $m, undef;
