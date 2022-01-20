package Lang::HL::Export;

use strict;
no warnings;
use utf8;
use feature qw(signatures);
no warnings "experimental::signatures";
no warnings "experimental::smartmatch";
use Hash::Merge;

require Exporter;

our $VERSION = '0.16';

our @ISA = qw(Exporter);
our @EXPORT = qw(
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
	hashKeys
	hashElement
	hashMerge
	hashDelete
	stringConcat
	stringSplit
	stringLength
	stringPart
	stringLast
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
	unshift(@{$array}, $element);
}

sub arrayShift($array) {
	return shift(@{$array});
}

sub arrayPush($array, $element) {
	push(@{$array}, $element);
}

sub arrayPop($array) {
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

Open Source.


=cut
