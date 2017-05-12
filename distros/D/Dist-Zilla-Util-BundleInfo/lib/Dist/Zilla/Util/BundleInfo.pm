use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Util::BundleInfo;

our $VERSION = '1.001005';

# ABSTRACT: Load and interpret a bundle

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );

















sub _coerce_bundle_name {
  my ($name) = @_;
  require Dist::Zilla::Util;
  return Dist::Zilla::Util->expand_config_package_name($name);
}







sub _isa_bundle {
  my ($name) = @_;
  require Module::Runtime;
  Module::Runtime::require_module($name);
  if ( not $name->can('bundle_config') ) {
    require Carp;
    Carp::croak("$name is not a bundle, as it does not have a bundle_config method");
  }
}










has bundle_name => (
  is       => ro  =>,
  required => 1,
  coerce   => sub { _coerce_bundle_name( $_[0] ) },
  isa      => sub { _isa_bundle( $_[0] ) },
);











has bundle_dz_name => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return $_[0]->bundle_name;
  },
);

































has bundle_payload => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    [];
  },
);

has _loaded_module => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Module::Runtime;
    Module::Runtime::require_module( $_[0]->bundle_name );
    return $_[0]->bundle_name;
  },
);

has _mvp_alias_map => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    return {} unless $self->_loaded_module->can('mvp_aliases');
    return $self->_loaded_module->mvp_aliases;
  },
);
has _mvp_alias_rmap => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    my $rmap = {};
    for my $alias_from ( keys %{ $self->_mvp_alias_map } ) {
      my $alias_to = $self->_mvp_alias_map->{$alias_from};
      $rmap->{$alias_to} = [] if not exists $rmap->{$alias_to};
      push @{ $rmap->{$alias_to} }, $alias_from;
    }
    return $rmap;
  },
);

sub _mvp_alias_for {
  my ( $self, $alias ) = @_;
  return unless exists $self->_mvp_alias_rmap->{$alias};
  return @{ $self->_mvp_alias_rmap->{$alias} };
}
has _mvp_multivalue_args => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return {} unless $_[0]->_loaded_module->can('mvp_multivalue_args');
    my $map = {};
    for my $arg ( $_[0]->_loaded_module->mvp_multivalue_args ) {
      $map->{$arg} = 1;
      for my $alias ( $_[0]->_mvp_alias_for($arg) ) {
        $map->{$alias} = 1;
      }
    }
    return $map;
  },
);

no Moo;

sub _property_is_mvp_multi {
  my ( $self, $property ) = @_;
  return exists $self->_mvp_multivalue_args->{$property};
}

sub _array_to_hash {
  my ( $self, @orig_payload ) = @_;
  my $payload = {};
  my ( $key_i, $value_i ) = ( 0, 1 );
  while ( $value_i <= $#orig_payload ) {
    my ($inputkey) = $orig_payload[$key_i];
    my ($value)    = $orig_payload[$value_i];
    my ($key)      = $inputkey;
    if ( exists $self->_mvp_alias_map->{$inputkey} ) {
      $key = $self->_mvp_alias_map->{$inputkey};
    }
    if ( $self->_property_is_mvp_multi($key) ) {
      $payload->{$key} = [] if not exists $payload->{$key};
      push @{ $payload->{$key} }, $value;
      next;
    }
    if ( exists $payload->{$key} ) {
      require Carp;
      Carp::carp( "Multiple specification of non-multivalue key $key for bundle" . $self->bundle_name );
      if ( not ref $payload->{$key} ) {
        $payload->{$key} = [ $payload->{$key} ];
      }
      push @{ $payload->{$key} }, $value;
      next;
    }
    $payload->{$key} = $value;
  }
  continue {
    $key_i   += 2;
    $value_i += 2;
  }
  return $payload;
}








sub plugins {
  my ( $self, )      = @_;
  my $payload        = $self->bundle_payload;
  my $bundle         = $self->bundle_name;
  my $bundle_dz_name = $self->bundle_dz_name;
  require Dist::Zilla::Util::BundleInfo::Plugin;
  my @out;
  if ( 'ARRAY' eq ref $payload ) {
    $payload = $self->_array_to_hash( @{$payload} );
  }
  for my $plugin ( $bundle->bundle_config( { name => $bundle_dz_name, payload => $payload } ) ) {
    push @out, Dist::Zilla::Util::BundleInfo::Plugin->inflate_bundle_entry($plugin);
  }
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::BundleInfo - Load and interpret a bundle

=head1 VERSION

version 1.001005

=head1 SYNOPSIS

  use Dist::Zilla::Util::BundleInfo;

  # [@RJBS]
  # -myparam = foo
  # param = bar
  # param = quux
  #
  my $info = Dist::Zilla::Util::BundleInfo->new(
    bundle_name => '@RJBS',
    bundle_payload => [
      '-myparam' => 'foo',
      'param'    => 'bar',
      'param'    => 'quux'
    ]
  );
  for my $plugin ( $info->plugins ) {
    print $plugin->to_dist_ini; # emit each plugin in order in dist.ini format.
  }

=head1 METHODS

=head2 C<plugins>

Returns a list of L<< C<::BundleInfo::Plugin>|Dist::Zilla::Util::BundleInfo::Plugin >> instances
representing the configuration data for each section returned by the bundle.

=head1 ATTRIBUTES

=head2 C<bundle_name>

The name of the bundle to get info from

  ->new( bundle_name => '@RJBS' )
  ->new( bundle_name => 'Dist::Zilla::PluginBundle::RJBS' )

=head2 C<bundle_dz_name>

The name to pass to the bundle in the C<name> parameter.

This is synonymous to the value of C<Foo> in

  [@Bundle / Foo]

=head2 C<bundle_payload>

The parameter list to pass to the bundle.

This is synonymous with the properties passed in C<dist.ini>

  {
    foo => 'bar',
    quux => 'do',
    multivalue => [ 'a' , 'b', 'c' ]
  }

C<==>

  [
    'foo' => 'bar',
    'quux' => 'do',
    'multivalue' => 'a',
    'multivalue' => 'b',
    'multivalue' => 'c',
  ]

C<==>

  foo = bar
  quux = do
  multivalue = a
  multivalue = b
  multivalue = c

=head1 PRIVATE FUNCTIONS

=head2 C<_coerce_bundle_name>

  _coerce_bundle_name('@Foo') # Dist::Zilla::PluginBundle::Foo

=head2 C<_isa_bundle>

  _isa_bundle('Foo::Bar::Baz') # fatals if Foo::Bar::Baz can't do ->bundle_config

=begin MetaPOD::JSON v1.1.0

{
  "namespace":"Dist::Zilla::Util::BundleInfo",
  "interface":"class",
  "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
