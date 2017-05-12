package Filesys::SamFS;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = (
# Version defines
	'SAM_VERSION',
	'NAME',
	'MAJORV',
	'MINORV',
	'FIXV',
	'SAM_BUILD_INFO',
	'SAM_BUILD_UNAME',

# stat functions and associated constants
	'sam_stat',
        'sam_stat_scalars',
	'sam_lstat',
        'sam_lstat_scalars',
	'sam_attrtoa',
	'sam_vsn_stat',
	'sam_segment_vsn_stat',
	'sam_segment_stat',
	'sam_segment_lstat',
	'sam_restore_file',
	'sam_restore_copy',
	'MAX_ARCHIVE',
	'MAX_VSNS',

# mode macros
	'S_IRGRP',
	'S_IROTH',
	'S_IRUSR',
	'S_IRWXG',
	'S_IRWXO',
	'S_IRWXU',
	'S_IWGRP',
	'S_IWOTH',
	'S_IWUSR',
	'S_IXGRP',
	'S_IXOTH',
	'S_IXUSR',
	'S_ISBLK',
	'S_ISCHR',
	'S_ISDIR',
	'S_ISFIFO',
	'S_ISGID',
	'S_ISREG',
	'S_ISUID',
	'S_ISLNK',
# New in 0.1
	'S_ISSOCK',

# attr macros
	'SS_SAMFS',
	'SS_REMEDIA',
	'SS_ARCHIVED',
	'SS_ARCHDONE',
	'SS_DAMAGED',
	'SS_CSGEN',
	'SS_CSUSE',
	'SS_CSVAL',
	'SS_OFFLINE',
	'SS_ARCHIVE_N',
	'SS_ARCHIVE_R',
	'SS_ARCHIVE_A',
	'SS_RELEASE_A',
	'SS_RELEASE_N',
	'SS_RELEASE_P',
	'SS_STAGE_A',
	'SS_STAGE_N',
	'SS_ISSAMFS',
	'SS_ISREMEDIA',
	'SS_ISARCHIVED',
	'SS_ISARCHDONE',
	'SS_ISDAMAGED',
	'SS_ISOFFLINE',
	'SS_ISARCHIVE_N',
	'SS_ISARCHIVE_A',
	'SS_ISARCHIVE_R',
	'SS_ISRELEASE_A',
	'SS_ISRELEASE_N',
	'SS_ISRELEASE_P',
	'SS_ISSTAGE_A',
	'SS_ISSTAGE_N',
	'SS_ISCSGEN',
	'SS_ISCSUSE',
	'SS_ISCSVAL',
# New in 3.3.1
	'SS_ARCHIVE_C',
        'SS_DIRECTIO',
        'SS_PARTIAL',
	'SS_ISARCHIVE_C',
        'SS_ISDIRECTIO',
        'SS_ISPARTIAL',
# New in 0.1
	'SS_DATA_V',
	'SS_AIO',
	'SS_SEGMENT_A',
	'SS_ARCHIVE_I',
	'SS_WORM',
	'SS_READONLY',
	'SS_SEGMENT_S',
	'SS_SEGMENT_F',
	'SS_SETFA_S',
	'SS_SETFA_G',
	'SS_DFACL',
	'SS_ACL',
	'SS_ISARCHIVE_I',
	'SS_ISSEGMENT_A',
	'SS_ISSEGMENT_S',
	'SS_ISSEGMENT_F',
#	'SS_ISSTAGE_M', SS_STAGE_M is missing
	'SS_ISWORM',
	'SS_ISREADONLY',
	'SS_ISSETFA_G',
	'SS_ISSETFA_S',
	'SS_ISDFACL',
	'SS_ISACL',
	'SS_ISDATAV',
	'SS_ISAIO',

# flag macros
	'SS_STAGEFAIL',
	'SS_STAGING',
	'SS_ISSTAGING',
	'SS_ISSTAGEFAIL',

# Copy flag macros
	'CF_ARCHIVED',
	'CF_ARCH_I',
	'CF_DAMAGED',
	'CF_REARCH',
	'CF_STALE',
	'CF_VAULT',

# devstat and associated constants
	'sam_devstat',
	'sam_ndevstat',
	'sam_devstr',
	'DT_CLASS_MASK',
	'DT_CLASS_SHIFT',
	'DT_DAT',
	'DT_DATA',
	'DT_DISK',
	'DT_DISK_SET',
	'DT_ERASABLE',
	'DT_EXABYTE_TAPE',
	'DT_FAMILY_SET',
	'DT_LINEAR_TAPE',
	'DT_MEDIA_MASK',
	'DT_META',
	'DT_META_SET',
	'DT_MULTIFUNCTION',
	'DT_OPTICAL',
	'DT_RAID',
	'DT_ROBOT',
	'DT_ROBOT_MASK',
	'DT_SCSI_R',
	'DT_SCSI_ROBOT_MASK',
	'DT_SQUARE_TAPE',
	'DT_TAPE',
	'DT_TAPE_R',
	'DT_TAPE_SR',
	'DT_VIDEO_TAPE',
	'DT_WORM_OPTICAL',
	'DT_WORM_OPTICAL_12',
# new DT_* in 0.1
	'DT_STRIPE_GROUP_MASK',
	'DT_STRIPE_GROUP',
	'DT_STK5800',
	'DT_9490',
	'DT_D3',
	'DT_xx',
	'DT_3590',
	'DT_3570',
	'DT_SONYDTF',
	'DT_SONYAIT',
	'DT_9840',
	'DT_FUJITSU_128',
	'DT_EXABYTE_M2_TAPE',
	'DT_9940',
	'DT_IBM3580',
	'DT_SONYSAIT',
	'DT_3592',
	'DT_TITAN',
	'DT_PLASMON_UDO',
	'DT_LMS4500',
	'DT_CYGNET',
	'DT_DOCSTOR',
	'DT_HPLIBS',
	'DT_PLASMON_D',
	'DT_PLASMON_G',
	'DT_DLT2700',
	'DT_METRUM_LIB',
	'DT_METD28',
	'DT_METD360',
	'DT_ACL_LIB',
	'DT_ACL452',
	'DT_ACL2640',
	'DT_EXB210',
	'DT_ADIC448',
	'DT_SPECLOG',
	'DT_STK97XX',
	'DT_UNUSED1',
	'DT_3570C',
	'DT_SONYDMS',
	'DT_SONYCSM',
	'DT_UNUSED2',
	'DT_ATLP3000',
	'DT_ADIC1000',
	'DT_EXBX80',
	'DT_STKLXX',
	'DT_IBM3584',
	'DT_ADIC100',
	'DT_UNUSED3',
	'DT_HP_C7200',
	'DT_QUAL82xx',
	'DT_ATL1500',
	'DT_ODI_NEO',
	'DT_QUANTUMC4',
	'DT_GRAUACI',
	'DT_STKAPI',
	'DT_IBMATL',
	'DT_LMF',
	'DT_SONYPSC',
	'DT_PSEUDO',
	'DT_PSEUDO_SSI',
	'DT_PSEUDO_SC',
	'DT_PSEUDO_SS',
	'DT_PSEUDO_RD',
	'DT_HISTORIAN',
	'DT_THIRD_PARTY',
	'DT_THIRD_MASK',
	'DT_UNKNOWN',
	'is_disk',
	'is_optical',
	'is_robot',
	'is_tape',
	'is_tapelib',
	'is_third_party',
	'is_stripe_group',
	'is_rsd',
	'is_stk5800',

	'DVST_ATTENTION',
	'DVST_AUDIT',
	'DVST_BAD_MEDIA',
	'DVST_CLEANING',
	'DVST_FORWARD',
	'DVST_FS_ACTIVE',
	'DVST_I_E_PORT',
	'DVST_LABELED',
	'DVST_MAINT',
	'DVST_MOUNTED',
	'DVST_OPENED',
	'DVST_POSITION',
	'DVST_PRESENT',
	'DVST_READY',
	'DVST_READ_ONLY',
	'DVST_REQUESTED',
	'DVST_SCANNED',
	'DVST_SCANNING',
	'DVST_SCAN_ERR',
	'DVST_STAGE_ACT',
	'DVST_STOR_FULL',
	'DVST_UNLOAD',
	'DVST_WAIT_IDLE',
	'DVST_WR_LOCK',

# Catalog
	'sam_opencat',
	'sam_closecat',
	'sam_getcatalog',
	'MAX_CAT',
	'BARCODE_LEN',
	'CATALOG_SLOT_DRIVE',
	'CATALOG_SLOT_MAIL',
	'CATALOG_SLOT_MEDIA',
	'CSP_BAD_MEDIA',
	'CSP_BAR_CODE',
	'CSP_CLEANING',
	'CSP_EXPORT',
	'CSP_INUSE',
	'CSP_LABELED',
	'CSP_NEEDS_AUDIT',
	'CSP_OCCUPIED',
	'CSP_READ_ONLY',
	'CSP_RECYCLE',
	'CSP_UNAVAIL',
	'CSP_WRITEPROTECT',
	'CS_BADMEDIA',
	'CS_BARCODE',
	'CS_CLEANING',
	'CS_EXPORT',
	'CS_INUSE',
	'CS_LABELED',
	'CS_NEEDS_AUDIT',
	'CS_OCCUPIED',
	'CS_RDONLY',
	'CS_RECYCLE',
	'CS_UNAVAIL',
	'CS_WRTPROT',

# Miscellaneous operations
	'sam_archive',
	'sam_cancelstage',
	'sam_release',
	'sam_ssum',
	'sam_stage',
	'sam_setfa',
	'sam_advise',

# Not yet
	'RI_blockio',
);

