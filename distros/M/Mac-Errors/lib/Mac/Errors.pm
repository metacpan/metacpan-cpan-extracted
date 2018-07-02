package Mac::Errors;
use strict;

use warnings;
no warnings;

use base qw(Tie::Scalar);
use vars qw(%MacErrors $MacError);

our $VERSION = '1.192';

use Exporter qw(import);

=encoding utf8

=head1 NAME

Mac::Errors - constants for Mac error codes

=head1 SYNOPSIS

	use Mac::Errors qw(openErr);

	if( $value == openErr ) {
		...
		}

	my $error = $MacErrors{ $symbol };
	# -- OR --
	my $error = $MacErrors{ $number };

	my $symbol = $error->symbol;
	my $number = $error->number;
	my $desc   = $error->description;

	# in MacPerl, $^E is meaningful, and we tie $MacError to it
	use Mac::Errors qw( $MacError );

	open FILE, $foo or die $^E;       # error number
	open FILE, $foo or die $MacError; # gets description from $^E

=head1 DESCRIPTION

The C<%MacErrors> hash indexes error information by the error
number or symbol.  Each value is a C<Mac::Errors> object which
has the symbol, number, and description.

The C<$MacError> scalar performs some tied magic to translate
MacPerl's C<$^E> to the error text. On other platforms, it is
always undef.

=head1 METHODS

=over 4

=item symbol

Returns the symbolic constant, (e.g. openErr)

=item number

Returns the error number, (e.g. -23)

=item description

Returns the error description from MacErrors.h, which may
mean something to you, and may not, (e.g. I/O System Errors).

Descriptions of errors are not unique, and some errors do
not have a description.

=back

=head1 CONSTANTS

All symbolic constants also have a subroutine of the same name.
The subroutine returns the error number.

=cut

our @EXPORT_OK = qw(%MacErrors $MacError);

tie $MacError, __PACKAGE__;

sub TIESCALAR {
	my( $class, $scalar ) = @_;
	return bless \$scalar, $class;
	}

sub FETCH {
	return unless $^O eq 'MacOS';
	my $errno = $^E + 0;
	return $errno unless exists $MacErrors{ $errno };
	return $MacErrors{ $errno }->description;
	}

constants();

sub constants {
	seek DATA, 0, 0; # this reads the entire script
	my $data = do { local $/; <DATA> };
	while( $data =~ m|=item (\w+)(?:\s+([^\n]+))?\n\s+?=cut\s+sub \1 \{ (-?\d+) \}|g ) {
		my( $symbol, $desc, $value ) = ( $1, $2, $3 );
		push @EXPORT_OK, $symbol;

		$desc  ||= $symbol;
		my $array = [ $symbol, $value, $desc ];

		bless $array, __PACKAGE__;

		$MacErrors{$symbol} = $MacErrors{$value} = $array;
		}
	}

sub symbol      { $_[0]->[0] }
sub number      { $_[0]->[1] }
sub description { $_[0]->[2] }

=over 4

=cut

=item paramErr

 error in user parameter list

=cut

sub paramErr { -50 }

=item noHardwareErr

 Sound Manager Error Returns

=cut

sub noHardwareErr { -200 }

=item notEnoughHardwareErr

 Sound Manager Error Returns

=cut

sub notEnoughHardwareErr { -201 }

=item userCanceledErr

=cut

sub userCanceledErr { -128 }

=item qErr

 queue element not found during deletion

=cut

sub qErr { -1 }

=item vTypErr

 invalid queue element

=cut

sub vTypErr { -2 }

=item corErr

 core routine number out of range

=cut

sub corErr { -3 }

=item unimpErr

 unimplemented core routine

=cut

sub unimpErr { -4 }

=item SlpTypeErr

 invalid queue element

=cut

sub SlpTypeErr { -5 }

=item seNoDB

 no debugger installed to handle debugger command

=cut

sub seNoDB { -8 }

=item controlErr

 I/O System Errors

=cut

sub controlErr { -17 }

=item statusErr

 I/O System Errors

=cut

sub statusErr { -18 }

=item readErr

 I/O System Errors

=cut

sub readErr { -19 }

=item writErr

 I/O System Errors

=cut

sub writErr { -20 }

=item badUnitErr

 I/O System Errors

=cut

sub badUnitErr { -21 }

=item unitEmptyErr

 I/O System Errors

=cut

sub unitEmptyErr { -22 }

=item openErr

 I/O System Errors

=cut

sub openErr { -23 }

=item closErr

 I/O System Errors

=cut

sub closErr { -24 }

=item dRemovErr

 tried to remove an open driver

=cut

sub dRemovErr { -25 }

=item abortErr

 IO call aborted by KillIO

=cut

sub abortErr { -27 }

=item iIOAbortErr

 IO abort error (Printing Manager)

=cut

sub iIOAbortErr { -27 }

=item notOpenErr

 Couldn't rd/wr/ctl/sts cause driver not opened

=cut

sub notOpenErr { -28 }

=item unitTblFullErr

 unit table has no more entries

=cut

sub unitTblFullErr { -29 }

=item dceExtErr

 dce extension error

=cut

sub dceExtErr { -30 }

=item slotNumErr

 invalid slot # error

=cut

sub slotNumErr { -360 }

=item gcrOnMFMErr

 gcr format on high density media error

=cut

sub gcrOnMFMErr { -400 }

=item dirFulErr

 Directory full

=cut

sub dirFulErr { -33 }

=item dskFulErr

 disk full

=cut

sub dskFulErr { -34 }

=item nsvErr

 no such volume

=cut

sub nsvErr { -35 }

=item ioErr

 I/O error (bummers)

=cut

sub ioErr { -36 }

=item bdNamErr

 there may be no bad names in the final system!

=cut

sub bdNamErr { -37 }

=item fnOpnErr

 File not open

=cut

sub fnOpnErr { -38 }

=item eofErr

 End of file

=cut

sub eofErr { -39 }

=item posErr

 tried to position to before start of file (r/w)

=cut

sub posErr { -40 }

=item mFulErr

 memory full (open) or file won't fit (load)

=cut

sub mFulErr { -41 }

=item tmfoErr

 too many files open

=cut

sub tmfoErr { -42 }

=item fnfErr

 File not found

=cut

sub fnfErr { -43 }

=item wPrErr

 diskette is write protected.

=cut

sub wPrErr { -44 }

=item vLckdErr

 volume is locked

=cut

sub vLckdErr { -46 }

=item fBsyErr

 File is busy (delete)

=cut

sub fBsyErr { -47 }

=item dupFNErr

 duplicate filename (rename)

=cut

sub dupFNErr { -48 }

=item opWrErr

 file already open with write permission

=cut

sub opWrErr { -49 }

=item rfNumErr

 refnum error

=cut

sub rfNumErr { -51 }

=item gfpErr

 get file position error

=cut

sub gfpErr { -52 }

=item volOffLinErr

 volume not on line error (was Ejected)

=cut

sub volOffLinErr { -53 }

=item permErr

 permissions error (on file open)

=cut

sub permErr { -54 }

=item volOnLinErr

 drive volume already on-line at MountVol

=cut

sub volOnLinErr { -55 }

=item nsDrvErr

 no such drive (tried to mount a bad drive num)

=cut

sub nsDrvErr { -56 }

=item noMacDskErr

 not a mac diskette (sig bytes are wrong)

=cut

sub noMacDskErr { -57 }

=item extFSErr

 volume in question belongs to an external fs

=cut

sub extFSErr { -58 }

=item fsRnErr

 file system internal error:during rename the old entry was deleted but could not be restored.

=cut

sub fsRnErr { -59 }

=item badMDBErr

 bad master directory block

=cut

sub badMDBErr { -60 }

=item wrPermErr

 write permissions error

=cut

sub wrPermErr { -61 }

=item dirNFErr

 Directory not found

=cut

sub dirNFErr { -120 }

=item tmwdoErr

 No free WDCB available

=cut

sub tmwdoErr { -121 }

=item badMovErr

 Move into offspring error

=cut

sub badMovErr { -122 }

=item wrgVolTypErr

 Wrong volume type error [operation not supported for MFS]

=cut

sub wrgVolTypErr { -123 }

=item fidNotFound

 no file thread exists.

=cut

sub fidNotFound { -1300 }

=item fidExists

 file id already exists

=cut

sub fidExists { -1301 }

=item notAFileErr

 directory specified

=cut

sub notAFileErr { -1302 }

=item diffVolErr

 files on different volumes

=cut

sub diffVolErr { -1303 }

=item catChangedErr

 the catalog has been modified

=cut

sub catChangedErr { -1304 }

=item desktopDamagedErr

 desktop database files are corrupted

=cut

sub desktopDamagedErr { -1305 }

=item sameFileErr

 can't exchange a file with itself

=cut

sub sameFileErr { -1306 }

=item badFidErr

 file id is dangling or doesn't match with the file number

=cut

sub badFidErr { -1307 }

=item notARemountErr

 when _Mount allows only remounts and doesn't get one

=cut

sub notARemountErr { -1308 }

=item fileBoundsErr

 file's EOF, offset, mark or size is too big

=cut

sub fileBoundsErr { -1309 }

=item fsDataTooBigErr

 file or volume is too big for system

=cut

sub fsDataTooBigErr { -1310 }

=item volVMBusyErr

 can't eject because volume is in use by VM

=cut

sub volVMBusyErr { -1311 }

=item badFCBErr

 FCBRecPtr is not valid

=cut

sub badFCBErr { -1327 }

=item errFSUnknownCall

 selector is not recognized by this filesystem

=cut

sub errFSUnknownCall { -1400 }

=item errFSBadFSRef

 FSRef parameter is bad

=cut

sub errFSBadFSRef { -1401 }

=item errFSBadForkName

 Fork name parameter is bad

=cut

sub errFSBadForkName { -1402 }

=item errFSBadBuffer

 A buffer parameter was bad

=cut

sub errFSBadBuffer { -1403 }

=item errFSBadForkRef

 A ForkRefNum parameter was bad

=cut

sub errFSBadForkRef { -1404 }

=item errFSBadInfoBitmap

 A CatalogInfoBitmap or VolumeInfoBitmap has reserved or invalid bits set

=cut

sub errFSBadInfoBitmap { -1405 }

=item errFSMissingCatInfo

 A CatalogInfo parameter was NULL

=cut

sub errFSMissingCatInfo { -1406 }

=item errFSNotAFolder

 Expected a folder, got a file

=cut

sub errFSNotAFolder { -1407 }

=item errFSForkNotFound

 Named fork does not exist

=cut

sub errFSForkNotFound { -1409 }

=item errFSNameTooLong

 File/fork name is too long to create/rename

=cut

sub errFSNameTooLong { -1410 }

=item errFSMissingName

 A Unicode name parameter was NULL or nameLength parameter was zero

=cut

sub errFSMissingName { -1411 }

=item errFSBadPosMode

 Newline bits set in positionMode

=cut

sub errFSBadPosMode { -1412 }

=item errFSBadAllocFlags

 Invalid bits set in allocationFlags

=cut

sub errFSBadAllocFlags { -1413 }

=item errFSNoMoreItems

 Iteration ran out of items to return

=cut

sub errFSNoMoreItems { -1417 }

=item errFSBadItemCount

 maximumItems was zero

=cut

sub errFSBadItemCount { -1418 }

=item errFSBadSearchParams

 Something wrong with CatalogSearch searchParams

=cut

sub errFSBadSearchParams { -1419 }

=item errFSRefsDifferent

 FSCompareFSRefs; refs are for different objects

=cut

sub errFSRefsDifferent { -1420 }

=item errFSForkExists

 Named fork already exists.

=cut

sub errFSForkExists { -1421 }

=item errFSBadIteratorFlags

 Flags passed to FSOpenIterator are bad

=cut

sub errFSBadIteratorFlags { -1422 }

=item errFSIteratorNotFound

 Passed FSIterator is not an open iterator

=cut

sub errFSIteratorNotFound { -1423 }

=item errFSIteratorNotSupported

 The iterator's flags or container are not supported by this call

=cut

sub errFSIteratorNotSupported { -1424 }

=item envNotPresent

 returned by glue.

=cut

sub envNotPresent { -5500 }

=item envBadVers

 Version non-positive

=cut

sub envBadVers { -5501 }

=item envVersTooBig

 Version bigger than call can handle

=cut

sub envVersTooBig { -5502 }

=item fontDecError

 error during font declaration

=cut

sub fontDecError { -64 }

=item fontNotDeclared

 font not declared

=cut

sub fontNotDeclared { -65 }

=item fontSubErr

 font substitution occurred

=cut

sub fontSubErr { -66 }

=item fontNotOutlineErr

 bitmap font passed to routine that does outlines only

=cut

sub fontNotOutlineErr { -32615 }

=item firstDskErr

 I/O System Errors

=cut

sub firstDskErr { -84 }

=item lastDskErr

 I/O System Errors

=cut

sub lastDskErr { -64 }

=item noDriveErr

 drive not installed

=cut

sub noDriveErr { -64 }

=item offLinErr

 r/w requested for an off-line drive

=cut

sub offLinErr { -65 }

=item noAdrMkErr

 couldn't find valid addr mark

=cut

sub noAdrMkErr { -67 }

=item dataVerErr

 read verify compare failed

=cut

sub dataVerErr { -68 }

=item badCksmErr

 addr mark checksum didn't check

=cut

sub badCksmErr { -69 }

=item badBtSlpErr

 bad addr mark bit slip nibbles

=cut

sub badBtSlpErr { -70 }

=item noDtaMkErr

 couldn't find a data mark header

=cut

sub noDtaMkErr { -71 }

=item badDCksum

 bad data mark checksum

=cut

sub badDCksum { -72 }

=item badDBtSlp

 bad data mark bit slip nibbles

=cut

sub badDBtSlp { -73 }

=item wrUnderrun

 write underrun occurred

=cut

sub wrUnderrun { -74 }

=item cantStepErr

 step handshake failed

=cut

sub cantStepErr { -75 }

=item tk0BadErr

 track 0 detect doesn't change

=cut

sub tk0BadErr { -76 }

=item initIWMErr

 unable to initialize IWM

=cut

sub initIWMErr { -77 }

=item twoSideErr

 tried to read 2nd side on a 1-sided drive

=cut

sub twoSideErr { -78 }

=item spdAdjErr

 unable to correctly adjust disk speed

=cut

sub spdAdjErr { -79 }

=item seekErr

 track number wrong on address mark

=cut

sub seekErr { -80 }

=item sectNFErr

 sector number never found on a track

=cut

sub sectNFErr { -81 }

=item fmt1Err

 can't find sector 0 after track format

=cut

sub fmt1Err { -82 }

=item fmt2Err

 can't get enough sync

=cut

sub fmt2Err { -83 }

=item verErr

 track failed to verify

=cut

sub verErr { -84 }

=item clkRdErr

 unable to read same clock value twice

=cut

sub clkRdErr { -85 }

=item clkWrErr

 time written did not verify

=cut

sub clkWrErr { -86 }

=item prWrErr

 parameter ram written didn't read-verify

=cut

sub prWrErr { -87 }

=item prInitErr

 InitUtil found the parameter ram uninitialized

=cut

sub prInitErr { -88 }

=item rcvrErr

 SCC receiver error (framing; parity; OR)

=cut

sub rcvrErr { -89 }

=back

=head1 Scrap Manager errors

=over 4

=item noScrapErr

 No scrap exists error

=cut

sub noScrapErr { -100 }

=back

=head1 ENET error codes

=over 4

=item eLenErr

 Length error ddpLenErr

=cut

sub eLenErr { -92 }

=item ddpSktErr

 error in soket number

=cut

sub ddpSktErr { -91 }

=item ddpLenErr

 data length too big

=cut

sub ddpLenErr { -92 }

=item noBridgeErr

 no network bridge for non-local send

=cut

sub noBridgeErr { -93 }

=item lapProtErr

 error in attaching/detaching protocol

=cut

sub lapProtErr { -94 }

=item excessCollsns

 excessive collisions on write

=cut

sub excessCollsns { -95 }

=item portNotPwr

 serial port not currently powered

=cut

sub portNotPwr { -96 }

=item portInUse

 driver Open error code (port is in use)

=cut

sub portInUse { -97 }

=back

=head1 Memory Manager errors

=over 4

=item memROZWarn

 soft error in ROZ

=cut

sub memROZWarn { -99 }

=item memROZError

 hard error in ROZ

=cut

sub memROZError { -99 }

=item memROZErr

 hard error in ROZ

=cut

sub memROZErr { -99 }

=item memFullErr

 Not enough room in heap zone

=cut

sub memFullErr { -108 }

=item nilHandleErr

 Master Pointer was NIL in HandleZone or other

=cut

sub nilHandleErr { -109 }

=item memWZErr

 WhichZone failed (applied to free block)

=cut

sub memWZErr { -111 }

=item memPurErr

 trying to purge a locked or non-purgeable block

=cut

sub memPurErr { -112 }

=item memAdrErr

 address was odd; or out of range

=cut

sub memAdrErr { -110 }

=item memAZErr

 Address in zone check failed

=cut

sub memAZErr { -113 }

=item memPCErr

 Pointer Check failed

=cut

sub memPCErr { -114 }

=item memBCErr

 Block Check failed

=cut

sub memBCErr { -115 }

=item memSCErr

 Size Check failed

=cut

sub memSCErr { -116 }

=back

=head1 Printing Errors

=over 4

=item iMemFullErr

=cut

sub iMemFullErr { -108 }

=item resourceInMemory

 Resource already in memory

=cut

sub resourceInMemory { -188 }

=item writingPastEnd

 Writing past end of file

=cut

sub writingPastEnd { -189 }

=item inputOutOfBounds

 Offset of Count out of bounds

=cut

sub inputOutOfBounds { -190 }

=item resNotFound

 Resource not found

=cut

sub resNotFound { -192 }

=item resFNotFound

 Resource file not found

=cut

sub resFNotFound { -193 }

=item addResFailed

 AddResource failed

=cut

sub addResFailed { -194 }

=item addRefFailed

 AddReference failed

=cut

sub addRefFailed { -195 }

=item rmvResFailed

 RmveResource failed

=cut

sub rmvResFailed { -196 }

=item rmvRefFailed

 RmveReference failed

=cut

sub rmvRefFailed { -197 }

=item resAttrErr

 attribute inconsistent with operation

=cut

sub resAttrErr { -198 }

=item mapReadErr

 map inconsistent with operation

=cut

sub mapReadErr { -199 }

=item CantDecompress

 resource bent ("the bends") - can't decompress a compressed resource

=cut

sub CantDecompress { -186 }

=item badExtResource

 extended resource has a bad format.

=cut

sub badExtResource { -185 }

=item noMemForPictPlaybackErr

=cut

sub noMemForPictPlaybackErr { -145 }

=item rgnOverflowErr

=cut

sub rgnOverflowErr { -147 }

=item rgnTooBigError

=cut

sub rgnTooBigError { -147 }

=item pixMapTooDeepErr

=cut

sub pixMapTooDeepErr { -148 }

=item insufficientStackErr

=cut

sub insufficientStackErr { -149 }

=item cMatchErr

 Color2Index failed to find an index

=cut

sub cMatchErr { -150 }

=item cTempMemErr

 failed to allocate memory for temporary structures

=cut

sub cTempMemErr { -151 }

=item cNoMemErr

 failed to allocate memory for structure

=cut

sub cNoMemErr { -152 }

=item cRangeErr

 range error on colorTable request

=cut

sub cRangeErr { -153 }

=item cProtectErr

 colorTable entry protection violation

=cut

sub cProtectErr { -154 }

=item cDevErr

 invalid type of graphics device

=cut

sub cDevErr { -155 }

=item cResErr

 invalid resolution for MakeITable

=cut

sub cResErr { -156 }

=item cDepthErr

 invalid pixel depth

=cut

sub cDepthErr { -157 }

=item rgnTooBigErr

=cut

sub rgnTooBigErr { -500 }

=item updPixMemErr

 insufficient memory to update a pixmap

=cut

sub updPixMemErr { -125 }

=item pictInfoVersionErr

 wrong version of the PictInfo structure

=cut

sub pictInfoVersionErr { -11000 }

=item pictInfoIDErr

 the internal consistancy check for the PictInfoID is wrong

=cut

sub pictInfoIDErr { -11001 }

=item pictInfoVerbErr

 the passed verb was invalid

=cut

sub pictInfoVerbErr { -11002 }

=item cantLoadPickMethodErr

 unable to load the custom pick proc

=cut

sub cantLoadPickMethodErr { -11003 }

=item colorsRequestedErr

 the number of colors requested was illegal

=cut

sub colorsRequestedErr { -11004 }

=back

=head1 General Errors

=over 4

=item cmProfileError

=cut

sub cmProfileError { -170 }

=item cmMethodError

=cut

sub cmMethodError { -171 }

=item cmMethodNotFound

 CMM not present

=cut

sub cmMethodNotFound { -175 }

=item cmProfileNotFound

 Responder error

=cut

sub cmProfileNotFound { -176 }

=item cmProfilesIdentical

 Profiles the same

=cut

sub cmProfilesIdentical { -177 }

=item cmCantConcatenateError

 Profile can't be concatenated

=cut

sub cmCantConcatenateError { -178 }

=item cmCantXYZ

 CMM cant handle XYZ space

=cut

sub cmCantXYZ { -179 }

=item cmCantDeleteProfile

 Responder error

=cut

sub cmCantDeleteProfile { -180 }

=item cmUnsupportedDataType

 Responder error

=cut

sub cmUnsupportedDataType { -181 }

=back

=head1 Sound Manager errors

=over 4

=item noHardware

 obsolete spelling

=cut

sub noHardware { noHardwareErr }

=item notEnoughHardware

 obsolete spelling

=cut

sub notEnoughHardware { notEnoughHardwareErr }

=item queueFull

 Sound Manager Error Returns

=cut

sub queueFull { -203 }

=item resProblem

 Sound Manager Error Returns

=cut

sub resProblem { -204 }

=item badChannel

 Sound Manager Error Returns

=cut

sub badChannel { -205 }

=item badFormat

 Sound Manager Error Returns

=cut

sub badFormat { -206 }

=item notEnoughBufferSpace

 could not allocate enough memory

=cut

sub notEnoughBufferSpace { -207 }

=item badFileFormat

 was not type AIFF or was of bad format,corrupt

=cut

sub badFileFormat { -208 }

=item channelBusy

 the Channel is being used for a PFD already

=cut

sub channelBusy { -209 }

=item buffersTooSmall

 can not operate in the memory allowed

=cut

sub buffersTooSmall { -210 }

=item channelNotBusy

=cut

sub channelNotBusy { -211 }

=item noMoreRealTime

 not enough CPU cycles left to add another task

=cut

sub noMoreRealTime { -212 }

=item siVBRCompressionNotSupported

 vbr audio compression not supported for this operation

=cut

sub siVBRCompressionNotSupported { -213 }

=item siNoSoundInHardware

 no Sound Input hardware

=cut

sub siNoSoundInHardware { -220 }

=item siBadSoundInDevice

 invalid index passed to SoundInGetIndexedDevice

=cut

sub siBadSoundInDevice { -221 }

=item siNoBufferSpecified

 returned by synchronous SPBRecord if nil buffer passed

=cut

sub siNoBufferSpecified { -222 }

=item siInvalidCompression

 invalid compression type

=cut

sub siInvalidCompression { -223 }

=item siHardDriveTooSlow

 hard drive too slow to record to disk

=cut

sub siHardDriveTooSlow { -224 }

=item siInvalidSampleRate

 invalid sample rate

=cut

sub siInvalidSampleRate { -225 }

=item siInvalidSampleSize

 invalid sample size

=cut

sub siInvalidSampleSize { -226 }

=item siDeviceBusyErr

 input device already in use

=cut

sub siDeviceBusyErr { -227 }

=item siBadDeviceName

 input device could not be opened

=cut

sub siBadDeviceName { -228 }

=item siBadRefNum

 invalid input device reference number

=cut

sub siBadRefNum { -229 }

=item siInputDeviceErr

 input device hardware failure

=cut

sub siInputDeviceErr { -230 }

=item siUnknownInfoType

 invalid info type selector (returned by driver)

=cut

sub siUnknownInfoType { -231 }

=item noSynthFound

=cut

sub noSynthFound { -240 }

=item synthOpenFailed

=cut

sub synthOpenFailed { -241 }

=item synthNotReady

=cut

sub synthNotReady { -242 }

=item bufTooSmall

=cut

sub bufTooSmall { -243 }

=item voiceNotFound

=cut

sub voiceNotFound { -244 }

=item incompatibleVoice

=cut

sub incompatibleVoice { -245 }

=item badDictFormat

=cut

sub badDictFormat { -246 }

=item midiNoClientErr

 no client with that ID found

=cut

sub midiNoClientErr { -250 }

=item midiNoPortErr

 no port with that ID found

=cut

sub midiNoPortErr { -251 }

=item midiTooManyPortsErr

 too many ports already installed in the system

=cut

sub midiTooManyPortsErr { -252 }

=item midiTooManyConsErr

 too many connections made

=cut

sub midiTooManyConsErr { -253 }

=item midiVConnectErr

 pending virtual connection created

=cut

sub midiVConnectErr { -254 }

=item midiVConnectMade

 pending virtual connection resolved

=cut

sub midiVConnectMade { -255 }

=item midiVConnectRmvd

 pending virtual connection removed

=cut

sub midiVConnectRmvd { -256 }

=item midiNoConErr

 no connection exists between specified ports

=cut

sub midiNoConErr { -257 }

=item midiWriteErr

 MIDIWritePacket couldn't write to all connected ports

=cut

sub midiWriteErr { -258 }

=item midiNameLenErr

 name supplied is longer than 31 characters

=cut

sub midiNameLenErr { -259 }

=item midiDupIDErr

 duplicate client ID

=cut

sub midiDupIDErr { -260 }

=item siInitSDTblErr

 slot int dispatch table could not be initialized.

=cut

sub siInitSDTblErr { 1 }

=item siInitVBLQsErr

 VBLqueues for all slots could not be initialized.

=cut

sub siInitVBLQsErr { 2 }

=item siInitSPTblErr

 slot priority table could not be initialized.

=cut

sub siInitSPTblErr { 3 }

=item sdmJTInitErr

 SDM Jump Table could not be initialized.

=cut

sub sdmJTInitErr { 10 }

=item sdmInitErr

 SDM could not be initialized.

=cut

sub sdmInitErr { 11 }

=item sdmSRTInitErr

 Slot Resource Table could not be initialized.

=cut

sub sdmSRTInitErr { 12 }

=item sdmPRAMInitErr

 Slot PRAM could not be initialized.

=cut

sub sdmPRAMInitErr { 13 }

=item smSDMInitErr

 Error; SDM could not be initialized.

