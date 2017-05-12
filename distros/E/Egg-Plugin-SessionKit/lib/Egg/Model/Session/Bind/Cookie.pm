package Egg::Model::Session::Bind::Cookie;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Cookie.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{cookie} ||= {};
	$c->{path}    ||= '/';
	$c->{expires} ||= '+1d';
	$class->next::method($e);
}

sub get_bind_data {
	my $self= shift;
	$self->e->request->cookie_value
	   ($self->config->{cookie}{name} || shift) || (undef);
}
sub set_bind_data {
	my($self, $key, $id)= @_;
	my %cookie= %{$self->config->{cookie}};
	my $name  = $cookie{name} || $key;
	$self->e->response->cookie( $name => { %cookie, value=> $id } );
}

1;

__END__

=head1 NAME

Egg::Model::Session::Bind::Cookie - The client and the session are related by using Cookie.

=head1 SYNOPSIS

  package MyApp::Model::Session::MySession;
  ............
  .....
  
  __PACKAGE__->config(
   cookie    => {
     ........
     ...
     },
   );
  
  __PACKAGE__->startup qw/
     Bind::Cookie
     ........
     ...
     /;

=head1 DESCRIPTION

It is a component module to relate the client and the session by using Cookie.

It uses it specifying 'Bind::Cookie' for 'startup'.

This component can be used by the default of the module generated
with L<Egg::Helper::Model::Session>.

=head1 CONFIGURATION

It sets it to config of the session component module with 'cookie' key.

  __PACKAGE__->config(
   cookie => {
     name    => 'ss',
     path    => '/',
     domain  => 'mydomain.name',
     expires => '+M',
     secure  => 1,
    },
   );

As for a set item, all cookie method of L<Egg::Response> is passed.

=head1 METHODS

=head2 get_bind_data

Session ID is received and returned from Cookie of the client.

Config-E<gt>{paran_name} or cookie-E<gt>{cookie}{name} is used for the key to
the cookie.

This method is called from 'accept_session_id' of L<Egg::Model::Session::Manager::TieHash>.

=head2 set_bind_data

It is prepared to send the client Cookie.

This method is called from 'Close' method of L<Egg::Model::Session::Manager::TieHash>
 or 'output_session_id' method.

=head2 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Response>,

=head2 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head2 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

