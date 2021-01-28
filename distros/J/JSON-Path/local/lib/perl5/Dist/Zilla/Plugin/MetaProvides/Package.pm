use 5.008;    # open scalar
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaProvides::Package;

our $VERSION = '2.004003';

# ABSTRACT: Extract namespaces/version from traditional packages for provides

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moose qw( with has around );
use MooseX::LazyRequire;
use MooseX::Types::Moose qw( HashRef Str );
use Dist::Zilla::MetaProvides::ProvideRecord 1.14000000;
use Data::Dump 1.16 ();
use Safe::Isa;


















use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';
with 'Dist::Zilla::Role::PPI';
with 'Dist::Zilla::Role::ModuleMetadata';

has '+meta_noindex' => ( default => sub { 1 } );











sub provides {
  my $self = shift;
  my (@records);
  for my $file ( @{ $self->_found_files() } ) {
    push @records, $self->_packages_for($file);
  }
  return $self->_apply_meta_noindex(@records);
}

has '_package_blacklist' => (
  isa => HashRef [Str],
  traits  => [ 'Hash', ],
  is      => 'rw',
  default => sub {
    return { map { $_ => 1 } qw( main DB ) };
  },
  handles => { _blacklist_contains => 'exists', },
);

# ->_packages_for( file ) => List[Dist::Zilla::MetaProvides::ProvideRecord]
sub _packages_for {
  my ( $self, $file ) = @_;

  if ( not $file->$_does('Dist::Zilla::Role::File') ) {
    $self->log_fatal('API Usage Invalid: _packages_for() takes only a file object');
    croak('packages_for() takes only a file object');
  }

  my $meta = $self->module_metadata_for_file($file);
  return unless $meta;

  $self->log_debug(
    'Version metadata from ' . $file->name . ' : ' . Data::Dump::dumpf(
      $meta,
      sub {
        if ( $_[1]->$_isa('version') ) {
          return { dump => $_[1]->stringify };
        }
        return { hide_keys => ['pod_headings'], };
      },
    ),
  );

  ## no critic (ProhibitArrayAssignARef)
  my @out;

  my $seen_blacklisted = {};
  my $seen             = {};

  for my $namespace ( $meta->packages_inside() ) {
    if ( $self->_blacklist_contains($namespace) ) {

      # note: these ones don't count as namespaces
      # at all for "did you forget a namespace" purposes
      $self->log_debug( "Skipping bad namespace: $namespace in " . $file->name );
      next;
    }

    if ( not $self->_can_index($namespace) ) {

      # These count for "You had a namespace but you hid it"
      $self->log_debug( "Skipping private(underscore) namespace: $namespace in " . $file->name );
      $seen_blacklisted->{$namespace} = 1;
      $seen->{$namespace}             = 1;
      next;
    }

    my $v = $meta->version($namespace);

    my (%struct) = (
      module => $namespace,
      file   => $file->name,
      ( ref $v ? ( version => $v->stringify ) : ( version => undef ) ),
      parent => $self,
    );

    $self->log_debug(
      'Version metadata for namespace ' . $namespace . ' in ' . $file->name . ' : ' . Data::Dump::dumpf(
        \%struct,
        sub {
          return { hide_keys => ['parent'] };
        },
      ),
    );
    $seen->{$namespace} = 1;
    push @out, Dist::Zilla::MetaProvides::ProvideRecord->new(%struct);
  }
  for my $namespace ( @{ $self->_all_packages_for($file) } ) {
    next if $seen->{$namespace};
    $self->log_debug("Found hidden namespace: $namespace");
    $seen_blacklisted->{$namespace} = 1;
  }

  if ( not @out ) {
    if ( not keys %{$seen_blacklisted} ) {
      $self->log( 'No namespaces detected in file ' . $file->name );
    }
    else {
      $self->log_debug( 'Only hidden namespaces detected in file ' . $file->name );
    }
    return ();
  }
  return @out;
}















has 'include_underscores' => ( is => 'ro', lazy => 1, default => sub { 0 } );

