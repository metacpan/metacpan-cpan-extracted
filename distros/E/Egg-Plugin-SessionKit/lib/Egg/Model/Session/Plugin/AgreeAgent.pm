package Egg::Model::Session::Plugin::AgreeAgent;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: AgreeAgent.pm 322 2008-04-17 12:33:58Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub init_session {
	my($self)= shift->next::method;
	if (my $agent= $self->data->{user_agent}) {
		$agent eq $self->e->request->agent || return do {
			$self->delete($self->session_id);
			$self->_remake_session
		  };
	} else {
		$self->data->{user_agent}= $self->e->request->agent;
	}
	$self;
}
sub _remake_session {
	my($self)= @_;
	$self->next::method;
	$self->data->{user_agent} ||= $self->e->request->agent;
	@_;
}

1;

__END__

=head1 NAME

Egg::Model::Session::Plugin::AgreeAgent - Plugin for session that confirms agreement of HTTP_USER_AGENT.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   .....
   Plugin::AgreeAgent
   );

=head1 DESCRIPTION

When environment variable 'HTTP_USER_AGENT' is not completely corresponding,
it is a plugin for the session to treat as another session.

HTTP_USER_AGENT at that time is preserved when a new session is opened, and the
 agreement of the HTTP_USER_AGENT will be confirmed next time. 

To use it, 'Plugin::AgreeAgent' is added to 'startup'.

At this time, 'init_session' is done in override, and note the competition with
 other components, please. 

=head1 METHODS

=head2 init_session

HTTP_USER_AGENT before in agreement with begins a new session when it is not.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

