#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native::Attribute::ReadOnlyArray" );
}

# new()

{
  my $raw = [ qw ( active default ) ];
  my $array = HTML::Native::Attribute::ReadOnlyArray->new ( $raw );
  isa_ok ( $raw, "ARRAY" );
  isa_ok ( $array, "HTML::Native::Attribute::ReadOnlyArray" );
}

# FETCH()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  is ( $array->[0], "active" );
  is ( $array->[1], "default" );
}

# STORE()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { $array->[0] = "active"; };
  dies_ok { $array->[1] = ""; };
  dies_ok { $array->[2] = "hello"; };
}

# FETCHSIZE()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  is ( @$array, 2 );
}

# STORESIZE() / EXTEND()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { @$array = (); };
  dies_ok { $#$array = 10; };
}

# EXISTS()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  ok ( exists $array->[0] );
  ok ( exists $array->[1] );
  ok ( ! exists $array->[2] );
}

# DELETE()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { delete $array->[1]; };
}

# CLEAR()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { @$array = (); };
}

# PUSH()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { push @$array, "hello"; };
}

# POP()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { pop @$array; };
}

# SHIFT()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { shift @$array; };
}

# UNSHIFT()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { unshift @$array, "hello"; };
}

# SPLICE()

{
  my $array = HTML::Native::Attribute::ReadOnlyArray->new (
    [ qw ( active default ) ]
  );
  dies_ok { splice @$array, 0, 1 };
}

done_testing();
