use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use Encoding::HandleUtf8 qw( fix_encoding );

############################################################################
# GitHub issue #2 Not a SCALAR reference.

subtest 'GitHub issue 2 - Not a SCALAR reference' => sub {
  plan tests => 2;
  my %hash = ( foo => 'bar' );
  my $hashref = \%hash;

  {
    local $@;
    eval { fix_encoding( input => %hash ) };
    my $err = $@;
    ok( !$err, 'passing hash by value' );
    diag($err) if $err;
  }

  {
    local $@;
    eval { fix_encoding( input => $hashref ) };
    my $err = $@;
    ok( !$err, 'passing hash by reference' );
    diag($err) if $err;
  }

};

############################################################################
1;
