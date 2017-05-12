package ExpenseTracker::Controllers::User;
{
  $ExpenseTracker::Controllers::User::VERSION = '0.008';
}
{
  $ExpenseTracker::Controllers::User::VERSION = '0.008';
}
use Mojo::Base 'ExpenseTracker::Controllers::Base';
use Digest::MD5 qw(md5_hex);

sub new{
  my $self = shift;
  
  my $obj = $self->SUPER::new(@_);
  
  $obj->{resource} = 'ExpenseTracker::Models::Result::User';

  return $obj;
  
}

=head update
  sample of overriding a default update method
=cut
sub update{
  my $self = shift;
  
  return $self->render(status => 405,  json => {message => 'You can only update your own profile!!!'} )
    if ( !defined $self->param('id') or !defined $self->app->user or $self->param('id') != $self->app->user->id );

  return $self->SUPER::update(@_);
}

sub _before_create{
  my $self = shift;
  
  $self->{_payload}->{password} = Digest::MD5::md5_hex( $self->{_payload}->{password} );
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker::Controllers::User - Controller responsible for the User resource


=head1 VERSION

version 0.008

=cut
