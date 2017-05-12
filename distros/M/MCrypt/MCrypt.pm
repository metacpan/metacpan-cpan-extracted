package MCrypt;

# require 5.005_62;
use strict;
# use warnings;
use Carp ;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MCrypt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
Types => [qw(
		    MCRYPT_BLOWFISH_448 MCRYPT_DES MCRYPT_3DES MCRYPT_3WAY
		    MCRYPT_GOST MCRYPT_SAFER_64 MCRYPT_SAFER_128 MCRYPT_CAST_128 
		    MCRYPT_XTEA MCRYPT_RC2_1024 MCRYPT_TWOFISH_128 MCRYPT_TWOFISH_192
		    MCRYPT_TWOFISH_256 MCRYPT_BLOWFISH_128 MCRYPT_BLOWFISH_192
		    MCRYPT_BLOWFISH_256 MCRYPT_CAST_256 MCRYPT_SAFERPLUS 
		    MCRYPT_LOKI97 MCRYPT_SERPENT_128 MCRYPT_SERPENT_192 
		    MCRYPT_SERPENT_256 
		    MCRYPT_RIJNDAEL_128 MCRYPT_RIJNDAEL_192 MCRYPT_RIJNDAEL_256
		    MCRYPT_RC2_256 MCRYPT_RC2_128 MCRYPT_CRYPT
		    MCRYPT_RC6_256 MCRYPT_IDEA MCRYPT_RC6_128 MCRYPT_RC6_192
		    MCRYPT_ARCFOUR MCRYPT_RC_4  
		    )],

Modes => [qw( MCRYPT_ENCRYPT MCRYPT_DECRYPT 
		     )],
Functions => [qw( 
		  mcrypt_cbc mcrypt_ecb mcrypt_ofb mcrypt_cfb
		  mcrypt_cbc_hex mcrypt_ecb_hex mcrypt_ofb_hex 
		  mcrypt_cfb_hex mcrypt_get_block_size
		  mcrypt_get_key_size mcrypt_get_cipher_name
		  )],		     
		     );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# use :DEFAULT to get everything in @EXPORT plus extras from @EXPORT_OK
# our @EXPORT_OK = qw( );
Exporter::export_ok_tags(qw(Types Functions Modes)) ;
Exporter::export_tags( qw(Functions) ) ;
# our @EXPORT = qw(
# );
our $VERSION = '0.92';

# package MCrypt::Constants;
# use strict;
# encryption mode constants
use constant MCRYPT_ENCRYPT    => 1;
use constant MCRYPT_DECRYPT    => 0;
# cipher mode constants
use constant MCRYPT_BLOWFISH_448 => 0 ;
use constant MCRYPT_DES          => 1 ;
use constant MCRYPT_3DES         => 2 ;
use constant MCRYPT_3WAY         => 3 ;
use constant MCRYPT_GOST         => 4 ;
use constant MCRYPT_SAFER_64     => 6 ;
use constant MCRYPT_SAFER_128    => 7 ;
use constant MCRYPT_CAST_128     => 8 ;
use constant MCRYPT_XTEA         => 9 ;
use constant MCRYPT_RC2_1024     => 11;
use constant MCRYPT_TWOFISH_128  => 10;
use constant MCRYPT_TWOFISH_192  => 12;
use constant MCRYPT_TWOFISH_256  => 13;
use constant MCRYPT_BLOWFISH_128 => 14;
use constant MCRYPT_BLOWFISH_192 => 15;
use constant MCRYPT_BLOWFISH_256 => 16;
use constant MCRYPT_CAST_256     => 17;
use constant MCRYPT_SAFERPLUS    => 18;
use constant MCRYPT_LOKI97       => 19;
use constant MCRYPT_SERPENT_128  => 20;
use constant MCRYPT_SERPENT_192  => 21;
use constant MCRYPT_SERPENT_256  => 22;
use constant MCRYPT_RIJNDAEL_128 => 23;
use constant MCRYPT_RIJNDAEL_192 => 24;
use constant MCRYPT_RIJNDAEL_256 => 25;
use constant MCRYPT_RC2_256      => 26;
use constant MCRYPT_RC2_128      => 27;
use constant MCRYPT_CRYPT        => 28;
use constant MCRYPT_RC6_256      => 100;
use constant MCRYPT_IDEA         => 101;
use constant MCRYPT_RC6_128      => 102;
use constant MCRYPT_RC6_192      => 103;
# define MCRYPT_RC4 MCRYPT_ARCFOUR
use constant MCRYPT_ARCFOUR      => 104;
use constant MCRYPT_RC_4         => 104;

# -- stop

bootstrap MCrypt $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
# start code here

