package HTML::AA;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.10';
#-------------------------------------------------------------------------------
# Module declaration
#-------------------------------------------------------------------------------
sub new {
	my $self = {};
	bless $self;
	return $self;
}
#-------------------------------------------------------------------------------
# The character-code is declared.
#-------------------------------------------------------------------------------
my $code = 'euc';
#-------------------------------------------------------------------------------
# The character-code that the module processes is declared.
# It is effective in the call that doesn't specify the character-code.
# If it wants to process it with EUC-JP, it is euc.
# $aart -> code('euc');
# If it wants to process it with Shift_JIS, it is sjis.
# $aart -> code('sjis');
#-------------------------------------------------------------------------------
sub code {
	my $self = shift;
	$code    = shift;
}
#-------------------------------------------------------------------------------
# The number of dots is calculated.
# $aart -> calcu($str);
#-------------------------------------------------------------------------------
sub calcu {
	my $self   = shift;
	my $str    = shift;

	return $self -> calcu_euc($str)  if $code eq 'euc';
	return $self -> calcu_sjis($str) if $code eq 'sjis';
}
# When you want to process it with EUC-JP disregarding the character-code declaration
# $aart -> calcu_euc($str);
sub calcu_euc {
	my $self = shift;
	my $str  = shift;

	my $count = 0;

	foreach ( $self -> divide_euc($str) ) {
		#------------------- 2 bytes
		if ($_ =~ /../) {
			if ($_ =~ /\xa1\xbc|\xa3\xcd|\xa3\xed|\xa4\xa2|\xa4\xa4|\xa4\xaa|\xa4\xb1|\xa4\xb9|\xa4\xbd|\xa4\xbe|\xa4\xbf|\xa4\xc0|\xa4\xc4|\xa4\xc5|\xa4\xcb|\xa4\xd2|\xa4\xd3|\xa4\xd4|\xa4\xf3|\xa5\xa6|\xa5\xaa|\xa5\xac|\xa5\xad|\xa5\xae|\xa5\xb0|\xa5\xb1|\xa5\xb2|\xa5\xba|\xa5\xbb|\xa5\xc0|\xa5\xc1|\xa5\xc2|\xa5\xc5|\xa5\xc7|\xa5\xca|\xa5\xcb|\xa5\xcd|\xa5\xd8|\xa5\xd9|\xa5\xda|\xa5\xdb|\xa5\xdc|\xa5\xdd|\xa5\xe6|\xa5\xef|\xa5\xf4/){
				$count += 15;
			}
			elsif ($_ =~ /\xa4\xa8|\xa4\xad|\xa4\xae|\xa4\xb4|\xa4\xb6|\xa4\xc1|\xa4\xc2|\xa4\xc6|\xa4\xc7|\xa4\xc9|\xa4\xca|\xa4\xde|\xa4\xe3|\xa4\xe5|\xa4\xe8|\xa4\xeb|\xa4\xed|\xa4\xee|\xa4\xf2|\xa5\xa2|\xa5\xa8|\xa5\xb4|\xa5\xb7|\xa5\xb8|\xa5\xb9|\xa5\xbe|\xa5\xc4|\xa5\xc6|\xa5\xd3|\xa5\xd4|\xa5\xd6|\xa5\xd7|\xa5\xde|\xa5\xe2|\xa5\xec|\xa5\xed|\xa5\xf3/){
				$count += 14;
			}
			elsif ($_ =~ /\xa3\xcf|\xa3\xd1|\xa4\xa3|\xa4\xa9|\xa4\xb0|\xa4\xb3|\xa4\xc3|\xa4\xe2|\xa4\xe9|\xa5\xa4|\xa5\xa9|\xa5\xab|\xa5\xaf|\xa5\xb3|\xa5\xbd|\xa5\xcc|\xa5\xd5|\xa5\xe3|\xa5\xe5|\xa5\xe9|\xa5\xf2/){
				$count += 13;
			}
			elsif ($_ =~ /\xa1\xb3|\xa1\xb4|\xa1\xb5|\xa3\xc2|\xa3\xc3|\xa3\xc4|\xa3\xc7|\xa3\xc8|\xa3\xcb|\xa3\xce|\xa3\xd2|\xa3\xd3|\xa3\xd5|\xa3\xf7|\xa4\xa1|\xa4\xa7|\xa4\xb5|\xa4\xb7|\xa4\xb8|\xa4\xc8|\xa4\xe7|\xa4\xea|\xa5\xa1|\xa5\xa5|\xa5\xa7|\xa5\xbf|\xa5\xc3|\xa5\xd2|\xa5\xe1|\xa5\xe8|\xa5\xea|\xa5\xee|\xa5\xf5|\xa5\xf6/){
				$count += 12;
			}
			elsif ($_ =~ /\x8e\xbb|\x8e\xd1|\x8e\xd4|\x8e\xd9|\xa1\xa2|\xa1\xa3|\xa1\xa4|\xa1\xa5|\xa1\xb6|\xa3\xb0|\xa3\xb1|\xa3\xb2|\xa3\xb3|\xa3\xb4|\xa3\xb5|\xa3\xb6|\xa3\xb7|\xa3\xb8|\xa3\xb9|\xa3\xc1|\xa3\xc5|\xa3\xd0|\xa3\xd6|\xa4\xa6|\xa5\xc9|\xa5\xce|\xa5\xdf|\xa1\xa1/){
				$count += 11;
			}
			elsif ($_ =~ /\x8e\xb0|\x8e\xb1|\x8e\xb3|\x8e\xb4|\x8e\xb5|\x8e\xb7|\x8e\xb9|\x8e\xbd|\x8e\xbe|\x8e\xc1|\x8e\xc2|\x8e\xc3|\x8e\xc5|\x8e\xc6|\x8e\xc8|\x8e\xca|\x8e\xcd|\x8e\xce|\x8e\xcf|\x8e\xd3|\x8e\xd5|\xa3\xc6|\xa3\xca|\xa3\xcc|\xa3\xd4|\xa3\xd8|\xa3\xd9|\xa3\xda|\xa3\xe2|\xa3\xe4|\xa3\xe8|\xa3\xeb|\xa3\xee|\xa3\xef|\xa3\xf0|\xa3\xf1|\xa3\xf5|\xa4\xa5|\xa5\xa3|\xa5\xc8|\xa5\xe7/){
				$count += 10;
			}
			elsif ($_ =~ /\xa3\xe1|\xa3\xe3|\xa3\xe5|\xa3\xe7|\xa3\xf3|\xa4\xaf|\x8e\xa6|\x8e\xb2|\x8e\xb6|\x8e\xb8|\x8e\xba|\x8e\xbc|\x8e\xbf|\x8e\xc0|\x8e\xc7|\x8e\xcc|\x8e\xd7|\x8e\xda|\x8e\xdb|\x8e\xdc|\x8e\xdd/){
				$count +=  9;
			}
			elsif ($_ =~ /\x8e\xa7|\x8e\xa9|\x8e\xaa|\x8e\xab|\x8e\xac|\x8e\xad|\x8e\xaf|\x8e\xc9|\x8e\xcb|\x8e\xd2|\x8e\xd6|\x8e\xd8|\xa1\xa6|\xa1\xa7|\xa1\xa8|\xa1\xab|\xa1\xac|\xa1\xad|\xa1\xae|\xa1\xaf|\xa1\xb0|\xa1\xbe|\xa1\xc6|\xa1\xc7|\xa1\xc8|\xa1\xc9|\xa1\xca|\xa1\xcb|\xa1\xcc|\xa1\xcd|\xa1\xce|\xa1\xcf|\xa1\xd0|\xa1\xd1|\xa1\xd2|\xa1\xd3|\xa1\xd4|\xa1\xd5|\xa1\xd6|\xa1\xd7|\xa1\xd8|\xa1\xd9|\xa1\xda|\xa1\xdb|\xa2\xf7|\xa2\xf8|\xa2\xf9|\xa3\xf6|\xa3\xf8|\xa3\xf9|\xa3\xfa/){
				$count +=  8;
			}
			elsif ($_ =~ /\x8e\xa2|\x8e\xa3|\x8e\xa5|\x8e\xa8|\x8e\xae|\x8e\xc4|\x8e\xd0|\x8e\xa1|\x8e\xa4/){
				$count +=  7;
			}
			elsif ($_ =~ /\xa3\xf2/){
				$count +=  6;
			}
			elsif ($_ =~ /\xa3\xe6|\xa3\xf4/){
				$count +=  5;
			}
			elsif ($_ =~ /\x8e\xde|\x8e\xdf|\xa3\xc9|\xa3\xe9|\xa3\xea|\xa3\xec/){
				$count +=  4;
			}
			# There is no character of 3 dots.
			else {
				$count += 16;
			}
		}
		#------------------- 1byte
		else {
			# There is no character of 15 dots.
			# There is no character of 14 dots.
			# There is no character of 13 dots.
			if ($_ =~ /\x4d|\x57|\x6d/){
				$count += 12;
			}
			elsif ($_ =~ /\x40|\x43|\x47|\x4f|\x51/){
				$count += 11;
			}
			elsif ($_ =~ /\x26|\x41|\x42|\x44|\x48|\x4b|\x4e|\x50|\x52|\x53|\x55|\x56|\x58|\x77/){
				$count += 10;
			}
			elsif ($_ =~ /\x45|\x46|\x4a|\x4c|\x54|\x59|\x5a/){
				$count +=  9;
			}
			elsif ($_ =~ /\x61|\x62|\x63|\x64|\x65|\x68|\x6e|\x6f|\x70|\x71|\x75|\x76|\x79|\x22|\x23|\x24|\x25|\x2a|\x2b|\x2d|\x2f|\x30|\x31|\x32|\x33|\x34|\x35|\x36|\x37|\x38|\x39|\x3c|\x3d|\x3e|\x5c/){
				$count +=  8;
			}
			elsif ($_ =~ /\x3f|\x5e|\x60|\x67|\x6b|\x73|\x78|\x7a|\x7e/){
				$count +=  7;
			}
			elsif ($_ =~ /\x72|\x74/){
				$count +=  6;
			}
			elsif ($_ =~ /\x28|\x29|\x5b|\x5d|\x5f|\x66|\x20/){
				$count +=  5;
			}
			elsif ($_ =~ /\x21|\x49|\x6a|\x7b|\x7c|\x7d/){
				$count +=  4;
			}
			elsif ($_ =~ /\x27|\x2c|\x2e|\x3a|\x3b|\x69|\x6c/){
				$count +=  3;
			}
		}
	}

	return $count;
}
# When you want to process it with Shift_JIS disregarding the character-code declaration
# $aart -> calcu_sjis($str);
sub calcu_sjis {
	my $self = shift;
	my $str  = shift;

	my $count = 0;

	foreach ( $self -> divide_sjis($str) ) {
		#------------------- 2 bytes
		if ($_ =~ /../) {
			if ($_ =~ /\x81\x5b|\x82\x6c|\x82\x8d|\x82\xa0|\x82\xa2|\x82\xa8|\x82\xaf|\x82\xb7|\x82\xbb|\x82\xbc|\x82\xbd|\x82\xbe|\x82\xc2|\x82\xc3|\x82\xc9|\x82\xd0|\x82\xd1|\x82\xd2|\x82\xf1|\x83\x45|\x83\x49|\x83\x4b|\x83\x4c|\x83\x4d|\x83\x4f|\x83\x50|\x83\x51|\x83\x59|\x83\x5a|\x83\x5f|\x83\x60|\x83\x61|\x83\x64|\x83\x66|\x83\x69|\x83\x6a|\x83\x6c|\x83\x77|\x83\x78|\x83\x79|\x83\x7a|\x83\x7b|\x83\x7c|\x83\x86|\x83\x8f|\x83\x94/){
				$count += 15;
			}
			elsif ($_ =~ /\x82\xa6|\x82\xab|\x82\xac|\x82\xb2|\x82\xb4|\x82\xbf|\x82\xc0|\x82\xc4|\x82\xc5|\x82\xc7|\x82\xc8|\x82\xdc|\x82\xe1|\x82\xe3|\x82\xe6|\x82\xe9|\x82\xeb|\x82\xec|\x82\xf0|\x83\x41|\x83\x47|\x83\x53|\x83\x56|\x83\x57|\x83\x58|\x83\x5d|\x83\x63|\x83\x65|\x83\x72|\x83\x73|\x83\x75|\x83\x76|\x83\x7d|\x83\x82|\x83\x8c|\x83\x8d|\x83\x93/){
				$count += 14;
			}
			elsif ($_ =~ /\x82\x6e|\x82\x70|\x82\xa1|\x82\xa7|\x82\xae|\x82\xb1|\x82\xc1|\x82\xe0|\x82\xe7|\x83\x43|\x83\x48|\x83\x4a|\x83\x4e|\x83\x52|\x83\x5c|\x83\x6b|\x83\x74|\x83\x83|\x83\x85|\x83\x89|\x83\x92/){
				$count += 13;
			}
			elsif ($_ =~ /\x81\x52|\x81\x53|\x81\x54|\x82\x61|\x82\x62|\x82\x63|\x82\x66|\x82\x67|\x82\x6a|\x82\x6d|\x82\x71|\x82\x72|\x82\x74|\x82\x97|\x82\x9f|\x82\xa5|\x82\xb3|\x82\xb5|\x82\xb6|\x82\xc6|\x82\xe5|\x82\xe8|\x83\x40|\x83\x44|\x83\x46|\x83\x5e|\x83\x62|\x83\x71|\x83\x81|\x83\x88|\x83\x8a|\x83\x8e|\x83\x95|\x83\x96/){
				$count += 12;
			}
			elsif ($_ =~ /\x81\x41|\x81\x42|\x81\x43|\x81\x44|\x81\x55|\x82\x4f|\x82\x50|\x82\x51|\x82\x52|\x82\x53|\x82\x54|\x82\x55|\x82\x56|\x82\x57|\x82\x58|\x82\x60|\x82\x64|\x82\x6f|\x82\x75|\x82\xa4|\x83\x68|\x83\x6d|\x83\x7e|\x81\x40/){
				$count += 11;
			}
			elsif ($_ =~ /\x82\x65|\x82\x69|\x82\x6b|\x82\x73|\x82\x77|\x82\x78|\x82\x79|\x82\x82|\x82\x84|\x82\x88|\x82\x8b|\x82\x8e|\x82\x8f|\x82\x90|\x82\x91|\x82\x95|\x82\xa3|\x83\x42|\x83\x67|\x83\x87/){
				$count += 10;
			}
			elsif ($_ =~ /\x82\x81|\x82\x83|\x82\x85|\x82\x87|\x82\x93|\x82\xad/){
				$count +=  9;
			}
			elsif ($_ =~ /\x81\x45|\x81\x46|\x81\x47|\x81\x4a|\x81\x4b|\x81\x4c|\x81\x4d|\x81\x4e|\x81\x4f|\x81\x5d|\x81\x65|\x81\x66|\x81\x67|\x81\x68|\x81\x69|\x81\x6a|\x81\x6b|\x81\x6c|\x81\x6d|\x81\x6e|\x81\x6f|\x81\x70|\x81\x71|\x81\x72|\x81\x73|\x81\x74|\x81\x75|\x81\x76|\x81\x77|\x81\x78|\x81\x79|\x81\x7a|\x81\xf5|\x81\xf6|\x81\xf7|\x82\x96|\x82\x98|\x82\x99|\x82\x9a/){
				$count +=  8;
			}
			# There is no character of 7 dots.
			elsif ($_ =~ /\x82\x92/){
				$count +=  6;
			}
			elsif ($_ =~ /\x82\x86|\x82\x94/){
				$count +=  5;
			}
			elsif ($_ =~ /\x82\x68|\x82\x89|\x82\x8a|\x82\x8c/){
				$count +=  4;
			}
			# There is no character of 3 dots.
			else {
				$count += 16;
			}
		}
		#------------------- 1byte
		else {
			# There is no character of 15 dots.
			# There is no character of 14 dots.
			# There is no character of 13 dots.
			if    ($_ =~ /\x4d|\x57|\x6d/){
				$count += 12;
			}
			elsif ($_ =~ /\x40|\x43|\x47|\x4f|\x51|\xbb|\xd1|\xd4|\xd9/){
				$count += 11;
			}
			elsif ($_ =~ /\x26|\x41|\x42|\x44|\x48|\x4b|\x4e|\x50|\x52|\x53|\x55|\x56|\x58|\x77|\xb0|\xb1|\xb3|\xb4|\xb5|\xb7|\xb9|\xbd|\xbe|\xc1|\xc2|\xc3|\xc5|\xc6|\xc8|\xca|\xcd|\xce|\xcf|\xd3|\xd5/){
				$count += 10;
			}
			elsif ($_ =~ /\x45|\x46|\x4a|\x4c|\x54|\x59|\x5a|\xa6|\xb2|\xb6|\xb8|\xba|\xbc|\xbf|\xc0|\xc7|\xcc|\xd7|\xda|\xdb|\xdc|\xdd/){
				$count +=  9;
			}
			elsif ($_ =~ /\x61|\x62|\x63|\x64|\x65|\x68|\x6e|\x6f|\x70|\x71|\x75|\x76|\x79|\x22|\x23|\x24|\x25|\x2a|\x2b|\x2d|\x2f|\x30|\x31|\x32|\x33|\x34|\x35|\x36|\x37|\x38|\x39|\x3c|\x3d|\x3e|\x5c|\xa7|\xa9|\xaa|\xab|\xac|\xad|\xaf|\xc9|\xcb|\xd2|\xd6|\xd8/){
				$count +=  8;
			}
			elsif ($_ =~ /\x3f|\x5e|\x60|\x67|\x6b|\x73|\x78|\x7a|\x7e|\xa2|\xa3|\xa5|\xa8|\xae|\xc4|\xd0|\xa1|\xa4/){
				$count +=  7;
			}
			elsif ($_ =~ /\x72|\x74/){
				$count +=  6;
			}
			elsif ($_ =~ /\x28|\x29|\x5b|\x5d|\x5f|\x66|\x20/){
				$count +=  5;
			}
			elsif ($_ =~ /\x21|\x49|\x6a|\x7b|\x7c|\x7d|\xde|\xdf/){
				$count +=  4;
			}
			elsif ($_ =~ /\x27|\x2c|\x2e|\x3a|\x3b|\x69|\x6c/){
				$count +=  3;
			}
		}
	}

	return $count;
}
#-------------------------------------------------------------------------------
# The variable of the character string is resolved to the array of one character.
# $aart -> divide($str);
#-------------------------------------------------------------------------------
sub divide {
	my $self   = shift;
	my $str    = shift;

	return $self -> divide_euc($str)  if $code eq 'euc';
	return $self -> divide_sjis($str) if $code eq 'sjis';
}
# When you want to process it with EUC-JP disregarding the character-code declaration
# $aart -> divide_euc($str);
sub divide_euc {
	my $self = shift;
	my $str  = shift;

	my $esc        = '[\x00-\x1F]';
	my $oneBytes   = '[\x20-\x7E]';
	my $twoBytes1  = '\x8E[\xA1-\xDF]';
	my $twoBytes2  = '[\xA1-\xFE][\xA1-\xFE]';
	my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';

	$str =~ s/$esc//og;
	my @array = $str =~ /$oneBytes|$twoBytes1|$twoBytes2|$threeBytes/og;
	return @array;
}
# When you want to process it with Shift_JIS disregarding the character-code declaration
# $aart -> divide_sjis($str);
sub divide_sjis {
	my $self = shift;
	my $str  = shift;

	my $esc       = '[\x00-\x1F]';
	my $oneBytes  = '[\x20-\x7E\xA1-\xDF]';
	my $twoBytes1 = '[\x81-\x9F][\x40-\x7E]';
	my $twoBytes2 = '[\xE0-\xEF][\x80-\xFC]';

	$str =~ s/$esc//og;
	my @array;
	while($str) {
		$str =~ s/(.)//;
		my $tmp = $1;

		if ($tmp =~ /$oneBytes/og) {
			push @array , $tmp;
			next;
		}
		$str =~ s/(.)//;
		$tmp .= $1;
		push @array , $tmp;
	}

	return @array;
}
#-------------------------------------------------------------------------------
# The character string that adds the adjustment dot is returned.
# $aart -> adjust($str_l, $str_r, position, $size);
#-------------------------------------------------------------------------------
sub adjust {
	my $self     = shift;
	my $str_l    = shift || q{};
	my $str_r    = shift || q{};
	my $position = shift || 'L';
	my $size     = shift;

	return $self -> adjust_right_euc($str_l, $str_r, $size) if $code eq 'euc' && $position eq 'R';
	return $self -> adjust_left_euc($str_l, $str_r, $size)  if $code eq 'euc' && $position eq 'L';
	return $self -> adjust_right_sjis($str_l, $str_r, $size) if $code eq 'sjis' && $position eq 'R';
	return $self -> adjust_left_sjis($str_l, $str_r, $size)  if $code eq 'sjis' && $position eq 'L';
}
# When you want to process it with EUC-JP disregarding the character-code declaration and position 'R'.
# $aart -> adjust_right_euc($str_l, $str_r, $size);
sub adjust_right_euc {
	my $self  = shift;
	my $str_l = shift || q{};
	my $str_r = shift || q{};
	my $size  = shift;
	my $count = $self -> calcu_euc("$str_l$str_r");

	my $diff = $size - $count;
	my $space = int( $diff/11 );

	my $set2 = q{};
	for (my $t = 0; $t < $space; $t ++) {
		$diff -= 11;
		$set2 .= "\xa1\xa1";
	}

	if ($diff == 1) {
		if ($set2 =~ s/\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1$/ \xa1\xa1 \xa1\xa1 \xa1\xa1 \./) {}
		else { $set2 =~ s/\xa1\xa1$/\.\.\.\./; }
	}
	if ($diff == 2) { $set2 =~ s/\xa1\xa1\xa1\xa1$/ \xa1\xa1 \./ }
	if ($diff == 3) { $set2 .= '.' }
	if ($diff == 4) {
		if ($set2 =~ s/\xa1\xa1\xa1\xa1\xa1\xa1$/ \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 =~ s/\xa1\xa1$/\.\.\.\.\./; }
	}
	if ($diff == 5) { $set2 .= ' ' }
	if ($diff == 6) {
		if ($set2 =~ s/\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1$/ \xa1\xa1 \xa1\xa1 \xa1\xa1 \. /) {}
		else { $set2 .= '..' }
	}
	if ($diff == 7) { $set2 =~ s/\xa1\xa1\xa1\xa1\xa1\xa1$/ \xa1\xa1 \xa1\xa1 \./ }
	if ($diff == 8) { $set2 .= ' .' }
	if ($diff == 9) {
		if ($set2 =~ s/\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1$/ \xa1\xa1 \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 .= '...' }
	}
	if ($diff == 10) { $set2 =~ s/\xa1\xa1\xa1\xa1$/\xa1\xa1 \xa1\xa1 / }

	return "$str_l$set2$str_r";
}
# When you want to process it with EUC-JP disregarding the character-code declaration and position 'L'.
# $aart -> adjust_left_euc($str_l, $str_r, $size);
sub adjust_left_euc {
	my $self   = shift;
	my $str_l  = join q{}, $self -> divide_euc(shift);
	my $str_r  = join q{}, $self -> divide_euc(shift);
	my $size   = shift;

	my $count = $self -> calcu_euc("$str_l$str_r");
	my $diff = $size - $count;
	my $space = int( $diff/11 );

	my $set2 = q{};
	for (my $t = 0; $t < $space; $t ++) {
		$diff -= 11;
		$set2 .= "\xa1\xa1";
	}
	if ($diff == 1) {
		if ($set2 =~ s/^\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1/\. \xa1\xa1 \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 =~ s/^\xa1\xa1/\.\.\.\./; }
	}
	if ($diff == 2) { $set2 =~ s/^\xa1\xa1\xa1\xa1/\. \xa1\xa1 / }
	if ($diff == 3) { $set2 = '.'.$set2 }
	if ($diff == 4) {
		if ($set2 =~ s/^\xa1\xa1\xa1\xa1\xa1\xa1/ \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 =~ s/^\xa1\xa1/\.\.\.\.\./ }
	}
	if ($diff == 5) { $set2 = ' '.$set2 }
	if ($diff == 6) {
		if ($set2 =~ s/^\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1/ \. \xa1\xa1 \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 = '..'.$set2 }
	}
	if ($diff == 7) { $set2 =~ s/^\xa1\xa1\xa1\xa1\xa1\xa1/\. \xa1\xa1 \xa1\xa1 / }
	if ($diff == 8) { $set2 = '. '.$set2 }
	if ($diff == 9) {
		if ($set2 =~ s/^\xa1\xa1\xa1\xa1\xa1\xa1\xa1\xa1/ \xa1\xa1 \xa1\xa1 \xa1\xa1 /) {}
		else { $set2 = '...'.$set2 }
	}
	if ($diff == 10) { $set2 =~ s/^\xa1\xa1\xa1\xa1/\xa1\xa1 \xa1\xa1 / }

	return "$str_l$set2$str_r";
}
# When you want to process it with Shift_JIS disregarding the character-code declaration and position 'R'.
# $aart -> adjust_right_sjis($str_l, $str_r, $size);
sub adjust_right_sjis {
	my $self  = shift;
	my $str_l = shift || q{};
	my $str_r = shift || q{};
	my $size  = shift;
	my $count = $self -> calcu_sjis("$str_l$str_r");

	my $diff = $size - $count;
	my $space = int( $diff/11 );

	my $set2 = q{};
	for (my $t = 0; $t < $space; $t ++) {
		$diff -= 11;
		$set2 .= "\x81\x40";
	}

	if ($diff == 1) {
		if ($set2 =~ s/\x81\x40\x81\x40\x81\x40\x81\x40\x81\x40$/ \x81\x40 \x81\x40 \x81\x40 \./) {}
		else { $set2 =~ s/\x81\x40$/\.\.\.\./; }
	}
	if ($diff == 2) { $set2 =~ s/\x81\x40\x81\x40$/ \x81\x40 \./ }
	if ($diff == 3) { $set2 .= '.' }
	if ($diff == 4) {
		if ($set2 =~ s/\x81\x40\x81\x40\x81\x40$/ \x81\x40 \x81\x40 /) {}
		else { $set2 =~ s/\x81\x40$/\.\.\.\.\./; }
	}
	if ($diff == 5) { $set2 .= ' ' }
	if ($diff == 6) {
		if ($set2 =~ s/\x81\x40\x81\x40\x81\x40\x81\x40\x81\x40$/ \x81\x40 \x81\x40 \x81\x40 \. /) {}
		else { $set2 .= '..' }
	}
	if ($diff == 7) { $set2 =~ s/\x81\x40\x81\x40\x81\x40$/ \x81\x40 \x81\x40 \./ }
	if ($diff == 8) { $set2 .= ' .' }
	if ($diff == 9) {
		if ($set2 =~ s/\x81\x40\x81\x40\x81\x40\x81\x40$/ \x81\x40 \x81\x40 \x81\x40 /) {}
		else { $set2 .= '...' }
	}
	if ($diff == 10) { $set2 =~ s/\x81\x40\x81\x40$/\x81\x40 \x81\x40 / }

	return "$str_l$set2$str_r";
}
# When you want to process it with Shift_JIS disregarding the character-code declaration and position 'L'.
# $aart -> adjust_left_sjis($str_l, $str_r, $size);
sub adjust_left_sjis {
	my $self   = shift;
	my $str_l  = shift || q{};
	my $str_r  = shift || q{};
	my $size   = shift;

	my $count = $self -> calcu_sjis("$str_l$str_r");
	my $diff = $size - $count;
	my $space = int( $diff/11 );

	my $set2 = q{};
	for (my $t = 0; $t < $space; $t ++) {
		$diff -= 11;
		$set2 .= "\x81\x40";
	}
	if ($diff == 1) {
		if ($set2 =~ s/^\x81\x40\x81\x40\x81\x40\x81\x40\x81\x40/\. \x81\x40 \x81\x40 \x81\x40 /) {}
		else { $set2 =~ s/^\x81\x40/\.\.\.\./; }
	}
	if ($diff == 2) { $set2 =~ s/^\x81\x40\x81\x40/\. \x81\x40 / }
	if ($diff == 3) { $set2 = '.'.$set2 }
	if ($diff == 4) {
		if ($set2 =~ s/^\x81\x40\x81\x40\x81\x40/ \x81\x40 \x81\x40 /) {}
		else { $set2 =~ s/^\x81\x40/\.\.\.\.\./ }
	}
	if ($diff == 5) { $set2 = ' '.$set2 }
	if ($diff == 6) {
		if ($set2 =~ s/^\x81\x40\x81\x40\x81\x40\x81\x40\x81\x40/ \. \x81\x40 \x81\x40 \x81\x40 /) {}
		else { $set2 = '..'.$set2 }
	}
	if ($diff == 7) { $set2 =~ s/^\x81\x40\x81\x40\x81\x40/\. \x81\x40 \x81\x40 / }
	if ($diff == 8) { $set2 = '. '.$set2 }
	if ($diff == 9) {
		if ($set2 =~ s/^\x81\x40\x81\x40\x81\x40\x81\x40/ \x81\x40 \x81\x40 \x81\x40 /) {}
		else { $set2 = '...'.$set2 }
	}
	if ($diff == 10) { $set2 =~ s/^\x81\x40\x81\x40/\x81\x40 \x81\x40 / }

	return "$str_l$set2$str_r";
}
#-------------------------------------------------------------------------------
# The number of shorter dots where the character string of the array becomes complete is returned.
# $aart -> shorter(@array);
#-------------------------------------------------------------------------------
sub shorter {
	my $self   = shift;
	my @array  = @_;

	return $self -> shorter_euc(@array)  if $code eq 'euc';
	return $self -> shorter_sjis(@array) if $code eq 'sjis';
}
# When you want to process it with EUC-JP disregarding the character-code declaration.
# $aart -> shorter_euc(@array);
sub shorter_euc {
	my $self  = shift;
	my @array = @_;
	my $fit   = 0;

	foreach my $buf (@array) {
		my $set = $self -> calcu_euc($buf);
		next if $fit >= $set;
		$fit = $set;
	}

	while (1) {
		my $flag = 0;
		foreach my $set (@array) {
			my $temp = $self -> adjust_right_euc($set,q{},$fit);
			my $temp2 = $self -> calcu_euc($temp);
			next if $fit == $temp2;
			$flag = 1;
			$fit ++;
			last;
		}
		last unless $flag;
	}

	return $fit;
}
# When you want to process it with Shift_JIS disregarding the character-code declaration.
# $aart -> shorter_sjis(@array);
sub shorter_sjis {
	my $self  = shift;
	my @array = @_;
	my $fit   = 0;

	foreach my $buf (@array) {
		my $set = $self -> calcu_sjis($buf);
		next if $fit >= $set;
		$fit = $set;
	}

	while (1) {
		my $flag = 0;
		foreach my $set (@array) {
			my $temp = $self -> adjust_right_sjis($set,q{},$fit);
			my $temp2 = $self -> calcu_sjis($temp);
			next if $fit == $temp2;
			$flag = 1;
			$fit ++;
			last;
		}
		last unless $flag;
	}

	return $fit;
}
#-------------------------------------------------------------------------------
# The number of shorter dots that hits multiples of the number specified that
# the character string of the array becomes complete is returned.
# ($minimun, $magnification) = $aart -> shorter_multiple($width, \@arrayL, \@arrayR);
#-------------------------------------------------------------------------------
sub shorter_multiple {
	my $self   = shift;
	my ($number, $left, $right) = @_;
	my @arrayL = @$left;
	my @arrayR = @$right;

	return $self -> shorter_multiple_euc($number, \@$left, \@$right)  if $code eq 'euc';
	return $self -> shorter_multiple_sjis($number, \@$left, \@$right) if $code eq 'sjis';
}
# When you want to process it with EUC-JP disregarding the character-code declaration.
# ($minimun, $magnification) = $aart -> shorter_multiple_euc($width, \@arrayL, \@arrayR);
sub shorter_multiple_euc() {
	my $self  = shift;
	my ($number, $left, $right) = @_;
	my @arrayL = @$left;
	my @arrayR = @$right;

	my $width = $self -> shorter_euc(@arrayL) + $self -> shorter_euc(@arrayR);
	my $multiple = $width / $number;
	my $shorter = ( $multiple - int($multiple) ) ? $number * ( int($multiple) + 1) : $number * $multiple;

	while (1) {
		my $flag = 0;
		for (my $i = 0; $i < @arrayL; $i ++) {
			my $temp = $self -> adjust_right_euc($arrayL[$i], $arrayR[$i], $shorter);
			my $temp2 = $self -> calcu_euc( $temp );
			next if $shorter == $temp2;
			$shorter += $number;
			$flag = 1;
			last;
		}
		last unless $flag;
	}

	return $shorter, $shorter / $number;
}
# When you want to process it with Shift_JIS disregarding the character-code declaration.
# ($minimun, $magnification) = $aart -> shorter_multiple_sjis($width, \@arrayL, \@arrayR);
sub shorter_multiple_sjis() {
	my $self  = shift;
	my ($number, $left, $right) = @_;
	my @arrayL = @$left;
	my @arrayR = @$right;

	my $width = $self -> shorter_sjis(@arrayL) + $self -> shorter_sjis(@arrayR);
	my $multiple = $width / $number;
	my $shorter = ( $multiple - int($multiple) ) ? $number * ( int($multiple) + 1) : $number * $multiple;

	while (1) {
		my $flag = 0;
		for (my $i = 0; $i < @arrayL; $i ++) {
			my $temp = $self -> adjust_right_sjis($arrayL[$i], $arrayR[$i], $shorter);
			my $temp2 = $self -> calcu_sjis( $temp );
			next if $shorter == $temp2;
			$shorter += $number;
			$flag = 1;
			last;
		}
		last unless $flag;
	}

	return $shorter, $shorter / $number;
}

