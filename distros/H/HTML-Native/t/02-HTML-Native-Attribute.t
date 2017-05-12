#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::Attribute" );
    use_ok ( "HTML::Native::Attribute::ReadOnly" );
}

# Implicit construction

{
  my $elem = HTML::Native->new ( img => { src => "logo.png" } );
  isa_ok ( $elem->{src}, "HTML::Native::Attribute" );
  is ( $elem->{src}, "logo.png" );
}

# Explicit construction

{
  my $attr = HTML::Native::Attribute->new ( "error" );
  isa_ok ( $attr, "HTML::Native::Attribute" );
  is ( $attr, "error" );
}

# Undefined stringification

{
  my $attr = HTML::Native::Attribute->new();
  is ( $attr, "" );
}

# Undefined conversion to hash

{
  my $attr = HTML::Native::Attribute->new();
  is_deeply ( \%$attr, {} );
}

# Undefined conversion to array

{
  my $attr = HTML::Native::Attribute->new();
  is_deeply ( \@$attr, [] );
}

# Scalar stringification

{
  my $attr = HTML::Native::Attribute->new ( "error" );
  is ( $attr, "error" );
}

# Scalar conversion to hash

{
  my $attr = HTML::Native::Attribute->new ( "error" );
  is_deeply ( \%$attr, { error => 1 } );
}

# Scalar conversion to array

{
  my $attr = HTML::Native::Attribute->new ( "error" );
  is_deeply ( \@$attr, [ "error" ] );
}

# Hash stringification

{
  my $attr =
      HTML::Native::Attribute->new ( { error => 1, fatal => 1, retry => 0 } );
  is ( $attr, "error fatal" );
  $attr->{fatal} = 0;
  is ( $attr, "error" );
}

# Hash conversion to array

{
  my $attr =
      HTML::Native::Attribute->new ( { error => 1, fatal => 1, retry => 0 } );
  is_deeply ( \@$attr, [ "error", "fatal" ] );
}

# Array stringification

{
  my $attr = HTML::Native::Attribute->new ( [ qw ( error fatal ) ] );
  is ( $attr, "error fatal" );
  pop @$attr;
  is ( $attr, "error" );
}

# Array conversion to hash

{
  my $attr = HTML::Native::Attribute->new ( [ qw ( error fatal ) ] );
  is_deeply ( \%$attr, { error => 1, fatal => 1 } );
}

# Multiple conversions

{
  my $attr = HTML::Native::Attribute->new ( "error" );
  is ( $attr, "error" );
  push @$attr, "fatal";
  is ( $attr, "error fatal" );
  $attr->{fatal} = 0;
  is ( $attr, "error" );
  shift @$attr;
  is ( $attr, "" );
}

# Entity encoding

{
  my $attr = HTML::Native::Attribute->new ( "<script>" );
  is ( $attr, "&lt;script&gt;" );
}

# Dynamic generation (unblessed)

{
  my $dyn = [ qw ( error fatal ) ];
  my $attr = HTML::Native::Attribute->new ( sub { return $dyn; } );
  isa_ok ( $attr, "HTML::Native::Attribute" );
  is ( $attr, "error fatal" );
  isa_ok ( \%$attr, "HTML::Native::Attribute::ReadOnlyHash" );
  isa_ok ( \@$attr, "HTML::Native::Attribute::ReadOnlyArray" );
  ok ( $attr->{error} );
  ok ( ! exists $attr->{warning} );
  is ( @$attr, 2 );
  $dyn = [ qw ( retry ) ];
  is ( $attr, "retry" );
  dies_ok { $attr->{error} = 1 };
  dies_ok { pop @$attr };
}

# Dynamic generation (blessed, read-write)

{
  my $dyn = HTML::Native::Attribute->new ( [ qw ( error fatal ) ] );
  my $attr = HTML::Native::Attribute->new ( sub { return $dyn; } );
  isa_ok ( $attr, "HTML::Native::Attribute" );
  is ( $attr, "error fatal" );
  ok ( $attr->{error} );
  ok ( ! exists $attr->{warning} );
  is ( @$attr, 2 );
  lives_ok { $attr->{error} = 1 };
  lives_ok { pop @$attr };
}

# Dynamic generation (blessed, read-only)

{
  my $dyn = HTML::Native::Attribute::ReadOnly->new ( [ qw ( error fatal ) ] );
  my $attr = HTML::Native::Attribute->new ( sub { return $dyn; } );
  isa_ok ( $attr, "HTML::Native::Attribute" );
  is ( $attr, "error fatal" );
  ok ( $attr->{error} );
  ok ( ! exists $attr->{warning} );
  is ( @$attr, 2 );
  dies_ok { $attr->{error} = 1 };
  dies_ok { pop @$attr };
}

done_testing();
