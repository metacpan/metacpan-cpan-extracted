=pod

=head1 NAME

Lingua::Phonology::FileFormatPOD - Documentation for the xml file format
written and read by Lingua::Phonology

=head1 SYNOPSIS

    <?xml version="1.0" standalone="yes" ?>
    <phonology>

        <!-- Feature definitions are contained within the <feature> tag -->
        <features>
            <feature name="TOP" type="privative">
                <!-- Children may be named with the <child> tag -->
                <child name="Middle" />
            </feature>
            <feature name="Middle" type="privative" />
            <feature name="bottom" type="privative" >
                <!-- Parents may be named with the <parent> tag -->
                <parent name="Middle" />
            </feature>
        </features>

        <!-- Symbol definitions are contained in the <symbol> tag -->
        <symbols>
            <symbol label="A" >
                <feature name="bottom" value="1" />
            </symbol>
        </symbols>

        <!-- Syllabification settings are within the <syllable> tag -->
        <syllable>
            <set_complex_onset />
            <no_coda />
            <min_son_dist value="2" />
        </syllable>

        <!-- Rules are defined in the <rules> tag -->
        <rules>
            <!-- By default, you are allowed to use n:method shortcuts -->
            <rule name="Default" >
                <!-- Equivalent to '$_[1]->bottom' -->
                <where> 1:bottom </where>

                <!-- Equivalent to "$_[0]->delink('Middle')" -->
                <do> 0:delink('Middle') </do>
            </rule>

            <!-- If you don't want shortcuts, you can specify "plain" code -->
            <rule name="Plain" >
                <where type="plain" >$_[-1]->bottom</where>
                <do type="plain" >$_[1]->delink('bottom')</do>
            </rule>

            <!-- You can also use more powerful linguistic-style rules -->
            <rule name="Linguistic" >
                [bottom] => 0 / _$
            </rule>
        </rules>

    </phonology>

=head1 DESCRIPTION

As of v0.3, Lingua::Phonology is able to read and write an XML file that
defines a complete Lingua::Phonology object. This file is meant to be
human-editable, so you can write a phonology definition in a text file and then
load it using Lingua::Phonology. Your perl script itself can be quite minimal,
as most of the work of creating your phonology is done in the file.

