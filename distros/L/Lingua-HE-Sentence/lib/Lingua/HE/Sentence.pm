package Lingua::HE::Sentence;

#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

Lingua::HE::Sentence - Module for splitting Hebrew text into sentences.

=head1 SYNOPSIS

	use Lingua::HE::Sentence qw( get_sentences );

	my $sentences=get_sentences($text);	## Get the sentences.
	foreach my $sentence (@$sentences) {
		## do something with $sentence
	}


=head1 DESCRIPTION

The C<Lingua::HE::Sentence> module contains the function get_sentences, which splits Hebrew text into its constituent sentences, based on regular expressions.

The module assumes text encoded in UTF-8. Supporting other input formats will be added upon request.

=head1 HEBREW DETAILS

Language:               Hebrew
Language ID:            he
MS Locale ID:           1037
ISO 639-1:              he
ISO 639-2 (MARC):       heb
ISO 8859 (charset):     8859-8
ANSI codepage:          1255
Unicode:                0590-05FF

=head1 PROBLEM DESCRIPTION

Many applications in natural language processing require some knowledge of sentence boundaries. The problem of properly locating sentence bonudaries in text in Hebrew is in many ways less severe than the same problem in other languages. The purpose of this module is to supply Perl users with a tool which can take plain text in Hebrew and get an ordered list of the sentences in the text.

=head1 PROPERTIES OF HEBREW SENTENCES

The following facts are part of the guidelines given by the 'academy of the Hebrew language'.

Sentences usually end with one of the following punctuation symbols:
	.	a dot
	?	a question mark
	!	an exclamation mark

No dot should be placed after sentences on titles (such as book names, chpter titles etc.)

A dot can be placed after letters and numbers used for listing items, chapters etc., as long as these letters or numbers are not placed on a special line. When these letters or numbers appear alone, no dot should succeed them. Brackets or a closing bracket can be used instead of a dot in this case.

Decimal point should be represented with a dot and not a comma in order to distinguish the number from its decimal fraction.

In some rare cases semicolons also represent end of sentence, but usually the sentences separated by sa semicolor are practically one long sentence. I chose not to split on semicolons at all.


=head1 ASSUMPTIONS

Input text is assumed to be represented in UTF-8

Input text is assumed to have some structure, i.e. titles are separated from the rest of the text with at least a couple of newline characters ('\n').

Input is expected to follow the PROPERTIES listed above.

Complex sentences should be further segmented using clause identificatoin algorithms, this module will not provide (at least in this version) any support for clause identification and segmentation.

=head1 FUNCTIONS

All functions used should be requested in the 'use' clause. None is exported by default.

=item get_sentences( $text )

The get sentences function takes a scalar containing ascii text as an argument and returns a reference to an array of sentences that the text has been split into.
Returned sentences will be trimmed (beginning and end of sentence) of white-spaces.
Strings with no alpha-numeric characters in them, won't be returned as sentences.

=item get_EOS(	)

This function returns the value of the string used to mark the end of sentence. You might want to see what it is, and to make sure your text doesn't contain it. You can use set_EOS() to alter the end-of-sentence string to whatever you desire.

=item set_EOS( $new_EOS_string )

This function alters the end-of-sentence string used to mark the end of sentences. 

=head1 BUGS

No proper handling of sentence boundaries within and in presence of quotes (either single or dounle). Please report bugs at http://rt.cpan.org/ and CC the author (see details below).

=head1 FUTURE WORK (in no particular order)

=item [0] Write tests!

=item [1] Object Oriented like usage.

=item [2] Supporting more encodings/charsets.

=item [3] Code cleanup and optimization.

=item [4] Fix bugs.

=item [5] Generate sentencizer based on supervised learning. (requires tagged texts...)

=head1 SEE ALSO

	Lingua::EN::Sentence

=head1 AUTHOR

Shlomo Yona shlomo@cs.haifa.ac.il

=head1 COPYRIGHT

Copyright (c) 2001-2005 Shlomo Yona. All rights reserved.

=head1 LICENSE

This library is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.  

=cut

#==============================================================================
#
# End of POD
#
#==============================================================================


#==============================================================================
#
# Pragmas
#
#==============================================================================