%EXPORT_TAGS = (version => [ qw(
                             SAM_VERSION
                             NAME
                             MAJORV
                             MINORV
                             FIXV
                             SAM_BUILD_INFO
                             SAM_BUILD_UNAME
                             ) ],
		stat => [ qw(
                             sam_stat
                             sam_stat_scalars
                             sam_lstat
                             sam_lstat_scalars
                             sam_attrtoa
                             sam_vsn_stat
                             sam_segment_vsn_stat
                             sam_segment_stat
                             sam_segment_lstat
                             sam_restore_file
                             sam_restore_copy
                             MAX_ARCHIVE
                             MAX_VSNS
                             ) ],
	        mode => [ qw(
                             S_IRGRP
                             S_IROTH
                             S_IRUSR
                             S_IRWXG
                             S_IRWXO
                             S_IRWXU
                             S_IWGRP
                             S_IWOTH
                             S_IWUSR
                             S_IXGRP
                             S_IXOTH
                             S_IXUSR
                             S_ISBLK
                             S_ISCHR
                             S_ISDIR
                             S_ISFIFO
                             S_ISGID
                             S_ISREG
                             S_ISUID
                             S_ISLNK
                             S_ISSOCK
                             ) ],
		attr => [ qw(
                             SS_SAMFS
                             SS_REMEDIA
                             SS_ARCHIVED
                             SS_ARCHDONE
                             SS_DAMAGED
                             SS_CSGEN
                             SS_CSUSE
                             SS_CSVAL
                             SS_OFFLINE
                             SS_ARCHIVE_N
                             SS_ARCHIVE_R
                             SS_ARCHIVE_A
                             SS_RELEASE_A
                             SS_RELEASE_N
                             SS_RELEASE_P
                             SS_STAGE_A
                             SS_STAGE_N
                             SS_ISSAMFS
                             SS_ISREMEDIA
                             SS_ISARCHIVED
                             SS_ISARCHDONE
                             SS_ISDAMAGED
                             SS_ISOFFLINE
                             SS_ISARCHIVE_N
                             SS_ISARCHIVE_A
                             SS_ISARCHIVE_R
                             SS_ISRELEASE_A
                             SS_ISRELEASE_N
                             SS_ISRELEASE_P
                             SS_ISSTAGE_A
                             SS_ISSTAGE_N
                             SS_ISCSGEN
                             SS_ISCSUSE
                             SS_ISCSVAL
                             SS_ARCHIVE_C
                             SS_DIRECTIO
                             SS_PARTIAL
                             SS_ISARCHIVE_C
                             SS_ISDIRECTIO
                             SS_ISPARTIAL
                             SS_DATA_V
                             SS_AIO
                             SS_SEGMENT_A
                             SS_ARCHIVE_I
                             SS_WORM
                             SS_READONLY
                             SS_SEGMENT_S
                             SS_SEGMENT_F
                             SS_SETFA_S
                             SS_SETFA_G
                             SS_DFACL
                             SS_ACL
                             SS_ISARCHIVE_I
                             SS_ISSEGMENT_A
                             SS_ISSEGMENT_S
                             SS_ISSEGMENT_F
                             SS_ISWORM
                             SS_ISREADONLY
                             SS_ISSETFA_G
                             SS_ISSETFA_S
                             SS_ISDFACL
                             SS_ISACL
                             SS_ISDATAV
                             SS_ISAIO
                            )],
# SS_ISSTAGE_M SS_STAGE_M is missing
	        flags => [ qw(
                             SS_STAGEFAIL
                             SS_STAGING
                             SS_ISSTAGING
                             SS_ISSTAGEFAIL
                             )],
	        copyflags => [ qw(
                             CF_ARCHIVED
                             CF_ARCH_I
                             CF_DAMAGED
                             CF_REARCH
                             CF_STALE
                             CF_VAULT
                             )],
	        devstat => [ qw(
                             sam_devstat
                             sam_ndevstat
                             sam_devstr
                             DT_CLASS_MASK
                             DT_CLASS_SHIFT
                             DT_DAT
                             DT_DATA
                             DT_DISK
                             DT_DISK_SET
                             DT_ERASABLE
                             DT_EXABYTE_TAPE
                             DT_FAMILY_SET
                             DT_LINEAR_TAPE
                             DT_MEDIA_MASK
                             DT_META
                             DT_META_SET
                             DT_MULTIFUNCTION
                             DT_OPTICAL
                             DT_RAID
                             DT_ROBOT
                             DT_ROBOT_MASK
                             DT_SCSI_R
                             DT_SCSI_ROBOT_MASK
                             DT_SQUARE_TAPE
                             DT_TAPE
                             DT_TAPE_R
                             DT_TAPE_SR
                             DT_VIDEO_TAPE
                             DT_WORM_OPTICAL
                             DT_WORM_OPTICAL_12
                             DT_STRIPE_GROUP_MASK
                             DT_STRIPE_GROUP
                             DT_STK5800
                             DT_9490
                             DT_D3
                             DT_xx
                             DT_3590
                             DT_3570
                             DT_SONYDTF
                             DT_SONYAIT
                             DT_9840
                             DT_FUJITSU_128
                             DT_EXABYTE_M2_TAPE
                             DT_9940
                             DT_IBM3580
                             DT_SONYSAIT
                             DT_3592
                             DT_TITAN
                             DT_PLASMON_UDO
                             DT_LMS4500
                             DT_CYGNET
                             DT_DOCSTOR
                             DT_HPLIBS
                             DT_PLASMON_D
                             DT_PLASMON_G
                             DT_DLT2700
                             DT_METRUM_LIB
                             DT_METD28
                             DT_METD360
                             DT_ACL_LIB
                             DT_ACL452
                             DT_ACL2640
                             DT_EXB210
                             DT_ADIC448
                             DT_SPECLOG
                             DT_STK97XX
                             DT_UNUSED1
                             DT_3570C
                             DT_SONYDMS
                             DT_SONYCSM
                             DT_UNUSED2
                             DT_ATLP3000
                             DT_ADIC1000
                             DT_EXBX80
                             DT_STKLXX
                             DT_IBM3584
                             DT_ADIC100
                             DT_UNUSED3
                             DT_HP_C7200
                             DT_QUAL82xx
                             DT_ATL1500
                             DT_ODI_NEO
                             DT_QUANTUMC4
                             DT_GRAUACI
                             DT_STKAPI
                             DT_IBMATL
                             DT_LMF
                             DT_SONYPSC
                             DT_PSEUDO
                             DT_PSEUDO_SSI
                             DT_PSEUDO_SC
                             DT_PSEUDO_SS
                             DT_PSEUDO_RD
                             DT_HISTORIAN
                             DT_THIRD_PARTY
                             DT_THIRD_MASK
                             DT_UNKNOWN
                             is_disk
                             is_optical
                             is_robot
                             is_tape
                             is_tapelib
                             is_third_party
                             is_stripe_group
                             is_rsd
                             is_stk5800
                             DVST_ATTENTION
                             DVST_AUDIT
                             DVST_BAD_MEDIA
                             DVST_CLEANING
                             DVST_FORWARD
                             DVST_FS_ACTIVE
                             DVST_I_E_PORT
                             DVST_LABELED
                             DVST_MAINT
                             DVST_MOUNTED
                             DVST_OPENED
                             DVST_POSITION
                             DVST_PRESENT
                             DVST_READY
                             DVST_READ_ONLY
                             DVST_REQUESTED
                             DVST_SCANNED
                             DVST_SCANNING
                             DVST_SCAN_ERR
                             DVST_STAGE_ACT
                             DVST_STOR_FULL
                             DVST_UNLOAD
                             DVST_WAIT_IDLE
                             DVST_WR_LOCK
                             )],
	        catalog => [ qw(
                             sam_opencat
                             sam_closecat
                             sam_getcatalog
                             MAX_CAT
                             BARCODE_LEN
                             CATALOG_SLOT_DRIVE
                             CATALOG_SLOT_MAIL
                             CATALOG_SLOT_MEDIA
                             CSP_BAD_MEDIA
                             CSP_BAR_CODE
                             CSP_CLEANING
                             CSP_EXPORT
                             CSP_INUSE
                             CSP_LABELED
                             CSP_NEEDS_AUDIT
                             CSP_OCCUPIED
                             CSP_READ_ONLY
                             CSP_RECYCLE
                             CSP_UNAVAIL
                             CSP_WRITEPROTECT
                             CS_BADMEDIA
                             CS_BARCODE
                             CS_CLEANING
                             CS_EXPORT
                             CS_INUSE
                             CS_LABELED
                             CS_NEEDS_AUDIT
                             CS_OCCUPIED
                             CS_RDONLY
                             CS_RECYCLE
                             CS_UNAVAIL
                             CS_WRTPROT
                             )],
	        operations => [ qw(
                             sam_archive
                             sam_cancelstage
                             sam_release
                             sam_ssum
                             sam_stage
                             sam_setfa
                             sam_advise
                             )],
                             );

