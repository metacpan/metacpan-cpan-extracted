package Egg::Model::Auth::Crypt::Func;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Func.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	if (my $salt= $class->config->{crypt_func_md5}) {
		$salt= '$1$'. $salt unless $salt=~m{^\$1\$};
		length($salt)== 11 or die q{As for 'crypt_func_md5',}
		. q{ I want you to set it by 11 characters that start by '$1$'.};
		$class->config->{crypt_func_md5}= $salt;
	}
	$class->next::method($e);
}
sub password_check {
	my $self = shift;
	my $crypt= shift || croak 'I want crypt string.';
	my $password= shift || croak 'I want password.';
	   $crypt=~s{^\s+} []; $crypt=~s{\s+$} [];
	   $password=~s{^\s+} []; $password=~s{\s+$} [];
	crypt($password, $crypt) eq $crypt ? 1: 0;
}
sub create_password {
	my $self    = shift;
	my $password= shift || croak 'I want password.';
	   $password=~s{^\s+} []; $password=~s{\s+$} [];
	my $salt= $self->config->{crypt_func_md5} || do {
		my @tmp= ('A'..'Z', 'a'..'z', '.', '/');
		$tmp[int rand(@tmp)]. $tmp[int rand(@tmp)];
	  };
	crypt($password, $salt);
}

1;

__END__

=head1 NAME

Egg::Model::Auth::Crypt::Func - AUTH component to treat code of attestation data by standard function.

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    crypt_func_md5 => '$1$abcd1234',
    );
  
  __PACKAGE__->setup_api( File => qw/ Crypt::Func / );

=head1 DESCRIPTION

It is API component to treat the password in the attestation data by function 
crypt of the Perl standard.

'Crypt::Func' is included in the list following API component name specified 
for 'setup_api' method.

  __PACKAGE__->setup_api( DBI => qw/ Crypt::Func / );

When the character of 11 digits that starts from '$1$' is set to 'crypt_func_md5'
 of the configuration, the code comes to be treated with MD5.

=head1 METHODS

=head2 password_check ([CRYPT_PASSWORD], [INPUT_PAWWORD])

The agreement of CRYPT_PASSWORD and INPUT_PAWWORD is confirmed.

=head2 create_password ([PLAIN_PASSWORD])

PLAIN_PASSWORD is encrypted.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

