use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::RemovePrereqs::Provided;

our $VERSION = '0.001001';

# ABSTRACT: Remove prerequisites that are already provided.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with around );
use Moose::Util::TypeConstraints qw( enum );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

my $sources = enum [qw( metaprovides )];

no Moose::Util::TypeConstraints;

with 'Dist::Zilla::Role::PrereqSource';

has provided_source => (
  isa     => $sources,
  is      => 'ro',
  default => sub { qw( metaprovides ) },
);

around dump_config => config_dumper( __PACKAGE__, { attrs => 'provided_source' } );

__PACKAGE__->meta->make_immutable;
no Moose;

sub _get_provides_metaprovides {
  my ( $self, ) = @_;
  my (@plugins) = @{ $self->zilla->plugins_with('-MetaProvider::Provider') || [] };
  if ( not @plugins ) {
    $self->log('No MetaProvides::Provider plugins found in dist to extract metaprovides from');
    return ();
  }
  my @provided = map { $_->provides } @plugins;
  if ( not @plugins ) {
    $self->log('No modules found while extracting provides from MetaProvider::Provider plugins');
    return ();
  }
  return map { $_->module } @provided;
}

my @phases = qw(configure build test runtime develop);
my @types  = qw(requires recommends suggests conflicts);





sub register_prereqs {
  my ($self)    = @_;
  my $prereqs   = $self->zilla->prereqs;
  my $method    = '_get_provides_' . $self->provided_source;
  my (@modules) = $self->$method;
  for my $phase (@phases) {
    for my $type (@types) {
      my $reqs = $prereqs->requirements_for( $phase, $type );
      for my $module (@modules) {
        $reqs->clear_requirement($module);
      }
    }
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RemovePrereqs::Provided - Remove prerequisites that are already provided.

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This module is a utility for people who are working with self-consuming code ( predominantly C<Dist::Zilla> distributions )
who wish to avoid self-dependencies in cases where some other prerequisite providing tool is over-zealous in determining
prerequisites.

This is an initial implementation that assumes you have L<< C<[MetaProvides]>|Dist::Zilla::Plugin::MetaProvides >> of some
description in place, and uses the data it provides to make sure the same modules don't exist as prerequisites.

=for Pod::Coverage register_prereqs

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
