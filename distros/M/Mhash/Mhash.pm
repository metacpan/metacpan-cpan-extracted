package Mhash;

# require 5.005_62;
 use strict;
 use warnings;
use Carp ;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mhash ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
Types => [qw(
	     MHASH_CRC32 MHASH_MD5 MHASH_SHA1 MHASH_HAVAL256 MHASH_RIPEMD160
	     MHASH_TIGER MHASH_GOST MHASH_CRC32B MHASH_HAVAL224 MHASH_HAVAL192
	     MHASH_HAVAL160
		    )],

Functions => [qw( mhash mhash_hex mhash_hmac mhash_hmac_hex 
mhash_get_block_size mhash_count  mhash_get_hash_name
		  )],		     
		     );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# use :DEFAULT to get everything in @EXPORT plus extras from @EXPORT_OK
# our @EXPORT_OK = qw( );
Exporter::export_ok_tags(qw(Types Functions )) ;
Exporter::export_tags( qw(Functions) ) ;

# our @EXPORT = qw(
# );
our $VERSION = '0.90';

bootstrap Mhash $VERSION;

# hash type constants
use constant MHASH_CRC32     => 0 ;
use constant MHASH_MD5       => 1 ;
use constant MHASH_SHA1      => 2 ;
use constant MHASH_HAVAL256  => 3 ;
use constant MHASH_RIPEMD160 => 5 ;
use constant MHASH_TIGER     => 7 ;
use constant MHASH_GOST      => 8 ;
use constant MHASH_CRC32B    => 9 ;
use constant MHASH_HAVAL224  => 10 ;
use constant MHASH_HAVAL192  => 11 ;
use constant MHASH_HAVAL160  => 12 ;

sub usage
{
    my ($mess, $package, $filename, $line, $subr);
    ($mess) = @_;
    ($package, $filename, $line, $subr) = caller(1);
    $Carp::CarpLevel = 1;
    croak "Usage: $package\::$subr - $mess";
}

sub mhash($$)
{
    my ($hash, $data) = @_ ;
    if($hash < 0)
    {
	usage("Invalid hash type.");
    }
    if(!$data)
    {
	usage("Please supply a non-null value for the hashed data.") ;
    }
    return _mhash($hash,$data);
}
sub mhash_hex($$)
{
    my ($hash, $data) = @_ ;
    if($hash < 0)
    {
	usage("Invalid hash type.");
    }
    if(!$data)
    {
	usage("Please supply a non-null value for the hashed data.") ;
    }
    return _mhash($hash,$data, 1);
}

sub mhash_hmac($$$)
{
    my ($hash, $data, $key) = @_ ;
    if($hash < 0)
    {
	usage("Invalid hash type.") ;
    }
    if(!$data || !$key)
    {
	usage("Please supply a non-null value for the hashed data and key.") ;
    }
    return _mhash_hmac($hash,$data,$key);
}

sub mhash_hmac_hex($$$)
{
    my ($hash, $data, $key) = @_ ;
    if($hash < 0)
    {
	usage("Invalid hash type.") ;
    }
    if(!$data || !$key)
    {
	usage("Please supply a non-null value for the hashed data and key.") ;
    }
    return _mhash_hmac($hash,$data,$key, 1);
}

sub mhash_count()
{
    return pmhash_count() ;
}

sub mhash_get_block_size($)
{
    my $hash = shift ;
    if($hash < 0)
    {
	usage("Invalid hash type.");
    }
    return pmhash_get_block_size($hash);
}