$VERSION = '0.101';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Filesys::SamFS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Filesys::SamFS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
# Note that calling a sub without an argument list passes @_ implicitly.

sub sam_stat {
  Filesys::SamFS::stat;
}

sub sam_lstat {
  Filesys::SamFS::lstat;
}

sub sam_stat_scalars {
  Filesys::SamFS::stat;
}

sub sam_lstat_scalars {
  Filesys::SamFS::lstat;
}

sub sam_vsn_stat {
  Filesys::SamFS::vsn_stat;
}

sub sam_segment_stat {
  Filesys::SamFS::sam_segment_stat;
}

sub sam_segment_lstat {
  Filesys::SamFS::sam_segment_lstat;
}

sub sam_restore_file {
  Filesys::SamFS::sam_restore_file;
}

sub sam_restore_copy {
  Filesys::SamFS::sam_restore_copy;
}

sub sam_attrtoa {
  Filesys::SamFS::attrtoa;
}

sub sam_devstat {
  Filesys::SamFS::devstat;
}

sub sam_ndevstat {
  Filesys::SamFS::ndevstat;
}

sub sam_devstr {
  Filesys::SamFS::devstr;
}

sub sam_opencat {
  Filesys::SamFS::opencat;
}

sub sam_closecat {
  Filesys::SamFS::closecat;
}

