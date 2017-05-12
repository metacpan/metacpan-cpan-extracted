package Egg::Model::Auth::Session::SessionKit;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SessionKit.pm 348 2008-06-14 19:02:44Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	$e->model_manager->isa('Egg::Model::Session')
	     || die q{I want setup of 'Egg::Model::Session'.};
	my $c= $class->config->{sessionkit}
	     || die q{I want config 'sessionkit'.};
	my $model_name= $c->{model_name}
	     || die q{I want config 'sessionkit' -> 'model_name'.};
	$e->is_model($model_name)
	     || die qq{'$model_name' model is not found.};
	$class->mk_classdata($_) for qw/ model_name session_key /;
	$class->model_name($model_name);
	$class->session_key
	     ($c->{atuh_session_key_name} || '___atuh_session_data');
	$class->next::method($e);
}
sub session {
	$_[0]->{___session} ||= $_[0]->e->model($_[0]->model_name);
}
sub get_session {
	$_[0]->session->{$_[0]->session_key} || 0;
}
sub set_session {
	my $self= shift;
	my $data= shift || croak 'I want session data.';
	my $update= $self->session->is_update;
	$self->session->{$self->session_key}= $data;
#	$self->session->is_update(0) unless $update;
	$data;
}
sub remove_session {
	my($self, $id)= @_;
	delete $self->session->{$self->session_key}
	    if $self->session->{$self->session_key};
	$self->next::method($id);
}

1;

=head1 NAME

Egg::Model::Auth::Session::FileCache - Session management for AUTH component that uses Egg::Model::Session.

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    sessionkit => {
      model_name       => 'session_model_name',
      auth_session_key => '___atuh_session_data',
      },
    );
  
  __PACKAGE__->setup_session('SessionKit');

=head1 DESCRIPTION

An easy session function is offered to the AUTH component by L<Egg::Model::Session>.

The setting of 'Sessionkit' is added to the configuration to use it and 'SessionKit'
is set by 'setup_session' method.

It is L<Egg::Model::Auth::Session::FileCache> and there is not building in a 
necessary Bind system component needing.
The string putting with the client is left to L<Egg::Model::Session>.

If L<Egg::Model::Session> is not set up, the exception is generated.

=head1 CONFIGURATION

=head3 model_name

Label name of L<Egg::Model::Session> to receive session data.

=head3 auth_session_key

Name of key to preserve attestation data in data received from L<Egg::Model::Session>.

Default is '___atuh_session_data'.

=head1 METHODS

=head2 session

The controller object of L<Egg::Model::Session> is returned.

=head2 get_session ([SESSION_ID])

The session data corresponding to SESSION_ID is returned.

=head2 set_session ([SESSION_DATA_HASH], [SESSION_ID])

The session data is preserved.

=head2 remove_session ([SESSION_ID])

The session data corresponding to SESSION_ID is annulled.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Session>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

