#-----------------------------------------------------------------------------
# File: Users.pm
#-----------------------------------------------------------------------------

package HTML::Bricks::Users;

use strict;
use HTML::Bricks::Config;

our $VERSION = '0.02';

#-----------------------------------------------------------------------------
# new
#-----------------------------------------------------------------------------
sub new($$) {

  my ($class,$basedir) = @_;

  my $self = {};

  $self->{basename} = $basedir . '/bricks/data/users';

  bless $self, $class;
  return $self;
}

#---------------------------------------------------------------------
# remove
#---------------------------------------------------------------------
sub remove($$) {
  my ($self,$name) = @_;
  return undef;
} 

#---------------------------------------------------------------------
# get
#---------------------------------------------------------------------
sub get($$) {
  my ($self, $name) = @_;

  my %user;

  if ($name eq $HTML::Bricks::Config{admin_user_name}) {
    $user{name} = $name;
    $user{password} = $HTML::Bricks::Config{encrypted_admin_password};
    return \%user;
  }

  return undef;
}

#---------------------------------------------------------------------
# set
#---------------------------------------------------------------------
sub set($$$) {
  my ($self,$name,$ruser) = shift;
  return undef;
}

return 1;
