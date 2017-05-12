use Test::More tests => 3;
use HTTP::Router;
use HTTP::Router::Debug;

my $r = HTTP::Router->new;
can_ok $r => 'routing_table';
can_ok $r => 'show_table';
isa_ok $r->routing_table => 'Text::SimpleTable';
