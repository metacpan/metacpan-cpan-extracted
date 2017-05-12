#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

if ( @ARGV != 2 ) {
  warn "Expected: delta_deps OLD.JSON NEW.JSON";
}

use JSON;
use Data::Dump qw( pp );
use Path::Tiny qw( path );
use Data::Difference qw( data_diff );

my $transcoder = JSON->new();
my $left       = $transcoder->decode( path( $ARGV[0] )->slurp );
my $right      = $transcoder->decode( path( $ARGV[1] )->slurp );

for my $bad (qw( prereqs x_Dist_Zilla x_BuiltWith )) {
  delete $left->{$bad};
  delete $right->{$bad};
}

sub get_type {
  if ( not exists $_[0]->{b} and exists $_[0]->{a} ) {
    return 'removed';
  }
  if ( exists $_[0]->{b} and not exists $_[0]->{a} ) {
    return 'added';
  }
  if ( exists $_[0]->{b} and exists $_[0]->{a} ) {
    return 'changed';
  }
  die "Unhandled combination";
}

my $colors = {
  added   => "\e[32m",
  removed => "\e[31m",
  changed => "\e[34m",
};
binmode( *STDOUT, ':utf8' );

sub prefix_data {
  my ( $prefix, $suffix, $data ) = @_;
  my (@lines) = split qq[\n], $data;
  return join q[], map { $prefix . $_ . $suffix } @lines;
}

for my $d ( data_diff( $left, $right ) ) {
  my $type  = get_type($d);
  my $color = $colors->{$type};
  print "$color$type\e[0m: " . join q[/], @{ $d->{path} };
  print qq[\n];
  if ( $type eq 'added' ) {
    print prefix_data( qq[+\t ] . $color, qq{\e[0m\n}, pp( $d->{b} ) );
  }
  if ( $type eq 'removed' ) {
    print prefix_data( qq[-\t ] . $color, qq{\e[0m\n}, pp( $d->{a} ) );
  }
  if ( $type eq 'changed' ) {
    print prefix_data( qq[-\t ] . $colors->{removed}, qq{\e[0m\n}, pp( $d->{a} ) );
    print prefix_data( qq[+\t ] . $colors->{added},   qq{\e[0m\n}, pp( $d->{b} ) );
  }
}
