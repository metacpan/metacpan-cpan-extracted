use 5.006;
use strict;
use warnings;

package Dist::Zilla::Role::BundleDeps;

our $VERSION = '0.002005';

# ABSTRACT: Automatically add all plugins in a bundle as dependencies

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY












use Moose::Role qw( around );























sub bundledeps_defaults {
  return {
    -phase        => 'develop',
    -relationship => 'requires',
  };
}

around bundle_config => sub {
  my ( $orig, $self, $section, ) = @_;
  my $myconf = $self->bundledeps_defaults;
  for my $param (qw( phase relationship )) {
    my $field = 'bundledeps_' . $param;
    next unless exists $section->{payload}->{$field};
    $myconf->{ q[-] . $param } = delete $section->{payload}->{$field};
  }
  my (@config) = $self->$orig($section);
  my $reqs = $self->_extract_plugin_prereqs(@config);
  return ( @config, $self->_create_prereq_plugin( $reqs => $myconf ) );
};

no Moose::Role;

sub _bundle_alias {
  my ($self) = @_;
  my $ns = $self->meta->name;
  if ( $ns =~ /\ADist::Zilla::PluginBundle::(.*\z)/msx ) {
    return q[@] . $1;
  }
  return $ns;
}

sub _extract_plugin_prereqs {
  my ( undef, @config ) = @_;
  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new();
  for my $item (@config) {
    my ( undef, $module, $conf ) = @{$item};
    my $version = 0;
    $version = $conf->{':version'} if exists $conf->{':version'};
    $reqs->add_string_requirement( $module, $version );
  }
  return $reqs;
}

sub _create_prereq_plugin {
  my ( $self, $reqs, $config ) = @_;
  my $plugin_conf = { %{$config}, %{ $reqs->as_string_hash } };
  my $prereq = [];
  push @{$prereq}, $self->_bundle_alias . '/::Role::BundleDeps';
  push @{$prereq}, 'Dist::Zilla::Plugin::Prereqs';
  push @{$prereq}, $plugin_conf;
  return $prereq;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::BundleDeps - Automatically add all plugins in a bundle as dependencies

=head1 VERSION

version 0.002005

=head1 SYNOPSIS

    package blahblahblah;
    use Moose;
    ...
    with 'Dist::Zilla::Role::PluginBundle';
    with 'Dist::Zilla::Role::BundleDeps';

Dependencies appear now for all plugins returned.

=head1 DESCRIPTION

This role attempts to solve the problem of communicating dependencies to META.* from bundles
in a different way.

My first attempt was L<< C<[Prereqs::Plugins]>|Dist::Zilla::Plugins::Prereqs::Plugins >>, which added
all values that are seen in the C<dist.ini> to dependencies.

However, that was inherently limited, as the C<:version> specifier
is lost before the plugins appear on C<< $zilla->plugins >>

This Role however, can see any declarations of C<:version> your bundle advertises,
by standing between your C<bundle_config> method and C<Dist::Zilla>

=head1 METHODS

=head2 C<bundledeps_defaults>

This method provides the C<HashRef> of defaults to use for the generated C<Prereqs> section.

Because this role is intended to advertise Plugin Bundle dependencies, and because those
dependencies will be "develop" dependencies everywhere other than the bundle itself,
our defaults are:

    {
        -phase        => develop,
        -relationship => requires,
    }

These can be overridden when consuming a bundle in C<dist.ini>

    [@Author::MyBundle]
    ; authordep Dist::Zilla::Role::BundleDeps
    bundledeps_phase = runtime
    bundledeps_relationship = requires

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Role::BundleDeps",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 LIMITATIONS

=head2 Self References in develop_requires

If you bundle plugins with your bundle, and use those plugins in the bundle,
you'll risk a self-reference problem, which may be solved in a future release of Dist::Zilla.

Until then, you'll need to possibly use L<< C<[RemovePrereqs]>|Dist::Zilla::Plugin::RemovePrereqs >>
to trim self-references.

=head2 Bootstrap problems on Bundles

When using your bundle to ship itself, the use of this role can imply some confusion if the role is not installed,
as C<dzil listdeps> will require this role present to work.

It is subsequently recommended to state an explicit C<AuthorDep> in C<dist.ini> to avoid this.

  [Bootstrap::lib]

  [@Author::MyBundle]
  ; authordep Dist::Zilla::Role::BundleDeps
  bundledeps_phase          = runtime
  bundledeps_relationship   = requires

=head1 SEE ALSO

L<< C<[BundleInspector]>|Dist::Zilla::Plugin::BundleInspector >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
