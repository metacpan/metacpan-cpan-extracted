package Egg::Model::Session::Plugin::AbsoluteIP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: AbsoluteIP.pm 322 2008-04-17 12:33:58Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub init_session {
	my($self)= shift->next::method;
	if (my $ip= $self->data->{ipaddr}) {
		$ip eq $self->e->request->address || return do {
			$self->delete($self->session_id);
			$self->_remake_session;
		  };
	} else {
		$self->data->{ipaddr}= $self->e->request->address;
	}
	$self;
}
sub _remake_session {
	my($self)= @_;
	$self->next::method;
	$self->data->{ipaddr} ||= $self->e->request->address;
	@_;
}

1;

__END__

=head1 NAME

Egg::Model::Session::Plugin::AbsoluteIP - Plugin for session that confirms agreement of IP address. 

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   Plugin::AbsoluteIP
   .....
   );

=head1 DESCRIPTION

When IP address is not completely corresponding, it is a plugin for the session 
to treat as another session.

IP address at that time is preserved when a new session is opened, and the 
agreement of the IP address will be confirmed next time.

To use it, 'Plugin::AbsoluteIP' is added to 'startup'.

Moreover, 'init_session' is done in override, and note the competition with other
components, please.

Besides, there is L<Egg::Model::Session::Plugin::CclassIP> confirmed at C class
level, too. However, please note that it is not efficiency with this plugin 
simultaneously that uses.

=head1 METHODS

=head2 init_session

A new session is begun when not agreeing to IP address before.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Model::Session::Plugin::CclassIP>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