1;
__END__

=head1 NAME

HTML::AA - The function to undergo plastic operation on the
character string displayed in a browser is possessed though it
is a MS P Gothic font of 12 points

=head1 SYNOPSIS

  use HTML::AA;

  my $aart = new HTML::AA;
  $aart -> code('euc');
  my $dot;
  my $str = 'Character string';
  my @str = ('Character string','Length adjustment');

  print  "Content-type: text/html; charset=EUC-JP\n\n";
  print  "<body>\n";
  print  "HTML::AA Sample of usage<br>\n";

  $dot = $aart -> calcu($str);
  printf "Number of dots of [%s] %d<br>\n", $str, $dot;

  printf "|%s|<br>\n", $aart -> adjust($str, q{}, 'R', 350);
  printf "|%s|<br>\n", $aart -> adjust($str, q{}, 'L', 350);
  printf "|%s|<br>\n", $aart -> adjust(q{}, $str, 'R', 350);
  printf "|%s|<br>\n", $aart -> adjust(q{}, $str, 'L', 350);
  printf "|%s|<br>\n", $aart -> adjust($str, $str, 'R', 350);
  printf "|%s|<br>\n", $aart -> adjust($str, $str, 'L', 350);

  $dot = $aart -> shorter(@str);
  printf "|%s|<br>\n", $aart -> adjust($_, q{}, 'R', $dot) foreach @str;
  printf "|%s|<br>\n", $aart -> adjust($_, q{}, 'L', $dot) foreach @str;
  printf "|%s|<br>\n", $aart -> adjust(q{}, $_, 'R', $dot) foreach @str;
  printf "|%s|<br>\n", $aart -> adjust(q{}, $_, 'L', $dot) foreach @str;

  print  "</body>\n";

=head1 DESCRIPTION

  HTML::AA Sample of usage
  Number of dots of [Character string] 111
  |Character string@@@@@@@@@@@@@@@@@@@@@. |
  |Character string. @@@@@@@@@@@@@@@@@@@@@|
  |@@@@@@@@@@@@@@@@@@@@@. Character string|
  |. @@@@@@@@@@@@@@@@@@@@@Character string|
  |Character string@@@@@@@@ @ @ .Character string|
  |Character string. @ @ @@@@@@@@Character string|
  |Character string.....|
  |Length adjustment|
  |Character string.....|
  |Length adjustment|
  |.....Character string|
  |Length adjustment|
  |.....Character string|
  |Length adjustment|

  Please replace "@" with \xa1\xa1 of EUC-JP.

  The explanation of Japanese is here. 
  http://penlabo.oh.land.to/HTML-AA.html

=head2 EXPORT

None by default.

=head1 SEE ALSO

I think finding when "ASCII art" is retrieved in Japanese.

=head1 AUTHOR

satoshi ishikawa E<lt>penguin5@u01.gate01.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2006 satoshi ishikawa
  and
  Companions of lounge thread of bulletin board of "2 channel"
  The explanation of "2 channnel" is here.
  http://2ch.net/

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
