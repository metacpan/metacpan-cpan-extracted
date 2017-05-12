package Lingua::EO::Orthography;


# ****************************************************************
# perl dependency
# ****************************************************************

use 5.008_001;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;
use utf8;


# ****************************************************************
# general depencency(-ies)
# ****************************************************************

use Carp qw(confess);
use Data::Util qw(:check neat);
use List::MoreUtils qw(any apply uniq);
use Memoize qw(memoize);
use Regexp::Assemble;
use Try::Tiny;


# ****************************************************************
# version
# ****************************************************************

our $VERSION = "0.04";


# ****************************************************************
# constructor
# ****************************************************************

sub new {
    my ($class, %init_arg) = @_;

    my $self = bless {}, $class;

    $self->sources(
          exists $init_arg{sources} ? $init_arg{sources}
        :                             ':all'
    );
    $self->target(
          exists $init_arg{target}  ? $init_arg{target}
        :                             'orthography'
    );

    return $self;
}


# ****************************************************************
# accessor(s) for attribute(s)
# ****************************************************************

sub sources {
    my ($self, $source_notation_candidates_ref) = @_;

    if (scalar @_ > 1) {    # $self->sources(undef) comes here and dies
        if (
            defined $source_notation_candidates_ref &&
            $source_notation_candidates_ref eq ':all'
        ) {
            $self->{sources} = [
                grep {
                    $_ ne 'orthography';
                } keys %{ $self->_notation }
            ];
        }
        else {
            try {
                $self->_check_source_notations($source_notation_candidates_ref);
            }
            catch {
                confess "Could not set source notations because: " . $_;
            };
            $self->{sources} = [ uniq @$source_notation_candidates_ref ];
        }
    }

    return $self->{sources};
}

sub target {
    my ($self, $target_notation_candidate) = @_;

    if (scalar @_ > 1) {    # $self->target(undef) comes here and dies
        try {
            $self->_check_notations($target_notation_candidate);
        }
        catch {
            confess "Could not set a target notation because: " . $_;
        };
        $self->{target} = $target_notation_candidate;
    }

    return $self->{target};
}


# ****************************************************************
# utility(-ies) for attribute(s)
# ****************************************************************

sub all_sources {
    my $self = shift;

    return @{ $self->{sources} };
}

sub add_sources {
    my ($self, @adding_notations) = @_;

    try {
        $self->_check_notations(@adding_notations);
    }
    catch {
        confess "Could not add source notations because: " . $_;
    };
    @{ $self->{sources} } = uniq $self->all_sources, @adding_notations;

    return $self->{sources};
}

sub remove_sources {
    my ($self, @removing_notations) = @_;

    try {
        $self->_check_notations(@removing_notations);

        # Note: I dare do not use List::Compare to get complement notations
        my %removing_notation;
        @removing_notation{ @removing_notations } = ();
        $self->{sources} = [
            grep {
                ! exists $removing_notation{$_};
            } $self->all_sources
        ];

        die 'Converter must maintain at least one source notation'
            unless @{ $self->{sources} };
    }
    catch {
        confess "Could not remove source notations because: " . $_;
    };

    return $self->{sources};
}


# ****************************************************************
# converter(s)
# ****************************************************************

sub convert {
    my ($self, $string) = @_;

    confess sprintf 'Could not convert string because '
                  . 'string (%s) must be a primitive value',
                neat($string)
        unless is_value($string);

    my $source_pattern   = $self->_source_pattern( @{ $self->sources } );
    my $target_character = $self->_target_character( $self->target );

    $string =~ s{
        ($source_pattern)
    }{$target_character->{$1}}xmsg;

    return $string;
}


# ****************************************************************
# checker(s)
# ****************************************************************

sub _check_notations {
    my ($self, @notation_candidates) = @_;

    my $notation_ref = $self->_notation;

    map {
        die sprintf 'Notation (%s) must be a primitive value',
                    neat($_)
            unless is_value($_);

        die sprintf 'Notation (%s) does not enumerated',
                    neat($_)
            unless exists $notation_ref->{$_};
    } @notation_candidates;

    return;
}

