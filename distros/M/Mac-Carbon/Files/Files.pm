=head1 NAME

Mac::Files - Macintosh Toolbox Interface to the File and Alias Manager

=head1 DESCRIPTION

=cut

package Mac::Files;

require DynaLoader;

use strict;
use base 'DynaLoader';
use base 'Exporter';
use vars qw(@EXPORT %EXPORT_TAGS $VERSION);

$VERSION = '1.10';
@EXPORT = qw(
	FSpGetCatInfo
	FSpSetCatInfo
	FSMakeFSSpec
	FSpCreate
	FSpDirCreate
	FSpDelete
	FSpGetFInfo
	FSpSetFInfo
	FSpSetFLock
	FSpRstFLock
	FSpRename
	FSpCatMove
	FSpExchangeFiles

	NewAlias
	NewAliasRelative
	NewAliasMinimal
	NewAliasMinimalFromFullPath
	UpdateAlias
	UpdateAliasRelative
	ResolveAlias
	ResolveAliasRelative
	GetAliasInfo

	UnmountVol
	Eject
	FlushVol

	FindFolder
);

%EXPORT_TAGS = (
	functions	=> [ @EXPORT ],
	all		=> \@EXPORT
);

sub constants {
	my @constants;
	seek DATA, 0, 0; # this reads the entire script
	my $data = do { local $/; <DATA> };
	while ($data =~ m|=item (\w+)\s+(?:([^\n]+)\n\s+)?=cut\s+sub \1 \(\) { (\S+) }|g) {
		my($symbol, $desc, $value ) = ($1, $2, $3);
		push @constants, $symbol;
	}
	push @EXPORT, @constants;
	$EXPORT_TAGS{constants} = \@constants;
}

constants();
bootstrap Mac::Files;


=head2 Constants

Constants for file access permissions.  Use these constants to request a
type of access to a file or fork, or to deny a type of access to a file
or fork to other paths that may request access.

Note that it is possible, on Mac OS 8 and 9, to open a file residing on
read-only media with write access. On Mac OS X, however, you cannot open
a file with write access on read-only media; the attempt to open the
file fails with a wrPermErr error.

=over 4

=item fsCurPerm

Requests whatever permissions are currently allowed. If write access is unavailable (because the file is locked or the file is already open with write permission), then read permission is granted. Otherwise read/write permission is granted.

=cut

sub fsCurPerm () { 0x00 }

=item fsRdPerm

Requests permission to read the file.

=cut

sub fsRdPerm () { 0x01 }

=item fsWrPerm

Requests permission to write to the file. If write permission is granted, no other access paths are granted write permission. Note, however, that the File Manager does not support write-only access to a file. Thus, fsWrPerm is synonymous with fsRdWrPerm.

=cut

sub fsWrPerm () { 0x02 }

=item fsRdWrPerm

Requests exclusive read and write permission. If exclusive read/write permission is granted, no other users are granted permission to write to the file. Other users may, however, be granted permission to read the file.

=cut

sub fsRdWrPerm () { 0x03 }

=item fsRdWrShPerm

Requests shared read and write permission. Shared read/write permission allows mutliple access paths for reading and writing. This is safe only if there is some way of locking portions of the file before writing to them. Use the functions PBLockRangeSync and PBUnlockRangeSync to lock and unlock ranges of bytes within a file. On Mac OS 8 and 9, these functions are supported only on remotely mounted volumes, or on local volumes that are shareable on the network. You should check that range locking is available before requesting shared read/ write permission. On Mac OS X, range locking is available on all volumes.

=cut

sub fsRdWrShPerm () { 0x04 }

=item fsRdDenyPerm

Requests that any other paths be prevented from having read access. A path cannot be opened if you request read permission (with the fsRdPerm constant) but some other path has requested deny-read access. Similarly, the path cannot be opened if you request deny-read permission, but some other path already has read access. This constant is used with the PBHOpenDenySync and PBHOpenRFDenySync functions.

=cut

sub fsRdDenyPerm () { 0x10 }

=item fsWrDenyPerm

