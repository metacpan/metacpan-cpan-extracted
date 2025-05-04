use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Regenerate::AfterReleasers;

our $VERSION = '0.001003';

# ABSTRACT: Tickle plugins that do "AfterRelease" from regenerate

our $AUTHORITY = 'cpan:DBOOK'; # AUTHORITY

use Moose qw( with has around );
use Safe::Isa qw( $_does );
use namespace::clean -except => 'meta';

with qw/ Dist::Zilla::Role::Plugin Dist::Zilla::Role::Regenerator /;

has plugins => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};
  $payload->{plugins} = $self->plugins;

  ## no critic (RequireInterpolationOfMetachars)
  # Self report when inherited
  $payload->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  return $config;
};

no Moose;
__PACKAGE__->meta->make_immutable;





sub mvp_multivalue_args { qw( plugins ) }
sub mvp_aliases { +{ plugin => 'plugins' } }

sub regenerate {
  my ($self) = @_;
  my $zilla = $self->zilla;
  for my $plugin ( @{ $self->plugins } ) {
    my $ref = $zilla->plugin_named($plugin);
    $self->log_fatal("No such plugin $plugin") if not $ref;
    $self->log_fatal("$plugin does not do -AfterRelease") if not $ref->$_does('Dist::Zilla::Role::AfterRelease');
    $ref->after_release();
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Regenerate::AfterReleasers - Tickle plugins that do "AfterRelease" from regenerate

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

  ; Example AfterRelease module
  [CopyFilesFromRelease / MyName]

  ; Configured to trip CopyFilesFromRelease during regenerate
  [Regenerate::AfterReleasers]
  plugin = MyName

=head1 DESCRIPTION

This C<Dist::Zilla> C<Plugin> allows you to promote selected plugins to execution under C<dzil regenerate>

Simply specifying the list of C<Plugin B<NAMES>> you wish to invoke will have their respective C<after_release>
methods called in the stated order.

B<Note:> They are executed in C<STATED> order, B<NOT> the order in C<dist.ini>. This may be seen as a bug or a feature,
and may be subject to change if it turns out to be a bad idea.

=for Pod::Coverage mvp_multivalue_args mvp_aliases regenerate

=head1 ATTRIBUTES

=head2 plugins

An Array of Strings of C<PluginName>

  [Regenerate]
  plugin = pluginName
  plugin = pluginName

B<aliases:> C<plugin>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
