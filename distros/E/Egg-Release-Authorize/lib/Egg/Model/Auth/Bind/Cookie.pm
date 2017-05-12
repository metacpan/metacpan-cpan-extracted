package Egg::Model::Auth::Bind::Cookie;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Cookie.pm 348 2008-06-14 19:02:44Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{cookie} ||= {};
	$c->{name}    ||= 'as';
	$c->{path}    ||= '/';
	$c->{expires} ||= '+1d';
	$class->next::method($e);
}
sub get_bind_id {
	my $self= shift;
	my $name= shift || $self->config->{cookie}{name};
	$self->e->request->cookie_value($name) || (undef);
}
sub set_bind_id {
	my $self = shift;
	my $value= shift || "";
	my %option= $_[0] ? (ref($_[0]) eq 'HASH' ? %{$_[0]}: @_)
	                  : %{$self->config->{cookie}};
	$self->e->response->cookie(
	  ($option{name} || $self->config->{cookie}{name}) =>
	       { %option, value=> $value }
	  );
}
sub remove_bind_id {
	my $self  = shift;
	my $option= $_[0] ? ($_[1] ? {@_}: $_[0]): $self->config->{cookie};
	$self->set_bind_id("", { %$option, expires=> '-1d' });
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Bind::Cookie - AUTH component that treats session ID.

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    cookie => {
      name    => 'auth_session',
      path    => '/',
      domain  => 'mydomain.name',
      expires => '+1d',
      secure  => 1,
      },
    );
  
  __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

=head1 DESCRIPTION

It relates by Cookie with the client of session ID.

'Bind::Cookie' is included in the list following the session name that adds the
setting of 'cookie' to the configuration to use it and sets it by 'setup_session'
 method.

   __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

It is not significant with the session module that doesn't need Bind system 
component even if it uses it.
Please note the return and becoming an unhappy rate.

The content of 'cookie' set by the configuration is a parameter passed to 'cookie'
 method of L<Egg::Response>.

=head1 METHODS

=head2 get_bind_id ([COOKIE_NAME])

Session ID acquired from Cookie is returned.

=head2 set_bind_id ([SESSION_ID], [COOKIE_ATTR_HASH])

SESSION_ID is set in Cookie.

=head2 remove_bind_id ([COOKIE_ATTR_HASH])

Cookie is invalidated.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Session::FileCache>,
L<Egg::Response>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