Requests that any other paths be prevented from having write access. A path cannot be opened if you request write permission (with the fsWrPerm constant) but some other path has requested deny-write access. Similarly, the path cannot be opened if you request deny-write permission, but some other path already has write access. This constant is used with the PBHOpenDenySync and PBHOpenRFDenySync functions.

=cut

sub fsWrDenyPerm () { 0x20 }

=back

ioFlAttrib bits, returned by FSpGetCatInfo.

=over 4

=item kioFlAttribLocked

Set if file or directory is locked

=cut

sub kioFlAttribLocked () { 0x01 }

=item kioFlAttribResOpen

Set if resource fork is open

=cut

sub kioFlAttribResOpen () { 0x04 }

=item kioFlAttribDataOpen

Set if data fork is open

=cut

sub kioFlAttribDataOpen () { 0x08 }

=item kioFlAttribDir

Set if this is a directory

=cut

sub kioFlAttribDir () { 0x10 }

=item kioFlAttribCopyProt

Set if AppleShare server "copy-protects" the file

=cut

sub kioFlAttribCopyProt () { 0x40 }

=item kioFlAttribFileOpen

Set if file (either fork) is open

=cut

sub kioFlAttribFileOpen () { 0x80 }

=item kioFlAttribInShared

Set if the directory is within a shared area of the directory hierarchy

=cut

sub kioFlAttribInShared () { 0x04 }

=item kioFlAttribMounted

Set if the directory is a share point that is mounted by some user

=cut

sub kioFlAttribMounted () { 0x08 }

=item kioFlAttribSharePoint

Set if the directory is a share point

=cut

sub kioFlAttribSharePoint () { 0x20 }

=back

Finder flags

=over 4

=item kIsOnDesk

Files and folders (System 6)

=cut

sub kIsOnDesk () { 0x0001 }

=item kColor

Files and folders; bit 0x0020 was kRequireSwitchLaunch, but is now reserved for future use

=cut

sub kColor () { 0x000E }

=item kIsShared

Files only (Applications only); if clear, the application needs to write to its resource fork, and therefore cannot be shared on a server

=cut

sub kIsShared () { 0x0040 }

=item kHasNoINITs

Files only (Extensions/Control Panels only); this file contains no INIT resource

=cut

sub kHasNoINITs () { 0x0080 }

=item kHasBeenInited

Files only; clear if the file contains desktop database; resources ('BNDL', 'FREF', 'open', 'kind'...) that have not been added yet. Set only by the Finder; reserved for folders - make sure this bit is cleared for folders; bit 0x0200 was the letter bit for AOCE, but is now reserved for future use

=cut

sub kHasBeenInited () { 0x0100 }

=item kHasCustomIcon

Files and folders

=cut

sub kHasCustomIcon () { 0x0400 }

=item kIsStationery

Files only

=cut

sub kIsStationery () { 0x0800 }

=item kNameLocked

Files and folders

=cut

sub kNameLocked () { 0x1000 }

=item kHasBundle

Files only

=cut

sub kHasBundle () { 0x2000 }

=item kIsInvisible

Files and folders

=cut

sub kIsInvisible () { 0x4000 }

=item kIsAlias

Files only

=cut

sub kIsAlias () { 0x8000 }

=back

AppleTalk/GetAliasInfo Constants

=over 4

=item asiZoneName

Return AppleTalk zone name from GetAliasInfo.

=cut

sub asiZoneName () { -3 }

=item asiServerName

Return AppleTalk server name from GetAliasInfo.

=cut

sub asiServerName () { -2 }

=item asiVolumeName

Return volume name from GetAliasInfo.

=cut

sub asiVolumeName () { -1 }

=item asiAliasName

Return last component of target file name from GetAliasInfo.

=cut

sub asiAliasName () { 0 }

=item asiParentName

Return name of enclosing folder from GetAliasInfo. This index value is 1.  Higher indices will return folder names higher up the hierarchy.

=cut

sub asiParentName () { 1 }

=back

Folder type constants.  Specify a type of folder on a particular volume.
Use in vRefNum parameter of FindFolder().

=over 4

=item kOnSystemDisk

previously was 0x8000 but that is an unsigned value whereas vRefNum is signed

