package MicroECC;

use 5.016001;
use strict;
use warnings;

use constant {
	secp160r1 => 0,
	secp192r1 => 1,
	secp224r1 => 2,
	secp256r1 => 3,
	secp256k1 => 4,
};

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MicroECC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  secp160r1 secp192r1 secp224r1 secp256r1 secp256k1
  make_key valid_public_key shared_secret curve_public_key_size curve_private_key_size
  compute_public_key verify sign
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('MicroECC', $VERSION);



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MicroECC - Perl wrapper for the micro-ecc ECDH and ECDSA library

=head1 SYNOPSIS

  use MicroECC;
  use Digest::SHA qw/sha1 sha256/;

  #curves: secp160r1 secp192r1 secp224r1 secp256r1 secp256k1
  my $curve = MicroECC::secp160r1();
  printf "Public key size: %d, private key size: %d.\n", 
	  MicroECC::curve_public_key_size($curve), MicroECC::curve_private_key_size($curve);

  my ($pubkey, $privkey) = MicroECC::make_key($curve);
  if(!MicroECC::valid_public_key($pubkey, $curve)){
	  print "Invalid public key.\n";
  }
  else {
	  print "Valid public key.\n";
  }

  # make shared secret with other people's public key.
  my $shared_secret = MicroECC::shared_secret($your_pubkey, $privkey);

  my $compute_pubkey = MicroECC::compute_public_key($privkey, $curve);
  if($compute_pubkey ne $pubkey) {
	  print "Invalid compute pubkey.\n";
  }
  else {
	  print "Public key compute success.\n";
  }

  my $message = "Coming soon: 14 Asia hotels we can't wait to check into in 2019";
  my $message_hash = sha256($message);
  my $signature = MicroECC::sign($privkey, $message_hash, $curve);
  printf "Signature: %s\n", unpack('H*', $signature);
  if(!MicroECC::verify($pubkey, $message_hash, $signature, $curve)) {
	  print "Verify failed.\n";
  }
  else {
	  print "Verify success.\n";
  }

=head1 DESCRIPTION

This is the perl wrapper for the micro-ecc library (https://github.com/kmackay/micro-ecc)
ECDH and ECDSA for 8-bit, 32-bit, and 64-bit processors. 


=head1 EXPORT

None by default.


=head1 AUTHOR

Jeff Zhang, <10395708@qq.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeff Zhang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
