package List::Objects::WithUtils::Hash::Inflated::RW;
$List::Objects::WithUtils::Hash::Inflated::RW::VERSION = '2.028003';
use strictures 2;
use Carp ();
use Scalar::Util ();

use parent 'List::Objects::WithUtils::Hash::Inflated';

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s/.*:://;
  Scalar::Util::blessed($self)
    or Carp::confess "Not a class method: '$method'";

  Carp::confess "Can't locate object method '$method'"
    unless exists $self->{$method};
  return $self->{$method} unless @_;
  Carp::confess "Multiple arguments passed to setter '$method'"
    if @_ > 1;
  $self->{$method} = $_[0]
}

1;

=pod

=for Pod::Coverage AUTOLOAD

=cut
