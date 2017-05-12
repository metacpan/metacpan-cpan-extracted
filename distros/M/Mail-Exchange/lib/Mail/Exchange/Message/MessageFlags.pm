package Mail::Exchange::Message::MessageFlags;
# From MS-OCXMSG V20120630 2.2.1.6

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;

use vars qw($VERSION @ISA @EXPORT);
@ISA=qw(Exporter);
$VERSION = "0.01";

@EXPORT=qw(mfRead mfUnmodified mfSubmitted mfUnsent mfHasAttach mfFromMe mfFAI
	mfNotifyRead mfNotifyUnread mfEverRead mfInternet mfUntrusted
);

sub mfRead		{ return 0x0001; }
sub mfUnmodified	{ return 0x0002; }
sub mfSubmitted		{ return 0x0004; }
sub mfUnsent		{ return 0x0008; }
sub mfHasAttach		{ return 0x0010; }
sub mfFromMe		{ return 0x0020; }
sub mfFAI		{ return 0x0040; }
sub mfNotifyRead	{ return 0x0100; }
sub mfNotifyUnread	{ return 0x0200; }
sub mfEverRead		{ return 0x0400; }
sub mfInternet		{ return 0x2000; }
sub mfUntrusted		{ return 0x8000; }