sub usage
{
    my ($mess, $package, $filename, $line, $subr);
    ($mess) = @_;
    ($package, $filename, $line, $subr) = caller(1);
    $Carp::CarpLevel = 1;
    croak "Usage: $package\::$subr - $mess";
}
sub mcrypt_cbc_hex($$$$;$)
{
    my ($cipher, $key, $data, $mode, $IV) = @_ ;
    $IV = "" if !$IV ;
    
    if($mode == MCRYPT_ENCRYPT)
    {   # ENCRYPT MODE
	return join('', unpack 'H*', mcrypt_cbc($cipher,$key,$data,$mode,$IV) ) ;
    } else {  # DECRYPT MODE
	return mcrypt_cbc($cipher, $key, pack('H*', $data), $mode, $IV) ;
    }
}
sub mcrypt_ecb_hex($$$$)
{
    my ($cipher,$key, $data, $mode) = @_ ;
    if($mode)  
    {   # ENCRYPT MODE
	return join('', unpack 'H*', mcrypt_ecb($cipher,$key,$data,$mode) ) ;
    } else {  # DECRYPT MODE
	return mcrypt_ecb($cipher, $key, pack('H*', $data), $mode) ;
    }
}
sub mcrypt_ofb_hex($$$$$)
{
    my ($cipher,$key, $data, $mode, $IV) = @_ ;
    if($mode)  
    {   # ENCRYPT MODE
	return join('', unpack 'H*', mcrypt_ofb($cipher,$key,$data,$mode,$IV) ) ;
    } else {  # DECRYPT MODE
	return mcrypt_ofb($cipher, $key, pack('H*', $data), $mode, $IV) ;
    }
}
sub mcrypt_cfb_hex($$$$$)
{
    my ($cipher,$key, $data, $mode, $IV) = @_ ;
    if($mode)  
    {   # ENCRYPT MODE
	return join('', unpack 'H*', mcrypt_cfb($cipher,$key,$data,$mode,$IV) ) ;
    } else {  # DECRYPT MODE
	return mcrypt_cfb($cipher, $key, pack('H*', $data), $mode, $IV) ;
    }
}

