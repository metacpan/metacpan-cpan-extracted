# Idea of RequestAgent is cut-n-paste from lwp-request
#
# If you know a better way of doing this, please let me know.
#
# We make our own specialization of LWP::UserAgent that asks for
# user/password if document is protected.

# $Id: RequestAgent.pm,v 1.2 2000/04/10 03:49:57 mah Exp $

package Image::Grab::RequestAgent;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require LWP::UserAgent;
@ISA = qw(LWP::UserAgent Exporter);
@EXPORT_OK = qw(
  &new
);
$VERSION='1.01';

use Carp;

my %realm;

sub new { 
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = LWP::UserAgent->new(@_);
  
  $self->env_proxy;

  bless $self, $class;
  return $self;
}

sub register_realm {
  my $self  = shift;
  my $realm = shift;
  my $user  = shift;
  my $pass  = shift;
  
  $realm{$realm}->{user} = $user;
  $realm{$realm}->{pass} = $pass;
}

sub get_basic_credentials  {
  my ($self, $realm) = @_;

  if(defined $realm{$realm}) {
    return ($realm{$realm}->{user},
	    $realm{$realm}->{pass});
  }
}

1;
