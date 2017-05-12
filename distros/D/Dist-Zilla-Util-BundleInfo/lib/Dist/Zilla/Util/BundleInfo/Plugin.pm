use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Util::BundleInfo::Plugin;

our $VERSION = '1.001005';

# ABSTRACT: Data about a single plugin instance in a bundle

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );








































has name => ( is => ro =>, required => 1, );
has module => (
  is       => ro =>,
  required => 1,
  isa      => sub {
    return if defined $_[0];
    require Carp;
    return Carp::croak('module must be a defined value');
  },
);
has payload => ( is => ro =>, required => 1, );

has _loaded_module => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Module::Runtime;
    Module::Runtime::require_module( $_[0]->module );
    return $_[0]->module;
  },
);

has _mvp_alias_rmap => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    return {} unless $self->_loaded_module->can('mvp_aliases');
    my $rmap = {};
    my $fmap = $self->_loaded_module->mvp_aliases;
    for my $key ( keys %{$fmap} ) {
      my $value = $fmap->{$key};
      $rmap->{$value} = [] if not exists $rmap->{$value};
      push @{ $rmap->{$value} }, $key;
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














sub inflate_bundle_entry {
  my ( $self, $entry ) = @_;
  my (%params);
  @params{qw( name module payload )} = @{$entry};
  for my $variable ( keys %params ) {
    next if defined $params{$variable};
    require Carp;
    Carp::carp("$variable was undefined");
  }
  return $self->new(%params);
}










sub to_bundle_entry {
  my ( $self, ) = @_;
  return [ $self->name, $self->module, $self->payload ];
}













sub short_module {
  my ($self) = @_;
  my $name = $self->module;
  if ( $name =~ /^Dist::Zilla::Plugin::(.*$)/xsm ) {
    return "$1";
  }
  return "=$name";
}

sub _dzil_ini_header {
  my ($self) = @_;
  return sprintf '[%s / %s]', $self->short_module, $self->name;
}

sub _dzil_config_line {
  my ( undef, $name, $value ) = @_;
  return sprintf '%s = %s', $name, $value;
}

sub _dzil_config_multiline {
  my ( $self, $key, @values ) = @_;
  if ( not $self->_property_is_mvp_multi($key) ) {
    require Carp;
    Carp::carp( "$key is not an MVP multi-value for " . $self->module );
  }
  my @out;
  for my $value (@values) {
    if ( not ref $value ) {
      push @out, $self->_dzil_config_line( $key, $value );
      next;
    }
    require Carp;
    Carp::croak('2 Dimensional arrays cannot be exported to distini format');
  }
  return @out;
}

sub _autoexpand_list {
  my ( $self, $key, $value ) = @_;
  if ( not ref $value ) {
    return ( $key, $value );
  }
  if ( not $self->_property_is_mvp_multi($key) ) {
    require Carp;
    Carp::carp( "$key is not an MVP multi-value for " . $self->module );
  }
  return map { ( $key, $_ ) } @{$value};
}
























sub payload_list {
  my ( $self, ) = @_;
  my $payload = $self->payload;
  my @out;
  for my $key ( sort keys %{$payload} ) {
    push @out, $self->_autoexpand_list( $key, $payload->{$key} );
  }
  return @out;
}








sub to_dist_ini {
  my ( $self, ) = @_;
  my @out;
  push @out, $self->_dzil_ini_header;

  my $payload = $self->payload;
  for my $key ( sort keys %{$payload} ) {
    my $value = $payload->{$key};
    if ( not ref $value ) {
      push @out, $self->_dzil_config_line( $key, $value );
      next;
    }
    if ( 'ARRAY' eq ref $value ) {
      if ( 0 == @{$value} ) {
        require Carp;
        Carp::carp( 'Can\'t create an INI entry for an empty array attribute ( with key: ' . $key . ' )' );
        next;
      }
      if ( 1 == @{$value} ) {
        push @out, $self->_dzil_config_line( $key, @{$value} );
        next;
      }
      push @out, $self->_dzil_config_multiline( $key, @{$value} );
      next;
    }
    require Carp;
    Carp::croak( 'Cannot format plugin payload of type ' . ref $value );
  }
  return join qq{\n}, @out, q[], q[];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::BundleInfo::Plugin - Data about a single plugin instance in a bundle

=head1 VERSION

version 1.001005

=head1 METHODS

=head2 C<inflate_bundle_entry>

Creates a C<<::BundleInfo::Plugin> node based on an array-line returned from
C<< yourbundle->bundle_config >>.

e.g:

  my $instance = ::Plugin->inflate_bundle_entry([
    '@ABUNDLE/My::Name::Here', 'Fully::Qualified::Module::Name', { %config }
  ]);

=head2 C<to_bundle_entry>

As with L<< C<inflate_bundle_entry>|/inflate_bundle_entry >>, except does the inverse operation,
turning an object into an array to pass to C<Dist::Zilla>

  my $line = $instance->to_bundle_entry;

=head2 C<short_module>

Returns the "short" form of the module name.

This is basically the inverse of Dist::Zillas plugin name expansion
routine

  Dist::Zilla::Plugin::Foo      -> Foo
  Non::Dist::Zilla::Plugin::Foo -> =Non::Dist::Zilla::Plugin::Foo

=head2 C<payload_list>

Returns the payload in "expanded" form.

Internally, payloads are stored as:

  {
    key_a => value_0,
    key_b => [ value_1, value_2, value_3 ],
  }

And this is optimal for coding.

This method returns them in an order more amenable for C<INI> injection.

  ( 'key_a', value_0,
    'key_b', value_1,
    'key_b', value_2,
    'key_b', value_3,
  )

=head2 C<to_dist_ini>

Returns a copy of this C<plugin> in a textual form suitable for injecting into
a C<dist.ini>

=head1 ATTRIBUTES

=head2 C<name>

The "name" property of the plugin.

e.g:

  [ Foo / Bar ]  ; My name is Bar

=head2 C<module>

The "module" property of the plugin.

e.g.:

  [ Foo / Bar ]  ; My module is Dist::Zilla::Plugin::Bar

=head2 C<payload>

The "payload" property of the plugin
that will be passed during C<register_compontent>

=begin MetaPOD::JSON v1.1.0

{
  "namespace":"Dist::Zilla::Util::BundleInfo::Plugin",
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
