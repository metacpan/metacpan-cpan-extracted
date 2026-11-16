package Lingua::EN::NameCase;

=head1 NAME

Lingua::EN::NameCase - Correctly case a person's name from UPPERCASE or lowercase

=cut

use strict;
use warnings;

# Names are free text and may hold lone surrogates or code points beyond
# Unicode.  Perl then warns from lc and friends; that is noise for the
# caller, who cannot fix it, so those warnings are off inside this module.
no warnings 'utf8';

# Deliberately NOT "use locale".  It made the result depend on the process
# locale: in the C locale (Windows code pages, bare containers) it gave
# "Emile" with an accent as "EMile", warned about every character above 255,
# and mis-cased "I" in Turkish.  Unicode rules are the same everywhere.
BEGIN {
	# Make native 8-bit strings follow Unicode rules too (Perl 5.12 and later).
	if ( $] >= 5.012 ) {
		require feature;
		feature->import('unicode_strings');
	}
}
use autodie qw(:all);

use Carp qw(croak);
use Exporter ();
use List::Util qw(max);
use Readonly;

# Private routines.  Sub::Private (enforce mode) makes a call from another
# package croak.  It is optional: it needs a recent Perl and several modules,
# and the module is just as correct without it, so a missing Sub::Private
# means only that the internals are not locked.
BEGIN {
	eval {
		require Sub::Private;
		Sub::Private->import(
			{ mode => 'enforce' },
			qw( _i18n _fail _safe_type _base_case _mac_case _particle_case _roman_case _postnominal_case )
		);
		1;
	};
}

our @ISA       = qw( Exporter );
our @EXPORT    = qw( nc );
our @EXPORT_OK = qw( NameCase nc );

=head1 VERSION

Version 1.22

=cut

our $VERSION = '1.22';

=head1 SYNOPSIS

	use Lingua::EN::NameCase qw( nc NameCase );

	# Pattern 1: fix one name.  nc() is like lc() and uc().
	my $name = nc('JOHN O\'CALLAGHAN');     # "John O'Callaghan"
	my $same = nc( \$name );                # a reference works too
	                                        # ($name itself is not changed)

	# Pattern 2: fix a list of names.  You get a new list back.
	my @clean = NameCase( 'ANNE JONES', 'BOB MCVEY' );

	# Pattern 3: fix an array in place.
	my @names = ( 'ANNE JONES', 'BOB MCVEY' );
	NameCase( \@names );                    # @names is now fixed

	# Pattern 4: clean data read from a file or database.
	open( my $fh, '<:encoding(UTF-8)', 'names.txt' );
	while ( my $line = <$fh> ) {
		chomp $line;
		print nc($line), "\n";
	}

	# Pattern 5: change the rules for part of your program only.
	{
		local $Lingua::EN::NameCase::SPANISH = 1;   # keep "El" and "La"
		print nc('EL PASO');                        # "El Paso"
	}
	print nc('EL PASO');                            # "el Paso"

	# Pattern 6: catch bad input.
	eval { nc( { not => 'a name' } ) };
	print "Problem: $@" if $@;

	# Other switches (all are package variables):
	#   $Lingua::EN::NameCase::HEBREW      = 0;  # "Ben" stays "Ben"
	#   $Lingua::EN::NameCase::ROMAN       = 0;  # "Li" stays "Li", not "LI"
	#   $Lingua::EN::NameCase::POSTNOMINAL = 0;  # "PHD" becomes "Phd"

=head1 DESCRIPTION

Forenames and surnames are often stored either wholly in UPPERCASE
or wholly in lowercase. This module allows you to convert names into
the correct case where possible.

Although forenames and surnames are normally stored separately if they
do appear in a single string, whitespace separated, NameCase and nc deal
correctly with them.

NameCase currently correctly name cases names which include any of the
following:

	Mc, Mac, al, el, ap, da, de, delle, della, di, du, del, der,
	la, le, lo, van and von.

It correctly deals with names which contain apostrophes and hyphens too.

=head2 EXAMPLE FIXES

	Original            Name Case
	--------            ---------
	KEITH               Keith
	LEIGH-WILLIAMS      Leigh-Williams
	MCCARTHY            McCarthy
	O'CALLAGHAN         O'Callaghan
	ST. JOHN            St. John

plus "son (daughter) of" etc. in various languages, e.g.:

	VON STREIT          von Streit
	VAN DYKE            van Dyke
	AP LLWYD DAFYDD     ap Llwyd Dafydd
	etc.

plus names with roman numerals (up to 89, LXXXIX), e.g.:

	henry viii          Henry VIII
	louis xiv           Louis XIV

=head2 CONFIGURATION

The behaviour is controlled by package variables, read on every call
so they may be changed at any time:

=over 4

=item C<$Lingua::EN::NameCase::HEBREW> (default 1)

Lowercase the Hebrew particles "ben" and "bat" when they follow another word.

=item C<$Lingua::EN::NameCase::SPANISH> (default 0)

Keep "El" and "La" capitalised (Spanish) instead of lowercasing them
(Greek and French).

=item C<$Lingua::EN::NameCase::ROMAN> (default 1)

Upper-case roman numerals (I to LXXXIX).

=item C<$Lingua::EN::NameCase::POSTNOMINAL> (default 1)

Normalise a trailing post-nominal such as "PhD" or "MBE".

=item C<$Lingua::EN::NameCase::MAX_LENGTH> (default C<undef>, no limit)

The longest name, in characters, that C<nc> will accept.  A longer name makes
C<nc> croak with the C<too_long> message instead of using time and memory on
it.  Set this when names come from an untrusted source.

=item C<%Lingua::EN::NameCase::MESSAGES>