sub _can_index {
  my ( $self, $namespace ) = @_;
  return 1 if $self->include_underscores;
  ## no critic (RegularExpressions::RequireLineBoundaryMatching)
  return if $namespace =~ qr/\A_/sx;
  return if $namespace =~ qr/::_/sx;
  return 1;
}

sub _all_packages_for {
  my ( $self, $file ) = @_;
  require PPI::Document;
  my $document = $self->ppi_document_for_file($file);
  my $packages = $document->find('PPI::Statement::Package');
  return [] unless ref $packages;
  return [ map { $_->namespace } @{$packages} ];
}

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $orig->( $self, @args );
  my $payload = $config->{ +__PACKAGE__ } = {};

  $payload->{finder} = $self->finder if $self->has_finder;
  $payload->{include_underscores} = $self->include_underscores;

  for my $plugin ( @{ $self->_finder_objects } ) {
    my $object_config = {};
    $object_config->{class}   = $plugin->meta->name  if $plugin->can('meta') and $plugin->meta->can('name');
    $object_config->{name}    = $plugin->plugin_name if $plugin->can('plugin_name');
    $object_config->{version} = $plugin->VERSION     if $plugin->can('VERSION');
    if ( $plugin->can('dump_config') ) {
      my $finder_config = $plugin->dump_config;
      $object_config->{config} = $finder_config if keys %{$finder_config};
    }
    push @{ $payload->{finder_objects} }, $object_config;
  }

  # Inject only when inherited.
  $payload->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  return $config;
};

















has finder => (
  isa           => 'ArrayRef[Str]',
  is            => ro =>,
  lazy_required => 1,
  predicate     => has_finder =>,
);

has _finder_objects => (
  isa      => 'ArrayRef',
  is       => ro =>,
  lazy     => 1,
  init_arg => undef,
  builder  => _build_finder_objects =>,
);

sub _vivify_installmodules_pm_finder {
  my ($self) = @_;
  my $name = $self->plugin_name;
  $name .= '/AUTOVIV/:InstallModulesPM';
  if ( my $plugin = $self->zilla->plugin_named($name) ) {
    return $plugin;
  }
  require Dist::Zilla::Plugin::FinderCode;
  my $plugin = Dist::Zilla::Plugin::FinderCode->new(
    {
      plugin_name => $name,
      zilla       => $self->zilla,
      style       => 'grep',
      code        => sub {
        my ( $file, $self ) = @_;
        local $_ = $file->name;
        ## no critic (RegularExpressions)
        return 1 if m{\Alib/} and m{\.(pm)$};
        return 1 if $_ eq $self->zilla->main_module;
        return;
      },
    },
  );
  push @{ $self->zilla->plugins }, $plugin;
  return $plugin;
}

sub _build_finder_objects {
  my ($self) = @_;
  if ( $self->has_finder ) {
    my @out;
    for my $finder ( @{ $self->finder } ) {
      my $plugin = $self->zilla->plugin_named($finder);
      if ( not $plugin ) {
        $self->log_fatal("no plugin named $finder found");
        croak("no plugin named $finder found");
      }
      if ( not $plugin->does('Dist::Zilla::Role::FileFinder') ) {
        $self->log_fatal("plugin $finder is not a FileFinder");
        croak("plugin $finder is not a FileFinder");
      }
      push @out, $plugin;
    }
    return \@out;
  }
  return [ $self->_vivify_installmodules_pm_finder ];
}

sub _found_files {
  my ($self) = @_;
  my %by_name;
  for my $plugin ( @{ $self->_finder_objects } ) {
    for my $file ( @{ $plugin->find_files } ) {
      $by_name{ $file->name } = $file;
    }
  }
  return [ values %by_name ];
}