sub sam_getcatalog {
  Filesys::SamFS::getcatalog;
}

sub sam_archive {
  Filesys::SamFS::archive;
}

sub sam_cancelstage {
  Filesys::SamFS::cancelstage;
}

sub sam_release {
  Filesys::SamFS::release;
}

sub sam_ssum {
  Filesys::SamFS::ssum;
}

sub sam_stage {
  Filesys::SamFS::stage;
}

sub sam_setfa {
  Filesys::SamFS::setfa;
}

sub sam_advise {
  Filesys::SamFS::advise;
}

1;
__END__

=head1 NAME

Filesys::SamFS - Perl extension mapping the SamFS API to Perl

=head1 SYNOPSIS

use Filesys::SamFS;

=head1 DESCRIPTION

Filesys::SamFS makes the SamFS API available to Perl. SamFS is a
HSM (Hierarchical Storage Management) Filesystem; it manages
files in two storage levels - a cache on disks and an archive
on removable media like magneto-optical disks or tapes.

SamFS is a product of Sun Microsystems, Inc. For more information, please
refer to
  http://www.sun.com/storagetek/management_software/data_management/sam/

=head1 Exported constants and functions

Filesys::SamFS does not export by default.
All constants and functions are available for explicit import
(i.e. use "Filesys::SamFS qw(SAM_VERSION)").
They have also been bundled up in useful groups for import with tags
(i.e. use "Filesys::SamFS qw(:version)").

