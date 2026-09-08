#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# The validity constraints of XML 1.0, one document per constraint
# violated, each named by the constraint it breaks. `validate => 1` stops
# at the first violation and reports it with its offset; `collect` runs
# the whole pass and hangs the list off the document.

sub valid   { file_xml_decode($_[0], profile => 'full', validate => 1) }
sub refused { my $x = shift; eval { valid($x); 1 } ? '' : $@ }
sub errors  {
    my $d = eval { file_xml_decode($_[0], profile => 'full', validate => 'collect') };
    return $d ? [$d->errors] : ["REFUSED: $@"];
}

# ---- a valid document is accepted, and nothing is reported -------------

{
    my $x = '<!DOCTYPE r ['
          . '<!ELEMENT r (a+, b?)>'
          . '<!ELEMENT a (#PCDATA)>'
          . '<!ELEMENT b EMPTY>'
          . '<!ATTLIST a id ID #IMPLIED ref IDREF #IMPLIED n NMTOKEN #IMPLIED>'
          . ']><r><a id="x1">one</a><a ref="x1" n="tok">two</a><b/></r>';
    ok(valid($x), 'a valid document validates');
    is_deeply(errors($x), [], 'and reports nothing under collect');
    is(scalar(my @e = file_xml_decode($x, profile => 'full')->errors), 0,
       'a document parsed without validate has no errors either');
}

# ---- VC: Element Valid --------------------------------------------------

my $EL = '<!ELEMENT r (a)><!ELEMENT a EMPTY>';

like(refused("<!DOCTYPE r [$EL]><r><b/></r>"),
     qr/an element the content model does not allow here \(VC: Element Valid\)/,
     'an element the model does not allow');
like(refused("<!DOCTYPE r [$EL]><r><a/><a/></r>"),
     qr/an element the content model does not allow here \(VC: Element Valid\)/,
     'one more than the model allows');
like(refused("<!DOCTYPE r [$EL]><r></r>"),
     qr/content ends before the content model does \(VC: Element Valid\)/,
     'and one fewer');
like(refused("<!DOCTYPE r [$EL]><r>text<a/></r>"),
     qr/character data where the content model allows only elements \(VC: Element Valid\)/,
     'character data in element content');
like(refused("<!DOCTYPE r [<!ELEMENT r EMPTY>]><r>x</r>"),
     qr/an element declared EMPTY has content \(VC: Element Valid\)/,
     'text in an EMPTY element');
like(refused("<!DOCTYPE r [<!ELEMENT r EMPTY><!ELEMENT a EMPTY>]><r><a/></r>"),
     qr/an element declared EMPTY has content \(VC: Element Valid\)/,
     'an element in an EMPTY element');
# second edition erratum E15: EMPTY means no content at all
like(refused("<!DOCTYPE r [<!ELEMENT r EMPTY>]><r><!-- c --></r>"),
     qr/an element declared EMPTY has content \(VC: Element Valid\)/,
     'a comment in an EMPTY element (erratum E15)');
like(refused("<!DOCTYPE r [<!ELEMENT r EMPTY>]><r><?pi x?></r>"),
     qr/an element declared EMPTY has content \(VC: Element Valid\)/,
     'and a processing instruction');
like(refused("<!DOCTYPE r [<!ELEMENT r (#PCDATA|a)*><!ELEMENT a EMPTY><!ELEMENT b EMPTY>]><r><b/></r>"),
     qr/an element the mixed content model does not name \(VC: Element Valid\)/,
     'an element a mixed model does not name');
like(refused("<!DOCTYPE r [<!ELEMENT r (a)>]><r><a/></r>"),
     qr/the element type is not declared \(VC: Element Valid\)/,
     'an element type with no declaration');
like(refused('<!DOCTYPE r []><r/>'),
     qr/the element type is not declared \(VC: Element Valid\)/,
     'an empty internal subset declares nothing');
like(refused('<r/>'),
     qr/no document type declaration to be valid against/,
     'and a document with no DOCTYPE cannot be valid at all');

