package IETF::ACE;

use strict;
use diagnostics;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use AutoLoader qw(AUTOLOAD);

use Unicode::String qw(utf8 ucs4 utf16);
use MIME::Base64;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IETF::ACE ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
) ] );

@EXPORT_OK = qw (
   @{ $EXPORT_TAGS{'all'} }
   &UCS4toName
   &UCS4toUPlus
   &UTF5toUCS4
   &GetCharFromUTF5
   &UCS4toRACE
   &RACEtoUCS4
   &UCS4toLACE
   &LACEtoUCS4
   &Base32Encode
   &Base32Decode
   &CheckForSTD13Name
   &CheckForBadSurrogates
   &HexOut
   &DebugOn
   &DebugOff
   &DebugOut
);

@EXPORT = qw(
);

$VERSION = '0.04';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

my @Formats = ('utf8', 'utf16', 'ucs4', 'utf5', 'race', 'lace', 'name', 'u+');
my $UTF5Chars = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
my $Base32Chars = 'abcdefghijklmnopqrstuvwxyz234567';
my $RACEPrefix = 'bq--';
my $LACEPrefix = 'lq--';

my $Debug = 0;

1;

sub UCS4toName {
	my $InString = shift(@_);
	my @TheNames = ucs4($InString)->name;
	my $NameString = join("\n", @TheNames) . "\n";
	return $NameString;
}

sub UCS4toUPlus {
	my $InString = shift(@_);
	my $TheHex = ucs4($InString)->hex . "\n";
	$TheHex =~ s/ /\n/g;
	$TheHex = uc($TheHex);
	return $TheHex;
}

