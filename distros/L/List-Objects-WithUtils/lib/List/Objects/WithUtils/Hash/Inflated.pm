package List::Objects::WithUtils::Hash::Inflated;
$List::Objects::WithUtils::Hash::Inflated::VERSION = '2.028003';
use strictures 2;
use Carp ();
use Scalar::Util ();

sub new {
  bless +{ @_[1 .. $#_] }, $_[0]
}

sub DEFLATE { %{ $_[0] } }

our $AUTOLOAD;

sub can {
  my ($self, $method) = @_;
  if (my $sub = $self->SUPER::can($method)) {
    return $sub
  }
  return unless exists $self->{$method};
  sub { 
    my ($self) = @_;
    if (my $sub = $self->SUPER::can($method)) {
      goto $sub
    }
    $AUTOLOAD = $method; 
    goto &AUTOLOAD 
  }
}

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s/.*:://;
  Scalar::Util::blessed($self)
    or Carp::confess "Not a class method: '$method'";
  
  Carp::confess "Can't locate object method '$method'"
    unless exists $self->{$method};
  Carp::confess "Accessor '$method' is read-only"
    if @_;

  $self->{$method}
}

sub DESTROY {}

1;

=pod

=for Pod::Coverage new can AUTOLOAD DEFLATE

=cut
