use Test::More tests=>2;

use_ok ("HTTP::Server::Simple::Static");
ok (HTTP::Server::Simple::Static->isa("Exporter"));
