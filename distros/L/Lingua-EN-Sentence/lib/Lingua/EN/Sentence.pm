package Lingua::EN::Sentence;

#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

Lingua::EN::Sentence - split text into sentences

=head1 SYNOPSIS

	use Lingua::EN::Sentence qw( get_sentences add_acronyms );
	
	add_acronyms('lt','gen');		## adding support for 'Lt. Gen.'
	my $text = q{
	A sentence usually ends with a dot, exclamation or question mark optionally followed by a space!
	A string followed by 2 carriage returns denotes a sentence, even though it doesn't end in a dot
	
	Dots after single letters such as U.S.A. or in numbers like -12.34 will not cause a split
	as well as common abbreviations such as Dr. I. Smith, Ms. A.B. Jones, Apr. Calif. Esq.
	and (some text) ellipsis such as ... or . . are ignored.
	Some valid cases canot be deteected, such as the answer is X. It cannot easily be
	differentiated from the single letter-dot sequence to abbreviate a person's given name.
	Numbered points within a sentence will not cause a split 1. Like this one.
	See the code for all the rules that apply.
	This string has 7 sentences.
	};
	
	my $sentences=get_sentences($text);	# Get the sentences.
	foreach my $sent (@$sentences)
	{
		$i++;
		print("SENTENCE $i:$sent\n");
	}


=head1 DESCRIPTION

The C<Lingua::EN::Sentence> module contains the function get_sentences, which
splits text into its constituent sentences, based on a regular expression and a
list of abbreviations (built in and given).

Certain well know exceptions, such as abbreviations, may cause incorrect
segmentations. But some of them are already integrated into this code and are
being taken care of. Still, if you see that there are words causing the
get_sentences function to fail, you can add those to the module, so it notices them.
Note that abbreviations are case sensitive, so 'Mrs.' is recognised but not 'mrs.'

=head1 ALGORITHM

The first step is to mark  the dot ending an abbreviation by changing it to a special
character. Now it won't cause a sentence split. The original dot is restored after
the sentences are split

Basically, I use a 'brute' regular expression to split the text into sentences.
(Well, nothing is yet split - I just mark the end-of-sentence). Then I look into
a set of rules which decide when an end-of-sentence is justified and when it's a
mistake. In case of a mistake, the end-of-sentence mark is removed. What are
such mistakes?

Letter-dot sequences:  U.S.A. ,  i.e. , e.g.
Dot sequences: '..' or '...'  or 'text . . more text'
Two carriage returns denote the end of a sentence even if it doesn't end with a dot

=head1 LIMITATIONS

1) John F. Kennedy was a former president
2) The answer is F. That ends the quiz

In the first sentence, F. is detected as a persons initial and not the end of a sentence.
But this means we cannot detect the true end of sentence 2, which is after the 'F'. This
case is not common though.

=head1 FUNCTIONS

All functions used should be requested in the 'use' clause. None is exported by
default.

=over 4

=item get_sentences( $text )

The get_sentences function takes a scalar containing ascii text as an argument
and returns a reference to an array of sentences that the text has been split
into. Returned sentences will be trimmed (beginning and end of sentence) of
white space. Strings with no alpha-numeric characters in them, won't be
returned as sentences.

=item add_acronyms( @acronyms )

This function is used for adding acronyms not supported by this code.
The input should be regular expressions for matching the desired acronyms,
but should not include the final period (C<.>). So, for example, C<blv?d>
matches C<blvd.> and C<bld.>. C<a\.mlf> will match C<a.mlf.>. You do not
need to bother with acronyms consisting of single letters and dots
(e.g. "U.S.A."), as these are found automatically. Note also that acronyms
are searched for on a case insensitive basis.

Please see 'Acronym/Abbreviations list' section for the abbreviations already
supported by this module.

=item get_acronyms( )

This function will return the defined list of acronyms.

=item set_acronyms( @my_acronyms )

This function replaces the predefined acronym list with the given list. See
L</add_acronyms> for details on the input specifications.


=item get_EOS( )

This function returns the value of the string used to mark the end of sentence.
You might want to see what it is, and to make sure your text doesn't contain it.
You can use set_EOS() to alter the end-of-sentence string to whatever you
desire.

=item set_EOS( $new_EOS_string )

This function alters the end-of-sentence string used to mark the end of sentences. 

