use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective;

our $VERSION = '1.001001';

# ABSTRACT: [DEPRECATED] Selectively upgrade a few modules to depend on the version used.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );
use Module::Data;

with 'Dist::Zilla::Role::PrereqSource';

__PACKAGE__->meta->make_immutable;
no Moose;


























sub wanted_latest {
  return { map { $_ => 1 } qw(  Test::More Module::Build Dist::Zilla::PluginBundle::Author::KENTNL ) };
}









sub current_version_of {
  my ( undef, $package ) = @_;
  return Module::Data->new($package)->_version_emulate;
}






















sub for_each_dependency {
  my ( $self, $cpanmeta, $callback ) = @_;

  my $prereqs = $cpanmeta->{prereqs};
  for my $phase ( keys %{$prereqs} ) {
    my $phase_data = $prereqs->{$phase};
    for my $type ( keys %{$phase_data} ) {
      my $type_data = $phase_data->{$type};
      next unless $type_data->isa('CPAN::Meta::Requirements');
      my $requirements = $type_data->{requirements};
      for my $package ( keys %{$requirements} ) {

        $callback->(
          $self,
          {
            phase       => $phase,
            type        => $type,
            package     => $package,
            requirement => $requirements->{$package},
          },
        );
      }
    }
  }
  return $self;
}

# This needs to be 'our' to be localised.
# Otherwise, we can't shadow the value of $in_recursion
# using localisation, so we'd have to decrement $in_recursion at the
# end, manually.
#
## no critic (ProhibitPackageVars,ProhibitLocalVars)
our $in_recursion = 0;











sub register_prereqs {
  if ( defined $in_recursion and $in_recursion > 0 ) {
    return;
  }
  local $in_recursion = ( $in_recursion + 1 );

  my $self    = shift;
  my $prereqs = $self->zilla->prereqs;

  $self->for_each_dependency(
    $prereqs->cpan_meta_prereqs => sub {
      my ( undef, $args ) = @_;
      my $package = $args->{package};

      return unless exists $self->wanted_latest->{$package};

      $self->zilla->register_prereqs(
        { phase => $args->{phase}, type => $args->{type} },
        $package, $self->current_version_of($package),
      );
    },
  );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective - [DEPRECATED] Selectively upgrade a few modules to depend on the version used.

=head1 VERSION

version 1.001001

=head1 SYNOPSIS

	[Autoprereqs]

	[Author::KENTNL::Prereqs::Latest::Selective]

This will automatically upgrade the minimum required version to the currently running version, for a selective  list of packages,
wherever they appear in dependencies.

Currently, the list of packages that will be upgraded to the current version are as follows:

=over 4

=item * Test::More    - What I test all my packages with

=item * Module::Build - The Installer I use for everything

=item * Dist::Zilla::PluginBundle::Author::KENTNL - The configuration setup I use for everything.

=back

=head1 DESCRIPTION

This module is deprecated and no longer used by C<@Author::KENTNL>

Instead, he recommends you use L<< C<[Prereqs::MatchInstalled]>|Dist::Zilla::Plugin::Prereqs::MatchInstalled >>

=head1 METHODS

=head2 wanted_latest

	my $hash = $plugin->wanted_latest();

A C<Hash> of Modules I want to be "Latest I've released with"

	{
		'Test::More' => 1,
		'Module::Build' => 1,
		'Dist::Zilla::PluginBundle::Author::KENTNL' => 1,
	}

=head2 current_version_of

	my $v = $plugin->current_version_of('Foo');

Returns the currently installed version of a given thing.

=head2 for_each_dependency

	$plugin->for_each_dependency( $cpan_meta, sub {
		my ( $self, $info ) = @_;

		printf "%s => %s\n", $_ , $info->{$_} for qw( phase type package requirement )
	});

Utility for iterating all dependency specifications.

Each dependency spec is passed as a C<HashRef>

	{
		phase => 'configure',
		type  => 'requires',
		package => 'Module::Metadata',
		requirement => bless({}, 'CPAN::Meta::Requirements::_Range::_Range'); # or close.
	}

=head2 register_prereqs

This module executes during C<prereqs> generation.

As such, its advised to place it B<after> other things you want C<prereq>'s upgraded on.

( Presently, it won't matter if you place it before, because it does some magic with phase emulation, but that might be removed one day )

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective",
    "interface":"class",
    "inherits":["Moose::Object"],
    "does":["Dist::Zilla::Role::PrereqSource"]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