around mvp_multivalue_args => sub {
  my ( $orig, $self, @rest ) = @_;
  return ( 'finder', $self->$orig(@rest) );
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaProvides::Package - Extract namespaces/version from traditional packages for provides

=head1 VERSION

version 2.004003

=head1 SYNOPSIS

In your C<dist.ini>:

    [MetaProvides::Package]

    ; This is the (optional) default: This forces any package versions
    ; added in the "provides" metadata to use the 'version'
    ; specified by dzil.
    ;
    ; Set it to 0 to force packages own versions to be respected. ( You probably don't want this )
    inherit_version = 1

    ; This is also the (optional) default: This forces any package without
    ; a version declaration to use the 'version' specified by default.
    ;
    ; Set it to 0 to allow packages to have no versions
    inherit_missing = 1

    ; This is the (optional) default: This being true discovers any [MetaNoIndex]
    ; plugins to also further exclude packages from the provides map.
    ;
    ; Set it to 0 if for some weird reason you don't want this.
    meta_noindex    = 1

    ; This is the (optional) default: Packages named _Foo::Bar or Foo::_Bar are not indexed.
    ; Set this to 1 to enable indexing of similarly named packages.
    include_underscores = 0

=head1 DESCRIPTION

This is a L<< C<Dist::Zilla>|Dist::Zilla >> Plugin that populates the C<provides>
property of C<META.json> and C<META.yml> by absorbing it from your shipped modules,
in a manner similar to how C<PAUSE> itself does it.

This allows you to easily create an authoritative index of what module provides what
version in advance of C<PAUSE> indexing it, which C<PAUSE> in turn will take verbatim.

=head1 CONSUMED ROLES

=head2 L<Dist::Zilla::Role::MetaProvider::Provider>

=head1 ROLE SATISFYING METHODS

=head2 C<provides>

A conformant function to the L<Dist::Zilla::Role::MetaProvider::Provider> Role.

=head3 signature: $plugin->provides()

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=head1 ATTRIBUTES

=head2 C<include_underscores>

This attribute controls automatic skipping of packages.

By default, C<MetaProvides::Package> skips packages matching the following regular expression:

  qr/(\A|::)_/

Setting this attribute to a C<true> value will avoid skipping these packages.

This feature was added in C<2.004001-TRIAL>

=head2 C<finder>

This attribute, if specified will

=over 4

=item * Override the C<FileFinder> used to find files containing packages

=item * Inhibit autovivification of the C<.pm> file finder

=back

This parameter may be specified multiple times to aggregate a list of finders

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::MetaProvides::Package",
    "interface":"class",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::MetaProvider::Provider"
}


=end MetaPOD::JSON

=head1 OPTIONS INHERITED FROM L<Dist::Zilla::Role::MetaProvider::Provider>

=head2 L<< C<inherit_version>|Dist::Zilla::Role::MetaProvider::Provider/inherit_version >>

How do you want existing versions ( Versions hard-coded into files before running this plug-in )to be processed?

=over 4

=item * DEFAULT: inherit_version = 1

Ignore anything you find in a file, and just probe C<< DZIL->version() >> for a value. This is a sane default and most will want this.

=item * inherit_version = 0

Use this option if you actually want to use hard-coded values in your files and use the versions parsed out of them.

=back

=head2 L<< C<inherit_missing>|Dist::Zilla::Role::MetaProvider::Provider/inherit_missing >>

In the event you are using the aforementioned C<< L</inherit_version> = 0 >>, this determines how to behave when encountering a
module with no version defined.

=over 4

=item * DEFAULT: inherit_missing = 1

When a module has no version, probe C<< DZIL->version() >> for an answer. This is what you want if you want to have some
files with fixed versions, and others to just automatically be maintained by Dist::Zilla.

=item * inherit_missing = 0

When a module has no version, emit a versionless record in the final metadata.

=back

=head2 L<< C<meta_noindex>|Dist::Zilla::Role::MetaProvider::Provider/meta_noindex >>

This is a utility for people who are also using L<< C<MetaNoIndex>|Dist::Zilla::Plugin::MetaNoIndex >>,
so that its settings can be used to eliminate items from the 'provides' list.

=over 4

=item * meta_noindex = 0

With this set, any C<MetaNoIndex> plugins are ignored.

=item * DEFAULT: meta_noindex = 1

When a module meets the criteria provided to L<< C<MetaNoIndex>|Dist::Zilla::Plugin::MetaNoIndex >>,
eliminate it from the metadata shipped to L<Dist::Zilla>.

=back

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::MetaProvides>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