=cut

sub kOnSystemDisk () { -32768 }

=item kOnAppropriateDisk

Generally, the same as kOnSystemDisk, but it's clearer that this isn't always the 'boot' disk.

=cut

sub kOnAppropriateDisk () { -32767 }

=back

Folder Domains - Carbon only.  The constants above can continue to be used,
but the folder/volume returned will be from one of the domains below.

=over 4

=item kSystemDomain

Read-only system hierarchy.

=cut

sub kSystemDomain () { -32766 }

=item kLocalDomain

All users of a single machine have access to these resources.

=cut

sub kLocalDomain () { -32765 }

=item kNetworkDomain

All users configured to use a common network server has access to these resources.

=cut

sub kNetworkDomain () { -32764 }

=item kUserDomain

Read/write. Resources that are private to the user.

=cut

sub kUserDomain () { -32763 }

=item kClassicDomain

Domain referring to the currently configured Classic System Folder

=cut

sub kClassicDomain () { -32762 }

=item kLastDomainConstant

The ID of the last domain in the above list, used by the Folder Manager to determine if a given parameter should be treated as a domain or a volume...

=cut

sub kLastDomainConstant () { kUserDomain }

=back

Constants for createFolder parameter of FindFolder().

=over 4

=item kCreateFolder

=cut

sub kCreateFolder () { 1 }

=item kDontCreateFolder

=cut

sub kDontCreateFolder () { 0 }

=back

Folder Type Constants for FindFolder().

=over 4

=item kSystemFolderType

the system folder

=cut

sub kSystemFolderType () { 'macs' }

=item kDesktopFolderType

the desktop folder; objects in this folder show on the desk top.

=cut

sub kDesktopFolderType () { 'desk' }

=item kSystemDesktopFolderType

the desktop folder at the root of the hard drive, never the redirected user desktop folder

=cut

sub kSystemDesktopFolderType () { 'sdsk' }

=item kTrashFolderType

the trash folder; objects in this folder show up in the trash

=cut

sub kTrashFolderType () { 'trsh' }

=item kSystemTrashFolderType

the trash folder at the root of the drive, never the redirected user trash folder

=cut

sub kSystemTrashFolderType () { 'strs' }

=item kWhereToEmptyTrashFolderType

the "empty trash" folder; Finder starts empty from here down

=cut

sub kWhereToEmptyTrashFolderType () { 'empt' }

=item kPrintMonitorDocsFolderType

Print Monitor documents

=cut

sub kPrintMonitorDocsFolderType () { 'prnt' }

=item kStartupFolderType

Finder objects (applications, documents, DAs, aliases, to...) to open at startup go here

=cut

sub kStartupFolderType () { 'strt' }

=item kShutdownFolderType

Finder objects (applications, documents, DAs, aliases, to...) to open at shutdown go here

=cut

sub kShutdownFolderType () { 'shdf' }

=item kAppleMenuFolderType

Finder objects to put into the Apple menu go here

=cut

sub kAppleMenuFolderType () { 'amnu' }

=item kControlPanelFolderType

Control Panels go here (may contain INITs)

=cut

sub kControlPanelFolderType () { 'ctrl' }

=item kSystemControlPanelFolderType

System control panels folder - never the redirected one, always "Control Panels" inside the System Folder

=cut

sub kSystemControlPanelFolderType () { 'sctl' }

=item kExtensionFolderType

System extensions go here

=cut

sub kExtensionFolderType () { 'extn' }

=item kFontsFolderType

Fonts go here

=cut

sub kFontsFolderType () { 'font' }

=item kPreferencesFolderType

preferences for applications go here

=cut

sub kPreferencesFolderType () { 'pref' }

=item kSystemPreferencesFolderType

System-type Preferences go here - this is always the system's preferences folder, never a logged in user's

=cut

sub kSystemPreferencesFolderType () { 'sprf' }

=item kTemporaryFolderType

