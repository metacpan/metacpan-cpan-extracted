package ExpenseTracker::Controllers::Currency;
{
  $ExpenseTracker::Controllers::Currency::VERSION = '0.008';
}
{
  $ExpenseTracker::Controllers::Currency::VERSION = '0.008';
}
use Mojo::Base 'ExpenseTracker::Controllers::Base';
use DateTime;

sub new{
  my $self = shift;
  
  my $obj = $self->SUPER::new(@_);
  
  $obj->{resource} = 'ExpenseTracker::Models::Result::Currency';

  return $obj;
  
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker::Controllers::Currency - Controller responsible for the Currency resource


=head1 VERSION

version 0.008

=cut
