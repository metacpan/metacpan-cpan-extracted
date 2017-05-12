use Test::More tests=>8;

use_ok(HTTP::Server::Simple);
ok(HTTP::Server::Simple->can('new'), 'can new()');
my $s= HTTP::Server::Simple->new();
isa_ok($s,'HTTP::Server::Simple');
is($s->port(),8080,'Defaults to 8080');
is($s->port(13432),13432,'Can change port');
is($s->port(),13432,'Change persists');
ok($s->can('print_banner'), 'can print_banner()');
ok($s->can('run'), 'can run()');
