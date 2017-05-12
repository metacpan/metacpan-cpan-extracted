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

my $lp = $left->{prereqs};
my $rp = $right->{prereqs};

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

sub get_phase {
  return $_[0]->{path}->[0] . ' ' . $_[0]->{path}->[1];
}

sub get_module {
  return $_[0]->{path}->[2];
}

my $cache;

sub cache_key {
  my ( $type, $phase ) = @_;
  return 'Dependencies::' . ucfirst($type) . ' / ' . $phase;
}

sub add_dep {
  my ( $phase, $module, $version ) = @_;
  my $cache_key = cache_key( 'Added', $phase );
  my $dep_cache = ( $cache->{$cache_key} ||= [] );
  if ( $version eq '0' ) {
    push @{$dep_cache}, $module;
    return;
  }
  push @{$dep_cache}, $module . ' ' . $version;
  return;
}

sub remove_dep {
  my ( $phase, $module, $version ) = @_;
  my $cache_key = cache_key( 'Removed', $phase );
  my $dep_cache = ( $cache->{$cache_key} ||= [] );
  if ( $version eq '0' ) {
    push @{$dep_cache}, $module;
    return;
  }
  push @{$dep_cache}, $module . ' ' . $version;
  return;
}

sub change_dep {
  my ( $phase, $module, $old_version, $new_version ) = @_;
  my $cache_key = cache_key( 'Changed', $phase );
  my $dep_cache = ( $cache->{$cache_key} ||= [] );
  push @{$dep_cache}, $module . ' ' . $old_version . chr(0xA0) . chr(0x2192) . chr(0xA0) . $new_version;
}

sub cache_change {
  my ( $type, $path, $remove, $add ) = @_;
  if ( $type eq 'added' ) {
    return add_dep( $path->[0] . ' ' . $path->[1], $path->[2], $add );
  }
  if ( $type eq 'removed' ) {
    return remove_dep( $path->[0] . ' ' . $path->[1], $path->[2], $remove );
  }
  if ( $type eq 'changed' ) {
    return change_dep( $path->[0] . ' ' . $path->[1], $path->[2], $remove, $add );
  }
  die "unknown type $type";
}

sub change_rel {
  my ( $type, $path, $remove, $add ) = @_;
  if ( $type eq 'added' ) {

    for my $key ( sort keys %{$add} ) {
      my $new_path = [ @{$path}, $key ];
      cache_change( $type, $new_path, undef, $add->{$key} );
    }
    return;
  }
  if ( $type eq 'removed' ) {
    for my $key ( sort keys %{$remove} ) {
      my $new_path = [ @{$path}, $key ];
      cache_change( $type, $new_path, $remove->{$key}, undef );
    }
    return;
  }

  die "Unhandled change_rel $type";
}

sub change_phase {
  my ( $type, $path, $remove, $add ) = @_;
  if ( $type eq 'added' ) {

    for my $key ( sort keys %{$add} ) {
      my $new_path = [ @{$path}, $key ];
      change_rel( $type, $new_path, undef, $add->{$key} );
    }
    return;
  }
  if ( $type eq 'removed' ) {
    for my $key ( sort keys %{$remove} ) {
      my $new_path = [ @{$path}, $key ];
      change_rel( $type, $new_path, $remove->{$key}, undef );
    }
    return;
  }
  die "Unhandled change_phase $type";
}

for my $d ( data_diff( $lp, $rp ) ) {
  my $type = get_type($d);
  if ( scalar @{ $d->{path} } == 3 ) {
    cache_change( $type, $d->{path}, $d->{a}, $d->{b} );
    next;
  }
  if ( scalar @{ $d->{path} } == 2 ) {
    change_rel( $type, $d->{path}, $d->{a}, $d->{b} );
    next;
  }
  if ( scalar @{ $d->{path} } == 1 ) {
    change_phase( $type, $d->{path}, $d->{a}, $d->{b} );
    next;
  }
  die "Path not a known length";
}

binmode( *STDOUT, ':utf8' );

for my $key ( sort keys %{$cache} ) {
  print ' [' . $key . ']';
  print qq[\n];
  for my $entry ( @{ $cache->{$key} } ) {
    print ' - ' . $entry . qq[\n];
  }
  print qq[\n];
}