=cut

sub smSDMInitErr { -290 }

=item smSRTInitErr

 Error; Slot Resource Table could not be initialized.

=cut

sub smSRTInitErr { -291 }

=item smPRAMInitErr

 Error; Slot Resource Table could not be initialized.

=cut

sub smPRAMInitErr { -292 }

=item smPriInitErr

 Error; Cards could not be initialized.

=cut

sub smPriInitErr { -293 }

=item smEmptySlot

 No card in slot

=cut

sub smEmptySlot { -300 }

=item smCRCFail

 CRC check failed for declaration data

=cut

sub smCRCFail { -301 }

=item smFormatErr

 FHeader Format is not Apple's

=cut

sub smFormatErr { -302 }

=item smRevisionErr

 Wrong revison level

=cut

sub smRevisionErr { -303 }

=item smNoDir

 Directory offset is Nil

=cut

sub smNoDir { -304 }

=item smDisabledSlot

 This slot is disabled (-305 use to be smLWTstBad)

=cut

sub smDisabledSlot { -305 }

=item smResrvErr

 Fatal reserved error. Resreved field <> 0.

=cut

sub smResrvErr { -307 }

=item smUnExBusErr

 Unexpected BusError

=cut

sub smUnExBusErr { -308 }

=item smBLFieldBad

 ByteLanes field was bad.

=cut

sub smBLFieldBad { -309 }

=item smFHBlockRdErr

 Error occurred during _sGetFHeader.

=cut

sub smFHBlockRdErr { -310 }

=item smFHBlkDispErr

 Error occurred during _sDisposePtr (Dispose of FHeader block).

=cut

sub smFHBlkDispErr { -311 }

=item smDisposePErr

 _DisposePointer error

=cut

sub smDisposePErr { -312 }

=item smNoBoardSRsrc

 No Board sResource.

=cut

sub smNoBoardSRsrc { -313 }

=item smGetPRErr

 Error occurred during _sGetPRAMRec (See SIMStatus).

=cut

sub smGetPRErr { -314 }

=item smNoBoardId

 No Board Id.

=cut

sub smNoBoardId { -315 }

=item smInitStatVErr

 The InitStatusV field was negative after primary or secondary init.

=cut

sub smInitStatVErr { -316 }

=item smInitTblVErr

 An error occurred while trying to initialize the Slot Resource Table.

=cut

sub smInitTblVErr { -317 }

=item smNoJmpTbl

 SDM jump table could not be created.

=cut

sub smNoJmpTbl { -318 }

=item smReservedSlot

 slot is reserved, VM should not use this address space.

=cut

sub smReservedSlot { -318 }

=item smBadBoardId

 BoardId was wrong; re-init the PRAM record.

=cut

sub smBadBoardId { -319 }

=item smBusErrTO

 BusError time out.
These errors are logged in the  vendor status field of the sInfo record.

=cut

sub smBusErrTO { -320 }

=item svTempDisable

 Temporarily disable card but run primary init.

=cut

sub svTempDisable { -32768 }

=item svDisabled

 Reserve range -32640 to -32768 for Apple temp disables.

=cut

sub svDisabled { -32640 }

=item smBadRefId

 Reference Id not found in List

=cut

sub smBadRefId { -330 }

=item smBadsList

 Bad sList: Id1 < Id2 < Id3 ...format is not followed.

=cut

sub smBadsList { -331 }

=item smReservedErr

 Reserved field not zero

=cut

sub smReservedErr { -332 }

=item smCPUErr

 Code revision is wrong

=cut

sub smCPUErr { -334 }

=item smsPointerNil

 LPointer is nil From sOffsetData. If this error occurs; check sInfo rec for more information.

=cut

sub smsPointerNil { -335 }

=item smNilsBlockErr

 Nil sBlock error (Dont allocate and try to use a nil sBlock)

=cut

sub smNilsBlockErr { -336 }

=item smSlotOOBErr

 Slot out of bounds error

=cut

sub smSlotOOBErr { -337 }

=item smSelOOBErr

 Selector out of bounds error

=cut

sub smSelOOBErr { -338 }

=item smNewPErr

 _NewPtr error

=cut

sub smNewPErr { -339 }

=item smBlkMoveErr

 _BlockMove error

=cut

sub smBlkMoveErr { -340 }

=item smCkStatusErr

 Status of slot = fail.

=cut

sub smCkStatusErr { -341 }

=item smGetDrvrNamErr

 Error occurred during _sGetDrvrName.

=cut

sub smGetDrvrNamErr { -342 }

=item smDisDrvrNamErr

 Error occurred during _sDisDrvrName.

=cut

sub smDisDrvrNamErr { -343 }

=item smNoMoresRsrcs

 No more sResources

=cut

sub smNoMoresRsrcs { -344 }

=item smsGetDrvrErr

 Error occurred during _sGetDriver.

=cut

sub smsGetDrvrErr { -345 }

=item smBadsPtrErr

 Bad pointer was passed to sCalcsPointer

=cut

sub smBadsPtrErr { -346 }

=item smByteLanesErr

 NumByteLanes was determined to be zero.

=cut

sub smByteLanesErr { -347 }

