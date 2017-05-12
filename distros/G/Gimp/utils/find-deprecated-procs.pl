#!/usr/local/bin/perl -w

# usage: $0 <deprecated-file> <pluginfile...>
# typically: ./utils/list-pdb-deprecations.pl <dumpfile> | $0 - examples/*

use strict;
use IO::All;

my $proc2replace = read_dep(io(shift @ARGV)->all);
$proc2replace = convert_gp($proc2replace);
#use Data::Dumper; print Dumper($proc2replace);

for my $plugin (@ARGV) {
  my $text = io($plugin)->all;
  map {
    print "$plugin: found '$_', try '$proc2replace->{$_}' instead\n";
  } grep { $text =~ /[^a-z_'"\$\/]$_[^a-z_'"]/ } keys %$proc2replace;
}

sub convert_gp {
  my $hash = shift;
  my %new;
  while (my ($k, $v) = each %$hash) {
    map { s#-#_#g } $k, $v; $new{$k} = $v;
    map { s#gimp_## } $k, $v; $new{$k} = $v unless $k eq $v or $k !~ /_/;
    map { s#script_fu_## } $k, $v; $new{$k} = $v unless $k eq $v or $k !~ /_/;
    map { s#plugin_## } $k, $v; $new{$k} = $v unless $k eq $v or $k !~ /_/;
    map { s#image_## } $k, $v; $new{$k} = $v unless $k eq $v or $k !~ /_/;
  }
  \%new;
}

sub read_dep {
  my $text = shift;
  my (
    $noexist,
    $noreplacement,
    @replacements
  ) = split /\n{2,}/, $text;
  +{
    map { %$_  } (
      parsenoreplace($noreplacement),
      map { parseblock($_) } @replacements
    )
  };
}

sub parsenoreplace {
  my ($head, @others) = split /\n/, shift;
  my %proc2replace;
  map {
    $proc2replace{$1} = 'NONE' if /(\S+)/;
  } @others;
  \%proc2replace;
}

sub parseblock {
  my ($head, @others) = split /\n/, shift;
  my $add = '';
  $add = " ($1)" if $head =~ /where the replacement has ([^:]+)/;
  my %proc2replace;
  map {
    $proc2replace{$1} = $2.$add if /"(.*?)", "(.*?)"/;
  } @others;
  \%proc2replace;
}
