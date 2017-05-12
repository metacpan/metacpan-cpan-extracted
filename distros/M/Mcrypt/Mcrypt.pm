# Filename: Mcrypt.pm
# Author:   Theo Schlossnagle <jesus@omniti.com>
# Created:  17th January 2001
# Version:  2.5.7.0
#
# Copyright (c) 1999,2001,2007 Theo Schlossnagle. All rights reserved.
#   This program is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#

package Mcrypt;

require 5.004;
require Exporter;
require DynaLoader;
require AutoLoader;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

$VERSION = "2.5.7.0" ;

@ISA = qw(Exporter DynaLoader);


%EXPORT_TAGS = (
		ALGORITHMS => [ qw(BLOWFISH
				   DES
				   3DES
				   GOST
				   CAST_128
				   XTEA
				   RC2
				   TWOFISH
				   CAST_256
				   SAFERPLUS
				   LOKI97
				   SERPENT
				   RIJNDAEL_128
				   RIJNDAEL_192
				   RIJNDAEL_256
				   ENIGMA
				   ARCFOUR
				   WAKE) ],
		MODES => [ qw(CBC
			      ECB
			      CFB
			      OFB
			      nOFB
			      STREAM) ],
		FUNCS => [ qw(mcrypt_load
			      mcrypt_unload
			      mcrypt_init
			      mcrypt_end
			      mcrypt_encrypt
			      mcrypt_decrypt
			      mcrypt_get_block_size
			      mcrypt_get_iv_size
			      mcrypt_get_key_size) ],
	       );

@EXPORT = qw( ERROR );

@EXPORT_OK = qw(ERROR

		BLOWFISH
		DES
		3DES
		GOST
		CAST_128
		XTEA
		RC2
		TWOFISH
		CAST_256
		SAFERPLUS
		LOKI97
		SERPENT
		RIJNDAEL_128
		RIJNDAEL_192
		RIJNDAEL_256
		ENIGMA
		ARCFOUR
		WAKE

		CBC
		ECB
		CFB
		OFB
		nOFB
		STREAM

		mcrypt_load
		mcrypt_unload
		mcrypt_init
		mcrypt_end
		mcrypt_encrypt
		mcrypt_decrypt
		mcrypt_get_block_size
		mcrypt_get_iv_size
		mcrypt_get_key_size);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    if($constname eq 'constant') {
        # This will recurse!
	croak "Problem loading Mcrypt libraries";
    }
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined Mcrypt macro $constname";
        }
    }
    eval "sub $AUTOLOAD { \"$val\" }";
    goto &$AUTOLOAD;
}

bootstrap Mcrypt $VERSION ;

sub new {
  my($self, %arg) = @_;
  my $class = ref($self) || $self;
  return undef unless defined($arg{'algorithm'});
  return undef  unless defined($arg{'mode'});
  $arg{'algorithm_dir'} = '' unless defined($arg{'algorithm_dir'});
  $arg{'mode_dir'} = '' unless defined($arg{'mode_dir'});
  my $td = mcrypt_load( $arg{'algorithm'}, $arg{'algorithm_dir'},
			$arg{'mode'}, $arg{'mode_dir'} );
  my $mcrypt = bless { TD => $td }, $class;
  $mcrypt->{Verbose} = 1;
  $mcrypt->{Verbose} = $arg{'verbose'} if(defined($arg{'verbose'}));
  $mcrypt->{KEY_SIZE} = mcrypt_get_key_size($td);
  $mcrypt->{IV_SIZE} = mcrypt_get_iv_size($td);
  $mcrypt->{BLOCK_SIZE} = -1; # default to not be in block mode
  $mcrypt->{BLOCK_SIZE} = mcrypt_get_block_size($td)
    if(mcrypt_is_block_algorithm_mode($td));
  return $mcrypt;
}

sub init {
  my($self, $key, $iv) = @_;
  if($self->{Verbose}) {
    print STDERR "Mcrypt: your initialization vector is the wrong length.\n"
      if($self->{Verbose} &&
	 ($self->{IV_SIZE} > 0) && ($self->{IV_SIZE} != length($iv)));
  }
  return ($self->{Initialized} = mcrypt_init($self->{TD}, $key, $iv));
}

sub end {
  my($self) = shift;
  my $ret = 0;
  $ret = mcrypt_end($self->{TD})
    if($self->{Initialized} && $self->{TD});
  $self->{TD} = 0;
  return $ret;
}

sub encrypt {
  my($self, $input) = @_;
  return undef unless($self->{Initialized});
  if($self->{Verbose}) {
    print STDERR
      "Mcrypt: running block mode and your input is not a valid length.\n"
	if($self->{Verbose} &&
	   ($self->{BLOCK_SIZE} > 0) &&
	   ($self->{BLOCK_SIZE} != length($input)));
  }
  return mcrypt_encrypt($self->{TD}, $input);
}

