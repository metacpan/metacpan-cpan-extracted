use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Dist::Zooky::License');

{
  my $license = Dist::Zooky::License->new( metaname => 'perl' );
  isa_ok( $license, 'Dist::Zooky::License' );
  is( ref $license->license, 'ARRAY', 'License is an arrayref' );
  is( scalar @{ $license->license }, 1, 'There is one item' );
  isa_ok( $license->license->[0], 'Software::License' );
  isa_ok( $license->license->[0], 'Software::License::Perl_5' );
}

{
  my $license = Dist::Zooky::License->new( metaname => 'perl_5' );
  isa_ok( $license, 'Dist::Zooky::License' );
  is( ref $license->license, 'ARRAY', 'License is an arrayref' );
  is( scalar @{ $license->license }, 1, 'There is one item' );
  isa_ok( $license->license->[0], 'Software::License' );
  isa_ok( $license->license->[0], 'Software::License::Perl_5' );
}

{
  my $license = Dist::Zooky::License->new( metaname => 'apache' );
  isa_ok( $license, 'Dist::Zooky::License' );
  is( ref $license->license, 'ARRAY', 'License is an arrayref' );
  is( scalar @{ $license->license }, 2, 'There are two items' );
  for ( @{ $license->license } ) {
    isa_ok( $_, 'Software::License' );
    like( ref $_, qr/^Software\:\:License\:\:Apache/, 'Looks like an Apache license' );
  }
}

