use strict;
use warnings;

package Lazy::Iterator;
$Lazy::Iterator::VERSION = '0.003';
#ABSTRACT: Objects encapsulating a set of lazy evaluation functions.


use Carp qw/ croak /;
use Scalar::Util qw/ blessed /;

use constant SCALAR_DEFER => eval { require Scalar::Defer; 1 };

sub _isa { defined blessed $_[0] and $_[0]->isa($_[1]); }


sub new {
  my ($class, $source) = @_;

  if (SCALAR_DEFER and _isa($source, 0)) {
    my $sd = $source;
    $source = sub { Scalar::Defer::force $sd };
  }

  croak "Not a CODE reference: $source" if ref $source ne 'CODE';

  return bless {code => $source, exhausted => 0}, $class;
}


sub exhausted {
  my $self = shift;

  $self->{get} = $self->get();

  return $self->{exhausted};
}


sub get {
  my $self = shift;

  return delete $self->{get} if exists $self->{get};

  return undef if $self->{exhausted};

  my $ret = $self->{code}->();
  $self->{exhausted} = 1 if not defined $ret;

  return $ret;
}


sub get_all {
  my $self = shift;

  my @res;
  while (defined(my $get = $self->get())) { push @res, $get; }

  return @res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lazy::Iterator - Objects encapsulating a set of lazy evaluation functions.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Lazy::Iterator;

  my $lazy = Lazy::Iterator->new(sub { state $i++ });

  while (my $next = $lazy->get()) { print "$next\n"; sleep 1; }

=head1 DESCRIPTION

Objects encapsulating a set of lazy evaluation functions, meaning you can
combine them using the L<C<l_*>|Lazy::Util/"C<l_*> functions"> functions from
L<C<Lazy::Util>>.

=head1 METHODS

=head2 C<< Lazy::Iterator->new($source) >>

  my $lazy = Lazy::Iterator->new(sub { $i++ });

C<< Lazy::Iterator->new >> takes a code reference which will be used as the
source for all the values and returns a C<Lazy::Iterator> object encapsulating
that source.

The C<$source> needs to be either a C<CODE> reference, or a C<Scalar::Defer>
variable of type C<0>, provided you have C<Scalar::Defer> available.

=head2 C<< $lazy->exhausted() >>

  my $exhausted = $lazy->exhausted();

C<< $lazy->exhausted() >> checks if there's any more values left in the source,
and caches any such value for the next C<< $lazy->get() >> call. It returns 0
if there are values left, and 1 if the source is exhausted.

An exhausted C<Lazy::Iterator> object will always return C<undef> from a
C<< $lazy->get() >> call.

=head2 C<< $lazy->get() >>

  my $next = $lazy->get();

C<< $lazy->get >> returns the next value from the source it encapsulates. When
there are no more values it returns C<undef>.

=head2 C<< $lazy->get_all() >>

  my @crazy = $lazy->get_all();

C<< $lazy->get_all >> returns all the values from the source, if it can. B<This
has the potential to never return as well as running out of memory> if given a
source of infinite values.

=head1 NOTES

If L<Scalar::Defer> is installed, it will assume that any variable of type C<0>
is a C<Scalar::Defer> variable and will treat it as a source of values.

=head1 SEE ALSO

=over 4

=item L<Lazy::Util>

=item L<Scalar::Defer>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