=item set_locale( $new_locale )
Receives language locale in the form language.country.character-set
for example:
	"fr_CA.ISO8859-1"
for Canadian French using character set ISO8859-1.

Returns a reference to a hash containing the current locale formatting values.
Returns undef if got undef.


The following will set the LC_COLLATE behaviour to Argentinian Spanish.
NOTE: The naming and availability of locales depends on your operating sysem.
Please consult the perllocale manpage for how to find out which locales are available in your system.

$loc = set_locale( "es_AR.ISO8859-1" );

This actually does this:

$loc = setlocale( LC_ALL, "es_AR.ISO8859-1" );

=back

=head1 Acronym/Abbreviations list

You can use the get_acronyms() function to get acronyms.
It has become too long to specify in the documentation.

If I come across a good general-purpose list - I'll incorporate it into this module.
Feel free to suggest such lists. 

=head1 FUTURE WORK

	[1] Object Oriented like usage
	[2] Supporting more than just English/French
	[3] Code optimization. Currently everything is RE based and not so optimized RE
	[4] Possibly use more semantic heuristics for detecting a beginning of a sentence

=head1 SEE ALSO

	Text::Sentence
	Lingua::Sentence
	Raku port of Lingua::EN::Sentence
	
=head1 REPOSITORY

L<https://github.com/kimryan/Lingua-EN-Sentence>	

=head1 AUTHOR

Shlomo Yona shlomo@cs.haifa.ac.il

Currently being maintained by Kim Ryan, kimryan at CPAN d o t org


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2001-2016 Shlomo Yona. All rights reserved.
Copyright (c) 2022 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

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

use strict;
use warnings;
use POSIX qw(locale_h setlocale);
#==============================================================================
#
# Modules
#
#==============================================================================
use Exporter;

#==============================================================================
#
# Public globals
#
#==============================================================================
use vars qw/$VERSION @ISA @EXPORT_OK $EOS $LOC $AP $P $PAP @ABBREVIATIONS/;
use Carp qw/cluck/;
use English;

our $VERSION = '0.33';

our $LOC;
if ($OSNAME ne 'android') {
	# Call POSIX function
	$LOC=  setlocale(LC_CTYPE, "en_US.UTF-8");
}

 
use locale;

@ISA = qw( Exporter );
@EXPORT_OK = qw( get_sentences add_acronyms get_acronyms set_acronyms get_EOS set_EOS set_locale);		

our $VERBOSE = 0; # echo intermediate data transforms, useful for debugging
our $EOS = "\001"; #"__EOS__";
our $EOA = '__EOA__';

our $P = q/[\.!?]/;			    # PUNCTUATION

$AP =  q/(?:'|"|\?|\)|\]|\})?/;	# AFTER PUNCTUATION
our $PAP = $P.$AP;

# ACRONYMS AND ABBREVIATIONS
my @PEOPLE = qw( Mr Mrs Ms Dr Prof Mme Ms?gr Sens? Reps? Gov Attys? Supt Insp Const Det Revd? Ald Rt Hon);
my @TITLE_SUFFIXES = qw(PhD Jn?r Sn?r Esq MD LLB);
my @MILITARY = qw( Col Gen Lt Cm?dr Adm Capt Sgt Cpl Maj Pte);
my @INSTITUTES = qw( Dept Univ Assn Bros);
my @COMPANIES = qw( Inc Pty Ltd Co Corp);
my @PLACES =
qw(
	Arc Al Ave Blv?d Cl Ct Cres Dr Expy? Fw?y Hwa?y La Pde? Pl Plz Rd St Tce 
	dist mt km in ft 	
	Ala  Ariz Ark Cal Calif Col Colo Conn Del Fed  Fla Ga Ida Id Ill Ind Ia Kan Kans Ken Ky
	La Me Md Is Mass Mich Minn Miss Mo Mont Neb Nebr Nev Mex Okla Ok Ore Penna Penn Pa Dak 
	Tenn Tex Ut Vt Va Wash Wis Wisc Wy Wyo USAFA Alta Man Ont Qu? Sask Yuk
	Aust Vic Qld Tas
);
my @MONTHS = qw(Jan Feb Mar Apr May Jun Jul Aug Sept? Oct Nov Dec);
my @MISC = qw(no esp est);  # Established
my @LATIN = qw(vs etc al ibid sic);
my @MATH = qw(fig eq sec cf Thm Def Conj resp);

our @ABBREVIATIONS = (@PEOPLE, @TITLE_SUFFIXES, @MILITARY, @INSTITUTES, @COMPANIES, @PLACES, @MONTHS, @MISC,@LATIN, @MATH);


#==============================================================================
#
# Public methods
#
#==============================================================================

#------------------------------------------------------------------------------
# get_sentences - takes text input and splits it into sentences.
# A regular expression viciously cuts the text into sentences, 
# and then a list of rules (some of them consist of a list of abbreviations)
# are applied on the marked text in order to fix end-of-sentence markings in 
# places which are not indeed end-of-sentence.
#------------------------------------------------------------------------------
sub get_sentences {
	my ($text) = @_;
	return [] unless defined $text;
	$VERBOSE and print("ORIGINAL\n$text\n");
	
	$text = mark_up_abbreviations($text);
	$VERBOSE and print("mark_up_abbreviations\n$text\n");
	
	$text = first_sentence_breaking($text);
	$VERBOSE and print("first_sentence_breaking\n$text\n");
	
	$text = remove_false_end_of_sentence($text);
	$VERBOSE and print("remove_false_end_of_sentence\n$text\n");
	
	$text = split_unsplit_stuff($text);
	$VERBOSE and print("split_unsplit_stuff\n$text\n");
	
	my @sentences = split(/$EOS/,$text);
	my $cleaned_sentences = clean_sentences(\@sentences);
	if ($VERBOSE) {
		my $i;
		foreach my $sent (@$cleaned_sentences) {
			$i++;
			print("SENTENCE $i >>>$sent<<<\n");
		}
	}
	return $cleaned_sentences;
}

#------------------------------------------------------------------------------
# add_acronyms - user can add a list of acronyms/abbreviations.
#------------------------------------------------------------------------------
sub add_acronyms {
	push @ABBREVIATIONS, @_;
}

#------------------------------------------------------------------------------
# get_acronyms - get list of defined acronyms.
#------------------------------------------------------------------------------
sub get_acronyms {
	return @ABBREVIATIONS;
}

#------------------------------------------------------------------------------
# set_acronyms - replace the predefined acronyms list with your own list.
#------------------------------------------------------------------------------
sub set_acronyms {
	@ABBREVIATIONS=@_;
}

#------------------------------------------------------------------------------
# get_EOS - get the value of the $EOS variable (end-of-sentence mark).
#------------------------------------------------------------------------------
sub get_EOS {
	return $EOS;
}

#------------------------------------------------------------------------------
# set_EOS - set the value of the $EOS variable (end-of-sentence mark).
#------------------------------------------------------------------------------
sub set_EOS {
	my ($new_EOS) = @_;
	if (not defined $new_EOS) {
		cluck "Won't set \$EOS to undefined value!\n";
		return $EOS;
	}
    $EOS = $new_EOS;
    return $EOS;	
}

#------------------------------------------------------------------------------

# set_locale - set the value of the locale.
#
# Receieves language locale in the form
#	language.country.character-set
# for example:
#	"fr_CA.ISO8859-1"
# for Canadian French using character set ISO8859-1.
#
# Returns a reference to a hash containing the current locale formatting values.
# Returns undef if got undef.
#
#	The following will set the LC_ALL behaviour to Argentinian Spanish.
#	NOTE: The naming and availability of locales depends on your operating system.
#	Please consult the perllocale manpage for how to find out which locales are
#	available in your system.
#
#		$loc = set_locale( "es_AR.ISO8859-1" );
#
# This actually does this:
#
#	$loc = setlocale( LC_ALL, "es_AR.ISO8859-1" ); # NOTE, but actually does LC_CTYPE, should be LC_COLLATE?

#------------------------------------------------------------------------------
sub set_locale {
	my ($new_locale) = @_;
	if (not defined $new_locale) {
		cluck "Won't set locale to undefined value!\n";
		return undef;
	}
	
	if ($OSNAME ne 'android') {
		# Call POSIX function
		$LOC = setlocale(LC_CTYPE, $new_locale);
		return $LOC;
	}
	else {
		return undef;	
	}	
}

#==============================================================================
#
# Private methods
#
#==============================================================================


## Please email me any suggestions for optimizing these RegExps.
sub remove_false_end_of_sentence {
	my ($marked_segment) = @_;
	
	
##	## don't do U.S.A., U.K.
##	$marked_segment=~s/(\.\w$PAP)$EOS/$1/sg; 
	$marked_segment=~s/([^-\w]\w$PAP\s)$EOS/$1/sg;
	$marked_segment=~s/([^-\w]\w$P)$EOS/$1/sg;         

	# don't split after a white-space followed by a single letter or number followed
	# by a dot followed by another whitespace., such as "Something. 1. point one"
	# Note: will fail for 12. Point 12
	$marked_segment=~s/(\s[\w\d]\.\s+)$EOS/$1/sg; 

	# fix ellipsis: bla bla... yada yada
	$marked_segment=~s/(\.\.\. )$EOS([[:lower:]])/$1$2/sg;
	
	# fix quoted EOS such as "." "?" "!"
	$marked_segment=~s/(['"]$P['"]\s+)$EOS/$1/sg;
		
	# don't break after quote unless its a capital letter.
	$marked_segment=~s/(["']\s*)$EOS(\s*[[:lower:]])/$1$2/sg;

	# don't break: text . . some more text.
	$marked_segment=~s/(\s\.\s)$EOS(\s*)/$1$2/sg;
    $marked_segment=~s/(["']\s*)$EOS(\s*[[:lower:]])/$1$2/sg;

	$marked_segment=~s/(\s$PAP\s)$EOS/$1/sg;
	
	return $marked_segment;
}

sub split_unsplit_stuff {
	my ($text) = @_;
	

	# $text=~s/(\D\d+)($P)(\s+)/$1$2$EOS$3/sg; # breaks numbered points, such as {EOL}1. point one

	$text=~s/([\w $P]\d)($P)(\s+)/$1$2$EOS$3/sg;
	
	# eg 'end. (' -> 'end. $EOS ('
	$text=~s/($PAP\s)(\s*\()/$1$EOS$2/gs; # open bracket
	
	$text=~s/('\w$P)(\s)/$1$EOS$2/gs;


	$text=~s/(\sno\.)(\s+)(?!\d)/$1$EOS$2/gis;

	# split where single capital letter followed by dot makes sense to break.
	# notice these are exceptions to the general rule NOT to split on single
	# letter.
	# notice also that single letter M is missing here, due to French 'mister'
	# which is represented as M.
	#
	# the rule will not split on names beginning or containing 
	# single capital letter dot in the first or second name
	# assuming 2 or three word name.
	
	# NOT WORKING , it breaks up U.S.A. after U.
	# Valid cases if single letter thrn dot are rare, such as 'The answer is F'.
	# Can't decipher meaning of this regex
	# $text=~s/(\s[[:lower:]]\w+\s+[^[[:^upper:]M]\.)(?!\s+[[:upper:]]\.)/$1$EOS/sg;
	

	# add EOS when you see "a.m." or "p.m." followed by a capital letter.
	$text=~s/([ap]\.m\.\s+)([[:upper:]])/$1$EOS$2/gs;

	return $text;
}

sub clean_sentences {
	my ($sentences) = @_;
		my $cleaned_sentences;
		foreach my $s (@$sentences) {
			next if not defined $s;
			next if $s!~m/\w+/;
			$s=~s/^\s*//;
			$s=~s/\s*$//;
##			$s=~s/\s+/ /g;
			# replace end of abbrev marker with a dot
			$s=~s/$EOA/\./g;
			push @$cleaned_sentences,$s;
		}
	return $cleaned_sentences;
}

# Replace seuence such as Mr. A. Smith Jnr. with Mr__EOA__ A__EOA__ etc
# This simplifies the code that detects end of sentnees. The marker is
# replaced with the original dot adter sentence slitting

sub mark_up_abbreviations {
	my ($text) = @_;
	
	my %found_abbrevs;	
	foreach my $abbrev (@ABBREVIATIONS) {
		if ($text=~/\b($abbrev)\./i) {
			$found_abbrevs{$abbrev} = 1;
         }		
	}

	foreach my $abbrev (keys %found_abbrevs) {
		$text=~s/($abbrev)\./$1$EOA/gs;
	}
	
	return $text;
}

sub first_sentence_breaking {
	my ($text) = @_;
	$text=~s/\n\s*\n/$EOS/gs;	## double new-line means a different sentence.
	$text=~s/($PAP\s)/$1$EOS/gs;
	$text=~s/(\s\w$P)/$1$EOS/gs; # break also when single letter comes before punc.
	return $text;
}


#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
