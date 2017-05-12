#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw{ no_plan };

BEGIN{
	use_ok( q{For::Else} );
}

{
  my $name = 'no else, empty foreach';

  my $value;

  foreach ( () ) {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, empty foreach, local variable';

  my $value;

  foreach my $item ( () ) {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, empty for';

  my $value;

  for ( () ) {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, empty for, local variable';

  my $value;

  for my $item ( () ) {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, empty foreach';

  my $value = 1;

  foreach ( () ) {
    $value++;
  }
  else {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, empty foreach, local variable';

  my $value = 1;

  foreach my $item ( () ) {
    $value++;
  }
  else {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, empty for';

  my $value = 1;

  for ( () ) {
    $value++;
  }
  else {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, empty for, local variable';

  my $value = 1;

  for my $item ( () ) {
    $value++;
  }
  else {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty foreach';

  my $value = 1;

  my @items = 1..5;

  foreach ( @items ) {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty foreach, local variable';

  my $value = 1;

  my @items = 1..5;

  foreach my $item ( @items ) {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty for';

  my $value = 1;

  my @items = 1..5;

  for ( @items ) {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty for, local variable';

  my $value = 1;

  my @items = 1..5;

  for my $item ( @items ) {
    $value = undef;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, non-empty foreach';

  my $value = 1;

  my @items = 1..5;

  foreach ( @items ) {
    $value = undef;
  }
  else {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty foreach, local variable';

  my $value = 1;

  my @items = 1..5;

  foreach my $item ( @items ) {
    $value = undef;
  }
  else {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'else, non-empty for';

  my $value = 1;

  my @items = 1..5;

  for ( @items ) {
    $value = undef;
  }
  else {
    $value++;
  }

  is( $value, undef, $name );
}

{
  my $name = 'no else, non-empty for, local variable';

  my $value = 1;

  my @items = 1..5;

  for my $item ( @items ) {
    $value = undef;
  }
  else {
    $value++;
  }

  is( $value, undef, $name );
}