The groups are the following:

=over

=item :version

SAM_VERSION
NAME
MAJORV
MINORV
FIXV
SAM_BUILD_INFO
SAM_BUILD_UNAME

Note that VERSION is the I<module> version; the SamFS version is available
as C<Filesys::SamFS::SAM_VERSION>.

=item :stat

sam_stat()
sam_stat_scalars()
sam_lstat()
sam_lstat_scalars()
sam_attrtoa()
sam_vsn_stat()
sam_segment_vsn_stat()
sam_segment_stat()
sam_segment_lstat()
sam_restore_file()
sam_restore_copy()
MAX_ARCHIVE
MAX_VSNS

=item :mode

S_IRGRP
S_IROTH
S_IRUSR
S_IRWXG
S_IRWXO
S_IRWXU
S_IWGRP
S_IWOTH
S_IWUSR
S_IXGRP
S_IXOTH
S_IXUSR
S_ISBLK(mode)
S_ISCHR(mode)
S_ISDIR(mode)
S_ISFIFO(mode)
S_ISGID(mode)
S_ISREG(mode)
S_ISUID(mode)
S_ISLNK(mode)
S_ISSOCK(mode)

=item :attr

SS_SAMFS
SS_REMEDIA
SS_ARCHIVED
SS_ARCHDONE
SS_DAMAGED
SS_CSGEN
SS_CSUSE
SS_CSVAL
SS_OFFLINE
SS_ARCHIVE_N
SS_ARCHIVE_R
SS_ARCHIVE_A
SS_RELEASE_A
SS_RELEASE_N
SS_RELEASE_P
SS_STAGE_A
SS_STAGE_N
SS_DATA_V
SS_AIO
SS_SEGMENT_A
SS_ARCHIVE_I
SS_WORM
SS_READONLY
SS_SEGMENT_S
SS_SEGMENT_F
SS_SETFA_S
SS_SETFA_G
SS_DFACL
SS_ACL
SS_ARCHIVE_C
SS_DIRECTIO
SS_PARTIAL
SS_ISSAMFS(attr)
SS_ISREMEDIA(attr)
SS_ISARCHIVED(attr)
SS_ISARCHDONE(attr)
SS_ISDAMAGED(attr)
SS_ISOFFLINE(attr)
SS_ISARCHIVE_N(attr)
SS_ISARCHIVE_A(attr)
SS_ISARCHIVE_R(attr)
SS_ISRELEASE_A(attr)
SS_ISRELEASE_N(attr)
SS_ISRELEASE_P(attr)
SS_ISSTAGE_A(attr)
SS_ISSTAGE_N(attr)
SS_ISCSGEN(attr)
SS_ISCSUSE(attr)
SS_ISCSVAL(attr)
SS_ISARCHIVE_C(attr)
SS_ISDIRECTIO(attr)
SS_ISPARTIAL(attr)
SS_ISARCHIVE_I(attr)
SS_ISSEGMENT_A(attr)
SS_ISSEGMENT_S(attr)
SS_ISSEGMENT_F(attr)
SS_ISWORM(attr)
SS_ISREADONLY(attr)
SS_ISSETFA_G(attr)
SS_ISSETFA_S(attr)
SS_ISDFACL(attr)
SS_ISACL(attr)
SS_ISDATAV(attr)
SS_ISAIO(attr)

