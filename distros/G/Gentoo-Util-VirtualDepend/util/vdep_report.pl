#!/usr/bin/env perl
# FILENAME: vdep_check.pl
# CREATED: 06/02/15 12:43:42 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Show result of CPAN version deltas in terms of virtuals.

use 5.020;
use warnings;

use Data::Dump qw( pp );
use Gentoo::Util::VirtualDepend;
use Module::CoreList;
use List::UtilsBy qw( sort_by uniq_by );
use Gentoo::PerlMod::Version qw( gentooize_version );
my $v = Gentoo::Util::VirtualDepend->new();

my $modvers = $Module::CoreList::version{'5.020002'};

my $table = {};
for my $module (keys %{$modvers}) {
  my $version = get_value( $modvers, $module );

  my $override = "untracked";
  if ( $v->has_module_override($module) ) {
    $override = $v->get_module_override($module);
  }

  do_log(" module $module resolves to: $override");

  $table->{$override} //= {};
  $table->{$override}->{$module} = $version;
}

for my $key ( keys %$table ) {
  next if $key eq 'untracked';
  my $entries = $table->{$key};
  my (@versions) = uniq_by { "$_" } values %{$entries};
  if (1 == @versions) {
    $table->{$key}  = [ $versions[0]  ];
  }
}

for my $key ( sort keys %$table ) {
  next if $key eq 'untracked';
  if ( ref $table->{$key} eq 'ARRAY' ) {
      my $v = gentooize_version( $table->{$key}->[0], { lax => 1 } );
      printf "%-40s%-30s\n", $key, $v;
      next;
  }
  printf "\e[31m%s\e[0m:\n---\t\t%s\n", $key, pp $table->{$key};
}

sub get_value {
  return '(absent)' unless exists $_[0]->{ $_[1] };
  return '(undef)'  unless defined $_[0]->{ $_[1] };
  return $_[0]->{ $_[1] };
}

use constant DEBUG => $ENV{DEBUG};

sub do_log {
  *STDERR->print("@_\n") if DEBUG;
}

sub simplify {
  my ($node) = @_;
  return $node->[0] if $node->[0] eq 'REMOVE';
  return sprintf '%s: %3$s',         @{$node} if $node->[0] eq 'ADD';
  return sprintf '%s: %2$s => %3$s', @{$node} if $node->[0] eq 'UPGRADE';
  return sprintf '%s: <%3$s>',       @{$node} if $node->[0] eq 'NOCHANGE';
  die "What is $node?";
}
