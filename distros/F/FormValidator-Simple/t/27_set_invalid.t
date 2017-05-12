use strict;
use Test::More tests => 6;
use CGI;

BEGIN { use_ok("FormValidator::Simple"); }

my $q = CGI->new;
$q->param(foo => 'FooBarBaz');

my $results = FormValidator::Simple->check( $q, [
    foo => [qw/NOT_BLANK/],
] );
ok($results->valid('foo'));
ok(!$results->invalid('foo'));

$results->set_invalid(foo => 'ANOTHER_CONSTRAINT');

ok(!$results->valid('foo'));
ok($results->invalid('foo'));
ok($results->invalid('foo', 'ANOTHER_CONSTRAINT'));

