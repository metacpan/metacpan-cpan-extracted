package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
badPasteboardFlavorErr
badPasteboardIndexErr
badPasteboardItemErr
badPasteboardSyncErr
callback
Capitan
CFStringRef
com
const
coreFoundationUnknownErr
defaultEncode
defaultFlavor
dualvar
duplicatePasteboardFlavorErr
executables
El
hoc
jpeg
JPEG
kPasteboardClientIsOwner
kPasteboardClipboard
kPasteboardFind
kPasteboardFlavorNoFlags
kPasteboardFlavorNotSaved
kPasteboardFlavorPromised
kPasteboardFlavorRequestOnly
kPasteboardFlavorSenderOnly
kPasteboardFlavorSenderTranslated
kPasteboardFlavorSystemTranslated
kPasteboardModified
kPasteboardUniqueName
mac
macerror
macOS
MacRoman
MacSomething
merchantability
noPasteboardPromiseKeeperErr
nobinary
noecho
noid
notPasteboardOwnerErr
pasteboards
pbcopy
pbencode
pbflavor
pbpaste
pbtool
Pbtool
Peeker
PerlDroplet
programmatically
readonly
ssh
subflavor
synch
UTF
UTIs
Wyant
XS
YAML
