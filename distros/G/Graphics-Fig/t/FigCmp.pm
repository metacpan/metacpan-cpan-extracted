#
# XFig Drawing Library
#
# Copyright (c) 2017 D Scott Guthridge <scott_guthridge@rompromity.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the Artistic License as published by the Perl Foundation, either
# version 2.0 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the Artistic License for more details.
# 
# You should have received a copy of the Artistic License along with this
# program.  If not, see <http://www.perlfoundation.org/artistic_license_2_0>.
#
#
# Compare two .fig files.
#
use 5.014;
package FigCmp;
use strict;
use warnings;

#
# figCompare: compare two fig files - return true if same
#
sub figCmp {
    my $filename1 = shift;
    my $filename2 = shift;
    my $line1 = "";
    my $line2 = "";
    my $result = undef;

    #
    # Open the input files.
    #
    open(my $fh1, "<", $filename1) || die "${filename1}: $!";
    open(my $fh2, "<", $filename2) || die "${filename2}: $!";

    #
    # Read the next word from each file and compare.
    #
    for (;;) {
	my $word1 = &getWord(\$line1, $fh1);
	my $word2 = &getWord(\$line2, $fh2);

	#
	# Handle EOF
	#
	if (!defined($word1) || !defined($word2)) {
	    if (defined($word1) || defined($word2)) {
		last;
	    }
	    $result = 1;
	    last;
	}

	#
	# If both words are numeric, use an approximate numeric compare.
	# Otherwise, use string compare.
	#
	if ($word1 =~ m/^[-+0-9.eE]+$/ && $word2 =~ m/^[-+0-9.eE]+$/) {
	    if (abs($word1 - $word2) > .001) {
		last;
	    }
	} elsif ($word1 ne $word2) {
	    last;
	}
    }
    close $fh1;
    close $fh2;

    return $result;
}

#
# getWord: read the next word from the given file
#   @line: reference to current line (caller must initialize to ""
#   	   before first call)
#   @fh:   reference to file handle
#
sub getWord {
    my $line = shift;
    my $fh   = shift;

    if (!defined($line)) {
	return undef;
    }
    for (;;) {
	if ($$line =~ s/^\s*([^\s]+)//) {
	    return $1;
	}
	if (!defined($$line = <$fh>)) {
	    return undef;
	}
	chop($$line);
    }
}

1;
