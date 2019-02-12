
package Jojo::Base::Compat;

our $VERSION = '0.7.0';

use 5.018;
use strict;
use warnings;
use utf8;
use feature      ();
use experimental ();

BEGIN {
  require Mojo::Base;
  our @ISA = qw(Mojo::Base);
}

use Carp       ();
use Mojo::Util ();
#use Sub::Inject 0.2.0 ();
use Importer::Zim ();

use constant ROLES =>
  !!(eval { require Jojo::Role; Jojo::Role->VERSION('0.5.0'); 1 });

use constant SIGNATURES => ($] >= 5.020);

our %EXPORT_TAGS;
our %EXPORT_GEN;

sub import {
  my $class = shift;
  return unless my $flag = shift;
  my $caller = caller;

  # Base
  my $base;
  if ($flag eq '-base') { $base = $class }

  # Strict
  elsif ($flag eq '-strict') { }

  # Role
  elsif ($flag eq '-role') {
    Carp::croak 'Jojo::Role 0.5.0+ is required for roles' unless ROLES;
    Jojo::Role->make_role($caller);
  }

  # Module
  elsif (($base = $flag) && ($flag = '-base') && !$base->can('new')) {
    require(Mojo::Util::class_to_path($base));
  }

  # Jojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.18');
  experimental->import('lexical_subs');

  # Signatures (Perl 5.20+)
  if ((shift || '') eq '-signatures') {
    Carp::croak 'Subroutine signatures require Perl 5.20+' unless SIGNATURES;
    experimental->import('signatures');
  }

  # ISA
  if ($base) {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base;
  }

  my @exports = @{$EXPORT_TAGS{$flag} // []};
  if (@exports) {
    my %exports = $class->_generate_subs($caller, @exports);
    Importer::Zim::export_to($caller, %exports);
    #goto &Sub::Inject::sub_inject;
  }
}

sub role_provider {'Jojo::Role'}

sub with_roles {
  Carp::croak 'Jojo::Role 0.5.0+ is required for roles' unless ROLES;
  my ($self, @roles) = @_;

  return Jojo::Role->create_class_with_roles($self, @roles)
    unless my $class = Scalar::Util::blessed $self;

  return Jojo::Role->apply_roles_to_object($self, @roles);
}

BEGIN {
  %EXPORT_TAGS = (-base => [qw(has with)], -role => [qw(has)], -strict => [],);

  %EXPORT_GEN = (
    has => sub {
      my (undef, $target) = @_;
      return sub { Mojo::Base::attr($target, @_) }
    },
    with => sub {    # dummy
      return sub { Carp::croak 'Jojo::Role 0.5.0+ is required for roles' }
    },
  );

  return unless ROLES;

  push @{$EXPORT_TAGS{-role}}, @{$Jojo::Role::EXPORT_TAGS{-role}};

  $EXPORT_GEN{$_} = $Jojo::Role::EXPORT_GEN{$_}
    for @{$Jojo::Role::EXPORT_TAGS{-role}};
}

sub _generate_subs {
  my ($class, $target) = (shift, shift);
  return map { my $cb = $EXPORT_GEN{$_}; $_ => $class->$cb($target) } @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Jojo::Base::Compat

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