Overrides the text of an error message by key (see L</MESSAGES> under
each routine).  The text may contain C<{name}> placeholders, which are
replaced by the arguments given when the error is raised.
This is the hook for translating the error messages.

=back

=cut

#--------------------------------------------------------------------------
# Public configuration.  These are package variables (not lexicals) because
# they are a documented part of the API.

our $HEBREW      = 1;
our $SPANISH     = 0;
our $ROMAN       = 1;
our $POSTNOMINAL = 1;
our $MAX_LENGTH;    # undef: no limit
our %MESSAGES;

#--------------------------------------------------------------------------
# Constant data.  Readonly guards against accidental modification; the hot
# path uses the pre-compiled structures built below, not these directly.

# Error message templates, keyed by message id.  Kept as templates so a
# translator can reorder the {placeholders}.
Readonly my %DEFAULT_MESSAGES => (
	usage_nc       => 'Usage: nc [[\\]$SCALAR] (got {got})',
	usage_namecase => 'Usage: $SCALAR|@ARRAY = NameCase [\\]$SCALAR|@ARRAY (got {got})',
	single_arg     => 'NameCase only accepts a single scalar, array or array ref',
	too_long       => 'Name is too long: {length} characters (the maximum is {max})',
);

# How a type name is shown in an error message: at most this many characters.
Readonly my $MAX_TYPE_NAME_LENGTH => 64;

# Reference types the functions accept.  (A plain hash: a Readonly hash is tied,
# which makes every lookup about ten times slower.)
my %ACCEPTED_REF = ( SCALAR => 1, ARRAY => 1 );

# Name fragments after "Mac" that are normally NOT capitalised,
# e.g. Machado, Mackie.  Matched as prefixes, as they always have been.
Readonly my @MAC_LOWERCASE_PREFIXES => qw(
	Evicius Hado Har Hin Hlin Ias Iulis Kie Kle Klin Quarie Omber In
	Kintosh Ken Hen Hiel Iol Kell Klem Krell Lin Key Kley Hell Hon
);

# One regex for the list above: "Mac" followed by an exception.
# The compiled patterns below are plain lexicals, not Readonly: they are never
# changed, and matching through a Readonly scalar costs about 25% more.
my $MAC_EXCEPTION = do {
	my $alternation = join '|', @MAC_LOWERCASE_PREFIXES;
	qr{ \b Mac ($alternation) }x;
};

# Particles that are lowercase whatever the context.  Al and Van are only
# particles when another word follows, otherwise they are forenames.
my $ALWAYS_LOWER_PARTICLE = qr{
	  Al(?=\s++\w) # al, Arabic (or the forename Al)
	| Ap\b         # ap, Welsh
	| Dell[ae]\b   # della, delle, Italian
	| D[aeiu]\b    # da, de, di Italian; du French
	| De[lr]\b     # del Italian; der Dutch/Flemish
	| L[eo]\b      # lo Italian; le French
	| Van(?=\s++\w) # van, German (or the forename Van)
	| Von\b        # von, Dutch/Flemish
}x;

# Particles whose case depends on a configuration flag.
# "++" never gives back whitespace it has taken: that could not help and would
# cost time on a long run of spaces.
my $HEBREW_PARTICLE  = qr{ (?<=\S\s) (?: Ben | Bat ) (?=\s++\w) }x;
my $SPANISH_CLASH    = qr{ (?: El | La ) \b }x;

# Roman numerals up to LXXXIX.
my $ROMAN_NUMERAL = qr{
	(?= [XxLlIiVv] )    # at least one letter: the pattern below can also match nothing
	(?: [Xx]{1,3} | [Xx][Ll]   | [Ll][Xx]{0,3} )?
	(?: [Ii]{1,3} | [Ii][VvXx] | [Vv][Ii]{0,3} )?
}x;

# One pattern per setting of (HEBREW, SPANISH), so each name is scanned once
# instead of three times.  Only the first letter of a particle is ever changed,
# so one pass gives the same answer as applying the rules one after another.
my %PARTICLE_PATTERN;
for my $hebrew ( 0, 1 ) {
	for my $spanish ( 0, 1 ) {
		my @alternatives = ($ALWAYS_LOWER_PARTICLE);
		push @alternatives, $HEBREW_PARTICLE if $hebrew;     # ben, bat after another word
		push @alternatives, $SPANISH_CLASH   if !$spanish;   # el, la: Greek and French, not Spanish
		my $any = join '|', @alternatives;
		$PARTICLE_PATTERN{"$hebrew$spanish"} = qr{ \b ($any) }x;
	}
}

# Gate for the Mc/Mac rules.  The last letter of the word must be checked as a
# letter: an older version let a space or punctuation stand in for it, so
# "Macdonalda Smith" passed the test that is meant to exclude names ending in
# a, c, i, o, z or j (typically Polish or Italian).
my $MAC_NAME = qr{
	  \b Mac            # "Mac" at the start of a word,
	  [A-Za-z]{3,}+     # then three or more letters (Mack, Macy, Mace are too short),
	  (?<! [aciozj] )   # the last of them not one of a c i o z j,
	  \b                # and the word ends there
	| \b Mc             # or "Mc" at the start of a word
}x;