sub UTF5toUCS4 {
	my $InString = shift(@_);
	my $OutString = '';
	my ($ThisUCS4, $ThisCharString, @RevString, $Char, $WhichChar);
	my ($TempNum, $TempChr, $TempPos);
	until(length($InString) == 0) {
		($ThisCharString, $InString) = &GetCharFromUTF5($InString);
		$ThisUCS4 = "\x00\x00\x00\x00";
		@RevString = reverse(split(//, $ThisCharString));
		$WhichChar = 0;
		foreach $Char (@RevString) {
			$TempNum = index($UTF5Chars, $Char) % 16;
			if(($WhichChar % 2) == 1) { $TempNum *= 16 };
			$TempChr = chr($TempNum);
			$TempPos = (int($WhichChar / 2));
			if($TempPos == 0) { $TempChr = "\x00" x 3 . $TempChr }
			elsif($TempPos == 1) { $TempChr = "\x00" x 2 . $TempChr . "\x00" }
			elsif($TempPos == 2) { $TempChr = "\x00" . $TempChr . "\x00" x 2 }
			elsif($TempPos == 3) { $TempChr = $TempChr . "\x00" x 3 }
			$ThisUCS4 = $ThisUCS4 | $TempChr;
			$WhichChar += 1;
		}
		$OutString .= $ThisUCS4;
	}
	return $OutString;
}

sub GetCharFromUTF5 {
	my $InString = shift(@_);
	my $FirstChar = substr($InString, 0, 1);
	unless(grep(/[GHIJKLMNOPQRSTUV]/, $FirstChar))
		{ &DieOut("Found bad character string in UTF5 at $InString" .
			" in GetCharFromUTF5\n") }
	my $ThisCharString = $FirstChar;
	$InString = substr($InString, 1);
	until(grep(/[GHIJKLMNOPQRSTUV]/, substr($InString, 0, 1))) {
		$ThisCharString .= substr($InString, 0, 1);
		$InString = substr($InString, 1);
		last if(length($InString) == 0);
	}
	return ($ThisCharString, $InString);
}

sub UCS4toUTF5 {
	my $InString = shift(@_);
	my $OutString = '';
	my ($ThisUCS4, $i, $Nibble, $HaveSeenFirst);
	until(length($InString) == 0) {
		$ThisUCS4 = substr($InString, 0, 4);
		$InString = substr($InString, 4);
		my @Octets = split(//, $ThisUCS4);
		$HaveSeenFirst = 0;
		foreach $i (0 .. 7) {
			if(($i % 2) == 0)
				{ $Nibble = chr(ord($Octets[int($i / 2)] & "\xf0") >> 4) }
			else
				{ $Nibble = $Octets[int($i / 2)] & "\x0f" };
			next if(($Nibble eq "\x00") and !($HaveSeenFirst));
			if($HaveSeenFirst)
				{ $OutString .= substr($UTF5Chars, ord($Nibble), 1) }
			else {
				$OutString .= substr($UTF5Chars, ord($Nibble)+16, 1);
				$HaveSeenFirst = 1;
			}
		}
	}
	return $OutString;

}

sub UCS4toRACE {
	my $InString = shift(@_);
	my (@InArr, $InStr, $InputPointer, $DoStep3, @UpperUniq, %UpperSeen,
		$U1, $U2, $N1, $CompString,
		$PostBase32);

	&DebugOut("Hex of input to UCS4toRACE:\n", &HexOut($InString));
	# Make an array of the UTF16 octets
	@InArr = split(//, ucs4($InString)->utf16);
	$InStr = join('', @InArr);
	&DebugOut("Hex of UTF16 input to UCS4toRACE:\n", &HexOut($InStr));
	if(&CheckForSTD13Name($InStr))
		{ &DieOut("Found all-STD13 name in input to UCS4toRACE\n") }

	# Prepare for steps 1 and 2 by making an array of the upper octets
	for($InputPointer = 0; $InputPointer <= $#InArr; $InputPointer += 2) {
		unless ($UpperSeen{$InArr[$InputPointer]}) {
			$UpperSeen{$InArr[$InputPointer]} = 1;
			push (@UpperUniq, $InArr[$InputPointer])
		}
	}
	if($#UpperUniq == 0) { # Step 1
		$U1 = $UpperUniq[0];
		$DoStep3 = 0;
	} elsif($#UpperUniq == 1) {  # Step 2
		if($UpperUniq[0] eq "\x00") {
			$U1 = $UpperUniq[1];
			$DoStep3 = 0;
		} elsif($UpperUniq[1] eq "\x00") {
			$U1 = $UpperUniq[0];
			$DoStep3 = 0;
		} else { $DoStep3 = 1 }
	} else { $DoStep3 = 1 }
	# Now output based on the value of $DoStep3
	if($DoStep3) {  # Step 3
		&DebugOut("Not compressing in UCS4toRACE (using D8 format).\n");
		$CompString = "\xd8" . join('', @InArr);
	} else {
		if(($U1 ge "\xd8") and ($U1 le "\xdc")) {  # Step 4a
			my $DieOrd = sprintf("%04lX", ord($U1));
			&DieOut("Found invalid input to UCS4toRACE step 4a: $DieOrd.\n");
		}
		&DebugOut("Compressing in UCS4toRACE (first octet is ",
				sprintf("%04lX", ord($U1)), ").\n");
		$CompString = $U1;  # Step 4b
		$InputPointer = 0;
		while($InputPointer <= $#InArr) {  # Step 5a
			$U2 = $InArr[$InputPointer++]; $N1 = $InArr[$InputPointer++];  # Step 5b
			if(($U2 eq "\x00") and ($N1 eq "\x99"))  # Step 5c
				{ &DieOut("Found U+0099 in input stream to UCS4toRACE step 5c.\n"); }
			if( ($U2 eq $U1) and ($N1 ne "\xff") )  # Step 6
				{ $CompString .= $N1 }
			elsif( ($U2 eq $U1) and ($N1 eq "\xff") )  # Step 7
				{ $CompString .= "\xff\x99" }
			else { $CompString .= "\xff" . $N1 }  # Step 8
		}
	}
	&DebugOut("Hex of output before Base32Encode:\n", &HexOut($CompString));
	if(length($CompString) >= 37)
		{  &DieOut("Length of compressed string was >= 37 in UCS4toRACE.\n") }
	$PostBase32 = &Base32Encode($CompString);
	return "$RACEPrefix$PostBase32";
}

sub RACEtoUCS4 {
	my $InString = lc(shift(@_));
	my ($PostBase32, @DeArr, $i, $U1, $N1, $OutString, $LCheck,
		$InputPointer, @UpperUniq, %UpperSeen);
	# Strip any whitespace
	$InString =~ s/\s*//g;
	# Strip of the prefix string
	unless(substr($InString, 0, length($RACEPrefix)) eq $RACEPrefix)
		{ &DieOut("The input to RACEtoUCS4 did not start with '$RACEPrefix'\n") }
	$InString = substr($InString, length($RACEPrefix));
	&DebugOut("The string after stripping in RACEtoUCS4: $InString\n");

	$PostBase32 = &Base32Decode($InString);
	@DeArr = split(//, $PostBase32);

	# Reverse the compression
	$U1 = $DeArr[0];  # Step 1a
	if($#DeArr < 1)  # Step 1b
		{ &DieOut("The output of Base32Decode was too short.\n") } 
	
	unless ($U1 eq "\xd8") {  # Step 1c
		$i = 1;
		until($i > $#DeArr) {  # Step 2a
			$N1 = $DeArr[$i++];  # Step 2b
			unless($N1 eq "\xff")  {  # Step 2c
				if(($U1 eq "\x00") and ($N1 eq "\x99"))  # Step 3
					{ &DieOut("Found 0099 in the input to RACEtoUCS4, step 3.\n") }
				$OutString .= $U1 . $N1;  # Step 4
			} else {
				if($i > $#DeArr)  # Step 5
					{ &DieOut("Input in RACE string at octet $i too short " .
						"at step 5\n") }
				$N1 = $DeArr[$i++];  # Step 6a
				if($N1 eq "\x99")  # Step 6b
					{ $OutString .= $U1 . "\xff" }
				else  # Step 7
					{ $OutString .= "\x00" . $N1 }
			}
		}
		if((length($OutString) % 2) == 1)  # Step 11
			{ &DieOut("The output of RACEtoUCS4 for compressed input was " .
				"an odd number of characters at step 11.\n") }
	} else {  # Was not compressed 
		$LCheck = substr(join('', @DeArr), 1);  # Step 8a
		if((length($LCheck) % 2 ) == 1 )  # Step 8b
			{ &DieOut("The output of RACEtoUCS4 for uncompressed input was " .
				"an odd number of characters at step 8b.\n") }
		# Do the step 9 check to be sure the right length was used
		my @CheckArr = split(//, $LCheck);
		for($InputPointer = 0; $InputPointer <= $#CheckArr; $InputPointer += 2) {
			unless ($UpperSeen{$CheckArr[$InputPointer]}) {
				$UpperSeen{$CheckArr[$InputPointer]} = 1;
				push (@UpperUniq, $CheckArr[$InputPointer])
			}
		}
		# Should it have been compressed?
		if( ($#UpperUniq == 0) or
			( ($#UpperUniq == 1) and 
				(($UpperUniq[0] eq "\x00") or ($UpperUniq[1] eq "\x00"))
			)
		) { &DieOut("Input to RACEtoUCS4 failed during LCHECK format test " .
				"in step 9.\n") }
		if((length($LCheck) % 2) == 1)  # Step 10a
			{ &DieOut("The output of RACEtoUCS4 for uncompressed input was " .
				"an odd number of characters at step 10a.\n") }
		$OutString = $LCheck
	}
	&DebugOut("Hex of output string:\n", &HexOut($OutString));
	if(&CheckForSTD13Name($OutString))
		{ &DieOut("Found all-STD13 name before output of RACEtoUCS4\n") }
	if(&CheckForBadSurrogates($OutString))
		{ &DieOut("Found bad surrogate before output of RACEtoUCS4\n") }
	return utf16($OutString)->ucs4;
}

sub UCS4toLACE {
	my $InString = shift(@_);
	my (@InArr, $InStr, $InputPointer, $High, $OutBuffer, $Count, $LowBuffer,
		$i, $CompString, $PostBase32);

	&DebugOut("Hex of input to UCS4toLACE:\n", &HexOut($InString));
	# Make an array of the UTF16 octets
	@InArr = split(//, ucs4($InString)->utf16);
	$InStr = join('', @InArr);
	&DebugOut("Hex of UTF16 input to UCS4toLACE:\n", &HexOut($InStr));
	if(&CheckForSTD13Name($InStr))
		{ &DieOut("Found all-STD13 name in input to UCS4toLACE\n") }

	if(((length($InStr) % 2) == 1) or (length($InStr) < 2))  # Step 1
		{ &DieOut("Odd length or too short on input to UCS4toLACE\n") }
	$InputPointer = 0;  # Step 2
	my $OutputBuffer = '';
	do {
		$High = $InArr[$InputPointer];  # Step 3
		$Count = 1; $LowBuffer = $InArr[$InputPointer+1];
		for($i = $InputPointer + 2; $i <= $#InArr; $i+=2) {  # Step 4
			last unless($InArr[$i] eq $High);
			$Count += 1;
			$LowBuffer .= $InArr[$i+1];
		}
		$OutputBuffer .= sprintf("%c", $Count) . "$High$LowBuffer";  # Step 5a
		$InputPointer = $InputPointer + (2 * $Count);  # Step 5b
	} while($InputPointer <= $#InArr);  # Step 6

	if(length($OutputBuffer) <= length($InStr))  # Step 7a
		{ $CompString = $OutputBuffer }
	else
		{ $CompString = "\xff" . $InStr; }

	&DebugOut("Hex of output before Base32Encode:\n", &HexOut($CompString));
	if(length($CompString) >= 37)
		{  &DieOut("Length of compressed string was >= 37 in UCS4toLACE.\n") }
	$PostBase32 = &Base32Encode($CompString);
	return "$LACEPrefix$PostBase32";
}

sub LACEtoUCS4 {
	my $InString = lc(shift(@_));
	my ($PostBase32, @DeArr, $Count, $InputPointer, $OutString, $LCheck,
		$OutputBuffer, $CompBuffer, @LArr, $LPtr, $RunCount, $RunBuffer);
        my $Low;
        my $High;
	# Strip any whitespace
	$InString =~ s/\s*//g;
	# Strip of the prefix string
	unless(substr($InString, 0, length($LACEPrefix)) eq $LACEPrefix)
		{ &DieOut("The input to LACEtoUCS4 did not start with '$LACEPrefix'\n") }
	$InString = substr($InString, length($LACEPrefix));
	&DebugOut("The string after stripping in LACEtoUCS4: $InString\n");

	$PostBase32 = &Base32Decode($InString);
	@DeArr = split(//, $PostBase32);

	$InputPointer = 0;  # Step 1a
	if($#DeArr < 1)  # Step 1b
		{ &DieOut("The output of Base32Decode was too short.\n") }
	$OutputBuffer = '';
	unless ($DeArr[$InputPointer] eq "\xff") {  # Step 2
		do {
			$Count = $DeArr[$InputPointer]; # Step 3a
			if(($Count == 0) or ($Count > 36))  # Step 3b
				{ &DieOut("Got bad count ($Count) in LACEtoUCS4 step 3b.\n") };
			if(++$InputPointer == $#DeArr)  # Step 3c and 3d
				{ &DieOut("Got bad length input in LACEtoUCS4 step 3d.\n") };
			$High = $DeArr[$InputPointer++]; # Step 4a and 4b
			do {
			if($InputPointer == $#DeArr)  # Step 5a
				{ &DieOut("Got bad length input in LACEtoUCS4 step 5a.\n") };
				$Low = $DeArr[$InputPointer++]; # Step 5c and 5c
				$OutputBuffer .= $High . $Low;  # Step 6
			} until(--$Count > 0);  # Step 7
		}  while($InputPointer < $#DeArr);  # Step 8
		if(length($OutputBuffer) > length($InString)) {  # Step 9b
			&DieOut("Wrong compression format found in LACEtoUCS4 step 9b.\n");
		} elsif((length($OutputBuffer) % 2) == 1) {  # Step 9c
			&DieOut("Odd length output buffer found in LACEtoUCS4 step 9c.\n");
		} else { $OutString = $OutputBuffer }  # Step 9d
	} else {  # Step 10
		$OutputBuffer = substr(join('', @DeArr), 1);  # Step 10a
		if((length($OutputBuffer) % 2 ) == 1 )  # Step 10b
			{ &DieOut("The output of LACEtoUCS4 for uncompressed input was " .
				"an odd number of characters at step 10b.\n") }
		# Step 11a
		$CompBuffer = ''; @LArr = split(//, $OutputBuffer); $LPtr = 0;
		do {
			$High = $LArr[$LPtr++];  # Step 3
			$RunCount = 1; $RunBuffer = $LArr[$LPtr++];
			while(1) {  # Step 4
				last if($LArr[$LPtr] ne $High);
				$LPtr +=1;
				$RunCount += 1;
				$RunBuffer .= $LArr[$LPtr++];
			}
			$CompBuffer .= sprintf("%c", $RunCount) . $High .
				$RunBuffer;  # Step 5
		} while($LPtr <= $#LArr);  # Step 6
		if(length($CompBuffer) <= length($OutputBuffer))  { # Step 11b
			&DieOut("Wrong compression format found in LACEtoUCS4 step 11b.\n");
		} else { $OutString = $OutputBuffer }  # Step 11c
	}
	&DebugOut("Hex of output string:\n", &HexOut($OutString));
	if(&CheckForSTD13Name($OutString))
		{ &DieOut("Found all-STD13 name before output of LACEtoUCS4\n") }
	if(&CheckForBadSurrogates($OutString))
		{ &DieOut("Found bad surrogate before output of LACEtoUCS4\n") }
	return utf16($OutString)->ucs4;
}

sub Base32Encode {
	my($ToEncode) = shift(@_);
	my ($i, $OutString, $CompBits, $FivePos, $FiveBitsString, $FiveIndex);
	
	&DebugOut("Hex of input to Base32Encode:\n", &HexOut($ToEncode));

	# Turn the compressed string into a string that represents the bits as
	#    0 and 1. This is wasteful of space but easy to read and debug.
	$CompBits = '';
	foreach $i (split(//, $ToEncode)) { $CompBits .= unpack("B8", $i) };

	# Pad the value with enough 0's to make it a multiple of 5
	if((length($CompBits) % 5) != 0)
		{ $CompBits .= '0' x (5 - (length($CompBits) % 5)) };  # Step 1a
	&DebugOut("The compressed bits in Base32Encode after padding:\n"
		. "$CompBits\n");
	$FivePos = 0;  # Step 1b
	do {
		$FiveBitsString = substr($CompBits, $FivePos, 5);  # Step 2
		$FiveIndex = unpack("N", pack("B32", ('0' x 27) . $FiveBitsString));
		$OutString .= substr($Base32Chars, $FiveIndex, 1);  # Step 3
		$FivePos += 5;  # Step 4a
	} until($FivePos == length($CompBits));  # Step 4b
	&DebugOut("Output of Base32Encode:\n$OutString\n");
	return $OutString;
}

sub Base32Decode {
	my ($ToDecode) = shift(@_);
	my ($InputCheck, $OutString, $DeCompBits, $DeCompIndex, @DeArr, $i,
		$PaddingLen, $PaddingContent);
	&DebugOut("Hex of input to Base32Decode:\n", &HexOut($ToDecode));

	$InputCheck = length($ToDecode) % 8;  # Step 1
	if(($InputCheck == 1) or
	   ($InputCheck == 3) or
	   ($InputCheck == 6))
		{ &DieOut("Input to Base32Decode was a bad mod length: $InputCheck\n") }

	# $DeCompBits is a string that represents the bits as
	#    0 and 1. This is wasteful of space but easy to read and debug.
	$DeCompBits = '';
	my $InChar;
	foreach $InChar (split(//, $ToDecode)) { 
		$DeCompIndex = pack("N", index($Base32Chars, $InChar));
		$DeCompBits .= substr(unpack("B32", $DeCompIndex), 27);
	}
	&DebugOut("The decompressed bits in Base32Decode:\n$DeCompBits\n");
	&DebugOut("The number of bits in Base32Decode: " ,
		length($DeCompBits), "\n");

	# Step 5
	my $Padding = length($DeCompBits) % 8;
	$PaddingContent = substr($DeCompBits, (length($DeCompBits) - $Padding));
	&DebugOut("The padding check in Base32Decode is \"$PaddingContent\"\n");
	unless(index($PaddingContent, '1') == -1)
		{ &DieOut("Found non-zero padding in Base32Decode\n") }

	# Break the decompressed string into octets for returning
	@DeArr = ();
	for($i = 0; $i < int(length($DeCompBits) / 8); $i++) {
		$DeArr[$i] =
			chr(unpack("N", pack("B32", ('0' x 24) . substr($DeCompBits, $i * 8, 8))));
	}
	$OutString = join('', @DeArr);
	&DebugOut("Hex of the decompressed array:\n", &HexOut("$OutString"));
	return $OutString;
}

sub CheckForSTD13Name {
	# The input is in UTF-16
	my $InCheck = shift(@_);
	my (@CheckArr, $CheckPtr, $Lower, $Upper);
	@CheckArr = split(//, $InCheck);
	$CheckPtr = 0;
	my $STD13Chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYX' .
		'0123456789-';
	until($CheckPtr > $#CheckArr) {
		$Upper = $CheckArr[$CheckPtr++];
		$Lower = $CheckArr[$CheckPtr++];
		if(($Upper ne "\x00") or
			(index($STD13Chars, $Lower) == -1) ) { return 0 }
	}
	return 1;
}

sub CheckForBadSurrogates {
	# The input is in UTF-16
	my $InCheck = shift(@_);
	my (@CheckArr, $CheckPtr, $Upper1, $Upper2);
	@CheckArr = split(//, $InCheck);
	$CheckPtr = 0;
	my $HighSurr = "\xD8\xD9\xDA\xDB";
	my $LowSurr = "\xDC\xDD\xDE\xDF";
	until($CheckPtr > $#CheckArr) {
		# Check for bad half-pair
		if((($CheckPtr + 2 ) >= $#CheckArr) and
			(index($HighSurr.$LowSurr, $CheckArr[$CheckPtr]) > -1 )) {
				&DebugOut("Found bad half-pair in CheckForBadSurrogates: " .
					sprintf("%2.2x", ord($CheckArr[$CheckPtr])));
				return 1;
		}
		last unless(defined($CheckArr[$CheckPtr + 4]));
		$Upper1 = $CheckArr[$CheckPtr += 2];
		$Upper2 = $CheckArr[$CheckPtr += 2];
		if( ((index($HighSurr, $Upper1) > -1) and
			 (index($LowSurr, $Upper2) == -1))
			or
			((index($HighSurr, $Upper1) == -1) and
			 (index($LowSurr, $Upper2) > -1))) {
			&DebugOut("Found bad pair in CheckForBadSurrogates: " .
				sprintf("%2.2x", ord($Upper1)) . " and " .
				sprintf("%2.2x", ord($Upper2)) . "\n");
			return 1;
		}
	}
	return 0;
}

sub HexOut {
	my $AllInStr = shift(@_);
	my($HexIn, $HexOut, @AllOrd, $i, $j, $k, $OutReg, $SpOut);
        my @HexIn;
	my($OctetIn, $LineCount);
        my @OctetIn;
	my $OutString = '';
	@AllOrd = split(//, $AllInStr);
	
	$HexIn[23] = '';
	while(@AllOrd) {
		for($i = 0; $i < 24; $i++) {
			$OctetIn[$i] = shift(@AllOrd);
			if(defined($OctetIn[$i])) {
				$HexIn[$i] = sprintf('%2.2x', ord($OctetIn[$i]));
				$LineCount = $i;
			}
		}
		for($j = 0; $j <= $LineCount; $j++ ) {
			$HexOut .= $HexIn[$j];
			if(($j % 4) == 3) { $HexOut .= ' ' }
			if((ord($OctetIn[$j]) < 20) or (ord($OctetIn[$j]) > 126))
				{ $OutReg .= '.' }
			else { $OutReg .= $OctetIn[$j] }
		}
		for ($k=length($HexOut); $k < 56; $k++) { $SpOut .= ' ' }
		$OutString .= "$HexOut$SpOut$OutReg\n" ;
		$HexOut = ''; $OutReg = ''; $SpOut = '';
	}
	return $OutString
}

sub DebugOn {
	$Debug = 1;
}

sub DebugOff {
	$Debug = 0;
}

sub DebugOut {
	# Print out an error string if $Debug is set
	my $DebugTemp = join('', @_);
	if($Debug) { print STDERR $DebugTemp; }
}

sub DieOut {
        my $DieTemp = shift(@_);
#        if(defined($ErrTmp)) { print STDERR $DieTemp; }
        die;
}


__END__
=head1 NAME

IETF::ACE - Perl extension for IETF IDN WG ACE character conversions

=head1 SYNOPSIS

  use IETF::ACE qw / ... /;

=head1 DESCRIPTION

IETF::ACE - Perl extension for IETF IDN WG ACE character conversions

  Subroutines

  UCS4toName
  UCS4toUPlus
  UTF5toUCS4
  GetCharFromUTF5
  UCS4toRACE
  RACEtoUCS4
  UCS4toLACE
  LACEtoUCS4
  Base32Encode
  Base32Decode
  CheckForSTD13Name
  CheckForBadSurrogates
  HexOut
  DebugOn
  DebugOff
  DebugOut

  The formats are:

  utf8
  utf16
  ucs4
  utf5      from draft-jseng-utf5-01.txt
  race      draft-ietf-idn-race-03.txt
  lace      draft-ietf-idn-lace-01.txt
  name      The character names; output only
  u+        The character hex values in U+ notation; output only

=head1 Example

 use strict;
 use diagnostics;

 use Unicode::String qw / utf8 /;
 use IETF::ACE qw / &UCS4toRACE /;

 my $TheIn="ábcde"; # .com

 my $TheUCS4 = utf8($TheIn)->ucs4;

 my $TheOut = &UCS4toRACE($TheUCS4);

 print <<EOD;
Latin1 Input = $TheIn.com
RACE Output = $TheOut.com
EOD

=head2 EXPORT

None by default.

=head1 AUTHOR

Paul Hoffman, Internet Mail Consortium
phoffman@mail.imc.org

James Briggs
james.briggs@yahoo.com

=head1 SEE ALSO

None.

=cut
