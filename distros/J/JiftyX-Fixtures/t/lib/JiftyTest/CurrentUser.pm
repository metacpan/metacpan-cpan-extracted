package JiftyTest::CurrentUser;
our $VERSION = '0.07';

use warnings;
use strict;

use base qw(Jifty::CurrentUser);
use JiftyTest::Model::User;

 #sub new {
 #  my $self = bless {}, shift;
 #  $self->SUPER::new;
 #  _init(@_);
 #  $self;
 #}

sub _init {
  my ($self, %args) = @_;

  if (keys %args) {
    delete $args{_bootstrap};
    $self->user_object( Jifty->app_class("Model","User")->new(current_user => $self)->set_id(1) );
    $self->user_object->load_by_cols(%args);
    # $self->{is_superuser} => 1 if $self->user_object->role eq "admin";
  }
  $self->SUPER::_init(%args);
}


1;
