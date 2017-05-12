package Egg::Plugin::Crypt::CBC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CBC.pm 318 2008-04-17 12:17:01Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.01';

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_crypt_cbc} ||= {};

	$conf->{cipher}  || die q{ Please setup 'plugin_crypt_cbc->{cipher}'. };
	$conf->{key}     || die q{ Please setup 'plugin_crypt_cbc->{key}'. };
	$conf->{iv}      ||= '$KJh#(}q';
	$conf->{padding} ||= 'standard';
	$conf->{prepend_iv}= 0 unless exists($conf->{prepend_iv});
	$conf->{regenerate_key}= 1 unless exists($conf->{regenerate_key});

	$e->next::method;
}
sub cbc {
	my $e= shift;
	@_ ? ($e->{crypt_cbc}= Egg::Plugin::Crypt::CBC::handler->new($e, @_))
	   : ($e->{crypt_cbc} ||= Egg::Plugin::Crypt::CBC::handler->new($e))
}

package Egg::Plugin::Crypt::CBC::handler;
use strict;
use warnings;
use MIME::Base64;
use base qw/Crypt::CBC/;

sub new {
	my($class, $e)= splice @_, 0, 2;
	my %option= (
	  %{$e->config->{plugin_crypt_cbc}},
	  %{ $_[1] ? {@_}: ($_[0] || {}) },
	  );
	$class->SUPER::new(\%option);
}
sub encode {
	my $self = shift;
	my $plain= shift || return "";
	my $crypt= encode_base64( $self->encrypt($plain) );
	$crypt=~tr/\r\n\t//d;
	$crypt || "";
}
sub decode {
	my $self = shift;
	my $crypt= shift || return "";
	$self->decrypt( decode_base64($crypt) ) || "";
}

1;

__END__

=head1 NAME

Egg::Plugin::Crypt::CBC - Crypt::CBC for Egg Plugin.

=head1 SYNOPSIS

  use Egg qw/ Crypt::CBC /;
  
  __PACKAGE__->egg_startup(
   .....
   ...
  
   plugin_crypt_cbc => {
     cipher=> 'Blowfish',
     key   => 'uniqueid',
     ...
     },
  
   );

  # The text is encrypted.
  my $crypt= $e->cbc->encode($text);
  
  # The code end text is decrypted.
  my $plain= $e->cbc->decode($crypt);
  
  # The cbc object is acquired in an arbitrary option.
  my $cbc= $e->cbc( cipher => 'DES' );

=head1 DESCRIPTION

It is a plugin to use the code and decoding by L<Crypt::CBC>.

=head1 CONFIGURATION

HASH is defined in 'plugin_crypt_cbc' key and it sets it.

The setting is an option to pass everything to L<Crypt::CBC>.

Please refer to the document of L<Crypt::CBC> for details.

=head2 cipher

The exception is generated in case of undefined.

=head2 key

The exception is generated in case of undefined.

=head2 iv

'$KJh#(}q' is provisionally defined in case of undefined.

Please define it.

=head2 padding

Default is 'standard'.

=head2 prepend_iv

Default is 0.

=head2 regenerate_key

Default is 1.

=head1 METHODS

=head2 cbc ( [OPTION_HASH] )

The handler object of this plugin is returned.

It turns by using the same object when the object is generated once usually.
When OPTION_HASH is given, it tries to generate the object newly.

=head1 HANDLER METHODS

The handler object has succeeded to L<Crypt::CBC>.

=head1 new

Constructor.

=head1 encode ( [PLAIN_TEXT] )

After PLAIN_TEXT is encrypted, the Base64 encode text is returned.

  my $crypt_text= $e->cbc->encode( 'plain text' );

=head1 decode ( [CRYPT_TEXT] )

The text encrypted by 'encode' method is made to the compound and returned.

  my $plain_text= $e->cbc->decode( 'crypt text' );

=head1 SEE ALSO

L<Egg::Release>,
L<Crypt::CBC>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

