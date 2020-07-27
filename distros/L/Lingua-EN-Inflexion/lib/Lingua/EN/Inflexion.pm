package Lingua::EN::Inflexion;
use 5.010; use warnings;
use Carp;

our $VERSION = '0.002000';

# Import noun, verb, and adj classes...
use Lingua::EN::Inflexion::Term;

sub import {
    my (undef, @exports) = @_;

    # Export interface...
    @exports = qw< noun verb adj inflect wordlist >  if !@exports;

    # Handle renames...
    my %export_name;
    @exports = map { ref eq 'HASH' ? do { @export_name{keys %$_} = values %$_; keys %$_ } : $_ }
                   @exports;

    no strict 'refs';
    for my $func (@exports) {
        *{caller().'::'.($export_name{$func}//$func)} = \&{$func};
    }
}


# Noun constructor...
sub noun ($) {
    my ($noun) = @_;
    return Lingua::EN::Inflexion::Noun->new($noun);
}

# Verb constructor...
sub verb ($) {
    my ($verb) = @_;
    return Lingua::EN::Inflexion::Verb->new($verb);
}


# Verb constructor...
sub adj ($) {
    my ($adj) = @_;
    return Lingua::EN::Inflexion::Adjective->new($adj);
}


# Convert a list of words to...a list of words in a single string...
sub wordlist {
    my (@words, %opt);

    # Unpack the argument list...
    my $sep    = ',';
    my $conj   = 'and';
    for my $arg (@_) {
        my $argtype = ref($arg);

           if ($argtype eq q{})     { push @words, $arg; $sep = ';' if $arg =~ /,/; }
        elsif ($argtype eq q{HASH}) { @opt{keys %$arg} = values %$arg }
        else                        { croak 'Invalid $argtype argument to wordlist' }
    }

    # Fill in defaults...
    $conj = $opt{conj}   // $conj;
    $sep  = $opt{sep}    // $sep;

    # Set the Oxford comma...
    my $oxford = $opt{final_sep} // $sep;

    # Construct the list phrase...
    my $list = @words < 3
                    ? join(" $conj ", @words)
                    : join("$sep ", @words[0..$#words-1]) . "$oxford $conj $words[-1]";

    # Condense any extra whitespace...
    $list =~ s/(\s)\s+/$1/g;

    return $list;
}


# All-in-one inflexions...
my %word_for_number = (
    0 => 'zero',   5 => 'five',
    1 => 'one',    6 => 'six',
    2 => 'two',    7 => 'seven',
    3 => 'three',  8 => 'eight',
    4 => 'four',   9 => 'nine',
                  10 => 'ten',
);

my $normalize_opts = sub {
    my ($opts) = @_;

    if ($opts =~ m{ [[:upper:]] }x) {
        $opts =~ s{ [[:lower:]] }{}gx;
    }
    return lc $opts;
};

sub inflect($) {
    my ($string) = @_;

    my $inflexion = 'singular';

    my $transform = {
        'N'  => sub{
                    my ($term, $opts) = @_;
                    carp "Unknown '$_' option to <N:...> command"
                        for $opts =~ /([^cps])/;

                    my $word = noun($term);
                    $word = $word->classical if $opts =~ /c/i;

                    return $opts =~ /p/i ?  $word->plural
                         : $opts =~ /s/i ?  $word->singular
                         :                  $word->$inflexion;
                },

        'V'   => sub{ return verb(shift)->$inflexion; },

        'A'   => sub{ return adj(shift)->$inflexion; },

        '#' => sub{
                    my ($count, $opts) = @_;
                    $opts =~ s{e}{asw}g;
                    carp "Unknown '$_' option to <#:...> command"
                        for $opts =~ /([^acdefinosw\d])/;

                    # Increment count if requested...
                    if ($opts =~ /i/i) {
                        $count++;
                    }

                    # Decide which inflexion the count requires...
                    $inflexion
                        = $count == 1 || $opts =~ /s/i && $count == 0 || $opts =~ /o/i ? 'singular'
                        :                                                                'plural';

                    # Defer handling of A/AN...
                    if ($count == 1 && $opts =~ /a/i) {
                        return "<#a:>";
                    }

                    my $count_word = $opts =~ /w|o/i ? noun($count) : undef;
                       $count_word = $count_word->classical if $count_word && $opts =~ /c/i;

                    my $count_thresh = $opts =~ /w(\d+)/i ? $1 : 11;

                    # Otherwise, interpolate count or its equivalent (deferring fuzzies)...
                    return $opts =~ /n|s/i && $count == 0  ?  'no'
                         : $opts =~ /w/i && $opts =~ /o/i  ?  $count_word->ordinal($count_thresh)
                         : $opts =~ /w/i                   ?  $count_word->cardinal($count_thresh)
                         : $opts =~ /o/i                   ?  $count_word->ordinal(0)
                         : $opts =~ /f/i                   ?  "<#f:$count>"
                         : $opts =~ /d/                    ?  q{}
                         :                                    $count;
               },
    };

    # Inflect markups...
    $string =~ s{ (?<ORIG>
                    < (?<FUNC> (?-i: [#NVA] ) )  # FUNC is case-sensitive
                      (?<OPTS> [^:]* ) \s*
                    : \s* (?<TERM> [^>]+? ) \s*
                    >
                    (?<TWS> \s* )
                  )
                }{
                    my %parsed = %+;
                    my $opts = $normalize_opts->($parsed{OPTS});
                    my $func = $transform->{ uc $parsed{FUNC} } // sub{shift};
                    my $replacement = $func->( $parsed{TERM}, $opts );
                    length $replacement > 0 ? $replacement . $parsed{TWS} : q{}
                }gexmsi;

    # Inflect consequent A/AN's...
    $string =~ s{ <[#]a:> \s*+ (?<next_word> \S++) }{ noun($+{next_word})->indefinite }gxe;
    $string =~ s{ <[#]a:> \s*+ \Z }{ "a" }xe;

    # Inflect fuzzies...
    state $fuzzy = sub {
        my ($count, $is_postfix) = @_;

        return $count >= 10 ? 'many'
             : $count >=  6 ? 'several'
             : $count >=  3 ? 'a few'
             : $count ==  2 ? 'a couple' . ($is_postfix ? q{} : ' of')
             : $count ==  1 ? 'one'
             :                ($is_postfix ? 'none' : 'no')
             ;
    };

    $string =~ s{ <\#f: (?<count> \d++) > (?= \s*+ [[:alpha:]]) }
                { $fuzzy->($+{count}) }gxe;
    $string =~ s{ <\#f: (?<count> \d++) > (?= [^[:alpha:]]*+ \Z) }
                { $fuzzy->($+{count}, 'postfix') }xe;

    # And we're done...
    return $string;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lingua::EN::Inflexion - Inflect English nouns, verbs, adjectives, and articles


=head1 VERSION

This document describes Lingua::EN::Inflexion version 0.002000


=head1 SYNOPSIS

    use Lingua::EN::Inflexion qw< noun inflect wordlist >;

    # Request a search term, and treat it as a noun object...
    my $search_term   = prompt("Enter something to search for");
    my $search_target = noun($search_term);

    # Search number-insensitively (as a qr/PLURAL|SINGULAR/ regex)...
    my @matches = search($search_target->as_regex);

    # Inflect it to correct English...
    #    "0 indexes were found"
    #    "1 index was found"
    #    "99 indexes were found"
    my $search_result
        = inflect("<#i:$#matches> <N:indexes> <V:were> found");

    # Inflect it to even better English...
    #    "no index was found"
    #    "one index was found"
    #    "99 indices were found"
    my $search_outcome
        = inflect("<#wnci:$#matches> <Nc:index> <V:was> found");

    # Generate properly formatted lists of words and phrases...
    my $list = wordlist(@words);


=head1 DESCRIPTION

Lingua::EN::Inflexion allows you to correctly inflect all
English nouns and verbs, as well as the small number of adjectives
and articles that still decline in modern English.

By default, the module follows the conventions of modern formal British
English (i.e. OED and Fowler's), but also attempts to support other
dialects as far as possible. The rules of inflexion it uses are almost
entirely table-driven (see L<"CONFIGURATION">), so they can easily be
adapted for local requirements if necessary.

Where an English noun has both a modern and a classical/unassimilated
plural form (e.g. "maximums" and "maxima", "indexes" and "indices",
"librettos" and "libretti"), the module favours the modern inflexion,
unless the older form is specifically requested
(see L<"classical() and unassimilated()">).

In the few cases where a word has two or more singular inflexions (e.g.
plural "bases" to singular "base" or "basis") or is otherwise ambiguous
(e.g. plural "opera" to singular "opus" vs singular "opera" to plural
"operas"), the module provides a best guess about the more common usage.
These guesses can be changed by rearranging the source tables
(see L<"Rebuilding the module">).


=head1 INTERFACE

By default, the module exports five subroutines: C<noun()>, C<verb()>,
C<adj()>, C<wordlist()>, and C<inflect()>.

The first three are constructors for objects representing nouns, verbs,
or adjectives respectively. These I<"inflexion objects"> then provide a
selection of methods allowing each term to be appropriately inflected.

The C<wordlist()> subroutine takes a list of words or phrases, and some
optional configuration arguments, and formats the list into a single
English phrase, with commas between the elements and a conjunction
before the last.

The C<inflect()> subroutine is a general tool for constructing correctly
inflected sentences from uninflected components, using string
interpolation and a simple mark-up language.

As usual, you can also explicitly import a subset of these subroutines:

    use Lingua::EN::Inflexion qw( noun verb );

or you can import (some of) them under different names, by specifying
the name mappings in one or more hashes:

    use Lingua::EN::Inflexion
        'inflect',                     # imported as: inflect()
        {
          'noun' => 'substantive',     # imported as: substantive()
          'verb' => 'doing_word',      # imported as: doing_word()
        },
        { 'adj'  => 'descriptive' }    # imported as: descriptive()


=head2 Common methods shared by all inflexion objects

The C<noun()>, C<verb()>, and C<adj()> methods each return an
object representing an instance of that part of speech. In addition
to their type-specific interfaces, all those inflexion objects share the
following set of common methods, none of which takes an argument:

=over

=item  C<< is_noun() >>

=item  C<< is_verb() >>

=item  C<< is_adj() >>

Returns true if the inflexion object represents the corresponding part
of speech. Shorter and quicker than calling:

    $term->isa('Lingua::EN::Inflexion::Noun')
    $term->isa('Lingua::EN::Inflexion::Verb')
    $term->isa('Lingua::EN::Inflexion::Adjective')


=item  C<< is_singular() >>

=item  C<< is_plural() >>

Returns true if the invocant represents a term of the
corresponding grammatical number.

Note that the same inflexion object may return true for I<both> of these
calls, if the term it represents is uninflected. For example:

    noun('fish')->is_singular     # true
    noun('fish')->is_plural       # true

    verb('can')->is_singular      # true
    verb('can')->is_plural        # true

    adj('typical')->is_singular   # true
    adj('typical')->is_plural     # true


=item  C<< singular( $optional_person ) >>

=item  C<< plural( $optional_person ) >>

Returns a string representing the corresponding inflexion of the term
represented by the invocant. For example:

    say noun('feet')->singular;    # "foot"

    say verb('is')->plural;        # "are"

    say adj("our")->singular;      # "my"

If the optional argument is provided, it must be an integer between 1
and 3, which specifies the grammatical "person" (1st , 2nd, or 3rd)
that is wanted. Very few English nouns and adjectives are inflected
by person, so this option only affects personal and possessive pronouns,
possessive adjectives, and verbs:

    say noun('she')->singular;      # "she"
    say noun('she')->singular(1);   # "I"
    say noun('she')->singular(2);   # "you"
    say noun('she')->singular(3);   # "she"

    say verb('am')->singular;       # "am"
    say verb('am')->singular(1);    # "am"
    say verb('am')->singular(2);    # "are"
    say verb('am')->singular(3);    # "is"

    say adj("my")->plural;       # "our"
    say adj("my")->plural(1);    # "our"
    say adj("my")->plural(2);    # "your"
    say adj("my")->plural(3);    # "their"

Note that, without the argument, the method always
attempts to preserve the original person of the term:

    say verb('am')->singular;       # "am"
    say verb('are')->singular;      # "are"
    say verb('is')->singular;       # "is"

Also note that, where a plural noun or adjective has multiple 3rd-person
singular forms, the method always prefers the gender neutral form:

    say noun("they")->singular;     # "it"  (not "she" or "he")
    say adj("our")->singular(3);    # "its" (not "hers" or "his")


=item  C<< classical() >> or C<< unassimilated() >>

This is a single method with two alternative names. It returns an
inflexion object representing the term, but which thereafter always
inflects in the classical/unassimilated maner. For example:

    say noun('brother')->plural;             # "brothers"
    say noun('brother')->classical->plural;  # "brethren"

Note that most terms have only a single plural form, in which
case the resulting classical inflexion object will just
return the single plural form anyway. In fact, in such cases,
the module may choose to have C<classical()> return the same
object as it was called on.


=item  C<< as_regex() >>

Returns a C<qr>'d regex object which would match (case-insensitively)
any inflected form of the word. For example:

    $word =~ noun('cherub')->as_regex   # qr/cherubs|cherubim|cherub/i

    $word =~ verb('eat')->as_regex      # qr/eats|eating|eaten|eat|ate/i

=back

=head3 Regex and string coercions

In Perl 5.12 or later, the C<< as_regex() >> method is called
automatically if an inflexion object is used anywhere a regex is
expected. So the previous example could also have been written as:

    $word =~ noun('cherub')             # qr/cherubs|cherubim|cherub/i

If an inflexion object is used as a string, it is coerced back the
original string from which the object was built:

    say noun("indices");                # prints: "indices"
    say verb("explains");               # prints: "explains"

If you want a particular inflexion of the original word, ask for it
explicitly:

    say noun("indices")->singular;      # prints: "index"
    say verb("explains")->plural;       # prints: "explain"


=head3 Smartmatching inflexion objects

If two inflexion objects are smartmatched, the operation
compares the two objects' singular, plural, and classical
plural inflexions, and returns true if any one pair of
inflexions matches (case-insensitively).

That is:

    noun($word1) ~~ noun($word2)

is just a shorthand for:

       lc(noun($word1)->singular)          eq lc(noun($word2)->singular)
    || lc(noun($word1)->plural)            eq lc(noun($word2)->plural)
    || lc(noun($word1)->classical->plural) eq lc(noun($word2)->classical->plural)


If an inflexion object is smartmatched against anything else, the
inflexion object is converted to a regex, which is then smartmatched
against the other argument.

That is:

    $something_else ~~ noun($word1)
       noun($word1) ~~ $something_else

are just slightly shorter (and less order-specific) ways of writing:

    $something_else =~ noun($word1)->as_regex;

Note that the behaviour of smartmatched inflexion objects, together with
the regex and string coercions described earlier, collectively means
that there are significant differences between:

    $word1 =~ noun($word2)         # $word1 matches any inflexion of $word2
    $word1 ~~ noun($word2)         # (ditto)

    noun($word1) =~ $word2         # $word1 matches $word2 exactly

    noun($word1) ~~ $word2         # any inflexion of $word1 matches $word2

    noun($word1) ~~ noun($word2)   # $word1 and $word2 match in at least
                                   # one of their inflexions

Choose the appropriate form of matching for the type and degree of
number-insensitivity you need.


=head3 Other coercions on inflexion objects

All other attempts to coerce an inflexion object to a value
(i.e. to a boolean or a number) fall back to the normal built-in
behaviour for Perl objects. That is: inflexion objects are always true,
and always numerify to their own memory address.

Any attempt to coerce an inflexion object to a reference produces
an exception.


=head2 The C<< noun() >> constructor and associated methods

The C<noun()> subroutine takes a single argument: a string containing
a noun or noun phrase. It returns an inflexion object representing
that noun:

    my $noun_obj = noun($string);

The subroutine is just a convenient wrapper around a constructor,
which you can call directly if you prefer:

    my $noun_obj = Lingua::EN::Inflexion::Noun->new($string);

Noun objects provide six extra methods in addition to the common methods
described above...

=head3 C<< indef_article() >>

This method takes a no argument and returns either the string C<'a'> or
the string C<'an'>, depending on which form of indefinite article the
singular inflexion of that particular word requires.

Thus:

    noun("uncle")->indef_article();    # "an"
    noun("union")->indef_article();    # "a"
    noun("house")->indef_article();    # "a"
    noun("hours")->indef_article();    # "an"


=head3 C<< indefinite($count = 1) >>

This method takes a single argument: an optional integer count
(which defaults to 1).

If the count value is 1, the method returns a string containing the
singular form of the noun with the appropriate indefinite article
(either "a" or "an") prepended.

If the count is not 1, the method returns a string containing the
plural form of the noun with the count value itself prepended.

Thus:

                                    #   $N = 0      $N = 1      $N = 2
                                    #
    noun("uncle")->indefinite($N);  # "0 uncles", "an uncle", "2 uncles"
    noun("union")->indefinite($N);  # "0 unions",  "a union", "2 unions"
    noun("house")->indefinite($N);  # "0 houses",  "a house", "2 houses"
    noun("hours")->indefinite($N);  # "0 hours",  "an hour",  "2 hours"


=head3 C<< cardinal() >> and C<< cardinal($threshold) >>

Convert the word into the English word for a cardinal number, using the
Lingua::EN::Nums2Words module (which must be installed or an exception
is thrown). If the C<$threshold> argument is supplied and the word
represents a number greater than or equal to that value, then word is
converted to digits instead.

For example:

    noun( 1)->cardinal;      # "one"
    noun(10)->cardinal;      # "ten"
    noun(11)->cardinal(20);  # "eleven"
    noun(21)->cardinal(20);  # "21"

The word is also converted if it is an English phrase representing
a valid number (via the Lingua::EN::Words2Nums module, which must
be installed or an exception is thrown):

    noun("one")->cardinal;                             # "one"
    noun("ten")->cardinal;                             # "ten"
    noun("eleven")->cardinal(20);                      # "eleven"
    noun("one hundred and twenty-one")->cardinal(20);  # "121"

Words that are ordinal numbers are also correctly converted:

    noun("first")->cardinal;  # "one"
    noun("142nd")->cardinal;  # "one hundred and forty-two"

Words that cannot be interpreted as numbers are treated as zero:

    noun("eon")->cardinal;    # "zero"
    noun("elven")->cardinal;  # "zero"


=head3 C<< ordinal() >> and C<< ordinal($threshold) >>

Convert the word into the English word for an ordinal number, using the
Lingua::EN::Nums2Words module (which must be installed or an exception
is thrown). If the C<$threshold> argument is supplied and the word
represents a number greater than or equal to that value, then word is
converted to digits instead.

For example:

    noun( 1)->ordinal;      # "first"
    noun(10)->ordinal;      # "tenth"
    noun(11)->ordinal(20);  # "eleventh"
    noun(21)->ordinal(20);  # "21st"

The word is also converted if it is an English phrase representing
a valid number (via the Lingua::EN::Words2Nums module, which must
be installed or an exception is thrown):

    noun("one")->ordinal;                             # "first"
    noun("ten")->ordinal;                             # "tenth"
    noun("eleven")->ordinal(20);                      # "eleventh"
    noun("one hundred and twenty-one")->ordinal(20);  # "121st"

Words that are ordinal numbers are also correctly converted:

    noun("first")->ordinal;     # "first"
    noun("142nd")->ordinal;     # "one hundred and forty-second"
    noun("first")->ordinal(0);  # "1st"
    noun("142nd")->ordinal(0);  # "142nd"

Words that cannot be interpreted as numbers are treated as zero:

    noun("eon")->ordinal;       # "zeroth"
    noun("elven")->ordinal;     # "zeroth"


=head2 The C<< verb() >> constructor and associated methods

The C<verb()> subroutine takes a single argument: a string containing a
simple verb in the present tense (singular or plural). It returns an
inflexion object representing that verb.

    my $verb_obj = verb($string);

Like C<noun()>, it's just a convenient shorthand for:

    my $verb_obj = Lingua::EN::Inflexion::Verb->new($string);

Verb objects provide eight extra methods (in addition to the common
methods described earlier)...

=head3 C<< past() >>

This method takes no arguments. It returns a string containing
the simple past tense (preterite) inflexion of the verb.

For example:

    say verb("bat")->past;   # "batted"
    say verb("sit")->past;   # "sat"
    say verb("eat")->past;   # "ate"


=head3 C<< pres_part() >>

This method takes no arguments. It returns a string containing
the present participle of the verb.

For example:

    say verb("bat")->pres_part;   # "batting"
    say verb("sit")->pres_part;   # "sitting"
    say verb("eat")->pres_part;   # "eating"


=head3 C<< past_part() >>

This method takes no arguments. It returns a string containing
the past participle of the verb.

For example:

    say verb("bat")->past;   # "batted"
    say verb("sit")->past;   # "sat"
    say verb("eat")->past;   # "eaten"


=head3 C<< is_present() >>

=head3 C<< is_past() >>

=head3 C<< is_pres_part() >>

=head3 C<< is_past_part() >>

These methods return true when the original verb from which the
inflexion object was constructed is in the appropriate tense
(present or simple past) or is the appropriate participle.

For example

    if (verb("sat")->is_present)   {...}   # false
    if (verb("sat")->is_past)      {...}   # true
    if (verb("sat")->is_pres_part) {...}   # false
    if (verb("sat")->is_past_part) {...}   # true


=head3 C<< indefinite($count = 1) >>

This method takes a single argument: an optional integer count
(which defaults to 1).

If the count value is 1, it returns the singular inflexion of the
verb. If the count is any other numeric value, it returns the
plural inflexion.


=head2 The C<< adj() >> constructor and associated methods

The C<adj()> subroutine takes a single argument: a string containing
a simple adjective. It returns an inflexion object representing that
adjective:

    my $adj_obj = adj($string);

Like C<noun()> and C<verb()>, it's just an abbreviation for:

    my $adj_obj = Lingua::EN::Inflexion::Adjective->new($string);

Adjective objects provide no methods except the common methods
described previously.


=head2 Sentence inflexions via the C<< inflect() >> subroutine

The OO nature of the Lingua::EN::Inflexion API makes it clean,
extensible, and robust. But does not make it easy to use in
the most common case:

    # Do the search...
    my $target = noun($word);
    my @results = search_for($target->as_regex);

    # Do some grammar...
    my $target_s = @results==1 ? $target->singular : $target->plural;
    my $was_were = @results==1 ? 'was'             : 'were';

    # Report the results...
    say @results . " $target_s $was_were found";

So Lingua::EN::Inflexion also provides a single subroutine that implements
a basic markup language to simplify the task:

    # Do the search...
    my @results = search_for( noun($word)->as_regex );

    # Report the results...
    say inflect "<#i:$#results> <N:$word)> <V:was> found";

The C<inflect()> subroutine takes a single string argument and
replaces any nested markups (in angle brackets) with the appropriate
inflexions of their contents. It then returns the inflected string.

The markup notation always takes the form: C<< <Xopts:content> >>
where C<X> is a command (either C<N> or C<V> or C<A> or C<#>),
C<opts> represents zero or more options for the command,
and C<content> is the data on which to apply the command (normally
a word or phrase to be inflected).

The four commands currently supported are:

=head3 C<< <#: I<integer> > >>

This markup sets the current count, which is used by which subsequent
markups in the string to chose whether to inflect their contents in the
singular (if the count is 1) or the plural (otherwise). The markup
itself is normally replaced with the integer specified or with
something equivalent, depending on the particular options used.

The options for this command are:

=over

=item C<n>

If the count equals zero, interpolate "no" into the string instead of the
actual count. For example:

    say inflect "<#n:$count> <N:results>";
              # "no results"   if $count == 0
              # "7 results"    if $count == 7

I<Mnemonic:> C<n> for "no" or "nil's not numeric".


=item C<s>

If the count equals zero, interpolate "no" into the string instead of
the actual count...and also inflect any subsequent nouns and verbs in
the singular. That is, the same word replacement as for the C<n> option,
but treating zero as singular, not plural:

    say inflect "<#n:$count> <N:item> <V:were> found";
              # "no items were found"

    say inflect "<#s:$count> <N:item> <V:were> found";
              # "no item was found"

I<Mnemonic:> C<s> for "singular" or "sophisticated" or "snooty".


=item C<a>

If the count equals one, interpolate "a" or "an" into the string instead
of the actual count. For example:

    say inflect "<#a:$count> <N:results>";
              # "a result"    if $count == 1
              # "3 results"   if $count == 3

    say inflect "<#a:$count> <N:outcomes>";
              # "an outcome"  if $count == 1
              # "3 outcomes"  if $count == 3

I<Mnemonic:> C<a> for "a" and "an", or "article".


=item C<w>

If the count is small (between zero and ten), interpolate the
appropriate English word instead of the number:

    say inflect "<#w:$count> <N:results>";
              # "six results"  if $count == 6
              # "ten results"  if $count == 10
              # "11 results"   if $count == 11

Note that this option is overridden by the special case behaviours of
both the C<n> and C<a> options, if either is also specified.

I<Mnemonic:> C<w> for "wordy" or "written-out".


=item C<w>I<N>

The C<w> option can also be followed by one or more digits, in which
case if the count is less than that number, the appropriate English word
is interpolated instead of the number:

    say inflect "<#w20:$count> <N:results>";
              # "six results"      if $count == 6
              # "nineteen results" if $count == 19
              # "20 results"       if $count == 20

In all other respects this variant behaves exactly like a regular C<w>
option, as described in the previous item.


=item C<o>

Display the count as an ordinal:

    say inflect "<#o:$count> <N:results>";
              # "1st result"   if $count == 6
              # "11th result"  if $count == 11
              # "22nd result"  if $count == 22

Note that, in keeping with English usage, under the C<o> option, the
effective count is set to 1, rather than the actual number provided.

When this option is combined with the C<w> option, the ordinal is
converted to words:

    say inflect "<#ow:$count> <N:results>";
              # "first result"  if $count == 6
              # "tenth result"  if $count == 10
              # "11th result"   if $count == 11

Note that this option is overridden by the special case behaviours of
both the C<n> and C<a> options, if either is also specified.

I<Mnemonic:> C<o> for "ordinal" or "ordered".


=item C<f>

Set the count, but instead of interpolating the number, interpolate
a phrase summarizing the general amount represented by that number.

For example:

    say inflect "Found <#f:$count> <N:matches>";
              # "Found no matches"           if $count == 0
              # "Found one match"            if $count == 1
              # "Found a couple of matches"  if $count == 2
              # "Found a few matches"        if $count ~~ 3..5;
              # "Found several matches"      if $count ~~ 6..9;
              # "Found many matches"         if $count >= 10

If the C<#> markup is at the end of the string (i.e. is not followed
by an alphabetic character), the phrases used are slightly different:

    say inflect "Searching for <Np:$target>.....found <#f:$count>.";
              # "Searching for 'items'.....found none."
              # "Searching for 'items'.....found one."
              # "Searching for 'items'.....found a couple."
              # "Searching for 'items'.....found a few."
              # "Searching for 'items'.....found several."
              # "Searching for 'items'.....found many."

The C<s> and C<a> options override the wording for counts of
zero or one:

    say inflect "Found <#fs:$count> <N:matches>";
              # "Found no match"             if $count == 0
              # "Found several matches"      if $count == 7

    say inflect "Found <#fa:$count> <N:matches>";
              # "Found a match"              if $count == 1
              # "Found several matches"      if $count == 7

I<Mnemonic:> C<f> for "fuzzy" or "friendly" or "few".


=item C<e>

You can combine multiple count options to obtain more
sophisticated effects. A particularly elegant combination is:

    say inflect "<#asw:$count> <N:matches> <V:were> found";
              # "no match was found"      if $count == 0
              # "a match was found"       if $count == 1
              # "ten matches were found"  if $count == 10
              # "12 matches were found"   if $count == 12

This set of options is useful, but bordering on ponderous, so there is
an abbreviation for it:

    say inflect "<#e:$count> <N:matches> <V:were> found";

I<Mnemonic:> C<e> for "eloquent" or "editorial expansion" or "erudite"
(or possibly: "elitist").


=item C<i>

Increment the supplied integer I<before> setting it as the current count
or interpolating it back into the string. This is useful if you have
an array of results and would like to interpolate its size as the
current count.

For example, instead of:

    my $count = scalar(@results);
    say inflect "<#:$count> <N:matches> <V:were> retrieved";

or (even more hideously):

    say inflect "<#:${\(@results)}> <N:matches> <V:were> retrieved";

you can just use:

    say inflect "<#i:$#results> <N:matches> <V:were> retrieved";

I<Mnemonic:> C<i> for "increment" or "its intrinsic index is insufficient; increase it".


=item C<d>

Set the current count definition, without displaying anything in place
of the markup.

This is useful for constructions that either do not mention the count
explicitly:

    say inflect "<#d:$count> <N:Match> found";
              # "Match found"           if $count == 1
              # "Matches found"         if $count > 1

or in constructions where the count has to appear I<after> something
whose inflexion it controls:

    say inflect "There <#d:$count> <V:were> $count <N:matches>";
              # "There was 1 match"     if $count == 1
              # "There were 7 matches"  if $count > 1

The C<a>, C<n>, and C<c> options override C<d>, so you can still be
specific when the count is less than two:

    say inflect "<#asd:$count> <N:matches> <V:were> found";
              # "no match was found"    if $count == 0
              # "a match was found"     if $count == 1
              # "matches were found"    if $count > 1

I<Mnemonic:> C<d> for "don't display" or "disguised definition" or "delete".

=back


=head3 C<< <N: I<contents> > >>

This markup inflects its contents as a noun. That is, the markup is
replaced with C<< noun('contents')->singular >> or
C<< noun('contents')->plural >> depending on the value specified
by the most recent preceding C<< <#:...> >> markup.

This command takes three options:

=over

=item C<c>

Cause the noun inflexion to use C<< noun('contents')->classical >>:

    say inflect "<#:$count> <N:$target> found";
              # "7 maximums found"
              # "7 formulas found"
              # "7 corpuses found"
              # "7 brothers found"

    say inflect "<#:$count> <Nc:$target> found";
              # "7 maxima found"
              # "7 formulae found"
              # "7 corpora found"
              # "7 brethren found"

I<Mnemonic:> C<c> for "classical" or "cultured" or "conformatio Caesaris cascus".


=item C<p>

Causes the noun to inflect to the plural, regardless of the currently
active count (i.e. regardless of the actual value specified in any
preceding C<< <#:...> >>.

This is sometimes useful for constructions such as:

    say inflect "Searching for <Np:$target>.....found $count";
              # "Searching for walruses...found 1"
              # "Searching for appendixes...found 4"
              # "Searching for denarii...found 12742"

I<Mnemonic:> C<p> for "plural" or "plentiful" or "plethora".


=item C<s>

Causes the noun to inflect to the singular, regardless of the currently
active count (i.e. regardless of the value in any preceding C<< <#:...> >>.

This is sometimes useful for constructions such as:

    say inflect "Searching for <#a:> <Ns:$target>.....found $count";
              # "Searching for a walrus...found 1"
              # "Searching for an appendix...found 4"
              # "Searching for a denarius...found 12742"

I<Mnemonic:> C<s> for "singular" or "solitary" or "solo".

=back

=head3 C<< <V: I<contents> > >>

This markup inflects its contents as a verb. That is, the markup is
replaced with C<< verb('contents')->singular >> or
C<< verb('contents')->plural >> depending on the value specified
by the most recent preceding C<< <#:...> >> markup.

This command has no options.


=head3 C<< <A: I<contents> > >>

This markup inflects its contents as an adjective. That is, the markup
is replaced with C<< adj('contents')->singular >> or
C<< adj('contents')->plural >> depending on the value specified by the
most recent preceding C<< <#:...> >> markup.

This command has no options.


=head3 Long-form markup notation

Every command in the C<inflect()> markup language is a single
uppercase letter. Every option is a single lowercase letter.
That's useful because it keeps markup relatively concise:

    say inflect "<#anw:$count> <Nc:$target> <V:were> found";

but it's also a problem because it makes the meaning of each
markup hard to remember six months later. So C<inflect()>
also allows you to specify options with complete words, like so:

    say inflect "<#AnNoWords:$count> <NounClassical:$target> <Verb:were> found";

That is: C<inflect()> allows the words C<Noun>, C<Verb>, and C<Adj> as
synonyms for the commands C<N>, C<V>, and C<A> respectively.

And if C<inflect()> encounters a markup where the options section contains
any uppercase letters, it ignores any lowercase letters within the options,
and then converts the uppercase letters to lowercase and uses those as its
options. Thus:

    say inflect "<#AnNoWords:$count> <NounClassical:$target> <Verb:were> found";

first maps the full command names back to the one-letter versions:

    say inflect "<#AnNoWords:$count> <N   Classical:$target> <V   :were> found";

then removes the lowercase letters from the options:

    say inflect "<#A N W    :$count> <N   C        :$target> <V   :were> found";

and finally converts what's left to lowercase:

    say inflect "<#a n w    :$count> <N   c        :$target> <V   :were> found";


=head2 Converting lists of words to phrases

When creating a list of words, commas are used between adjacent items,
except if the items contain commas, in which case semicolons are used.
But if there are less than three items, the commas/semicolons are omitted
entirely. The final item also has a conjunction (usually "and" or "or")
before it. And although it's often misleading , some people prefer to
omit the comma before that final conjunction, even when there are more
than two items.

That's complicated enough to warrant its own subroutine: C<wordlist()>.
This subroutine expects a list of words, possibly with one or more hash
references containing options. It returns a string that joins the list
together in the normal English usage. For example:

    print "You chose ", wordlist(@selected_items), "\n";
    # You chose barley soup, roast beef, and Yorkshire pudding

    print "You chose ", wordlist(@selected_items, {final_sep=>""}), "\n";
    # You chose barley soup, roast beef and Yorkshire pudding

    print "Please choose ", wordlist(@side_orders, {conj=>"or"}), "\n";
    # Please choose salad, vegetables, or ice-cream

The available options are:

    Option named    Specifies                Default value

    conj            Final conjunction        "and"
    sep             Inter-item separator     "," or ";"
    final_sep       Final separator          value of 'sep' option


=head1 CONVERTING FROM LINGUA::EN::INFLECT

This module is the successor to the original Lingua::EN::Inflect module.
The following tables summarize how to convert code from the old interface
to the new.

    Lingua::EN::Inflect subroutines         Lingua::EN::Inflexion code
    ====================================================================
    PL($word)                               # No equivalent
    --------------------------------------------------------------------
    PL_N($word)                             noun($word)->plural
    PL_V($word)                             verb($word)->plural
    PL_ADJ($word)                           adj($word)->plural
    --------------------------------------------------------------------
    NO($word)                               # No equivalent
    NUM($word)                              # No equivalent
    --------------------------------------------------------------------
    A($word)                                noun($word)->indefinite
    AN($word)                               noun($word)->indefinite
    --------------------------------------------------------------------
    PL_eq($word1, $word2)                   # No equivalent
    --------------------------------------------------------------------
    PL_N_eq($word1, $word2)                 noun($word1) ~~ noun($word2)
    PL_V_eq($word1, $word2)                 verb($word1) ~~ verb($word2)
    PL_ADJ_eq($word1, $word2)               adj($word1) ~~ adj($word2)
    --------------------------------------------------------------------
    PART_PRES($word)                        verb( $word )->pres_part
    --------------------------------------------------------------------
    ORD($word)                              noun( $word )->ordinal
    NUMWORDS($word)                         noun( $word )->cardinal
    --------------------------------------------------------------------
    WORDLIST(@words, \%opts)                wordlist( @words, \%opts)


    Lingua::EN::Inflect::inflect()          Lingua::EN::Inflexion::inflect()
    ========================================================================
    "PL($word)"                             # No equivalent
    ------------------------------------------------------------------------
    "PL_N($word)"                           "<N:$word>"
    "PL_V($word)"                           "<V:$word>"
    "PL_ADJ($word)"                         "<A:$word>"
    ------------------------------------------------------------------------
    "NUM($num)"                             "<#:$num>"
    "NO($word)"                             "<#n:$num>"
    ------------------------------------------------------------------------
    "A($word)"                              "<#a:$num> N<$word>"
    "AN($word)"                             "<#a:$num> N<$word>"
    ------------------------------------------------------------------------
    "PART_PRES($word)"                      # No equivalent
    ------------------------------------------------------------------------
    "ORD($word)"                            "<No:$word>"
    "NUMWORDS($word)"                       "<Nw:$word>"


=head1 LINGUISTIC ABYSSES

No further correspondence will be entered into on the topics of...

=head2 "octopi"

Yes, many people use it.
No, it isn't correct English...nor correct Latin...nor correct Greek.
Yes, there actually I<is> a classical Latin precedent for the inflexion.
No, that precedent isn't relevant to English, because "octopus" didn't come from classical Latin, or even I<via> classical Latin.
Yes, this module recognizes the word and will correctly inflect it back to "octopus" in the singular.
No, the module will never inflect "octopus" to "octopi".


=head2 "octopodes"

Yes, very few people use it (and almost only ever when raging against "octopi").
No, it isn't correct English...nor was it ever used in classical Latin.
Yes, there certainly I<is> a ancient Greek precedent for the inflexion.
No, that precedent isn't relevant to English, because "octopus" didn't come from ancient Greek either.
Yes, this module recognizes the word and will correctly inflect it back to "octopus" in the singular.
No, the module will never inflect "octopus" to "octopodes".


=head2 "octopuses"

For a thorough, erudite, and eminently satisfying explanation of why
it's only ever been "octopuses", I can sincerely recommend:
L<http://web.archive.org/web/20170112234148/http://www.heracliteanriver.com/?p=240>


=head2 "viri" and "virii"

The noun "virus" had no plural in its original Latin (probably because
it was a mass noun). So the only plural in English is the natural one:
"viruses".

Nevertheless, this module will do the right thing when asked to inflect
"viri" and "virii" back to the singular (unless you happen to think that
the right thing would be to beat them to death with a stick).


=head2 Singular "they", "them", "their", and "theirs"

...were good enough for Auden, Austen, Byron, Carroll, Caxton, Chaucer,
Defoe, Dickens, Eliot, Fitzgerald, Gaskell, Kipling, Orwell, Ruskin,
Scott, Shakespeare, Shaw, Shelley, Sheridan, Spenser, Stevenson, Swift,
Thackeray, Trollope, Wells, Wharton, and Wilde...so they're good enough
for this module.

In fact, it wasn't until the 19th Century that maniacal neo-Latinizing
prescriptive grammarians started pillorying the use of gender-neutral
singular "they" I<etc.> in English.

Meanwhile, real people have kept right on using it for the past two
hundred years, just as they did for the preceding five hundred.
And the OED now actually prefers "they" to "he" for gender-nonspecific
usages.

So if someone wants to complain about this module supporting--and
even favouring--the usage, I<they> are most welcome to write I<their>
own module as best suits I<them>.


=head2 Singular "themself"

Despite the fact that "themself" has been in use for nearly 500 years,
and actually predates "themselves", the word is not considered
acceptable in modern English, and certainly not as a singular form.

Eventually it may garner the same general acceptance as singular "they",
"them", and "their"...but not yet. Although one may encounter such
gender-nonspecific constructions as:

V<    >"Anyone might find B<themself> contemplating their own mortality."

the correct formulation is still:

V<    >"Anyone might find B<themselves> contemplating their own mortality."

The module does recognize "themself" as a reflexive pronoun, but
converts it to the currently accepted form ("themselves") for both
singular and plural inflexions.


=head2 "inflexion"

It's exactly the same thing as "inflection".
I simply find the classical spelling more elegant.


=head1 DIAGNOSTICS

=over

=item C<< Missing arg to %s >>

You passed an C<undef> as the single argument to C<noun()>, C<verb()>,
or C<adj()>. They require a string instead.


=item C<< Can't coerce %s object to %s reference >>

Inflexion objects can convert themselves to strings, or numbers, or booleans,
or regexes, but not to references.

You didn't accidentally write something like:

    $inflexion_obj->{plural}   # Should be: $inflexion_obj->plural

...did you?

=back


=head1 CONFIGURATION AND ENVIRONMENT

Lingua::EN::Inflexion has no run-time configuration files or environment
variables.

However, the module itself is largely created from two tables of
inflexions (for nouns and verbs respectively).


=head2 The F<nouns.lei> file

All the noun inflexions that Lingua::EN::Inflexion provides are
generated from a single file: F<nouns.lei>.

=head3 File format

The format of each entry in this file is as follows:

    SINGULAR NOUN   =>   MODERN PLURAL FORM  |  CLASSICAL FORM

Either the modern plural or the classical plural--but not
both--may be omitted. If the classical plural is omitted,
the C<|> is not required (but is still allowed).

Normal Perl comments (introduced by a C<#>) may also be included,
and will be ignored.

Each singular or plural form can consist of any number of words.

For example:

    man             =>   men
    minimum         =>   minimums        | minima
    mitochondrian   =>                   | mitochondria
    malum in se     =>                   | mala in se
    mother-in-law   =>   mothers-in-law  |


=head3 Inflexions of hyphenated terms

Terms that contain hyphens are automatically expanded to include the
non-hyphenated version of the term as well. So the final example above
also implies:

    mother in law   =>   mothers in law  |

However, the reverse is not true, so the second last example above
does I<not> imply:

    malum-in-se     =>                   | mala-in-se


=head3 Non-suffix-based inflexions

Terms like "mother-in-law" and "malum in se" are unusual in English, because
the component that is inflected is not the final word (as it is in terms
like "major general" and "mill pond").

"Mother-in-law" is a particular problem because there are an endless set
of other related terms: "father-in-law", "sister-in-law", "uncle-in-law",
"niece-in-law", "cousin-in-law", etc.

There are other similar patterns of non-terminal inflexion, such as
"passer-by"/"hanger-on"/"fender-off" (which become:
"passers-by"/"hangers-on"/"fenders-off" in the plural), or
"son of a gun"/"son of a bitch"/"son of a motherless goat"
(which become: "sons of guns"/"sons of bitches"/"sons of motherless goats").

To simplify specifying these kinds of inflexions, you can use three special
placeholders within any rule in the F<nouns.lei> file:

   (SING)     # Any other singular word defined in the file

   (PL)       # Any other plural word defined in the file

   (PREP)     # Any preposition

For example, to cover the various cases mentioned above (and many
others as well):

        son-of-a-(SING)  =>  sons-of-(PL)   # son-of-a-gun   --> sons-of-guns
                                            # son of a camel --> sons of camels

        (SING)-(PREP)-*  =>  (PL)-(PREP)-*  # mother-in-law  --> mothers-in-law
                                            # man of peace   --> men of peace

        (SING)-(PREP)    =>  (PL)-(PREP)    # passer-by      --> passers-by
                                            # hanger-on      --> hangers-on


=head3 Suffix-based inflexions

You can specify the inflexion of a general suffix in either of
two ways:

    *mouse  =>  *mice
    -men    =>  -mens  | -mina

A leading asterisk indicates that the suffix is itself a complete word,
so the C<*mouse> specification is shorthand for:

    mouse         =>  mice
    dormouse      =>  dormice
    flittermouse  =>  flittermice
    shrewmouse    =>  shrewmice
    titmouse      =>  titmice
    # etc.

A leading hyphen indicates that the suffix is I<not> itself a complete word,
so the C<-men> specification is shorthand for:

    foramen       =>  foramens  |  foramina
    lumen         =>  lumens    |  lumina
    numen         =>  numens    |  numina
    stamen        =>  stamens   |  stamina
    # etc.

but not for:

    men           =>  mens      |  mina


=head3 Conflicting inflexions

English noun inflexions are (unfortunately) not always one-to-one.

If two or more inflexions specify the same plural form, the module
always defaults to the first one to appear in the file. Hence, given:

    base   =>  bases
    basis  =>  bases

the following behaviour has been specified:

                    ->singular    ->plural

    noun('bases')     "base"       "bases"

That is, it will always use the first specification for any
plural-to-singular inflexion of "bases", and so never produce "basis".

Likewise, if two or more inflexions specify the same singular form,
the first of them will be used as the module's default. For example, given:

    octopus  =>  octopuses  |
    octopus  =>             |  octopi
    octopus  =>             |  octopodes

then the following behaviour has been specified:

                                 ->singular    ->plural

    noun('octopus')               "octopus"    "octopuses"
    noun('octopus')->classical    "octopus"    "octopuses"

That is, the module will always use the first specification for any
singular-to-plural inflexion of "octopus" (see the L<preceding
discussion|"octopi"> for an explanation of why this is the only
appropriate behaviour for this particular word.)


=head3 Non-indicative inflexions

A small number of suffix inflexions can present problems for the
C<is_singular()> and C<is_plural()> methods of inflexion objects.

For example, the most general rule for inflecting nouns in English is:

        -    =>  -s        # Form the plural by adding "-s"

But C<is_plural()> uses the specified plural form to determine the
number of a word, by matching it against a pattern built from the
inflexion specification. So, given the previous rule, it will cause
C<is_plural()> to identify as plural any word that matches C</.+s/>.

And that's a problem. Words like "rainbows" and "kittens" and "kisses"
are indeed plural. But words like "basis" and "atlas" and "yes" aren't.

So it's possible to specify an inflexion rule that can be used to
inflect words, but which is I<not> used to identify the words'
intrinsic number. To do that, use the special marker:
C<< <nonindicative> >>.

For example:

    <nonindicative>  -  =>  -s

This marker should not often be required, except for very general
inflexions. In fact, the standard F<noun.lei> that ships with the
module uses it only three times within 2500 inflexions


=head2 The F<verbs.lei> file

The vast majority of the verb inflexions provided by Lingua::EN::Inflexion
are also autogenerated, from the file F<verbs.lei>

=head3 File format

Each entry in this file consists of five words on a single line,
summarizing the inflexion of one verb. The order must be:

    PRESENT       PRESENT     SIMPLE      PRESENT         PAST
    SINGULAR      PLURAL       PAST      PARTICIPLE    PARTICIPLE


For example:

    bides         bide        bided       biding         bided
    bills         bill        billed      billing        billed
    binds         bind        bound       binding        bound
    bites         bite        bit         biting         bitten


=head3 Suffix-based inflexions

General suffix inflexions can be specified the same way as for
nouns: using either an asterisk (for complete words) or a hyphen
(for incomplete suffixes).

You can also use character classes to consolidate two or more similar
inflective patterns.

For example:

    # Handle "underbids" and "disbelieves" as well...
    *bids          *bid          *bade          *bidding        *bidden
    *believes      *believe      *believed      *believing      *believed

    # Handle "hisses" and "kisses"...
    -sses          -ss           -ssed          -ssing          -ssed

    # Handle "accrues" and "fetes", but not "sees"...
    -[^e]es        -[^e]e            -[^e]ed           -[^e]ing          -[^e]ed


=head3 Defective verbs

Entries for defective verbs still require all five columns to be
supplied. Use a single underscore to mark a column without supplying
an inflexion for that column. For example:

    may           may           _           _          _
    might         might         _           _          _
    must          must          _           _          _

    -n't          -n't          -n't        _          _

    -[^s]s        -[^s]         _           _          _


=head2 Rebuilding the module

The F<noun.lei> file is used to autogenerate the following components of
the module:

    lib/Lingua/EN/Inflexion/Noun.pm

    t/noun_is_singular.t
    t/noun_is_plural.t
    t/noun_plural.t
    t/noun_classical_plural.t
    t/noun_singular.t

If you change F<nouns.lei>, you can rebuild these files by running the
application F<bin/generate_nouns> from your command-line. Remember to
then reinstall the Noun.pm module for your changes to take effect.

The F<verb.lei> file is used to autogenerate the following components of
the module:

    lib/Lingua/EN/Inflexion/Verb.pm

    t/verb_is_singular.t
    t/verb_is_plural.t
    t/verb_plural.t
    t/verb_singular.t
    t/verb_past.t
    t/verb_pres_part.t
    t/verb_past_part.t

If you change F<verbs.lei>, you can rebuild these files by running the
application F<bin/generate_verbs> and then reinstalling the Verb.pm module.


=head1 DEPENDENCIES

The implementation of this module depends on several other modules that
are distributed with it (none of which has its own API, none of which
contains any user-servicable parts, and most of which are entirely
computer-generated).

=over

=item Lingua::EN::Inflexion::Term

Internals of the various methods for the three types of inflexion
objects.

=item Lingua::EN::Inflexion::Nouns

Internal hash tables and regex-based suffix patterns for nouns.
Autogenerated from the file F<nouns.lei>.

=item Lingua::EN::Inflexion::Verbs

Internal hash tables and regex-based suffix patterns for verbs.
Autogenerated from the file F<verbs.lei>.

=item Lingua::EN::Inflexion::Indefinite

Internal hash tables and regex logic for working out
whether a noun takes "a" or "an".


=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Not only is real English more complicated than we imagine,
it is probably more complicated than we I<can> imagine.
It is certainly more complicated than we can reasonably code.

Hence it is very likely that this module will get I<something>
wrong...though no bugs are currently outstanding.

Please report any bugs or make feature requests to
C<bug-lingua-en-inflexion@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014-2016, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