Readonly my @POST_NOMINAL_INITIALS => qw(
	VC GC KG LG KT LT KP GCB OM GCSI GCMG GCIE GCVO GBE CH KCB DCB KCSI KCMG
	DCMG KCIE KCVO DCVO KBE DBE CB CSI CMG CIE CVO CBE DSO LVO OBE ISO MVO MBE
	IOM CGC RRC DSC MC DFC AFC ARRC OBI DCM CGM GM IDSM DSM MM DFM AFM SGM IOM
	CPM QGM RVM BEM QPM QFSM QAM CPM MSM ERD VD TD UD ED RD VRD AE

	PC ADC QHP QHS QHDS QHNS QHC SCJ J LJ QS SL QC KC JP DL MP MSP MSYP AM AM
	MLA MEP  DBEnv DConstMgt DREst EdD DPhil PhD DLitt DSocSci MD EngD DD LLD
	DProf MA MArch MAnth MSc MMORSE MMath MMathStat MPharm MPhil MSc MSci MSt
	MRes MEng MChem MBiochem MSocSc MMus LLM BCL MPhys MComp MAcc MFin MBA MPA
	MEd MEP MEnt MCGI MGeol MLitt MEarthSc MClinRes BA BSc LLB BEng MBChB FdA
	FdSc FdEng PgDip PgD PgCert PgC PgCLTHE AUH AKC AUS HNC HNCert HND HNDip
	DipHE Dip OND CertHE ACSM MCSM DIC AICSM ARSM ARCS LLB LLM BCL MJur DPhil
	PhD LLD DipLP FCILEx GCILEx ACILEx CQSW DipSW BSW MSW FCILT CMILT MILT CPL
	CTP CML PLS CTL DLP PLog EJLog ESLog EMLog JrLog Log SrLog BArch MArch ARB
	RIBA RIAS RIAI RSAW MB BM BS BCh BChir MRCS FRCS MS MCh. MRCP FRCP MRCPCH
	FRCPCH MRCPath MFPM FFPM BDS MRCPsych FRCPsych MRCOG FRCOG MCEM FCEM FRCA
	FFPMRCA MRCGP FRCGP BSc MScChiro MChiro MSc DC LFHOM MFHOM FFHOM FADO FBDO
	FCOptom MCOptom MOst DPT MCSP FCSP. SROT MSCR FSCR. CPhT RN VN RVN BVSc
	BVetMed VetMB BVM&S MRCVS FRCVS FAWM PGCAP PGCHE PGCE PGDE BEd NPQH QTS
	CSci CSciTeach RSci RSciTech CEng IEng EngTech ICTTech DEM MM CMarEng
	CMarSci CMarTech IMarEng MarEngTech RGN SRN RMN RSCN SEN EN RNMH RN RM RN1
	RNA RN2 RN3 RNMH RN4 RN5 RNLD RN6 RN8 RNC RN7 RN9 RHV RSN ROH RFHN SPAN
	SPMH SPCN SPLD SPHP SCHM SCLD SPCC SPDN V100 V200 V300 LPE MSc
);

# Built once at load time.  Matching one alternation against the end of the
# name is far cheaper than the old loop of ~600 regex compilations per call.
# Later entries win a case-insensitive tie, as in the sequential original.
my %POST_NOMINAL_CANONICAL;
$POST_NOMINAL_CANONICAL{ lc $_ } = $_ for @POST_NOMINAL_INITIALS;

# Finding a post-nominal "at the end" by scanning every word boundary costs time
# in proportion to the length of the name.  Instead the name is reversed and the
# reversed entries are matched at the start, which takes the same time however
# long the name is.  The entry must begin at a word boundary, so the character
# after it (in the reversed text) must not be a word character; every entry
# starts with a letter or digit, which makes that equivalent to the old \b.
my $POST_NOMINAL_REVERSED = do {
	# Longest first, so the longest entry that fits wins, as before.
	my $alternation = join '|',
		map { quotemeta scalar reverse $_ } sort { length($b) <=> length($a) } keys %POST_NOMINAL_CANONICAL;
	qr{
		\A \n?            # an optional newline that ended the name
		($alternation)    # an entry (reversed), captured
		(?!\w)            # not preceded (in the original) by a word character
	}xi;
};

# How much of the end of a name can matter: the longest entry, a final newline
# and the character in front of the entry.  Only this much is copied and
# reversed, so a huge name costs no more here than a short one.
my $POST_NOMINAL_WINDOW = 2 + max map { length } @POST_NOMINAL_INITIALS;

#--------------------------------------------------------------------------
# Public functions

=head1 COMMON PITFALLS

=over 4

=item * A scalar is never changed in place

C<NameCase(\$name)> and C<nc(\$name)> read the string and return a new
one.  Always use the return value:  C<$name = nc($name);>.
Only an I<array reference> is changed in place.

=item * Empty and undefined input

C<undef>, an empty string and the string "0" are returned as they are.
No warning is given.  Check for C<undef> yourself if you need to know.

=item * Switches are global

The four switches are package variables.  If you change one, it changes for
the whole program until you change it back.  Use C<local> inside a block
to limit the change.

=item * Only the last word can be a post-nominal

"JANE PHD SMITH" is not changed to "Jane PhD Smith".  "SMITH PHD" is
changed to "Smith PhD".

=item * One name per string, with no extra text

"MR. AND MRS. SMITH" and similar text get the same treatment as a name.
Words like "Of" are not changed to "of".

=item * The result is a guess

Some names are cased wrongly.  For example "MACINNES" becomes "Macinnes".
Check important data by hand.  See L</LIMITATIONS>.

=item * Wrong number of arguments

C<nc> takes at most one argument.  C<NameCase> in scalar context takes
exactly one.  Anything else stops the program with an error message,
so wrap the call in C<eval> if the input is not trusted.

=item * Untrusted input

Set C<$Lingua::EN::NameCase::MAX_LENGTH> when names come from users.  Without
it, a very large string is processed in full, using memory in proportion to
its size.  A class name in an error message is shortened and any odd
character in it becomes "?".

=item * C<nc()> with no argument uses C<$_>

This is the same as the built-in C<lc>.  It can surprise you inside a loop.

