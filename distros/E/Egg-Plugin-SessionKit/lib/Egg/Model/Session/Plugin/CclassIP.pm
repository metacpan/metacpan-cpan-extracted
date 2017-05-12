package Egg::Model::Session::Plugin::CclassIP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CclassIP.pm 322 2008-04-17 12:33:58Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub init_session {
	my($self)= shift->next::method;
	if (my $regexp= $self->data->{c_class_ipaddr}) {
		$self->e->request->address=~m{^$regexp} || return do {
			$self->delete($self->session_id);
			$self->_remake_session;
		  };
	} else {
		$self->_c_class_ipaddr;
	}
	$self;
}
sub _remake_session {
	my($self)= @_;
	$self->next::method;
	$self->data->{c_class_ipaddr} ? $self : $self->_c_class_ipaddr;
}
sub _c_class_ipaddr {
	my($self)= @_;
	my($regexp)= $self->e->request->address=~m{^(\d+\.\d+\.\d+\.)};
	$self->data->{c_class_ipaddr}= quotemeta($regexp);
	$self;
}

1;

__END__

=head1 NAME

Egg::Model::Session::Plugin::CclassIP - Plugin for session that confirms C class agreement of IP address.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   Plugin::CclassIP
   .....
   );

=head1 DESCRIPTION

When IP address is not corresponding at C class level, it is a plugin for the 
session to treat as another session.

IP address at that time is preserved when a new session is opened, and C class 
part of the IP address will be confirmed next time.

To use it, 'Plugin::CclassIP' is added to 'startup'.

Moreover, 'init_session' is done in override, and note the competition with other
components, please.

Besides, there is L<Egg::Model::Session::Plugin::AbsoluteIP> confirmed at C class
level, too. However, please note that it is not efficiency with this plugin 
simultaneously that uses.

=head1 METHODS

=head2 init_session

A new session is begun when not agreeing to IP address before at C class level.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Model::Session::Plugin::AbsoluteIP>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

