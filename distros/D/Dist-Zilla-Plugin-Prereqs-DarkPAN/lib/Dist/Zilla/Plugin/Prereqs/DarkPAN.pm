use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::DarkPAN;

our $VERSION = 'v0.3.0';

# ABSTRACT: Depend on things from arbitrary places-not-CPAN

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
with 'Dist::Zilla::Role::PrereqSource::External';

use namespace::autoclean;














has prereq_phase => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  init_arg => undef,
  default  => 'runtime',
);

has prereq_type => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  init_arg => undef,
  default  => 'requires',
);

# For full phase control, use above commented code.

has _deps     => ( is => 'ro', isa => 'HashRef', default => sub { {} }, );
has _raw_deps => ( is => 'ro', isa => 'HashRef', default => sub { {} }, );

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{prereq_phase} = $self->prereq_phase;
  $localconf->{prereq_type}  = $self->prereq_type;
  $localconf->{_raw_deps}    = $self->_raw_deps;

  $localconf->{ q[$] . __PACKAGE__ . q[::VERSION] } = $VERSION
    unless __PACKAGE__ eq ref $self;
  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _add_dep {
  my ( undef, $stash, $args ) = @_;
  $stash->{deps} = {} unless exists $stash->{deps};
  my $ds     = $stash->{deps};
  my $logger = $stash->{logger};

  my $key   = $args->{key};
  my $value = $args->{value};

  # TODO perhaps have support for multiple URLs with either some
  # fallback strategy or round-robbin or random-source support.
  # Not a priority atm.
  return $logger->log_fatal( [ 'tried to define base uri for \'%s\' more than once.', $key ] )
    if exists $ds->{$key};

  return ( $ds->{$key} = $value );

}

sub _add_attribute {
  my ( undef, $stash, $args ) = @_;

  $stash->{attributes} = {} unless exists $stash->{attributes};

  my $attributes = $stash->{attributes};
  my $logger     = $stash->{logger};

  my $key       = $args->{key};
  my $attribute = $args->{attribute};
  my $value     = $args->{value};

  my $supported_attrs = { map { $_ => 1 } qw( minversion uri ) };

  return $logger->log_fatal( [ 'Attribute \'%s\' for key \'%s\' not supported.', $attribute, $key, ], )
    if not exists $supported_attrs->{$attribute};

  $attributes->{$key} = {} unless exists $attributes->{$key};

  return $logger->log_fatal( [ 'tried to set attribute \'%s\' for %s more than once.', $attribute, $key, ] )
    if exists $attributes->{$key}->{$attribute};

  return ( $attributes->{$key}->{$attribute} = $value );

}

sub _collect_data {
  my ( $class, $stash, $key, $value ) = @_;

  my $logger = $stash->{logger};

  # Parameters
  # -phase
  # -type
  # as supported by Prereqs are not supported here ( at least, not yet )
  return $logger->log_fatal('dash ( - ) prefixed parameters are presently not supported.')
    if $key =~ /\A-/msx;

  if ( $key =~ /\A([^.]+)[.](.*\z)/msx ) {

    # Foo::Bar.minversion
    my $key_name      = "$1";
    my $key_attribute = "$2";
    return $class->_add_attribute(
      $stash,
      {
        key       => $key_name,
        attribute => $key_attribute,
        value     => $value,
      },
    );
  }

  return $class->_add_dep( $stash, { key => $key, value => $value } );
}

sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %config;
  if ( ref $args[0] ) {
    %config = %{ $args[0] };
    shift @args;
  }
  else {
    %config = @args;
  }

  my $zilla = delete $config{zilla};
  my $name  = delete $config{plugin_name};
  my $_deps = {};

  my $zilla_logger = $zilla->chrome->logger;
  my $logger = $zilla_logger->proxy( { proxy_prefix => '[' . $name . ']', } );

  my $deps       = {};
  my $attributes = {};

  for my $key ( keys %config ) {
    $class->_collect_data( { logger => $logger, deps => $deps, attributes => $attributes, }, $key, $config{$key} );
  }
  for my $dep ( keys %{$attributes} ) {
    $logger->log_fatal( [ '[%s] Attributes specified for dependency \'%s\', which is not defined', $name, $dep ] )
      unless exists $deps->{$dep};
  }
  for my $dep ( keys %{$deps} ) {
    require Dist::Zilla::ExternalPrereq;
    my $edep = $attributes->{$dep};
    $edep = {} unless defined $edep;

    my $instance = Dist::Zilla::ExternalPrereq->new(
      name        => $dep,
      plugin_name => $name . '{ExternalPrereq: dep on=\'' . $dep . '\'}',
      zilla       => $zilla,
      baseurl     => $deps->{$dep},

      %{$edep},
    );
    $_deps->{$dep} = $instance;
  }
  return {
    zilla       => $zilla,
    plugin_name => $name,
    _deps       => $_deps,
    _raw_deps   => $deps,
    logger      => $logger,
  };

}





sub register_external_prereqs {
  my ( $self, $registersub ) = @_;

  for my $dep ( keys %{ $self->_deps } ) {
    $registersub->(
      {
        type  => $self->prereq_type,
        phase => $self->prereq_phase,
      },
      $self->_deps->{$dep},
    );
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::DarkPAN - Depend on things from arbitrary places-not-CPAN

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

From time to time, people find themselves in want to depending on something that
isn't from CPAN, but their team/in-house crew want a painless way to depend on
it anyway.

  [Prereqs::DarkPAN]
  DDG = http://adarkpan.example.org/  ; DarkPAN Base URI
  ; optional
  DDG.minversion = 0.4.0
  ; optional
  ; But likely to be substantially faster.
  DDG.uri = /path/to/foo/bar.tar.gz

This would provide to various user commands the knowledge that C<DDG.tar.gz> was
wanted to provide the package C<DDG>.

Our hope is one day you can just do

  # Doesn't work yet :(
  $ cpanm $( dzil listdeps )

  or
  # Doesn't work yet :(
  $ cpanm $( dzil listdeps --missing )

and have it do the right things.

In the interim, you can do

    $ cpanm $( dzil listdeps )  \
      && cpanm $( dzil listdeps_darkpan )

or

    $ cpanm $( dzil listdeps --missing ) \
      && cpanm $( dzil listdeps_darkpan --missing )

and have it work.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Prereqs::DarkPAN",
    "interface":"class",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::PrereqSource::External"
}


=end MetaPOD::JSON

=for Pod::Coverage register_external_prereqs

=head1 DarkPAN Configurations.

=head2 A Simple HTTP Server

The easiest DarkPAN-ish thing that this module supports is naïve HTTP Servers,
by simply setting the server and path to the resource.

  [Prereqs::DarkPAN]
  Foo = http://my.server/
  Foo.uri =  files/foo.tar.gz

You can specify an optional minimum version parameter C<minversion> as a client-side check to
make sure they haven't installed an older version of Foo.

This C<uri> will be reported to listdeps_darkpan with minimal modification, only
expanding relative paths to absolute ones so tools like C<cpanm> can use them.

=head2 A C<MicroCPAN> Configuration

There is a newly formed system for creating "proper" CPANs which only contain a
handful of modules. For these services you can simply do

  [Prereqs::DarkPAN]
  Foo = http://my.server/

And we'll fire up all sorts of magic to get the C<02packages.details.tar.gz>
file, shred it, and try installing 'Foo' from there.

=head2 Heavier CPAN configurations

The 3rd use case is when you have somewhat heavy-weight private CPANs where you
don't want to be encumbered by the weight of downloading and parsing
C<02packages.details.tar.gz>. If you have a full CPAN clone with a few modules
stuffed into it, and you only want those stuffed modules while using normal CPAN
( because the cloned versions from CPAN are now old ), its possibly better to
use the original notation

  [Prereqs::DarkPAN]
  Foo = http://my.server/
  Foo.uri = path/too/foo.tar.gz

As it will only fetch the file specified instead of relying on
C<02packages.details.tar.gz>

Granted, this latter approach will bind again to downloading a specific version
of the prerequisite, but this is still here for you if you need it.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
