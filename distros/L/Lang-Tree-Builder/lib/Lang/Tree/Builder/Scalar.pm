package Lang::Tree::Builder::Scalar;

=head1 NAME

Lang::Tree::Builder::Scalar - simple class representing a scalar.

=head1 SYNOPSIS

  my $scalar = new Lang::Tree::Builder::Scalar();
  $scalar->is_scalar == 1; # true
  $scalar->name eq 'scalar'; # true
  $scalar->lastpart eq 'scalar'; # true

This class is polymorphic with C<Lang::Tree::Builder::Class> and represents a
simple scalar in a way that is convenient for the templates.

=head2 new

Creates a new instance of a scalar. This is called via
C<Lang::Tree::Builder::Class::new> and so is effectively a singleton.

=cut

sub new {
    my ($class) = @_;
    bless {}, $class;
}

=head2 is_scalar

Returns true.

=cut

sub is_scalar { 1 }

=head2 is_substantial

Returns false.

=cut

sub is_substantial { 0 }

=head2 name

Returns C<scalar>.

=cut

sub name { 'scalar' }

=head2 lastpart

Returns C<scalar>.

=cut

sub lastpart { 'scalar' }

1;