temporary files go here (deleted periodically, but don't rely on it.)

=cut

sub kTemporaryFolderType () { 'temp' }

=item kExtensionDisabledFolderType

=cut

sub kExtensionDisabledFolderType () { 'extD' }

=item kControlPanelDisabledFolderType

=cut

sub kControlPanelDisabledFolderType () { 'ctrD' }

=item kSystemExtensionDisabledFolderType

=cut

sub kSystemExtensionDisabledFolderType () { 'macD' }

=item kStartupItemsDisabledFolderType

=cut

sub kStartupItemsDisabledFolderType () { 'strD' }

=item kShutdownItemsDisabledFolderType

=cut

sub kShutdownItemsDisabledFolderType () { 'shdD' }

=item kApplicationsFolderType

=cut

sub kApplicationsFolderType () { 'apps' }

=item kDocumentsFolderType

=cut

sub kDocumentsFolderType () { 'docs' }

=back

New Constants

=over 4

=item kVolumeRootFolderType

root folder of a volume

=cut

sub kVolumeRootFolderType () { 'root' }

=item kChewableItemsFolderType

items deleted at boot

=cut

sub kChewableItemsFolderType () { 'flnt' }

=item kApplicationSupportFolderType

third-party items and folders

=cut

sub kApplicationSupportFolderType () { 'asup' }

=item kTextEncodingsFolderType

encoding tables

=cut

sub kTextEncodingsFolderType () { "\304tex" }

=item kStationeryFolderType

stationery

=cut

sub kStationeryFolderType () { 'odst' }

=item kOpenDocFolderType

OpenDoc root

=cut

sub kOpenDocFolderType () { 'odod' }

=item kOpenDocShellPlugInsFolderType

OpenDoc Shell Plug-Ins in OpenDoc folder

=cut

sub kOpenDocShellPlugInsFolderType () { 'odsp' }

=item kEditorsFolderType

OpenDoc editors in Mac OS Folder

=cut

sub kEditorsFolderType () { 'oded' }

=item kOpenDocEditorsFolderType

OpenDoc subfolder of Editors folder

=cut

sub kOpenDocEditorsFolderType () { "\304odf" }

=item kOpenDocLibrariesFolderType

OpenDoc libraries folder

=cut

sub kOpenDocLibrariesFolderType () { 'odlb' }

=item kGenEditorsFolderType

CKH general editors folder at root level of Sys folder

=cut

sub kGenEditorsFolderType () { "\304edi" }

=item kHelpFolderType

CKH help folder currently at root of system folder

=cut

sub kHelpFolderType () { "\304hlp" }

=item kInternetPlugInFolderType

CKH internet plug ins for browsers and stuff

=cut

sub kInternetPlugInFolderType () { "\304net" }

=item kModemScriptsFolderType

CKH modem scripts, get 'em OUT of the Extensions folder

=cut

sub kModemScriptsFolderType () { "\304mod" }

=item kPrinterDescriptionFolderType

CKH new folder at root of System folder for printer descs.

=cut

sub kPrinterDescriptionFolderType () { 'ppdf' }

=item kPrinterDriverFolderType

CKH new folder at root of System folder for printer drivers

=cut

sub kPrinterDriverFolderType () { "\304prd" }

=item kScriptingAdditionsFolderType

CKH at root of system folder

=cut

sub kScriptingAdditionsFolderType () { "\304scr" }

=item kSharedLibrariesFolderType

CKH for general shared libs.

=cut

sub kSharedLibrariesFolderType () { "\304lib" }

=item kVoicesFolderType

CKH macintalk can live here

=cut

sub kVoicesFolderType () { 'fvoc' }

=item kControlStripModulesFolderType

CKH for control strip modules

=cut

sub kControlStripModulesFolderType () { 'sdev' }

=item kAssistantsFolderType

SJF for Assistants (Mac OS Setup Assistant, etc)

=cut

sub kAssistantsFolderType () { "ast\304" }

=item kUtilitiesFolderType

SJF for Utilities folder

=cut

sub kUtilitiesFolderType () { "uti\304" }

=item kAppleExtrasFolderType

SJF for Apple Extras folder

=cut

sub kAppleExtrasFolderType () { "aex\304" }

=item kContextualMenuItemsFolderType

SJF for Contextual Menu items

=cut

sub kContextualMenuItemsFolderType () { 'cmnu' }

=item kMacOSReadMesFolderType

SJF for Mac OS ReadMes folder

=cut

sub kMacOSReadMesFolderType () { "mor\304" }

=item kALMModulesFolderType

EAS for Location Manager Module files except type 'thng' (within kExtensionFolderType)

=cut

sub kALMModulesFolderType () { 'walk' }

=item kALMPreferencesFolderType

EAS for Location Manager Preferences (within kPreferencesFolderType; contains kALMLocationsFolderType)

=cut

sub kALMPreferencesFolderType () { 'trip' }

=item kALMLocationsFolderType

EAS for Location Manager Locations (within kALMPreferencesFolderType)

=cut

sub kALMLocationsFolderType () { 'fall' }

=item kColorSyncProfilesFolderType

for ColorSync Profiles

=cut

sub kColorSyncProfilesFolderType () { 'prof' }

=item kThemesFolderType

for Theme data files

=cut

sub kThemesFolderType () { 'thme' }

=item kFavoritesFolderType

Favorties folder for Navigation Services

=cut

sub kFavoritesFolderType () { 'favs' }

=item kInternetFolderType

Internet folder (root level of startup volume)

=cut

sub kInternetFolderType () { "int\304" }

=item kAppearanceFolderType

Appearance folder (root of system folder)

=cut

sub kAppearanceFolderType () { 'appr' }

=item kSoundSetsFolderType

Sound Sets folder (in Appearance folder)

=cut

sub kSoundSetsFolderType () { 'snds' }

=item kDesktopPicturesFolderType

Desktop Pictures folder (in Appearance folder)

=cut

sub kDesktopPicturesFolderType () { "dtp\304" }

=item kInternetSearchSitesFolderType

Internet Search Sites folder

=cut

sub kInternetSearchSitesFolderType () { 'issf' }

=item kFindSupportFolderType

Find support folder

=cut

sub kFindSupportFolderType () { 'fnds' }

=item kFindByContentFolderType

Find by content folder

=cut

sub kFindByContentFolderType () { 'fbcf' }

=item kInstallerLogsFolderType

Installer Logs folder

=cut

sub kInstallerLogsFolderType () { 'ilgf' }

=item kScriptsFolderType

Scripts folder

=cut

sub kScriptsFolderType () { "scr\304" }

=item kFolderActionsFolderType

Folder Actions Scripts folder

=cut

sub kFolderActionsFolderType () { 'fasf' }

=item kLauncherItemsFolderType

Launcher Items folder

=cut

sub kLauncherItemsFolderType () { 'laun' }

=item kRecentApplicationsFolderType

Recent Applications folder

=cut

sub kRecentApplicationsFolderType () { 'rapp' }

=item kRecentDocumentsFolderType

Recent Documents folder

=cut

sub kRecentDocumentsFolderType () { 'rdoc' }

=item kRecentServersFolderType

Recent Servers folder

=cut

sub kRecentServersFolderType () { 'rsvr' }

=item kSpeakableItemsFolderType

Speakable Items folder

=cut

sub kSpeakableItemsFolderType () { 'spki' }

=item kKeychainFolderType

Keychain folder

=cut

sub kKeychainFolderType () { 'kchn' }

=item kQuickTimeExtensionsFolderType

QuickTime Extensions Folder (in Extensions folder)

=cut

sub kQuickTimeExtensionsFolderType () { 'qtex' }

=item kDisplayExtensionsFolderType

Display Extensions Folder (in Extensions folder)

=cut

sub kDisplayExtensionsFolderType () { 'dspl' }

=item kMultiprocessingFolderType

Multiprocessing Folder (in Extensions folder)

=cut

sub kMultiprocessingFolderType () { 'mpxf' }

=item kPrintingPlugInsFolderType

Printing Plug-Ins Folder (in Extensions folder)

=cut

sub kPrintingPlugInsFolderType () { 'pplg' }

=back

New Folder Types to accommodate the Mac OS X Folder Manager
These folder types are not applicable on Mac OS 9.

=over 4

=item kDomainTopLevelFolderType

The top-level of a Folder domain, e.g. "/System"

=cut

sub kDomainTopLevelFolderType () { 'dtop' }

=item kDomainLibraryFolderType

the Library subfolder of a particular domain

=cut

sub kDomainLibraryFolderType () { 'dlib' }

=item kColorSyncFolderType

Contains ColorSync-related folders

=cut

sub kColorSyncFolderType () { 'sync' }

=item kColorSyncCMMFolderType

ColorSync CMMs

=cut

sub kColorSyncCMMFolderType () { 'ccmm' }

=item kColorSyncScriptingFolderType

ColorSync Scripting support

=cut

sub kColorSyncScriptingFolderType () { 'cscr' }

=item kPrintersFolderType

Contains Printing-related folders

=cut

sub kPrintersFolderType () { 'impr' }

=item kSpeechFolderType

Contains Speech-related folders

=cut

sub kSpeechFolderType () { 'spch' }

=item kCarbonLibraryFolderType

Contains Carbon-specific file

=cut

sub kCarbonLibraryFolderType () { 'carb' }

=item kDocumentationFolderType

Contains Documentation files (not user documents)

=cut

sub kDocumentationFolderType () { 'info' }

=item kDeveloperDocsFolderType

Contains Developer Documentation files and folders

=cut

sub kDeveloperDocsFolderType () { 'ddoc' }

=item kDeveloperHelpFolderType

Contains Developer Help related files

=cut

sub kDeveloperHelpFolderType () { 'devh' }

=item kISSDownloadsFolderType

Contains Internet Search Sites downloaded from the Internet

=cut

sub kISSDownloadsFolderType () { 'issd' }

=item kUserSpecificTmpFolderType

Contains temporary items created on behalf of the current user

=cut

sub kUserSpecificTmpFolderType () { 'utmp' }

=item kCachedDataFolderType

Contains various cache files for different clients

=cut

sub kCachedDataFolderType () { 'cach' }

=item kFrameworksFolderType

Contains Mac OS X Framework folders

=cut

sub kFrameworksFolderType () { 'fram' }

=item kPrivateFrameworksFolderType

Contains Mac OS X Private Framework folders

=cut

sub kPrivateFrameworksFolderType () { 'pfrm' }

=item kClassicDesktopFolderType

Mac OS 9 compatible desktop folder - same as kSystemDesktopFolderType but with a more appropriate name for Mac OS X code.

=cut

sub kClassicDesktopFolderType () { 'sdsk' }

=item kDeveloperFolderType

Contains Mac OS X Developer Resources

=cut

sub kDeveloperFolderType () { 'devf' }

=item kSystemSoundsFolderType

Contains Mac OS X System Sound Files

=cut

sub kSystemSoundsFolderType () { 'ssnd' }

=item kComponentsFolderType

Contains Mac OS X components

=cut

sub kComponentsFolderType () { 'cmpd' }

=item kQuickTimeComponentsFolderType

Contains QuickTime components for Mac OS X

=cut

sub kQuickTimeComponentsFolderType () { 'wcmp' }

=item kCoreServicesFolderType

Refers to the "CoreServices" folder on Mac OS X

=cut

sub kCoreServicesFolderType () { 'csrv' }

=item kPictureDocumentsFolderType

Refers to the "Pictures" folder in a users home directory

=cut

sub kPictureDocumentsFolderType () { 'pdoc' }

=item kMovieDocumentsFolderType

Refers to the "Movies" folder in a users home directory

=cut

sub kMovieDocumentsFolderType () { 'mdoc' }

=item kMusicDocumentsFolderType

Refers to the "Music" folder in a users home directory

=cut

sub kMusicDocumentsFolderType () { "\265doc" }

=item kInternetSitesFolderType

Refers to the "Sites" folder in a users home directory

=cut

sub kInternetSitesFolderType () { 'site' }

=item kPublicFolderType

Refers to the "Public" folder in a users home directory

=cut

sub kPublicFolderType () { 'pubb' }

=item kAudioSupportFolderType

Refers to the Audio support folder for Mac OS X

=cut

sub kAudioSupportFolderType () { 'adio' }

=item kAudioSoundsFolderType

Refers to the Sounds subfolder of Audio Support

=cut

sub kAudioSoundsFolderType () { 'asnd' }

=item kAudioSoundBanksFolderType

Refers to the Banks subfolder of the Sounds Folder

=cut

sub kAudioSoundBanksFolderType () { 'bank' }

=item kAudioAlertSoundsFolderType

Refers to the Alert Sounds subfolder of the Sound Folder

=cut

sub kAudioAlertSoundsFolderType () { 'alrt' }

=item kAudioPlugInsFolderType

Refers to the Plug-ins subfolder of the Audio Folder

=cut

sub kAudioPlugInsFolderType () { 'aplg' }

=item kAudioComponentsFolderType

Refers to the Components subfolder of the Audio Plug-ins Folder

=cut

sub kAudioComponentsFolderType () { 'acmp' }

=item kKernelExtensionsFolderType

Refers to the Kernel Extensions Folder on Mac OS X

=cut

sub kKernelExtensionsFolderType () { 'kext' }

=item kDirectoryServicesFolderType

Refers to the Directory Services folder on Mac OS X

=cut

sub kDirectoryServicesFolderType () { 'dsrv' }

=item kDirectoryServicesPlugInsFolderType

Refers to the Directory Services Plug-Ins folder on Mac OS X

=cut

sub kDirectoryServicesPlugInsFolderType () { 'dplg' }

=item kInstallerReceiptsFolderType

Refers to the "Receipts" folder in Mac OS X

=cut

sub kInstallerReceiptsFolderType () { 'rcpt' }

=item kFileSystemSupportFolderType

Refers to the [domain]/Library/Filesystems folder in Mac OS X

=cut

sub kFileSystemSupportFolderType () { 'fsys' }

=item kAppleShareSupportFolderType

Refers to the [domain]/Library/Filesystems/AppleShare folder in Mac OS X

=cut

sub kAppleShareSupportFolderType () { 'shar' }

=item kAppleShareAuthenticationFolderType

Refers to the [domain]/Library/Filesystems/AppleShare/Authentication folder in Mac OS X

=cut

sub kAppleShareAuthenticationFolderType () { 'auth' }

=item kMIDIDriversFolderType

Refers to the MIDI Drivers folder on Mac OS X

=cut

sub kMIDIDriversFolderType () { 'midi' }

=item kKeyboardLayoutsFolderType

Refers to the [domain]/Library/KeyboardLayouts folder in Mac OS X

=cut

sub kKeyboardLayoutsFolderType () { 'klay' }

=item kIndexFilesFolderType

Refers to the [domain]/Library/Indexes folder in Mac OS X

=cut

sub kIndexFilesFolderType () { 'indx' }

=item kFindByContentIndexesFolderType

Refers to the [domain]/Library/Indexes/FindByContent folder in Mac OS X

=cut

sub kFindByContentIndexesFolderType () { 'fbcx' }

=item kManagedItemsFolderType

Refers to the Managed Items folder for Mac OS X

=cut

sub kManagedItemsFolderType () { 'mang' }

=item kBootTimeStartupItemsFolderType

Refers to the "StartupItems" folder of Mac OS X

=cut

sub kBootTimeStartupItemsFolderType () { 'empz' }

=back

More Folder Constants

=over 4

=item kLocalesFolderType

PKE for Locales folder

=cut

sub kLocalesFolderType () { "\304loc" }

=item kFindByContentPluginsFolderType

Find By Content Plug-ins

=cut

sub kFindByContentPluginsFolderType () { 'fbcp' }

=item kUsersFolderType

"Users" folder, contains one folder for each user.

=cut

sub kUsersFolderType () { 'usrs' }

=item kCurrentUserFolderType

The folder for the currently logged on user.

=cut

sub kCurrentUserFolderType () { 'cusr' }

=item kCurrentUserRemoteFolderLocation

The remote folder for the currently logged on user

=cut

sub kCurrentUserRemoteFolderLocation () { 'rusf' }

=item kCurrentUserRemoteFolderType

The remote folder location for the currently logged on user

=cut

sub kCurrentUserRemoteFolderType () { 'rusr' }

=item kSharedUserDataFolderType

A Shared "Documents" folder, readable & writeable by all users

=cut

sub kSharedUserDataFolderType () { 'sdat' }

=item kVolumeSettingsFolderType

Volume specific user information goes here

=cut

sub kVolumeSettingsFolderType () { 'vsfd' }

=item kAppleshareAutomountServerAliasesFolderType

Appleshare puts volumes to automount inside this folder.

=cut

sub kAppleshareAutomountServerAliasesFolderType () { "srv\304" }

=item kPreMacOS91ApplicationsFolderType

The "Applications" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91ApplicationsFolderType () { "\345pps" }

=item kPreMacOS91InstallerLogsFolderType

The "Installer Logs" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91InstallerLogsFolderType () { "\356lgf" }

=item kPreMacOS91AssistantsFolderType

The "Assistants" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91AssistantsFolderType () { "\345st\304" }

=item kPreMacOS91UtilitiesFolderType

The "Utilities" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91UtilitiesFolderType () { "\374ti\304" }

=item kPreMacOS91AppleExtrasFolderType

The "Apple Extras" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91AppleExtrasFolderType () { "\345ex\304" }

=item kPreMacOS91MacOSReadMesFolderType

The "Mac OS ReadMes" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91MacOSReadMesFolderType () { "\265or\304" }

=item kPreMacOS91InternetFolderType

The "Internet" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91InternetFolderType () { "\356nt\304" }

=item kPreMacOS91AutomountedServersFolderType

The "Servers" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91AutomountedServersFolderType () { "\337rv\304" }

=item kPreMacOS91StationeryFolderType

The "Stationery" folder, pre Mac OS 9.1

=cut

sub kPreMacOS91StationeryFolderType () { "\370dst" }

=back

=cut

# 
# Translate volume name or number
#
sub _VolumeID {
	my ($id) = @_;
	my ($name, $vRef);
	if ($id =~ /^[^:]+:$/) {
		($name, $vRef) = ($id, 0);
	} else {
		($name, $vRef) = ("", $id);
	}
	return ($name, $vRef);
}

sub UnmountVol 	{	_UnmountVol(&_VolumeID);	}
sub Eject	{	_Eject     (&_VolumeID);	}
sub FlushVol 	{	_FlushVol  (&_VolumeID);	}

# we try to convert the path to an HFS-style path because
# NewAliasMinimalFromFullPath only works with HFS-style paths
# ... or in the future we could try FSNewAliasMinmalUnicode,
# but that will only work if the directory underneath works ...
# plus we need to convert to Unicode ... bleah
if ($^O ne 'MacOS') {
	*NAMFFP = *NewAliasMinimalFromFullPath{CODE};
	no strict 'refs';
	no warnings 'redefine'; 
	*NewAliasMinimalFromFullPath = sub {
		NAMFFP(_Unix2Mac($_[0]));
	}
}

sub _Unix2Mac {
	require MacPerl;
	my($path) = @_;

	# normalize
	# for this reason, either file, or path to file, must exist already
	my $path2 = MacPerl::MakeFSSpec($path);
	$path = MacPerl::MakePath($path2);

	# is this a relative url?
	if (substr($path, 0, 1) ne '/') {
		$path =~ tr|/:|:/|;
		$path = ':' . $path;
	}

	# is this an absolute url with another Volume?
	elsif ($path =~ m|^/Volumes/([^/]+)(/.*)|) {
		my $volume = $1;
		my $rest   = $2;

		$rest =~ tr|/:|:/|;
		$path = $volume . $rest;
	}

	# absolute path off of startup volume
	elsif (substr($path, 0, 1) eq '/') {
		(my $volume = scalar MacPerl::Volumes()) =~ s/^.+?:(.+)$/$1/;

		$path =~ tr|/:|:/|;
		$path = $volume . $path;
	}

	return $path;
}


=include Files.xs

=head1 AUTHOR

Written by Matthias Ulrich Neeracher E<lt>neeracher@mac.comE<gt>.
Currently maintained by Chris Nandor E<lt>pudge@pobox.comE<gt>.

=cut

1;

__DATA__