# whitespace between elements is ignored by a content model
ok(valid("<!DOCTYPE r [$EL]><r>\n  <a/>\n</r>"), 'whitespace in element content is ignored');
# but comments and processing instructions are ignored by every model
ok(valid("<!DOCTYPE r [$EL]><r><!-- c --><a/><?pi x?></r>"),
   'and so are comments and processing instructions, outside EMPTY');
# ANY takes any declared element in any order
ok(valid("<!DOCTYPE r [<!ELEMENT r ANY><!ELEMENT a EMPTY>]><r>t<a/>t<a/></r>"),
   'ANY takes text and any declared element');

# ---- VC: Deterministic Content Model ------------------------------------

{
    my $nd = '<!DOCTYPE r [<!ELEMENT r ((a,b)|(a,c))>'
           . '<!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY>]><r><a/><b/></r>';
    like(refused($nd), qr/not deterministic: one name could match two positions \(VC: Deterministic Content Model\)/,
         'a model where one name could match two positions');
    my $det = '<!DOCTYPE r [<!ELEMENT r (a,(b|c))>'
            . '<!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY>]><r><a/><b/></r>';
    ok(valid($det), 'and the deterministic rewrite of it');
    # the offset is the declaration's, not the document's
    like(refused($nd), qr/\(VC: Deterministic Content Model\) at byte offset 13 /,
         'reported at the declaration it is in');
}

# ---- the models the automaton has to get right --------------------------

{
    my $decl = '<!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY>';
    my @ok = (
        [ '(a)',           '<a/>' ],
        [ '(a?)',          ''     ],
        [ '(a?)',          '<a/>' ],
        [ '(a*)',          ''     ],
        [ '(a*)',          '<a/><a/><a/>' ],
        [ '(a+)',          '<a/><a/>' ],
        [ '(a,b)',         '<a/><b/>' ],
        [ '(a|b)',         '<b/>' ],
        [ '(a,b?,c)',      '<a/><c/>' ],
        [ '(a,b?,c)',      '<a/><b/><c/>' ],
        [ '((a,b)|c)',     '<a/><b/>' ],
        [ '((a,b)|c)',     '<c/>' ],
        [ '((a|b)*,c)',    '<c/>' ],
        [ '((a|b)*,c)',    '<a/><b/><a/><c/>' ],
        [ '(a,(b,c)+)',    '<a/><b/><c/><b/><c/>' ],
        [ '((a?,b?)*)',    '' ],
        [ '((a?,b?)*)',    '<b/><a/>' ],
    );
    my @no = (
        [ '(a)',           ''     ],
        [ '(a)',           '<b/>' ],
        [ '(a?)',          '<a/><a/>' ],
        [ '(a+)',          ''     ],
        [ '(a,b)',         '<b/><a/>' ],
        [ '(a|b)',         '<a/><b/>' ],
        [ '(a,b?,c)',      '<a/><b/>' ],
        [ '((a,b)|c)',     '<a/><c/>' ],
        [ '((a|b)*,c)',    '<a/><b/>' ],
        [ '(a,(b,c)+)',    '<a/><b/>' ],
    );
    for my $t (@ok) {
        my $x = "<!DOCTYPE r [<!ELEMENT r $t->[0]>$decl]><r>$t->[1]</r>";
        ok(eval { valid($x); 1 }, "model $t->[0] accepts '$t->[1]'") or diag $@;
    }
    for my $t (@no) {
        my $x = "<!DOCTYPE r [<!ELEMENT r $t->[0]>$decl]><r>$t->[1]</r>";
        like(refused($x), qr/\(VC: Element Valid\)/, "model $t->[0] refuses '$t->[1]'");
    }
}

# ---- VC: No Duplicate Types, Unique Element Type Declaration -----------

like(refused('<!DOCTYPE r [<!ELEMENT r (#PCDATA|a|a)*><!ELEMENT a EMPTY>]><r/>'),
     qr/names the same element type twice \(VC: No Duplicate Types\)/,
     'a mixed model naming one type twice');
like(refused('<!DOCTYPE r [<!ELEMENT r EMPTY><!ELEMENT r EMPTY>]><r/>'),
     qr/declared more than once \(VC: Unique Element Type Declaration\)/,
     'an element type declared twice');