sub mcrypt_cbc($$$$;$)
{
    my ($cipher, $key, $data, $mode, $IV) = @_ ;
    my $ivlen     = 0 ;
    my $blocksize = 0 ;
    $IV = "" if !$IV ;
    if( $ivlen = length($IV) )
    {
	$blocksize = mcrypt_get_block_size($cipher) ;
	if( $ivlen != $blocksize )
	{
	    usage("The blocksize for the specified cipher is $blocksize bytes, the IV length must match the blocksize.\n") ;
	}
        return _mcrypt_cbc($cipher,$key,$data,$mode,$IV) ;
    }
    return _mcrypt_cbc($cipher,$key,$data,$mode) ;
}
sub mcrypt_ecb($$$$)
{
    my ($cipher, $key, $data, $mode) = @_ ;
    return _mcrypt_ecb($cipher,$key,$data,$mode) ;
}
sub mcrypt_ofb($$$$$)
{
    my ($cipher, $key, $data, $mode, $IV) = @_ ;
    my ($ivlen, $blocksize) ;
    
    $blocksize = mcrypt_get_block_size($cipher) ;    
    if ($blocksize != length($IV))
    {
	usage("The blocksize for the specified cipher is $blocksize bytes, the IV length must match the blocksize.\n") ;
    }
    return _mcrypt_ofb($cipher,$key,$data,$mode,$IV) ;
}
sub mcrypt_cfb($$$$$)
{
    my ($cipher, $key, $data, $mode, $IV) = @_ ;
    my ($ivlen, $blocksize) ;
    
    $blocksize = mcrypt_get_block_size($cipher) ;
    if ($blocksize != length($IV))
    {
	usage("The blocksize for the specified cipher is $blocksize bytes, the IV length must match the blocksize.\n") ;
    }
    return _mcrypt_cfb($cipher,$key,$data,$mode,$IV) ;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

MCrypt - Perl extension for MCrypt Crypto library

=head1 DISCLAIMER

=head2 THIS IS A FIRST RELEASE BETA VERSION.

    Yes, it does work.

If you have use for this, please try and use it and report any bugs you find.  Feedback from users of this module is important.

=head1 SYNOPSIS

  use MCrypt qw(:Functions :Modes :Types) ;
  my $key = "my secret key";
  my $data "this is my secret data";
  # optional IV that matches the blocksize of the cipher!
  my $iv = "12345678" ; # 8 bytes for MCRYPT_3DES
  $ciphertext = mcrypt_cbc( MCRYPT_3DES, $key, $data, MCRYPT_ENCRYPT, $iv ) ;

  **NOTE** Please read the section on EXPORT TAGS below for information on the MCRYPT_ constants and the how to conserve your namespace.

=head1 DEPENDENCIES

This interface is dependent on the 2.2.x tree of the MCRYPT library.  Please download and install the latest libmcrypt-2.2.x.tar.gz at ftp://argeas.cs-net.gr/pub/unix/mcrypt.  As of this writing, the latest is libmcrypt-2.2.7.tar.gz.  Additional information about the mcrypt library can be found at http://mcrypt.hellug.gr.

Libmcrypt MUST be found in your library path when using this module.  In Linux, libmcrypt is defaultly installed in /usr/local/lib -- in this case, be sure that the /usr/local/lib path is in your /etc/ld.so.conf.


=head1 DESCRIPTION

This is an perl interface to the MCrypt crypto library, which supports a wide variety of block algorithms such as DES, TripleDES, Blowfish (default), 3-WAY, SAFER-SK64, SAFER-SK128, TWOFISH, TEA, RC2, GOST, LOKI, SERPENT, CAST and RIJNDAEL in CBC, OFB, CFB and ECB cipher modes.

Mcrypt can be used to encrypt and decrypt using the above mentioned ciphers. The four important mcrypt
commands (mcrypt_cfb(), mcrypt_cbc(), mcrypt_ecb(), and mcrypt_ofb()) can operate in both modes which are named MCRYPT_ENCRYPT and MCRYPT_DECRYPT, respectively. 

Mcrypt can operate in four block cipher modes (CBC, OFB, CFB, and ECB).  We will outline the normal use for each of these modes. For a more complete reference and discussion see Applied Cryptography by Schneier (ISBN 0-471-11709-9). 

      ECB (electronic codebook) is suitable for random data, such as encrypting other keys. Since data there is short and random, the disadvantages of ECB have a favorable negative effect. 

      CBC (cipher block chaining) is especially suitable for encrypting files where the security is increased over ECB significantly. 

      CFB (cipher feedback) is the best mode for encrypting byte streams where single bytes must be encrypted. 

      OFB (output feedback, in 8bit) is comparable to CFB, but can be used in applications where error propagation cannot be tolerated. It's insecure (because it operates in 8bit mode) so it is not recommended to use it. 

MCrypt does not support encrypting/decrypting bit streams currently. As of now, MCrypt only supports handling of strings. 


Here is the list of cipher constants which are currently supported by the MCrypt module:

      MCRYPT_DES 

      MCRYPT_3DES 

      MCRYPT_3WAY

      MCRYPT_GOST

      MCRYPT_SAFER64 

      MCRYPT_SAFER128 

      MCRYPT_CAST_128 

      MCRYPT_CAST_256 

      MCRYPT_XTEA

      MCRYPT_RC2_128

      MCRYPT_RC2_192

      MCRYPT_RC2_1024

      MCRYPT_TWOFISH128

      MCRYPT_TWOFISH192 

      MCRYPT_TWOFISH256 

      MCRYPT_BLOWFISH_128

      MCRYPT_BLOWFISH_192

      MCRYPT_BLOWFISH_256

      MCRYPT_BLOWFISH_448 (the default if a blank cipher is supplied)

      MCRYPT_CAST_256

      MCRYPT_SAFERPLUS

      MCRYPT_LOKI97

      MCRYPT_SERPENT_128

      MCRYPT_SERPENT_192

      MCRYPT_SERPENT_256

      MCRYPT_RIJNDAEL_128

      MCRYPT_RIJNDAEL_192

      MCRYPT_RIJNDAEL_256

      MCRYPT_CRYPT

      MCRYPT_RC6_128

      MCRYPT_RC6_192

      MCRYPT_RC6_256

      MCRYPT_IDEA (non-free)

      MCRYPT_ARCFOUR (also aliased as MCRYPT_RC_4) 

You must (in CFB and OFB mode) or can (in CBC mode) supply an initialization vector (IV) to the respective cipher function. The IV must be unique and must be the same when decrypting/encrypting. With data which is stored encrypted, you can take the output of a function of the index under which the data is stored (e.g. the MD5 key of the filename). Alternatively, you can transmit the IV together with the encrypted data (see chapter 9.3 of Applied Cryptography by Schneier (ISBN 0-471-11709-9) for a discussion of this topic). 

=head1 EXPORT TAGS
 
  A more conservative usage of the above SYNOPSIS:

  # no export tags supplied in the below line; import :Functions by default
  use MCrypt ;
  my $key = "my secret key";
  my $data "this is my secret data";
  # optional IV that matches the blocksize of the cipher!
  my $iv = "12345678" ; # 8 bytes for MCRYPT_3DES
  $ciphertext = mcrypt_cbc( MCrypt::MCRYPT_3DES, $key, $data, MCrypt::MCRYPT_ENCRYPT, $iv ) ;
  


Functions
  This tag exports all the functions related to MCrypt.  This tag should always be imported unless you are going to be calling MCrypt functions with the full package name.  This tag is automatically imported if no export tags are supplied as in the above example.
(i.e. MCrypt::mcrypt_cbc()).

Modes
  This tag exports the encryption mode constants MCRYPT_ENCRYPT and MCRYPT_DECRYPT.  It is recommended that you import this tag as it only imports two constants into your namespace.  If you are being conservative with your namespace, you can leave this out providing you call these constant with the package name. 
(i.e. MCrypt::MCRYPT_ENCRYPT )

Types   
  This tag exports the cipher constants defined by the list of ciphers above in DESCRIPTION.  It is recommended you import this tag for ease of use.  If you are concerned with polluting your namespace, do not import this tag, and use the form MCrypt::MCRYPT_CIPHERNAME when supplying the cipher to the MCrypt functions. 
(i.e. MCrypt::MCRYPT_3DES )

=head1 PROGRAMMING FUNCTIONS AND METHODS

The following methods are available:

mcrypt_cbc()
   
 Mcrypt_cbc() encrypts or decrypts (depending on mode) the data with cipher and key in CBC cipher mode and returns the resulting string. 

   $ciphertext = mcrypt_cbc($cipher, $key, $data, $mode, [$IV]) ;

Cipher is one of the MCRYPT_ciphername constants. 

Key is the key supplied to the algorithm. It must be kept secret. 

Data is the data which shall be encrypted/decrypted. 

Mode is MCRYPT_ENCRYPT or MCRYPT_DECRYPT. 

IV is the optional initialization vector.   (This must be the blocksize of the cipher!)


mcrypt_ecb()

 Mcrypt_ecb() encrypts or decrypts (depending on mode) the data with cipher and key in ECB cipher mode and returns the resulting string. 

   $ciphertext = mcrypt_ecb($cipher, $key, $data, $mode) ;

Cipher is one of the MCRYPT_ciphername constants. 

Key is the key supplied to the algorithm. It must be kept secret. 

Data is the data which shall be encrypted/decrypted. 

Mode is MCRYPT_ENCRYPT or MCRYPT_DECRYPT. 


mcrypt_ofb()

 Mcrypt_ofb() encrypts or decrypts (depending on mode) the data with cipher and key in OFB cipher mode and returns the resulting string. 

   $ciphertext = mcrypt_ofb($cipher, $key, $data, $mode, $IV) ;

Cipher is one of the MCRYPT_ciphername constants. 

Key is the key supplied to the algorithm. It must be kept secret. 

Data is the data which shall be encrypted/decrypted. 

Mode is MCRYPT_ENCRYPT or MCRYPT_DECRYPT. 

IV is the initialization vector.  (This must be the blocksize of the cipher!)


mcrypt_cfb()

 Mcrypt_cfb() encrypts or decrypts (depending on mode) the data with cipher and key in CFB cipher mode and returns the resulting string. 

   $ciphertext = mcrypt_cfb($cipher, $key, $data, $mode, $IV) ;

Cipher is one of the MCRYPT_ciphername constants. 

Key is the key supplied to the algorithm. It must be kept secret. 

Data is the data which shall be encrypted/decrypted. 

Mode is MCRYPT_ENCRYPT or MCRYPT_DECRYPT. 

IV is the initialization vector.  (This must be the blocksize of the cipher!)


mcrypt_get_cipher_name()

 Mcrypt_get_cipher_name() is used to get the name of the specified cipher.  This function takes the cipher number as an argument and returns the name of the cipher as a string or false, if the cipher does not exist.

   $ciphername = mcrypt_get_cipher_name( MCRYPT_3DES ) ;

Cipher is one of the MCRYPT_ciphername constants. 

mcrypt_get_key_size()

 Mcrypt_get_key_size() is used to get the size of a key of the specified cipher.  This function takes one argument, the cipher and returns the size in bytes.  This function is useful to find the keysize for a specific cipher.  The key you use SHOULD match the keysize.

   $keysize = mcrypt_get_key_size( MCRYPT_3DES ) ;

Cipher is one of the MCRYPT_ciphername constants. 
 
mcrypt_get_block_size()

 Mcrypt_get_block_size() is used to get the size of a block of the specified cipher.  This function takes one argument, the cipher and returns the size in bytes.   This function is useful for determining the correct size of the IV of a cipher.

   $keysize = mcrypt_get_block_size( MCRYPT_3DES ) ;

Cipher is one of the MCRYPT_ciphername constants.


=head1 TODO

 - More bug testing.
 - implement mcrypt_create_iv() in a nice way
 - detection of libmcrypt installation

=head1 AUTHOR

Kuo, Frey, kero@3SHEEP.COM.

=head2 CREDITS

Mavroyanopoulos, Nikos, <nmav@hellug.gr> - for the libmcrypt library.

Schumann, Sasha, <sascha@schumann.2ns.de> - for PHP's implementation of the libmcrypt interface.

=head1 SEE ALSO

mcrypt(3).

=cut
