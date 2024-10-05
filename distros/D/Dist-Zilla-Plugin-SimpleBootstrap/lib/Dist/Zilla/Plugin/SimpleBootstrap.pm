use v5.20;
package Dist::Zilla::Plugin::SimpleBootstrap;
use Moose;
use experimental qw(signatures postderef);

our $VERSION = 'v0.1.0';

use File::ShareDir ();

{
  use MooseX::Types -declare => [qw(
    INIOptions
  )];
  use MooseX::Types::Moose qw( HashRef ArrayRef Str );

  use Moose::Util::TypeConstraints qw(
    subtype
    coerce
  );
}

use namespace::autoclean;

with qw(
  Dist::Zilla::Role::Plugin
);

sub mvp_multivalue_args { qw(module_shares) };
sub mvp_aliases         { +{
  module_share => 'module_shares',
} };

has lib => (
  is => 'ro',
  default => 'lib',
);

has share => (
  is => 'ro',
);

subtype INIOptions, as HashRef[Str];
coerce INIOptions,
  from ArrayRef[Str],
  via {
    +{
      map s/\A\s+//r,
      map s/\s+\z//r,
      map split(/=>?/, $_, 2),
      @$_
    };
  },
;

has module_shares => (
  is => 'ro',
  isa => INIOptions,
  coerce => 1,
);

around BUILDARGS => sub ($orig, $class, @args) {
  my $args = $class->$orig(@args);
  if (!exists $args->{module_shares} && !exists $args->{share}) {
    my $root = $args->{zilla}->root->absolute;
    if (-d $root->child('share')) {
      $args->{share} = 'share';
    }
  }
  return $args;
};

# called when reading dist.ini. @INC is localized while reading dist.ini, so
# this won't last after reading.
around plugin_from_config => sub ($orig, @args) {
  my $self = $orig->(@args);
  my $zilla = $self->zilla;

  # we can't use ensure_all_roles because it can modify attributes
  if (!$zilla->does('Dist::Zilla::Role::_SimpleBootstrap')) {
    my $class = Moose::Util::with_traits(ref $zilla, 'Dist::Zilla::Role::_SimpleBootstrap');
    bless $zilla, $class;
  }

  $self->install_share;
  $self->install_lib;
  return $self;
};

sub install_lib ($self) {
  my $zilla = $self->zilla;
  my $root = $zilla->root->absolute;

  my $lib = $root->child($self->lib)->stringify;

  unshift @INC, $lib
    unless grep $_ eq $lib, @INC;
}

sub install_share ($self) {
  my $zilla = $self->zilla;
  my $root = $zilla->root->absolute;

  if (my $dist_share = $self->share) {
    $File::ShareDir::DIST_SHARE{$zilla->name} //=
      $root->child($dist_share)->stringify;
  }

  if (my $module_shares = $self->module_shares) {
    for my $module (keys %$module_shares) {
      $File::ShareDir::MODULE_SHARE{$module} //=
        $root->child($module_shares->{$module})->stringify
    }
  }
}

{
  package # hide
    Dist::Zilla::Role::_SimpleBootstrap;
  { use Moose::Role; }
  before _setup_default_plugins => sub ($self, @) {
    for my $plugin ($self->plugins->@*) {
      next
        unless $plugin->isa('Dist::Zilla::Plugin::SimpleBootstrap');
      $plugin->install_lib;
    }
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Graham Knop

=head1 NAME

Dist::Zilla::Plugin::SimpleBootstrap - Bootstrap a Dist::Zilla library

=head1 SYNOPSIS

  # in dist.ini
  [SimpleBootstrap]

  # use a plugin under lib/
  [Plugin::Under::Development]

=head1 DESCRIPTION

Allow using a plugin being developed in its own C<dist.ini>. Unlike
L<[Bootstrap::lib]|Dist::Zilla::Plugin::Bootstrap::lib>, it doesn't try to use
a version of the module that has been built by L<Dist::Zilla>, instead always
using modules directly from F<lib/>.

Additionally, it ensures that the modules are available during the build phase.
L<Dist::Zilla> localizes L<< C<@INC>|perlvar/@INC >> during the initial loading
of modules, so modifications made at that time wouldn't normally persist. This
allows things like L<Pod::Weaver> plugins to be used from the F<lib/> directory.

If a F<share/> directory exists, it will be set as the
L<share directory|File::ShareDir/dist_dir> for the distribution.

=head1 OPTIONS

=over 4

=item lib

Can be used to specify an alternate directory to bootstrap, rather than F<lib>.

=item share

Specifies the dist share directory for the distribution.

If F<module_share> is not specified, this defaults to F<share>.

Defaults to F<share>.

=item module_share

Specifies L<module share directories|File::ShareDir/module_dir>. Should be formatted as:

  module_share = My::Module = share

=back

=head1 KNOWN ISSUES

=over 4

=item *

This module will not work well when used with L<Test::DZil>.

=back

=head1 SEE ALSO

=over 4

=item * L<[Bootstrap::lib]|Dist::Zilla::Plugin::Bootstrap::lib>, a significantly
more complex plugin, which doesn't solve the problem of C<@INC> being localized.
Also does not include handling for share directories.

=item * L<[lib]|Dist::Zilla::Plugin::lib>, a simple plugin, but which doesn't
solve the problem of C<@INC> being localized. Also does not include handling for
share directories.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Dist-Zilla-Plugin-SimpleBootstrap/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
