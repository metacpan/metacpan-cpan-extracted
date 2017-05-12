package Egg::Model::Session;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Session.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub _setup {
	my($class, $e)= @_;
	Egg::Model::Session::handler->_setup($e);
	$class->next::method($e);
}
sub _output {
	my($self, $e)= @_;
	$self->any_hook(qw/ Model::Session _output /);
	$self->next::method($e);
}
sub _finalize_error {
	my($self, $e)= @_;
	$self->any_hook(qw/ Model::Session _finalize_error /);
	$self->next::method($e);
}

package Egg::Model::Session::handler;
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/ Egg::Model /;

sub new {
	my($class, $e)= @_;
	$e->{session_default} ||= do {
		my $pkg= $e->project_name. '::Model::Session';
		$e->model_manager->context($pkg->default);
	  };
}
sub _setup {
	my($class, $e)= @_;
	my $base= $e->project_name. '::Model::Session';
	my $path= $e->path_to(qw{ lib_project  Model/Session });
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	push @{"${base}::ISA"}, 'Egg::Base';
	$base->mk_classdata($_) for qw/ default labels /;
	my $labels= $base->labels( $e->ixhash );
	for (sort (grep /.+\.pm$/, <$path/*>)) {  ## no critic.
		m{([^\\\/\:]+)\.pm$} || next;
		my $name= $1;
		my $dc  = "${base}::$name";
		my $tc  = "${dc}::TieHash";
		$dc->require or die $@;
		$dc->mk_classdata('label_name');
		my $c= $dc->config || die qq{I want setup ${dc}->config.};
		my $label= $dc->label_name( $c->{label_name} || "session::$name" );
		$e->model_manager->add_register(0, $label, $dc);
		$tc->config($c);
		$base->default($label) if $c->{default};
		$tc->_setup($e);
		$tc->startup($e, $c);  ## Compatibility with old version.
		$labels->{$label}= $dc;
	}
	%$labels or die q{ The session component is not found. };
	$base->default((keys %$labels)[0]) unless $base->{default};
	@_;
}

1;

__END__

=head1 NAME

Egg::Model::Session - Model to use session.

=head1 SYNOPSIS

  my $session= $e->model('session_label');
  
  # Data is preserved in the session.
  $session->{hoge}= 'booo';
  
  # The session is shut and it preserves it.
  $session->close_session;

=head1 DESCRIPTION

It is a model to use the session.

To use it, the module is generated under the control of the project with the 
helper.

see L<Egg::Helper::Model::Session>.

  % cd /path/to/MyApp/bin
  % ./egg_helper M::Session [MODULE_NAME]

It is this and MyApp? in the lib directory of the project.
 '... /Model/Session/MODULE_NAME.pm' is generated.

And, 'Session' is added to the MODEL setting of the project.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  .........
  ...
  MODEL => ['Session'],

The session module is set up when the project is started by this and using it
becomes possible.

Two or more kind of sessions can be treated at the same time by setting up two
or more this session modules.

=head1 HOW TO SESSION

To acquire the session data, it acquires it specifying the label name that 
relates to the generated module name.

  # If it is MyApp::Model::Session::Hoge
  #   ( The capital letter and the small letter are identified )
  my $session= $e->model('session::hoge');

The label name can set the name of the favor with Confifration of the session 
module.

  __PACKAGE__->config(
    label_name => 'myname',
    );

When the above-mentioned setting is done, easiness can be done a little by 
specifying the label name.

  my $session= $e->model('myname');

However, please note no collision with the label name that other models use.

The obtained object only puts data in and out as it is because it is session 
data now. 

  my $session_data= $session->{hoge};
  
  $session->{new_data}= 'ok';

And, the session is preserved by the 'close_session' method.

  $session->close_session;

However, because 'close_session' method is called if it is necessary for '_finish'
hook of the project being called, 'close_session' need not usually be considered
in the application.

The judgment whether it preserves or annul it is L<Egg::Model::Session::Manager>.
It judges with the flag that drinks and is set in 'is_update'.
Only when the key to a single hierarchy is substituted, this flag is set.
Therefore, the update of the value of the subhierarchy cannot be judged for 
HASH of the layered structure.
To update only the value of the subhierarchy and to preserve it, 'is_update' 
should be made effective specifying it.

  # Only it is to be referred to the hoge key, is_update : like being undefined.
  $session->{hoge}{booo} = 1;
  
  # It is necessary to define is_update for oneself.
  $session->is_update(1);

  # The necessity is not in is_update if it is this.
  $session->{hoge}{booo} = 1;
  $session->{banban}     = 'ok';

=head1 SESSION MODULE

The session module generated with the helper
has 'MyApp::Model::Session::[MODEULE_NAME]::Manager' class
that succeeds to 'L<Egg::Model::Session::Manager::TieHash>'
with 'MyApp::Model::Session::[MODEULE_NAME]::Manager' class
that succeeds to 'L<Egg::Model::Session::Manager::Base>'.

The configuration of the session is done in the Manager class.

  package MyApp::Model::Session::Hoge;
  use strict;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    label_name=> 'myname',
    .........
    ....
    );

When two or more session modules have been treated, the session that sets
'default' and treats by default can be specified.

The session treated by default in the result of sorting is decided if there is
no 'default' all.

  __PACKAGE__->config(
    default => 1,
    );

Please refer to the document of the component module for each TieHash for the
content set to the configuration.

And, it is 'startup' method and TieHash. The name of the component module that
decides the operation of the class is specified.

  __PACKAGE__->startup(
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    );

It becomes above in default,

and L<Egg::Model::Session::ID::SHA1>
and L<Egg::Model::Session::Bind::Cookie>
and L<Egg::Model::Session::Base::FileCache>

However, Yo is seen.

The following roles are in the above-mentioned each component module.

  ID::SHA1        ... Session ID issue etc.
  Bind::Cookie    ... Session ID ties to the client.
  Base::FileCache ... Reading and preservation. of session data.

Moreover, they are all described here and it uses it though it is thought 
according to circumstances that the component and the plugin, etc.
concerning the preservation form are necessary. 

When '+' is applied to the head, it is treated as a full name though it only has
to specify since 'Egg::Model::Session' for the name.

  __PACKAGE__->startup(
    .....
    +Egg::Plugin::SessionKit::Bind::URI
    );

=head2 List of component module enclosed with this package.

=head3 I/O relation of session data.

L<Egg::Model::Session::Base::DBI>,
L<Egg::Model::Session::Base::DBIC>,
L<Egg::Model::Session::Base::FileCache>,

=head3 Relation of session ID and client.

L<Egg::Model::Session::Bind::Cookie>,

=head3 Session ID issue etc.

L<Egg::Model::Session::ID::IPaddr>,
L<Egg::Model::Session::ID::MD5>,
L<Egg::Model::Session::ID::SHA1>,
L<Egg::Model::Session::ID::UniqueID>,
L<Egg::Model::Session::ID::UUID>,

=head3 Preservation form relation of session data.

L<Egg::Model::Session::Store::Base64>,
L<Egg::Model::Session::Store::UUencode>,

=head3 Plugin etc.

L<Egg::Model::Session::Plugin::AbsoluteIP>,
L<Egg::Model::Session::Plugin::AgreeAgent>,
L<Egg::Model::Session::Plugin::CclassIP>,
L<Egg::Model::Session::Plugin::Ticket>,

=head1 METHODS

=head2 new

This constructor returns the session object of the read default configuration.

=head1 MANAGER CLASS

The manager class is an object that wrapped the session data.
TieHash according to AUTOLOAD though there is too no method that can be used.
It is possible to use it in shape to relay the method of the class.

=head1 TIEHASH CLASS

It is an object that becomes a main body that treats the session data.

Each TieHASH component : the method with the @ISA base. It is common.

=head1 HOOK METHOD

'_finish' and '_finalize_error' are picked up because it is 'close_session'
and TieHash. The hook is done to the class.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::Session::Manager::Base>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Helper::Model::Session>,
L<UNIVERSAL::require>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

