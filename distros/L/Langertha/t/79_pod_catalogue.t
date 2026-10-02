#!/usr/bin/env perl
# ABSTRACT: Guard the lib/Langertha.pm POD catalogues against engine/role drift

use strict;
use warnings;

use Test2::Bundle::More;
use Path::Tiny qw( path );

use Langertha ();

# lib/Langertha.pm carries two hand-maintained POD catalogues — "=head2 Engine
# Modules" and "=head2 Roles". They are the front door: a user runs
# `perldoc Langertha` to find out what ships. Hand-maintained lists rot, and
# this one did (karr #86 — XAI, Moonshot, Hetzner, VLLMHook, OpenAIResponses
# and nine roles including Role::AnthropicCompatible were never registered).
#
# This guard holds every lib/Langertha/{Engine,Role}/**/*.pm against the
# matching list, in both directions:
#
#   file on disk, not in the POD  -> undocumented ship (the #86 failure)
#   in the POD, no file on disk   -> the POD advertises something that is gone
#
# A module that deliberately stays out of a catalogue goes in the allowlist
# below, with the reason. That is the documented boundary, not a convenience.

# Abstract bases are deliberately absent from the user-facing engine
# catalogue: you subclass them, you never instantiate them. Note they are
# still named in the section's intro prose (and documented in their own POD),
# so extenders — including third-party LangerthaX::Engine::* engines — can
# find them; they are just not entries in the "pick a provider" list.
my %ENGINE_NOT_CATALOGUED = (
  'Langertha::Engine::Remote'         => 'abstract base for all remote engines',
  'Langertha::Engine::OpenAIBase'     => 'abstract base for OpenAI-compatible engines',
  'Langertha::Engine::AnthropicBase'  => 'abstract base for Anthropic-compatible engines',
);

# Every role is catalogued today, including the ones that are composed by the
# Raider/Raid layer rather than by an engine (Role::Runnable). The mechanism
# stays so a future deliberate omission has a home with its reason attached,
# rather than being dropped silently.
my %ROLE_NOT_CATALOGUED = ();

my $main_file = $INC{'Langertha.pm'} or die 'Langertha not in %INC';
my $pod       = path($main_file)->slurp_utf8;

# lib/Langertha.pm -> lib/Langertha/, which is where Engine/ and Role/ live.
my $lib_dir = path( $main_file =~ s/\.pm\z//r );
ok( $lib_dir->is_dir, 'located the lib/Langertha/ tree' )
  or BAIL_OUT("no directory at $lib_dir — the guard cannot see the modules");

# Pull out the =over ... =back body of one =head2 section. Only the list body
# is scanned, so the L<> links in a section's intro prose (which name the
# abstract bases on purpose) are not mistaken for catalogue entries.
sub catalogue_body {
  my ($heading) = @_;
  my ($body) = $pod =~ /^=head2 \s \Q$heading\E \s*$ (.*?) ^=back\b/msx;
  return $body;
}

# An entry is the module named at the START of an =item. Descriptions may link
# to other modules ("composed by L<Langertha::Role::Chat>") — those are prose,
# not catalogue entries, and must not count as coverage.
sub catalogue_entries {
  my ( $body, $namespace ) = @_;
  my @entries;
  push @entries, $1
    while $body =~ /^=item \s \* \s L<(\Q$namespace\E [\w:]+)>/gmsx;
  return @entries;
}

sub modules_on_disk {
  my ( $subdir, $namespace ) = @_;
  my $dir = $lib_dir->child($subdir);
  my @found;
  $dir->visit(
    sub {
      my ($path) = @_;
      return unless -f $path && $path->basename =~ /\.pm\z/;
      my $rel = $path->relative($dir)->stringify;
      $rel =~ s/\.pm\z//;
      push @found, $namespace . join '::', split m{/}, $rel;
    },
    { recurse => 1 },
  );
  return sort @found;
}

for my $lane (
  {
    heading   => 'Engine Modules',
    subdir    => 'Engine',
    namespace => 'Langertha::Engine::',
    allowlist => \%ENGINE_NOT_CATALOGUED,
    allowname => '%ENGINE_NOT_CATALOGUED',
    floor     => 30,
  },
  {
    heading   => 'Roles',
    subdir    => 'Role',
    namespace => 'Langertha::Role::',
    allowlist => \%ROLE_NOT_CATALOGUED,
    allowname => '%ROLE_NOT_CATALOGUED',
    floor     => 30,
  },
) {
  my $heading   = $lane->{heading};
  my $allowlist = $lane->{allowlist};

  my $body = catalogue_body($heading);
  ok( defined $body, "found the '=head2 $heading' catalogue in Langertha.pm" )
    or BAIL_OUT("cannot parse the '$heading' catalogue — the guard is blind");

  my @listed = catalogue_entries( $body, $lane->{namespace} );

  # Sanity floor: if the POD's list formatting ever changes shape, fail loudly
  # here instead of silently passing every module below.
  cmp_ok( scalar @listed, '>=', $lane->{floor},
    "parsed a plausible number of '$heading' entries" );

  my %listed = map { $_ => 1 } @listed;
  is( scalar keys %listed, scalar @listed,
    "no module is listed twice under '$heading'" );

  my @on_disk = modules_on_disk( $lane->{subdir}, $lane->{namespace} );

  # Direction 1: everything that ships is documented.
  for my $module (@on_disk) {
    my $is_listed    = $listed{$module};
    my $is_allowed   = exists $allowlist->{$module};

    ok( $is_listed || $is_allowed, "$module is in the '$heading' catalogue" )
      or diag(
          "$module ships but no '=head2 $heading' entry names it.\n"
        . "  documented surface -> add an '=item * L<$module> - ...' line\n"
        . "                        to lib/Langertha.pm\n"
        . "  deliberately out   -> add it to $lane->{allowname} in this test,\n"
        . "                        with the reason" );

    ok( !( $is_listed && $is_allowed ),
      "$module is not both catalogued and allowlisted as absent" );
  }

  # Direction 2: the catalogue does not advertise modules that are gone.
  my %on_disk = map { $_ => 1 } @on_disk;
  for my $module (@listed) {
    ok( $on_disk{$module},
      "catalogued $module exists as a file under lib/Langertha/$lane->{subdir}/" );
  }

  # The allowlist must not rot either.
  for my $module ( sort keys %{$allowlist} ) {
    ok( $on_disk{$module}, "allowlisted $module still exists" );
  }
}

# The headline count in "=head2 Key Features" is the first number a reader
# sees. It drifted to 24 while 35 engines shipped, so it is held to the
# catalogue rather than to someone's memory.
{
  my ($claimed) = $pod =~ /^=item \s \* \s B<(\d+) \s engines>/msx;
  ok( defined $claimed, 'found the engine count in Key Features' );

  my @listed = catalogue_entries(
    catalogue_body('Engine Modules') // '', 'Langertha::Engine::' );

  is( $claimed, scalar @listed,
    'the advertised engine count matches the Engine Modules catalogue' )
    or diag( "Key Features says $claimed engines, the catalogue lists "
      . scalar(@listed)
      . ".\nUpdate the B<N engines> line in lib/Langertha.pm." );
}

done_testing;
