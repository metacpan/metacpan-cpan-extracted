use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::ConfigDumper;

our $VERSION = '0.003009';

# ABSTRACT: A Dist::Zilla plugin configuration extraction utility

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Try::Tiny qw( try catch );
use Sub::Exporter::Progressive -setup => { exports => [qw( config_dumper dump_plugin )], };









































sub config_dumper {
  my ( $package, @methodnames ) = @_;
  if ( not defined $package or ref $package ) {
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    croak('config_dumper(__PACKAGE__, @recipie ): Arg 1 must not be ref or undef');
    ## use critic
  }

  my (@tests) = map { _mk_test( $package, $_ ) } @methodnames;
  my $CFG_PACKAGE = __PACKAGE__;
  return sub {
    my ( $orig, $self, @rest ) = @_;
    my $cnf     = $self->$orig(@rest);
    my $payload = {};
    my @fails;
    for my $test (@tests) {
      $test->( $self, $payload, \@fails );
    }
    if ( keys %{$payload} ) {
      $cnf->{$package} = $payload;
    }
    if (@fails) {
      $cnf->{$CFG_PACKAGE} = {} unless exists $cnf->{$CFG_PACKAGE};
      $cnf->{$CFG_PACKAGE}->{$package} = {} unless exists $cnf->{$CFG_PACKAGE};
      $cnf->{$CFG_PACKAGE}->{$package}->{failed} = \@fails;
    }
    return $cnf;
  };
}






































sub dump_plugin {
  my ($plugin) = @_;
  my $object_config = {};
  $object_config->{class}   = $plugin->meta->name  if $plugin->can('meta') and $plugin->meta->can('name');
  $object_config->{name}    = $plugin->plugin_name if $plugin->can('plugin_name');
  $object_config->{version} = $plugin->VERSION     if $plugin->can('VERSION');
  if ( $plugin->can('dump_config') ) {
    my $finder_config = $plugin->dump_config;
    $object_config->{config} = $finder_config if keys %{$finder_config};
  }
  return $object_config;
}

sub _mk_method_test {
  my ( undef, $methodname ) = @_;
  return sub {
    my ( $instance, $payload, $fails ) = @_;
    try {
      my $value = $instance->$methodname();
      $payload->{$methodname} = $value;
    }
    catch {
      push @{$fails}, $methodname;
    };
  };
}

sub _mk_attribute_test {
  my ( undef, $attrname ) = @_;
  return sub {
    my ( $instance, $payload, $fails ) = @_;
    try {
      my $metaclass           = $instance->meta;
      my $attribute_metaclass = $metaclass->find_attribute_by_name($attrname);
      if ( $attribute_metaclass->has_value($instance) ) {
        $payload->{$attrname} = $attribute_metaclass->get_value($instance);
      }
    }
    catch {
      push @{$fails}, $attrname;
    };
  };
}

sub _mk_hash_test {
  my ( $package, $hash ) = @_;
  my @out;
  if ( exists $hash->{attrs} and 'ARRAY' eq ref $hash->{attrs} ) {
    push @out, map { _mk_attribute_test( $package, $_ ) } @{ $hash->{attrs} };
  }
  return @out;
}

sub _mk_test {
  my ( $package, $methodname ) = @_;
  return _mk_method_test( $package, $methodname ) if not ref $methodname;
  return $methodname if 'CODE' eq ref $methodname;
  return _mk_hash_test( $package, $methodname ) if 'HASH' eq ref $methodname;
  croak "Don't know what to do with $methodname";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ConfigDumper - A Dist::Zilla plugin configuration extraction utility

=head1 VERSION

version 0.003009

=head1 SYNOPSIS

  ...

  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

  around dump_config => config_dumper( __PACKAGE__, qw( foo bar baz ) );

=head1 DESCRIPTION

This module contains a utility function for use within the C<Dist::Zilla>
plugin ecosystem, to simplify extraction of plugin settings for plugin
authors, in order for plugins like C<Dist::Zilla::Plugin::MetaConfig> to expose
those values to consumers.

Primarily, it specializes in:

=over 4

=item * Making propagating configuration from the plugins inheritance hierarchy
nearly foolproof.

=item * Providing simple interfaces to extract values of lists of named methods
or accessors

=item * Providing a way to intelligently and easily probe the value of lazy
attributes without triggering their vivification.

=back

=head1 FUNCTIONS

=head2 C<config_dumper>

  config_dumper( __PACKAGE__, qw( method list ) );

Returns a function suitable for use with C<around dump_config>.

  my $sub = config_dumper( __PACKAGE__, qw( method list ) );
  around dump_config => $sub;

Or

  around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    return config_dumper(__PACKAGE__, qw( method list ))->( $orig, $self, @args );
  };

Either way:

  my $function = config_dumper( $package_name_for_config, qw( methods to call on $self ));
  my $hash = $function->( $function_that_returns_a_hash, $instance_to_call_methods_on, @somethinggoeshere );

=~ All of this approximates:

  around dump_config => sub {
    my ( $orig , $self , @args ) = @_;
    my $conf = $self->$orig( @args );
    my $payload = {};

    for my $method ( @methods ) {
      try {
        $payload->{ $method } = $self->$method();
      };
    }
    $config->{+__PACKAGE__} = $payload;
  }

Except with some extra "things dun goofed" handling.

=head2 C<dump_plugin>

This function serves the other half of the equation, emulating C<dzil>'s own
internal behavior for extracting the C<plugin> configuration data.

  for my $plugin ( @{ $zilla->plugins } ) {
    pp( dump_plugin( $plugin )); # could prove useful somewhere.
  }

Its not usually something you need, but its useful in:

=over 4

=item * Tests

=item * Crazy Stuff like injecting plugins

=item * Crazy Stuff like having "Child" plugins

=back

This serves to be a little more complicated than merely calling C<< ->dump_config >>,
as the structure C<dzil> uses is:

  {
    class   => ...
    name    => ...
    version => ...
    config  => $dump_config_results_here
  }

And of course, there's a bunch of magic stuff with C<meta>, C<can> and C<if keys %$configresults>

All that insanity is wrapped in this simple interface.

=head1 ADVANCED USE

=head2 CALLBACKS

Internally

  config_dumper( $pkg, qw( method list ) );

Maps to a bunch of subs, so its more like:

  config_dumper( $pkg, sub {
    my ( $instance, $payload ) = @_;
    $payload->{'method'} = $instance->method;
  }, sub {
    $_[1]->{'list'} = $_[0]->list;
  });

So if you want to use that because its more convenient for some problem, be my guest.

  around dump_config => config_dumper( __PACKAGE__, sub {
    $_[1]->{'x'} = 'y'
  });

is much less ugly than

  around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    my $conf = $self->$orig(@args);
    $config->{+__PACKAGE__} = { # if you forget the +, things break
       'x' => 'y'
    };
    return $config;
  };

=head2 DETAILED CONFIGURATION

There's an additional feature for advanced people:

  config_dumper( $pkg, \%config );

=head3 C<attrs>

  config_dumper( $pkg, { attrs => [qw( foo bar baz )] });

This is for cases where you want to deal with C<Moose> attributes,
but want added safety of B<NOT> loading attributes that have no value yet.

For each item in C<attrs>, we'll call C<Moose> attribute internals to determine
if the attribute named has a value, and only then will we fetch it.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