Note that the include file defines SS_ISSTAGE_M, but the corresponding
flag SS_STAGE_M is missing.

=item :flags

SS_STAGEFAIL
SS_STAGING
SS_ISSTAGING(flags)
SS_ISSTAGEFAIL(flags)

=item :copyflags

CF_ARCHIVED
CF_ARCH_I
CF_DAMAGED
CF_REARCH
CF_STALE
CF_VAULT

=item :devstat

sam_devstat(eq)
sam_ndevstat(eq)
sam_devstr(status)
DT_CLASS_MASK
DT_CLASS_SHIFT
DT_DAT
DT_DATA
DT_DISK
DT_DISK_SET
DT_ERASABLE
DT_EXABYTE_TAPE
DT_FAMILY_SET
DT_LINEAR_TAPE
DT_MEDIA_MASK
DT_META
DT_META_SET
DT_MULTIFUNCTION
DT_OPTICAL
DT_RAID
DT_ROBOT
DT_ROBOT_MASK
DT_SCSI_R
DT_SCSI_ROBOT_MASK
DT_SQUARE_TAPE
DT_TAPE
DT_TAPE_R
DT_TAPE_SR
DT_VIDEO_TAPE
DT_WORM_OPTICAL
DT_WORM_OPTICAL_12
DT_STRIPE_GROUP_MASK
DT_STRIPE_GROUP
DT_STK5800
DT_9490
DT_D3
DT_xx
DT_3590
DT_3570
DT_SONYDTF
DT_SONYAIT
DT_9840
DT_FUJITSU_128
DT_EXABYTE_M2_TAPE
DT_9940
DT_IBM3580
DT_SONYSAIT
DT_3592
DT_TITAN
DT_PLASMON_UDO
DT_LMS4500
DT_CYGNET
DT_DOCSTOR
DT_HPLIBS
DT_PLASMON_D
DT_PLASMON_G
DT_DLT2700
DT_METRUM_LIB
DT_METD28
DT_METD360
DT_ACL_LIB
DT_ACL452
DT_ACL2640
DT_EXB210
DT_ADIC448
DT_SPECLOG
DT_STK97XX
DT_UNUSED1
DT_3570C
DT_SONYDMS
DT_SONYCSM
DT_UNUSED2
DT_ATLP3000
DT_ADIC1000
DT_EXBX80
DT_STKLXX
DT_IBM3584
DT_ADIC100
DT_UNUSED3
DT_HP_C7200
DT_QUAL82xx
DT_ATL1500
DT_ODI_NEO
DT_QUANTUMC4
DT_GRAUACI
DT_STKAPI
DT_IBMATL
DT_LMF
DT_SONYPSC
DT_PSEUDO
DT_PSEUDO_SSI
DT_PSEUDO_SC
DT_PSEUDO_SS
DT_PSEUDO_RD
DT_HISTORIAN
DT_THIRD_PARTY
DT_THIRD_MASK
DT_UNKNOWN
is_disk
is_optical
is_robot
is_tape
is_tapelib
is_third_party
is_stripe_group
is_rsd
is_stk5800
DVST_ATTENTION
DVST_AUDIT
DVST_BAD_MEDIA
DVST_CLEANING
DVST_FORWARD
DVST_FS_ACTIVE
DVST_I_E_PORT
DVST_LABELED
DVST_MAINT
DVST_MOUNTED
DVST_OPENED
DVST_POSITION
DVST_PRESENT
DVST_READY
DVST_READ_ONLY
DVST_REQUESTED
DVST_SCANNED
DVST_SCANNING
DVST_SCAN_ERR
DVST_STAGE_ACT
DVST_STOR_FULL
DVST_UNLOAD
DVST_WAIT_IDLE
DVST_WR_LOCK

=item :catalog

