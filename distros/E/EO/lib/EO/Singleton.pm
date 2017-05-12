package EO::Singleton;

use warnings;
use strict;
use EO;

our @ISA       = qw( EO );
our $VERSION = 0.96;
my $_singletons = {};

sub new {
  my $class = shift;
  $_singletons->{$class} ||= $class->SUPER::new(@_);
}

sub _reset_singleton {
  my $self = shift;
  $_singletons->{ ref($self) } = $self;
}

sub get {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->SUPER::get( @_ );
}

sub set {
  my $self = ref($_[0]) ? shift : shift->new;
  $self->SUPER::set( @_ );
}

sub clone {
  my $self = shift;
  return $self;
}

1;

__END__

=head1 NAME

EO::Singleton - A generic singleton base class

=head1 SYNOPSIS

inherit from EO::Singleton:

  package MySingleton;
  use base qw( EO::Singleton );
  ...

then in your code:

  my $a = MySingleton->new;
  my $b = MySingleton->new;

and $a and $b will be the same object.

=head1 TODO

I want to be able to call MySingleton->method and have this be equivalent
to MySingleton->new->method.

=head1 AUTHOR

Tom Insam
tinsam@fotango.com

=head1 SEE ALSO

EO

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