=back

=head1 ENCODING

The module works on Perl character strings.  Decode your input first,
for example with C<Encode::decode('UTF-8', $bytes)> or by reading a file
with C<< open(my $fh, '<:encoding(UTF-8)', $file) >>.  Print the result
through an encoded handle, for example C<< binmode(STDOUT, ':encoding(UTF-8)') >>.

=over 4

=item * Safe (decoded characters)

Accented letters ("EMILE ZOLA" with an accent), Greek and other alphabets
that have upper and lower case, and emojis.  An emoji is left as it is,
and the words around it are fixed: C<john E<lt>emojiE<gt> smith> becomes
C<John E<lt>emojiE<gt> Smith>.

=item * Not safe (raw bytes)

A UTF-8 byte string that was not decoded.  The ASCII letters are fixed, but
the bytes of non-ASCII letters are left alone and are not changed to
capitals.

=item * Scripts without case

Chinese, Japanese, Korean, Arabic, Hebrew and similar text is returned
unchanged.  It is safe to pass in.

=item * Apostrophes

Only the plain apostrophe (C<'>) is understood in the 's rule.
"FRED'S" becomes "Fred's", but "FRED" followed by a curly apostrophe and "S"
becomes "Fred" followed by the curly apostrophe and a capital "S".

=item * Sharp s

The German sharp s at the start of a word becomes "Ss".

=item * Error messages

The built-in messages are plain ASCII English.  Text you put in
C<%MESSAGES> may be any characters; use character strings.

=back

The module ignores the process locale (C<LC_ALL>, C<LC_CTYPE>): the result
is the same everywhere.

=head1 FUNCTIONS

=head2 NameCase

Takes a scalar, scalarref, array or arrayref, and changes the case of the
contents, as appropriate. Essentially a wrapper around nc().

=head3 PURPOSE

Case one name, or a whole list of names, in one call.

=head3 ARGS

One scalar, one scalar reference, one array reference, or (in list context
only) a list of scalars.

=head3 RETURNS

=over 4

=item * List context with a list, or an array reference

A list of name-cased copies.  The source is not modified.

=item * Scalar or void context with an array reference

The array is modified in place; the array reference is returned so calls
can be chained.  The new names are stored into the existing elements, so a
reference to an element, or an array that aliases other variables (such as
C<\@_>), sees the change.

=item * Scalar or scalar reference

A name-cased copy.  A scalar reference is I<not> modified (see L</LIMITATIONS>).
An undefined, empty or "0" value comes back unchanged.

=back

If the first argument is an array reference, any further arguments are
ignored.  An empty array reference gives an empty list (or an unchanged
empty array).  In list context a single scalar or scalar reference gives a
list of one name.

=head3 SIDE EFFECTS

Modifies the referenced array only in the in-place case above.  If any
element is invalid, the function croaks and the array is left unchanged.
Dies (via L<Carp/croak>) on bad arguments.

=head3 USAGE

See L</SYNOPSIS>.

=head3 EXAMPLE

	my @fixed = NameCase( 'JOHN SMITH', 'mary o\'neil' );
	# ('John Smith', "Mary O'Neil")

	my @names = ( 'ANNE JONES', 'BOB MCVEY' );
	NameCase( \@names );
	# @names is now ('Anne Jones', 'Bob McVey')

	my $one = NameCase( 'DAVID VAN DYKE' );   # 'David van Dyke'

=head3 API SPECIFICATION

=head4 input

	{
		names => {
			type     => 'arrayref',    # list of scalars, or one [] / \scalar
			optional => 0,
			min      => 1,
		},
	}

A single hash reference, or any reference type other than SCALAR or ARRAY,
is rejected.

Valid and invalid input, by partition:

=over 4

=item Argument form

Valid: one string, one scalar reference (copied, not changed), one array
reference, or a list of strings.  Invalid: no argument or, in scalar or
void context, more than one (croak C<single_arg>); a HASH, CODE, GLOB or
other reference (croak C<usage_namecase>).

=item Array size

0, 1, 2 and many are all valid.  An empty array returns an empty result.
In list context the original is never changed.  In scalar or void context
an array reference is changed in place and returned.

=item Each element

Must satisfy the C<nc> domain (see below), including C<$MAX_LENGTH>.  One
bad element croaks, and then no element of the array is changed.

=back

The domain of each element is the domain of L</nc>.

=head4 output

	{ type => 'arrayref', element_type => 'string' }    # list context
	{ type => 'string' }                                # one scalar
	{ type => 'arrayref' }                              # in place

=head3 MESSAGES

=over 4

=item C<usage_namecase>

I<Usage: $SCALAR|@ARRAY = NameCase [\]$SCALAR|@ARRAY (got {got})>.
The first argument was a reference of an unsupported type (C<{got}>).
Pass a scalar, a scalar ref or an array ref.

=item C<single_arg>

I<NameCase only accepts a single scalar, array or array ref>.
No arguments were given, or several were given in scalar context.
Pass exactly one value, or call in list context.

=back

=head3 PSEUDOCODE

	validate: reject refs that are neither ARRAY nor SCALAR
	if list context and (more than one arg or an ARRAY ref):
		return nc of each element
	elsif ARRAY ref:
		replace each element by nc(element); return the ref
	elsif SCALAR ref:
		return nc(dereferenced value)
	elsif exactly one arg:
		return nc(arg)
	else:
		croak single_arg

=cut

sub NameCase {
	my $first = $_[0];
	my $kind  = ref $first;    # '' for a plain scalar or no argument

	_fail( 'usage_namecase', { got => $kind } ) if $kind && !$ACCEPTED_REF{$kind};

	# We have an array, or several scalars, in list context: return a list.
	if ( wantarray && ( @_ > 1 || $kind eq 'ARRAY' ) ) {
		return map { nc($_) } @{ $kind eq 'ARRAY' ? $first : \@_ };
	}

	# An array ref in scalar/void context is converted in place, as that is
	# the only way to be useful when no list is wanted.  The whole answer is
	# built first, so a bad element croaks before the caller's array is touched.
	# It is then stored into the existing elements (a slice), not by replacing
	# the array contents, so a caller's references to elements, and an array
	# that aliases other variables (such as \@_), see the change.
	if ( $kind eq 'ARRAY' ) {
		my @fixed = map { nc($_) } @{$first};
		@{$first}[ 0 .. $#fixed ] = @fixed;
		return $first;
	}

	# Scalar refs are copied, not modified (documented limitation).
	return nc( ${$first} ) if $kind eq 'SCALAR';

	_fail('single_arg') unless @_ == 1;
	return nc($first);
}

=head2 nc

Takes a scalar or scalarref, and change the case of the name in the
corresponding string appropriately.

=head3 PURPOSE

Name-case a single string.

=head3 ARGS

Zero or one argument: a string or a scalar reference to a string.
With no argument, C<$_> is used (like C<lc> and C<uc>).

=head3 RETURNS

The name-cased string.  An undefined, empty or "0" input is returned
unchanged.  The input is never modified.

=head3 SIDE EFFECTS

None.  Reads the package variables listed under L</CONFIGURATION>.
It does not change C<$_>, C<$@>, C<$!> or any C<alarm> timer.

=head3 USAGE

	use Lingua::EN::NameCase qw(nc);
	print nc('MR. JON WHITACRE III');    # Mr. Jon Whitacre III

=head3 EXAMPLE

	nc('KEITH');              # 'Keith'
	nc('o\'callaghan');       # "O'Callaghan"
	nc('mccarthy');           # 'McCarthy'
	nc(\ 'henry viii');       # 'Henry VIII'
	nc('van der post');       # 'van der Post'

	local $Lingua::EN::NameCase::ROMAN = 0;
	nc('na li');              # 'Na Li'

=head3 API SPECIFICATION

=head4 input

	{
		name => {
			type     => 'string',     # or a scalarref to a string
			optional => 1,            # defaults to $_
			max      => undef,        # $MAX_LENGTH, when set
		},
	}

Valid and invalid input, by partition:

=over 4

=item Argument count

Valid: 0 (C<$_> is used) or 1.  Invalid: 2 or more (croak C<usage_nc>,
reported as C<list>).

=item Argument type

Valid: a string, a number, a scalar reference, C<undef>, C<''> and C<'0'>
(the last three are returned unchanged).  Invalid: any other reference
(HASH, ARRAY, CODE, GLOB, REF, Regexp, or an object); croak C<usage_nc>,
with the type or class name made safe and cut to 64 characters.

=item Length (C<$MAX_LENGTH>)

Counted in characters, never bytes.  C<undef> means no limit.  A length
equal to the maximum is accepted.  One character more croaks C<too_long>.
A maximum of 0 admits only the false values.  Negative or non-numeric
maximums are not checked; keep to non-negative integers.

=item Text

Any character string is accepted: ASCII, accented Latin, Greek, Cyrillic,
CJK, Hebrew, emoji, combining marks (Zalgo), and bidi controls such as
U+202E.  None of these crash or lose characters.  The result is at most 3
times as long as the input.  Undecoded bytes are not cased.

=item Recognised patterns

C<Mac> is split when 3 or more letters follow and the last is not one of
C<a c i o z j>; C<Mc> is always split.  Roman numerals I to LXXXIX are
converted; 90 (XC), IIII, XXXX and LXXXX are not.  Post-nominals are
converted only at the end of the string.

=back

=head4 output

	{ type => 'string', optional => 1 }    # undef in, undef out

=head3 MESSAGES

=over 4

=item C<usage_nc>

I<Usage: nc [[\]$SCALAR] (got {got})>.
More than one argument, or a reference that is not a scalar reference,
was supplied (C<{got}> names the type).  Pass one string or C<\$string>.

=item C<too_long>

I<Name is too long: {length} characters (the maximum is {max})>.
C<$MAX_LENGTH> is set and the name is longer.  Shorten the input, or raise
the limit.

=back

=head3 PSEUDOCODE

	validate arguments (at most one; a plain scalar or SCALAR ref)
	take the argument, or $_ when none was given
	dereference it if it is a reference
	return it at once if it is false (undef, '', '0')
	lowercase it, capitalise each word, lowercase 's
	apply the Mc/Mac rules
	lowercase the particles (da, de, van, von, ...)
	if ROMAN: upper-case roman numerals
	if POSTNOMINAL: normalise a trailing PhD, MBE, ...
	return the result

=cut

sub nc {
	# Read the argument exactly once.  A tied variable could answer differently
	# each time it is read, which would let a bad value slip past the check.
	# With no argument we work on $_, so the caller's $_ is never modified,
	# even when it holds a reference.
	my $name = @_ ? $_[0] : $_;
	my $kind = ref $name;

	_fail( 'usage_nc', { got => $kind || 'list' } )
		if @_ > 1 || ( $kind && $kind ne 'SCALAR' );

	$name = ${$name} if $kind;

	# undef, '' and '0' have no case to fix.
	return $name unless $name;

	# Refuse oversize input before any copy of it is made.
	_fail( 'too_long', { length => length $name, max => $MAX_LENGTH } )
		if defined $MAX_LENGTH && length $name > $MAX_LENGTH;

	$name = _base_case($name);
	$name = _mac_case($name);
	$name = _particle_case($name);
	$name = _roman_case($name)       if $ROMAN;
	$name = _postnominal_case($name) if $POSTNOMINAL;

	return $name;
}

#--------------------------------------------------------------------------
# Private functions (locked by Sub::Private when it is installed; see above).

# Purpose:      Raise a localised error.
# Entry:        $key is a message id; $args is an optional hashref of
#               placeholder values.
# Exit status:  Never returns.
# Side effects: Croaks, reporting the error at the caller of the public
#               function (Carp skips frames inside this package).
sub _fail {
	my ( $key, $args ) = @_;

	# The type name may come from an attacker (a class name can hold newlines
	# or be megabytes long), so it is made safe before it reaches a log.
	$args = { %{ $args || {} } };
	$args->{got} = _safe_type( $args->{got} ) if defined $args->{got};

	# An empty or missing text would make a useless error: fall back to the id.
	my $message = _i18n( $key, $args );
	$message = $key unless defined $message && length $message;
	croak $message;

	# Not reached: croak never returns.  This stops a guard clause from
	# falling through into bad data if croak is ever replaced.
	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	die $message;    ## no critic
}

# Purpose:      Make a reference type or class name safe to show in a message.
# Entry:        $type is a string (possibly hostile).
# Exit status:  Returns the string with every character other than a word
#               character or colon replaced by "?", cut to a fixed length.
# Side effects: None.
sub _safe_type {
	my ($type) = @_;

	# Cut first, then clean: a class name can be megabytes long.
	$type = substr $type, 0, $MAX_TYPE_NAME_LENGTH;
	$type =~ s{ [^\w:] }{?}gx;

	return $type;
}

# Purpose:      Turn a message id into text, in the user's wording if they
#               have supplied one in %MESSAGES.
# Entry:        $key is a message id; $args is an optional hashref.
#               Each {name} in the template is replaced by $args->{name};
#               an unknown {name} is left as written.
# Exit status:  Returns the message string; an unknown key is returned as is.
# Side effects: None.
sub _i18n {
	my ( $key, $args ) = @_;

	# A missing key is a programming error, but it must not hide the real
	# problem behind a second warning.
	$key = 'unknown_message' unless defined $key;
	$args ||= {};
	# Force a plain string: a reference here would become the exception itself.
	my $template = '' . ( $MESSAGES{$key} // $DEFAULT_MESSAGES{$key} // $key );

	$template =~ s{ \{ (\w++) \} }{ $args->{$1} // "{$1}" }gex;

	return $template;
}

# Purpose:      Lowercase everything, capitalise each word, then undo the
#               capital after an apostrophe (O'Neil stays, but Fred's -> Fred's).
# Entry:        $name is a non-empty string.
# Exit status:  Returns the converted string.
# Side effects: None.
sub _base_case {
	my ($name) = @_;

	$name = lc $name;
	$name =~ s{ \b (\w) }{\u$1}gx;
	$name =~ s{ (\'\w) \b }{\L$1}gx;

	return $name;
}

# Purpose:      Fix Mc and Mac names, e.g. McDonald, MacDonald, but Machado.
# Entry:        $name has been through _base_case().
# Exit status:  Returns the converted string.
# Side effects: None.
sub _mac_case {
	my ($name) = @_;

	# Taken from NameParse.pm: only touch names that look like Mc/Mac names.
	if ( $name =~ $MAC_NAME ) {
		$name =~ s{ \b (Ma?c) ([A-Za-z]) }{$1\u$2}gx;

		# Undo the capital for one-word exceptions such as Machado.
		$name =~ s{$MAC_EXCEPTION}{Mac\l$1}g;
		$name =~ s{ \b Macisaac }{MacIsaac}gx;
	}
	$name =~ s{ \b Macmurdo }{MacMurdo}gx;

	return $name;
}

# Purpose:      Lowercase "son of" particles: al, ap, da, de, del, van, von ...
# Entry:        $name has been through _base_case().
# Exit status:  Returns the converted string.
# Side effects: None.
sub _particle_case {
	my ($name) = @_;

	# Hebrew ben/bat need a preceding word, or "Ben Jones" would lose its
	# capital: <http://www.jewfaq.org/jnames.htm>.  El and La are lowercase in
	# Greek and French, but not in Spanish.  The pattern for the current
	# switches was built at load time.
	my $pattern = $PARTICLE_PATTERN{ ( $HEBREW ? 1 : 0 ) . ( $SPANISH ? 1 : 0 ) };
	$name =~ s{$pattern}{\l$1}g;

	return $name;
}

# Purpose:      Upper-case roman numerals, e.g. Henry VIII.
# Entry:        $name has been through _base_case().
# Exit status:  Returns the converted string.
# Side effects: None.
sub _roman_case {
	my ($name) = @_;

	$name =~ s{ \b ($ROMAN_NUMERAL) \b }{\U$1}gx;

	return $name;
}

# Purpose:      Put a trailing post-nominal (PhD, MBE ...) into its usual case.
# Entry:        $name has been through _base_case().
# Exit status:  Returns the converted string.
# Side effects: None.
sub _postnominal_case {
	my ($name) = @_;

	my $length = length $name;
	my $tail   = $length > $POST_NOMINAL_WINDOW ? substr( $name, $length - $POST_NOMINAL_WINDOW ) : $name;
	my $reversed = reverse $tail;

	if ( $reversed =~ $POST_NOMINAL_REVERSED ) {
		# Offsets are in the reversed tail, which ends where the name ends.
		my ( $start, $end ) = ( $-[1], $+[1] );
		my $entry = lc scalar reverse substr( $reversed, $start, $end - $start );

		# A text can match only through case folding (the long s U+017F matches
		# "s", the "fi" ligature matches "fi") and then has no exact key.  It is
		# left as it is: writing the missing value would delete the text.
		my $canonical = $POST_NOMINAL_CANONICAL{$entry};
		substr( $name, $length - $end, $end - $start ) = $canonical if defined $canonical;
	}

	return $name;
}

=head1 SECURITY

The module only reads and builds strings.  It opens no files, runs no
programs, uses no string C<eval>, and never turns its input into code or
into part of a regular expression.  Notes for programs that use it:

=over 4

=item * Taint mode

Taint is kept: a name that is tainted gives a tainted result.  The module
never launders data and works under C<perl -T>.

=item * Untrusted names

Names from users can be very long.  Set C<$Lingua::EN::NameCase::MAX_LENGTH>.
Case mapping can lengthen text: the result is at most three times as long as
the input.  The length check is on the input, before the mapping.

=item * Error messages

The type or class name of a bad argument is cut to 64 characters and any
character other than a letter, digit, underscore or colon is shown as "?",
so a hostile class name cannot add lines or escape codes to a log.

=item * Settings are global

The switches, C<$MAX_LENGTH> and C<%MESSAGES> are package variables, so any
code in the same program can change them.  Use C<local>.  They are not a
security boundary.

=item * Locked internals

L<Sub::Private>, when installed, stops other packages calling the internal
routines.  This is for tidiness, not security; it is switched off when the
environment variable C<HARNESS_ACTIVE> is true, and it is absent when
L<Sub::Private> is not installed.

=item * Malformed text

Invalid characters (lone surrogates, code points above U+10FFFF) are passed
through without a warning.  Check the encoding of untrusted input before
calling this module.

=back

=head1 PERFORMANCE

A typical name (two to four words) takes about 10 microseconds, which is
about 100,000 names a second, measured on an ordinary desktop with Perl 5.40.
The time grows in step with the length of the name.  Each step is a small
number of regular expression passes over the name, and
the cost of each pass was measured and tuned:

=over 4

=item * The roman numeral and particle rules each make one pass.

=item * A trailing post-nominal is found by matching the reversed name at its
start, so a very long name costs no more for this step than a short one.

=item * Patterns are compiled once, when the module loads.

=item * If L<Sub::Private> is installed each internal call is about 0.4
microseconds slower; this is the price of locking the internals.

=back

Set C<$Lingua::EN::NameCase::MAX_LENGTH> to bound the time spent on any one
name.

=head1 LIMITATIONS

The design choices below are known weaknesses.

=over 4

=item * Global configuration

C<$HEBREW>, C<$SPANISH>, C<$ROMAN> and C<$POSTNOMINAL> are package
variables, so one part of a program changing them changes the result for
all of it.  Use C<local> to scope a change.  A per-call options hash would
be better, but would change the API.

=item * Scalar references are not modified in place

C<NameCase(\$name)> returns a copy.  Changing this would break existing
callers.

=item * Exceptions are prefixes

The "Mac" exceptions match the start of a word, so MacInnes becomes
Macinnes and MacKenzie becomes Mackenzie.  An exact-surname list would be
more accurate but needs data this module does not have.

=item * Everything is an English-language heuristic

Names are not cased by a grammar.  "Ben" and "Van" are lowercased only when
they follow another word, and every word of a name is treated alike
(C<Estate Of Laura Jones>).  For real name parsing use
L<Lingua::EN::NameParse>.

=item * Locale is ignored

Case rules are the Unicode rules, whatever the locale.  Older versions used
C<use locale>, which gave different answers on different machines.  Data in
a legacy 8-bit code page must be decoded first (see L</ENCODING>).  Language
rules are not applied, so Turkish "I" becomes "i", not a dotless "i".

=item * The Mac test covers the whole string

Whether the "Mac" rules apply is decided once for the whole string, not word
by word.  A string that holds both a name such as "Mcdonald" and a name such
as "Macchiato" will have both treated as Mac names.  Pass one name at a time.

=item * Hebrew particles need one space

"ben" and "bat" are recognised only when exactly one white space character
separates them from the word in front.

=item * Post-nominals only at the end

Only the last word is checked, and the list is not exhaustive.
Since the entries are now matched literally, "MCh." and "FCSP." require
their final dot (the dot used to match any character).

=item * Error messages

Messages are English templates with C<{name}> placeholders, replaceable
through C<%MESSAGES>.  There is no plural or gender handling because none
of the messages needs it.

=item * Encapsulation

The internal routines are guarded with L<Sub::Private> in enforce mode, but
only if that module is installed.  It is optional because it needs Perl 5.14
or later and heavy dependencies; without it the internals are ordinary
subroutines whose names start with an underscore.  L<Sub::Protected> is not
used because the module has no classes or methods to protect.

=back

=head1 BUGS

The module covers the rules that I know of. There are probably a lot
more rules, exceptions etc. for "Western"-style languages which could be
incorporated.

There are probably lots of exceptions and problems - but as a general
data 'cleaner' it may be all you need.

Use Kim Ryan's L<Lingua::EN::NameParse> for any really sophisticated name parsing.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Lingua-EN-NameCase/coverage/>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Lingua::EN::NameCase

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Lingua-EN-NameCase>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-NameCase>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Lingua-EN-NameCase>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Lingua-EN-NameCase>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Lingua::EN::NameCase>

=back

=head1 AUTHOR

  1998-2014    Mark Summerfield <summer@qtrac.eu>
  2014-present Barbie <barbie@cpan.org>

  2020- Maintained by Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Kim Ryan <kimaryan@ozemail.com.au> for his Mc/Mac solution.

=encoding utf8

=head1 FORMAL SPECIFICATION

This section is for readers who know Z notation.  It is the only part of
this file that is not plain ASCII.  Each schema describes one function.
A prime (') marks a value after the call.  C<ARGS> is the list of arguments,
C<ANY> is any Perl value, and C<STRING> is a Perl string.

=head2 NameCase

	┌─ NameCase ─────────────────────────────────────────────
	│ args? : seq ANY
	│ ctx?  : { list, scalar, void }
	│ out!  : seq STRING ∪ STRING ∪ ARRAYREF
	├────────────────────────────────────────────────────────
	│ ref(head args?) ∉ { ARRAY, SCALAR, ∅ } ⇒ croak usage_namecase
	│ ctx? = list ∧ (#args? > 1 ∨ ref(head args?) = ARRAY)
	│     ⇒ out! = nc ∘ (elements args?)
	│ ctx? ≠ list ∧ ref(head args?) = ARRAY
	│     ⇒ head args? ' = nc ∘ (head args?) ∧ out! = head args?
	│ ref(head args?) = SCALAR ⇒ out! = nc(↑(head args?))
	│ ref(head args?) = ∅ ∧ #args? = 1 ⇒ out! = nc(head args?)
	│ otherwise ⇒ croak single_arg
	└────────────────────────────────────────────────────────

=head2 nc

	┌─ nc ───────────────────────────────────────────────────
	│ name? : STRING ∪ ↑STRING ∪ {⊥}
	│ out!  : STRING ∪ {⊥}
	├────────────────────────────────────────────────────────
	│ #args > 1 ∨ ref(name?) ∉ { ∅, SCALAR } ⇒ croak usage_nc
	│ MAX_LENGTH ≠ ⊥ ∧ value ∉ {⊥, "", "0"} ∧ #value > MAX_LENGTH ⇒ croak too_long
	│ value = (name? ∈ ↑STRING ⇒ ↑name?  ∨  name?)
	│ value ∈ {⊥, "", "0"} ⇒ out! = value
	│ otherwise
	│   out! = postnominal ∘ roman ∘ particles ∘ mac ∘ base (value)
	│   where roman and postnominal apply only when enabled
	└────────────────────────────────────────────────────────

=head2 Configuration

	┌─ Config ───────────────────────────────────────────────
	│ HEBREW, SPANISH, ROMAN, POSTNOMINAL : { 0, 1 }
	│ MAX_LENGTH : ℕ ∪ {⊥}
	│ MESSAGES : KEY ⇸ STRING
	└────────────────────────────────────────────────────────
	┌─ Init ─────────────────────────────────────────────────
	│ Config'
	├────────────────────────────────────────────────────────
	│ HEBREW' = 1 ∧ SPANISH' = 0 ∧ ROMAN' = 1 ∧ POSTNOMINAL' = 1
	│ MESSAGES' = ∅ ∧ MAX_LENGTH' = ⊥
	└────────────────────────────────────────────────────────
	┌─ Set ──────────────────────────────────────────────────
	│ ΔConfig ; flag? : { HEBREW, SPANISH, ROMAN, POSTNOMINAL } ; v? : { 0, 1 }
	├────────────────────────────────────────────────────────
	│ flag?' = v? ∧ all other variables are unchanged
	└────────────────────────────────────────────────────────

nc and NameCase read Config and never change it (ΞConfig).

=head1 STATE DIAGRAM

The module keeps no data between calls except the configuration.  So there
are two small machines: the configuration, and what happens during one call.

Configuration (the four switches, C<$MAX_LENGTH> and C<%MESSAGES>):

	  use Lingua::EN::NameCase
	            |
	            v
	   +-----------------+   set a switch or %MESSAGES key   +-----------------+
	   |    DEFAULTS     |---------------------------------->|   CUSTOMISED    |
	   | HEBREW=1        |   action: later calls use it      | any switch or   |
	   | SPANISH=0       |<----------------------------------| message differs |
	   | ROMAN=1         |   set back, or leave a block      +-----------------+
	   | POSTNOMINAL=1   |   that used "local"                  |          ^
	   +-----------------+                                      +----------+
	                                                            set again

DEFAULTS also means that C<$MAX_LENGTH> is C<undef> and C<%MESSAGES> is
empty.  Both states accept every call below.  Calls never change the
configuration.

One call to C<nc> or C<NameCase>:

	 nc(...) / NameCase(...)
	        |
	        v
	  +------------+  bad type, wrong count   +----------+
	  | VALIDATING |------------------------->|  FAILED  |
	  +------------+  action: croak with the  +----------+
	        |         message (usage_nc,       (the caller
	        | ok      usage_namecase,           gets an
	        v         single_arg)               exception)
	  +------------+  undef, "" or "0"        +----------+
	  |  READING   |------------------------->|   DONE   |
	  +------------+  action: return it as is +----------+
	        |                                       ^
	        | has text                              |
	        v                                       |
	  +------------+  base case, Mc/Mac, particles,  |
	  |   CASING   |  roman numerals (if ROMAN),     |
	  +------------+  post-nominal (if POSTNOMINAL)  |
	        |                                       |
	        +---------------------------------------+
	          action: return the new string

	  READING also goes to FAILED when $MAX_LENGTH is set and the text is
	  longer (message too_long).  The caller gets an exception and nothing
	  is changed.

	  NameCase only: an array ref in scalar or void context goes from
	  CASING to DONE after replacing each element (the only side effect
	  on caller data), and returns the array ref.

=head1 LICENSE AND COPYRIGHT

Copyright (c) Mark Summerfield 1998-2014. All Rights Reserved.
Copyright (c) Barbie 2014-2015. All Rights Reserved.
Copyright (c) Nigel Horne 2020-2026. All Rights Reserved.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic License 2.0.

=cut

1;
