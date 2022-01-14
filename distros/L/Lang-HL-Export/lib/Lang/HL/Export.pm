package Lang::HL::Export;

use strict;
use warnings;
use utf8;
use feature qw(signatures);
no warnings "experimental::signatures";
no warnings "experimental::smartmatch";
use Hash::Merge;

require Exporter;

our $VERSION = '0.10';

our @ISA = qw(Exporter);
our @EXPORT = qw(
	arrayElement
	arrayLength
	arrayMerge
	arraySort
	arrayPop
	arrayPush
	arrayShift
	arrayUnshift
	arraySort
	arrayJoin
	arrayReverse
	arrayDelete
	hashElement
	hashKeys
	hashMerge
	hashDelete
	stringConcat
	stringSplit
	stringLength
	stringPart
	stringLast
	stringChop
	stringChomp
	readFile
	writeFile
	randomNumber
	makeInt
);


sub arrayDelete($array, $element) {
	delete($array->[$element]);
}

sub hashDelete($hash, $element) {
	delete($hash->{$element});
}

sub stringChop($string) {
	return chop($string);
}

sub stringChomp($string) {
	return chomp($string);
}

sub arrayReverse($array) {
	my @reversedArray = reverse(@{$array});
	return \@reversedArray;
}

sub arrayJoin($separator, $array) {
	my @array = @{$array};
	return join($separator, $array);
}

sub arraySort($array) {
	my @array = @{$array};
	my @sortedArray = sort(@array);
	return \@sortedArray;
}

sub arrayUnshift($array, $element) {
	# Places the element at the beginning of an array,
	# shifting all the values to the right
	unshift(@{$array}, $element)
}

sub arrayShift($array) {
	# Shifts the first value of the array off and returns it,
	# shortening the array by 1 and moving everything down.
	return shift(@{$array});
}

sub arrayPush($array, $element) {
	push(@{$array}, $element);
}

sub arrayPop($array) {
	# Pops and returns the last value of the array,
	# shortening the array by one element.
	return pop(@{$array});
}

sub makeInt($number) {
	return int $number;
}

sub randomNumber($number) {
	return rand($number);
}

sub stringConcat($textOne, $textTwo) {
	return $textOne . $textTwo;
}

sub stringSplit($separator, $text) {
    my @split = split($separator, $text);
    return \@split;
}

sub stringLength($text) {
	return length($text);
}

sub stringPart($text, $from, $to) {
	return substr($text, $from, $to);
}

sub stringLast($text) {
	return substr($text, -1);
}

sub arrayElement($array, $element) {
	if( $element ~~ $array ) {
		return 1;
	} else {
		return 0;
	}
}

sub arrayLength($array) {
    my @newArray = @{$array};
    return $#newArray;
}

sub arrayMerge($arrayOne, $arrayTwo) {
	my @newArray = ( @{$arrayOne}, @{$arrayTwo} );
	return \@newArray;
}

sub hashElement($hash, $element) {
	my %hashMap  = %{$hash};
	if( exists $hashMap{$element} ) {
		return 1;
	} else {
		return 0;
	}
}

sub hashKeys($hash) {
    my @keys = keys(%{$hash});
    return \@keys;
}

sub hashMerge($hashOne, $hashTwo) {
	my $mergedHash = merge($hashOne, $hashTwo);
	return $mergedHash;
}

sub readFile($fileName) {
    my $fileContent;
    open(my $fh, '<:encoding(UTF-8)', $fileName) or die "Cannot open the $fileName file";
	{
        local $/;
        $fileContent = <$fh>;
    }
    close($fh);
    return $fileContent;
}

sub writeFile($fileName, $fileContent) {
    open(my $fh, '>:encoding(UTF-8)', $fileName) or die "Cannot open the $fileName file";
    print $fh $fileContent;
    close($fh);
}

1;
__END__

=head1 NAME

Lang::HL::Export

=head1 AUTHOR

Rajkumar Reddy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

=cut
