package Egg::Model::Auth::Crypt::SHA1;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SHA1.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Digest::SHA1 qw/ sha1_hex /;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	$class->config->{crypt_sha1_salt} ||= "";
	$class->next::method($e);
}
sub password_check {
	my $self = shift;
	my $crypt= shift || croak 'I want crypt string.';
	   $crypt=~s{^\s+} []; $crypt=~s{\s+$} [];
	$crypt eq $self->create_password(@_) ? 1: 0;
}
sub create_password {
	my $self    = shift;
	my $password= shift || croak 'I want password.';
	   $password=~s{^\s+} []; $password=~s{\s+$} [];
	sha1_hex($password. $self->config->{crypt_sha1_salt});
}
sub valid_crypt {
	($_[1] and $_[1]=~m{^[a-f0-9]{40}$}) ? 1: 0;
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Crypt::SHA1 - AUTH component to treat code of attestation data with Digest::SHA1.

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    crypt_sha1_salt => 'abcd1234',
    );
  
  __PACKAGE__->setup_api( File => qw/ Crypt::SHA1 / );

=head1 DESCRIPTION

It is API component to treat the password in the attestation data with L<Digest::SHA1>.

'Crypt::SHA1' is included in the list following API component name specified for
 'setup_api' method. 

  __PACKAGE__->setup_api( DBI => qw/ Crypt::SHA1 / );

When 'crypt_sha1_salt' of the configuration is set, the character string that 
connects the content behind former password comes to be used to generate checksum.

=head1 METHODS

=head2 password_check ([CRYPT_PASSWORD], [INPUT_PAWWORD])

The agreement of CRYPT_PASSWORD and INPUT_PAWWORD is confirmed.

=head2 create_password ([PLAIN_PASSWORD])

PLAIN_PASSWORD is encrypted.

=head2 valid_crypt ([CRYPT_PASSWORD])

CRYPT_PASSWORD is HEX value of 32 digits or it confirms it.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,
L<Digest::SHA1>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

