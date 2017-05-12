package Egg::Model::Auth::Crypt::CBC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CBC.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Crypt::CBC;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	$class->config->{crypt_cbc_salt} ||= "";
	my $c= $class->config->{crypt_cbc} ||= {};
	$c->{cipher} || die __PACKAGE__. q{ - I want setup 'crypt_cbc->{cipher}'.};
	$c->{key}    || die __PACKAGE__. q{ - I want setup 'crypt_cbc->{key}'.};
	$c->{iv}      ||= '$KJh#(}q';
	$c->{padding} ||= 'standard';
	$c->{prepend_iv}    = 0 unless exists($c->{prepend_iv});
	$c->{regenerate_key}= 1 unless exists($c->{regenerate_key});
	$class->next::method($e);
}
sub __cbc {
	${$_[0]}->{_crypt_cbc} ||= Crypt::CBC->new($_[0]->config->{crypt_cbc});
}
sub password_check {
	my $self = shift;
	my $crypt= shift || croak 'I want crypt string.';
	   $crypt=~s{^\s+} []; $crypt=~s{\s+$} [];
	my $password= shift || croak 'I want target password.';
	   $password=~s{^\s+} []; $password=~s{\s+$} [];
	$password eq $self->__cbc->decrypt_hex($crypt) ? 1: 0;
}
sub create_password {
	my $self    = shift;
	my $password= shift || croak 'I want target password.';
	   $password=~s{^\s+} []; $password=~s{\s+$} [];
	$self->__cbc->encrypt_hex($password. $self->config->{crypt_cbc_salt});
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Crypt::CBC - AUTH component to treat code of attestation data with Crypt::CBC. 

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    crypt_cbc => {
      cipher => 'Blowfish',
      key    => 'AbCd1234',
      .......
      ...
      },
    );
  
  __PACKAGE__->setup_api( File => qw/ Crypt::CBC / );

=head1 DESCRIPTION

It is API component to treat the password in the attestation data with L<Crypt::CBC>.

'Crypt::CBC' is included in the list following API component name that adds the
 setting of 'crypt_cbc' to the configuration to use it and specifies it for 
 'setup_api' method.

  __PACKAGE__->setup_api( File => qw/ Crypt::CBC / );

And, please set 'cipher' and 'key' used when the password in the attestation 
data is encrypted in 'crypt_cbc'.

Additionally, all set content extends to Crypt::CBC.

=head1 METHODS

=head2 password_check ([CRYPT_PASSWORD], [INPUT_PAWWORD])

CRYPT_PASSWORD is decoded and whether it agrees is confirmed with INPUT_PAWWORD.

=head2 create_password ([PLAIN_PASSWORD])

PLAIN_PASSWORD is encrypted.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,
L<Crypt::CBC>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