sub _check_source_notations {
    my ($self, $source_notation_candidates_ref) = @_;

    confess 'Source notations must be an array reference'
        unless is_array_ref($source_notation_candidates_ref);
    confess 'Source notations must be a nonnull array reference'
        unless @$source_notation_candidates_ref;

    $self->_check_notations(@$source_notation_candidates_ref);

    return;
}


# ****************************************************************
# internal properties
# ****************************************************************

sub _notation {
    return {
        orthography => [(           # LATIN (CAPITAL|SMALL) LETTER ...
            "\x{108}", "\x{109}",   #   ... C WITH CIRCUMFLEX
            "\x{11C}", "\x{11D}",   #   ... G WITH CIRCUMFLEX
            "\x{124}", "\x{125}",   #   ... H WITH CIRCUMFLEX
            "\x{134}", "\x{135}",   #   ... J WITH CIRCUMFLEX
            "\x{15C}", "\x{15D}",   #   ... S WITH CIRCUMFLEX
            "\x{16C}", "\x{16D}",   #   ... U WITH BREVE
        )],
        zamenhof            => [qw(Ch ch Gh gh Hh hh Jh jh Sh sh U  u )],
        capital_zamenhof    => [qw(CH ch GH gh HH hh JH jh SH sh U  u )],
        postfix_h           => [qw(Ch ch Gh gh Hh hh Jh jh Sh sh Uw uw)],
        postfix_capital_h   => [qw(CH ch GH gh HH hh JH jh SH sh UW uw)],
        postfix_x           => [qw(Cx cx Gx gx Hx hx Jx jx Sx sx Ux ux)],
        postfix_capital_x   => [qw(CX cx GX gx HX hx JX jx SX sx UX ux)],
        postfix_caret       => [qw(C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U^ u^)],
        postfix_apostrophe  => [qw(C' c' G' g' H' h' J' j' S' s' U' u')],
        prefix_caret        => [qw(^C ^c ^G ^g ^H ^h ^J ^j ^S ^s ^U ^u)],
    };
}

sub _source_pattern {
    my ($self, @source_notations) = @_;

    my $regexp_assembler = Regexp::Assemble->new;
    my $notation_ref     = $self->_notation;

    SOURCE_NOTATION:
    foreach my $source_notation (@source_notations) {
        SOURCE_CHARACTER:
        foreach my $source_character (
            @{ $notation_ref->{ $source_notation } }
        ) {
            next SOURCE_CHARACTER
                if $source_character =~ m{ \A [Uu] \z }xms;
            ( my $escaped_source_character = $source_character )
                =~ s{ (?=[\^\*\+]) }{\\}xms;
            $regexp_assembler->add($escaped_source_character);
        }
    }

    return $regexp_assembler->re;
}

sub _target_character {
    my ($self, $target_notation) = @_;

    return ( $self->_converter_table )->{$target_notation};
}

# Returns table as {$target_notation}{'source_character'} => 'target_character'
sub _converter_table {
    my $self = shift;

    my $converter_table;
    my $source_notations_ref = $self->_notation;
    my $target_notation_ref  = { %$source_notations_ref };

    TARGET_NOTATION:
    while (
        my ($target_notation, $target_characters_ref)
            = each %$target_notation_ref
    ) {
        SOURCE_NOTATION:
        while (
            my ($source_notation, $source_characters_ref)
                = each %$source_notations_ref
        ) {
            next SOURCE_NOTATION
                if $source_notation eq $target_notation;

            SOURCE_CHARACTER:
            foreach my $index ( 0 .. $#{$source_characters_ref} ) {
                next SOURCE_CHARACTER
                    if $source_characters_ref->[$index]
                        =~ m{ \A [Uu] \z }xms;
                $converter_table->{ $target_notation }
                                  { $source_characters_ref->[$index] }
                    = $target_characters_ref->[$index];
            }
        }
    }

    return $converter_table;
}


# ****************************************************************
# memoization
# ****************************************************************

