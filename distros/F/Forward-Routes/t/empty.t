use strict;
use warnings;
use Test::More tests => 5;
use lib 'lib';
use Forward::Routes;


# path, but only root object exists
my $r = Forward::Routes->new;

my $m = $r->match(get => '/');
is $m, undef;

$m = $r->match(get => '');
is $m, undef;


# base route defined via slash
$r = Forward::Routes->new;
$r->add_route('/')->via('get')->name('home');

$m = $r->match(get => '');
isa_ok $m->[0], 'Forward::Routes::Match';

$m = $r->match(get => '/');
isa_ok $m->[0], 'Forward::Routes::Match';

is $r->build_path('home')->{path}, '';