sam_opencat
sam_closecat
sam_getcatalog
MAX_CAT
BARCODE_LEN
CATALOG_SLOT_DRIVE
CATALOG_SLOT_MAIL
CATALOG_SLOT_MEDIA
CSP_BAD_MEDIA
CSP_BAR_CODE
CSP_CLEANING
CSP_EXPORT
CSP_INUSE
CSP_LABELED
CSP_NEEDS_AUDIT
CSP_OCCUPIED
CSP_READ_ONLY
CSP_RECYCLE
CSP_UNAVAIL
CSP_WRITEPROTECT
CS_BADMEDIA(status)
CS_BARCODE(status)
CS_CLEANING(status)
CS_EXPORT(status)
CS_INUSE(status)
CS_LABELED(status)
CS_NEEDS_AUDIT(status)
CS_OCCUPIED(status)
CS_RDONLY(status)
CS_RECYCLE(status)
CS_UNAVAIL(status)
CS_WRTPROT(status)

=item :operations

sam_archive
sam_cancelstage
sam_release
sam_ssum
sam_stage
sam_setfa
sam_advise

=back

=head1 Interface

The following paragraphs describe the interface from the Perl
viewpoint and emphasize differences from the C API.  For a description
of the commonalities, please refer to the SamFS API manpages.

=head2 stat and lstat

B<Filesys::SamFS::stat($path)> (importable as sam_stat) returns a
list, much like the standard Perl function stat.

The first 13 elements are the same as for stat, while the additional
elements are specific to SamFS filesystems. The element "blocks" is
not returned by the sam_stat function in older versions of the SamFS
API and the element "blksize" is never returned (a block size of 512
is assumed). If the code is compiled with OLD_SAMFS defined, these
elements are always returned as B<undef>.

Example usage:

C<($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
$atime,$mtime,$ctime,undef,undef,
# So far, much like stat()
$attr,$attribute_time,$creation_time,$residence_time,
$cs_algo,$flags,$gen,$partial_size,@copyref)
           = Filesys::SamFS::stat($path);>

C<@copyref> is a list of MAX_ARCHIVE elements, each an array reference.
The arrays referenced contain the elements flags, n_vsns, creation_time
and position.

B<Filesys::SamFS::stat($path)> returns an empty list on error.
$! is set in this case.

B<Note>: SamFS uses 64 bit integers for sizes and positions.
Since perl on Solaris works with only 32 bit integers, we have an
impedance problem here.
The XS solves this problem by returning these elements as strings.
This is sufficient for printing the values.
For I<manipulation>, it is recommended to use B<Math::BigInt>.
In this case, this affects the I<size> element.

B<Filesys::SamFS::lstat($path)> (importable as sam_lstat) has the same
interface as sam_stat, but when given the path of a symbolic link,
will return information about the link rather than the file it points to.
I.e. it has the same relation to B<sam_stat> as B<lstat> has to B<stat>.

Note that these functions also work for a I<path> that does
not lie on a SamFS filesystem.
The elements specific to SamFS are returned as zero in this case,
but blksize and blocks are still returned as B<undef>.
(This is so because the SamFS API function sam_stat()/sam_lstat()
just do not provide these elements.)

=head2 stat_scalars and lstat_scalars

These are variants of stat and lstat that try to solve the problem of
a struct definition acquiring more fields over time. The first 13
elements are again the same as for stat and lstat in Perl. The array
@copyref is returned by reference as the fourteenth element, and newer
fields are added after that. The usage is:

C<($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
$atime,$mtime,$ctime,undef,undef,
# So far, much like Perl stat()
$attr,$attribute_time,$creation_time,$residence_time,
$cs_algo,$flags,$gen,$partial_size,
# So far, just like Filesys::SamFS::stat()
$copyref,
# New fields
$stripe_width,$stripe_group,$segment_size,$segment_number,
$stage_ahead,$admin_id,$allocahead)
           = Filesys::SamFS::stat_scalars($path);>

Again, lstat_scalars is stat_scalars with the same difference as stat
vs. lstat.

=head2 segment_stat

B<Filesys::SamFS::segment_stat($path)> (importable as
sam_segment_stat) returns a list of arrays, each like the list
returned by stat_scalars, one array per segment of the file. Note that
a list with just one array is returned for an unsegmented file.

There is also the lstat variant of this function, segment_lstat
(importable as sam_lstat).

=head2 vsn_stat

B<Filesys::SamFS::vsn_stat($path, $copy)> (importable as sam_vsn_stat)
returns a list of MAX_VSNS array references.
Each array referenced contains the elements vsn, length, position and offset.
All of them are strings.

B<Filesys::SamFS::vsn_stat($path, $copy)> returns an empty list on error.
$! is set in this case.

=head2 segment_vsn_stat

