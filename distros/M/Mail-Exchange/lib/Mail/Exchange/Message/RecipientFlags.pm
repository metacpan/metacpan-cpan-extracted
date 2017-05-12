package Mail::Exchange::Message::RecipientFlags;
# From MS-OXOCAL V20120630 2.2.4.10.1

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;

use vars qw($VERSION @ISA @EXPORT);
@ISA=qw(Exporter);
$VERSION = "0.01";

@EXPORT=qw(
	recipSendable recipOrganizer recipExceptionalResponse
	recipExceptionalDeleted recipOriginal
);

sub recipSendable		{ return 0x0001; }
sub recipOrganizer		{ return 0x0002; }
sub recipExceptionalResponse	{ return 0x0010; }
sub recipExceptionalDeleted	{ return 0x0020; }
sub recipOriginal		{ return 0x0100; }
