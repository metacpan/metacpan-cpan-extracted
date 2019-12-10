package IO::Compress::Lzop::Constants ;

use strict ;
use warnings;
use bytes;

require Exporter;

our ($VERSION, @ISA, @EXPORT);

$VERSION = '2.093';

@ISA = qw(Exporter);

@EXPORT= qw(
	SIGNATURE

	M_LZO1X_1
	M_LZO1X_1_15
	M_LZO1X_999
	M_NRV1A
	M_NRV1B
	M_NRV2A
	M_NRV2B
	M_NRV2D
	M_ZLIB

	F_ADLER32_D
	F_ADLER32_C
	F_STDIN
	F_STDOUT
	F_NAME_DEFAULT
	F_DOSISH
	F_H_EXTRA_FIELD
	F_H_GMTDIFF
	F_CRC32_D
	F_CRC32_C
	F_MULTIPART
	F_H_FILTER
	F_H_CRC32
	F_H_PATH
	F_MASK

	F_OS_FAT
	F_OS_AMIGA
	F_OS_VMS
	F_OS_UNIX
	F_OS_VM_CMS
	F_OS_ATARI
	F_OS_OS2
	F_OS_MAC9
	F_OS_Z_SYSTEM
	F_OS_CPM
	F_OS_TOPS20
	F_OS_NTFS
	F_OS_QDOS
	F_OS_ACORN
	F_OS_VFAT
	F_OS_MFS
	F_OS_BEOS
	F_OS_TANDEM
	F_OS_SHIFT
	F_OS_MASK

	F_CS_NATIVE
	F_CS_LATIN1
	F_CS_DOS
	F_CS_WIN32
	F_CS_WIN16
	F_CS_UTF8
	F_CS_SHIFT
	F_CS_MASK

	F_RESERVED

	BLOCK_SIZE
    MAX_BLOCK_SIZE

    FLAG_CRC_COMP
    FLAG_CRC_UNCOMP
    

);

use constant SIGNATURE       => "\x89\x4c\x5a\x4f\x00\x0d\x0a\x1a\x0a";

use constant M_LZO1X_1       =>    1;
use constant M_LZO1X_1_15    =>    2;
use constant M_LZO1X_999     =>    3;
use constant M_NRV1A         => 0x1a;
use constant M_NRV1B         => 0x1b;
use constant M_NRV2A         => 0x2a;
use constant M_NRV2B         => 0x2b;
use constant M_NRV2D         => 0x2d;
use constant M_ZLIB          =>  128;

# header flags 
use constant F_ADLER32_D     => 0x00000001;
use constant F_ADLER32_C     => 0x00000002;
use constant F_STDIN         => 0x00000004;
use constant F_STDOUT        => 0x00000008;
use constant F_NAME_DEFAULT  => 0x00000010;
use constant F_DOSISH        => 0x00000020;
use constant F_H_EXTRA_FIELD => 0x00000040;
use constant F_H_GMTDIFF     => 0x00000080;
use constant F_CRC32_D       => 0x00000100;
use constant F_CRC32_C       => 0x00000200;
use constant F_MULTIPART     => 0x00000400;
use constant F_H_FILTER      => 0x00000800;
use constant F_H_CRC32       => 0x00001000;
use constant F_H_PATH        => 0x00002000;
use constant F_MASK          => 0x00003FFF;

use constant F_OS_FAT        => 0x00000000;     # DOS, OS2, Win95 
use constant F_OS_AMIGA      => 0x01000000;
use constant F_OS_VMS        => 0x02000000;
use constant F_OS_UNIX       => 0x03000000;
use constant F_OS_VM_CMS     => 0x04000000;
use constant F_OS_ATARI      => 0x05000000;
use constant F_OS_OS2        => 0x06000000;     # OS2
use constant F_OS_MAC9       => 0x07000000;
use constant F_OS_Z_SYSTEM   => 0x08000000;
use constant F_OS_CPM        => 0x09000000;
use constant F_OS_TOPS20     => 0x0a000000;
use constant F_OS_NTFS       => 0x0b000000;     # Win NT/2000/XP
use constant F_OS_QDOS       => 0x0c000000;
use constant F_OS_ACORN      => 0x0d000000;
use constant F_OS_VFAT       => 0x0e000000;     # Win32 
use constant F_OS_MFS        => 0x0f000000;
use constant F_OS_BEOS       => 0x10000000;
use constant F_OS_TANDEM     => 0x11000000;
use constant F_OS_SHIFT      => 24;
use constant F_OS_MASK       => 0xff000000;

# character set for file name encoding [mostly unused] 
use constant F_CS_NATIVE     => 0x00000000;
use constant F_CS_LATIN1     => 0x00100000;
use constant F_CS_DOS        => 0x00200000;
use constant F_CS_WIN32      => 0x00300000;
use constant F_CS_WIN16      => 0x00400000;
use constant F_CS_UTF8       => 0x00500000;     # filename is UTF-8 encoded
use constant F_CS_SHIFT      => 20;
use constant F_CS_MASK       => 0x00f00000;

use constant F_RESERVED      => ((F_MASK | F_OS_MASK | F_CS_MASK) ^ 0xffffffff);

use constant BLOCK_SIZE      => 256 * 1024 ;
use constant MAX_BLOCK_SIZE  => 64 * 1024 * 1024 ;

use constant FLAG_CRC_COMP    => F_ADLER32_C | F_CRC32_C ;
use constant FLAG_CRC_UNCOMP  => F_ADLER32_D | F_CRC32_D ;


1;

