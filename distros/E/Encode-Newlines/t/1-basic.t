#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;

my ($CR, $LF, $CRLF) = ("\015", "\012", "\015\012");
my $Native = (
    ($^O =~ /^(?:MSWin|cygwin|dos|os2)/) ? $CRLF :
    ($^O =~ /^MacOS/) ? $CR : $LF
);

use_ok('Encode');
use_ok('Encode::Newlines');

is(encode(CR => ".$LF.$LF.") => ".$CR.$CR.", 'CR');
is(decode(CR => ".$CRLF.$CRLF.") => ".$CR.$CR.", 'CR');
is(encode(LF => ".$CR.$CR.") => ".$LF.$LF.", 'LF');
is(decode(LF => ".$CRLF.$CRLF.") => ".$LF.$LF.", 'LF');
is(decode(CRLF => ".$CR.$CR.") => ".$CRLF.$CRLF.", 'CRLF');
is(encode(CRLF => ".$LF.$LF.") => ".$CRLF.$CRLF.", 'CRLF');
is(decode(Native => ".$CR.$CR.") => ".$Native.$Native.", 'Native');
is(encode(Native => ".$LF.$LF.") => ".$Native.$Native.", 'Native');
is(encode(Native => ".$CRLF.$CRLF.") => ".$Native.$Native.", 'Native');
is(decode('LF-CR' => ".$CRLF.$CRLF.") => ".$LF.$LF.", 'LF-CR');
is(encode('LF-CR' => ".$CRLF.$CRLF.") => ".$CR.$CR.", 'LF-CR');

is(eval { decode(CRLF => ".$CR.$CRLF.") } => undef, 'Mixed decode');
like($@, qr/Mixed/, 'Mixed warnings');

local $Encode::Newlines::AllowMixed = 1;
is(eval { decode(CRLF => ".$CR.$CRLF.") } => ".$CRLF.$CRLF.", 'AllowMixed');

local $Encode::Newlines::AllowMixed = 0;
is(eval { decode(CRLF => ".$CR.$CRLF.") } => undef, 'Mixed decode');
like($@, qr/Mixed/, 'Mixed warnings');

1;