sub _memoize_methods {
    map {
        memoize $_
    } qw(
        _check_notations
        _check_source_notations
        _notation
        _source_pattern
        _target_character
        _converter_table
    );

    return;
}


# ****************************************************************
# compile-time process(es)
# ****************************************************************

__PACKAGE__->_memoize_methods;


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=encoding utf-8

=head1 NAME

Lingua::EO::Orthography - A orthography/substitute converter for Esperanto characters

=head1 VERSION

This document describes
L<Lingua::EO::Orthography|Lingua::EO::Orthography>
version C<0.04>.

=head2 Translations

=over 4

=item en: English

L<Lingua::EO::Orthography|Lingua::EO::Orthography>
(This document)

=item eo: Esperanto

L<Lingua::EO::Orthography::EO|Lingua::EO::Orthography::EO>

=item ja: Japanese

L<Lingua::EO::Orthography::JA|Lingua::EO::Orthography::JA>

=back

=head1 SYNOPSIS

    use utf8;
    use Lingua::EO::Orthography;

    my ($converter, $original, $converted);

    # orthographize ...
    $converter = Lingua::EO::Orthography->new;
    $original  = q(C^i-momente, la songha h'orajxo ^sprucigas aplauwdon.);
    $converted = $converter->convert($original);

    # substitute ... (X-system)
    $converter->sources([qw(orthography)]); # (accepts multiple notations)
    $converter->target('postfix_x');
        # same as above:
        # $converter = Lingua::EO::Orthography->new(
        #     sources => [qw(orthography)],
        #     target  => 'postfix_x',
        # );
    $original  = q(Ĉi-momente, la sonĝa ĥoraĵo ŝprucigas aplaŭdon);
    $converted = $converter->convert($original);

=head1 DESCRIPTION

6 letters in the Esperanto alphabet did not exist in ASCII.
Their letters, which have supersigns (eo: supersignoj),
are often spelled in substitute notations (eo: surogataj skribosistemoj)
for the history, namely, for the ages of typography and typewriter.
Currently, it is not unusual to spell them in orthography (eo: ortografio)
by the spread of Unicode (eo: Unikodo).
However, there is still much environment
where the input with a keyboard is difficult,
and people may treat an old document described in substitute notation.

This object oriented module provides you a conversion of their notations.

=head2 Caveat

B<This module is on stage of beta release, and the API may be changed.
Your feedback is welcome.>

=head2 Catalogue of notations

The following notation names are usable in
L<new()|/new>, L<add_sources()|/add_sources>, and so on.

I am going to expand an API in the future,
and you will can add notations except them.

=over 4

=item C<orthography>

    Ĉ ĉ Ĝ ĝ Ĥ ĥ Ĵ ĵ Ŝ ŝ Ŭ ŭ

    (\x{108} \x{109} \x{11C} \x{11D} \x{124} \x{125}
     \x{134} \x{135} \x{15C} \x{15D} \x{16C} \x{16D})

It is the I<orthography> of the Esperanto alphabet.
The converter treats letters with supersign, which exist in Unicode.
The character encoding is UTF-8.

You should use the orthography today unless there is some particular reason
because Unicode was spread sufficiently.
Perl 5.8.1 or later also treat it correctly.

I recommend that you treat UTF-8 flagged string in your program throughout and
convert string in only input from external or output to external (on demand),
for to correctly work functions such as C<length()>
in the condition which turns L<utf8|utf8> pragma on.
It is the same as the principle of L<Encode|Encode>
and L<Perl IO layer|perlio>.

=item C<zamenhof>

    Ch ch Gh gh Hh hh Jh jh Sh sh U  u

It is a substitute notation, which places C<h> as a postfix,
however, does not place it for C<u>.

It was suggested by Dr. Zamenhof, the father of Esperanto,
in I<Fundamento de Esperanto>
and people called it I<Zamenhof system> (eo: I<Zamenhofa sistemo>).
For this reason, people also called it I<the second orthography>,
but it is not used very much today.

It has a problem that string which range between roots (such as 'flug/haven/o')
looks like substituted string in several words such as 'flughaveno'
(en: 'airport').
This module does not evade this problem at the present time.

=item C<capital_zamenhof>

    CH ch GH gh HH hh JH jh SH sh U  u

It is a variant of L<'capital_zamenhof' notation|/capital_zamenhof>.

It places a capital C<H> as a postfix of a capital alphabet.

=item C<postfix_h>

    Ch ch Gh gh Hh hh Jh jh Sh sh Uw uw

It is an extended notation of L<'capital_zamenhof' notation|/capital_zamenhof>.

It places C<w> as a postfix of C<u>.

People called it I<H-system> (eo: I<H-sistemo>).

=item C<postfix_capital_h>

    CH ch GH gh HH hh JH jh SH sh UW uw

It is a variant of L<'postfix_h' notation|/postfix_h>.

It places a capital C<H> or C<W> as a postfix of a capital alphabet.

=item C<postfix_x>

    Cx cx Gx gx Hx hx Jx jx Sx sx Ux ux

It is a substitute notation, which places C<x> as a postfix.

People called it I<X-system> (eo: I<X-sistemo, iksa sistemo>).

People widely use it as a substitute notation,
because X does not exist in the Esperanto alphabet,
and was not used except for the case of
to describe non-Esperanto word as the original language.

=item C<postfix_capital_x>

    CX cx GX gx HX hx JX jx SX sx UX ux

It is a variant of L<'postfix_x' notation|/postfix_x>.

It places a capital C<X> as a postfix of a capital alphabet.

=item C<postfix_caret>

    C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U^ u^

It is a substitute notation, which places a caret C<^> as a postfix.

People called it I<caret system> (eo: I<ĉapelita sistemo>).

People often use it as a substitute notation,
because caret have the same shape as circumflex.

This module does not support a way,
which describe C<u~> like C<u^> at the present time.

=item C<postfix_apostrophe>

    C' c' G' g' H' h' J' j' S' s' U' u'

It is a substitute notation, which places an apostrophe C<'> as a postfix.

=item C<prefix_caret>

    ^C ^c ^G ^g ^H ^h ^J ^j ^S ^s ^U ^u

It is a substitute notation, which places a caret C<^> as a prefix.

=back

=head2 Comparison with Lingua::EO::Supersignoj

There is L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj> in CPAN.
It provides us with correspondent functions of this module.

I compare them by the following list:

 Viewpoints                 ::Supersignoj   ::Orthography               Note
 -------------------------- --------------- --------------------------- ----
 Version                    0.02            0.04
 Can convert @lines         Yes             No                          *1
 Have accessors             Yes             Yes, and it has utilities   *2
 Can customize notation     Only 'u'        No (under consideration)    *3
 Can treat 'flughaveno'     No              No (under consideration)    *4
 API language               eo: Esperanto   en: English
 Can convert as N:1         No              Yes                         *5
 Speed                      Satisfied       About 400% faster           *6
 Immediate dependencies     1 (0 in core)   6 (2 in core)               *7
 Whole dependencies         1 (0 in core)   15 (8 in core)              *7
 Test case number           3               93                          *8
 License                    Unknown         Perl (Artistic or GNU GPL)
 Last modified on           Mar. 2003       Mar. 2010

=over 4

=item 1.

To convert C<@lines> with L<Lingua::EO::Orthography|Lingua::EO::Orthography>:

    @converted_lines = map { $converter->convert($_) } @original_lines;

=item 2.

L<Lingua::EO::Orthography|Lingua::EO::Orthography> has utility methods,
what are L<all_sources()|/all_sources>, L<add_sources()|/add_sources> and
L<remove_sources()|/remove_sources()>.

=item 3.

I plan to design the API of this function:

    $converter = Lingua::EO::Orthography->new(
        notations => {
            postfix_asterisk => [qw(C* c* G* g* H* h* J* j* S* s* U* u*)],
        },
    );

    $notations_ref = $converter->notations;

    @notations = $converter->all_notations;

    @notations = $converter->notations({
        postfix_underscore => [qw(C_ c_ G_ g_ H_ h_ J_ j_ S_ s_ U_ u_)],
    });

    $converter->add_notations(
        postfix_diacritics => [qw(C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U~ u~)],
    );

=item 4.

I plan to design the API of this function:

    $converter = Lingua::EO::Orthography->new(
        ignore_words => [qw(
            bushaltejo flughaveno Kinghaio ...
        )],
    );

    $ignore_words_ref = $converter->ignore_words;

    @ignore_words = $converter->all_ignore_words;

    @ignore_words = $converter->ignore_words([qw(kuracherbo)]);

    $converter->add_ignore_words([qw(
        longhara navighalto ...
    )]);

=item 5.

I expect that you may design your practical application
to accept multiple notations, from my experience.

I included an example in the distribution.
L<Lingua::EO::Orthography|Lingua::EO::Orthography> can convert string
into the orthography at once, such as F<examples/converter.pl>.
The correspondent in L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj> is
F<examples/correspondent.pl>.
In this case, you must convert string while you replace source notation.

=item 6.

L<Lingua::EO::Orthography|Lingua::EO::Orthography> can convert string
about 400% faster than L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>.

The reason for the difference is to cache a pattern of regular expression
and a character converting table to replace string, with L<Memoize|Memoize>.
Furthermore, L<Lingua::EO::Orthography|Lingua::EO::Orthography> can
convert characters from multiple notations at once.

See F<examples/benchmark.pl> in this distribution.

=item 7.

The source of dependencies is L<http://deps.cpantesters.org/>.

Such number excludes modules for building and testing.

Any dependencies of L<Lingua::EO::Orthography|Lingua::EO::Orthography> have
a certain favorable opinion.
I quite agree with those recommendation.

But, I consider reducing dependencies.
I already abandon make this module to depend
L<namespace::clean|namespace::clean>,
L<namespace::autoclean|namespace::autoclean>, and so on.

=item 8.

Such number excludes author's tests.

=back

=head1 METHODS

=head2 Constructor

=head3 C<< new >>

    $converter = Lingua::EO::Orthography->new(%init_arg);

Returns a L<Lingua::EO::Orthography|Lingua::EO::Orthography> object,
which is a converter.

Accepts a hash as a converting alignment.
You can assign C<sources> and/or C<target> as key of the hash.

=over 4

=item C<< sources => \@source_notations >>

Accepts an array reference or C<:all>
as source L<notations|/Catalogue of notations>.

C<:all> is equivalent to
L<zamenhof|/zamenhof>,
L<capital_zamenhof|/capital_zamenhof>,
L<postfix_h|/postfix_h>,
L<postfix_capital_h|/postfix_capital_h>,
L<postfix_x|/postfix_x>,
L<postfix_capital_x|/postfix_capital_x>,
L<postfix_caret|/postfix_caret>,
L<postfix_apostrophe|/postfix_apostrophe> and
L<prefix_caret|/prefix_caret>.

If you omit to assign it, the converter consider that
you assign C<:all> to it.

If you assign a value except C<:all> and an array reference,
number of notation elements is 0 or
notations elements has an unknown notation or C<undef>,
the converter throws an exception.

=item C<< target => $target_notation >>

Accepts a string as target L<notation|/Catalogue of notations>.

If you omit to assign it, the converter consider that
you assign L<orthography|/orthography> to it.

If you assign an unknown notation or C<undef>,
the converter throws an exception.

=back

=head2 Accessors

=head3 C<< sources >>

    $source_notations_ref = $converter->sources;

Returns source notations as an array reference.
If you want to get it as a list, you can use L<all_sources()|/all_sources>.

    $source_notations_ref = $converter->sources(\@notations);

Accepts an array reference as source notations.
You can use notations as L<new()|/new> constructor.

Return value is the same as when an argument was not passed.

=head3 C<< target >>

    $target_notation = $converter->target;

Returns target notation as a scalar.

    $target_notation = $converter->target($notation);

Accepts a string as target notation.
You can use notations as L<new()|/new> constructor.

Return value is the same as when an argument was not passed.

=head2 Converter

=head3 C<< convert >>

    $converted_string = $converter->convert($original_string);

Accepts string, convert it, and returns converted string.
Argument string was not polluted by this method, that is to say,
argument string was not changed by side-effect of this method.
A conversion of string is based on notations,
which assigned at L<new()|/new> constructor or
accessors of L<sources()|/sources> and L<target()|/target>.

String are case-sensitive.
That is to say, the converter does not consider C<cX> to substitute notations
in L<'postfix_x' notation|/postfix_x>, and do not convert it.

String of arguments should turn UTF8 flag on.
String of return value also became on.

An URL or an e-mail address may have string,
which was consused itself with substitute notation.
If you do not will convert it, run L<convert()|/convert> each words
after to C<split()> a sentence into words.
This let you that the converter except string, which includes C<://> or C<@>,
from the target of the conversion.
See RFC 2396 and 3986 for URI, and see RFC 5321 and 5322 for e-mail address.
I described a concrete example to
F<examples/ignore_addresses.pl> in the distribution.

=head2 Utilities

=head3 C<< all_sources >>

    @all_source_notations = $converter->all_sources;

Returns source notations as a list.
If you want to get it as an array reference, you can use L<sources()|/sources>.

=head3 C<< add_sources >>

    $source_notations_ref = $converter->add_sources(@adding_notations);

Adds passed notations as a list to source notations.
You can use notations as L<new()|/new> constructor.

Returns source notations as an array reference.

=head3 C<< remove_sources >>

    $source_notations_ref = $converter->remove_sources(@removing_notations);

Removes passed notations as a list from source notations.
You can use notations as L<new()|/new> constructor.

Returns rest source notations as an array reference.

Notations after the removing must maintain at least 1.
If you remove all notations, the converter throws an exception.

=head1 SEE ALSO

=over 4

=item *

L. L. Zamenhof, I<Fundamento de Esperanto>, 1905

=item *

L<http://en.wikipedia.org/wiki/Esperanto_orthography>

=item *

L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>

=item *

L<http://freshmeat.net/projects/eoconv/>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements to
C<< <bug-lingua-eo-orthography at rt dot cpan dot org> >>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Lingua-EO-Orthography>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible, please add as small a sample
as you can make of the code that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    % perldoc Lingua::EO::Orthography

The Esperanto edition of documentation is also available.

    % perldoc Lingua::EO::Orthography::EO

You can also find the Japanese edition of documentation for this module
with the C<perldocjp> command from L<Pod::PerldocJp|Pod::PerldocJp>.

    % perldocjp Lingua::EO::Orthography::JA

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EO-Orthography>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-EO-Orthography>

=item Search CPAN

L<http://search.cpan.org/dist/Lingua-EO-Orthography>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/Lingua-EO-Orthography>

=back

=head1 VERSION CONTROL

This module is maintained using I<git>.
You can get the latest version from
L<git://github.com/gardejo/p5-lingua-eo-orthography.git>.

=head1 CODE COVERAGE

I use L<Devel::Cover|Devel::Cover> to test the code coverage of my tests,
below is the C<Devel::Cover> summary report on this distribution's test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 .../Lingua/EO/Orthography.pm  100.0  100.0  100.0  100.0  100.0  100.0  100.0
 Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 TO DO

=over 4

=item *

More tests

=item *

Less dependencies

=item *

To provide an API to add user's notation

=item *

To correctly treat words such as C<flughaveno> (C<flug/haven/o>)
in L<'postfix_h' notation|/postfix_x> with user's lexicon

=item *

To correctly treat words such as C<ankaŭ>
in L<'zamenhof' notation|/zamenhof> with user's lexicon

=item *

To release a L<Moose|Moose> friendly class
such as C<Lingua::EO::Orthography::Moosified>

=back

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Juerd Waalboer wrote L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>,
which this module refer to.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
