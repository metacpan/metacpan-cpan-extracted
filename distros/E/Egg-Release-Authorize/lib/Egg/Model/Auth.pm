package Egg::Model::Auth;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Auth.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	Egg::Model::Auth::handler->_setup($e);
	$class->next::method($e);
}
sub _finish {
	my($self)= @_;
	$self->any_hook(qw/ Model::Auth _finish /);
	$self->next::method;
}
sub _error_finalize {
	my($self)= @_;
	$self->any_hook(qw/ Model::Auth _error_finalize /);
	$self->next::method;
}

package Egg::Model::Auth::handler;
use strict;

sub new {
	my($class, $e, $c, $default)= @_;
	my $pkg= $e->project_name. '::Model::Auth';
	$e->model_manager->context($pkg->default);
}
sub _setup {
	my($class, $e)= @_;
	my $base= $e->project_name. '::Model::Auth';
	my $path= $e->path_to(qw{ lib_project  Model/Auth });
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	push @{"${base}::ISA"}, 'Egg::Base';
	$base->mk_classdata($_) for qw/ default labels /;
	my $labels= $base->labels($e->ixhash);
	for (sort (grep /.+\.pm$/, <$path/*>)) {  ## no critic.
		m{([^\\\/\:]+)\.pm$} || next;
		my $name = $1;
		my $dc   = "${base}::$name";
		my $c= $class->_init_config($dc);
		my $label= lc( $c->{label_name} || "auth::$name" );
		$e->model_manager->add_register(0, $label, $dc);
		$base->default($label) if $c->{default};
		$labels->{$label}= $dc;
		$dc->_setup($e);
	}
	%$labels || die __PACKAGE__. q{ - The Auth controller is not found.};
	$base->default((keys %$labels)[0]) unless $base->default;
	@_;
}
sub _init_config {
	my($class, $dc)= @_;
	$dc->require or die $@;
	my $c= $dc->config || die __PACKAGE__. qq{ - '$dc' config is empty.};
	$c->{interval}= 5 * 60 unless exists($c->{interval});
	$c->{interval}=~m{^\d+$}
	    || die qq{$dc - I want 'interval' a numerical value. };
	$c->{param_id}       ||= '__uid';
	$c->{param_password} ||= '__psw';
	$c->{login_get_ok} ||= 0;
	$class->__remake_regex($c, $_) for qw/ allow_hosts abs_allow_hosts  /;
	$dc->mk_classdata($_) for qw/ errors error_message /;
	$dc->errors({
	  100 => 'I want user ID.',
	  110 => 'ID is invalid.',
	  120 => 'ID is not registered.',
	  130 => 'Registered ID is empty.',
	  140 => 'Account is not active.',
	  200 => 'I want Password.',
	  210 => 'Password is invalid.',
	  220 => 'Registered password is empty.',
	  230 => 'Mistake of password.',
	  300 => 'Invalid session.',
	  400 => 'Internal error.',
	  500 => 'Method Not Allowed.',
	  510 => 'Forbidden.',
	  %{ $c->{error_messages} || {} },
	  });
	$c;
}
sub __remake_regex {
	my($class, $c, $key)= @_;
	$c->{$key} || return 0;
	my $tmp= ref($c->{$key}) eq 'ARRAY' ? $c->{$key}: [$c->{$key}];
	$c->{$key}= join '|', map{ quotemeta($_) }@$tmp if @$tmp;
}

1;

__END__

=head1 NAME

Egg::Model::Auth - Model by whom attestation function is offered.

=head1 SYNOPSIS

  my $auth= $e->model('auth_label');
  
  # The login form is checked.
  if (my $data= $auth->login_check) {
     .... Login OK.
  } else {
     .... Login failed.
  }
  
  # Maintenance logged in.
  my $data= $auth->is_login || return $e->finished(FORBIDDEN);
  $e->stash->{user_name}= $data->{___user};
  
  # Logout.
  $auth->logout;

=head1 DESCRIPTION

It is a model to use the attestation function.

To use it, the module is generated under the control of the project with the 
helper.

see L<Egg::Helper::Model::Auth>.

  % cd /path/to/MyApp/bin
  % ./egg_helper M::Auth [MODULE_NAME]

MyApp/Model/Auth/MODULE_NAME.pm is generated to the lib directory of the project
 with this.

And, 'Auth' is added to the MODEL setting of the project.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  .........
  ...
  MODEL => ['Auth'],

The attestation module is set up when the project is started by this and using
 it becomes possible.

=head1 HOW TO AUTH

The attestation data prepared beforehand is acquired by API system module, and
it attests it compared with data from which the data is input to the login form.
And, when it passes the attestation, the data is preserved in the session and 
the attestation at the back is maintained.

API class should be at least giving the ID column and the password column though
any composition is not cared about the column etc. of the prepared attestation 
data. 

  % vi /path/to/MyApp/lib/MyApp/Model/Auth/Hoo.pm
  ........
  ___PACKAGE__->config(
    file => {
      .............
      id_field       => 'id',
      password_field => 'passwd',
      },
    );

The example is a setting of API system module of the default that the helper 
script generates and it sets it with the key 'file'.
Some this setting methods are different depending on API system module used and
refer to the document for details, please.

And, please set the parameter name to receive the input value from the login form.

  ___PACKAGE__->config(
    ............
    param_id       => 'user_id',
    param_password => 'passwd',
    );

The login form can be checked only by calling 'login_check' method by this.

The login form in this setting becomes FORM of the following feeling.

  <FORM METHOD="POST" ACTION="[login_check_uri]">
  <INPUT NAME="userid" TYPE="text" />
  <INPUT NAME="passwd" TYPE="password" />
  </FROM>

API system module done to load it is done by 'setup_api' method.

  __PACKAGE__->setup_api('File');

Egg::Model::Auth::API::File is set up.
The part of 'Egg::Model::Auth::API' at the module name head is omitted and 
specified.
Besides, because L<Egg::Model::Auth::API::DBI> and L<Egg::Model::Auth::API::DBIC>
 are enclosed, this part is corrected according to the system.

Moreover, to build other components into API object, the list is passed following
the module name.

  __PACKAGE__->setup_api( File => qw/ Crypt::SHA1 / );

The part of first 'Egg::Model::Auth' of the component module is omitted and specified.

Next, it is a session system module.

   __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

The method of specifying the argument is almost the same as 'setup_api' though
 it does to the setup by 'setup_session' method. 

The part of 'Egg::Model::Auth::Session' omits, and is component name 'Egg::Model::Auth'
at the module name head is omitted.

I think that it is more efficient that L<Egg::Model::Session> uses installation
L<Egg::Model::Auth::Session::SessionKit> though L<Egg::Model::Auth::Session::FileCache>
 is specified in default.

The check by 'login_check' method is always needed though a session system module
operates unquestionably even, except for no setup.

To build in the plug-in module, the list is passed to 'setup_plugin' method.

  __PACKAGE__->setup_plugin(qw/ Keep /);

The part of 'Egg::Model::Auth::Plugin' is omitted.

It is the same object as a session system component that builds in. Therefore, 
it doesn't care even if this method is not used and it finishes by 'setup_session'.

  __PACKAGE__->setup_session( FileCache => qw/
    Bind::Cookie
    Plugin::Keep
    / );

The Auth controller's preparation is completed though it is a confusing 
explanation. 

It calls from the project as follows and it uses it.

   my $auth= $e->model('auth::hoo');

When 'label_name' is set, it is possible to call it by an arbitrary label name.

   __PACKAGE__->config(
      label_name => 'myauth',
      );

   my $auth= $e->model('myauth');

=head1 CONFIGURATION

It individually sets it in each AUTH controller who generates it with the 
helper.

=head3 label_name

Label name to receive object.

  my $auth= $e->model('label_name');

=head3 default

The AUTH controller defaults when keeping effective and it is treated.

=head3 interval

The interval of the re-attestation after it attests it is set.

Real data is acquired at these intervals and the data of the session is 
confirmed.

Default is '5 * 60'. ( 5 minutes )

=head3 param_id

ID name of login form.

=head3 param_password

Password name of login form.

=head3 login_get_ok

The request method returns and 'login_check' method comes not to return GET the
error either.

=head3 allow_hosts

'login_check' method comes to return the error whenever it requests excluding 
the host who set it.

However, when environment variable HTTP_REFERER is not obtained, the error is 
not returned.

  allow_hosts => [qw/
    myhost.com
    www.myhost.com
    ......
    /],

=head3 abs_allow_hosts

'login_check' method comes to return the error whenever it requests excluding 
the host who set it.
It makes an error of here when environment variable HTTP_REFERER is not 
obtained.

  abs_allow_hosts => [qw/
    myhost.com
    www.myhost.com
    ......
    /],

=head3 allow_addr_regexp

It comes to return the error when not matching it to the putter of set Internet 
Protocol address.

   allow_addr_regexp => qr{^(?:192\.168\.1\.\d+|192\.168\.11\.\d+)$},

=head3 error_messages

The error message of default is changed.

The setting is HASH, and the structure is made '[error_code] =E<gt> [error_message]'.

  error_message => {
    100 => 'I want user ID.',
    110 => 'ID is invalid.',
    .............
    },

The error message is set to the following way way in default.

  100 ..... I want user ID.
  110 ..... ID is invalid.
  120 ..... ID is not registered.
  130 ..... Registered ID is empty.
  140 ..... Account is not active.
  200 ..... I want Password.
  210 ..... Password is invalid.
  220 ..... Registered password is empty.
  230 ..... Mistake of password.
  300 ..... Invalid session.
  400 ..... Internal error.
  500 ..... Method Not Allowed.
  510 ..... Forbidden.

The change is not scheduled in the future though the code is the one having 
negligently allocated it.

=head1 METHODS

This module doesn't have the method that can be especially used.

AUTH controller's base class L<Egg::Model::Auth::Base>
Please refer to base class L<Egg::Model::Auth::Base::API> of API module.

=head2 new

Constructor.

The object of the AUTH controller of default is returned.

  my $auth= $e->model('auth');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::Auth::Base>,
L<Egg::Model::Auth::Base::API>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

