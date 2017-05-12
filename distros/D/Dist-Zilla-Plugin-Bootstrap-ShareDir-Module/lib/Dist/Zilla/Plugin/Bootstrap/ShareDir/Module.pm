use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Bootstrap::ShareDir::Module;

our $VERSION = '1.001002';

# ABSTRACT: Use a share directory on your dist for a module during bootstrap

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
with 'Dist::Zilla::Role::Bootstrap';














has module_map => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

sub _build_module_map { return {} }

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  if ( $self->meta->find_attribute_by_name('module_map')->has_value($self) ) {
    $localconf->{module_map} = $self->module_map;
  }
  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

around 'plugin_from_config' => sub {
  my ( $orig, $self, $name, $payload, $section ) = @_;

  my $special_fields = [qw( try_built fallback )];
  my $module_map     = { %{$payload} };
  my $new            = {};

  for my $field ( @{$special_fields} ) {
    $new->{$field} = delete $module_map->{$field} if exists $module_map->{$field};
  }
  $new->{module_map} = $module_map;

  return $self->$orig( $name, $new, $section );
};

sub bootstrap {
  my $self = shift;
  my $root = $self->_bootstrap_root;

  if ( not defined $root ) {
    $self->log( ['Not bootstrapping'] );
    return;
  }
  my $resolved_map = {};

  for my $key ( keys %{ $self->module_map } ) {
    require Path::Tiny;
    $resolved_map->{$key} = Path::Tiny::path( $self->module_map->{$key} )->absolute($root);
  }
  require Test::File::ShareDir::Object::Module;
  my $share_object = Test::File::ShareDir::Object::Module->new( modules => $resolved_map );
  for my $module ( $share_object->module_names ) {
    $self->log( [ 'Bootstrapped sharedir for %s -> %s', $module, $resolved_map->{$module}->relative(q[.])->stringify ] );
    $self->log_debug(
      [
        'Installing module %s sharedir ( %s => %s )',
        "$module",
        $share_object->module_share_source_dir($module) . q{},
        $share_object->module_share_target_dir($module) . q{},
      ],
    );
    $share_object->install_module($module);
  }
  $self->_add_inc( $share_object->inc->tempdir . q{} );
  $self->log_debug( [ 'Sharedir for %s installed to %s', $self->distname, $share_object->inc->module_tempdir . q{} ] );
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Bootstrap::ShareDir::Module - Use a share directory on your dist for a module during bootstrap

=head1 VERSION

version 1.001002

=head1 DESCRIPTION

This module allows one to load a C<Module> styled C<ShareDir> using a C<Bootstrap>
mechanism so a distribution can use files in its own source tree when building with itself.

This is very much like the C<Bootstrap::lib> plugin in that it injects libraries into
C<@INC> based on your existing source tree, or a previous build you ran.

And it is syntactically like the C<ModuleShareDirs> plugin.

B<Note> that this is really only useful for self consuming I<plugins> and will have no effect
on the C<test> or C<run> phases of your dist. ( For that, you'll need C<Test::File::ShareDir> ).

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Bootstrap::ShareDir::Module",
    "interface":"class",
    "does":"Dist::Zilla::Role::Bootstrap",
    "inherits":"Moose::Object"
}


=end MetaPOD::JSON

=head1 USAGE

    [Bootstrap::lib]

    [Bootstrap::ShareDir::Module]
    Foo::Bar = shares/foo_bar
    Foo::Baz = shares/foo_baz

    [ModuleShareDirs]
    Foo::Bar = shares/foo_bar
    Foo::Baz = shares/foo_baz

The only significant difference between this module and C<ModuleShareDirs> is this module exists to
make a C<share> visible to plugins for the distribution being built, while C<ModuleShareDirs> exists
to export a C<share> directory visible after install time.

Additionally, there are two primary attributes that are provided by
L<< C<Dist::Zilla::Role::Bootstrap>|Dist::Zilla::Role::Bootstrap >>, See
L<< Dist::Zilla::Role::Bootstrap/ATTRIBUTES >>

For instance, this bootstraps C<ROOT/Your-Dist-Name-$VERSION/shares/foo_bar> if it exists and
there's only one C<$VERSION>, otherwise it falls back to simply bootstrapping C<ROOT/shares/foo_bar>

    [Bootstrap::ShareDir::Module]
    Foo::Bar = shares/foo_bar
    Foo::Baz = shares/foo_baz
    ; These are special cased
    dir = share
    try_built = 1

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