B<Filesys::SamFS::segment_vsn_stat($path, $copy, $segment_index)>
(importable as sam_segment_vsn_stat) is the equivalent of vsn_stat for
segmented files. In addition to a copy number, it requires a segment
number. It returns the same list as vsn_stat.

=head2 restore_file

B<Filesys::SamFS::restore_file($path, $st_mode, $st_uid, $st_gid,
$st_size, $st_atime, $st_ctime, $st_mtime, $copies)>
(importable as sam_restore_file) creates an offline file.
You must supply it with a number of attributes for the file.
$copies is a reference to an array containing MAX_ARCHIVE sub-arrays.
Each of those arrays must contain four elements media, position,
creation_time and vsn.

=head2 restore_copy

B<Filesys::SamFS::restore_copy($path, $copy_no, $st_mode, $st_uid, $st_gid,
$st_size, $st_atime, $st_ctime, $st_mtime, $copies, $sections)>
(importable as sam_restore_copy) creates archive copy for an existing
file. $sections is optional and only required for a segmented file.
It is a reference to an array containing sub-arrays, one for each
section. The sections have the elements vsn, length, position
and offset.

=head2 attrtoa

B<Filesys::SamFS::attrtoa($attr)> (importable as sam_attrtoa)
translates a numeric attribute word into a symbolic string,
which is returned.

=head2 devstat

B<Filesys::SamFS::devstat($eq)> (importable as sam_devstat)
and B<Filesys::SamFS::ndevstat($eq)> (importable as sam_ndevstat)
both return a list of values or no values at all in the case
of an error.

C<($type, $name, $vsn, $state, $status, $space, $capacity) = Filesys::SamFS::ndevstat($eq);>

=head2 devstr

B<Filesys::SamFS::devstr($status)> (importable as sam_devstr)
can be used to translate the binary status value into a string.
This string is returned.

=head2 Catalog

B<Filesys::SamFS::opencat($path)> (importable as sam_opencat)
opens a SamFS robot catalog. If this operation succeeds, it
returns a list C<($cat_handle, $audit_time, $vcersion, $count, $media)>.
C<$cat_handle> identifies the opened catalog and must be passed to
C<closecat> and C<getcatalog>.
For the other elements of the list please refer to the sam_opencat
manpage.
If the opening of the catalog fails, an empty list is returned
and C>$!> is set.

B<Filesys::SamFS::closecat($cat_handle)> (importable as sam_closecat)
closes the catalog opened with C<opencat>, as identified by the handle.
It returns 0 on success. On failure, it returns -1 and sets C<$!>.

B<Filesys::SamFS::getcatalog($cat_handle, $slot)> (importable as sam_getcat)
queries the catalog identified by the handle for a single slot.
Note that the SamFS API funtion sam_getcatalog() can query several slots;
we try to keep the interface simple by not returning a list of lists.
The list returned has the elements
C<($type, $status, $media, $vsn, $access, $capacity, $space, $ptoc_fwa,
$modification_time, $mount_time, $bar_code)>.
getcatalog returns an empty list on failure and sets C<$!>.

=head2 Attributes
B<sam_archive($path, $opns)> (importable as sam_archive)
sets archive attributes on the file or directory pointed to by $path.
Please refer to sam_archive(3) for details.

B<sam_cancelstage($path)> (importable as sam_cancelstage)
cancels a staging operation of the file pointed to by $path.
Please refer to sam_cancelstage(3) for details.

B<sam_release($path, $opns)> (importable as sam_release)
sets release attributes on the file or directory pointed to by $path.
Please refer to sam_release(3) for details.

B<sam_ssum($path, $opns)> (importable as sam_ssum)
sets the checksum attributes for the file ppointed to by $path.
Please refer to sam_ssum(3) for details.

B<sam_stage($path, $opns)> (importable as sam_stage)
sets stage attributes on the file or directory pointed to by $path.
Please refer to sam_stage(3) for details.

B<sam_setfa($path, $opns)> (importable as sam_setfa)
sets attributes on the file or directory pointed to by $path.
Please refer to sam_setfa(3) for details.

B<sam_advise($fildes, $opns)> (importable as sam_advise)
requests special I/O modes from SamFS.
$fildes is the numeric filedescriptor of an open file.
(Use fileno(FILEHANDLE) to retrieve the filedescriptor for
a filehandle or $io->fileno when using IO::Handle.)
Please refer to sam_advise(3) for details.

=head1 Unimplemented functions

sam_request

Not yet implemented. I don't really understand what it does.

sam_readrminfo

sam_segment

Both of these are not documented in the manpages, and the header
file does not provide enough information.

=head1 AUTHOR

Lupe Christoph <lupe@lupe-christoph.de>

=head1 SEE ALSO

perl(1), the SamFS man pages, e.g. sam_stat(3).

=cut
