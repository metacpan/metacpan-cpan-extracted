package FFI::Platypus::TypeParser;

use strict;
use warnings;
use List::Util 1.45 qw( uniqstr );
use Carp qw( croak );

# ABSTRACT: FFI Type Parser
our $VERSION = '1.10'; # VERSION


# The TypeParser and Type classes are used internally ONLY and
# are not to be exposed to the user.  External users should
# not under any circumstances rely on the implementation of
# these classes.

sub new
{
  my($class) = @_;
  my $self = bless { types => {}, type_map => {} }, $class;
  $self->build;
  $self;
}

sub build {}

our %basic_type;

# this just checks if the underlying libffi/platypus implementation
# has the basic type.  It is used mainly to verify that exotic types
# like longdouble and complex_float are available before the test
# suite tries to use them.
sub have_type
{
  my(undef, $name) = @_;
  !!$basic_type{$name};
}

sub create_type_custom
{
  my($self, $basic_type_name, @rest) = @_;

  my $tm = $self->type_map->{$basic_type_name||'opaque'};

  croak "$basic_type_name is not a legal native type for a custom type"
    unless $tm;

  my $basic = $self->global_types->{basic}->{$tm}
  || croak "$basic_type_name is not a legal native type for a custom type";

  $self->_create_type_custom($basic->type_code, @rest);
}

# this is the type map provided by the language plugin, if any
# in addition to the basic types (which map to themselves).
sub type_map
{
  my($self, $new) = @_;

  if(defined $new)
  {
    $self->{type_map} = $new;
  }

  $self->{type_map};
}

# this stores the types that have been mentioned so far.  It also
# usually includes aliases.
sub types
{
  shift->{types};
}

{
  my %store;

  foreach my $name (keys %basic_type)
  {
    my $type_code = $basic_type{$name};
    $store{basic}->{$name} = __PACKAGE__->create_type_basic($type_code);
    $store{ptr}->{$name}   = __PACKAGE__->create_type_pointer($type_code);
    $store{rev}->{$type_code} = $name;
  }

  sub global_types
  {
    \%store;
  }
}

# list all the types that this type parser knows about, including
# those provided by the language plugin (if any), those defined
# by the user, and the basic types that everyone gets.
sub list_types
{
  my($self) = @_;
  uniqstr( ( keys %{ $self->type_map } ), ( keys %{ $self->types } ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::TypeParser - FFI Type Parser

=head1 VERSION

version 1.10

=head1 DESCRIPTION

This class is private to FFI::Platypus.  See L<FFI::Platypus> for
the public interface to Platypus types.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Pisar (ppisar)

Mohammad S Anwar (MANWAR)

Håkon Hægland (hakonhagland, HAKONH)

Meredith (merrilymeredith, MHOWARD)

Diab Jerius (DJERIUS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015,2016,2017,2018,2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