# ---- VC: Root Element Type ---------------------------------------------

like(refused('<!DOCTYPE q [<!ELEMENT r EMPTY>]><r/>'),
     qr/the root element is not the one the DOCTYPE names \(VC: Root Element Type\)/,
     'a root that is not the one the DOCTYPE names');

# ---- the attribute constraints ------------------------------------------

my $E = '<!ELEMENT r EMPTY>';

like(refused("<!DOCTYPE r [$E]><r x='1'/>"),
     qr/the attribute is not declared for this element type \(VC: Attribute Value Type\)/,
     'an undeclared attribute');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x CDATA #REQUIRED>]><r/>"),
     qr/#REQUIRED is absent \(VC: Required Attribute\)/,
     'a missing #REQUIRED attribute');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x CDATA #FIXED 'a'>]><r x='b'/>"),
     qr/#FIXED has another value \(VC: Fixed Attribute Default\)/,
     'a #FIXED attribute given another value');
ok(valid("<!DOCTYPE r [$E<!ATTLIST r x CDATA #FIXED 'a'>]><r x='a'/>"),
   'and the same value is fine');

like(refused("<!DOCTYPE r [$E<!ATTLIST r x ID #IMPLIED>]><r x='1bad'/>"),
     qr/an ID value is not an NCName \(VC: ID/, 'an ID value that is not an NCName');
like(refused('<!DOCTYPE r [<!ELEMENT r (a,a)><!ELEMENT a EMPTY><!ATTLIST a x ID #IMPLIED>]>'
           . '<r><a x="same"/><a x="same"/></r>'),
     qr/two elements carry the same ID value \(VC: ID\)/, 'two elements with one ID value');
like(refused("<!DOCTYPE r [$E<!ATTLIST r a ID #IMPLIED b ID #IMPLIED>]><r/>"),
     qr/more than one ID attribute \(VC: One ID per Element Type\)/,
     'two ID attributes on one element type');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x ID 'v'>]><r/>"),
     qr/must be #IMPLIED or #REQUIRED \(VC: ID Attribute Default\)/,
     'an ID attribute with a default value');

like(refused("<!DOCTYPE r [$E<!ATTLIST r x IDREF #IMPLIED>]><r x='nope'/>"),
     qr/matches no ID in the document \(VC: IDREF\)/, 'an IDREF matching no ID');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x IDREF #IMPLIED>]><r x='1bad'/>"),
     qr/an IDREF value is not an NCName \(VC: IDREF/, 'an IDREF that is not an NCName');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x IDREFS #IMPLIED>]><r x='a 1bad'/>"),
     qr/an IDREFS value holds something that is not an NCName \(VC: IDREF/,
     'an IDREFS holding something that is not an NCName');

like(refused("<!DOCTYPE r [$E<!ATTLIST r x ENTITY #IMPLIED>]><r x='nope'/>"),
     qr/does not name an unparsed entity \(VC: Entity Name\)/,
     'an ENTITY naming nothing');
like(refused("<!DOCTYPE r [$E<!ENTITY e 'text'><!ATTLIST r x ENTITY #IMPLIED>]><r x='e'/>"),
     qr/does not name an unparsed entity \(VC: Entity Name\)/,
     'an ENTITY naming a parsed entity');
ok(valid("<!DOCTYPE r [$E<!NOTATION n SYSTEM 'n'><!ENTITY e SYSTEM 'u' NDATA n>"
       . "<!ATTLIST r x ENTITY #IMPLIED>]><r x='e'/>"),
   'and one naming an unparsed entity is fine');

# Namespaces erratum NE08: in a namespace-aware document a tokenised
# value is an NCName, so a colon in one is a violation and not a name
# character. NMTOKEN is not on that list and keeps its colon.
like(refused("<!DOCTYPE r [$E<!ATTLIST r x ID #IMPLIED>]><r x='a:b'/>"),
     qr/an ID value is not an NCName \(VC: ID, and Namespaces erratum NE08\)/,
     'an ID value with a colon in it');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x IDREF #IMPLIED>]><r x='a:b'/>"),
     qr/an IDREF value is not an NCName/, 'and an IDREF with one');