sub mhash_get_hash_name($)
{
    my $hash = shift ;
    if($hash < 0)
    {
	usage("Invalid hash type.");
    }
    return pmhash_get_hash_name($hash);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Mhash - Perl extension for Mhash Hash library

=head1 DISCLAIMER

If you have use for this, please try and use it and report any bugs you find.  Feedback and comments from users of this module is important for further development.

=head1 SYNOPSIS

=head2 A STANDARD HASHING EXAMPLE 

  use Mhash qw( mhash_hex ) ;
  my $data  = "this is my secret data";
  $hash_hex = mhash_hex(Mhash::MHASH_MD5, $data) ;

=head2 AN EXAMPLE PROGRAM USING HMAC

    use Mhash qw( mhash_hmac_hex ) ;
    my $key  = "Jefe" ;
    my $data = "what do ya want for nothing?" ;
    my $hash_hex = mhash_hmac_hex(Mhash::MHASH_MD5, $data, $key) ;
    # $hash_hex should be 750c783e6ab0b503eaa86e310a5db738 according to RFC 2104.


  **NOTE** Please read the section on EXPORT TAGS below for information on the MHASH_ constants and the how to manage your namespace.

=head1 DEPENDENCIES

This interface is dependent on the MHASH library.  Please download and install the latest mhash-x.x.x.tar.gz at ftp://mhash.sourceforge.net/dl/.  As of this writing, the latest is mhash-0.8.3.tar.gz.  Additional information about the mhash library can be found at http://mhash.sourceforge.net.

The MHASH library MUST be found in your library path when using this module.  In Linux, libmhash is defaultly installed in /usr/local/lib -- in this case, be sure that the /usr/local/lib path is in your /etc/ld.so.conf.  Don't forget to run /sbin/ldconfig to update your linker cache after mhash library installation!


=head1 DESCRIPTION

This is an perl interface to the Mhash hash library, which provides a uniform interface to a large number of hash algorithms (also known as "one-way" algorithms).  
These algorithms can be used to compute checksums, message digests, and other signatures. Mhash support HMAC generation (a mechanism for message authentication using cryptographic hash functions, and is described in RFC2104). HMAC can be used to create message digests using a secret key, so that these message digests cannot be regenerated (or replaced) by someone else.  At the time of writing this, the library supports the algorithms: SHA1, GOST, HAVAL, MD5, RIPEMD160, TIGER, and CRC32 checksums.


Here is the list of hash constants which are currently supported by the Mhash module:

      MHASH_CRC32

      MHASH_MD5

      MHASH_SHA1

      MHASH_GOST

      MHASH_RIPEMD160

      MHASH_TIGER

      MHASH_GOST

      MHASH_CRC32B

      MHASH_HAVAL224

      MHASH_HAVAL192

      MHASH_HAVAL160


=head1 EXPORT TAGS
 

=head2 :Functions

  This tag exports all the functions related to Mhash.  This tag should be imported for convenience unless you are going to be importing specific functions into your namespace by hand.  This tag is automatically imported if no export tags are supplied as in the above example.

The following functions are imported with this export tag:

mhash 
mhash_hex 
mhash_hmac 
mhash_hmac_hex 
mhash_count
mhash_get_block_size 
mhash_get_hash_name

example: 

     use Mhash; 
         OR
     use Mhash(:Functions) ;

=head2 :Types   

  This tag exports the cipher constants defined by the list of hash types above in DESCRIPTION.  It is recommended you import this tag for ease of use.  If you are concerned with polluting your namespace, do not import this tag, and use the form Mhash::MHASH_HASHNAME when supplying the cipher to the Mhash functions.

example:

    use Mhash(:Types :Functions) ;
    $blah = mhash(MHASH_MD5, $data) ;

=head1 PROGRAMMING FUNCTIONS AND METHODS

The following methods are available:

mhash(), mhash_hex()
   
 mhash() applies a hash function specified by hash to the data and returns the resulting hash (also called digest). 
 mhash_hex() computes the hash and returns the hash value in hexadecimal form.

   $hash = mhash($hash, $data) ;

$hash is one of the MHASH_ciphername constants. 

$data is the data which shall be hashed.


mhash_hmac(), mhash_hmac_hex()

 mhash_hmac() computes a HMAC hash and returns the binary hash value.
 mhash_hmac_hex() computes a HMAC hash and returns the hash value in hexadecimal form.

   $hash_hmac = mhash_hmac($hash, $data, $key) ;

$hash is one of the MHASH_ciphername constants. 

$data is the data which shall be hashed.

$key is the key supplied to the hash algorithm. It must be kept secret.  It should be the blocksize of the current hash - use mhash_get_block_size() to get the blocksize.


mhash_get_block_size()

Mhash_get_block_size() is used to get the size of a block of the specified hash. 
Mhash_get_block_size() takes one argument, the hash and returns the size in bytes or false, if the hash does not exist. 

   $blocksize = mhash_get_block_size($hash) ;

$hash is one of the MHASH_ciphername constants. 


mhash_get_hash_name()

 Mhash_get_hash_name() gets the name of the specified hash.  Mhash_get_hash_name() takes one argument, the hash and returns the name of the hash as a string or false, if the hash does not exist.

   $hashname = mhash_get_hash_name($hash) ;

$hash is one of the MHASH_ciphername constants. 

mhash_count()

 Mhash_count() returns the highest available hash id. Hashes are numbered from 0 to this hash id. 

 Mhash_count() takes no arguments.

=head1 TODO

 - More bug testing.
 - detection of libmhash installation
 - support for the key generation functions of mhash

=head1 AUTHOR

Kuo, Frey. <kero@3SHEEP.COM>.

=head2 CREDITS

Mavroyanopoulos, Nikos <nmav@hellug.gr>, Schumann, Sasha <sascha@schumann.2ns.de> - for the libmhash library.

=head1 SEE ALSO

mhash(3).

=cut
