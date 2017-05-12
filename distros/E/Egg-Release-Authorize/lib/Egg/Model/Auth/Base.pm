package Egg::Model::Auth::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Base Egg::Component /;
use Egg::Model::Auth::Base::API;

our $VERSION= '0.01';

__PACKAGE__->mk_accessors(qw/ is_error data handlers /);

sub error_undefind_id       { 100 }
sub error_invalid_id        { 110 }
sub error_not_registered    { 120 }
sub error_id_empty          { 130 }
sub error_not_active        { 140 }
sub error_undefind_password { 200 }
sub error_invalid_password  { 210 }
sub error_password_empty    { 220 }
sub error_mistake_password  { 230 }
sub error_invalid_session   { 300 }
sub error_innternal         { 400 }
sub error_method_not_allowd { 500 }
sub error_forbidden         { 510 }

sub setup_plugin {
	my $class= shift;
	$class->isa_register(1, "Egg::Model::Auth::Plugin::$_")
	        for (ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_);
	$class->isa_terminator(__PACKAGE__);
	$class;
}
sub setup_session {
	my $class = shift;
	my $s_name= shift || croak q{I want session name.};
	my @comps;
	if (@_) { push @comps, $_ for (ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_) }
	$class->isa_register
	        (1, $_, "Egg::Model::Auth::$_") for (@comps, "Session::$s_name");
	$class->isa_terminator(__PACKAGE__);
	$class;
}
sub setup_api {
	my $class= shift;
	my $a_name= shift || croak q{I want api name.};
	my $comps= $_[1] ? [@_]: ($_[0] || []);
	my $api;
	if ($class->can('default')) {
		$api= $class->api_list;
	} else {
		$class->mk_classdata('default');
		$class->mk_classdata('api_list');
		$class->default(lc $a_name);
		$api= $class->api_list( $class->ixhash );
	}
	my $b_class= 'Egg::Model::Auth::Base::API';
	my $a_class= "${class}::API::$a_name";
	$api->{lc $a_name}= $a_class;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	@{"${a_class}::ISA"}= $b_class;
	$a_class->isa_register(1, $_, "Egg::Model::Auth::$_")
	    for ((ref($comps) eq 'ARRAY' ? @$comps: $comps), "API::$a_name");
	$a_class->isa_terminator($b_class);
	$a_class->can('myname') || die
	qq{Method of 'myname' is not found from 'Egg::Model::Auth::API::$a_name'.};
	$a_class->config($class->config);
	$a_class->mk_classdata($_)
	    for qw/ id_col psw_col act_col grp_col parent_class /;
	$a_class->parent_class($class);
	$class;
}
sub new {
	my($class, $e)= @_;
	bless { e => $e, handlers => {} }, $class;
}
sub _setup {
	my($class, $e)= @_;
	$_->_setup($e) for values %{$class->api_list};
	$class->next::method($e);
}
sub api {
	my $self = shift;
	my $label= lc(shift) || $self->default;
	$self->handlers->{$label} ||= do {
		my $api= $self->api_list->{$label}
		       || croak qq{Auth API of '$label' is not found.};
		$api->new($self, $self->e);
	  };
}
sub login_check {
	my $self= shift;
	my $api= $self->api( (@_== 3 or @_ == 1) ? shift: undef );
	$self->reset;
	my($c, $req)= ($self->config, $self->e->request);
	return $self->error( &error_method_not_allowd )
	    if ($req->is_head or (! $c->{login_get_ok} and $req->is_get));
	{
		my $regexp;
		if ($regexp= $c->{allow_addr_regexp}) {
			$req->address=~m{$regexp}
			        || return $self->error( &error_forbidden );
		}
		if ($regexp= $c->{allow_hosts}) {
			if (my $referer= $req->referer) {
				$referer=~m{^https?\://(?:$regexp)}
				    || return $self->error( &error_forbidden );
			}
		} elsif ($regexp= $c->{abs_allow_hosts}) {
			my $referer= $req->referer
			        || return $self->error( &error_forbidden );
			$referer=~m{^https?\://(?:$regexp)}
			        || return $self->error( &error_forbidden );
		}
	  };
	my $id = shift || $req->params->{$c->{param_id}}
	               || return $self->error( &error_undefind_id );
	my $psw= shift || $req->params->{$c->{param_password}}
	               || return $self->error( &error_undefind_password );
	$api->valid_id($id)
	       || return $self->error( &error_invalid_id );
	$psw=~s{^\s+} [];  $psw=~s{\s+$} [];
	$api->valid_password($psw)
	       || return $self->error( &error_invalid_password );
	my $data= $self->__more_check(0, $api, $id, $psw) || return 0;
	$self->data($data);
}
sub is_login {
	my $self= shift;
	my $session= shift || $self->data || $self->get_session
	          || return $self->error( &error_invalid_session );
	$self->reset;
	return $self->__invalid_session unless ref($session) eq 'HASH';
	my $id = $session->{___user} || return $self->__invalid_session;
	my $old= $session->{___start_interval} || return $self->__invalid_session;
	return ($old < (time- $self->config->{interval})) ? do {
		my $label= $session->{___api_name} || $self->__invalid_session;
		$self->__continue_check
		   ($self->api($label), $id, $session) || $self->remove_session;
	  }: do {
		$self->data($session);
	  };
}
sub logout {
	$_[0]->remove_session;
	1;
}
sub user_name {
	my $self= shift;
	my $data= $self->data || $self->is_login || return (undef);
	$data->{___user} || (undef);
}
sub group_check {
	my $self = shift;
	$self->user_name || return 0;
	my $group= shift || croak 'I want group name.';
	   $group=~s{\s+$} [];
	my $data = $self->data->{___group} || return 0;
	$group eq $data ? 1: 0;
}
sub remove_session {
	my($self)= @_;
	$self->remove_bind_id;
	$self->reset;
	0;
}
sub reset {
	my($self)= @_;
	$self->data( undef );
	$self->is_error( undef );
	$self->error_message( undef );
	$self;
}
sub get_bind_id    { }
sub set_bind_id    { }
sub remove_bind_id { }

sub __invalid_session {
	my($self)= @_;
	$self->remove_session;
	$self->error( &error_invalid_session );
}
sub __continue_check {
	my($self, $api, $id, $session)= @_;
	my $psw= $session->{___input_password}
	       || return $self->error( &error_undefind_password );
	$self->__more_check(1, $api, $id, $psw, $session);
}
sub __more_check {
	my($self, $continue, $api, $id, $psw, $session)= @_;
	my $data= $api->restore_member($id, $session)
	       || return $self->error( &error_not_registered );
	$data->{___active}
	       || return $self->error( &error_not_active );
	$data->{___password}
	       || return $self->error( &error_password_empty );
	$api->password_check($data->{___password}, $psw, $data)
	       || return $self->error( &error_mistake_password );
	$data->{___group}=~s{\s+$} [] if $data->{___group};
	$self->__setup_data($continue, $api, $id, $psw, $data);
}
sub __setup_data {
	my($self, $continue, $api, $id, $psw, $data)= @_;
	$data->{__api_name}        ||= $api->myname;
	$data->{___user}           ||= $id;
	$data->{___input_password} ||= $psw;
	$data->{___start_interval}   = time;
	$self->data( $self->set_session($data) );
}
sub _finish {
	my($self)= @_;
	$self->___any_hook('_finish');
	$self->next::method;
}
sub _finalize_error {
	my($self)= @_;
	$self->___any_hook('_finalize_error');
	$self->next::method;
}
sub ___any_hook {
	my($self, $method)= @_;
	my $list= $self->handlers || return 0;
	$_->$method for values %$list;
}
sub error {
	my $self= shift;
	return 0 if $self->is_error;
	my $code= shift || 400;
	if (my $msg= $self->errors->{$code}) {
		$self->error_message($msg);
	} else {
		$self->error_message($code);
		$code= 400;
	}
	$self->is_error($code);
	0;
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Base - Base class for AUTH controller.

=head1 SYNOPSIS

  package MyApp::Model::Auth::Hooo;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config ( ....... );
  
  __PACKAGE__->setup_plugin( ...... );
  
  __PACKAGE__->setup_session( ...... );
  
  __PACKAGE__->setup_api( ...... );

=head1 DESCRIPTION

It is a base class to succeed to from the AUTH controller who outputs it with 
L<Egg::Helper::Model::Auth>.

=head1 METHODS

L<Egg::Base> and L<Egg::Component> have been succeeded to.

=head2 setup_plugin ([PLUGIN_LIST])

It is made to use by registering Plugin system module in @ISA of this class.

PLUGIN_LIST is a list of the name of Plugin system module. The part of 
'Egg::Model::Auth::Plugin' is omitted and specified.

  __PACKAGE__->setup_plugin(qw/ Keep /);

=head2 setup_session ([SESSION_NAME] => [COMP_LIST])

It is made to use by registering Session system module in @ISA of this class.

SESSION_NAME is a name of Session system module. The part of 
'Egg::Model::Auth::Session' is omitted and specified.

  __PACKAGE__->setup_session('SessionKit');

COMP_LIST is passed by the list if there is a component module that wants to 
register in addition.
The name that omits the part of 'Egg::Model::Auth' is specified.

  __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie /);

=head2 setup_api ([API_NAME] => [COMP_LIST])

It is made to use by registering API system module to API class.

  __PACKAGE__->setup_api('DBI');

Additionally, COMP_LIST is a list of the module name that wants to be built into
API class. The name that omits the part of 'Egg::Model::Auth' is specified.

  __PACKAGE__->setup_api( File => qw/ Crypt::SHA1 /);

To use a different kind of API module at the same time, setup_api is described.
two or more.

However, the same kind of API module cannot be used at the same time.

   __PACKAGE__->setup_api('DBI');
   __PACKAGE__->setup_api( File => qw/ Crypt::SHA1 / );
   
   # And, the API_NAME is specified by 'login_check' method.
   $e->model('auth::hooo')->login_check('dbi');

=head2 new

Constructor.

  my $auth= $e->model('auth_label_name');

=head2 api ([API_NAME])

API object set by 'setup_api' method is returned.

API_NAME passes the name passed to 'setup_api' method.

When API_NAME is total abbreviated, API object that default and has been treated
is returned.

  my $api= $auth->api('File');

=head2 login_check ([API_NAME], [USER_ID], [PASSWORD])

The argument is passed to API object, the attestation check is done, and if it 
is correct, the mass of the attestation data is returned by the HASH reference.
When the attestation session is begun, it is necessary to call this method.

API_NAME passes the name passed to 'setup_api' method.
When API_NAME is total abbreviated, API object of default is used.

When USER_ID is omitted, the acquisition of form input data of 'id_param' is tried.

When PASSWORD is omitted, the acquisition of form input data of 'password_param'
is tried.

  if (my $user= $auth->login_check('File', $user_id, $password)) {
     ...... It was possible to log it in.
  } else {
     ...... It is not possible to log it in.
  }

  # When you omit API.
  if (my $user= $auth->login_check($user_id, $password)) {
     ......
  } .....
  
  # It shortens further if ID and the password are obtained from the input of the form.
  if (my $user= $auth->login_check) {
     ......
  } ....

The content of the error can be acquired in 'is_error' and 'error_message' 
though 0 is returned when the attestation doesn't pass.

  if (my $user= $auth->login_check) {
     ......
  } else {
     # The error message buried under the template is set.
     $e->stash->{error_message}= $auth->error_message;
  }

The error message can be customized.

see L<Egg::Model::Auth>.

=head2 is_login

The attestation of the session begun on 'login_check' method is returned.

The cross-check with API object of the interval set in 'interval' is done.

  if ($auth->is_login) {
    ...... The screen etc. only for the member are displayed.
  } else {
    return $e->finished(403);
  }

=head2 logout

It logs out annulling the attestation session.

  $auth->logout;
  $e->stash->{logout_message}= 'Thank you for use.';

=head2 user_name

ID under the attestation is returned.

If 'is_login' method has not been called yet, 'is_login' is called.

  if (my $user_name= $auth->user_name) {
     $e->stash->{message}= "Mr. ${user_name} hello.";
  } else {
     return $e->finished(403);
  }

=head2 group_check ([GROUP_NAME])

User's authority etc. under the attestation are checked.

Invalidity always returns if 'group_field' is not set by the configuration.

  $e->stash->{group_name}= 
     $auth->group_check('SYSOP') ? 'Manager' : 'General';

=head2 remove_session

The attestation session is annulled and 'reset' method is called. In a word the
 same thing as 'logout' method is done.

As for 'logout' method, the point to always return an effective value is different 
though this method always returns an invalid value.

  $auth->remove_session;

=head2 reset

Login in 'login_check' method is invalidated. However, the session is not annulled.

  $auth->reset;

=head2 get_bind_id, set_bind_id, remove_bind_id

Nothing is done.

see L<Egg::Model::Auth::Bind::Cookie>.

=head2 data

HASH to refer to the data acquired after it attests it is restored.

It doesn't become, and do not change inside data about this data leading only, 
please.

  my $email= $auth->data->{email};

=head2 is_error

When failing in the attestation because of 'login_check' and 'is_login', the 
error code is returned.

=head2 error_message

When failing in the attestation because of 'login_check' and 'is_login', the 
error message is returned.

Please set 'error_messages' of the configuration to customize the error message.

see L<Egg::Model::Auth>.

=head2 error ([ERROR_CODE])

ERROR_CODE is set in 'is_error' method, and the error message of correspondence
 is set in 'error_message' method. And, an invalid value is returned.

When the error message corresponding to passed ERROR_CODE is not obtained, 400 
is set in is_error, and ERROR_CODE is set in 'error_message' method.

If 'is_error' has defined it, an invalid value has been returned without doing 
anything.

=head2 error_*

Besides, the method of returning the following error codes is prepared.

=over 4

=item * error_undefind_id       = 100

=item * error_invalid_id        = 110

=item * error_not_registered    = 120

=item * error_id_empty          = 130

=item * error_not_active        = 140

=item * error_undefind_password = 200

=item * error_invalid_password  = 210

=item * error_password_empty    = 220

=item * error_mistake_password  = 230

=item * error_invalid_session   = 300

=item * error_innternal         = 400

=item * error_method_not_allowd = 500

=item * error_forbidden         = 510

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,
L<Egg::Base>,
L<Egg::Component>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