ok(valid("<!DOCTYPE r [$E<!ATTLIST r x NMTOKEN #IMPLIED>]><r x='a:b'/>"),
   'while an NMTOKEN may still hold a colon');

like(refused("<!DOCTYPE r [$E<!ATTLIST r x NMTOKEN #IMPLIED>]><r x='a/b'/>"),
     qr/an NMTOKEN value is not a name token \(VC: Name Token\)/, 'an NMTOKEN that is not one');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x NMTOKENS #IMPLIED>]><r x='ok a/b'/>"),
     qr/an NMTOKENS value holds something that is not a name token \(VC: Name Token\)/,
     'an NMTOKENS holding one that is not');
# a tokenised value is normalised, so a tab still in it came from a
# character reference and is part of the token, not between two
like(refused("<!DOCTYPE r [$E<!ATTLIST r x NMTOKENS #IMPLIED>]><r x='abc&#9;xyz'/>"),
     qr/\(VC: Name Token\)/,
     'a tab from a character reference does not separate name tokens');
ok(valid("<!DOCTYPE r [$E<!ATTLIST r x NMTOKENS #IMPLIED>]><r x='abc&#32;xyz'/>"),
   'and a space from one does');

like(refused("<!DOCTYPE r [$E<!ATTLIST r x (p|q) #IMPLIED>]><r x='z'/>"),
     qr/not one of the ones declared for it \(VC: Enumeration\)/,
     'an enumerated value that is not one of them');
like(refused("<!DOCTYPE r [$E<!ATTLIST r x (p|p) #IMPLIED>]><r/>"),
     qr/names the same token twice \(VC: No Duplicate Tokens\)/,
     'an enumeration naming one token twice');

# ---- notations -----------------------------------------------------------

like(refused("<!DOCTYPE r [<!ELEMENT r ANY><!ATTLIST r x NOTATION (n) #IMPLIED>]><r/>"),
     qr/names a notation that is not declared \(VC: Notation Attributes\)/,
     'a NOTATION attribute naming an undeclared notation');
like(refused("<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM 'n'>"
           . "<!ATTLIST r x NOTATION (n) #IMPLIED>]><r x='m'/>"),
     qr/not one of the notations declared for it \(VC: Notation Attributes\)/,
     'a NOTATION value that is not one of them');
like(refused("<!DOCTYPE r [$E<!NOTATION n SYSTEM 'n'><!ATTLIST r x NOTATION (n) #IMPLIED>]><r/>"),
     qr/declared EMPTY may not have a NOTATION attribute \(VC: No Notation on Empty Element\)/,
     'a NOTATION attribute on an EMPTY element');
like(refused("<!DOCTYPE r [<!ELEMENT r ANY><!ENTITY e SYSTEM 'u' NDATA nope>]><r/>"),
     qr/names a notation that is not declared \(VC: Notation Declared\)/,
     'an unparsed entity naming an undeclared notation');

# ---- VC: Attribute Default Value Syntactically Correct ------------------

for my $case (
    [ "<!ATTLIST r x (p|q) 'z'>",      'an enumeration default outside the list' ],
    [ "<!ATTLIST r x NMTOKEN 'a/b'>",  'an NMTOKEN default that is not one' ],
    [ "<!ATTLIST r x NMTOKENS 'a \$b'>", 'an NMTOKENS default holding one that is not' ],
    [ "<!ATTLIST r x ENTITY '7'>",     'an ENTITY default that is not an NCName' ],
    [ "<!ATTLIST r x IDREF '1bad'>",   'an IDREF default that is not an NCName' ],
) {
    like(refused("<!DOCTYPE r [<!ELEMENT r ANY>$case->[0]]><r/>"),
         qr/does not meet its type's constraints \(VC: Attribute Default Value Syntactically Correct\)/,
         $case->[1]);
}

# ---- a construct that straddles a parameter entity ----------------------
#
# The text of a parameter entity is included in the stream, so a
# declaration split across one does finish reading; that it was split is
# a validity constraint and nothing more.

