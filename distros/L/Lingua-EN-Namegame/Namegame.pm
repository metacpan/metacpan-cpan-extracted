# Namegame.pm module
#########################################################+
#      From the CONSULTIX "Perl Programming" class      #+
# POB 70563, Seattle WA 98107 USA tim@consultix-inc.com #+
#  Copyright 1997-2001, Tim Maher. All Rights Reserved  #+
#########################################################+
# Tim Maher, tim@teachmeperl.com

package	Lingua::EN::Namegame;

use 5.006;	# 5.6.0 needed for "our" keyword
use strict;
use warnings;
use Carp;

require	Exporter;

our @ISA		=	qw(Exporter);
our @EXPORT		=	qw(name2verse);
our @EXPORT_OK		=	qw( );
our $VERSION		= 	'0.05';

our ($SEP);

# name_game
# A program that generates a rhyming verse from a name,
# as in the famous song "The Name Game", by Shirley Ellis

# Inspired by "One-Liner #40", in TPJ #15, Fall 1999, p. 11.
#  by Sean M. Burke:
#   s<^([bcdfghjklmnpqrstvwxyz]*)(\w+).*>
#   <$1$2 $1$2 $1o $1$2 / Bonana-Fanna-Fo-F$2 / Fe Fi Mo M$2 / $1$2!>i;

# Reworked by Tim Maher to comply with the
# rhyming rules of the song, as documented in 
# http://www.geocities.com/SunsetStrip/Palladium/1306/shirley.htm.

# GENERAL RULES:
# 1) Say the name twice 
#	"Dave  Dave"

# 2) Say "bo" and Name again, replacing Name's first letter by B
#	"Bo Bave"

# 3) Say Banana Fanna Fo Name, replacing Name's first letter by F
#	"banana Fanna Fo Fave"

# 4) Say Fee Fi Mo Name, replacing Name's first letter by M
#	"Fee Fi Mo Mave"

# 5) Say Name once more 
#	"Dave"


# ALTERNATE RULES, for Names Starting with B, F, or M
#   (e.g., Marsha)
# 2. B-names; instead of bo Bob, use Bo-ob
# 3. F-names; instead of Banana Fanna Fo Fred
#    -- Banana Fanna Fo-red
# 4. M-names; instead of Fee Fi Mo Marsha -- Fee Fi Mo-arsha


sub name2verse {

	my $name=shift;	# grab the name for making the verse
	my ($f, $s, $i, $rest, $verse);

	# need >= two word-chars, including one vowel
	unless ( defined $name  and
			$name =~ /[a-z][a-z]/i  and 
				$name =~/[aeiouy]/i ) {
		carp 'name2verse(): Name needs ',
			'two or more letters ',
			"including one vowel\n";
		return undef;
	}

	local $SEP="\n";	# meant to leak into sub indent() below
	# /^([bcdfghjklmnpqrstvwxyz]*)([a-zA-Z]+)/ 

	# Grab leading consonants (if present), and following vowels

	$name =~ /^\s*([b-df-hj-np-tv-z]*)([a-z]+)/i  or  return undef;

	$f="\u$1";	# force upper-case; "first" part (includes initial)
	$s="\L$2";	# force lower-case; "second" part
	$i=substr($f,0,1);	# force upper-case; "initial"
	$f ne '' and
		$rest=substr($f,1) . $s;	# "rest" of first part

	#print "I, rest, F, S = $i, $rest, $f, $s\n";
	# print "Using rule #2, for $f/$s\n";

	# Now construct the verse for this name

	# Rule #1: State name twice
	$verse="\u$f$s \u$f$s " . indent();

	# Rule #2: General Case; Rob -> Bo-Bob
	if ($i ne 'B') {
		$verse.="bo \uB$s, " . indent();
	}
	# Rule #2: Special Case For B-names; Bob -> Bo-ob
	else {
		$verse.="${i}o-$rest, " . indent();
	}

	# Rule #3: General Case; Tom -> Fo-Fom
	if ($i ne 'F') {			# Fo Fom
		$verse.="Banana Fanna Fo F$s, " . indent();
	}
	# Rule #3: Special Case for F-names; Fred -> Fo-red
	else {
		$verse.="Banana Fanna ${i}o-$rest, " . indent();
	}
	# Rule #4: General Case; Tom -> Mo-Mom
	if ($i ne 'M') {
		$verse.="Fee Fi Mo M$s\n\t";
	}
	# Rule #4: Special Case for M-names; Marsha -> Mo-arsha
	else {
		$verse.="Fee Fi Mo-$s\n\t";
	}
	$verse.="\U$f$s!";
	return $verse;
}
sub indent { return ${SEP}.=' '; }
1;

__DATA__

=pod

=head1 NAME

Lingua::EN::Namegame - Creates a "Name-Game" verse from a name (or word)

=head1 VERSION

This document describes version 0.04 of Lingua::EN::Namegame,
released January 01, 2003.

=head1 SYNOPSIS

	use Lingua::EN::Namegame;

	$verse = name2verse ('Marsha');

	print $verse;

I<Or, more simply, at your OS command prompt>:

	name2verse.pl  Marsha		# script provided with module