For example, the following script reads the phonology defined in
C<my_phono.xml>, then reads a list of underlying forms from STDIN, applies the
rules to them, and writes the surface forms to C<phono.out>.

    use Lingua::Phonology;

    my $phono = new Lingua::Phonology;

    $phono->loadfile('my_phono.xml');

    open OUT, '>phono.out' or die $!;

    while (<>) {
        chomp $_;

        # The following assumes one word per line. It also assumes that all of
        # our symbols are one character and that there are no diacritics.
        # Implementing this script if any of the preceding are false is left as
        # an exercise to the reader.
        @word = $phono->symbols->segment(split //, $_);

        $phono->rules->apply_all(\@word);

        print OUT $phono->symbols->spell(@word), "\n";
    }

Of course, having this be successful depends on C<my_phono.xml> working
properly. The rest of this document describes how to do that.

=head1 GETTING STARTED

The root element of your phonology should be <phonology></phonology>.
Within those tags are four major sub-sections:

=over 4

=item * FEATURES

Defines the features your phonology uses. Enclosed in <features></features> tags,
described in the L<"FEATURES"> section.

=item * SYMBOLS

Defines the phonetic symbols your phonology uses. 
Enclosed in <symbols></symbols> tags, described in the L<"SYMBOLS"> section.

=item * SYLLABLE

Defines syllabification rules for your phonology. Enclosed in <syllable></syllable> tags, described in the L<"SYLLABLE"> section.

=item * RULES

Defines rules that apply to words in your phonology and the order in which they
apply. Enclosed in <rules></rules> tags, described in the L<"RULES"> section.
Linguistic style rules are also included in the rules section, and are
described in L<"LINGUISTIC-STYLE RULES">.

=back

ALL phonology files must have EACH of these sections. Trying to read a
phonology which is missing some section will usually result in errors.
(Exception: If you use the C<loadfile()> method of one of the sub-objects, then
the file given only needs to have the section corresponding to the object used.
For example, if you call $phono->features->loadfile('phono.xml'),
'phono.xml' only needs to have a <features></features> section.)

However, if a certain section is unneeded or unnecessary for your phonology,
nothing keeps you from using an tags with no content.

=head1 FEATURES

Your feature definitions should be enclosed in <features></features>
tags. This section defines the feature set that your phonology uses and the
heirarchy between them, which in turn controls the way you define your symbols
and rules. For a discussion of the general principles behind making a feature
set, see C<Lingua::Phonology::Features>.

Within the <features></features> tags, you use the <feature></feature> tag to
define a single feature. (That's singular: don't confuse the outer
<featureB<s>> tag with the inner <feature> tag.) The <feature> tag must contain
at least two attributes: a name, given by the B<name> attribute, and a type,
given by the B<type> attribute. The name may be any string, but the type must
be one of 'privative', 'binary', or 'scalar'. For the meanings of these
settings, see L<Lingua::Phonology::Features>.

If you don't need to specify parents or children for a feature, this is all you
need. You can use unary tag for such simple features, like this:

    <feature name="foo" type="binary" />

If a feature has children , you may list them inside <child /> tags inside the
<feature></feature> tags. The name of the child feature is given in the B<name>
attribute of the <child /> tag. For example:

    <feature name="Parent" type="privative" >
        <child name="Child 1" />
        <child name="Child 2" />
    </feature>

Alternately, you may use the <parent /> tag to name the parents of a feature,
like so:

    <feature name="child" type="scalar" >
        <parent name="Parent 1" />
        <parent name="Parent 2" />
    </feature>

Remember that the features you name inside <parent> or <child> tags must ALSO
be defined elsewhere with a <feature /> tag. Trying to include a child/parent
that is not defined on its own will generate a warning.

Also, the parent/child relationship is symmetrical. A feature is the child of
all of its parents and the parent of all of its children. You do NOT need to
include both <child> and <parent> tags for a child-parent pair, one or the
other will suffice. It's up to you whether you prefer to do this with <child>
tags or with <parent> tags.

To see a full example of a feature definition, see
L<Lingua::Phonology::Features/"THE DEFAULT FEATURE SET"> and look at the
DEFAULT FEATURE SET section.  That section describes the default feature set
and shows the XML structure used to generate that feature set.

=head1 SYMBOLS

Your symbol definitions must be enclosed within the <symbols></symbols> tag.
You define your symbols based on features in your feature set, and associate
each of them with a label. For a discussion of the general ideas behind making
a symbol set, see L<Lingua::Phonology::Symbols>.

With the <symbols></symbols> tag are a series of <symbol> tags. (Once again,
the interior <symbol> tag is singular, while the outer <symbolB<s>> tag is
plural.) The <symbol> tag must have a B<label> attribute, the value for which
is the symbol string. Thus, the opening tag looks something like this:

    <symbol label="k" >

Inside the <symbol></symbol> tags are a series of unary <feature> tags. Each of
these <feature> tags takes two attributes: a B<name> attribute that gives a
feature name from the current feature set, and a B<value> attribute that gives
the value of the symbol prototype for that feature. The C<value> attribute can
be either a number or a text value. Whatever it is, it will be converted
according to the C<number_form> and C<text_form> conversions described in
L<Lingua::Phonology::Features>. Some examples:

    <feature name="privative_feature" value="*" />
    <feature name="binary_feature" value="+" />
    <feature name="scalar_feature" value="2" />

A whole symbol definition looks like this:

    <symbol label="k" >
        <feature name="dorsal" value="1" />
        <feature name="voice" value="*" />
    </symbol>

You can define as many symbols as you want in your file.  For an example of a
complete symbol set definition, see L<Lingua::Phonology::Symbols/"THE DEFAULT
SYMBOL SET">. That section describes the default symbols and shows the XML
structure used to generate those symbols.

=head1 SYLLABLE

Your syllable section is enclosed with the <syllable></syllable> tag.
The syllable section of your file defines the syllabification parameters used
in your phonology. Unlike the other sections, this section does not consist of
an unlimited number of definitions but of settings to a given number of
parameters. Each of the parameters is represented by its own tag.

Parameters for the syllable section fall into several categories.

=over 4

=item * Boolean

Boolean parameters are either true or false. To set a boolean parameter to
true, include a unary tag with 'set_' prefixed to the name of the parameters.
You can turn on codas, for example, by including a <set_coda /> tag.
Conversely, you can set a boolean parameter to false by including a tag and
prefixing 'no_' to its name. You can turn codas off with a <no_coda />
tag.

Including a tag that has the name of the parameter without any prefix turns
that parameter on. Thus, including a <coda /> tag turns codas on in
exactly the same way that <set_coda /> does.

Boolean parameters are C<onset, complex_onset, coda, complex_coda>.

=item * Integer

Integer parameters may have any whole number as their value. They may be set by
including the name of the parameter as a tag with a single B<value> parameter.
E.g. <min_son_dist value="2" />.

Integer parameters are C<min_son_dist, onset_son_dist, coda_son_dist,
min_nucl_son, min_coda_son, max_edge_son>.

=item * Code

Code parameters must have perl code as their value. The perl code is contained
between opening and closing tags of the name of the parameter. For example, you
might set 'clear_seg' with <clear_seg> not $_[0]->SYLL </clear_seg>.

The perl code is subject to shortcut expansion. See L<"Notes on writing perl
code"> below.
    
Code parameters are C<clear_seg, begin_adjoin, end_adjoin>.

=back

There are two additional parameters which don't fit into any of the above
types. These are C<direction> and C<sonorous>.

The C<direction> parameter is set with a unary tag that has a B<value>
attribute, rather like the integer tags. Like so: <direction value="leftward"
/>. However, the only valid values it may have are "leftward" and "rightward."

The C<sonorous> parameter is set with a paired <sonorous></sonorous>
tag, within which are one or more <feature /> tags. Each <feature /> tag has a
B<name> attribute that defines the feature, and a B<score> attribute that gives
the number of sonority points that feature is worth. As an example, the
following defines the default sonority values:

    <sonorous>
        <feature name="sonorant" score="1" />
        <feature name="approximant" score="1" />
        <feature name="vocoid" score="1" />
        <feature name="aperture" score="1" />
    </sonorous>

The meaning and application of these parameters is described in more detail in
L<Lingua::Phonology::Syllable>. As a more complete example, the following
defines the default settings for Lingua::Phonology::Syllable:

    <syllable>
        <set_onset />
        <no_complex_onset />
        <no_coda />
        <no_complex_coda />
        <min_son_dist value="3" />
        <min_coda_son value="0" />
        <max_edge_son value="100" />
        <min_nucl_son value="3" />
        <direction value="rightward" />
        <sonorous>
            <feature name="sonorant" score="1" />
            <feature name="approximant" score="1" />
            <feature name="vocoid" score="1" />
            <feature name="aperture" score="1" />
        </sonorous>
        <clear_seg> return 1; </clear_seg>
        <begin_adjoin> return 0; </begin_adjoin>
        <end_adjoin> return 0; </end_adjoin>
    </syllable>

=head1 RULES

Your rules section is enclosed in <rules></rules> tags. This section defines
the rules which act in your phonology. Rule definitions are enclosed in
<rule></rule> tags, rule order is written with <order></order> tags, and
persistent rules are written with <persist></persist> tags. Each of these is
discussed below. For a complete discussion of how to write rules and the
meanings of these parameters, see L<Lingua::Phonology::Rules>.


=head2 Rule declarations

You may make as many rules as you would like. Each rule is enclosed in
<rule></rule> tags.  The opening <rule> tag must contain a B<name> attribute,
which gives the name of the rule to be added. E.g. C<< <rule name="Metathesis" > >>

Within the <rule></rule> tags you may include a tag for each of the properties
that a rule normally has. These properties include C<direction, domain, tier,
filter, where, do, result>.

The first three properties (C<direction, domain, tier>), take a simple text
string as their value. They are represented by a unary tag with a single
B<value> attribute. E.g.:

    <direction value="rightward" />
    <domain value="SYLL" />
    <tier value="vocoid" />

The other four properties (C<filter, where, do, result>) take perl code as
their value. They are represented as a pair of tags with perl as their
contents. E.g.:

    <where>
        $_[0]->vocoid and $_[1]->nasal
    </where>
    <do>
        $_[0]->nasal($_[1]->value_ref('nasal'))
    </do>
    <!-- Likewise for other code properties -->

Considerations for writing code inside the XML structure and some shortcuts are
described below in L<"Notes on writing perl code">. A complete discussion of
rules and what they do is in L<Lingua::Phonology::Rules/"WRITING RULES">.

You may also use linguistic-style rules as the content of a rule declaration.
This is discussed in L<"LINGUISTIC-STYLE RULES">

=head2 Rule order and persistent rules

To give the order in which your rules apply, use the <order></order> tags.
Within the <order> tag you include one or more <block></block> tags, which in
turn contain unary <rule> tags. Each <rule> tag has one B<name> attribute,
which gives the name of the rule to be applied. For example:

    <order>
        <block>
            <rule name="A1" />
            <rule name="A2" />
        </block>
        <block>
            <rule name="B" />
        </block>
        <block>
            <rule name="C1" />
            <rule name="C2" />
            <rule name="C3" />
        </block>
    </order>

Persistent rules are given within <persist></persist> tags. Between these tags
you may have any number of unary <rule> tags with a B<name> attribute, just as
above. Example:

    <persist>
        <rule name="P1" />
        <rule name="P2" />
    </persist>

Rule order and persistent rules are described in more detail in
L<Lingua::Phonology::Features/"apply_all"> and following sections.

=head2 Notes on writing perl code

When you write perl code as the content of a <where></where> tag or any other
similar tag, your code is evaluated in the package C<main>. Thus, if you
reference C<$foo> or any other variable other than C<@_>, you're getting
C<$main::foo>. If you want your code to be evaluated in some other package, be
sure to include the appropriate C<package> declaration.

The code for rule properties usually works on the contents of C<@_>, and we
write things like C<< $_[1]->feature_name >> constantly. It becomes tiresome to
repeatedly type this whole string, and when such strings are printed back out
they are escaped into the near-unreadable C<< $_[1]-&gt;feature_name >>. To
solve both problems, this module provides a shortcut method. Anything like C<<
$_[n]->method >> can be rewritten as C<n:method>, where C<n> is an integer and
C<method> is a method name. The module will expand such shortcuts appropriately
before evaluating them. Thus, all of the following are equivalent:

    1:nasal                         $_[1]->nasal
    0:delink('vocoid')              $_[0]->delink('vocoid')
    -1:BOUNDARY                     $_[-1]->BOUNDARY
    0:voice(1:value_ref('voice'))   $_[0]->voice($_[1]->value_ref('voice'))

In order for this to work, there must be NO WHITESPACE between the number, the
colon, and the following method name. (This is to avoid most conflicts with the
ternary C<?:> operator.) Also, the number must be an integer matching the
regular expression C</-?\d+/>, and the method following must be a valid perl
method call. Thus, all of the following are B<incorrect>:

    1: labial
    1.2:nasal
    0:'long feature name'
    $n:dorsal

By default, all perl code found in your XML file is expanded this way. If you
need to keep this from happening, then you can add a C<type="plain"> attribute
to the opening tag. The following two are identical:

    <where> 1:nasal </where>
    <where type="plain" > $_[1]->nasal </where>

Though as a matter of fact, there's nothing wrong with just doing this:

    <where> $_[1]->nasal </where>

The only time you really B<have> to use the type attribute is if you insist on
doing something like this:

    <where type="plain">
        $_[0]->aperture > 1 ? 1:0
    </where>

If you didn't use the C<type="plain"> attribute, this would come out to:

    $_[1]->aperture > 1 ? $_[1]->0

Which is a syntax error, of course. But if your use of whitespace is sane, you
should rarely, if ever, run into conflicts.

=head1 LINGUISTIC-STYLE RULES

Generative phonologists have developed a more-or-less standard notation for
writing their rules, and Lingua::Phonology can now parse such rules. To include
a linguistic-style rule in your rule set, simply write the rule as the content
of a <rule></rule> tag (i.e. not inside any other tag). For example:

    <rule name="Vowel Nasalization" >
        [vocoid] => [nasal] / _[nasal]
    </rule>

If you are familiar with generative phonology literature, you will probably
find such rules easier to write and understand than the pure perl rules
discussed above. This section will discuss exactly how you can write such rules
and how the Lingua::Phonology module will turn them into perl code.

=head2 Input segments and output segments

The simplest form of linguistic rule is an unconditional change, in which some
segment or feature is changed regardless of what other segments are present.
Such rules follow this format:

    input_segments => output_segments

You write the input segments on the left side, and what they become on the
right side. In the middle you write C<< => >>. Actually, because people have
their own styles, you can write any of C<< => >>, C<< -> >>, or C<< > >>. In
this document we'll always use C<< => >>.

To write this kind of rule, you simply need to know how to describe input
segments and output segments. In linguistic literature, this is generally done
by writing feature descriptions. A feature description consists of a set of
feature values enclosed in square brackets '[]', like this:

    [-anterior voice]

The features inside the square brackets may be specified in three different
ways:

=over 4

=item * privative style

In this style, you simply list the name of the feature to test or set any true
value: C<[nasal]>. To test for or set a false value, you precede the name of
the feature with an asterisk: C<[*nasal]>. This is most appropriate for
privative features which are either true (present) or false (absent).

=item * binary style

In this style, you put a '+' before the name of the feature to test or set the
value 1: C<[+anterior]>. You put a '-' before the name of the feature to test
or set the value 0: C<[-anterior]>. You may also put an '*' before the name of
the feature to set its value to undefined: C<[*anterior]>. This is most
appropriate for binary features which are either positive, negative, or
undefined.

=item * scalar style

In this style, you put the name of the feature first, followed by an '=', then
any value. If the value you give is a numeral or a word with no non
alphanumeric characters, you do not need to include the value in quotes:
C<[aperture=2], [scalar=word]>. If the value you wish to assign includes
non-alphanumeric characters, you need to put the value in double quotes:
C<[scalar="long, strange value"]>. This is best for scalar features which can
have a range of values.

=back

Strictly speaking, any type of feature can be tested or set with any of the
styles above, but it's recommended that you use each style with the appropriate
type of feature.

Example:

    [dorsal -anterior] => [nasal]

Read: "Any segment that is dorsal and -anterior (i.e. a palatal) becomes nasal."

In formal linguistic literature you must always define your segments with
feature bundles like above. However, Lingua::Phonology also allows you to
define a segment with a symbol from the current symbol set. This is done by
writing the symbol between /slashes/, like so: C</s/>. This makes many rules
clearer. Example:

    /z/ => /s/

Read: "All /z/'s become /s/'s."

You can, of course, mix the two styles

    [Coronal] => /s/

Read: "All coronals (dentals, alveolars, etc.) become /s/."

Remember that whatever comes between the slashes is the symbol. If you write
C</sk/>, Lingua::Phonology will look for a single segment whose symbol is 'sk'.
If you want an /s/ followed by a /k/, write C</s//k/>.

Another extension of strict linguistic form is the fact that you can include
more than one segment in your input and output segments. Your linguistics
professor might not like the following rule, but Lingua::Phonology has no
problem with it:

    /s/[nasal] => /z/[*nasal voice]

Read: "/s/ followed by a nasal is replaced with /z/ followed by a voiced stop."

The only stipulation here is that your statement must be B<balanced>: there
must be the same number of segments on both sides of the arrow.

One final trick is to use an empty set of braces, C<[]>, which will match
anything at all on the left side of an arrow, and leave a segment unchanged on
the right side. For example:

    /s/[]/r/ => /S/[]/l/

Read: "/s/ followed by anything, followed by an /r/, becomes /S/, followed by
the same thing, followed by an /l/."

The only thing that C<[]> does not match is nothing at all--it implies that
some segment exists there, but you don't care what it is. (To match nothing at
all you can use C<0>, but see below at L<"Inserting and deleting">.

See L<"Details of parsing"> for some warnings and more detail about how
segments are parsed.

=head2 Conditions

The rules we have written so far have been unconditioned rules, which don't
depend on segments other than the ones being changed. However most linguistic
rules are not unconditional, and so we need to add the condition clause. The
general format for rules with conditions is this:

    input_segments => output_segments / conditions

A slash normally separates the condition from the rest of the rule. However,
this can sometimes get lost amid the slashes used around symbols, so you can
also write it with a colon:

    input_segments => output_segments : conditions

The condition itself is written just like the input and output segments, with
bracketed feature bundles or symbols. However, you put an underscore '_' where
the input/output segment(s) go.  No matter how many segments you use, you only
put a SINGLE underscore there to represent them. For example:

    /s/ => /S/ : _/i/

Read: "Replace /s/ with /S/ when the next segment is /i/".

You can put segments before and after the underscore:

    [vocoid] => [nasal] / [voice]_[nasal]

Read: "Vocoids become nasalized when the next segment is nasal and the
preceding segment is voiced".  

You often want to do something at the end of a word or at the beginning of a
word. For this, the special symbol C<$> is used. If you use a '$', it must be
either the very first symbol or the very last symbol in the condition (or you
can put one at both ends, but this implies that you know the whole word you're
looking for). Example:

    [Coronal] => /s/ : _$

Read: "Coronals become /s/ at the end of a word."

=head2 Sets of segments and conditions

Sometimes you want to do something when this OR that is true, and nothing can
be found in common between this and that. (Linguists hate such rules, but they
do exist, unfortunately.) To accomplish this, you need a set, which lists a
group of segments or conditions. In either case, a set consists of two
parenthesis '()' enclosing the options, which are themselves separated by pipes
'|'.

Here's an example segment set:

    /s/ => /x/ : _(/r/ | /k/ | /u/ | /i/)

Read: "/s/ becomes /x/ when the next segment is any of /r/, /k/, /u/, or /i/".
This rule, by the way, actually exists in Old Church Slavic. I didn't make it
up, unlike most of the other example rules.

You can mix different kinds of feature definitions in a set, of course:

    (/d/ | /g/ | [labial]) => [*Place] / _$

Read: "/d/, /g/, or any labial delink their Place node (and become glottals) at
the end of a word."

You can also make a set of conditions. Example:

    [labial] => /m/ : ( _/m/ | [nasal]_ )

Read: "Any labial becomes /m/, either when the next segment is /m/ or when the
preceding segment is a nasal."

When you make a set of conditions, the set must be the B<entire> condition part
of the rule. For example, the following variation of the preceding rule is
wrong, and won't parse:

    # WRONG
    [labial] => /m/ : ( _/m/ | [nasal]_ )$

Intention: "Any labial becomes /m/, either when it precedes an /m/ which is the
last segment in the word, or when it follows a nasal and is the last segment in
the word." As nice as this sounds, it doesn't work. Sorry.

=head2 Inserting and deleting

Insertion and deletion are both accomplished with the special symbol '0'. You
can use a '0' on either the left-hand or right-hand side of the arrow in a
linguistic rule, but it has a slightly different meaning on each side. You
CANNOT use a C<0> in the condition part of the rule, nor inside a segment set.
Both of the following are wrong:

    (/k/ | [voice] | 0) => [nasal] #WRONG, will not parse
    /s/ => /z/ : _0/d/ # WRONG, will not parse

On the left-hand side of an arrow, the C<0> means "Don't look for a segment
here, but insert a segment in this spot." The segment to be inserted is
whatever is in the corresponding spot on the right side of the arrow. Example:

    /s/0[Coronal] => []/i/[] : _[*vocoid]

Read: "Insert an /i/ between /s/ and another coronal when the following segment
is not a vocoid". Remember that [] can be used on the left-hand side of a rule
to mean "match anything" and on the right-hand side of an arrow to mean "don't
change anything". This rule is exactly equivalent to the following rule:

    0 => /i/ : /s/_[Coronal][*vocoid]

The second form here is more formally correct, but the first illustrates how
you can include a C<0> anywhere in a rule to insert a segment at that point.

On the right-hand side of an arrow, the C<0> means "Delete whichever segment is
in this spot." The segment to be deleted is whichever segment occupies the same
spot on the right-hand side of the arrow. Example:

    /s//k/ => /S/0 : _$

Read: "An /s/ followed by a /k/ becomes /S/ followed by nothing at the end of a
word."

Here's a similar example:

    [vocoid][nasal coda] => [nasal]0

Read: "A vowel folllowed by a coda nasal is nasalized, and the nasal is
deleted."

=head2 Using linguistic rules with other rule parameters

You can use a linguistic rule together with other tags or parameters that are
normally part of a rule. In fact, it is often necessary to do so to create a
rule. For example, suppose you wish to have a front vowel harmony rule. You
could try to write something like this

    [vocoid] => [-anterior] / _[][-anterior vocoid]

Read: "A vocoid becomes [-anterior] (front) when the segment after the next one
is also a front vocoid". Here we assume that the C<[]> represents the
intervening consonant, which we don't care about. However, this rule will break
if there is not exactly one consonant between the vowels. To remedy this, you
should specify a tier of C<vocoid>, which will cause the rule to ignore all
non-vocoids. The whole rule declaration would then look like this:

    <rule name="Vowel Harmony" >
        <tier value="vocoid" />
        [] => [-anterior] / _[-anterior]
    </rule>

Note that we've removed the C<vocoid> statements from the feature bundles.
That's because they are now redundant--we know that only vocoids are included
in this rule. We also removed the C<[]> from the condition, because any
intervening consonant will not appear at all in our word. This rule will work
no matter how many consonants appear between the vowels.

The parameters that you can specify this way are C<direction, tier, filter,
domain, result>. You should not try to specify a C<where> or C<do> property
together with a linguistic rule, because the linguistic rule I<is> the C<where>
and C<do> properties. Any C<where> or C<do> that you specify will be ignored.

=head2 Limitations

There is one important aspect of linguistic rules which is missing in the
current implementation. That is the ability to include I<variables>, usually
denoted by Greek letters in generative rules. Variables let you assign the
value of one segment to be the same as the value of any other segment. The
current linguistic rule parser has no mechanism for variables, although this
will be implemented at a future date.

=head2 Details of parsing

Internally, Lingua::Phonology uses the strings C<'__TRUE', '__FALSE',
'__BOUNDARY', '__NULL'> as markers. DO NOT attempt to use symbols with these
names or assign these as values to a scalar reference.

For the curious, here is the perl code that Lingua::Phonology generates from
the feature declaration formats. These are all illustrated with C<$_[0]>,
although the actual element of C<@_> acted upon varies and should be
irrelevant:

    Linguistic form     When testing               When assigning
    ===========================================================================
    [feature]           ($_[0]->feature)           $_[0]->feature(1);
    [*feature]          (not $_[0]->feature)       $_[0]->delink('feature');
    [-feature]          ($_[0]->feature == 0)      $_[0]->feature(0);
    [+feature]          ($_[0]->feature == 1)      $_[0]->feature(1);
    [feature=val]       ($_[0]->feature eq 'val')  $_[0]->feature('val');
    /sym/               ($_[0]->spell eq 'sym')    Lingua::Phonology::Functions::change($_[0], 'sym');

The parser for linguistic rules was written with Parse::RecDescent. What
follows is the Parse::RecDescent grammar, minus some irrelevant detail. 


    Rule: From Arrow To When(?)

    From: (Segment | SegmentSet | Null)(s)

    Arrow: '>' | '->' | '=>'

    To: (Segment | Null)(s)

    When: ('/'|':') (Condition | ConditionSet)

    ConditionSet: '(' <leftop: Condition '|' Condition> ')'

    Condition: Boundary(?) (Segment | SegmentSet)(s?) '_' (Segment | SegmentSet)(s?) Boundary(?)

    SegmentSet: '(' <leftop: Segment '|' Segment> ')'

    Segment: ( '[' Feature(s?) ']' | '/' Text '/')

    Feature: Text '=' Text | /[\+\-\*]/ Text | Text
        
    Text: /\w+/ | <perl_quotelike> 

    Boundary: '$'

    Null: '0'

=head1 SAVING A PHONOLOGY

Lingua::Phonology objects can save their state to a file with the C<savefile()>
method. This method accepts a filename as its argument, and is documented in
C<Lingua::Phonology/"savefile">. When you use this method, the XML document
generated has a couple of idiosyncrasies:

=over 4

=item *

The order of elements will not be preserved from the file you loaded (if you
loaded a file), except for those handful of elements for which ordering is
crucial.

=item *

Formatting is made as human-readable as possible, but there may be some
problems.

=item *

Code references are deparsed using B::Deparse. B::Deparse is not always able to
deparse a code reference correctly, though I have never had problems with it.

=item *

Deparsed code is always written out with C<n:method> shortcuts. There is no
capability for remembering or re-creating linguistic style rules, and probably
never will be. As a corrolary, if you want to see how your linguistic rules are
parsed into perl, you can load your XML file and then save it to a different
file to see what comes out.

=back

=head1 BUGS

Lingua::Phonology has little or no resources for dealing with files that are
valid XML but don't follow the format given here. It is likely to die with
unhelpful error messages, instead.

=head1 SEE ALSO

L<Lingua::Phonology>

L<Lingua::Phonology::Features>

L<Lingua::Phonology::Symbols>

L<Lingua::Phonology::Segment>

L<Lingua::Phonology::Rules>

L<Lingua::Phonology::Syllable>

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>.

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut
