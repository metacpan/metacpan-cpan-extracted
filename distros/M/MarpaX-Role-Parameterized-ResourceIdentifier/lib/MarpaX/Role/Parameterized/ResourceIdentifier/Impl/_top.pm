use strict;
use warnings FATAL => 'all';

package MarpaX::Role::Parameterized::ResourceIdentifier::Impl::_top;

# ABSTRACT: Resource Identifier: top level implementation

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Carp qw/croak/;
use MarpaX::Role::Parameterized::ResourceIdentifier::Setup;
use Module::Find qw/findsubmod/;
use Module::Runtime qw/use_module is_module_name/;
use Scalar::Util qw/blessed/;
use Try::Tiny;

our $scheme_re = qr/^[A-Za-z][A-Za-z0-9.+-]*(?=:)/;
our $setup  = MarpaX::Role::Parameterized::ResourceIdentifier::Setup->new;

sub _new_from_specific {
  my ($class, $args, $scheme) = @_;

  my $impl_dirname          = $setup->impl_dirname;
  my $plugins_dirname       = $setup->plugins_dirname;
  my $can_scheme_methodname = $setup->can_scheme_methodname;

  my $plugins_namespace     = sprintf('%s::%s::%s', $class, $impl_dirname, $plugins_dirname);

  my $self;

  foreach (findsubmod($plugins_namespace)) {
    #
    # Look if there is a class saying it is dealing with this scheme.
    # We require there is a class method able to answer to this
    # question: $can_scheme_methodname()
    #
    my $subclass = $_;
    try {
      use_module($subclass);
      #
      # This will natively croak if the subclass does not provide
      # this as a class method
      #
      if ($subclass->$can_scheme_methodname($scheme)) {
        $self = $subclass->new($args);
        $self->has_recognized_scheme(!!1);
      }
    } catch {
        # print STDERR $_;
        return
    };
    last if blessed($self);
  }
  $self
}

sub _new_from_generic {
  my ($class, $args) = @_;

  my $impl_dirname = $setup->impl_dirname;

  my $subclass = sprintf('%s::%s::%s', $class, $impl_dirname, '_generic');

  my $self;
  try {
    use_module($subclass);
    $self = $subclass->new($args);
  };

  $self
}

sub _new_from_common {
  my ($class, $args) = @_;

  my $impl_dirname = $setup->impl_dirname;

  my $subclass = sprintf('%s::%s::%s', $class, $impl_dirname, '_common');

  use_module($subclass);
  $subclass->new($args)
}

sub _arg2scheme {
  my $arg = shift;
  return if (! defined $arg);
  my $rc;
  if ($arg =~ $scheme_re) {
    $rc = substr($arg, $-[0], $+[0] - $-[0])
  }
  $rc
}

sub new {
  my ($class, $args, $next) = @_;

  croak 'Missing argument' unless defined $args;
  #
  # scheme argument ? The original logic of URI is ok for me.
  #
  my $scheme;
  $scheme = _arg2scheme($args) if (! ref($args));
  $scheme = $next->scheme      if ((! defined($scheme)) && defined($next) && blessed($next) && $next->can('scheme'));
  $scheme = _arg2scheme($next) if ((! defined($scheme)) && defined($next) && ! ref($next));

  my $self;
  $self = $class->_new_from_specific($args, $scheme) if defined $scheme;
  $self = $class->_new_from_generic ($args)          unless blessed($self);
  $self = $class->_new_from_common  ($args)          unless blessed($self);

  $self
}

sub new_abs {
  my ($class, $args, $abs) = @_;

  $class->new($args)->abs($abs)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Role::Parameterized::ResourceIdentifier::Impl::_top - Resource Identifier: top level implementation

=head1 VERSION

version 0.003

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