=head2 Output

	Marsha Marsha 
	    bo Barsha, 
		Banana Fanna Fo Farsha, 
		    Fee Fi Mo-arsha
			MARSHA!

I<Or, for extra policital correctness>

	name2verse_nonprofane.pl  Bart	# script provided with module

=head2 Output

	Sorry, the verse for Bart contains a profane word.

=head1 DESCRIPTION

=head2 Purpose

B<name2verse>
is a subroutine that generates a rhyming verse based on a name (or word),
in accordance with the L<rhyming algorithm> documented in the lyrics of the
famous 1960's song B<The Name Game>, by I<Shirley Ellis>.

=head2 Background

A presentation based on this program was featured as a I<Lightning Talk>
at the North American B<Yet Another Perl Conference> (B<YAPC::NA>) 
in St. Louis MO, USA, on 6/28/2002.

Thanks to the foresight of the moderator (B<MJD>),
the presentation was scheduled as the I<last one> for the day,
providing us ample time to delve into extra-curricular shenanigans after the technical
part of the presentation.

And few present will ever forget the spine-tingling effect of
B<300+ deranged Perl fanatics> giving song to the
rhyming verses for various Perl I<built-in functions>,
including B<map>, B<grep>, B<split>, and of course, the
especially euphonious B<wantarray>:

	Wantarray Wantarray
	    bo Bantarray, 
		Banana Fanna Fo Fantarray, 
		    Fee Fi Mo Mantarray
			  WANTARRAY!

Notice the way this oddly chosen function name smoothly metamorphoses into a denizen of the deep
in the penultimate line!

And some thought Larry had goofed up by not calling it B<wantlist> instead.  I<Poppycock!>

=head2 Profanity Issues

Hey, that's not a bad word itself; let's try it!

	Poppycock Poppycock
	    bo Boppycock, 
		Banana Fanna Fo Foppycock, 
		    Fee Fi Mo Moppycock
		      POPPYCOCK!

Which reminds me that some actual human names, such as B<Bart> and especially B<Chuck>,
give rise to B<really rousingly ribald rhymes>, which has often led to embarassing outbursts of
I<blushing and snickering> in
our
Perl training classes.  One solution is to use the 
supplied
B<name2verse_nonprofane.pl> script to identify and filter-out verses that are
judged to contain profane words.
It does this through use of the "profanity matching regex" of I<Damian Conway's> B<Regexp::Common> module.


=for comment =head1 RHYMING_ALGORITHM

=head1 RHYMING ALGORITHM

This program was inspired by "One-Liner #40", in B<The Perl Journal> #15, Fall 1999, p. 11.,
by I<Sean M. Burke>,
which used a simplified version of the algorithm for succinctness:

 s<^([bcdfghjklmnpqrstvwxyz]*)(\w+).*>
    <$1$2 $1$2 $1o $1$2/Bonana-Fanna-Fo-F$2/Fe Fi Mo M$2/$1$2!>i;

In contrast, this module aims to comply with the actual rhyming rules of the song, as documented in
L<http://www.geocities.com/SunsetStrip/Palladium/1306/shirley.htm>.

=for comment
(In this regard, I recently made a change 
to give better results for names containing B<Y>s, such as B<Lydia> and B<Lyle>.)

=head2 General Rules

=over

=item 1. Say the Name twice (following examples using "Dave")

	-> "Dave Dave"


=item 2. Say "bo" and Name again, replacing Name's first letter by B

	-> "Bo Bave"

=item 3. Say "Banana Fanna Fo" Name, replacing Name's first letter by F

	-> "banana Fanna Fo Fave"

=item 4. Say "Fee Fi Mo" Name, replacing Name's first letter by M

	-> "Fee Fi Mo Mave"

=item 5. Finally, exclaim Name

	-> "Dave!"

=back

=head2 Alternate Rules

Modified versions of rules 2-4 apply to Names starting with B<B>, B<F>, or B<M>.

=over

=item 2. B<B>-names:

say "Bo" and then Name without the initial B:

	-> "Bo-ob" (for Bob)
	-> "Bo-rian" (for Brian)
	-> "Bo-lanche" (for Blanche)

=item 3. B<F>-names:

instead of "Banana Fanna Fo" Fred:

	-> "Banana Fanna" B<Fo-red>

=item 4. B<M>-names:

instead of "Fee Fi Mo" Marsha:

	-> "Fee Fi" B<Mo-arsha>

=back

=head1 BUGS

Please let me know if you find any bugs.

=head1 EXPORTS

name2verse()

=head1 SCRIPTS

B<name2verse.pl>, B<name2verse_nonprofane.pl>

=head1 AUTHOR

	Tim Maher
	Consultix
	yumpy@cpan.org
	http://www.teachmeperl.com

=head1 SEE ALSO

L<http://www.geocities.com/SunsetStrip/Palladium/1306/shirley.htm>

=head1 LICENSE

Copyright (c) 2002, Timothy F. Maher.  All rights reserved. 

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=for comment Meant to be hidden now:
See (L<http://www.perl.com/perl/misc/Artistic.html>) and
(L<http://www.gnu.org/copyleft/gpl.html>) for details.

=cut

1;