sub decrypt {
  my($self, $input) = @_;
  return undef unless($self->{Initialized});
  if($self->{Verbose}) {
    print STDERR
      "Mcrypt: running block mode and your input is not a valid length.\n"
	if($self->{Verbose} &&
	   ($self->{BLOCK_SIZE} > 0) &&
	   ($self->{BLOCK_SIZE} != length($input)));
  }
  return mcrypt_decrypt($self->{TD}, $input);
}

sub DESTROY {
  my($self) = shift;
  if($self->{Initialized}) {
    $self->end();
  } else {
    mcrypt_unload($self->{TD});
  }
}

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Mcrypt - Perl extension for the Mcrypt cryptography library

=head1 SYNOPSIS

  use Mcrypt;

  # Procedural routines

  $td = Mcrypt::mcrypt_load($algorithm, $algorithm_dir,
			    $mode, $mode_dir);

  Mcrypt::mcrypt_get_key_size($td);   # in bytes
  Mcrypt::mcrypt_get_iv_size($td);    # in bytes
  Mcrypt::mcrypt_get_block_size($td); # in bytes

  Mcrypt::mcrypt_init($td, $key, $iv);

  $encryptedstr = Mcrypt::mcrypt_encrypt($td, $decryptedstr);
  $decryptedstr = Mcrypt::mcrypt_decrypt($td, $encryptedstr);

  Mcrypt::mcrypt_end($td);

  # Object-oriented methods

  $td = Mcrypt->new( algorithm => $algorithm,
		     mode => $mode );

  $keysize = $td->{KEY_SIZE};
  $ivsize  = $td->{IV_SIZE};
  $blksize = $td->{BLOCK_SIZE};

  $td->init($key, $iv);

  $encryptedstr = $td->encrypt($decryptedstr);
  $decryptedstr = $td->decrypt($encryptedstr);

  # If the $td goes out of context,
  # the destructor will do this for you
  $td->end();

=head1 DESCRIPTION

This module wraps the libmcrypt encryption library for easy and convenient
use from within perl.  Encryption and decryption using a variety of algorithms
is as easy as a few simple lines of perl.

=head1 Exported constants

The predefined groups of exports in the use statements are as follows:

use Mcrypt qw(:ALGORITHMS);

Exports the BLOWFISH DES 3DES GOST 
CAST_128 XTEA RC2 TWOFISH CAST_256 SAFERPLUS LOKI97 SERPENT
RIJNDAEL_128 RIJNDAEL_192 RIJNDAEL_256 ENIGMA ARCFOUR WAKE libmcrypt
algorithms.  See the mcrypt(3) man page for more details.

use Mcrypt qw(:MODES);

Exports the CBC ECB CFB OFB bOFB STREAM modes of encryption.  See the
mcrypt(3) man page for more details.

use Mcrypt qw(:FUNCS);

Exports the following functions: mcrypt_load, mcrypt_unload,
mcrypt_init, mcrypt_end, mcrypt_encrypt, mcrypt_decrypt,
mcrypt_get_block_size, mcrypt_get_iv_size, mcrypt_get_key_size.

=head1 EXAMPLES

  # Procedural approach:
  # create an ecryption descriptor:
  #   ALGORITHM: blowfish (256 bit key + 16 byte IV)
  #   MODE:      cfb
  # The user application has set:
  #   $method to either "encrypt" or "decrypt"
  #   $infile to the input filename
  #   $outfile to the output filename
  my($td) = Mcrypt::mcrypt_load( Mcrypt::BLOWFISH, '',
				 Mcrypt::CFB, '' );
  my($key) = "32 bytes of your apps secret key";  # secret key
  my($iv) = "16 bytes of rand"; # shared initialization vector
  Mcrypt::mcrypt_init($td, $key, $iv) || die "Could not initialize td";
  print Mcrypt::mcrypt_encrypt($td, $_) while(<>);
  Mcrypt::mcrypt_end($td);

  # OO approach of the above except decrypting
  my($td) = Mcrypt->new( algorithm => Mcrypt::BLOWFISH,
                         mode => Mcrypt::CFB,
                         verbose => 0 );
  my($key) = "k" x $td->{KEY_SIZE};
  my($iv) = "i" x $td->{IV_SIZE};
  $td->init($key, $iv);
  print $td->decrypt($_) while (<>);
  $td->end();

=head1 AUTHOR

Theo Schlossnagle <jesus@omniti.com>

=head1 SEE ALSO

The libmcrypt man page: mcrypt(3).  Other libmcrypt information is
available at http://mcrypt.hellug.gr/.

=cut