{
    # the resolver answers whatever it is asked with the one subset under
    # test, so how a system identifier resolves against the base is not
    # part of what these cases assert
    my $subset;
    my $res = sub { $subset };
    my $go  = sub {
        my ($dtd, $doc) = @_;
        $subset = $dtd;
        eval { file_xml_decode(qq{<!DOCTYPE r SYSTEM "d.dtd">$doc},
                               profile => 'full', validate => 1,
                               resolve => $res); 1 } ? '' : $@;
    };
    my $re = qr/began inside one parameter entity's replacement text and ended outside it/;

    like($go->('<!ENTITY % e "(#PCDATA"><!ELEMENT r %e;)>', '<r/>'), $re,
         'a content model group opened in a parameter entity and closed outside it');
    like($go->('<!ENTITY % e ">"><!ELEMENT r (#PCDATA) %e;', '<r/>'), $re,
         'a declaration whose > came from a parameter entity');
    like($go->('<!ENTITY % a "(x"><!ENTITY % b "|y)"><!ELEMENT r %a;%b;>'
             . '<!ELEMENT x EMPTY><!ELEMENT y EMPTY>', '<r><x/></r>'), $re,
         'and a group whose halves came from two different entities at one depth');
    like($go->('<!ENTITY % e "n CDATA #IMPLIED>"><!ELEMENT r EMPTY><!ATTLIST r %e;', '<r/>'), $re,
         'an ATTLIST whose > came from a parameter entity');
    like($go->('<!ENTITY % e "INCLUDE["><!ELEMENT r EMPTY><![ %e; <!ATTLIST r a CDATA "v"> ]]>', '<r/>'), $re,
         'a conditional section whose keyword and bracket came from one');

    # a parameter entity that supplies a whole declaration is properly
    # nested and no violation at all
    is($go->('<!ENTITY % e "<!ELEMENT r EMPTY>">%e;', '<r/>'), '',
       'a parameter entity holding a whole declaration is properly nested');
    is($go->('<!ELEMENT r EMPTY><!ENTITY % e "CDATA"><!ATTLIST r a %e; #IMPLIED>', '<r a="v"/>'), '',
       'and one supplying part of a declaration it opened and closed inside');
}

# ---- a CDATA section is character data, empty or not --------------------

like(refused("<!DOCTYPE r [<!ELEMENT r (a*)><!ELEMENT a EMPTY>]><r><a/><![CDATA[ ]]><a/></r>"),
     qr/character data where the content model allows only elements \(VC: Element Valid\)/,
     'a whitespace CDATA section in element content is not ignorable whitespace');
like(refused("<!DOCTYPE r [<!ELEMENT r (a*)><!ELEMENT a EMPTY>]><r><a/><![CDATA[]]><a/></r>"),
     qr/character data where the content model allows only elements \(VC: Element Valid\)/,
     'and an empty one is still a section');

# ---- a namespace declaration the DTD declares ---------------------------

