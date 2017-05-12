use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use Forward::Routes;



#############################################################################
### resources with custom id constraint


my $r = Forward::Routes->new;
$r->add_resources(
    'users',
    'photos' => -constraints => {id => qr/\d{6}/},
    'tags'
);

my $m = $r->match(get => 'photos/123456');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 123456};

$m = $r->match(get => 'photos/12345');
is $m, undef;

$m = $r->match(get => 'photos/abc123456');
is $m, undef;



$m = $r->match(get => 'tags/abc123456');
is_deeply $m->[0]->params => {controller => 'Tags', action => 'show', id => 'abc123456'};