use 5.008_004; # due to utf8 support
use warnings;
use strict;
#==============================================================================
#
# Modules
#
#==============================================================================
require Exporter;

#==============================================================================
#
# Public globals
#
#==============================================================================
use Carp qw/cluck/;
use utf8;

our $VERSION = '0.13';

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( get_sentences get_EOS set_EOS);

our $EOS="\001";

#==============================================================================
#
# Public methods
#
#==============================================================================

#------------------------------------------------------------------------------
# get_sentences - takes text input and splits it into sentences.
# A regular expression cuts viciously the text into sentences, 
# and then a list of rules (some of them consist of a list of abbreviations)
# is applied on the marked text in order to fix end-of-sentence markings on 
# places which are not indeed end-of-sentence.
#------------------------------------------------------------------------------
sub get_sentences {
	my ($text)=@_;
	return [] unless defined $text;

	my $marked_text = sentence_breaking($text);
	my @sentences = split(/$EOS/,$marked_text);
	my $cleaned_sentences = clean_sentences(\@sentences);
	return $cleaned_sentences;
}

#------------------------------------------------------------------------------
# get_EOS - get the value of the $EOS (end-of-sentence mark).
#------------------------------------------------------------------------------
sub get_EOS {
	return $EOS;
}

#------------------------------------------------------------------------------
# set_EOS - set the value of the $EOS (end-of-sentence mark).
#------------------------------------------------------------------------------
sub set_EOS {
	my ($new_EOS) = @_;
	if (not defined $new_EOS) {
		cluck "Won't set \$EOS to undefined value!\n";
		return $EOS;
	}
	return $EOS = $new_EOS;
}

#==============================================================================
#
# Private methods
#
#==============================================================================

sub clean_sentences {
	my ($sentences) = @_;
		my $cleaned_sentences = [];
		foreach my $s (@$sentences) {
			next if not defined $s;
			next if $s=~m/^\s*$/;
			$s=~s/^\s*//;
			$s=~s/\s*$//;
			push @$cleaned_sentences,$s;
		}
	return $cleaned_sentences;
}

sub sentence_breaking {
	my ($text) = @_;
	## double new-line means a different sentence.
	$text=~s/\n\s*\n/$EOS/gs;
	## break by end-of-sentence just before closing quotes/punct. and opening quotes/punct.
	$text=~s/(\p{IsEndOfSentenceCharacter}+(['"\p{ClosePunctuation}])?\s+)/$1$EOS/gs;
	$text=~s/(['"\p{ClosePunctuation}]\s*\p{IsEndOfSentenceCharacter}+\s+)/$1$EOS/gs;

	# breake also when single letter comes before punc.
	$text=~s/(\s\w\p{IsEndOfSentenceCharacter}\s+)/$1$EOS/gs; 

	## unbreak a series of alphanum/end-of-sentence within punctuation before an EOS
	$text=~s/(\p{Punctuation}[\w\p{IsEndOfSentenceCharacter}]['"\p{ClosePunctuation}]\s*)$EOS/$1/gs; 
	## re-break stuff
	$text=~s/(\p{IsEndOfSentenceCharacter}+['"\p{ClosePunctuation}]?\s+)(?!$EOS)/$1$EOS/gs;


	## unbreak stuff like: VAV-(!)
	$text=~s/$EOS(\s*(?:\x{05D5}-?(?:\w|\s)*)?['"\p{OpenPunctuation}]\s*\p{IsEndOfSentenceCharacter}+['"\p{ClosePunctuation}]\s*)/$1/gs;
	## unbreak stuff like: '?!'
	$text=~s/(['"\p{OpenPunctuation}]\s*\p{IsEndOfSentenceCharacter}+['"\p{ClosePunctuation}]\s*)$EOS/$1/gs;
	## unbreak stuff like: 'i.b.m.' followed by text
	$text=~s/(\p{IsEndOfSentenceCharacter}\w+\p{IsEndOfSentenceCharacter}\p{Punctuation}*\s*)$EOS/$1/gs;

	return $text;
}

# End of Sentence characters
# 21 !
# 2E .
# 3F ?
sub IsEndOfSentenceCharacter {
	return <<'END';
21
2E
3F
END
}

#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