=item smOffsetErr

 Offset was too big (temporary error

=cut

sub smOffsetErr { -348 }

=item smNoGoodOpens

 No opens were successfull in the loop.

=cut

sub smNoGoodOpens { -349 }

=item smSRTOvrFlErr

 SRT over flow.

=cut

sub smSRTOvrFlErr { -350 }

=back

=head1 Dictionary Manager errors

=over 4

=item notBTree

 The file is not a dictionary.

=cut

sub notBTree { -410 }

=item btNoSpace

 Can't allocate disk space.

=cut

sub btNoSpace { -413 }

=item btDupRecErr

 Record already exists.

=cut

sub btDupRecErr { -414 }

=item btRecNotFnd

 Record cannot be found.

=cut

sub btRecNotFnd { -415 }

=item btKeyLenErr

 Maximum key length is too long or equal to zero.

=cut

sub btKeyLenErr { -416 }

=item btKeyAttrErr

 There is no such a key attribute.

=cut

sub btKeyAttrErr { -417 }

=item unknownInsertModeErr

 There is no such an insert mode.

=cut

sub unknownInsertModeErr { -20000 }

=item recordDataTooBigErr

 The record data is bigger than buffer size (1024 bytes).

=cut

sub recordDataTooBigErr { -20001 }

=item fsmFFSNotFoundErr

 Foreign File system does not exist - new Pack2 could return this error too

=cut

sub fsmFFSNotFoundErr { -431 }

=item fsmBusyFFSErr

 File system is busy, cannot be removed

=cut

sub fsmBusyFFSErr { -432 }

=item fsmBadFFSNameErr

 Name length not 1 <= length <= 31

=cut

sub fsmBadFFSNameErr { -433 }

=item fsmBadFSDLenErr

 FSD size incompatible with current FSM vers

=cut

sub fsmBadFSDLenErr { -434 }

=item fsmDuplicateFSIDErr

 FSID already exists on InstallFS

=cut

sub fsmDuplicateFSIDErr { -435 }

=item fsmBadFSDVersionErr

 FSM version incompatible with FSD

=cut

sub fsmBadFSDVersionErr { -436 }

=item fsmNoAlternateStackErr

 no alternate stack for HFS CI

=cut

sub fsmNoAlternateStackErr { -437 }

=back

=head1 Edition Mgr errors

=over 4

=item editionMgrInitErr

 edition manager not inited by this app

=cut

sub editionMgrInitErr { -450 }

=item badSectionErr

 not a valid SectionRecord

=cut

sub badSectionErr { -451 }

=item notRegisteredSectionErr

 not a registered SectionRecord

=cut

sub notRegisteredSectionErr { -452 }

=item badEditionFileErr

 edition file is corrupt

=cut

sub badEditionFileErr { -453 }

=item badSubPartErr

 can not use sub parts in this release

=cut

sub badSubPartErr { -454 }

=item multiplePublisherWrn

 A Publisher is already registered for that container

=cut

sub multiplePublisherWrn { -460 }

=item containerNotFoundWrn

 could not find editionContainer at this time

=cut

sub containerNotFoundWrn { -461 }

=item containerAlreadyOpenWrn

 container already opened by this section

=cut

sub containerAlreadyOpenWrn { -462 }

=item teScrapSizeErr

 scrap item too big for text edit record

=cut

sub teScrapSizeErr { -501 }

=item hwParamErr

 bad selector for _HWPriv

=cut

sub hwParamErr { -502 }

=back

=head1 Process Manager errors

=over 4

=item procNotFound

 no eligible process with specified descriptor

=cut

sub procNotFound { -600 }

=item memFragErr

 not enough room to launch app w/special requirements

=cut

sub memFragErr { -601 }

=item appModeErr

 memory mode is 32-bit, but app not 32-bit clean

=cut

sub appModeErr { -602 }

=item protocolErr

 app made module calls in improper order

=cut

sub protocolErr { -603 }

=item hardwareConfigErr

 hardware configuration not correct for call

=cut

sub hardwareConfigErr { -604 }

=item appMemFullErr

 application SIZE not big enough for launch

=cut

sub appMemFullErr { -605 }

=item appIsDaemon

 app is BG-only, and launch flags disallow this

=cut

sub appIsDaemon { -606 }

=item bufferIsSmall

 error returns from Post and Accept

=cut

sub bufferIsSmall { -607 }

=item noOutstandingHLE

=cut

sub noOutstandingHLE { -608 }

=item connectionInvalid

=cut

sub connectionInvalid { -609 }

=back

=head1 More Process Manager errors

=over 4

=item wrongApplicationPlatform

 The application could not launch because the required platform is not available

=cut

sub wrongApplicationPlatform { -875 }

=item appVersionTooOld

 The application's creator and version are incompatible with the current version of Mac OS.

=cut

sub appVersionTooOld { -876 }

=item threadTooManyReqsErr

=cut

sub threadTooManyReqsErr { -617 }

=item threadNotFoundErr

=cut

sub threadNotFoundErr { -618 }

=item notEnoughMemoryErr

 insufficient physical memory

=cut

sub notEnoughMemoryErr { -620 }

=item notHeldErr

 specified range of memory is not held

=cut

sub notHeldErr { -621 }

=item cannotMakeContiguousErr

 cannot make specified range contiguous

=cut

sub cannotMakeContiguousErr { -622 }

=item notLockedErr

 specified range of memory is not locked

=cut

sub notLockedErr { -623 }

=item interruptsMaskedErr

 don't call with interrupts masked

=cut

sub interruptsMaskedErr { -624 }

=item cannotDeferErr

 unable to defer additional functions

=cut

sub cannotDeferErr { -625 }

=item vmMorePhysicalThanVirtualErr

 VM could not start because there was more physical memory than virtual memory (bad setting in VM config resource)

=cut

sub vmMorePhysicalThanVirtualErr { -628 }

=item vmKernelMMUInitErr

 VM could not start because VM_MMUInit kernel call failed

=cut

sub vmKernelMMUInitErr { -629 }

=item vmOffErr

 VM was configured off, or command key was held down at boot

=cut

sub vmOffErr { -630 }

=item vmMemLckdErr

 VM could not start because of a lock table conflict (only on non-SuperMario ROMs)

=cut

sub vmMemLckdErr { -631 }

=item vmBadDriver

 VM could not start because the driver was incompatible

=cut

sub vmBadDriver { -632 }

=item vmInvalidBackingFileIDErr

 invalid BackingFileID

=cut

sub vmInvalidBackingFileIDErr { -640 }

=item vmMappingPrivilegesErr

 requested MappingPrivileges cannot be obtained

=cut

sub vmMappingPrivilegesErr { -641 }

=item vmBusyBackingFileErr

 open views found on BackingFile

=cut

sub vmBusyBackingFileErr { -642 }

=item vmNoMoreBackingFilesErr

 no more BackingFiles were found

=cut

sub vmNoMoreBackingFilesErr { -643 }

=item vmInvalidFileViewIDErr

 invalid FileViewID

=cut

sub vmInvalidFileViewIDErr { -644 }

=item vmFileViewAccessErr

 requested FileViewAccess cannot be obtained

=cut

sub vmFileViewAccessErr { -645 }

=item vmNoMoreFileViewsErr

 no more FileViews were found

=cut

sub vmNoMoreFileViewsErr { -646 }

=item vmAddressNotInFileViewErr

 address is not in a FileView

=cut

sub vmAddressNotInFileViewErr { -647 }

=item rcDBNull

=cut

sub rcDBNull { -800 }

=item rcDBValue

=cut

sub rcDBValue { -801 }

=item rcDBError

=cut

sub rcDBError { -802 }

=item rcDBBadType

=cut

sub rcDBBadType { -803 }

=item rcDBBreak

=cut

sub rcDBBreak { -804 }

=item rcDBExec

=cut

sub rcDBExec { -805 }

=item rcDBBadSessID

=cut

sub rcDBBadSessID { -806 }

=item rcDBBadSessNum

 bad session number for DBGetConnInfo

=cut

sub rcDBBadSessNum { -807 }

=item rcDBBadDDEV

 bad ddev specified on DBInit

=cut

sub rcDBBadDDEV { -808 }

=item rcDBAsyncNotSupp

 ddev does not support async calls

=cut

sub rcDBAsyncNotSupp { -809 }

=item rcDBBadAsyncPB

 tried to kill a bad pb

=cut

sub rcDBBadAsyncPB { -810 }

=item rcDBNoHandler

 no app handler for specified data type

=cut

sub rcDBNoHandler { -811 }

=item rcDBWrongVersion

 incompatible versions

=cut

sub rcDBWrongVersion { -812 }

=item hmHelpDisabled

 Show Balloons mode was off, call to routine ignored

=cut

sub hmHelpDisabled { -850 }

=item hmBalloonAborted

 Returned if mouse was moving or mouse wasn't in window port rect

=cut

sub hmBalloonAborted { -853 }

=item hmSameAsLastBalloon

 Returned from HMShowMenuBalloon if menu & item is same as last time

=cut

sub hmSameAsLastBalloon { -854 }

=item hmHelpManagerNotInited

 Returned from HMGetHelpMenuHandle if help menu not setup

=cut

sub hmHelpManagerNotInited { -855 }

=item hmSkippedBalloon

 Returned from calls if helpmsg specified a skip balloon

=cut

sub hmSkippedBalloon { -857 }

=item hmWrongVersion

 Returned if help mgr resource was the wrong version

=cut

sub hmWrongVersion { -858 }

=item hmUnknownHelpType

 Returned if help msg record contained a bad type

=cut

sub hmUnknownHelpType { -859 }

=item hmOperationUnsupported

 Returned from HMShowBalloon call if bad method passed to routine

=cut

sub hmOperationUnsupported { -861 }

=item hmNoBalloonUp

 Returned from HMRemoveBalloon if no balloon was visible when call was made

=cut

sub hmNoBalloonUp { -862 }

=back

=head1 PPC errors

=over 4

=item notInitErr

 PPCToolBox not initialized

=cut

sub notInitErr { -900 }

=item nameTypeErr

 Invalid or inappropriate locationKindSelector in locationName

=cut

sub nameTypeErr { -902 }

=item noPortErr

 Unable to open port or bad portRefNum.  If you're calling
AESend, this is because your application does not have

=cut

sub noPortErr { -903 }

=item noGlobalsErr

 The system is hosed, better re-boot

=cut

sub noGlobalsErr { -904 }

=item localOnlyErr

 Network activity is currently disabled

=cut

sub localOnlyErr { -905 }

=item destPortErr

 Port does not exist at destination

=cut

sub destPortErr { -906 }

=item sessTableErr

 Out of session tables, try again later

=cut

sub sessTableErr { -907 }

=item noSessionErr

 Invalid session reference number

=cut

sub noSessionErr { -908 }

=item badReqErr

 bad parameter or invalid state for operation

=cut

sub badReqErr { -909 }

=item portNameExistsErr

 port is already open (perhaps in another app)

=cut

sub portNameExistsErr { -910 }

=item noUserNameErr

 user name unknown on destination machine

=cut

sub noUserNameErr { -911 }

=item userRejectErr

 Destination rejected the session request

=cut

sub userRejectErr { -912 }

=item noMachineNameErr

 user hasn't named his Macintosh in the Network Setup Control Panel

=cut

sub noMachineNameErr { -913 }

=item noToolboxNameErr

 A system resource is missing, not too likely

=cut

sub noToolboxNameErr { -914 }

=item noResponseErr

 unable to contact destination

=cut

sub noResponseErr { -915 }

=item portClosedErr

 port was closed

=cut

sub portClosedErr { -916 }

=item sessClosedErr

 session was closed

=cut

sub sessClosedErr { -917 }

=item badPortNameErr

 PPCPortRec malformed

=cut

sub badPortNameErr { -919 }

=item noDefaultUserErr

 user hasn't typed in owners name in Network Setup Control Pannel

=cut

sub noDefaultUserErr { -922 }

=item notLoggedInErr

 The default userRefNum does not yet exist

=cut

sub notLoggedInErr { -923 }

=item noUserRefErr

 unable to create a new userRefNum

=cut

sub noUserRefErr { -924 }

=item networkErr

 An error has occurred in the network, not too likely

=cut

sub networkErr { -925 }

=item noInformErr

 PPCStart failed because destination did not have inform pending

=cut

sub noInformErr { -926 }

=item authFailErr

 unable to authenticate user at destination

=cut

sub authFailErr { -927 }

=item noUserRecErr

 Invalid user reference number

=cut

sub noUserRecErr { -928 }

=item badServiceMethodErr

 illegal service type, or not supported

=cut

sub badServiceMethodErr { -930 }

=item badLocNameErr

 location name malformed

=cut

sub badLocNameErr { -931 }

=back

=head1 Font Mgr errors

=over 4

=item kFMIterationCompleted

=cut

sub kFMIterationCompleted { -980 }

=item kFMInvalidFontFamilyErr

=cut

sub kFMInvalidFontFamilyErr { -981 }

=item kFMInvalidFontErr

=cut

sub kFMInvalidFontErr { -982 }

=item kFMIterationScopeModifiedErr

=cut

sub kFMIterationScopeModifiedErr { -983 }

=item kFMFontTableAccessErr

=cut

sub kFMFontTableAccessErr { -984 }

=item nbpBuffOvr

 Buffer overflow in LookupName

=cut

sub nbpBuffOvr { -1024 }

=item nbpNoConfirm

=cut

sub nbpNoConfirm { -1025 }

=item nbpConfDiff

 Name confirmed at different socket

=cut

sub nbpConfDiff { -1026 }

=item nbpDuplicate

 Duplicate name exists already

=cut

sub nbpDuplicate { -1027 }

=item nbpNotFound

 Name not found on remove

=cut

sub nbpNotFound { -1028 }

=item aspBadVersNum

 Server cannot support this ASP version

=cut

sub aspBadVersNum { -1066 }

=item aspBufTooSmall

 Buffer too small

=cut

sub aspBufTooSmall { -1067 }

=item aspNoMoreSess

 No more sessions on server

=cut

sub aspNoMoreSess { -1068 }

=item aspNoServers

 No servers at that address

=cut

sub aspNoServers { -1069 }

=item aspParamErr

 Parameter error

=cut

sub aspParamErr { -1070 }

=item aspServerBusy

 Server cannot open another session

=cut

sub aspServerBusy { -1071 }

=item aspSessClosed

 Session closed

=cut

sub aspSessClosed { -1072 }

=item aspSizeErr

 Command block too big

=cut

sub aspSizeErr { -1073 }

=item aspTooMany

 Too many clients (server error)

=cut

sub aspTooMany { -1074 }

=item reqFailed

=cut

sub reqFailed { -1096 }

=item tooManyReqs

=cut

sub tooManyReqs { -1097 }

=item tooManySkts

=cut

sub tooManySkts { -1098 }

=item badATPSkt

=cut

sub badATPSkt { -1099 }

=item badBuffNum

=cut

sub badBuffNum { -1100 }

=item noRelErr

=cut

sub noRelErr { -1101 }

=item cbNotFound

=cut

sub cbNotFound { -1102 }

=item noSendResp

=cut

sub noSendResp { -1103 }

=item noDataArea

=cut

sub noDataArea { -1104 }

=back

=head1 driver control ioResults

=over 4

=item errRefNum

 bad connection refNum

=cut

sub errRefNum { -1280 }

=item errAborted

 control call was aborted

=cut

sub errAborted { -1279 }

=item errState

 bad connection state for this operation

=cut

sub errState { -1278 }

=item errOpening

 open connection request failed

=cut

sub errOpening { -1277 }

=item errAttention

 attention message too long

=cut

sub errAttention { -1276 }

=item errFwdReset

 read terminated by forward reset

=cut

sub errFwdReset { -1275 }

=item errDSPQueueSize

 DSP Read/Write Queue Too small

=cut

sub errDSPQueueSize { -1274 }

=back

=head1 Apple event manager error messages

=over 4

=item errAECoercionFail

 bad parameter data or unable to coerce the data supplied

=cut

sub errAECoercionFail { -1700 }

=item errAEDescNotFound

=cut

sub errAEDescNotFound { -1701 }

=item errAECorruptData

=cut

sub errAECorruptData { -1702 }

=item errAEWrongDataType

=cut

sub errAEWrongDataType { -1703 }

=item errAENotAEDesc

=cut

sub errAENotAEDesc { -1704 }

=item errAEBadListItem

 the specified list item does not exist

=cut

sub errAEBadListItem { -1705 }

=item errAENewerVersion

 need newer version of the AppleEvent manager

=cut

sub errAENewerVersion { -1706 }

=item errAENotAppleEvent

 the event is not in AppleEvent format

=cut

sub errAENotAppleEvent { -1707 }

=item errAEEventNotHandled

 the AppleEvent was not handled by any handler

=cut

sub errAEEventNotHandled { -1708 }

=item errAEReplyNotValid

 AEResetTimer was passed an invalid reply parameter

=cut

sub errAEReplyNotValid { -1709 }

=item errAEUnknownSendMode

 mode wasn't NoReply, WaitReply, or QueueReply or Interaction level is unknown

=cut

sub errAEUnknownSendMode { -1710 }

=item errAEWaitCanceled

 in AESend, the user cancelled out of wait loop for reply or receipt

=cut

sub errAEWaitCanceled { -1711 }

=item errAETimeout

 the AppleEvent timed out

=cut

sub errAETimeout { -1712 }

=item errAENoUserInteraction

 no user interaction is allowed

=cut

sub errAENoUserInteraction { -1713 }

=item errAENotASpecialFunction

 there is no special function for/with this keyword

=cut

sub errAENotASpecialFunction { -1714 }

=item errAEParamMissed

 a required parameter was not accessed

=cut

sub errAEParamMissed { -1715 }

=item errAEUnknownAddressType

 the target address type is not known

=cut

sub errAEUnknownAddressType { -1716 }

=item errAEHandlerNotFound

 no handler in the dispatch tables fits the parameters to AEGetEventHandler or AEGetCoercionHandler

=cut

sub errAEHandlerNotFound { -1717 }

=item errAEReplyNotArrived

 the contents of the reply you are accessing have not arrived yet

=cut

sub errAEReplyNotArrived { -1718 }

=item errAEIllegalIndex

 index is out of range in a put operation

=cut

sub errAEIllegalIndex { -1719 }

=item errAEImpossibleRange

 A range like 3rd to 2nd, or 1st to all.

=cut

sub errAEImpossibleRange { -1720 }

=item errAEWrongNumberArgs

 Logical op kAENOT used with other than 1 term

=cut

sub errAEWrongNumberArgs { -1721 }

=item errAEAccessorNotFound

 Accessor proc matching wantClass and containerType or wildcards not found

=cut

sub errAEAccessorNotFound { -1723 }

=item errAENoSuchLogical

 Something other than AND, OR, or NOT

=cut

sub errAENoSuchLogical { -1725 }

=item errAEBadTestKey

 Test is neither typeLogicalDescriptor nor typeCompDescriptor

=cut

sub errAEBadTestKey { -1726 }

=item errAENotAnObjSpec

 Param to AEResolve not of type 'obj '

=cut

sub errAENotAnObjSpec { -1727 }

=item errAENoSuchObject

 e.g.,: specifier asked for the 3rd, but there are only 2. Basically, this indicates a run-time resolution error.

=cut

sub errAENoSuchObject { -1728 }

=item errAENegativeCount

 CountProc returned negative value

=cut

sub errAENegativeCount { -1729 }

=item errAEEmptyListContainer

 Attempt to pass empty list as container to accessor

=cut

sub errAEEmptyListContainer { -1730 }

=item errAEUnknownObjectType

 available only in version 1.0.1 or greater

=cut

sub errAEUnknownObjectType { -1731 }

=item errAERecordingIsAlreadyOn

 available only in version 1.0.1 or greater

=cut

sub errAERecordingIsAlreadyOn { -1732 }

=item errAEReceiveTerminate

 break out of all levels of AEReceive to the topmost (1.1 or greater)

=cut

sub errAEReceiveTerminate { -1733 }

=item errAEReceiveEscapeCurrent

 break out of only lowest level of AEReceive (1.1 or greater)

=cut

sub errAEReceiveEscapeCurrent { -1734 }

=item errAEEventFiltered

 event has been filtered, and should not be propogated (1.1 or greater)

=cut

sub errAEEventFiltered { -1735 }

=item errAEDuplicateHandler

 attempt to install handler in table for identical class and id (1.1 or greater)

=cut

sub errAEDuplicateHandler { -1736 }

=item errAEStreamBadNesting

 nesting violation while streaming

=cut

sub errAEStreamBadNesting { -1737 }

=item errAEStreamAlreadyConverted

 attempt to convert a stream that has already been converted

=cut

sub errAEStreamAlreadyConverted { -1738 }

=item errAEDescIsNull

 attempting to perform an invalid operation on a null descriptor

=cut

sub errAEDescIsNull { -1739 }

=item errAEBuildSyntaxError

 AEBuildDesc and friends detected a syntax error

=cut

sub errAEBuildSyntaxError { -1740 }

=item errOSASystemError

=cut

sub errOSASystemError { -1750 }

=item errOSAInvalidID

=cut

sub errOSAInvalidID { -1751 }

=item errOSABadStorageType

=cut

sub errOSABadStorageType { -1752 }

=item errOSAScriptError

=cut

sub errOSAScriptError { -1753 }

=item errOSABadSelector

=cut

sub errOSABadSelector { -1754 }

=item errOSASourceNotAvailable

=cut

sub errOSASourceNotAvailable { -1756 }

=item errOSANoSuchDialect

=cut

sub errOSANoSuchDialect { -1757 }

=item errOSADataFormatObsolete

=cut

sub errOSADataFormatObsolete { -1758 }

=item errOSADataFormatTooNew

=cut

sub errOSADataFormatTooNew { -1759 }

=item errOSACorruptData

=cut

sub errOSACorruptData { errAECorruptData }

=item errOSARecordingIsAlreadyOn

=cut

sub errOSARecordingIsAlreadyOn { errAERecordingIsAlreadyOn }

=item errOSAComponentMismatch

 Parameters are from 2 different components

=cut

sub errOSAComponentMismatch { -1761 }

=back

=head1 AppleEvent error definitions

=over 4

=item errOffsetInvalid

=cut

sub errOffsetInvalid { -1800 }

=item errOffsetIsOutsideOfView

=cut

sub errOffsetIsOutsideOfView { -1801 }

=item errTopOfDocument

=cut

sub errTopOfDocument { -1810 }

=item errTopOfBody

=cut

sub errTopOfBody { -1811 }

=item errEndOfDocument

=cut

sub errEndOfDocument { -1812 }

=back

=head1 Drag Manager error codes

=over 4

=item badDragRefErr

 unknown drag reference

=cut

sub badDragRefErr { -1850 }

=item badDragItemErr

 unknown drag item reference

=cut

sub badDragItemErr { -1851 }

=item badDragFlavorErr

 unknown flavor type

=cut

sub badDragFlavorErr { -1852 }

=item duplicateFlavorErr

 flavor type already exists

=cut

sub duplicateFlavorErr { -1853 }

=item cantGetFlavorErr

 error while trying to get flavor data

=cut

sub cantGetFlavorErr { -1854 }

=item duplicateHandlerErr

 handler already exists

=cut

sub duplicateHandlerErr { -1855 }

=item handlerNotFoundErr

 handler not found

=cut

sub handlerNotFoundErr { -1856 }

=item dragNotAcceptedErr

 drag was not accepted by receiver

=cut

sub dragNotAcceptedErr { -1857 }

=item unsupportedForPlatformErr

 call is for PowerPC only

=cut

sub unsupportedForPlatformErr { -1858 }

=item noSuitableDisplaysErr

 no displays support translucency

=cut

sub noSuitableDisplaysErr { -1859 }

=item badImageRgnErr

 bad translucent image region

=cut

sub badImageRgnErr { -1860 }

=item badImageErr

 bad translucent image PixMap

=cut

sub badImageErr { -1861 }

=back

=head1 QuickTime errors

=over 4

=item couldNotResolveDataRef

=cut

sub couldNotResolveDataRef { -2000 }

=item badImageDescription

=cut

sub badImageDescription { -2001 }

=item badPublicMovieAtom

=cut

sub badPublicMovieAtom { -2002 }

=item cantFindHandler

=cut

sub cantFindHandler { -2003 }

=item cantOpenHandler

=cut

sub cantOpenHandler { -2004 }

=item badComponentType

=cut

sub badComponentType { -2005 }

=item noMediaHandler

=cut

sub noMediaHandler { -2006 }

=item noDataHandler

=cut

sub noDataHandler { -2007 }

=item invalidMedia

=cut

sub invalidMedia { -2008 }

=item invalidTrack

=cut

sub invalidTrack { -2009 }

=item invalidMovie

=cut

sub invalidMovie { -2010 }

=item invalidSampleTable

=cut

sub invalidSampleTable { -2011 }

=item invalidDataRef

=cut

sub invalidDataRef { -2012 }

=item invalidHandler

=cut

sub invalidHandler { -2013 }

=item invalidDuration

=cut

sub invalidDuration { -2014 }

=item invalidTime

=cut

sub invalidTime { -2015 }

=item cantPutPublicMovieAtom

=cut

sub cantPutPublicMovieAtom { -2016 }

=item badEditList

=cut

sub badEditList { -2017 }

=item mediaTypesDontMatch

=cut

sub mediaTypesDontMatch { -2018 }

=item progressProcAborted

=cut

sub progressProcAborted { -2019 }

=item movieToolboxUninitialized

=cut

sub movieToolboxUninitialized { -2020 }

=item noRecordOfApp

 replica

=cut

sub noRecordOfApp { movieToolboxUninitialized }

=item wfFileNotFound

=cut

sub wfFileNotFound { -2021 }

=item cantCreateSingleForkFile

 happens when file already exists

=cut

sub cantCreateSingleForkFile { -2022 }

=item invalidEditState

=cut

sub invalidEditState { -2023 }

=item nonMatchingEditState

=cut

sub nonMatchingEditState { -2024 }

=item staleEditState

=cut

sub staleEditState { -2025 }

=item userDataItemNotFound

=cut

sub userDataItemNotFound { -2026 }

=item maxSizeToGrowTooSmall

=cut

sub maxSizeToGrowTooSmall { -2027 }

=item badTrackIndex

=cut

sub badTrackIndex { -2028 }

=item trackIDNotFound

=cut

sub trackIDNotFound { -2029 }

=item trackNotInMovie

=cut

sub trackNotInMovie { -2030 }

=item timeNotInTrack

=cut

sub timeNotInTrack { -2031 }

=item timeNotInMedia

=cut

sub timeNotInMedia { -2032 }

=item badEditIndex

=cut

sub badEditIndex { -2033 }

=item internalQuickTimeError

=cut

sub internalQuickTimeError { -2034 }

=item cantEnableTrack

=cut

sub cantEnableTrack { -2035 }

=item invalidRect

=cut

sub invalidRect { -2036 }

=item invalidSampleNum

=cut

sub invalidSampleNum { -2037 }

=item invalidChunkNum

=cut

sub invalidChunkNum { -2038 }

=item invalidSampleDescIndex

=cut

sub invalidSampleDescIndex { -2039 }

=item invalidChunkCache

=cut

sub invalidChunkCache { -2040 }

=item invalidSampleDescription

=cut

sub invalidSampleDescription { -2041 }

=item dataNotOpenForRead

=cut

sub dataNotOpenForRead { -2042 }

=item dataNotOpenForWrite

=cut

sub dataNotOpenForWrite { -2043 }

=item dataAlreadyOpenForWrite

=cut

sub dataAlreadyOpenForWrite { -2044 }

=item dataAlreadyClosed

=cut

sub dataAlreadyClosed { -2045 }

=item endOfDataReached

=cut

sub endOfDataReached { -2046 }

=item dataNoDataRef

=cut

sub dataNoDataRef { -2047 }

=item noMovieFound

=cut

sub noMovieFound { -2048 }

=item invalidDataRefContainer

=cut

sub invalidDataRefContainer { -2049 }

=item badDataRefIndex

=cut

sub badDataRefIndex { -2050 }

=item noDefaultDataRef

=cut

sub noDefaultDataRef { -2051 }

=item couldNotUseAnExistingSample

=cut

sub couldNotUseAnExistingSample { -2052 }

=item featureUnsupported

=cut

sub featureUnsupported { -2053 }

=item noVideoTrackInMovieErr

 QT for Windows error

=cut

sub noVideoTrackInMovieErr { -2054 }

=item noSoundTrackInMovieErr

 QT for Windows error

=cut

sub noSoundTrackInMovieErr { -2055 }

=item soundSupportNotAvailableErr

 QT for Windows error

=cut

sub soundSupportNotAvailableErr { -2056 }

=item unsupportedAuxiliaryImportData

=cut

sub unsupportedAuxiliaryImportData { -2057 }

=item auxiliaryExportDataUnavailable

=cut

sub auxiliaryExportDataUnavailable { -2058 }

=item samplesAlreadyInMediaErr

=cut

sub samplesAlreadyInMediaErr { -2059 }

=item noSourceTreeFoundErr

=cut

sub noSourceTreeFoundErr { -2060 }

=item sourceNotFoundErr

=cut

sub sourceNotFoundErr { -2061 }

=item movieTextNotFoundErr

=cut

sub movieTextNotFoundErr { -2062 }

=item missingRequiredParameterErr

=cut

sub missingRequiredParameterErr { -2063 }

=item invalidSpriteWorldPropertyErr

=cut

sub invalidSpriteWorldPropertyErr { -2064 }

=item invalidSpritePropertyErr

=cut

sub invalidSpritePropertyErr { -2065 }

=item gWorldsNotSameDepthAndSizeErr

=cut

sub gWorldsNotSameDepthAndSizeErr { -2066 }

=item invalidSpriteIndexErr

=cut

sub invalidSpriteIndexErr { -2067 }

=item invalidImageIndexErr

=cut

sub invalidImageIndexErr { -2068 }

=item internalComponentErr

=cut

sub internalComponentErr { -2070 }

=item notImplementedMusicOSErr

=cut

sub notImplementedMusicOSErr { -2071 }

=item cantSendToSynthesizerOSErr

=cut

sub cantSendToSynthesizerOSErr { -2072 }

=item cantReceiveFromSynthesizerOSErr

=cut

sub cantReceiveFromSynthesizerOSErr { -2073 }

=item illegalVoiceAllocationOSErr

=cut

sub illegalVoiceAllocationOSErr { -2074 }

=item illegalPartOSErr

=cut

sub illegalPartOSErr { -2075 }

=item illegalChannelOSErr

=cut

sub illegalChannelOSErr { -2076 }

=item illegalKnobOSErr

=cut

sub illegalKnobOSErr { -2077 }

=item illegalKnobValueOSErr

=cut

sub illegalKnobValueOSErr { -2078 }

=item illegalInstrumentOSErr

=cut

sub illegalInstrumentOSErr { -2079 }

=item illegalControllerOSErr

=cut

sub illegalControllerOSErr { -2080 }

=item midiManagerAbsentOSErr

=cut

sub midiManagerAbsentOSErr { -2081 }

=item synthesizerNotRespondingOSErr

=cut

sub synthesizerNotRespondingOSErr { -2082 }

=item synthesizerOSErr

=cut

sub synthesizerOSErr { -2083 }

=item illegalNoteChannelOSErr

=cut

sub illegalNoteChannelOSErr { -2084 }

=item noteChannelNotAllocatedOSErr

=cut

sub noteChannelNotAllocatedOSErr { -2085 }

=item tunePlayerFullOSErr

=cut

sub tunePlayerFullOSErr { -2086 }

=item tuneParseOSErr

=cut

sub tuneParseOSErr { -2087 }

=item noExportProcAvailableErr

=cut

sub noExportProcAvailableErr { -2089 }

=item componentDllLoadErr

 Windows specific errors (when component is loading)

=cut

sub componentDllLoadErr { -2091 }

=item componentDllEntryNotFoundErr

 Windows specific errors (when component is loading)

=cut

sub componentDllEntryNotFoundErr { -2092 }

=item qtmlDllLoadErr

 Windows specific errors (when qtml is loading)

=cut

sub qtmlDllLoadErr { -2093 }

=item qtmlDllEntryNotFoundErr

 Windows specific errors (when qtml is loading)

=cut

sub qtmlDllEntryNotFoundErr { -2094 }

=item qtmlUninitialized

=cut

sub qtmlUninitialized { -2095 }

=item unsupportedOSErr

=cut

sub unsupportedOSErr { -2096 }

=item cannotFindAtomErr

=cut

sub cannotFindAtomErr { -2101 }

=item notLeafAtomErr

=cut

sub notLeafAtomErr { -2102 }

=item atomsNotOfSameTypeErr

=cut

sub atomsNotOfSameTypeErr { -2103 }

=item atomIndexInvalidErr

=cut

sub atomIndexInvalidErr { -2104 }

=item duplicateAtomTypeAndIDErr

=cut

sub duplicateAtomTypeAndIDErr { -2105 }

=item invalidAtomErr

=cut

sub invalidAtomErr { -2106 }

=item invalidAtomContainerErr

=cut

sub invalidAtomContainerErr { -2107 }

=item invalidAtomTypeErr

=cut

sub invalidAtomTypeErr { -2108 }

=item cannotBeLeafAtomErr

=cut

sub cannotBeLeafAtomErr { -2109 }

=item pathTooLongErr

=cut

sub pathTooLongErr { -2110 }

=item emptyPathErr

=cut

sub emptyPathErr { -2111 }

=item noPathMappingErr

=cut

sub noPathMappingErr { -2112 }

=item pathNotVerifiedErr

=cut

sub pathNotVerifiedErr { -2113 }

=item unknownFormatErr

=cut

sub unknownFormatErr { -2114 }

=item wackBadFileErr

=cut

sub wackBadFileErr { -2115 }

=item wackForkNotFoundErr

=cut

sub wackForkNotFoundErr { -2116 }

=item wackBadMetaDataErr

=cut

sub wackBadMetaDataErr { -2117 }

=item qfcbNotFoundErr

=cut

sub qfcbNotFoundErr { -2118 }

=item qfcbNotCreatedErr

=cut

sub qfcbNotCreatedErr { -2119 }

=item AAPNotCreatedErr

=cut

sub AAPNotCreatedErr { -2120 }

=item AAPNotFoundErr

=cut

sub AAPNotFoundErr { -2121 }

=item ASDBadHeaderErr

=cut

sub ASDBadHeaderErr { -2122 }

=item ASDBadForkErr

=cut

sub ASDBadForkErr { -2123 }

=item ASDEntryNotFoundErr

=cut

sub ASDEntryNotFoundErr { -2124 }

=item fileOffsetTooBigErr

=cut

sub fileOffsetTooBigErr { -2125 }

=item notAllowedToSaveMovieErr

=cut

sub notAllowedToSaveMovieErr { -2126 }

=item qtNetworkAlreadyAllocatedErr

=cut

sub qtNetworkAlreadyAllocatedErr { -2127 }

=item urlDataHHTTPProtocolErr

=cut

sub urlDataHHTTPProtocolErr { -2129 }

=item urlDataHHTTPNoNetDriverErr

=cut

sub urlDataHHTTPNoNetDriverErr { -2130 }

=item urlDataHHTTPURLErr

=cut

sub urlDataHHTTPURLErr { -2131 }

=item urlDataHHTTPRedirectErr

=cut

sub urlDataHHTTPRedirectErr { -2132 }

=item urlDataHFTPProtocolErr

=cut

sub urlDataHFTPProtocolErr { -2133 }

=item urlDataHFTPShutdownErr

=cut

sub urlDataHFTPShutdownErr { -2134 }

=item urlDataHFTPBadUserErr

=cut

sub urlDataHFTPBadUserErr { -2135 }

=item urlDataHFTPBadPasswordErr

=cut

sub urlDataHFTPBadPasswordErr { -2136 }

=item urlDataHFTPServerErr

=cut

sub urlDataHFTPServerErr { -2137 }

=item urlDataHFTPDataConnectionErr

=cut

sub urlDataHFTPDataConnectionErr { -2138 }

=item urlDataHFTPNoDirectoryErr

=cut

sub urlDataHFTPNoDirectoryErr { -2139 }

=item urlDataHFTPQuotaErr

=cut

sub urlDataHFTPQuotaErr { -2140 }

=item urlDataHFTPPermissionsErr

=cut

sub urlDataHFTPPermissionsErr { -2141 }

=item urlDataHFTPFilenameErr

=cut

sub urlDataHFTPFilenameErr { -2142 }

=item urlDataHFTPNoNetDriverErr

=cut

sub urlDataHFTPNoNetDriverErr { -2143 }

=item urlDataHFTPBadNameListErr

=cut

sub urlDataHFTPBadNameListErr { -2144 }

=item urlDataHFTPNeedPasswordErr

=cut

sub urlDataHFTPNeedPasswordErr { -2145 }

=item urlDataHFTPNoPasswordErr

=cut

sub urlDataHFTPNoPasswordErr { -2146 }

=item urlDataHFTPServerDisconnectedErr

=cut

sub urlDataHFTPServerDisconnectedErr { -2147 }

=item urlDataHFTPURLErr

=cut

sub urlDataHFTPURLErr { -2148 }

=item notEnoughDataErr

=cut

sub notEnoughDataErr { -2149 }

=item qtActionNotHandledErr

=cut

sub qtActionNotHandledErr { -2157 }

=item qtXMLParseErr

=cut

sub qtXMLParseErr { -2158 }

=item digiUnimpErr

 feature unimplemented

=cut

sub digiUnimpErr { -2201 }

=item qtParamErr

 bad input parameter (out of range, etc)

=cut

sub qtParamErr { -2202 }

=item matrixErr

 bad matrix, digitizer did nothing

=cut

sub matrixErr { -2203 }

=item notExactMatrixErr

 warning of bad matrix, digitizer did its best

=cut

sub notExactMatrixErr { -2204 }

=item noMoreKeyColorsErr

 all key indexes in use

=cut

sub noMoreKeyColorsErr { -2205 }

=item notExactSizeErr

 Can't do exact size requested

=cut

sub notExactSizeErr { -2206 }

=item badDepthErr

 Can't digitize into this depth

=cut

sub badDepthErr { -2207 }

=item noDMAErr

 Can't do DMA digitizing (i.e. can't go to requested dest

=cut

sub noDMAErr { -2208 }

=back

=head1 Kernel Error Codes

=over 4

=item kernelIncompleteErr

=cut

sub kernelIncompleteErr { -2401 }

=item kernelCanceledErr

=cut

sub kernelCanceledErr { -2402 }

=item kernelOptionsErr

=cut

sub kernelOptionsErr { -2403 }

=item kernelPrivilegeErr

=cut

sub kernelPrivilegeErr { -2404 }

=item kernelUnsupportedErr

=cut

sub kernelUnsupportedErr { -2405 }

=item kernelObjectExistsErr

=cut

sub kernelObjectExistsErr { -2406 }

=item kernelWritePermissionErr

=cut

sub kernelWritePermissionErr { -2407 }

=item kernelReadPermissionErr

=cut

sub kernelReadPermissionErr { -2408 }

=item kernelExecutePermissionErr

=cut

sub kernelExecutePermissionErr { -2409 }

=item kernelDeletePermissionErr

=cut

sub kernelDeletePermissionErr { -2410 }

=item kernelExecutionLevelErr

=cut

sub kernelExecutionLevelErr { -2411 }

=item kernelAttributeErr

=cut

sub kernelAttributeErr { -2412 }

=item kernelAsyncSendLimitErr

=cut

sub kernelAsyncSendLimitErr { -2413 }

=item kernelAsyncReceiveLimitErr

=cut

sub kernelAsyncReceiveLimitErr { -2414 }

=item kernelTimeoutErr

=cut

sub kernelTimeoutErr { -2415 }

=item kernelInUseErr

=cut

sub kernelInUseErr { -2416 }

=item kernelTerminatedErr

=cut

sub kernelTerminatedErr { -2417 }

=item kernelExceptionErr

=cut

sub kernelExceptionErr { -2418 }

=item kernelIDErr

=cut

sub kernelIDErr { -2419 }

=item kernelAlreadyFreeErr

=cut

sub kernelAlreadyFreeErr { -2421 }

=item kernelReturnValueErr

=cut

sub kernelReturnValueErr { -2422 }

=back

=head1 Text Services Mgr error codes

=over 4

=item tsmComponentNoErr

 component result = no error

=cut

sub tsmComponentNoErr { 0 }

=item tsmUnsupScriptLanguageErr

=cut

sub tsmUnsupScriptLanguageErr { -2500 }

=item tsmInputMethodNotFoundErr

=cut

sub tsmInputMethodNotFoundErr { -2501 }

=item tsmNotAnAppErr

 not an application error

=cut

sub tsmNotAnAppErr { -2502 }

=item tsmAlreadyRegisteredErr

 want to register again error

=cut

sub tsmAlreadyRegisteredErr { -2503 }

=item tsmNeverRegisteredErr

 app never registered error (not TSM aware)

=cut

sub tsmNeverRegisteredErr { -2504 }

=item tsmInvalidDocIDErr

 invalid TSM documentation id

=cut

sub tsmInvalidDocIDErr { -2505 }

=item tsmTSMDocBusyErr

 document is still active

=cut

sub tsmTSMDocBusyErr { -2506 }

=item tsmDocNotActiveErr

 document is NOT active

=cut

sub tsmDocNotActiveErr { -2507 }

=item tsmNoOpenTSErr

 no open text service

=cut

sub tsmNoOpenTSErr { -2508 }

=item tsmCantOpenComponentErr

 can't open the component

=cut

sub tsmCantOpenComponentErr { -2509 }

=item tsmTextServiceNotFoundErr

 no text service found

=cut

sub tsmTextServiceNotFoundErr { -2510 }

=item tsmDocumentOpenErr

 there are open documents

=cut

sub tsmDocumentOpenErr { -2511 }

=item tsmUseInputWindowErr

 not TSM aware because we are using input window

=cut

sub tsmUseInputWindowErr { -2512 }

=item tsmTSHasNoMenuErr

 the text service has no menu

=cut

sub tsmTSHasNoMenuErr { -2513 }

=item tsmTSNotOpenErr

 text service is not open

=cut

sub tsmTSNotOpenErr { -2514 }

=item tsmComponentAlreadyOpenErr

 text service already opened for the document

=cut

sub tsmComponentAlreadyOpenErr { -2515 }

=item tsmInputMethodIsOldErr

 returned by GetDefaultInputMethod

=cut

sub tsmInputMethodIsOldErr { -2516 }

=item tsmScriptHasNoIMErr

 script has no imput method or is using old IM

=cut

sub tsmScriptHasNoIMErr { -2517 }

=item tsmUnsupportedTypeErr

 unSupported interface type error

=cut

sub tsmUnsupportedTypeErr { -2518 }

=item tsmUnknownErr

 any other errors

=cut

sub tsmUnknownErr { -2519 }

=item tsmInvalidContext

 Invalid TSMContext specified in call

=cut

sub tsmInvalidContext { -2520 }

=item tsmNoHandler

 No Callback Handler exists for callback

=cut

sub tsmNoHandler { -2521 }

=item tsmNoMoreTokens

 No more tokens are available for the source text

=cut

sub tsmNoMoreTokens { -2522 }

=item tsmNoStem

 No stem exists for the token

=cut

sub tsmNoStem { -2523 }

=back

=head1 Mixed Mode error codes

=over 4

=back

=head1 NameRegistry error codes

=over 4

=item nrLockedErr

=cut

sub nrLockedErr { -2536 }

=item nrNotEnoughMemoryErr

=cut

sub nrNotEnoughMemoryErr { -2537 }

=item nrInvalidNodeErr

=cut

sub nrInvalidNodeErr { -2538 }

=item nrNotFoundErr

=cut

sub nrNotFoundErr { -2539 }

=item nrNotCreatedErr

=cut

sub nrNotCreatedErr { -2540 }

=item nrNameErr

=cut

sub nrNameErr { -2541 }

=item nrNotSlotDeviceErr

=cut

sub nrNotSlotDeviceErr { -2542 }

=item nrDataTruncatedErr

=cut

sub nrDataTruncatedErr { -2543 }

=item nrPowerErr

=cut

sub nrPowerErr { -2544 }

=item nrPowerSwitchAbortErr

=cut

sub nrPowerSwitchAbortErr { -2545 }

=item nrTypeMismatchErr

=cut

sub nrTypeMismatchErr { -2546 }

=item nrNotModifiedErr

=cut

sub nrNotModifiedErr { -2547 }

=item nrOverrunErr

=cut

sub nrOverrunErr { -2548 }

=item nrResultCodeBase

=cut

sub nrResultCodeBase { -2549 }

=item nrPathNotFound

 a path component lookup failed

=cut

sub nrPathNotFound { -2550 }

=item nrPathBufferTooSmall

 buffer for path is too small

=cut

sub nrPathBufferTooSmall { -2551 }

=item nrInvalidEntryIterationOp

 invalid entry iteration operation

=cut

sub nrInvalidEntryIterationOp { -2552 }

=item nrPropertyAlreadyExists

 property already exists

=cut

sub nrPropertyAlreadyExists { -2553 }

=item nrIterationDone

 iteration operation is done

=cut

sub nrIterationDone { -2554 }

=item nrExitedIteratorScope

 outer scope of iterator was exited

=cut

sub nrExitedIteratorScope { -2555 }

=item nrTransactionAborted

 transaction was aborted

=cut

sub nrTransactionAborted { -2556 }

=back

=head1 Icon Services error codes

=over 4

=item invalidIconRefErr

 The icon ref is not valid

=cut

sub invalidIconRefErr { -2580 }

=item noSuchIconErr

 The requested icon could not be found

=cut

sub noSuchIconErr { -2581 }

=back

=head1 Dynamic AppleScript errors

=over 4

=item errOSACantCoerce

 Signaled when a value can't be coerced to the desired type.

=cut

sub errOSACantCoerce { errAECoercionFail }

=item errOSACantAccess

 Signaled when an object is not found in a container

=cut

sub errOSACantAccess { errAENoSuchObject }

=item errOSACantAssign

 Signaled when an object cannot be set in a container.

=cut

sub errOSACantAssign { -10006 }

=item errOSAGeneralError

 Signaled by user scripts or applications when no actual error code is to be returned.

=cut

sub errOSAGeneralError { -2700 }

=item errOSADivideByZero

 Signaled when there is an attempt to divide by zero

=cut

sub errOSADivideByZero { -2701 }

=item errOSANumericOverflow

 Signaled when integer or real value is too large to be represented

=cut

sub errOSANumericOverflow { -2702 }

=item errOSACantLaunch

 Signaled when application can't be launched or when it is remote and program linking is not enabled

=cut

sub errOSACantLaunch { -2703 }

=item errOSAAppNotHighLevelEventAware

 Signaled when an application can't respond to AppleEvents

=cut

sub errOSAAppNotHighLevelEventAware { -2704 }

=item errOSACorruptTerminology

 Signaled when an application's terminology resource is not readable

=cut

sub errOSACorruptTerminology { -2705 }

=item errOSAStackOverflow

 Signaled when the runtime stack overflows

=cut

sub errOSAStackOverflow { -2706 }

=item errOSAInternalTableOverflow

 Signaled when a runtime internal data structure overflows

=cut

sub errOSAInternalTableOverflow { -2707 }

=item errOSADataBlockTooLarge

 Signaled when an intrinsic limitation is exceeded for the size of a value or data structure.

=cut

sub errOSADataBlockTooLarge { -2708 }

=item errOSACantGetTerminology

=cut

sub errOSACantGetTerminology { -2709 }

=back

=head1 Static AppleScript errors

=over 4

=item errOSATypeError

=cut

sub errOSATypeError { errAEWrongDataType }

=item OSAMessageNotUnderstood

 Signaled when a message was sent to an object that didn't handle it

=cut

sub OSAMessageNotUnderstood { errAEEventNotHandled }

=item OSAUndefinedHandler

 Signaled when a function to be returned doesn't exist.

=cut

sub OSAUndefinedHandler { errAEHandlerNotFound }

=item OSAIllegalAccess

 Signaled when a container can never have the requested object

=cut

sub OSAIllegalAccess { errAEAccessorNotFound }

=item OSAIllegalIndex

 Signaled when index was out of range. Specialization of errOSACantAccess

=cut

sub OSAIllegalIndex { errAEIllegalIndex }

=item OSAIllegalRange

 Signaled when a range is screwy. Specialization of errOSACantAccess

=cut

sub OSAIllegalRange { errAEImpossibleRange }

=item OSAIllegalAssign

 Signaled when an object can never be set in a container

=cut

sub OSAIllegalAssign { -10003 }

=item OSASyntaxError

 Signaled when a syntax error occurs. (e.g. "Syntax error" or "<this> can't go after <that>")

=cut

sub OSASyntaxError { -2740 }

=item OSASyntaxTypeError

 Signaled when another form of syntax was expected. (e.g. "expected a <type> but found <this>")

=cut

sub OSASyntaxTypeError { -2741 }

=item OSATokenTooLong

 Signaled when a name or number is too long to be parsed

=cut

sub OSATokenTooLong { -2742 }

=item OSAMissingParameter

 Signaled when a parameter is missing for a function invocation

=cut

sub OSAMissingParameter { errAEDescNotFound }

=item OSAParameterMismatch

 Signaled when function is called with the wrong number of parameters, or a parameter pattern cannot be matched

=cut

sub OSAParameterMismatch { errAEWrongNumberArgs }

=item OSADuplicateParameter

 Signaled when a formal parameter, local variable, or instance variable is specified more than once

=cut

sub OSADuplicateParameter { -2750 }

=item OSADuplicateProperty

 Signaled when a formal parameter, local variable, or instance variable is specified more than once.

=cut

sub OSADuplicateProperty { -2751 }

=item OSADuplicateHandler

 Signaled when more than one handler is defined with the same name in a scope where the language doesn't allow it

=cut

sub OSADuplicateHandler { -2752 }

=item OSAUndefinedVariable

 Signaled when a variable is accessed that has no value

=cut

sub OSAUndefinedVariable { -2753 }

=item OSAInconsistentDeclarations

 Signaled when a variable is declared inconsistently in the same scope, such as both local and global

=cut

sub OSAInconsistentDeclarations { -2754 }

=item errASCantConsiderAndIgnore

=cut

sub errASCantConsiderAndIgnore { -2720 }

=item errASCantCompareMoreThan32k

 Parser/Compiler errors:

=cut

sub errASCantCompareMoreThan32k { -2721 }

=item errASTerminologyNestingTooDeep

=cut

sub errASTerminologyNestingTooDeep { -2760 }

=item errASIllegalFormalParameter

=cut

sub errASIllegalFormalParameter { -2761 }

=item errASParameterNotForEvent

=cut

sub errASParameterNotForEvent { -2762 }

=item errASNoResultReturned

 The range -2780 thru -2799 is reserved for dialect specific error codes. (Error codes from different dialects may overlap.)

=cut

sub errASNoResultReturned { -2763 }

=back

=head1 The preferred spelling for Code Fragment Manager errors:

=over 4

=item cfragFirstErrCode

 The first value in the range of CFM errors.

=cut

sub cfragFirstErrCode { -2800 }

=item cfragContextIDErr

 The context ID was not valid.

=cut

sub cfragContextIDErr { -2800 }

=item cfragConnectionIDErr

 The connection ID was not valid.

=cut

sub cfragConnectionIDErr { -2801 }

=item cfragNoSymbolErr

 The specified symbol was not found.

=cut

sub cfragNoSymbolErr { -2802 }

=item cfragNoSectionErr

 The specified section was not found.

=cut

sub cfragNoSectionErr { -2803 }

=item cfragNoLibraryErr

 The named library was not found.

=cut

sub cfragNoLibraryErr { -2804 }

=item cfragDupRegistrationErr

 The registration name was already in use.

=cut

sub cfragDupRegistrationErr { -2805 }

=item cfragFragmentFormatErr

 A fragment's container format is unknown.

=cut

sub cfragFragmentFormatErr { -2806 }

=item cfragUnresolvedErr

 A fragment had "hard" unresolved imports.

=cut

sub cfragUnresolvedErr { -2807 }

=item cfragNoPositionErr

 The registration insertion point was not found.

=cut

sub cfragNoPositionErr { -2808 }

=item cfragNoPrivateMemErr

 Out of memory for internal bookkeeping.

=cut

sub cfragNoPrivateMemErr { -2809 }

=item cfragNoClientMemErr

 Out of memory for fragment mapping or section instances.

=cut

sub cfragNoClientMemErr { -2810 }

=item cfragNoIDsErr

 No more CFM IDs for contexts, connections, etc.

=cut

sub cfragNoIDsErr { -2811 }

=item cfragInitOrderErr

=cut

sub cfragInitOrderErr { -2812 }

=item cfragImportTooOldErr

 An import library was too old for a client.

=cut

sub cfragImportTooOldErr { -2813 }

=item cfragImportTooNewErr

 An import library was too new for a client.

=cut

sub cfragImportTooNewErr { -2814 }

=item cfragInitLoopErr

 Circularity in required initialization order.

=cut

sub cfragInitLoopErr { -2815 }

=item cfragInitAtBootErr

 A boot library has an initialization function.  (System 7 only)

=cut

sub cfragInitAtBootErr { -2816 }

=item cfragLibConnErr

=cut

sub cfragLibConnErr { -2817 }

=item cfragCFMStartupErr

 Internal error during CFM initialization.

=cut

sub cfragCFMStartupErr { -2818 }

=item cfragCFMInternalErr

 An internal inconstistancy has been detected.

=cut

sub cfragCFMInternalErr { -2819 }

=item cfragFragmentCorruptErr

 A fragment's container was corrupt (known format).

=cut

sub cfragFragmentCorruptErr { -2820 }

=item cfragInitFunctionErr

 A fragment's initialization routine returned an error.

=cut

sub cfragInitFunctionErr { -2821 }

=item cfragNoApplicationErr

 No application member found in the cfrg resource.

=cut

sub cfragNoApplicationErr { -2822 }

=item cfragArchitectureErr

 A fragment has an unacceptable architecture.

=cut

sub cfragArchitectureErr { -2823 }

=item cfragFragmentUsageErr

 A semantic error in usage of the fragment.

=cut

sub cfragFragmentUsageErr { -2824 }

=item cfragFileSizeErr

 A file was too large to be mapped.

=cut

sub cfragFileSizeErr { -2825 }

=item cfragNotClosureErr

 The closure ID was actually a connection ID.

=cut

sub cfragNotClosureErr { -2826 }

=item cfragNoRegistrationErr

 The registration name was not found.

=cut

sub cfragNoRegistrationErr { -2827 }

=item cfragContainerIDErr

 The fragment container ID was not valid.

=cut

sub cfragContainerIDErr { -2828 }

=item cfragClosureIDErr

 The closure ID was not valid.

=cut

sub cfragClosureIDErr { -2829 }

=item cfragAbortClosureErr

 Used by notification handlers to abort a closure.

=cut

sub cfragAbortClosureErr { -2830 }

=item cfragOutputLengthErr

 An output parameter is too small to hold the value.

=cut

sub cfragOutputLengthErr { -2831 }

=back

=head1 Reserved values for internal "warnings".

=over 4

=item cfragFirstReservedCode

=cut

sub cfragFirstReservedCode { -2897 }

=item cfragReservedCode_3

=cut

sub cfragReservedCode_3 { -2897 }

=item cfragReservedCode_2

=cut

sub cfragReservedCode_2 { -2898 }

=item fragContextNotFound

=cut

sub fragContextNotFound { cfragContextIDErr }

=item fragConnectionIDNotFound

=cut

sub fragConnectionIDNotFound { cfragConnectionIDErr }

=item fragSymbolNotFound

=cut

sub fragSymbolNotFound { cfragNoSymbolErr }

=item fragSectionNotFound

=cut

sub fragSectionNotFound { cfragNoSectionErr }

=item fragLibNotFound

=cut

sub fragLibNotFound { cfragNoLibraryErr }

=item fragDupRegLibName

=cut

sub fragDupRegLibName { cfragDupRegistrationErr }

=item fragFormatUnknown

=cut

sub fragFormatUnknown { cfragFragmentFormatErr }

=item fragHadUnresolveds

=cut

sub fragHadUnresolveds { cfragUnresolvedErr }

=item fragNoMem

=cut

sub fragNoMem { cfragNoPrivateMemErr }

=item fragNoAddrSpace

=cut

sub fragNoAddrSpace { cfragNoClientMemErr }

=item fragNoContextIDs

=cut

sub fragNoContextIDs { cfragNoIDsErr }

=item fragObjectInitSeqErr

=cut

sub fragObjectInitSeqErr { cfragInitOrderErr }

=item fragImportTooOld

=cut

sub fragImportTooOld { cfragImportTooOldErr }

=item fragImportTooNew

=cut

sub fragImportTooNew { cfragImportTooNewErr }

=item fragInitLoop

=cut

sub fragInitLoop { cfragInitLoopErr }

=item fragInitRtnUsageErr

=cut

sub fragInitRtnUsageErr { cfragInitAtBootErr }

=item fragLibConnErr

=cut

sub fragLibConnErr { cfragLibConnErr }

=item fragMgrInitErr

=cut

sub fragMgrInitErr { cfragCFMStartupErr }

=item fragConstErr

=cut

sub fragConstErr { cfragCFMInternalErr }

=item fragCorruptErr

=cut

sub fragCorruptErr { cfragFragmentCorruptErr }

=item fragUserInitProcErr

=cut

sub fragUserInitProcErr { cfragInitFunctionErr }

=item fragAppNotFound

=cut

sub fragAppNotFound { cfragNoApplicationErr }

=item fragArchError

=cut

sub fragArchError { cfragArchitectureErr }

=item fragInvalidFragmentUsage

=cut

sub fragInvalidFragmentUsage { cfragFragmentUsageErr }

=item invalidComponentID

=cut

sub invalidComponentID { -3000 }

=item validInstancesExist

=cut

sub validInstancesExist { -3001 }

=item componentNotCaptured

=cut

sub componentNotCaptured { -3002 }

=item componentDontRegister

=cut

sub componentDontRegister { -3003 }

=item unresolvedComponentDLLErr

=cut

sub unresolvedComponentDLLErr { -3004 }

=item invalidTranslationPathErr

 Source type to destination type not a valid path

=cut

sub invalidTranslationPathErr { -3025 }

=item couldNotParseSourceFileErr

 Source document does not contain source type

=cut

sub couldNotParseSourceFileErr { -3026 }

=item noTranslationPathErr

=cut

sub noTranslationPathErr { -3030 }

=item badTranslationSpecErr

=cut

sub badTranslationSpecErr { -3031 }

=item buf2SmallErr

=cut

sub buf2SmallErr { -3101 }

=item noMPPErr

=cut

sub noMPPErr { -3102 }

=item ckSumErr

=cut

sub ckSumErr { -3103 }

=item extractErr

=cut

sub extractErr { -3104 }

=item readQErr

=cut

sub readQErr { -3105 }

=item atpLenErr

=cut

sub atpLenErr { -3106 }

=item atpBadRsp

=cut

sub atpBadRsp { -3107 }

=item recNotFnd

=cut

sub recNotFnd { -3108 }

=back

=head1 OpenTransport errors

=over 4

=item kOTNoError

 No Error occurred

=cut

sub kOTNoError { 0 }

=item kOTOutOfMemoryErr

 OT ran out of memory, may be a temporary

=cut

sub kOTOutOfMemoryErr { -3211 }

=item kOTNotFoundErr

 OT generic not found error

=cut

sub kOTNotFoundErr { -3201 }

=item kOTDuplicateFoundErr

 OT generic duplicate found error

=cut

sub kOTDuplicateFoundErr { -3216 }

=item kOTBadAddressErr

 XTI2OSStatus(TBADADDR) A Bad address was specified

=cut

sub kOTBadAddressErr { -3150 }

=item kOTBadOptionErr

 XTI2OSStatus(TBADOPT) A Bad option was specified

=cut

sub kOTBadOptionErr { -3151 }

=item kOTAccessErr

 XTI2OSStatus(TACCES) Missing access permission

=cut

sub kOTAccessErr { -3152 }

=item kOTBadReferenceErr

 XTI2OSStatus(TBADF) Bad provider reference

=cut

sub kOTBadReferenceErr { -3153 }

=item kOTNoAddressErr

 XTI2OSStatus(TNOADDR) No address was specified

=cut

sub kOTNoAddressErr { -3154 }

=item kOTOutStateErr

 XTI2OSStatus(TOUTSTATE) Call issued in wrong state

=cut

sub kOTOutStateErr { -3155 }

=item kOTBadSequenceErr

 XTI2OSStatus(TBADSEQ) Sequence specified does not exist

=cut

sub kOTBadSequenceErr { -3156 }

=item kOTSysErrorErr

 XTI2OSStatus(TSYSERR) A system error occurred

=cut

sub kOTSysErrorErr { -3157 }

=item kOTLookErr

 XTI2OSStatus(TLOOK) An event occurred - call Look()

=cut

sub kOTLookErr { -3158 }

=item kOTBadDataErr

 XTI2OSStatus(TBADDATA) An illegal amount of data was specified

=cut

sub kOTBadDataErr { -3159 }

=item kOTBufferOverflowErr

 XTI2OSStatus(TBUFOVFLW) Passed buffer not big enough

=cut

sub kOTBufferOverflowErr { -3160 }

=item kOTFlowErr

 XTI2OSStatus(TFLOW) Provider is flow-controlled

=cut

sub kOTFlowErr { -3161 }

=item kOTNoDataErr

 XTI2OSStatus(TNODATA) No data available for reading

=cut

sub kOTNoDataErr { -3162 }

=item kOTNoDisconnectErr

 XTI2OSStatus(TNODIS) No disconnect indication available

=cut

sub kOTNoDisconnectErr { -3163 }

=item kOTNoUDErrErr

 XTI2OSStatus(TNOUDERR) No Unit Data Error indication available

=cut

sub kOTNoUDErrErr { -3164 }

=item kOTBadFlagErr

 XTI2OSStatus(TBADFLAG) A Bad flag value was supplied

=cut

sub kOTBadFlagErr { -3165 }

=item kOTNoReleaseErr

 XTI2OSStatus(TNOREL) No orderly release indication available

=cut

sub kOTNoReleaseErr { -3166 }

=item kOTNotSupportedErr

 XTI2OSStatus(TNOTSUPPORT) Command is not supported

=cut

sub kOTNotSupportedErr { -3167 }

=item kOTStateChangeErr

 XTI2OSStatus(TSTATECHNG) State is changing - try again later

=cut

sub kOTStateChangeErr { -3168 }

=item kOTNoStructureTypeErr

 XTI2OSStatus(TNOSTRUCTYPE) Bad structure type requested for OTAlloc

=cut

sub kOTNoStructureTypeErr { -3169 }

=item kOTBadNameErr

 XTI2OSStatus(TBADNAME) A bad endpoint name was supplied

=cut

sub kOTBadNameErr { -3170 }

=item kOTBadQLenErr

 XTI2OSStatus(TBADQLEN) A Bind to an in-use addr with qlen > 0

=cut

sub kOTBadQLenErr { -3171 }

=item kOTAddressBusyErr

 XTI2OSStatus(TADDRBUSY) Address requested is already in use

=cut

sub kOTAddressBusyErr { -3172 }

=item kOTIndOutErr

 XTI2OSStatus(TINDOUT) Accept failed because of pending listen

=cut

sub kOTIndOutErr { -3173 }

=item kOTProviderMismatchErr

 XTI2OSStatus(TPROVMISMATCH) Tried to accept on incompatible endpoint

=cut

sub kOTProviderMismatchErr { -3174 }

=item kOTResQLenErr

 XTI2OSStatus(TRESQLEN)

=cut

sub kOTResQLenErr { -3175 }

=item kOTResAddressErr

 XTI2OSStatus(TRESADDR)

=cut

sub kOTResAddressErr { -3176 }

=item kOTQFullErr

 XTI2OSStatus(TQFULL)

=cut

sub kOTQFullErr { -3177 }

=item kOTProtocolErr

 XTI2OSStatus(TPROTO) An unspecified provider error occurred

=cut

sub kOTProtocolErr { -3178 }

=item kOTBadSyncErr

 XTI2OSStatus(TBADSYNC) A synchronous call at interrupt time

=cut

sub kOTBadSyncErr { -3179 }

=item kOTCanceledErr

 XTI2OSStatus(TCANCELED) The command was cancelled

=cut

sub kOTCanceledErr { -3180 }

=item kEPERMErr

 Permission denied

=cut

sub kEPERMErr { -3200 }

=item kENOENTErr

 No such file or directory

=cut

sub kENOENTErr { -3201 }

=item kENORSRCErr

 No such resource

=cut

sub kENORSRCErr { -3202 }

=item kEINTRErr

 Interrupted system service

=cut

sub kEINTRErr { -3203 }

=item kEIOErr

 I/O error

=cut

sub kEIOErr { -3204 }

=item kENXIOErr

 No such device or address

=cut

sub kENXIOErr { -3205 }

=item kEBADFErr

 Bad file number

=cut

sub kEBADFErr { -3208 }

=item kEAGAINErr

 Try operation again later

=cut

sub kEAGAINErr { -3210 }

=item kENOMEMErr

 Not enough space

=cut

sub kENOMEMErr { -3211 }

=item kEACCESErr

 Permission denied

=cut

sub kEACCESErr { -3212 }

=item kEFAULTErr

 Bad address

=cut

sub kEFAULTErr { -3213 }

=item kEBUSYErr

 Device or resource busy

=cut

sub kEBUSYErr { -3215 }

=item kEEXISTErr

 File exists

=cut

sub kEEXISTErr { -3216 }

=item kENODEVErr

 No such device

=cut

sub kENODEVErr { -3218 }

=item kEINVALErr

 Invalid argument

=cut

sub kEINVALErr { -3221 }

=item kENOTTYErr

 Not a character device

=cut

sub kENOTTYErr { -3224 }

=item kEPIPEErr

 Broken pipe

=cut

sub kEPIPEErr { -3231 }

=item kERANGEErr

 Message size too large for STREAM

=cut

sub kERANGEErr { -3233 }

=item kEWOULDBLOCKErr

 Call would block, so was aborted

=cut

sub kEWOULDBLOCKErr { -3234 }

=item kEDEADLKErr

 or a deadlock would occur

=cut

sub kEDEADLKErr { -3234 }

=item kEALREADYErr

=cut

sub kEALREADYErr { -3236 }

=item kENOTSOCKErr

 Socket operation on non-socket

=cut

sub kENOTSOCKErr { -3237 }

=item kEDESTADDRREQErr

 Destination address required

=cut

sub kEDESTADDRREQErr { -3238 }

=item kEMSGSIZEErr

 Message too long

=cut

sub kEMSGSIZEErr { -3239 }

=item kEPROTOTYPEErr

 Protocol wrong type for socket

=cut

sub kEPROTOTYPEErr { -3240 }

=item kENOPROTOOPTErr

 Protocol not available

=cut

sub kENOPROTOOPTErr { -3241 }

=item kEPROTONOSUPPORTErr

 Protocol not supported

=cut

sub kEPROTONOSUPPORTErr { -3242 }

=item kESOCKTNOSUPPORTErr

 Socket type not supported

=cut

sub kESOCKTNOSUPPORTErr { -3243 }

=item kEOPNOTSUPPErr

 Operation not supported on socket

=cut

sub kEOPNOTSUPPErr { -3244 }

=item kEADDRINUSEErr

 Address already in use

=cut

sub kEADDRINUSEErr { -3247 }

=item kEADDRNOTAVAILErr

 Can't assign requested address

=cut

sub kEADDRNOTAVAILErr { -3248 }

=item kENETDOWNErr

 Network is down

=cut

sub kENETDOWNErr { -3249 }

=item kENETUNREACHErr

 Network is unreachable

=cut

sub kENETUNREACHErr { -3250 }

=item kENETRESETErr

 Network dropped connection on reset

=cut

sub kENETRESETErr { -3251 }

=item kECONNABORTEDErr

 Software caused connection abort

=cut

sub kECONNABORTEDErr { -3252 }

=item kECONNRESETErr

 Connection reset by peer

=cut

sub kECONNRESETErr { -3253 }

=item kENOBUFSErr

 No buffer space available

=cut

sub kENOBUFSErr { -3254 }

=item kEISCONNErr

 Socket is already connected

=cut

sub kEISCONNErr { -3255 }

=item kENOTCONNErr

 Socket is not connected

=cut

sub kENOTCONNErr { -3256 }

=item kESHUTDOWNErr

 Can't send after socket shutdown

=cut

sub kESHUTDOWNErr { -3257 }

=item kETOOMANYREFSErr

 Too many references: can't splice

=cut

sub kETOOMANYREFSErr { -3258 }

=item kETIMEDOUTErr

 Connection timed out

=cut

sub kETIMEDOUTErr { -3259 }

=item kECONNREFUSEDErr

 Connection refused

=cut

sub kECONNREFUSEDErr { -3260 }

=item kEHOSTDOWNErr

 Host is down

=cut

sub kEHOSTDOWNErr { -3263 }

=item kEHOSTUNREACHErr

 No route to host

=cut

sub kEHOSTUNREACHErr { -3264 }

=item kEPROTOErr

 ''' fill out missing codes '''

=cut

sub kEPROTOErr { -3269 }

=item kETIMEErr

=cut

sub kETIMEErr { -3270 }

=item kENOSRErr

=cut

sub kENOSRErr { -3271 }

=item kEBADMSGErr

=cut

sub kEBADMSGErr { -3272 }

=item kECANCELErr

=cut

sub kECANCELErr { -3273 }

=item kENOSTRErr

=cut

sub kENOSTRErr { -3274 }

=item kENODATAErr

=cut

sub kENODATAErr { -3275 }

=item kEINPROGRESSErr

=cut

sub kEINPROGRESSErr { -3276 }

=item kESRCHErr

=cut

sub kESRCHErr { -3277 }

=item kENOMSGErr

=cut

sub kENOMSGErr { -3278 }

=item kOTClientNotInittedErr

=cut

sub kOTClientNotInittedErr { -3279 }

=item kOTPortHasDiedErr

=cut

sub kOTPortHasDiedErr { -3280 }

=item kOTPortWasEjectedErr

=cut

sub kOTPortWasEjectedErr { -3281 }

=item kOTBadConfigurationErr

=cut

sub kOTBadConfigurationErr { -3282 }

=item kOTConfigurationChangedErr

=cut

sub kOTConfigurationChangedErr { -3283 }

=item kOTUserRequestedErr

=cut

sub kOTUserRequestedErr { -3284 }

=back

=head1 Color Picker errors

=over 4

=item firstPickerError

=cut

sub firstPickerError { -4000 }

=item invalidPickerType

=cut

sub invalidPickerType { firstPickerError }

=item requiredFlagsDontMatch

=cut

sub requiredFlagsDontMatch { -4001 }

=item pickerResourceError

=cut

sub pickerResourceError { -4002 }

=item cantLoadPicker

=cut

sub cantLoadPicker { -4003 }

=item cantCreatePickerWindow

=cut

sub cantCreatePickerWindow { -4004 }

=item cantLoadPackage

=cut

sub cantLoadPackage { -4005 }

=item pickerCantLive

=cut

sub pickerCantLive { -4006 }

=item colorSyncNotInstalled

=cut

sub colorSyncNotInstalled { -4007 }

=item badProfileError

=cut

sub badProfileError { -4008 }

=item kNSL68kContextNotSupported

 no 68k allowed

=cut

sub kNSL68kContextNotSupported { -4170 }

=item kNSLSchedulerError

 A custom thread routine encountered an error

=cut

sub kNSLSchedulerError { -4171 }

=item kNSLBadURLSyntax

 URL contains illegal characters

=cut

sub kNSLBadURLSyntax { -4172 }

=item kNSLNoCarbonLib

=cut

sub kNSLNoCarbonLib { -4173 }

=item kNSLUILibraryNotAvailable

 The NSL UI Library needs to be in the Extensions Folder

=cut

sub kNSLUILibraryNotAvailable { -4174 }

=item kNSLNotImplementedYet

=cut

sub kNSLNotImplementedYet { -4175 }

=item kNSLErrNullPtrError

=cut

sub kNSLErrNullPtrError { -4176 }

=item kNSLSomePluginsFailedToLoad

 (one or more plugins failed to load, but at least one did load; this error isn't fatal)

=cut

sub kNSLSomePluginsFailedToLoad { -4177 }

=item kNSLNullNeighborhoodPtr

 (client passed a null neighborhood ptr)

=cut

sub kNSLNullNeighborhoodPtr { -4178 }

=item kNSLNoPluginsForSearch

 (no plugins will respond to search request; bad protocol(s)?)

=cut

sub kNSLNoPluginsForSearch { -4179 }

=item kNSLSearchAlreadyInProgress

 (you can only have one ongoing search per clientRef)

=cut

sub kNSLSearchAlreadyInProgress { -4180 }

=item kNSLNoPluginsFound

 (manager didn't find any valid plugins to load)

=cut

sub kNSLNoPluginsFound { -4181 }

=item kNSLPluginLoadFailed

 (manager unable to load one of the plugins)

=cut

sub kNSLPluginLoadFailed { -4182 }

=item kNSLBadProtocolTypeErr

 (client is trying to add a null protocol type)

=cut

sub kNSLBadProtocolTypeErr { -4183 }

=item kNSLNullListPtr

 (client is trying to add items to a nil list)

=cut

sub kNSLNullListPtr { -4184 }

=item kNSLBadClientInfoPtr

 (nil ClientAsyncInfoPtr; no reference available)

=cut

sub kNSLBadClientInfoPtr { -4185 }

=item kNSLCannotContinueLookup

 (Can't continue lookup; error or bad state)

=cut

sub kNSLCannotContinueLookup { -4186 }

=item kNSLBufferTooSmallForData

 (Client buffer too small for data from plugin)

=cut

sub kNSLBufferTooSmallForData { -4187 }

=item kNSLNoContextAvailable

 (ContinueLookup function ptr invalid)

=cut

sub kNSLNoContextAvailable { -4188 }

=item kNSLRequestBufferAlreadyInList

=cut

sub kNSLRequestBufferAlreadyInList { -4189 }

=item kNSLInvalidPluginSpec

=cut

sub kNSLInvalidPluginSpec { -4190 }

=item kNSLNoSupportForService

=cut

sub kNSLNoSupportForService { -4191 }

=item kNSLBadNetConnection

=cut

sub kNSLBadNetConnection { -4192 }

=item kNSLBadDataTypeErr

=cut

sub kNSLBadDataTypeErr { -4193 }

=item kNSLBadServiceTypeErr

=cut

sub kNSLBadServiceTypeErr { -4194 }

=item kNSLBadReferenceErr

=cut

sub kNSLBadReferenceErr { -4195 }

=item kNSLNoElementsInList

=cut

sub kNSLNoElementsInList { -4196 }

=item kNSLInsufficientOTVer

=cut

sub kNSLInsufficientOTVer { -4197 }

=item kNSLInsufficientSysVer

=cut

sub kNSLInsufficientSysVer { -4198 }

=item kNSLNotInitialized

=cut

sub kNSLNotInitialized { -4199 }

=item kDTPHoldJobErr

=cut

sub kDTPHoldJobErr { -4200 }

=item kDTPStopQueueErr

=cut

sub kDTPStopQueueErr { -4201 }

=item kDTPTryAgainErr

=cut

sub kDTPTryAgainErr { -4202 }

=back

=head1 ColorSync Result codes

=over 4

=item cmElementTagNotFound

=cut

sub cmElementTagNotFound { -4200 }

=item cmIndexRangeErr

 Tag index out of range

=cut

sub cmIndexRangeErr { -4201 }

=item cmCantDeleteElement

=cut

sub cmCantDeleteElement { -4202 }

=item cmFatalProfileErr

=cut

sub cmFatalProfileErr { -4203 }

=item cmInvalidProfile

 A Profile must contain a 'cs1 ' tag to be valid

=cut

sub cmInvalidProfile { -4204 }

=item cmInvalidProfileLocation

 Operation not supported for this profile location

=cut

sub cmInvalidProfileLocation { -4205 }

=item cmCantCopyModifiedV1Profile

 Illegal to copy version 1 profiles that have been modified
Profile Search Errors

=cut

sub cmCantCopyModifiedV1Profile { -4215 }

=item cmInvalidSearch

 Bad Search Handle

=cut

sub cmInvalidSearch { -4206 }

=item cmSearchError

=cut

sub cmSearchError { -4207 }

=item cmErrIncompatibleProfile

 Other ColorSync Errors

=cut

sub cmErrIncompatibleProfile { -4208 }

=item cmInvalidColorSpace

 Profile colorspace does not match bitmap type

=cut

sub cmInvalidColorSpace { -4209 }

=item cmInvalidSrcMap

 Source pix/bit map was invalid

=cut

sub cmInvalidSrcMap { -4210 }

=item cmInvalidDstMap

 Destination pix/bit map was invalid

=cut

sub cmInvalidDstMap { -4211 }

=item cmNoGDevicesError

 Begin/End Matching -- no gdevices available

=cut

sub cmNoGDevicesError { -4212 }

=item cmInvalidProfileComment

 Bad Profile comment during drawpicture

=cut

sub cmInvalidProfileComment { -4213 }

=item cmRangeOverFlow

 Color conversion warning that some output color values over/underflowed and were clipped

=cut

sub cmRangeOverFlow { -4214 }

=item cmNamedColorNotFound

 NamedColor not found

=cut

sub cmNamedColorNotFound { -4216 }

=item badFolderDescErr

=cut

sub badFolderDescErr { -4270 }

=item duplicateFolderDescErr

=cut

sub duplicateFolderDescErr { -4271 }

=item noMoreFolderDescErr

=cut

sub noMoreFolderDescErr { -4272 }

=item invalidFolderTypeErr

=cut

sub invalidFolderTypeErr { -4273 }

=item duplicateRoutingErr

=cut

sub duplicateRoutingErr { -4274 }

=item routingNotFoundErr

=cut

sub routingNotFoundErr { -4275 }

=item internalScrapErr

=cut

sub internalScrapErr { -4988 }

=item duplicateScrapFlavorErr

=cut

sub duplicateScrapFlavorErr { -4989 }

=item badScrapRefErr

=cut

sub badScrapRefErr { -4990 }

=item processStateIncorrectErr

=cut

sub processStateIncorrectErr { -4991 }

=item scrapPromiseNotKeptErr

=cut

sub scrapPromiseNotKeptErr { -4992 }

=item noScrapPromiseKeeperErr

=cut

sub noScrapPromiseKeeperErr { -4993 }

=item nilScrapFlavorDataErr

=cut

sub nilScrapFlavorDataErr { -4994 }

=item scrapFlavorFlagsMismatchErr

=cut

sub scrapFlavorFlagsMismatchErr { -4995 }

=item scrapFlavorSizeMismatchErr

=cut

sub scrapFlavorSizeMismatchErr { -4996 }

=item illegalScrapFlavorFlagsErr

=cut

sub illegalScrapFlavorFlagsErr { -4997 }

=item illegalScrapFlavorTypeErr

=cut

sub illegalScrapFlavorTypeErr { -4998 }

=item illegalScrapFlavorSizeErr

=cut

sub illegalScrapFlavorSizeErr { -4999 }

=item scrapFlavorNotFoundErr

 == noTypeErr

=cut

sub scrapFlavorNotFoundErr { -102 }

=back

=head1 AFP Protocol Errors

=over 4

=item afpAccessDenied

 Insufficient access privileges for operation

=cut

sub afpAccessDenied { -5000 }

=item afpAuthContinue

 Further information required to complete AFPLogin call

=cut

sub afpAuthContinue { -5001 }

=item afpBadUAM

 Unknown user authentication method specified

=cut

sub afpBadUAM { -5002 }

=item afpBadVersNum

 Unknown AFP protocol version number specified

=cut

sub afpBadVersNum { -5003 }

=item afpBitmapErr

 Bitmap contained bits undefined for call

=cut

sub afpBitmapErr { -5004 }

=item afpCantMove

 Move destination is offspring of source, or root was specified

=cut

sub afpCantMove { -5005 }

=item afpDenyConflict

 Specified open/deny modes conflict with current open modes

=cut

sub afpDenyConflict { -5006 }

=item afpDirNotEmpty

 Cannot delete non-empty directory

=cut

sub afpDirNotEmpty { -5007 }

=item afpDiskFull

 Insufficient free space on volume for operation

=cut

sub afpDiskFull { -5008 }

=item afpEofError

 Read beyond logical end-of-file

=cut

sub afpEofError { -5009 }

=item afpFileBusy

 Cannot delete an open file

=cut

sub afpFileBusy { -5010 }

=item afpFlatVol

 Cannot create directory on specified volume

=cut

sub afpFlatVol { -5011 }

=item afpItemNotFound

 Unknown UserName/UserID or missing comment/APPL entry

=cut

sub afpItemNotFound { -5012 }

=item afpLockErr

 Some or all of requested range is locked by another user

=cut

sub afpLockErr { -5013 }

=item afpMiscErr

 Unexpected error encountered during execution

=cut

sub afpMiscErr { -5014 }

=item afpNoMoreLocks

 Maximum lock limit reached

=cut

sub afpNoMoreLocks { -5015 }

=item afpNoServer

 Server not responding

=cut

sub afpNoServer { -5016 }

=item afpObjectExists

 Specified destination file or directory already exists

=cut

sub afpObjectExists { -5017 }

=item afpObjectNotFound

 Specified file or directory does not exist

=cut

sub afpObjectNotFound { -5018 }

=item afpParmErr

 A specified parameter was out of allowable range

=cut

sub afpParmErr { -5019 }

=item afpRangeNotLocked

 Tried to unlock range that was not locked by user

=cut

sub afpRangeNotLocked { -5020 }

=item afpRangeOverlap

 Some or all of range already locked by same user

=cut

sub afpRangeOverlap { -5021 }

=item afpSessClosed

 Session closed

=cut

sub afpSessClosed { -5022 }

=item afpUserNotAuth

 No AFPLogin call has successfully been made for this session

=cut

sub afpUserNotAuth { -5023 }

=item afpCallNotSupported

 Unsupported AFP call was made

=cut

sub afpCallNotSupported { -5024 }

=item afpObjectTypeErr

 File/Directory specified where Directory/File expected

=cut

sub afpObjectTypeErr { -5025 }

=item afpTooManyFilesOpen

 Maximum open file count reached

=cut

sub afpTooManyFilesOpen { -5026 }

=item afpServerGoingDown

 Server is shutting down

=cut

sub afpServerGoingDown { -5027 }

=item afpCantRename

 AFPRename cannot rename volume

=cut

sub afpCantRename { -5028 }

=item afpDirNotFound

 Unknown directory specified

=cut

sub afpDirNotFound { -5029 }

=item afpIconTypeError

 Icon size specified different from existing icon size

=cut

sub afpIconTypeError { -5030 }

=item afpVolLocked

 Volume is Read-Only

=cut

sub afpVolLocked { -5031 }

=item afpObjectLocked

 Object is M/R/D/W inhibited

=cut

sub afpObjectLocked { -5032 }

=item afpContainsSharedErr

 the folder being shared contains a shared folder

=cut

sub afpContainsSharedErr { -5033 }

=item afpIDNotFound

=cut

sub afpIDNotFound { -5034 }

=item afpIDExists

=cut

sub afpIDExists { -5035 }

=item afpDiffVolErr

=cut

sub afpDiffVolErr { -5036 }

=item afpCatalogChanged

=cut

sub afpCatalogChanged { -5037 }

=item afpSameObjectErr

=cut

sub afpSameObjectErr { -5038 }

=item afpBadIDErr

=cut

sub afpBadIDErr { -5039 }

=item afpPwdSameErr

 Someone tried to change their password to the same password on a mantadory password change

=cut

sub afpPwdSameErr { -5040 }

=item afpPwdTooShortErr

 The password being set is too short: there is a minimum length that must be met or exceeded

=cut

sub afpPwdTooShortErr { -5041 }

=item afpPwdExpiredErr

 The password being used is too old: this requires the user to change the password before log-in can continue

=cut

sub afpPwdExpiredErr { -5042 }

=item afpInsideSharedErr

 The folder being shared is inside a shared folder OR the folder contains a shared folder and is being moved into a shared folder
OR the folder contains a shared folder and is being moved into the descendent of a shared folder.

=cut

sub afpInsideSharedErr { -5043 }

=item afpInsideTrashErr

 The folder being shared is inside the trash folder OR the shared folder is being moved into the trash folder
OR the folder is being moved to the trash and it contains a shared folder

=cut

sub afpInsideTrashErr { -5044 }

=item afpPwdNeedsChangeErr

 The password needs to be changed

=cut

sub afpPwdNeedsChangeErr { -5045 }

=item afpPwdPolicyErr

 Password does not conform to servers password policy

=cut

sub afpPwdPolicyErr { -5046 }

=item afpAlreadyLoggedInErr

 User has been authenticated but is already logged in from another machine (and that's not allowed on this server)

=cut

sub afpAlreadyLoggedInErr { -5047 }

=back

=head1 AppleShare Client Errors

=over 4

=item afpBadDirIDType

=cut

sub afpBadDirIDType { -5060 }

=item afpCantMountMoreSrvre

 The Maximum number of server connections has been reached

=cut

sub afpCantMountMoreSrvre { -5061 }

=item afpAlreadyMounted

 The volume is already mounted

=cut

sub afpAlreadyMounted { -5062 }

=back

=head1 NumberFormatting error codes

=over 4

=item numberFormattingNotANumberErr

=cut

sub numberFormattingNotANumberErr { -5200 }

=item numberFormattingOverflowInDestinationErr

=cut

sub numberFormattingOverflowInDestinationErr { -5201 }

=item numberFormattingBadNumberFormattingObjectErr

=cut

sub numberFormattingBadNumberFormattingObjectErr { -5202 }

=item numberFormattingSpuriousCharErr

=cut

sub numberFormattingSpuriousCharErr { -5203 }

=item numberFormattingLiteralMissingErr

=cut

sub numberFormattingLiteralMissingErr { -5204 }

=item numberFormattingDelimiterMissingErr

=cut

sub numberFormattingDelimiterMissingErr { -5205 }

=item numberFormattingEmptyFormatErr

=cut

sub numberFormattingEmptyFormatErr { -5206 }

=item numberFormattingBadFormatErr

=cut

sub numberFormattingBadFormatErr { -5207 }

=item numberFormattingBadOptionsErr

=cut

sub numberFormattingBadOptionsErr { -5208 }

=item numberFormattingBadTokenErr

=cut

sub numberFormattingBadTokenErr { -5209 }

=item numberFormattingUnOrderedCurrencyRangeErr

=cut

sub numberFormattingUnOrderedCurrencyRangeErr { -5210 }

=item numberFormattingBadCurrencyPositionErr

=cut

sub numberFormattingBadCurrencyPositionErr { -5211 }

=item numberFormattingNotADigitErr

 deprecated misspelled versions:

=cut

sub numberFormattingNotADigitErr { -5212 }

=item numberFormattingUnOrdredCurrencyRangeErr

=cut

sub numberFormattingUnOrdredCurrencyRangeErr { -5210 }

=item textParserBadParamErr

=cut

sub textParserBadParamErr { -5220 }

=item textParserObjectNotFoundErr

=cut

sub textParserObjectNotFoundErr { -5221 }

=item textParserBadTokenValueErr

=cut

sub textParserBadTokenValueErr { -5222 }

=item textParserBadParserObjectErr

=cut

sub textParserBadParserObjectErr { -5223 }

=item textParserParamErr

=cut

sub textParserParamErr { -5224 }

=item textParserNoMoreTextErr

=cut

sub textParserNoMoreTextErr { -5225 }

=item textParserBadTextLanguageErr

=cut

sub textParserBadTextLanguageErr { -5226 }

=item textParserBadTextEncodingErr

=cut

sub textParserBadTextEncodingErr { -5227 }

=item textParserNoSuchTokenFoundErr

=cut

sub textParserNoSuchTokenFoundErr { -5228 }

=item errUnknownAttributeTag

=cut

sub errUnknownAttributeTag { -5240 }

=item errMarginWilllNotFit

=cut

sub errMarginWilllNotFit { -5241 }

=item errNotInImagingMode

=cut

sub errNotInImagingMode { -5242 }

=item errAlreadyInImagingMode

=cut

sub errAlreadyInImagingMode { -5243 }

=item errEngineNotFound

=cut

sub errEngineNotFound { -5244 }

=item errIteratorReachedEnd

=cut

sub errIteratorReachedEnd { -5245 }

=item errInvalidRange

=cut

sub errInvalidRange { -5246 }

=item errOffsetNotOnElementBounday

=cut

sub errOffsetNotOnElementBounday { -5247 }

=item errNoHiliteText

=cut

sub errNoHiliteText { -5248 }

=item errEmptyScrap

=cut

sub errEmptyScrap { -5249 }

=item errReadOnlyText

=cut

sub errReadOnlyText { -5250 }

=item errUnknownElement

=cut

sub errUnknownElement { -5251 }

=item errNonContiuousAttribute

=cut

sub errNonContiuousAttribute { -5252 }

=item hrHTMLRenderingLibNotInstalledErr

=cut

sub hrHTMLRenderingLibNotInstalledErr { -5360 }

=item hrMiscellaneousExceptionErr

=cut

sub hrMiscellaneousExceptionErr { -5361 }

=item hrUnableToResizeHandleErr

=cut

sub hrUnableToResizeHandleErr { -5362 }

=item errIANoErr

=cut

sub errIANoErr { 0 }

=item errIAUnknownErr

=cut

sub errIAUnknownErr { -5380 }

=item errIAAllocationErr

=cut

sub errIAAllocationErr { -5381 }

=item errIAParamErr

=cut

sub errIAParamErr { -5382 }

=item errIANoMoreItems

=cut

sub errIANoMoreItems { -5383 }

=item errIABufferTooSmall

=cut

sub errIABufferTooSmall { -5384 }

=item errIACanceled

=cut

sub errIACanceled { -5385 }

=item errIAInvalidDocument

=cut

sub errIAInvalidDocument { -5386 }

=item errIATextExtractionErr

=cut

sub errIATextExtractionErr { -5387 }

=back

=head1 QuickTime Streaming Errors

=over 4

=item qtsBadSelectorErr

=cut

sub qtsBadSelectorErr { -5400 }

=item qtsBadStateErr

=cut

sub qtsBadStateErr { -5401 }

=item qtsBadDataErr

 something is wrong with the data

=cut

sub qtsBadDataErr { -5402 }

=item qtsUnsupportedDataTypeErr

=cut

sub qtsUnsupportedDataTypeErr { -5403 }

=item qtsUnsupportedRateErr

=cut

sub qtsUnsupportedRateErr { -5404 }

=item qtsUnsupportedFeatureErr

=cut

sub qtsUnsupportedFeatureErr { -5405 }

=item qtsTooMuchDataErr

=cut

sub qtsTooMuchDataErr { -5406 }

=item qtsUnknownValueErr

=cut

sub qtsUnknownValueErr { -5407 }

=item qtsTimeoutErr

=cut

sub qtsTimeoutErr { -5408 }

=item qtsConnectionFailedErr

=cut

sub qtsConnectionFailedErr { -5420 }

=back

=head1 Gestalt error codes

=over 4

=item gestaltUnknownErr

 value returned if Gestalt doesn't know the answer

=cut

sub gestaltUnknownErr { -5550 }

=item gestaltUndefSelectorErr

 undefined selector was passed to Gestalt

=cut

sub gestaltUndefSelectorErr { -5551 }

=item gestaltDupSelectorErr

 tried to add an entry that already existed

=cut

sub gestaltDupSelectorErr { -5552 }

=item menuPropertyInvalidErr

 invalid property creator

=cut

sub menuPropertyInvalidErr { -5603 }

=item menuPropertyInvalid

 "menuPropertyInvalid" is deprecated

=cut

sub menuPropertyInvalid { menuPropertyInvalidErr }

=item menuPropertyNotFoundErr

 specified property wasn't found

=cut

sub menuPropertyNotFoundErr { -5604 }

=item menuNotFoundErr

 specified menu or menu ID wasn't found

=cut

sub menuNotFoundErr { -5620 }

=item menuUsesSystemDefErr

 GetMenuDefinition failed because the menu uses the system MDEF

=cut

sub menuUsesSystemDefErr { -5621 }

=item menuItemNotFoundErr

 specified menu item wasn't found

=cut

sub menuItemNotFoundErr { -5622 }

=item errInvalidWindowPtr

 tried to pass a bad WindowRef argument

=cut

sub errInvalidWindowPtr { -5600 }

=item errInvalidWindowRef

 tried to pass a bad WindowRef argument

=cut

sub errInvalidWindowRef { -5600 }

=item errUnsupportedWindowAttributesForClass

 tried to create a window with WindowAttributes not supported by the WindowClass

=cut

sub errUnsupportedWindowAttributesForClass { -5601 }

=item errWindowDoesNotHaveProxy

 tried to do something requiring a proxy to a window which doesn't have a proxy

=cut

sub errWindowDoesNotHaveProxy { -5602 }

=item errInvalidWindowProperty

 tried to access a property tag with private creator

=cut

sub errInvalidWindowProperty { -5603 }

=item errWindowPropertyNotFound

 tried to get a nonexistent property

=cut

sub errWindowPropertyNotFound { -5604 }

=item errUnrecognizedWindowClass

 tried to create a window with a bad WindowClass

=cut

sub errUnrecognizedWindowClass { -5605 }

=item errCorruptWindowDescription

 tried to load a corrupt window description (size or version fields incorrect)

=cut

sub errCorruptWindowDescription { -5606 }

=item errUserWantsToDragWindow

 if returned from TrackWindowProxyDrag, you should call DragWindow on the window

=cut

sub errUserWantsToDragWindow { -5607 }

=item errWindowsAlreadyInitialized

 tried to call InitFloatingWindows twice, or called InitWindows and then floating windows

=cut

sub errWindowsAlreadyInitialized { -5608 }

=item errFloatingWindowsNotInitialized

 called HideFloatingWindows or ShowFloatingWindows without calling InitFloatingWindows

=cut

sub errFloatingWindowsNotInitialized { -5609 }

=item errWindowNotFound

 returned from FindWindowOfClass

=cut

sub errWindowNotFound { -5610 }

=item errWindowDoesNotFitOnscreen

 ConstrainWindowToScreen could not make the window fit onscreen

=cut

sub errWindowDoesNotFitOnscreen { -5611 }

=item windowAttributeImmutableErr

 tried to change attributes which can't be changed

=cut

sub windowAttributeImmutableErr { -5612 }

=item windowAttributesConflictErr

 passed some attributes that are mutually exclusive

=cut

sub windowAttributesConflictErr { -5613 }

=item windowManagerInternalErr

 something really weird happened inside the window manager

=cut

sub windowManagerInternalErr { -5614 }

=item windowWrongStateErr

 window is not in a state that is valid for the current action

=cut

sub windowWrongStateErr { -5615 }

=item windowGroupInvalidErr

 WindowGroup is invalid

=cut

sub windowGroupInvalidErr { -5616 }

=item windowAppModalStateAlreadyExistsErr

 we're already running this window modally

=cut

sub windowAppModalStateAlreadyExistsErr { -5617 }

=item windowNoAppModalStateErr

 there's no app modal state for the window

=cut

sub windowNoAppModalStateErr { -5618 }

=item errWindowDoesntSupportFocus

=cut

sub errWindowDoesntSupportFocus { -30583 }

=item kNavWrongDialogStateErr

=cut

sub kNavWrongDialogStateErr { -5694 }

=item kNavWrongDialogClassErr

=cut

sub kNavWrongDialogClassErr { -5695 }

=item kNavInvalidSystemConfigErr

=cut

sub kNavInvalidSystemConfigErr { -5696 }

=item kNavCustomControlMessageFailedErr

=cut

sub kNavCustomControlMessageFailedErr { -5697 }

=item kNavInvalidCustomControlMessageErr

=cut

sub kNavInvalidCustomControlMessageErr { -5698 }

=item collectionItemLockedErr

=cut

sub collectionItemLockedErr { -5750 }

=item collectionItemNotFoundErr

=cut

sub collectionItemNotFoundErr { -5751 }

=item collectionIndexRangeErr

=cut

sub collectionIndexRangeErr { -5752 }

=back

=head1 Display Manager error codes (-6220...-6269)

=over 4

=item kDMGenErr

 Unexpected Error
Mirroring-Specific Errors

=cut

sub kDMGenErr { -6220 }

=item kDMMirroringOnAlready

 Returned by all calls that need mirroring to be off to do their thing.

=cut

sub kDMMirroringOnAlready { -6221 }

=item kDMWrongNumberOfDisplays

 Can only handle 2 displays for now.

=cut

sub kDMWrongNumberOfDisplays { -6222 }

=item kDMMirroringBlocked

 DMBlockMirroring() has been called.

=cut

sub kDMMirroringBlocked { -6223 }

=item kDMCantBlock

 Mirroring is already on, can't Block now (call DMUnMirror() first).

=cut

sub kDMCantBlock { -6224 }

=item kDMMirroringNotOn

 Returned by all calls that need mirroring to be on to do their thing.
Other Display Manager Errors

=cut

sub kDMMirroringNotOn { -6225 }

=item kSysSWTooOld

 Missing critical pieces of System Software.

=cut

sub kSysSWTooOld { -6226 }

=item kDMSWNotInitializedErr

 Required software not initialized (eg windowmanager or display mgr).

=cut

sub kDMSWNotInitializedErr { -6227 }

=item kDMDriverNotDisplayMgrAwareErr

 Video Driver does not support display manager.

=cut

sub kDMDriverNotDisplayMgrAwareErr { -6228 }

=item kDMDisplayNotFoundErr

 Could not find item (will someday remove).

=cut

sub kDMDisplayNotFoundErr { -6229 }

=item kDMNotFoundErr

 Could not find item.

=cut

sub kDMNotFoundErr { -6229 }

=item kDMDisplayAlreadyInstalledErr

 Attempt to add an already installed display.

=cut

sub kDMDisplayAlreadyInstalledErr { -6230 }

=item kDMMainDisplayCannotMoveErr

 Trying to move main display (or a display mirrored to it)

=cut

sub kDMMainDisplayCannotMoveErr { -6231 }

=item kDMNoDeviceTableclothErr

 obsolete

=cut

sub kDMNoDeviceTableclothErr { -6231 }

=item laTooSmallBufferErr

 output buffer is too small to store any result

=cut

sub laTooSmallBufferErr { -6984 }

=item laEnvironmentBusyErr

 specified environment is used

=cut

sub laEnvironmentBusyErr { -6985 }

=item laEnvironmentNotFoundErr

 can't fint the specified environment

=cut

sub laEnvironmentNotFoundErr { -6986 }

=item laEnvironmentExistErr

 same name environment is already exists

=cut

sub laEnvironmentExistErr { -6987 }

=item laInvalidPathErr

 path is not correct

=cut

sub laInvalidPathErr { -6988 }

=item laNoMoreMorphemeErr

 nothing to read

=cut

sub laNoMoreMorphemeErr { -6989 }

=item laFailAnalysisErr

 analysis failed

=cut

sub laFailAnalysisErr { -6990 }

=item laTextOverFlowErr

 text is too long

=cut

sub laTextOverFlowErr { -6991 }

=item laDictionaryNotOpenedErr

 the dictionary is not opened

=cut

sub laDictionaryNotOpenedErr { -6992 }

=item laDictionaryUnknownErr

 can't use this dictionary with this environment

=cut

sub laDictionaryUnknownErr { -6993 }

=item laDictionaryTooManyErr

 too many dictionaries

=cut

sub laDictionaryTooManyErr { -6994 }

=item laPropertyValueErr

 Invalid property value

=cut

sub laPropertyValueErr { -6995 }

=item laPropertyUnknownErr

 the property is unknown to this environment

=cut

sub laPropertyUnknownErr { -6996 }

=item laPropertyIsReadOnlyErr

 the property is read only

=cut

sub laPropertyIsReadOnlyErr { -6997 }

=item laPropertyNotFoundErr

 can't find the property

=cut

sub laPropertyNotFoundErr { -6998 }

=item laPropertyErr

 Error in properties

=cut

sub laPropertyErr { -6999 }

=item kUSBNoErr

=cut

sub kUSBNoErr { 0 }

=item kUSBNoTran

=cut

sub kUSBNoTran { 0 }

=item kUSBNoDelay

=cut

sub kUSBNoDelay { 0 }

=item kUSBNotSent2Err

 Transaction not sent

=cut

sub kUSBNotSent2Err { -6901 }

=item kUSBNotSent1Err

 Transaction not sent

=cut

sub kUSBNotSent1Err { -6902 }

=item kUSBBufUnderRunErr

 Host hardware failure on data out, PCI busy?

=cut

sub kUSBBufUnderRunErr { -6903 }

=item kUSBBufOvrRunErr

 Host hardware failure on data in, PCI busy?

=cut

sub kUSBBufOvrRunErr { -6904 }

=item kUSBRes2Err

=cut

sub kUSBRes2Err { -6905 }

=item kUSBRes1Err

=cut

sub kUSBRes1Err { -6906 }

=item kUSBUnderRunErr

 Less data than buffer

=cut

sub kUSBUnderRunErr { -6907 }

=item kUSBOverRunErr

 Packet too large or more data than buffer

=cut

sub kUSBOverRunErr { -6908 }

=item kUSBWrongPIDErr

 Pipe stall, Bad or wrong PID

=cut

sub kUSBWrongPIDErr { -6909 }

=item kUSBPIDCheckErr

 Pipe stall, PID CRC error

=cut

sub kUSBPIDCheckErr { -6910 }

=item kUSBNotRespondingErr

 Pipe stall, No device, device hung

=cut

sub kUSBNotRespondingErr { -6911 }

=item kUSBEndpointStallErr

 Device didn't understand

=cut

sub kUSBEndpointStallErr { -6912 }

=item kUSBDataToggleErr

 Pipe stall, Bad data toggle

=cut

sub kUSBDataToggleErr { -6913 }

=item kUSBBitstufErr

 Pipe stall, bitstuffing

=cut

sub kUSBBitstufErr { -6914 }

=item kUSBCRCErr

 Pipe stall, bad CRC

=cut

sub kUSBCRCErr { -6915 }

=item kUSBQueueFull

 Internal queue maxxed

=cut

sub kUSBQueueFull { -6948 }

=item kUSBNotHandled

 Notification was not handled   (same as NotFound)

=cut

sub kUSBNotHandled { -6987 }

=item kUSBUnknownNotification

 Notification type not defined

=cut

sub kUSBUnknownNotification { -6949 }

=item kUSBInternalReserved10

=cut

sub kUSBInternalReserved10 { -6951 }

=item kUSBInternalReserved9

=cut

sub kUSBInternalReserved9 { -6952 }

=item kUSBInternalReserved8

=cut

sub kUSBInternalReserved8 { -6953 }

=item kUSBInternalReserved7

=cut

sub kUSBInternalReserved7 { -6954 }

=item kUSBInternalReserved6

=cut

sub kUSBInternalReserved6 { -6955 }

=item kUSBInternalReserved5

=cut

sub kUSBInternalReserved5 { -6956 }

=item kUSBInternalReserved4

=cut

sub kUSBInternalReserved4 { -6957 }

=item kUSBInternalReserved3

=cut

sub kUSBInternalReserved3 { -6958 }

=item kUSBInternalReserved2

=cut

sub kUSBInternalReserved2 { -6959 }

=item kUSBPortDisabled

 The port you are attached to is disabled, use USBDeviceReset.

=cut

sub kUSBPortDisabled { -6969 }

=item kUSBQueueAborted

 Pipe zero stall cleared.

=cut

sub kUSBQueueAborted { -6970 }

=item kUSBTimedOut

 Transaction timed out.

=cut

sub kUSBTimedOut { -6971 }

=item kUSBDeviceDisconnected

 Disconnected during suspend or reset

=cut

sub kUSBDeviceDisconnected { -6972 }

=item kUSBDeviceNotSuspended

 device is not suspended for resume

=cut

sub kUSBDeviceNotSuspended { -6973 }

=item kUSBDeviceSuspended

 Device is suspended

=cut

sub kUSBDeviceSuspended { -6974 }

=item kUSBInvalidBuffer

 bad buffer, usually nil

=cut

sub kUSBInvalidBuffer { -6975 }

=item kUSBDevicePowerProblem

 Device has a power problem

=cut

sub kUSBDevicePowerProblem { -6976 }

=item kUSBDeviceBusy

 Device is already being configured

=cut

sub kUSBDeviceBusy { -6977 }

=item kUSBUnknownInterfaceErr

 Interface ref not recognised

=cut

sub kUSBUnknownInterfaceErr { -6978 }

=item kUSBPipeStalledError

 Pipe has stalled, error needs to be cleared

=cut

sub kUSBPipeStalledError { -6979 }

=item kUSBPipeIdleError

 Pipe is Idle, it will not accept transactions

=cut

sub kUSBPipeIdleError { -6980 }

=item kUSBNoBandwidthError

 Not enough bandwidth available

=cut

sub kUSBNoBandwidthError { -6981 }

=item kUSBAbortedError

 Pipe aborted

=cut

sub kUSBAbortedError { -6982 }

=item kUSBFlagsError

 Unused flags not zeroed

=cut

sub kUSBFlagsError { -6983 }

=item kUSBCompletionError

 no completion routine specified

=cut

sub kUSBCompletionError { -6984 }

=item kUSBPBLengthError

 pbLength too small

=cut

sub kUSBPBLengthError { -6985 }

=item kUSBPBVersionError

 Wrong pbVersion

=cut

sub kUSBPBVersionError { -6986 }

=item kUSBNotFound

 Not found

=cut

sub kUSBNotFound { -6987 }

=item kUSBOutOfMemoryErr

 Out of memory

=cut

sub kUSBOutOfMemoryErr { -6988 }

=item kUSBDeviceErr

 Device error

=cut

sub kUSBDeviceErr { -6989 }

=item kUSBNoDeviceErr

 No device

=cut

sub kUSBNoDeviceErr { -6990 }

=item kUSBAlreadyOpenErr

 Already open

=cut

sub kUSBAlreadyOpenErr { -6991 }

=item kUSBTooManyTransactionsErr

 Too many transactions

=cut

sub kUSBTooManyTransactionsErr { -6992 }

=item kUSBUnknownRequestErr

 Unknown request

=cut

sub kUSBUnknownRequestErr { -6993 }

=item kUSBRqErr

 Request error

=cut

sub kUSBRqErr { -6994 }

=item kUSBIncorrectTypeErr

 Incorrect type

=cut

sub kUSBIncorrectTypeErr { -6995 }

=item kUSBTooManyPipesErr

 Too many pipes

=cut

sub kUSBTooManyPipesErr { -6996 }

=item kUSBUnknownPipeErr

 Pipe ref not recognised

=cut

sub kUSBUnknownPipeErr { -6997 }

=item kUSBUnknownDeviceErr

 device ref not recognised

=cut

sub kUSBUnknownDeviceErr { -6998 }

=item dcmParamErr

 bad parameter

=cut

sub dcmParamErr { -7100 }

=item dcmNotDictionaryErr

 not dictionary

=cut

sub dcmNotDictionaryErr { -7101 }

=item dcmBadDictionaryErr

 invalid dictionary

=cut

sub dcmBadDictionaryErr { -7102 }

=item dcmPermissionErr

 invalid permission

=cut

sub dcmPermissionErr { -7103 }

=item dcmDictionaryNotOpenErr

 dictionary not opened

=cut

sub dcmDictionaryNotOpenErr { -7104 }

=item dcmDictionaryBusyErr

 dictionary is busy

=cut

sub dcmDictionaryBusyErr { -7105 }

=item dcmBlockFullErr

 dictionary block full

=cut

sub dcmBlockFullErr { -7107 }

=item dcmNoRecordErr

 no such record

=cut

sub dcmNoRecordErr { -7108 }

=item dcmDupRecordErr

 same record already exist

=cut

sub dcmDupRecordErr { -7109 }

=item dcmNecessaryFieldErr

 lack required/identify field

=cut

sub dcmNecessaryFieldErr { -7110 }

=item dcmBadFieldInfoErr

 incomplete information

=cut

sub dcmBadFieldInfoErr { -7111 }

=item dcmBadFieldTypeErr

 no such field type supported

=cut

sub dcmBadFieldTypeErr { -7112 }

=item dcmNoFieldErr

 no such field exist

=cut

sub dcmNoFieldErr { -7113 }

=item dcmBadKeyErr

 bad key information

=cut

sub dcmBadKeyErr { -7115 }

=item dcmTooManyKeyErr

 too many key field

=cut

sub dcmTooManyKeyErr { -7116 }

=item dcmBadDataSizeErr

 too big data size

=cut

sub dcmBadDataSizeErr { -7117 }

=item dcmBadFindMethodErr

 no such find method supported

=cut

sub dcmBadFindMethodErr { -7118 }

=item dcmBadPropertyErr

 no such property exist

=cut

sub dcmBadPropertyErr { -7119 }

=item dcmProtectedErr

 need keyword to use dictionary

=cut

sub dcmProtectedErr { -7121 }

=item dcmNoAccessMethodErr

 no such AccessMethod

=cut

sub dcmNoAccessMethodErr { -7122 }

=item dcmBadFeatureErr

 invalid AccessMethod feature

=cut

sub dcmBadFeatureErr { -7124 }

=item dcmIterationCompleteErr

 no more item in iterator

=cut

sub dcmIterationCompleteErr { -7126 }

=item kRAInvalidParameter

=cut

sub kRAInvalidParameter { -7100 }

=item kRAInvalidPort

=cut

sub kRAInvalidPort { -7101 }

=item kRAStartupFailed

=cut

sub kRAStartupFailed { -7102 }

=item kRAPortSetupFailed

=cut

sub kRAPortSetupFailed { -7103 }

=item kRAOutOfMemory

=cut

sub kRAOutOfMemory { -7104 }

=item kRANotSupported

=cut

sub kRANotSupported { -7105 }

=item kRAMissingResources

=cut

sub kRAMissingResources { -7106 }

=item kRAIncompatiblePrefs

=cut

sub kRAIncompatiblePrefs { -7107 }

=item kRANotConnected

=cut

sub kRANotConnected { -7108 }

=item kRAConnectionCanceled

=cut

sub kRAConnectionCanceled { -7109 }

=item kRAUnknownUser

=cut

sub kRAUnknownUser { -7110 }

=item kRAInvalidPassword

=cut

sub kRAInvalidPassword { -7111 }

=item kRAInternalError

=cut

sub kRAInternalError { -7112 }

=item kRAInstallationDamaged

=cut

sub kRAInstallationDamaged { -7113 }

=item kRAPortBusy

=cut

sub kRAPortBusy { -7114 }

=item kRAUnknownPortState

=cut

sub kRAUnknownPortState { -7115 }

=item kRAInvalidPortState

=cut

sub kRAInvalidPortState { -7116 }

=item kRAInvalidSerialProtocol

=cut

sub kRAInvalidSerialProtocol { -7117 }

=item kRAUserLoginDisabled

=cut

sub kRAUserLoginDisabled { -7118 }

=item kRAUserPwdChangeRequired

=cut

sub kRAUserPwdChangeRequired { -7119 }

=item kRAUserPwdEntryRequired

=cut

sub kRAUserPwdEntryRequired { -7120 }

=item kRAUserInteractionRequired

=cut

sub kRAUserInteractionRequired { -7121 }

=item kRAInitOpenTransportFailed

=cut

sub kRAInitOpenTransportFailed { -7122 }

=item kRARemoteAccessNotReady

=cut

sub kRARemoteAccessNotReady { -7123 }

=item kRATCPIPInactive

 TCP/IP inactive, cannot be loaded

=cut

sub kRATCPIPInactive { -7124 }

=item kRATCPIPNotConfigured

 TCP/IP not configured, could be loaded

=cut

sub kRATCPIPNotConfigured { -7125 }

=item kRANotPrimaryInterface

 when IPCP is not primary TCP/IP intf.

=cut

sub kRANotPrimaryInterface { -7126 }

=item kRAConfigurationDBInitErr

=cut

sub kRAConfigurationDBInitErr { -7127 }

=item kRAPPPProtocolRejected

=cut

sub kRAPPPProtocolRejected { -7128 }

=item kRAPPPAuthenticationFailed

=cut

sub kRAPPPAuthenticationFailed { -7129 }

=item kRAPPPNegotiationFailed

=cut

sub kRAPPPNegotiationFailed { -7130 }

=item kRAPPPUserDisconnected

=cut

sub kRAPPPUserDisconnected { -7131 }

=item kRAPPPPeerDisconnected

=cut

sub kRAPPPPeerDisconnected { -7132 }

=item kRAPeerNotResponding

=cut

sub kRAPeerNotResponding { -7133 }

=item kRAATalkInactive

=cut

sub kRAATalkInactive { -7134 }

=item kRAExtAuthenticationFailed

=cut

sub kRAExtAuthenticationFailed { -7135 }

=item kRANCPRejectedbyPeer

=cut

sub kRANCPRejectedbyPeer { -7136 }

=item kRADuplicateIPAddr

=cut

sub kRADuplicateIPAddr { -7137 }

=item kRACallBackFailed

=cut

sub kRACallBackFailed { -7138 }

=item kATSUInvalidTextLayoutErr

 An attempt was made to use a ATSUTextLayout
which hadn't been initialized or is otherwise

=cut

sub kATSUInvalidTextLayoutErr { -8790 }

=item kATSUInvalidStyleErr

 An attempt was made to use a ATSUStyle which
hadn't been properly allocated or is otherwise

=cut

sub kATSUInvalidStyleErr { -8791 }

=item kATSUInvalidTextRangeErr

 An attempt was made to extract information
from or perform an operation on a ATSUTextLayout

=cut

sub kATSUInvalidTextRangeErr { -8792 }

=item kATSUFontsMatched

 This is not an error code but is returned by
ATSUMatchFontsToText() when changes need to

=cut

sub kATSUFontsMatched { -8793 }

=item kATSUFontsNotMatched

 This value is returned by ATSUMatchFontsToText()
when the text contains Unicode characters which

=cut

sub kATSUFontsNotMatched { -8794 }

=item kATSUNoCorrespondingFontErr

 This value is retrned by font ID conversion
routines ATSUFONDtoFontID() and ATSUFontIDtoFOND()

=cut

sub kATSUNoCorrespondingFontErr { -8795 }

=item kATSUInvalidFontErr

 Used when an attempt was made to use an invalid font ID.

=cut

sub kATSUInvalidFontErr { -8796 }

=item kATSUInvalidAttributeValueErr

 Used when an attempt was made to use an attribute with
a bad or undefined value.

=cut

sub kATSUInvalidAttributeValueErr { -8797 }

=item kATSUInvalidAttributeSizeErr

 Used when an attempt was made to use an attribute with a
bad size.

=cut

sub kATSUInvalidAttributeSizeErr { -8798 }

=item kATSUInvalidAttributeTagErr

 Used when an attempt was made to use a tag value that
was not appropriate for the function call it was used.

=cut

sub kATSUInvalidAttributeTagErr { -8799 }

=item kATSUInvalidCacheErr

 Used when an attempt was made to read in style data
from an invalid cache.  Either the format of the

=cut

sub kATSUInvalidCacheErr { -8800 }

=item kATSUNotSetErr

 Used when the client attempts to retrieve an attribute,
font feature, or font variation from a style when it

=cut

sub kATSUNotSetErr { -8801 }

=item kATSUNoStyleRunsAssignedErr

 Used when an attempt was made to measure, highlight or draw
a ATSUTextLayout object that has no styleRuns associated with it.

=cut

sub kATSUNoStyleRunsAssignedErr { -8802 }

=item kATSUQuickDrawTextErr

 Used when QuickDraw Text encounters an error rendering or measuring
a line of ATSUI text.

=cut

sub kATSUQuickDrawTextErr { -8803 }

=item kATSULowLevelErr

 Used when an error was encountered within the low level ATS
mechanism performing an operation requested by ATSUI.

=cut

sub kATSULowLevelErr { -8804 }

=item kATSUNoFontCmapAvailableErr

 Used when no CMAP table can be accessed or synthesized for the
font passed into a SetAttributes Font call.

=cut

sub kATSUNoFontCmapAvailableErr { -8805 }

=item kATSUNoFontScalerAvailableErr

 Used when no font scaler is available for the font passed
into a SetAttributes Font call.

=cut

sub kATSUNoFontScalerAvailableErr { -8806 }

=item kATSUCoordinateOverflowErr

 Used to indicate the coordinates provided to an ATSUI routine caused
a coordinate overflow (i.e. > 32K).

=cut

sub kATSUCoordinateOverflowErr { -8807 }

=item kATSULineBreakInWord

 This is not an error code but is returned by ATSUBreakLine to
indicate that the returned offset is within a word since there was

=cut

sub kATSULineBreakInWord { -8808 }

=item kATSUBusyObjectErr

 An ATSUI object is being used by another thread

=cut

sub kATSUBusyObjectErr { -8809 }

=item kATSUInvalidFontFallbacksErr

 An attempt was made to use a ATSUFontFallbacks
which hadn't been initialized or is otherwise

=cut

sub kATSUInvalidFontFallbacksErr { -8810 }

=back

=head1 general text errors

=over 4

=item kTextUnsupportedEncodingErr

 specified encoding not supported for this operation

=cut

sub kTextUnsupportedEncodingErr { -8738 }

=item kTextMalformedInputErr

 in DBCS, for example, high byte followed by invalid low byte

=cut

sub kTextMalformedInputErr { -8739 }

=item kTextUndefinedElementErr

 text conversion errors

=cut

sub kTextUndefinedElementErr { -8740 }

=item kTECMissingTableErr

=cut

sub kTECMissingTableErr { -8745 }

=item kTECTableChecksumErr

=cut

sub kTECTableChecksumErr { -8746 }

=item kTECTableFormatErr

=cut

sub kTECTableFormatErr { -8747 }

=item kTECCorruptConverterErr

 invalid converter object reference

=cut

sub kTECCorruptConverterErr { -8748 }

=item kTECNoConversionPathErr

=cut

sub kTECNoConversionPathErr { -8749 }

=item kTECBufferBelowMinimumSizeErr

 output buffer too small to allow processing of first input text element

=cut

sub kTECBufferBelowMinimumSizeErr { -8750 }

=item kTECArrayFullErr

 supplied name buffer or TextRun, TextEncoding, or UnicodeMapping array is too small

=cut

sub kTECArrayFullErr { -8751 }

=item kTECBadTextRunErr

=cut

sub kTECBadTextRunErr { -8752 }

=item kTECPartialCharErr

 input buffer ends in the middle of a multibyte character, conversion stopped

=cut

sub kTECPartialCharErr { -8753 }

=item kTECUnmappableElementErr

=cut

sub kTECUnmappableElementErr { -8754 }

=item kTECIncompleteElementErr

 text element may be incomplete or is too long for internal buffers

=cut

sub kTECIncompleteElementErr { -8755 }

=item kTECDirectionErr

 direction stack overflow, etc.

=cut

sub kTECDirectionErr { -8756 }

=item kTECGlobalsUnavailableErr

 globals have already been deallocated (premature TERM)

=cut

sub kTECGlobalsUnavailableErr { -8770 }

=item kTECItemUnavailableErr

 item (e.g. name) not available for specified region (& encoding if relevant)
text conversion status codes

=cut

sub kTECItemUnavailableErr { -8771 }

=item kTECUsedFallbacksStatus

=cut

sub kTECUsedFallbacksStatus { -8783 }

=item kTECNeedFlushStatus

=cut

sub kTECNeedFlushStatus { -8784 }

=item kTECOutputBufferFullStatus

 output buffer has no room for conversion of next input text element (partial conversion)
deprecated error & status codes for low-level converter

=cut

sub kTECOutputBufferFullStatus { -8785 }

=item unicodeChecksumErr

=cut

sub unicodeChecksumErr { -8769 }

=item unicodeNoTableErr

=cut

sub unicodeNoTableErr { -8768 }

=item unicodeVariantErr

=cut

sub unicodeVariantErr { -8767 }

=item unicodeFallbacksErr

=cut

sub unicodeFallbacksErr { -8766 }

=item unicodePartConvertErr

=cut

sub unicodePartConvertErr { -8765 }

=item unicodeBufErr

=cut

sub unicodeBufErr { -8764 }

=item unicodeCharErr

=cut

sub unicodeCharErr { -8763 }

=item unicodeElementErr

=cut

sub unicodeElementErr { -8762 }

=item unicodeNotFoundErr

=cut

sub unicodeNotFoundErr { -8761 }

=item unicodeTableFormatErr

=cut

sub unicodeTableFormatErr { -8760 }

=item unicodeDirectionErr

=cut

sub unicodeDirectionErr { -8759 }

=item unicodeContextualErr

=cut

sub unicodeContextualErr { -8758 }

=item kUTCUnderflowErr

=cut

sub kUTCUnderflowErr { -8850 }

=item kUTCOverflowErr

=cut

sub kUTCOverflowErr { -8851 }

=item codecErr

=cut

sub codecErr { -8960 }

=item noCodecErr

=cut

sub noCodecErr { -8961 }

=item codecUnimpErr

=cut

sub codecUnimpErr { -8962 }

=item codecSizeErr

=cut

sub codecSizeErr { -8963 }

=item codecScreenBufErr

=cut

sub codecScreenBufErr { -8964 }

=item codecImageBufErr

=cut

sub codecImageBufErr { -8965 }

=item codecSpoolErr

=cut

sub codecSpoolErr { -8966 }

=item codecAbortErr

=cut

sub codecAbortErr { -8967 }

=item codecWouldOffscreenErr

=cut

sub codecWouldOffscreenErr { -8968 }

=item codecBadDataErr

=cut

sub codecBadDataErr { -8969 }

=item codecDataVersErr

=cut

sub codecDataVersErr { -8970 }

=item codecExtensionNotFoundErr

=cut

sub codecExtensionNotFoundErr { -8971 }

=item scTypeNotFoundErr

=cut

sub scTypeNotFoundErr { codecExtensionNotFoundErr }

=item codecConditionErr

=cut

sub codecConditionErr { -8972 }

=item codecOpenErr

=cut

sub codecOpenErr { -8973 }

=item codecCantWhenErr

=cut

sub codecCantWhenErr { -8974 }

=item codecCantQueueErr

=cut

sub codecCantQueueErr { -8975 }

=item codecNothingToBlitErr

=cut

sub codecNothingToBlitErr { -8976 }

=item codecNoMemoryPleaseWaitErr

=cut

sub codecNoMemoryPleaseWaitErr { -8977 }

=item codecDisabledErr

 codec disabled itself -- pass codecFlagReenable to reset

=cut

sub codecDisabledErr { -8978 }

=item codecNeedToFlushChainErr

=cut

sub codecNeedToFlushChainErr { -8979 }

=item lockPortBitsBadSurfaceErr

=cut

sub lockPortBitsBadSurfaceErr { -8980 }

=item lockPortBitsWindowMovedErr

=cut

sub lockPortBitsWindowMovedErr { -8981 }

=item lockPortBitsWindowResizedErr

=cut

sub lockPortBitsWindowResizedErr { -8982 }

=item lockPortBitsWindowClippedErr

=cut

sub lockPortBitsWindowClippedErr { -8983 }

=item lockPortBitsBadPortErr

=cut

sub lockPortBitsBadPortErr { -8984 }

=item lockPortBitsSurfaceLostErr

=cut

sub lockPortBitsSurfaceLostErr { -8985 }

=item codecParameterDialogConfirm

=cut

sub codecParameterDialogConfirm { -8986 }

=item codecNeedAccessKeyErr

 codec needs password in order to decompress

=cut

sub codecNeedAccessKeyErr { -8987 }

=item codecOffscreenFailedErr

=cut

sub codecOffscreenFailedErr { -8988 }

=item codecDroppedFrameErr

 returned from ImageCodecDrawBand

=cut

sub codecDroppedFrameErr { -8989 }

=item directXObjectAlreadyExists

=cut

sub directXObjectAlreadyExists { -8990 }

=item lockPortBitsWrongGDeviceErr

=cut

sub lockPortBitsWrongGDeviceErr { -8991 }

=item kBadAdapterErr

 invalid adapter number

=cut

sub kBadAdapterErr { -9050 }

=item kBadAttributeErr

 specified attributes field value is invalid

=cut

sub kBadAttributeErr { -9051 }

=item kBadBaseErr

 specified base system memory address is invalid

=cut

sub kBadBaseErr { -9052 }

=item kBadEDCErr

 specified EDC generator specified is invalid

=cut

sub kBadEDCErr { -9053 }

=item kBadIRQErr

 specified IRQ level is invalid

=cut

sub kBadIRQErr { -9054 }

=item kBadOffsetErr

 specified PC card memory array offset is invalid

=cut

sub kBadOffsetErr { -9055 }

=item kBadPageErr

 specified page is invalid

=cut

sub kBadPageErr { -9056 }

=item kBadSizeErr

 specified size is invalid

=cut

sub kBadSizeErr { -9057 }

=item kBadSocketErr

 specified logical or physical socket number is invalid

=cut

sub kBadSocketErr { -9058 }

=item kBadTypeErr

 specified window or interface type is invalid

=cut

sub kBadTypeErr { -9059 }

=item kBadVccErr

 specified Vcc power level index is invalid

=cut

sub kBadVccErr { -9060 }

=item kBadVppErr

 specified Vpp1 or Vpp2 power level index is invalid

=cut

sub kBadVppErr { -9061 }

=item kBadWindowErr

 specified window is invalid

=cut

sub kBadWindowErr { -9062 }

=item kBadArgLengthErr

 ArgLength argument is invalid

=cut

sub kBadArgLengthErr { -9063 }

=item kBadArgsErr

 values in argument packet are invalid

=cut

sub kBadArgsErr { -9064 }

=item kBadHandleErr

 clientHandle is invalid

=cut

sub kBadHandleErr { -9065 }

=item kBadCISErr

 CIS on card is invalid

=cut

sub kBadCISErr { -9066 }

=item kBadSpeedErr

 specified speed is unavailable

=cut

sub kBadSpeedErr { -9067 }

=item kReadFailureErr

 unable to complete read request

=cut

sub kReadFailureErr { -9068 }

=item kWriteFailureErr

 unable to complete write request

=cut

sub kWriteFailureErr { -9069 }

=item kGeneralFailureErr

 an undefined error has occurred

=cut

sub kGeneralFailureErr { -9070 }

=item kNoCardErr

 no PC card in the socket

=cut

sub kNoCardErr { -9071 }

=item kUnsupportedFunctionErr

 function is not supported by this implementation

=cut

sub kUnsupportedFunctionErr { -9072 }

=item kUnsupportedModeErr

 mode is not supported

=cut

sub kUnsupportedModeErr { -9073 }

=item kBusyErr

 unable to process request at this time - try later

=cut

sub kBusyErr { -9074 }

=item kWriteProtectedErr

 media is write-protected

=cut

sub kWriteProtectedErr { -9075 }

=item kConfigurationLockedErr

 a configuration has already been locked

=cut

sub kConfigurationLockedErr { -9076 }

=item kInUseErr

 requested resource is being used by a client

=cut

sub kInUseErr { -9077 }

=item kNoMoreItemsErr

 there are no more of the requested item

=cut

sub kNoMoreItemsErr { -9078 }

=item kOutOfResourceErr

 Card Services has exhausted the resource

=cut

sub kOutOfResourceErr { -9079 }

=item kNoCardSevicesSocketsErr

=cut

sub kNoCardSevicesSocketsErr { -9080 }

=item kInvalidRegEntryErr

=cut

sub kInvalidRegEntryErr { -9081 }

=item kBadLinkErr

=cut

sub kBadLinkErr { -9082 }

=item kBadDeviceErr

=cut

sub kBadDeviceErr { -9083 }

=item k16BitCardErr

=cut

sub k16BitCardErr { -9084 }

=item kCardBusCardErr

=cut

sub kCardBusCardErr { -9085 }

=item kPassCallToChainErr

=cut

sub kPassCallToChainErr { -9086 }

=item kCantConfigureCardErr

=cut

sub kCantConfigureCardErr { -9087 }

=item kPostCardEventErr

 _PCCSLPostCardEvent failed and dropped an event

=cut

sub kPostCardEventErr { -9088 }

=item kInvalidDeviceNumber

=cut

sub kInvalidDeviceNumber { -9089 }

=item kUnsupportedVsErr

 Unsupported Voltage Sense

=cut

sub kUnsupportedVsErr { -9090 }

=item kInvalidCSClientErr

 Card Services ClientID is not registered

=cut

sub kInvalidCSClientErr { -9091 }

=item kBadTupleDataErr

 Data in tuple is invalid

=cut

sub kBadTupleDataErr { -9092 }

=item kBadCustomIFIDErr

 Custom interface ID is invalid

=cut

sub kBadCustomIFIDErr { -9093 }

=item kNoIOWindowRequestedErr

 Request I/O window before calling configuration

=cut

sub kNoIOWindowRequestedErr { -9094 }

=item kNoMoreTimerClientsErr

 All timer callbacks are in use

=cut

sub kNoMoreTimerClientsErr { -9095 }

=item kNoMoreInterruptSlotsErr

 All internal Interrupt slots are in use

=cut

sub kNoMoreInterruptSlotsErr { -9096 }

=item kNoClientTableErr

 The client table has not be initialized yet

=cut

sub kNoClientTableErr { -9097 }

=item kUnsupportedCardErr

 Card not supported by generic enabler

=cut

sub kUnsupportedCardErr { -9098 }

=item kNoCardEnablersFoundErr

 No Enablers were found

=cut

sub kNoCardEnablersFoundErr { -9099 }

=item kNoEnablerForCardErr

 No Enablers were found that can support the card

=cut

sub kNoEnablerForCardErr { -9100 }

=item kNoCompatibleNameErr

 There is no compatible driver name for this device

=cut

sub kNoCompatibleNameErr { -9101 }

=item kClientRequestDenied

 CS Clients should return this code inorder to
deny a request-type CS Event

=cut

sub kClientRequestDenied { -9102 }

=item kNotReadyErr

 PC Card failed to go ready

=cut

sub kNotReadyErr { -9103 }

=item kTooManyIOWindowsErr

 device requested more than one I/O window

=cut

sub kTooManyIOWindowsErr { -9104 }

=item kAlreadySavedStateErr

 The state has been saved on previous call

=cut

sub kAlreadySavedStateErr { -9105 }

=item kAttemptDupCardEntryErr

 The Enabler was asked to create a duplicate card entry

=cut

sub kAttemptDupCardEntryErr { -9106 }

=item kCardPowerOffErr

 Power to the card has been turned off

=cut

sub kCardPowerOffErr { -9107 }

=item kNotZVCapableErr

 This socket does not support Zoomed Video

=cut

sub kNotZVCapableErr { -9108 }

=item noDeviceForChannel

=cut

sub noDeviceForChannel { -9400 }

=item grabTimeComplete

=cut

sub grabTimeComplete { -9401 }

=item cantDoThatInCurrentMode

=cut

sub cantDoThatInCurrentMode { -9402 }

=item notEnoughMemoryToGrab

=cut

sub notEnoughMemoryToGrab { -9403 }

=item notEnoughDiskSpaceToGrab

=cut

sub notEnoughDiskSpaceToGrab { -9404 }

=item couldntGetRequiredComponent

=cut

sub couldntGetRequiredComponent { -9405 }

=item badSGChannel

=cut

sub badSGChannel { -9406 }

=item seqGrabInfoNotAvailable

=cut

sub seqGrabInfoNotAvailable { -9407 }

=item deviceCantMeetRequest

=cut

sub deviceCantMeetRequest { -9408 }

=item badControllerHeight

=cut

sub badControllerHeight { -9994 }

=item editingNotAllowed

=cut

sub editingNotAllowed { -9995 }

=item controllerBoundsNotExact

=cut

sub controllerBoundsNotExact { -9996 }

=item cannotSetWidthOfAttachedController

=cut

sub cannotSetWidthOfAttachedController { -9997 }

=item controllerHasFixedHeight

=cut

sub controllerHasFixedHeight { -9998 }

=item errAEBadKeyForm

=cut

sub errAEBadKeyForm { -10002 }

=item errAECantHandleClass

=cut

sub errAECantHandleClass { -10010 }

=item errAECantSupplyType

=cut

sub errAECantSupplyType { -10009 }

=item errAECantUndo

=cut

sub errAECantUndo { -10015 }

=item errAEEventFailed

=cut

sub errAEEventFailed { -10000 }

=item errAEIndexTooLarge

=cut

sub errAEIndexTooLarge { -10007 }

=item errAEInTransaction

=cut

sub errAEInTransaction { -10011 }

=item errAELocalOnly

=cut

sub errAELocalOnly { -10016 }

=item errAENoSuchTransaction

=cut

sub errAENoSuchTransaction { -10012 }

=item errAENotAnElement

=cut

sub errAENotAnElement { -10008 }

=item errAENotASingleObject

=cut

sub errAENotASingleObject { -10014 }

=item errAENotModifiable

=cut

sub errAENotModifiable { -10003 }

=item errAENoUserSelection

=cut

sub errAENoUserSelection { -10013 }

=item errAEPrivilegeError

=cut

sub errAEPrivilegeError { -10004 }

=item errAEReadDenied

=cut

sub errAEReadDenied { -10005 }

=item errAETypeError

=cut

sub errAETypeError { -10001 }

=item errAEWriteDenied

=cut

sub errAEWriteDenied { -10006 }

=item errAENotAnEnumMember

 enumerated value in SetData is not allowed for this property

=cut

sub errAENotAnEnumMember { -10023 }

=item errAECantPutThatThere

 in make new, duplicate, etc. class can't be an element of container

=cut

sub errAECantPutThatThere { -10024 }

=item telGenericError

=cut

sub telGenericError { -1 }

=item telNoErr

=cut

sub telNoErr { 0 }

=item telNoTools

 no telephone tools found in extension folder

=cut

sub telNoTools { 8 }

=item telBadTermErr

 invalid TELHandle or handle not found

=cut

sub telBadTermErr { -10001 }

=item telBadDNErr

 TELDNHandle not found or invalid

=cut

sub telBadDNErr { -10002 }

=item telBadCAErr

 TELCAHandle not found or invalid

=cut

sub telBadCAErr { -10003 }

=item telBadHandErr

 bad handle specified

=cut

sub telBadHandErr { -10004 }

=item telBadProcErr

 bad msgProc specified

=cut

sub telBadProcErr { -10005 }

=item telCAUnavail

 a CA is not available

=cut

sub telCAUnavail { -10006 }

=item telNoMemErr

 no memory to allocate handle

=cut

sub telNoMemErr { -10007 }

=item telNoOpenErr

 unable to open terminal

=cut

sub telNoOpenErr { -10008 }

=item telBadHTypeErr

 bad hook type specified

=cut

sub telBadHTypeErr { -10010 }

=item telHTypeNotSupp

 hook type not supported by this tool

=cut

sub telHTypeNotSupp { -10011 }

=item telBadLevelErr

 bad volume level setting

=cut

sub telBadLevelErr { -10012 }

=item telBadVTypeErr

 bad volume type error

=cut

sub telBadVTypeErr { -10013 }

=item telVTypeNotSupp

 volume type not supported by this tool

=cut

sub telVTypeNotSupp { -10014 }

=item telBadAPattErr

 bad alerting pattern specified

=cut

sub telBadAPattErr { -10015 }

=item telAPattNotSupp

 alerting pattern not supported by tool

=cut

sub telAPattNotSupp { -10016 }

=item telBadIndex

 bad index specified

=cut

sub telBadIndex { -10017 }

=item telIndexNotSupp

 index not supported by this tool

=cut

sub telIndexNotSupp { -10018 }

=item telBadStateErr

 bad device state specified

=cut

sub telBadStateErr { -10019 }

=item telStateNotSupp

 device state not supported by tool

=cut

sub telStateNotSupp { -10020 }

=item telBadIntExt

 bad internal external error

=cut

sub telBadIntExt { -10021 }

=item telIntExtNotSupp

 internal external type not supported by this tool

=cut

sub telIntExtNotSupp { -10022 }

=item telBadDNDType

 bad DND type specified

=cut

sub telBadDNDType { -10023 }

=item telDNDTypeNotSupp

 DND type is not supported by this tool

=cut

sub telDNDTypeNotSupp { -10024 }

=item telFeatNotSub

 feature not subscribed

=cut

sub telFeatNotSub { -10030 }

=item telFeatNotAvail

 feature subscribed but not available

=cut

sub telFeatNotAvail { -10031 }

=item telFeatActive

 feature already active

=cut

sub telFeatActive { -10032 }

=item telFeatNotSupp

 feature program call not supported by this tool

=cut

sub telFeatNotSupp { -10033 }

=item telConfLimitErr

 limit specified is too high for this configuration

=cut

sub telConfLimitErr { -10040 }

=item telConfNoLimit

 no limit was specified but required

=cut

sub telConfNoLimit { -10041 }

=item telConfErr

 conference was not prepared

=cut

sub telConfErr { -10042 }

=item telConfRej

 conference request was rejected

=cut

sub telConfRej { -10043 }

=item telTransferErr

 transfer not prepared

=cut

sub telTransferErr { -10044 }

=item telTransferRej

 transfer request rejected

=cut

sub telTransferRej { -10045 }

=item telCBErr

 call back feature not set previously

=cut

sub telCBErr { -10046 }

=item telConfLimitExceeded

 attempt to exceed switch conference limits

=cut

sub telConfLimitExceeded { -10047 }

=item telBadDNType

 DN type invalid

=cut

sub telBadDNType { -10050 }

=item telBadPageID

 bad page ID specified

=cut

sub telBadPageID { -10051 }

=item telBadIntercomID

 bad intercom ID specified

=cut

sub telBadIntercomID { -10052 }

=item telBadFeatureID

 bad feature ID specified

=cut

sub telBadFeatureID { -10053 }

=item telBadFwdType

 bad fwdType specified

=cut

sub telBadFwdType { -10054 }

=item telBadPickupGroupID

 bad pickup group ID specified

=cut

sub telBadPickupGroupID { -10055 }

=item telBadParkID

 bad park id specified

=cut

sub telBadParkID { -10056 }

=item telBadSelect

 unable to select or deselect DN

=cut

sub telBadSelect { -10057 }

=item telBadBearerType

 bad bearerType specified

=cut

sub telBadBearerType { -10058 }

=item telBadRate

 bad rate specified

=cut

sub telBadRate { -10059 }

=item telDNTypeNotSupp

 DN type not supported by tool

=cut

sub telDNTypeNotSupp { -10060 }

=item telFwdTypeNotSupp

 forward type not supported by tool

=cut

sub telFwdTypeNotSupp { -10061 }

=item telBadDisplayMode

 bad display mode specified

=cut

sub telBadDisplayMode { -10062 }

=item telDisplayModeNotSupp

 display mode not supported by tool

=cut

sub telDisplayModeNotSupp { -10063 }

=item telNoCallbackRef

 no call back reference was specified, but is required

=cut

sub telNoCallbackRef { -10064 }

=item telAlreadyOpen

 terminal already open

=cut

sub telAlreadyOpen { -10070 }

=item telStillNeeded

 terminal driver still needed by someone else

=cut

sub telStillNeeded { -10071 }

=item telTermNotOpen

 terminal not opened via TELOpenTerm

=cut

sub telTermNotOpen { -10072 }

=item telCANotAcceptable

 CA not "acceptable"

=cut

sub telCANotAcceptable { -10080 }

=item telCANotRejectable

 CA not "rejectable"

=cut

sub telCANotRejectable { -10081 }

=item telCANotDeflectable

 CA not "deflectable"

=cut

sub telCANotDeflectable { -10082 }

=item telPBErr

 parameter block error, bad format

=cut

sub telPBErr { -10090 }

=item telBadFunction

 bad msgCode specified
telNoTools        = -10101,        unable to find any telephone tools

=cut

sub telBadFunction { -10091 }

=item telNoSuchTool

 unable to find tool with name specified

=cut

sub telNoSuchTool { -10102 }

=item telUnknownErr

 unable to set config

=cut

sub telUnknownErr { -10103 }

=item telNoCommFolder

 Communications/Extensions Ä not found

=cut

sub telNoCommFolder { -10106 }

=item telInitFailed

 initialization failed

=cut

sub telInitFailed { -10107 }

=item telBadCodeResource

 code resource not found

=cut

sub telBadCodeResource { -10108 }

=item telDeviceNotFound

 device not found

=cut

sub telDeviceNotFound { -10109 }

=item telBadProcID

 invalid procID

=cut

sub telBadProcID { -10110 }

=item telValidateFailed

 telValidate failed

=cut

sub telValidateFailed { -10111 }

=item telAutoAnsNotOn

 autoAnswer in not turned on

=cut

sub telAutoAnsNotOn { -10112 }

=item telDetAlreadyOn

 detection is already turned on

=cut

sub telDetAlreadyOn { -10113 }

=item telBadSWErr

 Software not installed properly

=cut

sub telBadSWErr { -10114 }

=item telBadSampleRate

 incompatible sample rate

=cut

sub telBadSampleRate { -10115 }

=back

=head1 Power Manager Errors

=over 4

=item pmBusyErr

 Power Mgr never ready to start handshake

=cut

sub pmBusyErr { -13000 }

=item pmReplyTOErr

 Timed out waiting for reply

=cut

sub pmReplyTOErr { -13001 }

=item pmSendStartErr

 during send, pmgr did not start hs

=cut

sub pmSendStartErr { -13002 }

=item pmSendEndErr

 during send, pmgr did not finish hs

=cut

sub pmSendEndErr { -13003 }

=item pmRecvStartErr

 during receive, pmgr did not start hs

=cut

sub pmRecvStartErr { -13004 }

=item kPowerHandlerExistsForDeviceErr

=cut

sub kPowerHandlerExistsForDeviceErr { -13006 }

=item kPowerHandlerNotFoundForDeviceErr

=cut

sub kPowerHandlerNotFoundForDeviceErr { -13007 }

=item kPowerHandlerNotFoundForProcErr

=cut

sub kPowerHandlerNotFoundForProcErr { -13008 }

=item kPowerMgtMessageNotHandled

=cut

sub kPowerMgtMessageNotHandled { -13009 }

=item kPowerMgtRequestDenied

=cut

sub kPowerMgtRequestDenied { -13010 }

=item kCantReportProcessorTemperatureErr

=cut

sub kCantReportProcessorTemperatureErr { -13013 }

=item kProcessorTempRoutineRequiresMPLib2

=cut

sub kProcessorTempRoutineRequiresMPLib2 { -13014 }

=item kNoSuchPowerSource

=cut

sub kNoSuchPowerSource { -13020 }

=item debuggingExecutionContextErr

 routine cannot be called at this time

=cut

sub debuggingExecutionContextErr { -13880 }

=item debuggingDuplicateSignatureErr

 componentSignature already registered

=cut

sub debuggingDuplicateSignatureErr { -13881 }

=item debuggingDuplicateOptionErr

 optionSelectorNum already registered

=cut

sub debuggingDuplicateOptionErr { -13882 }

=item debuggingInvalidSignatureErr

 componentSignature not registered

=cut

sub debuggingInvalidSignatureErr { -13883 }

=item debuggingInvalidOptionErr

 optionSelectorNum is not registered

=cut

sub debuggingInvalidOptionErr { -13884 }

=item debuggingInvalidNameErr

 componentName or optionName is invalid (NULL)

=cut

sub debuggingInvalidNameErr { -13885 }

=item debuggingNoCallbackErr

 debugging component has no callback

=cut

sub debuggingNoCallbackErr { -13886 }

=item kHIDVersionIncompatibleErr

=cut

sub kHIDVersionIncompatibleErr { -13909 }

=item kHIDSuccess

=cut

sub kHIDSuccess { 0 }

=item kHIDInvalidRangePageErr

=cut

sub kHIDInvalidRangePageErr { -13923 }

=item kHIDReportIDZeroErr

=cut

sub kHIDReportIDZeroErr { -13924 }

=item kHIDReportCountZeroErr

=cut

sub kHIDReportCountZeroErr { -13925 }

=item kHIDReportSizeZeroErr

=cut

sub kHIDReportSizeZeroErr { -13926 }

=item kHIDUnmatchedDesignatorRangeErr

=cut

sub kHIDUnmatchedDesignatorRangeErr { -13927 }

=item kHIDUnmatchedStringRangeErr

=cut

sub kHIDUnmatchedStringRangeErr { -13928 }

=item kHIDInvertedUsageRangeErr

=cut

sub kHIDInvertedUsageRangeErr { -13929 }

=item kHIDUnmatchedUsageRangeErr

=cut

sub kHIDUnmatchedUsageRangeErr { -13930 }

=item kHIDInvertedPhysicalRangeErr

=cut

sub kHIDInvertedPhysicalRangeErr { -13931 }

=item kHIDInvertedLogicalRangeErr

=cut

sub kHIDInvertedLogicalRangeErr { -13932 }

=item kHIDBadLogicalMaximumErr

=cut

sub kHIDBadLogicalMaximumErr { -13933 }

=item kHIDBadLogicalMinimumErr

=cut

sub kHIDBadLogicalMinimumErr { -13934 }

=item kHIDUsagePageZeroErr

=cut

sub kHIDUsagePageZeroErr { -13935 }

=item kHIDEndOfDescriptorErr

=cut

sub kHIDEndOfDescriptorErr { -13936 }

=item kHIDNotEnoughMemoryErr

=cut

sub kHIDNotEnoughMemoryErr { -13937 }

=item kHIDBadParameterErr

=cut

sub kHIDBadParameterErr { -13938 }

=item kHIDNullPointerErr

=cut

sub kHIDNullPointerErr { -13939 }

=item kHIDInvalidReportLengthErr

=cut

sub kHIDInvalidReportLengthErr { -13940 }

=item kHIDInvalidReportTypeErr

=cut

sub kHIDInvalidReportTypeErr { -13941 }

=item kHIDBadLogPhysValuesErr

=cut

sub kHIDBadLogPhysValuesErr { -13942 }

=item kHIDIncompatibleReportErr

=cut

sub kHIDIncompatibleReportErr { -13943 }

=item kHIDInvalidPreparsedDataErr

=cut

sub kHIDInvalidPreparsedDataErr { -13944 }

=item kHIDNotValueArrayErr

=cut

sub kHIDNotValueArrayErr { -13945 }

=item kHIDUsageNotFoundErr

=cut

sub kHIDUsageNotFoundErr { -13946 }

=item kHIDValueOutOfRangeErr

=cut

sub kHIDValueOutOfRangeErr { -13947 }

=item kHIDBufferTooSmallErr

=cut

sub kHIDBufferTooSmallErr { -13948 }

=item kHIDNullStateErr

=cut

sub kHIDNullStateErr { -13949 }

=item kModemOutOfMemory

=cut

sub kModemOutOfMemory { -14000 }

=item kModemPreferencesMissing

=cut

sub kModemPreferencesMissing { -14001 }

=item kTXNEndIterationErr

=cut

sub kTXNEndIterationErr { -22000 }

=item kTXNCannotAddFrameErr

=cut

sub kTXNCannotAddFrameErr { -22001 }

=item kTXNInvalidFrameIDErr

=cut

sub kTXNInvalidFrameIDErr { -22002 }

=item kTXNIllegalToCrossDataBoundariesErr

=cut

sub kTXNIllegalToCrossDataBoundariesErr { -22003 }

=item kTXNUserCanceledOperationErr

=cut

sub kTXNUserCanceledOperationErr { -22004 }

=item kTXNBadDefaultFileTypeWarning

=cut

sub kTXNBadDefaultFileTypeWarning { -22005 }

=item kTXNCannotSetAutoIndentErr

=cut

sub kTXNCannotSetAutoIndentErr { -22006 }

=item kTXNRunIndexOutofBoundsErr

=cut

sub kTXNRunIndexOutofBoundsErr { -22007 }

=item kTXNNoMatchErr

=cut

sub kTXNNoMatchErr { -22008 }

=item kTXNAttributeTagInvalidForRunErr

 dataValue is set to this per invalid tag

=cut

sub kTXNAttributeTagInvalidForRunErr { -22009 }

=item kTXNSomeOrAllTagsInvalidForRunErr

=cut

sub kTXNSomeOrAllTagsInvalidForRunErr { -22010 }

=item kTXNInvalidRunIndex

=cut

sub kTXNInvalidRunIndex { -22011 }

=item kTXNAlreadyInitializedErr

=cut

sub kTXNAlreadyInitializedErr { -22012 }

=item kTXNCannotTurnTSMOffWhenUsingUnicodeErr

=cut

sub kTXNCannotTurnTSMOffWhenUsingUnicodeErr { -22013 }

=item kTXNCopyNotAllowedInEchoModeErr

=cut

sub kTXNCopyNotAllowedInEchoModeErr { -22014 }

=item kTXNDataTypeNotAllowedErr

=cut

sub kTXNDataTypeNotAllowedErr { -22015 }

=item kTXNATSUIIsNotInstalledErr

=cut

sub kTXNATSUIIsNotInstalledErr { -22016 }

=item kTXNOutsideOfLineErr

=cut

sub kTXNOutsideOfLineErr { -22017 }

=item errKCNotAvailable

=cut

sub errKCNotAvailable { -25291 }

=item errKCReadOnly

=cut

sub errKCReadOnly { -25292 }

=item errKCAuthFailed

=cut

sub errKCAuthFailed { -25293 }

=item errKCNoSuchKeychain

=cut

sub errKCNoSuchKeychain { -25294 }

=item errKCInvalidKeychain

=cut

sub errKCInvalidKeychain { -25295 }

=item errKCDuplicateKeychain

=cut

sub errKCDuplicateKeychain { -25296 }

=item errKCDuplicateCallback

=cut

sub errKCDuplicateCallback { -25297 }

=item errKCInvalidCallback

=cut

sub errKCInvalidCallback { -25298 }

=item errKCDuplicateItem

=cut

sub errKCDuplicateItem { -25299 }

=item errKCItemNotFound

=cut

sub errKCItemNotFound { -25300 }

=item errKCBufferTooSmall

=cut

sub errKCBufferTooSmall { -25301 }

=item errKCDataTooLarge

=cut

sub errKCDataTooLarge { -25302 }

=item errKCNoSuchAttr

=cut

sub errKCNoSuchAttr { -25303 }

=item errKCInvalidItemRef

=cut

sub errKCInvalidItemRef { -25304 }

=item errKCInvalidSearchRef

=cut

sub errKCInvalidSearchRef { -25305 }

=item errKCNoSuchClass

=cut

sub errKCNoSuchClass { -25306 }

=item errKCNoDefaultKeychain

=cut

sub errKCNoDefaultKeychain { -25307 }

=item errKCInteractionNotAllowed

=cut

sub errKCInteractionNotAllowed { -25308 }

=item errKCReadOnlyAttr

=cut

sub errKCReadOnlyAttr { -25309 }

=item errKCWrongKCVersion

=cut

sub errKCWrongKCVersion { -25310 }

=item errKCKeySizeNotAllowed

=cut

sub errKCKeySizeNotAllowed { -25311 }

=item errKCNoStorageModule

=cut

sub errKCNoStorageModule { -25312 }

=item errKCNoCertificateModule

=cut

sub errKCNoCertificateModule { -25313 }

=item errKCNoPolicyModule

=cut

sub errKCNoPolicyModule { -25314 }

=item errKCInteractionRequired

=cut

sub errKCInteractionRequired { -25315 }

=item errKCDataNotAvailable

=cut

sub errKCDataNotAvailable { -25316 }

=item errKCDataNotModifiable

=cut

sub errKCDataNotModifiable { -25317 }

=item kUCOutputBufferTooSmall

 Output buffer too small for Unicode string result

=cut

sub kUCOutputBufferTooSmall { -25340 }

=item kUCTSNoKeysAddedToObjectErr

=cut

sub kUCTSNoKeysAddedToObjectErr { -25342 }

=item kMPIterationEndErr

=cut

sub kMPIterationEndErr { -29275 }

=item kMPPrivilegedErr

=cut

sub kMPPrivilegedErr { -29276 }

=item kMPProcessCreatedErr

=cut

sub kMPProcessCreatedErr { -29288 }

=item kMPProcessTerminatedErr

=cut

sub kMPProcessTerminatedErr { -29289 }

=item kMPTaskCreatedErr

=cut

sub kMPTaskCreatedErr { -29290 }

=item kMPTaskBlockedErr

=cut

sub kMPTaskBlockedErr { -29291 }

=item kMPTaskStoppedErr

 A convention used with MPThrowException.

=cut

sub kMPTaskStoppedErr { -29292 }

=item kMPBlueBlockingErr

=cut

sub kMPBlueBlockingErr { -29293 }

=item kMPDeletedErr

=cut

sub kMPDeletedErr { -29295 }

=item kMPTimeoutErr

=cut

sub kMPTimeoutErr { -29296 }

=item kMPTaskAbortedErr

=cut

sub kMPTaskAbortedErr { -29297 }

=item kMPInsufficientResourcesErr

=cut

sub kMPInsufficientResourcesErr { -29298 }

=item kCollateAttributesNotFoundErr

=cut

sub kCollateAttributesNotFoundErr { -29500 }

=item kCollateInvalidOptions

=cut

sub kCollateInvalidOptions { -29501 }

=item kCollateMissingUnicodeTableErr

=cut

sub kCollateMissingUnicodeTableErr { -29502 }

=item kCollateUnicodeConvertFailedErr

=cut

sub kCollateUnicodeConvertFailedErr { -29503 }

=item kCollatePatternNotFoundErr

=cut

sub kCollatePatternNotFoundErr { -29504 }

=item kCollateInvalidChar

=cut

sub kCollateInvalidChar { -29505 }

=item kCollateBufferTooSmall

=cut

sub kCollateBufferTooSmall { -29506 }

=item kFNSInvalidReferenceErr

 ref. was NULL or otherwise bad

=cut

sub kFNSInvalidReferenceErr { -29580 }

=item kFNSBadReferenceVersionErr

 ref. version is out of known range

=cut

sub kFNSBadReferenceVersionErr { -29581 }

=item kFNSInvalidProfileErr

 profile is NULL or otherwise bad

=cut

sub kFNSInvalidProfileErr { -29582 }

=item kFNSBadProfileVersionErr

 profile version is out of known range

=cut

sub kFNSBadProfileVersionErr { -29583 }

=item kFNSDuplicateReferenceErr

 the ref. being added is already in the profile

=cut

sub kFNSDuplicateReferenceErr { -29584 }

=item kFNSMismatchErr

 reference didn't match or wasn't found in profile

=cut

sub kFNSMismatchErr { -29585 }

=item kFNSInsufficientDataErr

 insufficient data for the operation

=cut

sub kFNSInsufficientDataErr { -29586 }

=item kFNSBadFlattenedSizeErr

 flattened size didn't match input or was too small

=cut

sub kFNSBadFlattenedSizeErr { -29587 }

=item kLocalesBufferTooSmallErr

=cut

sub kLocalesBufferTooSmallErr { -30001 }

=item kLocalesTableFormatErr

=cut

sub kLocalesTableFormatErr { -30002 }

=item kALMInternalErr

=cut

sub kALMInternalErr { -30049 }

=item kALMGroupNotFoundErr

=cut

sub kALMGroupNotFoundErr { -30048 }

=item kALMNoSuchModuleErr

=cut

sub kALMNoSuchModuleErr { -30047 }

=item kALMModuleCommunicationErr

=cut

sub kALMModuleCommunicationErr { -30046 }

=item kALMDuplicateModuleErr

=cut

sub kALMDuplicateModuleErr { -30045 }

=item kALMInstallationErr

=cut

sub kALMInstallationErr { -30044 }

=item kALMDeferSwitchErr

=cut

sub kALMDeferSwitchErr { -30043 }

=item kSSpInternalErr

=cut

sub kSSpInternalErr { -30340 }

=item kSSpVersionErr

=cut

sub kSSpVersionErr { -30341 }

=item kSSpCantInstallErr

=cut

sub kSSpCantInstallErr { -30342 }

=item kSSpParallelUpVectorErr

=cut

sub kSSpParallelUpVectorErr { -30343 }

=item kNSpInitializationFailedErr

=cut

sub kNSpInitializationFailedErr { -30360 }

=item kNSpAlreadyInitializedErr

=cut

sub kNSpAlreadyInitializedErr { -30361 }

=item kNSpTopologyNotSupportedErr

=cut

sub kNSpTopologyNotSupportedErr { -30362 }

=item kNSpPipeFullErr

=cut

sub kNSpPipeFullErr { -30364 }

=item kNSpHostFailedErr

=cut

sub kNSpHostFailedErr { -30365 }

=item kNSpProtocolNotAvailableErr

=cut

sub kNSpProtocolNotAvailableErr { -30366 }

=item kNSpInvalidGameRefErr

=cut

sub kNSpInvalidGameRefErr { -30367 }

=item kNSpInvalidParameterErr

=cut

sub kNSpInvalidParameterErr { -30369 }

=item kNSpOTNotPresentErr

=cut

sub kNSpOTNotPresentErr { -30370 }

=item kNSpOTVersionTooOldErr

=cut

sub kNSpOTVersionTooOldErr { -30371 }

=item kNSpMemAllocationErr

=cut

sub kNSpMemAllocationErr { -30373 }

=item kNSpAlreadyAdvertisingErr

=cut

sub kNSpAlreadyAdvertisingErr { -30374 }

=item kNSpNotAdvertisingErr

=cut

sub kNSpNotAdvertisingErr { -30376 }

=item kNSpInvalidAddressErr

=cut

sub kNSpInvalidAddressErr { -30377 }

=item kNSpFreeQExhaustedErr

=cut

sub kNSpFreeQExhaustedErr { -30378 }

=item kNSpRemovePlayerFailedErr

=cut

sub kNSpRemovePlayerFailedErr { -30379 }

=item kNSpAddressInUseErr

=cut

sub kNSpAddressInUseErr { -30380 }

=item kNSpFeatureNotImplementedErr

=cut

sub kNSpFeatureNotImplementedErr { -30381 }

=item kNSpNameRequiredErr

=cut

sub kNSpNameRequiredErr { -30382 }

=item kNSpInvalidPlayerIDErr

=cut

sub kNSpInvalidPlayerIDErr { -30383 }

=item kNSpInvalidGroupIDErr

=cut

sub kNSpInvalidGroupIDErr { -30384 }

=item kNSpNoPlayersErr

=cut

sub kNSpNoPlayersErr { -30385 }

=item kNSpNoGroupsErr

=cut

sub kNSpNoGroupsErr { -30386 }

=item kNSpNoHostVolunteersErr

=cut

sub kNSpNoHostVolunteersErr { -30387 }

=item kNSpCreateGroupFailedErr

=cut

sub kNSpCreateGroupFailedErr { -30388 }

=item kNSpAddPlayerFailedErr

=cut

sub kNSpAddPlayerFailedErr { -30389 }

=item kNSpInvalidDefinitionErr

=cut

sub kNSpInvalidDefinitionErr { -30390 }

=item kNSpInvalidProtocolRefErr

=cut

sub kNSpInvalidProtocolRefErr { -30391 }

=item kNSpInvalidProtocolListErr

=cut

sub kNSpInvalidProtocolListErr { -30392 }

=item kNSpTimeoutErr

=cut

sub kNSpTimeoutErr { -30393 }

=item kNSpGameTerminatedErr

=cut

sub kNSpGameTerminatedErr { -30394 }

=item kNSpConnectFailedErr

=cut

sub kNSpConnectFailedErr { -30395 }

=item kNSpSendFailedErr

=cut

sub kNSpSendFailedErr { -30396 }

=item kNSpMessageTooBigErr

=cut

sub kNSpMessageTooBigErr { -30397 }

=item kNSpCantBlockErr

=cut

sub kNSpCantBlockErr { -30398 }

=item kISpInternalErr

=cut

sub kISpInternalErr { -30420 }

=item kISpSystemListErr

=cut

sub kISpSystemListErr { -30421 }

=item kISpBufferToSmallErr

=cut

sub kISpBufferToSmallErr { -30422 }

=item kISpElementInListErr

=cut

sub kISpElementInListErr { -30423 }

=item kISpElementNotInListErr

=cut

sub kISpElementNotInListErr { -30424 }

=item kISpSystemInactiveErr

=cut

sub kISpSystemInactiveErr { -30425 }

=item kISpDeviceInactiveErr

=cut

sub kISpDeviceInactiveErr { -30426 }

=item kISpSystemActiveErr

=cut

sub kISpSystemActiveErr { -30427 }

=item kISpDeviceActiveErr

=cut

sub kISpDeviceActiveErr { -30428 }

=item kDSpNotInitializedErr

=cut

sub kDSpNotInitializedErr { -30440 }

=item kDSpSystemSWTooOldErr

=cut

sub kDSpSystemSWTooOldErr { -30441 }

=item kDSpInvalidContextErr

=cut

sub kDSpInvalidContextErr { -30442 }

=item kDSpInvalidAttributesErr

=cut

sub kDSpInvalidAttributesErr { -30443 }

=item kDSpContextAlreadyReservedErr

=cut

sub kDSpContextAlreadyReservedErr { -30444 }

=item kDSpContextNotReservedErr

=cut

sub kDSpContextNotReservedErr { -30445 }

=item kDSpContextNotFoundErr

=cut

sub kDSpContextNotFoundErr { -30446 }

=item kDSpFrameRateNotReadyErr

=cut

sub kDSpFrameRateNotReadyErr { -30447 }

=item kDSpConfirmSwitchWarning

=cut

sub kDSpConfirmSwitchWarning { -30448 }

=item kDSpInternalErr

=cut

sub kDSpInternalErr { -30449 }

=item kFBCvTwinExceptionErr

 no telling what it was

=cut

sub kFBCvTwinExceptionErr { -30500 }

=item kFBCnoIndexesFound

=cut

sub kFBCnoIndexesFound { -30501 }

=item kFBCallocFailed

 probably low memory

=cut

sub kFBCallocFailed { -30502 }

=item kFBCbadParam

=cut

sub kFBCbadParam { -30503 }

=item kFBCfileNotIndexed

=cut

sub kFBCfileNotIndexed { -30504 }

=item kFBCbadIndexFile

 bad FSSpec, or bad data in file

=cut

sub kFBCbadIndexFile { -30505 }

=item kFBCcompactionFailed

 V-Twin exception caught

=cut

sub kFBCcompactionFailed { -30506 }

=item kFBCvalidationFailed

 V-Twin exception caught

=cut

sub kFBCvalidationFailed { -30507 }

=item kFBCindexingFailed

 V-Twin exception caught

=cut

sub kFBCindexingFailed { -30508 }

=item kFBCcommitFailed

 V-Twin exception caught

=cut

sub kFBCcommitFailed { -30509 }

=item kFBCdeletionFailed

 V-Twin exception caught

=cut

sub kFBCdeletionFailed { -30510 }

=item kFBCmoveFailed

 V-Twin exception caught

=cut

sub kFBCmoveFailed { -30511 }

=item kFBCtokenizationFailed

 couldn't read from document or query

=cut

sub kFBCtokenizationFailed { -30512 }

=item kFBCmergingFailed

 couldn't merge index files

=cut

sub kFBCmergingFailed { -30513 }

=item kFBCindexCreationFailed

 couldn't create index

=cut

sub kFBCindexCreationFailed { -30514 }

=item kFBCaccessorStoreFailed

=cut

sub kFBCaccessorStoreFailed { -30515 }

=item kFBCaddDocFailed

=cut

sub kFBCaddDocFailed { -30516 }

=item kFBCflushFailed

=cut

sub kFBCflushFailed { -30517 }

=item kFBCindexNotFound

=cut

sub kFBCindexNotFound { -30518 }

=item kFBCnoSearchSession

=cut

sub kFBCnoSearchSession { -30519 }

=item kFBCindexingCanceled

=cut

sub kFBCindexingCanceled { -30520 }

=item kFBCaccessCanceled

=cut

sub kFBCaccessCanceled { -30521 }

=item kFBCindexFileDestroyed

=cut

sub kFBCindexFileDestroyed { -30522 }

=item kFBCindexNotAvailable

=cut

sub kFBCindexNotAvailable { -30523 }

=item kFBCsearchFailed

=cut

sub kFBCsearchFailed { -30524 }

=item kFBCsomeFilesNotIndexed

=cut

sub kFBCsomeFilesNotIndexed { -30525 }

=item kFBCillegalSessionChange

 tried to add/remove vols to a session
that has hits

=cut

sub kFBCillegalSessionChange { -30526 }

=item kFBCanalysisNotAvailable

=cut

sub kFBCanalysisNotAvailable { -30527 }

=item kFBCbadIndexFileVersion

=cut

sub kFBCbadIndexFileVersion { -30528 }

=item kFBCsummarizationCanceled

=cut

sub kFBCsummarizationCanceled { -30529 }

=item kFBCindexDiskIOFailed

=cut

sub kFBCindexDiskIOFailed { -30530 }

=item kFBCbadSearchSession

=cut

sub kFBCbadSearchSession { -30531 }

=item notAQTVRMovieErr

=cut

sub notAQTVRMovieErr { -30540 }

=item constraintReachedErr

=cut

sub constraintReachedErr { -30541 }

=item callNotSupportedByNodeErr

=cut

sub callNotSupportedByNodeErr { -30542 }

=item selectorNotSupportedByNodeErr

=cut

sub selectorNotSupportedByNodeErr { -30543 }

=item invalidNodeIDErr

=cut

sub invalidNodeIDErr { -30544 }

=item invalidViewStateErr

=cut

sub invalidViewStateErr { -30545 }

=item timeNotInViewErr

=cut

sub timeNotInViewErr { -30546 }

=item propertyNotSupportedByNodeErr

=cut

sub propertyNotSupportedByNodeErr { -30547 }

=item settingNotSupportedByNodeErr

=cut

sub settingNotSupportedByNodeErr { -30548 }

=item limitReachedErr

=cut

sub limitReachedErr { -30549 }

=item invalidNodeFormatErr

=cut

sub invalidNodeFormatErr { -30550 }

=item invalidHotSpotIDErr

=cut

sub invalidHotSpotIDErr { -30551 }

=item noMemoryNodeFailedInitialize

=cut

sub noMemoryNodeFailedInitialize { -30552 }

=item streamingNodeNotReadyErr

=cut

sub streamingNodeNotReadyErr { -30553 }

=item qtvrLibraryLoadErr

=cut

sub qtvrLibraryLoadErr { -30554 }

=item themeInvalidBrushErr

 pattern index invalid

=cut

sub themeInvalidBrushErr { -30560 }

=item themeProcessRegisteredErr

=cut

sub themeProcessRegisteredErr { -30561 }

=item themeProcessNotRegisteredErr

=cut

sub themeProcessNotRegisteredErr { -30562 }

=item themeBadTextColorErr

=cut

sub themeBadTextColorErr { -30563 }

=item themeHasNoAccentsErr

=cut

sub themeHasNoAccentsErr { -30564 }

=item themeBadCursorIndexErr

=cut

sub themeBadCursorIndexErr { -30565 }

=item themeScriptFontNotFoundErr

 theme font requested for uninstalled script system

=cut

sub themeScriptFontNotFoundErr { -30566 }

=back

=head1 Control Manager Error Codes

=over 4

=item errMessageNotSupported

=cut

sub errMessageNotSupported { -30580 }

=item errDataNotSupported

=cut

sub errDataNotSupported { -30581 }

=item errControlDoesntSupportFocus

=cut

sub errControlDoesntSupportFocus { -30582 }

=item errUnknownControl

=cut

sub errUnknownControl { -30584 }

=item errCouldntSetFocus

=cut

sub errCouldntSetFocus { -30585 }

=item errNoRootControl

=cut

sub errNoRootControl { -30586 }

=item errRootAlreadyExists

=cut

sub errRootAlreadyExists { -30587 }

=item errInvalidPartCode

=cut

sub errInvalidPartCode { -30588 }

=item errControlsAlreadyExist

=cut

sub errControlsAlreadyExist { -30589 }

=item errControlIsNotEmbedder

=cut

sub errControlIsNotEmbedder { -30590 }

=item errDataSizeMismatch

=cut

sub errDataSizeMismatch { -30591 }

=item errControlHiddenOrDisabled

=cut

sub errControlHiddenOrDisabled { -30592 }

=item errCantEmbedIntoSelf

=cut

sub errCantEmbedIntoSelf { -30594 }

=item errCantEmbedRoot

=cut

sub errCantEmbedRoot { -30595 }

=item errItemNotControl

=cut

sub errItemNotControl { -30596 }

=item controlInvalidDataVersionErr

=cut

sub controlInvalidDataVersionErr { -30597 }

=item controlPropertyInvalid

=cut

sub controlPropertyInvalid { -5603 }

=item controlPropertyNotFoundErr

=cut

sub controlPropertyNotFoundErr { -5604 }

=item kURLInvalidURLReferenceError

=cut

sub kURLInvalidURLReferenceError { -30770 }

=item kURLProgressAlreadyDisplayedError

=cut

sub kURLProgressAlreadyDisplayedError { -30771 }

=item kURLDestinationExistsError

=cut

sub kURLDestinationExistsError { -30772 }

=item kURLInvalidURLError

=cut

sub kURLInvalidURLError { -30773 }

=item kURLUnsupportedSchemeError

=cut

sub kURLUnsupportedSchemeError { -30774 }

=item kURLServerBusyError

=cut

sub kURLServerBusyError { -30775 }

=item kURLAuthenticationError

=cut

sub kURLAuthenticationError { -30776 }

=item kURLPropertyNotYetKnownError

=cut

sub kURLPropertyNotYetKnownError { -30777 }

=item kURLUnknownPropertyError

=cut

sub kURLUnknownPropertyError { -30778 }

=item kURLPropertyBufferTooSmallError

=cut

sub kURLPropertyBufferTooSmallError { -30779 }

=item kURLUnsettablePropertyError

=cut

sub kURLUnsettablePropertyError { -30780 }

=item kURLInvalidCallError

=cut

sub kURLInvalidCallError { -30781 }

=item kURLFileEmptyError

=cut

sub kURLFileEmptyError { -30783 }

=item kURLExtensionFailureError

=cut

sub kURLExtensionFailureError { -30785 }

=item kURLInvalidConfigurationError

=cut

sub kURLInvalidConfigurationError { -30786 }

=item kURLAccessNotAvailableError

=cut

sub kURLAccessNotAvailableError { -30787 }

=item badComponentInstance

 when cast to an OSErr this is -32767

=cut

sub badComponentInstance { 0x80008001 }

=item dsBusError

 bus error

=cut

sub dsBusError { 1 }

=item dsAddressErr

 address error

=cut

sub dsAddressErr { 2 }

=item dsIllInstErr

 illegal instruction error

=cut

sub dsIllInstErr { 3 }

=item dsZeroDivErr

 zero divide error

=cut

sub dsZeroDivErr { 4 }

=item dsChkErr

 check trap error

=cut

sub dsChkErr { 5 }

=item dsOvflowErr

 overflow trap error

=cut

sub dsOvflowErr { 6 }

=item dsPrivErr

 privilege violation error

=cut

sub dsPrivErr { 7 }

=item dsTraceErr

 trace mode error

=cut

sub dsTraceErr { 8 }

=item dsLineAErr

 line 1010 trap error

=cut

sub dsLineAErr { 9 }

=item dsLineFErr

 line 1111 trap error

=cut

sub dsLineFErr { 10 }

=item dsMiscErr

 miscellaneous hardware exception error

=cut

sub dsMiscErr { 11 }

=item dsCoreErr

 unimplemented core routine error

=cut

sub dsCoreErr { 12 }

=item dsIrqErr

 uninstalled interrupt error

=cut

sub dsIrqErr { 13 }

=item dsIOCoreErr

 IO Core Error

=cut

sub dsIOCoreErr { 14 }

=item dsLoadErr

 Segment Loader Error

=cut

sub dsLoadErr { 15 }

=item dsFPErr

 Floating point error

=cut

sub dsFPErr { 16 }

=item dsNoPackErr

 package 0 not present

=cut

sub dsNoPackErr { 17 }

=item dsNoPk1

 package 1 not present

=cut

sub dsNoPk1 { 18 }

=item dsNoPk3

 package 3 not present

=cut

sub dsNoPk3 { 20 }

=item dsNoPk4

 package 4 not present

=cut

sub dsNoPk4 { 21 }

=item dsNoPk5

 package 5 not present

=cut

sub dsNoPk5 { 22 }

=item dsNoPk6

 package 6 not present

=cut

sub dsNoPk6 { 23 }

=item dsNoPk7

 package 7 not present

=cut

sub dsNoPk7 { 24 }

=item dsMemFullErr

 out of memory!

=cut

sub dsMemFullErr { 25 }

=item dsBadLaunch

 can't launch file

=cut

sub dsBadLaunch { 26 }

=item dsFSErr

 file system map has been trashed

=cut

sub dsFSErr { 27 }

=item dsStknHeap

 stack has moved into application heap

=cut

sub dsStknHeap { 28 }

=item negZcbFreeErr

 ZcbFree has gone negative

=cut

sub negZcbFreeErr { 33 }

=item dsFinderErr

 can't load the Finder error

=cut

sub dsFinderErr { 41 }

=item dsBadSlotInt

 unserviceable slot interrupt

=cut

sub dsBadSlotInt { 51 }

=item dsBadSANEOpcode

 bad opcode given to SANE Pack4

=cut

sub dsBadSANEOpcode { 81 }

=item dsBadPatchHeader

 SetTrapAddress saw the 'come-from' header

=cut

sub dsBadPatchHeader { 83 }

=item menuPrgErr

 happens when a menu is purged

=cut

sub menuPrgErr { 84 }

=item dsMBarNFnd

 Menu Manager Errors

=cut

sub dsMBarNFnd { 85 }

=item dsHMenuFindErr

 Menu Manager Errors

=cut

sub dsHMenuFindErr { 86 }

=item dsWDEFNotFound

 could not load WDEF

=cut

sub dsWDEFNotFound { 87 }

=item dsCDEFNotFound

 could not load CDEF

=cut

sub dsCDEFNotFound { 88 }

=item dsNoFPU

 an FPU instruction was executed and the machine doesn't have one

=cut

sub dsNoFPU { 90 }

=item dsNoPatch

 Can't patch for particular Model Mac

=cut

sub dsNoPatch { 98 }

=item dsBadPatch

 Can't load patch resource

=cut

sub dsBadPatch { 99 }

=item dsParityErr

 memory parity error

=cut

sub dsParityErr { 101 }

=item dsOldSystem

 System is too old for this ROM

=cut

sub dsOldSystem { 102 }

=item ds32BitMode

 booting in 32-bit on a 24-bit sys

=cut

sub ds32BitMode { 103 }

=item dsNeedToWriteBootBlocks

 need to write new boot blocks

=cut

sub dsNeedToWriteBootBlocks { 104 }

=item dsNotEnoughRAMToBoot

 must have at least 1.5MB of RAM to boot 7.0

=cut

sub dsNotEnoughRAMToBoot { 105 }

=item dsBufPtrTooLow

 bufPtr moved too far during boot

=cut

sub dsBufPtrTooLow { 106 }

=item dsVMDeferredFuncTableFull

 VM's DeferUserFn table is full

=cut

sub dsVMDeferredFuncTableFull { 112 }

=item dsVMBadBackingStore

 Error occurred while reading or writing the VM backing-store file

=cut

sub dsVMBadBackingStore { 113 }

=item dsCantHoldSystemHeap

 Unable to hold the system heap during boot

=cut

sub dsCantHoldSystemHeap { 114 }

=item dsSystemRequiresPowerPC

 Startup disk requires PowerPC

=cut

sub dsSystemRequiresPowerPC { 116 }

=item dsGibblyMovedToDisabledFolder

 For debug builds only, signals that active gibbly was disabled during boot.

=cut

sub dsGibblyMovedToDisabledFolder { 117 }

=item dsUnBootableSystem

 Active system file will not boot on this system because it was designed only to boot from a CD.

=cut

sub dsUnBootableSystem { 118 }

=item dsMustUseFCBAccessors

 FCBSPtr and FSFCBLen are invalid - must use FSM FCB accessor functions

=cut

sub dsMustUseFCBAccessors { 119 }

=item dsMacOSROMVersionTooOld

 The version of the "Mac OS ROM" file is too old to be used with the installed version of system software

=cut

sub dsMacOSROMVersionTooOld { 120 }

=item dsLostConnectionToNetworkDisk

 Lost communication with Netboot server

=cut

sub dsLostConnectionToNetworkDisk { 121 }

=item dsRAMDiskTooBig

 The RAM disk is too big to boot safely; will be turned off

=cut

sub dsRAMDiskTooBig { 122 }

=item dsWriteToSupervisorStackGuardPage

 the supervisor stack overflowed into its guard page

=cut

sub dsWriteToSupervisorStackGuardPage { 128 }

=item dsReinsert

 request user to reinsert off-line volume

=cut

sub dsReinsert { 30 }

=item shutDownAlert

 handled like a shutdown error

=cut

sub shutDownAlert { 42 }

=item dsShutDownOrRestart

 user choice between ShutDown and Restart

=cut

sub dsShutDownOrRestart { 20000 }

=item dsSwitchOffOrRestart

 user choice between switching off and Restart

=cut

sub dsSwitchOffOrRestart { 20001 }

=item dsForcedQuit

 allow the user to ExitToShell, return if Cancel

=cut

sub dsForcedQuit { 20002 }

=item dsRemoveDisk

 request user to remove disk from manual eject drive

=cut

sub dsRemoveDisk { 20003 }

=item dsDirtyDisk

 request user to return a manually-ejected dirty disk

=cut

sub dsDirtyDisk { 20004 }

=item dsShutDownOrResume

 allow user to return to Finder or ShutDown

=cut

sub dsShutDownOrResume { 20109 }

=item dsSCSIWarn

 Portable SCSI adapter warning.

=cut

sub dsSCSIWarn { 20010 }

=item dsMBSysError

 Media Bay replace warning.

=cut

sub dsMBSysError { 29200 }

=item dsMBFlpySysError

 Media Bay, floppy replace warning.

=cut

sub dsMBFlpySysError { 29201 }

=item dsMBATASysError

 Media Bay, ATA replace warning.

=cut

sub dsMBATASysError { 29202 }

=item dsMBATAPISysError

 Media Bay, ATAPI replace warning...

=cut

sub dsMBATAPISysError { 29203 }

=item dsMBExternFlpySysError

 Media Bay, external floppy drive reconnect warning

=cut

sub dsMBExternFlpySysError { 29204 }

=item dsNoExtsMacsBug

 not a SysErr, just a placeholder

=cut

sub dsNoExtsMacsBug { -1 }

=item dsNoExtsDisassembler

 not a SysErr, just a placeholder

=cut

sub dsNoExtsDisassembler { -2 }

=item dsMacsBugInstalled

 say 'MacsBug Installed'

=cut

sub dsMacsBugInstalled { -10 }

=item dsDisassemblerInstalled

 say 'Disassembler Installed'

=cut

sub dsDisassemblerInstalled { -11 }

=item dsExtensionsDisabled

 say 'Extensions Disabled'

=cut

sub dsExtensionsDisabled { -13 }

=item dsGreeting

 welcome to Macintosh greeting

=cut

sub dsGreeting { 40 }

=item dsSysErr

 general system error
old names here for compatibility's sake

=cut

sub dsSysErr { 32767 }

=item CDEFNFnd

=cut

sub CDEFNFnd { dsCDEFNotFound }

=item dsNotThe1

 not the disk I wanted

=cut

sub dsNotThe1 { 31 }

=item dsBadStartupDisk

 unable to mount boot volume (sad Mac only)

=cut

sub dsBadStartupDisk { 42 }

=item dsSystemFileErr

 can't find System file to open (sad Mac only)

=cut

sub dsSystemFileErr { 43 }

=item dsHD20Installed

 say 'HD20 Startup'

=cut

sub dsHD20Installed { -12 }

=item mBarNFnd

 system error code for MBDF not found

=cut

sub mBarNFnd { -126 }

=item fsDSIntErr

 non-hardware Internal file system error

=cut

sub fsDSIntErr { -127 }

=item hMenuFindErr

 could not find HMenu's parent in MenuKey (wrong error code - obsolete)

=cut

sub hMenuFindErr { -127 }

=item userBreak

 user debugger break

=cut

sub userBreak { -490 }

=item strUserBreak

 user debugger break; display string on stack

=cut

sub strUserBreak { -491 }

=back

=head1 DS Errors which are specific to the new runtime model introduced with PowerPC

=over 4

=item dsBadLibrary

 Bad shared library

=cut

sub dsBadLibrary { 1010 }

=back

=head1 TO DO

* make some sensible export tags

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/Mac-Errors

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

"See why 1984 won't be like 1984";

__DATA__