like(refused(q{<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r xmlns CDATA #FIXED "urn:a">]>}
           . q{<r xmlns="urn:b"/>}),
     qr/#FIXED has another value \(VC: Fixed Attribute Default\)/,
     'a #FIXED xmlns given another namespace');
ok(valid(q{<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r xmlns CDATA #FIXED "urn:a">]>}
       . q{<r xmlns="urn:a"/>}),
   'and the one it fixes is fine');
# Namespaces is a layer above XML 1.0, so to a DTD a declaration is an
# Attribute like any other and VC: Attribute Value Type applies to it.
# eduni hst-bh-005 and hst-bh-006 are the conformance cases.
like(refused('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r xmlns="urn:a"/>'),
     qr/the attribute is not declared for this element type \(VC: Attribute Value Type\)/,
     'a default namespace declaration the DTD does not declare');
like(refused('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r xmlns:p="urn:p"/>'),
     qr/the attribute is not declared for this element type \(VC: Attribute Value Type\)/,
     'and a prefixed one');
like(refused('<!DOCTYPE r [<!ELEMENT r EMPTY>]>'
           . '<r xmlns:xml="http://www.w3.org/XML/1998/namespace"/>'),
     qr/the attribute is not declared for this element type \(VC: Attribute Value Type\)/,
     'xmlns:xml too, though the parse accepts it and drops it');
ok(valid(q{<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r xmlns CDATA #IMPLIED}
       . q{ xmlns:p CDATA #IMPLIED>]><r xmlns="urn:a" xmlns:p="urn:p"/>}),
   'a DTD written for namespaced markup declares them and is valid');
ok(valid(q{<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r xmlns:xml CDATA #IMPLIED>]>}
       . q{<r xmlns:xml="http://www.w3.org/XML/1998/namespace"/>}),
   'and declaring xmlns:xml answers for it');

# ---- collect ------------------------------------------------------------

{
    my $x = '<!DOCTYPE r [<!ELEMENT r (a)><!ELEMENT a EMPTY><!ATTLIST a x CDATA #REQUIRED>]>'
          . '<r><b/><a/><c/></r>';
    my $e = errors($x);
    is(scalar @$e, 4, 'collect gathers every violation');
    like($e->[0], qr/content model does not allow here/, 'the first is the element out of place');
    like($e->[1], qr/element type is not declared/,      'then the undeclared b');
    like($e->[2], qr/#REQUIRED is absent/,               'then the missing attribute on a');
    like($e->[3], qr/element type is not declared/,      'then the undeclared c');
    my @off = map { /at byte offset (\d+)/ ? $1 : -1 } @$e;
    is_deeply([sort { $a <=> $b } @off], \@off, 'and they are in document order');
    like($_, qr/^File::Raw::XML: /, 'each message is in the one shape') for @$e;

    ok(file_xml_decode($x, profile => 'full', validate => 'collect'),
       'and the document comes back');
    ok(!eval { file_xml_decode($x, profile => 'full', validate => 1); 1 },
       'while validate => 1 refuses it');
}

# ---- the ID index validation builds -------------------------------------

{
    my $x = '<!DOCTYPE r [<!ELEMENT r (a,a)><!ELEMENT a (#PCDATA)>'
          . '<!ATTLIST a key ID #IMPLIED>]><r><a key="k1">one</a><a key="k2">two</a></r>';
    my $d = valid($x);
    is($d->by_id(key => 'k1')->text, 'one', 'by_id answers over the DTD-declared ID attribute');
    is($d->by_id(key => 'k2')->text, 'two', 'and the other one');
    is($d->by_id(key => 'nope'), undef, 'and misses what is not there');
    is($d->xpath('string(id("k2"))'), 'two', 'and XPath id() reads the same index');

    # without validate there is no index, because nothing said which
    # attribute is an ID
    my $plain = file_xml_decode($x, profile => 'full');
    is($plain->by_id(key => 'k1'), undef, 'a parse without validate builds no index');

    # id_attrs keeps its own index and its own refusal
    my $opt = file_xml_decode($x, profile => 'full', id_attrs => ['key']);
    is($opt->by_id(key => 'k1')->text, 'one', 'id_attrs builds one without validate');
}

# ---- the option itself ---------------------------------------------------

ok(!eval { file_xml_decode('<r/>', validate => 1); 1 }, 'validate is a full-profile option');
like($@, qr/validate is an option of profile => 'full'/, '  and says so under strict');
ok(!eval { file_xml_decode('<r/>', profile => 'full', validate => 'nope'); 1 },
   'and it takes 1, 0 or collect');
like($@, qr/validate must be 1, 0 or 'collect'/, '  naming what it takes');
ok(file_xml_decode('<r/>', profile => 'full', validate => 0), 'validate => 0 does not validate');

# ---- the reader does not validate ---------------------------------------

{
    require File::Raw::XML::Reader;
    my $r = File::Raw::XML::Reader->new(profile => 'full');
    $r->feed('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r><a/></r>', 1);
    my $n = 0;
    while (defined(my $k = $r->next)) { $n++ }
    ok($n, 'a reader reads a document no validator would accept');
}

done_testing;
