use strict;
use warnings;
use Test::More;
use Module::Runtime qw( use_module );

use lib 't/lib';
use TestUtil;

my @roles = qw(
  Backend
  ObjectReader
  ObjectWriter
  RefReader
  RefWriter
);

my @todo = qw(
  Cogit-RefWriter
  Git::PurePerl-RefWriter
);

for my $backend ( available_backends() ) {
    for my $role (@roles) {
        local $TODO = "$role not implemented for $backend"
          if grep /$backend-$role/, @todo;
        ok(
            use_module("Git::Database::Backend::$backend")
              ->does("Git::Database::Role::$role"),
            "$backend does $role"
        );
        last if $backend eq 'None';
    }
}

done_testing;
