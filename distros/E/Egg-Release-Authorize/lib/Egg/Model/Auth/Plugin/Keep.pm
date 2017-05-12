package Egg::Model::Auth::Plugin::Keep;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Keep.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Crypt::CBC;
use Digest::SHA1 qw/ sha1_hex /;

our $VERSION= '0.06';

my @Items= qw/ __api_name ___user ___input_password /;

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{plugin_keep}
	       || die q{I want setup 'plugin_keep'.};
	$c->{check_sum}  ||= 'd08bdd7994fb7af48c70138d6a77a6b2010c8998';
	length($c->{check_sum}) < 20 and die q{'check_sum' is too short.};
	$c->{delimiter}  ||= ' : ';
	$c->{param_name} ||= '__auto_login';
	my $cookie= $c->{cookie} ||= {};
	$cookie->{name}    ||= 'keep';
	$cookie->{path}    ||= '/';
	$cookie->{expires} ||= '+7d';
	my $cbc= $c->{crypt} || die q{I want setup 'plugin_keep' of 'crypt'.};
	$cbc->{cipher}  || die q{I want setup 'crypt' of 'cipher'.};
	$cbc->{key}     || die q{I want setup 'crypt' of 'key'.};
	$cbc->{iv}      ||= '$KJh#(}q';
	$cbc->{padding} ||= 'standard';
	$cbc->{prepend_iv}    = 0 unless exists($cbc->{prepend_iv});
	$cbc->{regenerate_key}= 1 unless exists($cbc->{regenerate_key});
	$class->next::method($e);
}
sub __keep_cbc {
	$_[0]->{_crypt_keep_cbc}
	   ||= Crypt::CBC->new($_[0]->config->{plugin_keep}{crypt});
}
sub is_login {
	my $self= shift;
	if (my $session= $self->get_session) { return $self->next::method($session) }
	my $c= $self->config->{plugin_keep};
	my $crypt= $self->e->request->cookie_value($c->{cookie}{name}) || return do {
		$self->e->debug_out(__PACKAGE__. ' - Cookie data is empty.');
		$self->next::method(1);
	  };
	my $plain= $self->__keep_cbc->decrypt_hex($crypt) || return do {
		$self->e->debug_out(__PACKAGE__. ' - Data cannot be decrypt.');
		$self->next::method(1);
	  };
	my %data;
	(my $checksum, @data{@Items})= split $c->{delimiter}, $plain;
	($data{__api_name} and $self->api_list->{$data{__api_name}}) || return do {
		$self->e->debug_out(__PACKAGE__. ' - There is no corresponding API.');
		$self->next::method(1);
	  };
	my $api= $self->api($data{__api_name});
	$api->valid_id($data{___user}) || return do {
		$self->e->debug_out(__PACKAGE__. ' - The user name is bad.');
		$self->next::method(1);
	  };
	$api->valid_password($data{___input_password}) || return do {
		$self->e->debug_out(__PACKAGE__. ' - The password is bad.');
		$self->next::method(1);
	  };
	$checksum eq sha1_hex($c->{check_sum}. $data{___input_password}) || return do {
		$self->e->debug_out(__PACKAGE__. ' - The checksum is bad.');
		$self->next::method(1);
	  };
	$data{___start_interval}= time- ($self->config->{interval}+ 60);
	$self->next::method(\%data);
}
sub remove_bind_id {
	my($self)= @_;
	my $name= $self->config->{plugin_keep}{cookie}{name} || 'aa';
	$self->e->request->cookie_more( $name => 'deny' );
	$self->e->response->cookies->{$name}= { value=> "", expires=> '-1d' };
	$self->e->debug_out(__PACKAGE__. ' - Cookie was removed.');
	$self->next::method;
}
sub __setup_data {
	my $self= shift;
	return $self->next::method(@_) if $_[0];
	my $data= $self->next::method(@_);
	my($e, $c)= ($self->e, $self->config->{plugin_keep});
	return $data unless $e->request->params->{$c->{param_name}};
	my $checksum= sha1_hex($c->{check_sum}. $data->{___input_password});
	my $plain = join $c->{delimiter}, ($checksum, @{$data}{@Items});
	my %cookie= %{$c->{cookie}};
	$e->response->cookies->{$cookie{name}}=
	   { %cookie, value=> $self->__keep_cbc->encrypt_hex($plain) };
	$data;
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Plugin::Keep - The attestation is maintained by Cookie. 

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    check_sum => 'abcdefghijklmnopqrstu',
    delimiter  => ' : ',
    param_name => '__auto_login',
    cookie => {
      ...........
      },
    crypt => {
      ...........
      },
    );
  
  __PACKAGE__->setup_plugin(qw/ Keep /);
  
  __PACKAGE__->setup_session('SessionKit');

=head1 DESCRIPTION

The attestation session to which the code that can be decoded to Cookie is set 
and the session cut is revived. As a result, the attestation is maintained to 
perpetuity.

'plugin_keep' is set to the configuration to use it, and 'Keep' is included in
 the list of 'setup_session' method.

  __PACKAGE__->setup_plugin(qw/ Keep /);

It and the session component are needed.

  __PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

When 'login_check' is called, Cookie for the perpetuity attestation is set if 
the input parameter concerning 'The next automatic log in' is effective.

Attestation information is acquired from Cookie if the attestation session doesn't
 exist when 'is_login' is called and the attestation session is revived at the 
 following.

It is necessary to note it very when using it to preserve attestation 
information in Cookie.

=head1 CONDIFGURATION

The following items are set and used in 'plugin_keep'.

=head3 check_sum

Character string of 20-40 suitable digit to generate checksum.

=head3 delimiter

Each attestation data delimiter.
Default is ' : '.

=head3 param_name

Name of the form data for flag to do perpetuity attestation effectively.
Default is '__auto_login'.

=head3 cookie

The content is a parameter to pass it to 'cookie' method of L<Egg::Response>.

  name    ..... Name of Cookie. Default is 'aa'.
  expires ..... Validity term of Cookie for perpetuity attestation. Default is '+7D'.

=head3 crypt

The content is an option to pass to L<Crypt::CBC>.

=head1 METHODS

=head2 is_login

If the attestation session exists and doesn't exist, attestation information is
 acquired from Cookie, and the attestation session is revived.

And, processing is passed to 'is_login' of L<Egg::Model::Auth::Base>.

=head2 remove_bind_id

=head2 reset

Cookie for the perpetuity attestation is annulled. 
And, processing is passed to 'reset' of L<Egg::Model::Auth::Base>.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base>,
L<Egg::Response>,
L<Crypt::CBC>,
L<Digest::SHA1>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

