# vim:ft=perl
use Test::More;
use lib 'ex';
BEGIN { if (eval { require DBD::SQLite }) {
            plan tests => 2;
        } else { Test::More->import(skip_all =>"SQLite not working: $@") }
      }


package BeerDB;
use base qw(Apache::MVC Maypole::Component);
use Class::DBI::Loader::Relationship;
BEGIN { BeerDB->setup("dbi:SQLite:t/beerdb.db"); }
BeerDB->config->{uri_base} = "http://localhost/beerdb/";
BeerDB->config->{template_root} = "t/templates";
package BeerDB::Beer;
sub view_as_comp :Exported {};
package main;

use Maypole::Constants;
BeerDB->init;
my $data = BeerDB->component("/frontpage");
like($data, qr/Root/, "Included root");
like($data, qr/Organic Best/, "Included subcomponent");
