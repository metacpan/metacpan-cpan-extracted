package MacOSX::File::Constants;

=head1 NAME

MacOSX::File::Constants - Get (HFS) File Attributes

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

require 5.005_62;
use strict;
use warnings;
use Carp;

our $RCSID = q$Id: Constants.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.70 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

		 kIsAlias
		 kIsInvisible
		 kHasBundle
		 kNameLocked
		 kIsStationery
		 kHasCustomIcon
		 kHasBeenInited
		 kHasNoINITs
		 kIsShared
		 kIsHiddenExtention 
		 kIsOnDesk          
		 kFSNodeLockedMask
		 kFSNodeResOpenMask
		 kFSNodeDataOpenMask
		 kFSNodeIsDirectoryMask
		 kFSNodeCopyProtectMask
		 kFSNodeForkOpenMask
		 ResultCode
		 );

=head2 EXPORT

fdFlags Constants: 
kIsAlias, kIsInvisible, kHasBundle, kNameLocked, kIsStationery,
kHasCustomIcon, kHasBeenInited, kHasNoINITs, kIsShared, 
kIsHiddenExtention, kIsOnDesk,

nodeFlags Constants:
kFSNodeLockedMask, kFSNodeResOpenMask, kFSNodeDataOpenMask,
kFSNodeIsDirectoryMask, kFSNodeCopyProtectMask, kFSNodeForkOpenMask

OSErr related:
ResultCode

=cut

# constants for FdFlags from <Finder.h>
    use constant kIsAlias           => 0x8000;
use constant kIsInvisible       => 0x4000;
use constant kHasBundle         => 0x2000;
use constant kNameLocked        => 0x1000;
use constant kIsStationery      => 0x0800;
use constant kHasCustomIcon     => 0x0400;
use constant kHasBeenInited     => 0x0100;
use constant kHasNoINITs        => 0x0080;
use constant kIsShared          => 0x0040;
use constant kIsHiddenExtention => 0x0010;
use constant kIsOnDesk          => 0x0001;

# kIsHiddenExtention corresponds to 'E' attribute of
# /Developer/Tools/SetFile command
# but there is no corresponding constant in <Finder.h> !

# constants for nodeFlags from <Files.h>
# only kFSNodeLockedMask is relevant, however.
use constant kFSNodeLockedMask      => 0x0001;
use constant kFSNodeResOpenMask     => 0x0004;
use constant kFSNodeDataOpenMask    => 0x0008;
use constant kFSNodeIsDirectoryMask => 0x0010;
use constant kFSNodeCopyProtectMask => 0x0040;
use constant kFSNodeForkOpenMask    => 0x0080;

use constant ResultCode =>
    { qw(
	 0  noErr
	 -28  notOpenErr
	 -33  dirFulErr
	 -34  dskFulErr
	 -35  nsvErr
	 -36  ioErr
	 -37  bdNamErr
	 -38  fnOpnErr
	 -39  eofErr
	 -40  posErr
	 -42  tmfoErr
	 -43  fnfErr
	 -44  wPrErr
	 -45  fLckdErr
	 -46  vLckdErr
	 -47  fBsyErr
	 -48  dupFNErr
	 -49  opWrErr
	 -50  paramErr
	 -51  rfNumErr
	 -52  gfpErr
	 -53  volOffLinErr
	 -54  permErr
	 -55  volOnLinErr
	 -56  nsDrvErr
	 -57  noMacDskErr
	 -58  extFSErr
	 -59  fsRnErr
	 -60  badMDBErr
	 -61  wrPermErr
	 -108  memFullErr
	 -120  dirNFErr
	 -121  tmwdoErr
	 -122  badMovErr
	 -123  wrgVolTypErr
	 -124  volGoneErr
	 -1300  fidNotFound
	 -1301  fidExists
	 -1302  notAFileErr
	 -1303  diffVolErr
	 -1304  catChangedErr
	 -1306  sameFileErr
	 -1401  errFSBadFSRef
	 -1402  errFSBadForkName
	 -1403  errFSBadBuffer
	 -1404  errFSBadForkRef
	 -1405  errFSBadInfoBitmap
	 -1406  errFSMissingCatInfo
	 -1407  errFSNotAFolder
	 -1409  errFSForkNotFound
	 -1410  errFSNameTooLong
	 -1411  errFSMissingName
	 -1412  errFSBadPosMode
	 -1413  errFSBadAllocFlags
	 -1417  errFSNoMoreItems
	 -1418  errFSBadItemCount
	 -1419  errFSBadSearchParams
	 -1420  errFSRefsDifferent
	 -1421  errFSForkExists
	 -1422  errFSBadIteratorFlags
	 -1423  errFSIteratorNotFound
	 -1424  errFSIteratorNotSupported
	 -5000  afpAccessDenied
	 -5002  afpBadUAM
	 -5003  afpBadVersNum
	 -5006  afpDenyConflict
	 -5015  afpNoMoreLocks
	 -5016  afpNoServer
	 -5020  afpRangeNotLocked
	 -5021  afpRangeOverlap
	 -5023  afpUserNotAuth
	 -5025  afpObjectTypeErr
	 -5033  afpContainsSharedErr
	 -5034  afpIDNotFound
	 -5035  afpIDExists
	 -5037  afpCatalogChanged
	 -5038  afpSameObjectErr
	 -5039  afpBadIDErr
	 -5042  afpPwdExpiredErr
	 -5043  afpInsideSharedErr
	 -5060  afpBadDirIDType
	 -5061  afpCantMountMoreSrvre
	 -5062  afpAlreadyMounted
	 -5063  afpSameNodeErr
	 ) };

1;
__END__
