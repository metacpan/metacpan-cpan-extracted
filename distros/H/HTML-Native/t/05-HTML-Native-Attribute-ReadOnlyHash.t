#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native::Attribute::ReadOnlyHash" );
}

# new()

{
  my $raw = { active => 1, default => 1 };
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( $raw );
  isa_ok ( $raw, "HASH" );
  isa_ok ( $hash, "HTML::Native::Attribute::ReadOnlyHash" );
}

# FETCH()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  ok ( $hash->{active} );
  ok ( $hash->{default} );
  ok ( ! $hash->{highlight} );
}

# STORE()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  dies_ok { $hash->{active} = 0; };
  dies_ok { $hash->{active} = 1; };
  dies_ok { $hash->{highlight} = 1; };
}

# DELETE()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  dies_ok { delete $hash->{active}; };
  dies_ok { delete $hash->{highlight}; };
}

# CLEAR()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  dies_ok { %$hash = (); };
}

# EXISTS()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  ok ( exists $hash->{active} );
  ok ( ! exists $hash->{highlight} );
}

# FIRSTKEY() / NEXTKEY()

{
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( {
    active => 1,
    default => 1,
  } );
  is_deeply ( [ sort keys %$hash ], [ "active", "default" ] );
  is_deeply ( [ sort values %$hash ], [ 1, 1 ] );
  while ( ( my $key, my $value ) = each %$hash ) {
    dies_ok { $hash->{$key} = ! $value; };
  }
  is_deeply ( $hash, { active => 1, default => 1 } );
}

# SCALAR()

{
  my $raw = { active => 1, default => 1 };
  my $hash = HTML::Native::Attribute::ReadOnlyHash->new ( $raw );
  ok ( scalar %$hash );
  %$raw = ();
  ok ( ! scalar %$hash );
}

done_testing();
