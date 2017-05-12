use strict;
use warnings;
use Test::More tests => 5;
use lib 'lib';
use Forward::Routes;



#############################################################################
### no path passed to match

my $r = Forward::Routes->new;
$r->add_route('/')->defaults(first_name => 'foo', last_name => 'bar')->name('one');

my $m = $r->match(get => '');
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar'};

is $r->build_path('one')->{path}, '';


#############################################################################
# exception

eval {$m = $r->match(get => undef)};
like $@, qr/Forward::Routes->match: missing path/;

eval {$m = $r->match('get')};
like $@, qr/Forward::Routes->match: missing path/;

eval {$m = $r->match('')};
like $@, qr/Forward::Routes->match: missing request method/;
