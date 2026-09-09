package File::Raw::XML;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

use File::Raw;

require XSLoader;
XSLoader::load('File::Raw::XML', $VERSION);

1;

__END__

=head1 NAME

File::Raw::XML - an XML parser

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use File::Raw qw(slurp);
    use File::Raw::XML qw(file_xml_decode);

    my $doc = file_xml_decode($bytes, id_attrs => ['ID']);
    my $doc = file_slurp('metadata.xml', plugin => 'xml');

    my $root = $doc->root;
    my ($assertion) = $root->find($SAML_NS, 'Assertion');
    my ($signature) = $assertion->find($DS_NS, 'Signature');

    my $bytes = $assertion->c14n(mode    => 'exclusive',
                                 without => [$signature]);

    my $signed = $doc->by_id(ID => $reference_uri_without_the_hash);

=head1 DESCRIPTION

An XML 1.0 and Namespaces 1.0 parser producing a read-only tree, and a
canonicaliser for it in the three algorithms a signature names: Exclusive
XML Canonicalization 1.0, Canonical XML 1.0 and Canonical XML 1.1. It is
written for consumers that verify signatures over the canonical form,
where one wrong byte is a signature that never verifies, and it is small
enough to own rather than fence: the safe subset of XML is not large.

By default it is not a full XML processor. It refuses every document with
a DOCTYPE and accepts UTF-8 only, and that one rule is what removes entity
expansion, external entities, parameter entities, external DTD fetches,
the billion laughs and XXE as a class. Three surfaces reach the same tree:
a L<File::Raw> plugin, a direct codec for bytes already in memory, and a C
ABI for XS consumers.

C<< profile => 'full' >> is a full XML 1.0 and 1.1 processor over the same
core: document type declarations and their internal and external subsets,
entity expansion under budgets, every encoding, DTD validation and
XInclude. Nothing in that paragraph is reachable without asking for it, and
what the default profile does is unchanged by any of it. See L</PROFILES>.

XPath 1.0, the writer and the mutable tree are over any document under
either profile, since none of them reads a declaration.

=head1 PROFILES

    my $doc = file_xml_decode($bytes);                        # strict
    my $doc = file_xml_decode($bytes, profile => 'full');      # everything

C<strict> is the default everywhere: the codec, the plugin, the reader and
the C ABI's C<parse> entry. Under it a document type declaration is
refused wherever it stands, the input is UTF-8 or it is refused, and the
tree, the messages and the canonical bytes are what they are and will not
move. A caller who wants the guarantee that no entity was expanded and
nothing was fetched has it by doing nothing.

C<full> reads what strict refuses. On its own it brings document type
declarations, the internal subset, entity expansion under
L</BUDGETS>, UTF-16 and ISO-8859-1 through L</ENCODINGS>, XML 1.1, and the
record of where CDATA sections were. Anything that reaches outside the
document is a further option on top of it and is off until named:
C<resolve> for an external subset or an external entity (L</RESOLVERS>),
C<validate> for the validity constraints (L</VALIDATION>), C<xinclude> for
inclusion (L</XINCLUDE>).

An option that only the full profile can honour is refused under strict
rather than ignored, so a caller who asks for one and does not get it is
told.

=head1 WHAT IS ACCEPTED

Under either profile: XML 1.0 with Namespaces 1.0, in UTF-8: elements, attributes, text, CDATA
sections, comments, processing instructions and the XML declaration; the
five predefined entities and numeric character references. Line ends are
normalised as section 2.11 of XML 1.0 requires, and attribute values as
section 3.3.3 does for an attribute with no declared type, which without a
DOCTYPE is every attribute: a literal tab, line feed or carriage return in
a value becomes a space, while a character reference to one of them stays
the character.

Namespace declarations are resolved at parse time. The C<xml> prefix is
bound without a declaration and is never reported as one. Unprefixed
attributes have no namespace, never the default.

Under C<< profile => 'full' >>, additionally: a document type declaration
with its internal subset and, with a resolver, its external subset;
element, attribute list, entity and notation declarations; general and
parameter entities, expanded under L</BUDGETS>; conditional sections in
external markup; XML 1.1 and its line ends; and the encodings
L</ENCODINGS> lists. Attribute values are then normalised by their
declared type rather than as CDATA, and declared defaults are materialised
onto every element that lacked them.

=head1 WHAT IS REFUSED

Every refusal dies with a message naming the byte offset it was found at
and up to sixteen bytes of what was there, with anything outside printable
ASCII rendered as C<\xNN>. In the order the parser meets them:

=over 4

=item * Input longer than C<max_bytes>, when one is given.

=item * Under C<strict>, a UTF-16 or UTF-32 byte order mark, or a first
pair of bytes that is one; an XML declaration naming any encoding other
than UTF-8; an XML version other than 1.0. L</ENCODINGS> says what C<full>
reads instead.

=item * Under C<strict>, a DOCTYPE anywhere, and every other declaration
beginning C<< <! >> with it. This is the rule that removes entity
expansion, external entities, parameter entities, external DTD fetches,
the billion laughs and XXE as a class. C<< profile => 'full' >> is the
only thing that reads one, and under it the billion laughs is stopped by
L</BUDGETS> instead.

=item * A byte sequence that is not UTF-8: overlong forms, surrogates,
anything above U+10FFFF. A character that is valid UTF-8 and not an XML
character: a C0 control other than tab, line feed and carriage return,
U+FFFE, U+FFFF.

=item * A named entity other than the five predefined ones; a character
reference to a non-character; C<< ]]> >> in content; a literal C<< < >> in
an attribute value; C<--> inside a comment; a processing instruction whose
target is C<xml> in any case anywhere but offset 0.

=item * A name that is not a name; a qualified name with more than one
colon, or a colon at either end.

=item * An attribute given twice on one element, literally or through two
prefixes bound to one namespace.

=item * A prefix with no binding in scope; C<xmlns:xml> bound to anything
but the XML namespace, or another prefix bound to it; C<xmlns:xmlns>;
undeclaring a prefix with an empty value in a document that is not XML
1.1, that being Namespaces 1.1; a relative namespace URI, over which
canonicalisation is undefined.

=item * Nesting deeper than C<max_depth>.

=item * More than one root element, none, or content outside it.

=item * Two elements carrying the same value for an attribute named in
C<id_attrs>. Which of two is "the" element is the whole of the signature
wrapping attack, and a lookup that picked one would be picking for the
attacker, so the document is refused instead.

=back

=head1 DIRECT CODEC

=head2 file_xml_decode($bytes, %options)

Parse bytes into a L<File::Raw::XML::Document>, or die with a message as
above. A string with the character flag on is taken as its UTF-8; one
without it is taken as bytes, and refused if they are not UTF-8. A string
holding Latin-1 characters must be upgraded first.

Exported on request, by name or under C<:codec>; C<:const> exports the
node kind constants C<FRX_ELEMENT>, C<FRX_TEXT>, C<FRX_COMMENT>, C<FRX_PI>
and C<FRX_DOCUMENT> and the event kinds C<FRX_START>, C<FRX_END> and
C<FRX_DOCTYPE>; C<:all> exports both. A bare C<use> exports nothing.

=head2 file_xml_events($bytes, %options)

The push form of L<File::Raw::XML::Reader>: parses C<$bytes> and calls,
for each event, the callback given under C<start>, C<end>, C<text>,
C<comment>, C<pi> or C<doctype>, with the reader positioned on the event
as the one argument, so the reader's accessors describe it. A missing
callback skips its events. Every other key is an option of the reader.
Dies as the codec would, at the first refusal. Exported with
C<file_xml_decode> under C<:codec>, or by name.

=head2 File::Raw::XML->new_document(%options)

An empty L<File::Raw::XML::Document> with only its document node, to be
built with L<File::Raw::XML::Document/new_element> and the editing methods
of L<File::Raw::XML::Node>. The one option is C<version>, C<1.0> by
default or C<1.1>.

=head1 OPTIONS

The same options for the codec, the plugin and the reader. An unknown one
dies, and so does one that only C<< profile => 'full' >> can honour when
the profile is C<strict>: an option that was silently ignored would be a
caller believing something the parser is not doing.

Under either profile:

=over 4

=item * C<max_bytes> - the largest input accepted, in bytes; 0, the
default, is no cap. The ceiling is the caller's to set.

=item * C<max_depth> - the deepest nesting accepted; the root is depth 1;
the default is 256.

=item * C<id_attrs> - an arrayref of attribute local names, in any
namespace, whose values are indexed for L<File::Raw::XML::Document/by_id>
and refused when duplicated. With none, nothing is indexed and nothing is
refused.

=back

Under C<< profile => 'full' >> only:

=over 4

=item * C<encoding> - the input's encoding, overriding what the bytes and
the declaration say. See L</ENCODINGS>.

=item * C<resolve> - where an external subset, an external entity or an
XInclude gets its bytes. See L</RESOLVERS>.

=item * C<base> - the document's own URI, which relative system
identifiers resolve against.

=item * C<validate> - check the document against its document type
declaration. See L</VALIDATION>.

=item * C<xinclude> - process C<xi:include>. See L</XINCLUDE>.

=item * C<max_entity_depth>, C<max_expansion_bytes>,
C<max_expansion_ratio>, C<max_fetches>, C<max_xinclude_depth>,
C<max_token_bytes> - see L</BUDGETS>.

=back

=head1 ENCODINGS

Under C<strict> the input is UTF-8, and anything else is refused at the
byte order mark, at the first pair of bytes or at the declaration.

Under C<< profile => 'full' >> the encoding is worked out the way section
4.3.3 and appendix F say: a byte order mark if there is one, then the
first four bytes, then what the declaration names. UTF-8, UTF-16 in either
byte order and ISO-8859-1 are read; anything else is refused by name. The
C<encoding> option overrides all of it, for the caller who knows what the
bytes are because the transport said so.

Whatever came in, what comes out is characters, and every offset in a
refusal is an offset into the bytes you passed rather than into the
transcoded form, so a message points where you can look.

=head1 DOCUMENT TYPE DECLARATIONS

Under C<< profile => 'full' >> a DOCTYPE is read: its name, its public and
system identifiers and its internal subset, all of which
L<File::Raw::XML::Document/doctype> reports as they were written.

What the declarations say is applied to the tree before you see it.
Attribute defaults are materialised onto every element that lacked them,
in declaration order after the written attributes. Attribute values are
normalised by their declared type rather than as CDATA. Entity references
are replaced by their replacement text: there is no entity reference node,
which is what Canonical XML requires and what makes the canonical form of
a document with entities equal to the canonical form of the same document
without them.

An external subset is fetched only with a C<resolve>, and refused without
one rather than skipped, because a document whose declarations were partly
read would canonicalise differently from a processor that read them all.

=head1 RESOLVERS

The core opens no file and no socket. An external subset, an external
entity and an XInclude reach it as bytes through C<resolve> and no other
way, so nothing leaves the process that the caller did not agree to.

    my $doc = file_xml_decode($bytes, profile => 'full', resolve => sub {
        my %r = @_;    # kind, public_id, system_id, base
        return $store{ $r{system_id} };
    });

C<kind> is C<subset>, C<entity> or C<xinclude>. Returning C<undef> is a
refusal and so is dying, and either way the message names the reference's
offset. The system identifier arrives already resolved against the
document's C<base> and the base of whatever declared it.

    my $doc = file_slurp($path, plugin => 'xml', profile => 'full',
                         resolve => 'file');

is the one built-in resolver: it reads files, and only files whose real
path, symbolic links followed, lies under the real path of the document's
own directory. It needs a document with a path, so the codec refuses it.

=head1 BUDGETS

Every expansion has one, each refused with the offset it was crossed at.
A budget of 0 means the default and never means unlimited.

=over 4

=item * C<max_entity_depth> - how deep entity references may nest; 16.

=item * C<max_expansion_bytes> - how much text expansion may produce in
all; 16 MiB.

=item * C<max_expansion_ratio> - how many times the input's own length
that may be; 100.

=item * C<max_fetches> - how many times the resolver may be called; 32.

=item * C<max_xinclude_depth> - how deep inclusion may nest; 8.

=item * C<max_token_bytes> - the largest single token a reader will hold
while waiting for its end; 16 MiB.

=back

Together they are what stops the billion laughs under C<full>, where the
DOCTYPE rule that stops it under C<strict> no longer applies. A document
that would expand to more than any of them is refused rather than
truncated.

=head1 THE TREE

A L<File::Raw::XML::Document> owns the tree; every L<File::Raw::XML::Node>
handed out keeps its document alive for as long as the node exists, so
there is nothing the caller has to do about lifetime. The tree is
read-only, and it is not shareable across interpreter threads.

Names, attribute values and text come back as character strings. Where a
method takes a namespace, C<undef> means any namespace and the empty
string means no namespace. One class serves every node kind, with C<kind>
telling them apart; the document node is a node too, whose children are
the top-level comments and processing instructions with the root element
among them.

=head1 CANONICALISATION

    my $bytes = $node->c14n(mode        => 'exclusive',
                            comments    => 0,
                            prefix_list => ['xs', '#default'],
                            without     => [$signature]);
    my $bytes = $doc->c14n(%same);

The canonical form of the node's subtree, or of the whole document, as
bytes with no character flag, because a signature is over bytes.

C<mode> names the algorithm: C<exclusive>, the default, is Exclusive XML
Canonicalization Version 1.0 (W3C Recommendation, 18 July 2002);
C<inclusive> is Canonical XML Version 1.0 (15 March 2001); C<inclusive-1.1>
is Canonical XML Version 1.1 (2 May 2008). Comments are rendered when
C<comments> is true, the C<WithComments> variant of each.

C<without> names subtrees left out of the node set: the element named, its
attributes and everything below it. This is the enveloped-signature
transform, and it is the only subset the tree expresses; a node's
ancestors are always in the set when the node is, so nothing here can
orphan a node. A node from another document is an error.

The node whose ancestors lie outside the set is the one you called C<c14n>
on, and each algorithm treats it as its Recommendation says: Canonical XML
1.0 copies onto it the nearest occurrence of every attribute in the
C<xml> namespace it does not itself carry; Canonical XML 1.1 copies
C<xml:lang> and C<xml:space> that way, joins C<xml:base> through its
section 2.4, and never copies C<xml:id>; the exclusive algorithm copies
nothing. The exclusive algorithm renders a namespace declaration only where
it is visibly used and not already rendered by an ancestor in the output;
C<prefix_list> is its C<InclusiveNamespaces PrefixList>, with C<#default>
naming the default namespace, and the inclusive modes ignore it.

=head1 EVENTS AND STREAMING

L<File::Raw::XML::Reader> is a pull reader over the same parser: bytes in
through C<feed>, one event at a time out through C<next>, and the memory
held is the memory of one record, so a stream of a million records costs
what one costs. L</file_xml_events> is the push form of it.

The C<xml> plugin streams too:

    file_each_line($path, $cb, plugin => 'xml', record => [$ns, $local]);

yields one L<File::Raw::XML::Document> per matching element, built from
that element's start event, with the namespace bindings in scope carried
into it so each record canonicalises as it would have in place.

A reader enforces every well-formedness constraint the codec does, at the
same offsets. It does not validate: a validity constraint is about a
finished document and an event stream has none.

=head1 WRITING

    my $bytes = $doc->to_string(indent => 2);
    file_spew($path, $doc, plugin => 'xml', encoding => 'UTF-16');

L<File::Raw::XML::Document/to_string> writes a document or a subtree back
as markup: an encoding, a declaration, indentation, C<< <a/> >> or
C<< <a></a> >>, the quote, and the recorded DOCTYPE. It is a second
serialiser beside the canonical one and shares only the escapers with it,
so no option here can move a canonical byte.

Parsing what it wrote gives a document equal to the one it was given,
which L<File::Raw::XML::Document/equals> is for and which the test suite
asserts over every document it has.

=head1 EDITING

    my $doc  = File::Raw::XML->new_document;
    my $root = $doc->new_element($NS, 'p:Envelope');
    $doc->document->append($root);
    $root->set_attr('', 'ID', 'x1');

A document can be built from nothing or edited in place: see
L<File::Raw::XML::Document/BUILDING> and L<File::Raw::XML::Node/EDITING>.
A node is never moved or freed by an edit, so every node you already hold
stays valid, and a prefix that would mean something else where a subtree
lands gets a declaration rather than changing meaning.

=head1 XPATH

    my @nodes = $doc->xpath('//item[@sku = $sku]', vars => { sku => $s });
    my $n     = $doc->xpath('count(//item)');

XPath 1.0 in full, over a document of either profile: the four value
types, the thirteen axes, the 27 core functions. See
L<File::Raw::XML::XPath>, which also compiles an expression once for
evaluating many times.

=head1 VALIDATION

    my $doc = file_xml_decode($bytes, profile => 'full', validate => 1);
    my $doc = file_xml_decode($bytes, profile => 'full', validate => 'collect');
    warn "$_\n" for $doc->errors;

C<< validate => 1 >> checks every validity constraint of XML 1.0 and dies
at the first one broken, with the constraint named and the byte offset it
was found at, in the shape every other refusal uses. C<< validate =>
'collect' >> checks them all, returns the document, and puts the list on
it for L<File::Raw::XML::Document/errors>, in document order. There is no
warning channel and no third state: the specification's errors that are
raised "at user option" are collected.

Validating is not the same as parsing. A document with no document type
declaration is well-formed and cannot be valid, and one whose declaration
declares nothing leaves every element type undeclared, so C<validate>
refuses both.

A namespace declaration is validated as an attribute. Namespaces in XML
is a layer above XML 1.0, so C<xmlns:foo="..."> is an Attribute to the
grammar and has to be declared for its element type like any other. A
document type declaration written without the C<xmlns> attributes its
markup uses therefore makes every document drawn from it invalid, which
is a real friction between document type declarations and namespaces and
not a quirk of this parser. It costs nothing unless C<validate> is asked
for. Content models are compiled to an automaton, and one that
is not deterministic is itself a violation, reported against the
declaration it is in rather than against the document.

A validated document gets its ID index from the attributes the document
type declaration says are IDs, which is what
L<File::Raw::XML::Document/by_id> and XPath's C<id()> then answer over. A
document parsed with C<id_attrs> keeps that index instead: the two are
different questions and never both apply.

L<File::Raw::XML::Reader> does not validate. A validity constraint is
about a finished document, and an event stream has none.

=head1 XINCLUDE

Under C<< profile => 'full' >> and C<< xinclude => 1 >>, every
C<xi:include> element in the namespace C<http://www.w3.org/2001/XInclude>
is replaced, after the document is parsed, by what it names. The bytes
arrive through the same C<resolve> option external entities use, called
with a kind of C<xinclude>, so an C<href> reaches no file and no socket
the caller has not agreed to.

C<href> is resolved against the base URI in force at the include element,
which is the document's C<base> option with any C<xml:base> above it
applied. C<parse> is C<xml>, the default, or C<text>, which reads the
bytes as one text node under C<encoding> and never as markup.
C<xpointer> takes a bare name, resolved through the included document's
ID index, or the C<element()> scheme with a child sequence; the other
XPointer schemes are refused by name. An C<xi:include> with no C<href>
includes from the document itself.

When the resolver refuses, or the bytes do not parse, the C<xi:fallback>
children stand in the include's place; with no C<xi:fallback> that is
fatal. An inclusion loop, and a chain deeper than C<max_xinclude_depth>
(8 by default), are fatal whatever fallback says. Every fetch counts
against C<max_fetches>.

The included subtree is copied into the including document, so what comes
back is one document, and section 4.7.5's fixup puts an C<xml:base> on
each included root naming where it came from. That attribute is part of
the document from then on: it is written by C<to_string> and it appears in
the canonical form, which is correct and worth knowing before you
canonicalise an included document.

=head1 C ABI

File::Raw::XML exposes a small C ABI so that B<other XS modules> can
parse, walk and canonicalise entirely in C, with no per-call Perl
dispatch. The motivating consumer is L<Punk::SAML>, which verifies XML
signatures over the canonical form.

The header is distributed through L<ExtUtils::Depends> - a consumer
B<does not copy it>. Building this dist installs F<frx_abi.h> and writes
C<File::Raw::XML::Install::Files>, so a dependent's F<Makefile.PL> that
says

    my $pkg = ExtUtils::Depends->new('My::Consumer', 'File::Raw::XML');
    WriteMakefile( ..., $pkg->get_makefile_vars );

picks up F<frx_abi.h> on its include path automatically.

This is an integration surface for XS authors, not part of the Perl API.
Perl callers should use L</DIRECT CODEC> and the two classes above.

=head2 The table

The contract lives in F<include/frx_abi.h>:

    #define FRX_ABI_VERSION 2

    typedef struct frx_doc  frx_doc;      /* opaque; owns every node and string */
    typedef struct frx_node frx_node;     /* opaque; borrowed from its doc */

    enum { FRX_ELEMENT = 1, FRX_TEXT, FRX_COMMENT, FRX_PI, FRX_DOCUMENT };
    enum { FRX_C14N_EXC = 0, FRX_C14N_INC10, FRX_C14N_INC11 };

    typedef struct frx_abi {
        int abi_version;              /* consumers compare >=, never == */

        /* the strict profile, and all `parse` will ever be */
        void (*opts_init)(frx_opts *o);
        frx_doc *(*parse)(pTHX_ const char *bytes, STRLEN len,
                          const frx_opts *o, SV **err);
        void     (*doc_free)(pTHX_ frx_doc *d);
        root, document, kind, ns, local, prefix, parent, first_child, next,
        attr_count, attr, attr_value, find, by_id, text, c14n

        /* the full profile */
        parse_ex, err_format
        version, standalone
        doctype_name, doctype_public, doctype_system, doctype_subset
        cdata_span_count, cdata_span
        error_count, error_at
        write_opts_init, write, tree_equal
        reader_new, reader_free, reader_feed, reader_next, reader_str,
        reader_int, reader_offset, reader_attr_count, reader_attr,
        reader_subtree, reader_error
        new_document, new_element, new_text, new_comment, new_pi,
        append_child, insert_before, remove_node, set_attr, remove_attr,
        set_text, declare_ns, set_name, import_node
        xpath_compile, xpath_free, xpath_var_count, xpath_var_name,
        xpath_bind_str, xpath_bind_num, xpath_bind_bool,
        xpath_result_new, xpath_result_free, xpath_eval,
        xpath_result_kind, xpath_result_number, xpath_result_string,
        xpath_result_count, xpath_result_node
    } frx_abi;

The header is the contract and carries every signature; the names above
are the shape of it. C<parse> takes C<frx_opts> and means the strict
profile, and that is all it will ever mean: a consumer that calls it can
never be handed an entity-expanded or transcoded document, whatever a
later version adds. C<parse_ex> takes C<frx_opts_ex>, which begins with
its own C<sizeof> so that later versions can add options without a new
entry.

Everything that can fail after C<parse> takes an C<< frx_err * >> rather
than a message SV, and C<err_format> renders one, so no entry needs a
wrapper to translate a refusal.

The table is B<append-only> from the first release onwards: new entries go
at the end, C<FRX_ABI_VERSION> bumps, existing offsets never move. A
consumer written against version N keeps working against every later
version.

=head2 File::Raw::XML::_abi_ptr

    my $iv = File::Raw::XML::_abi_ptr;

Returns the address of the process-wide C<frx_abi> table as an integer (an
C<IV>). A consumer calls this once at C<BOOT>, C<INT2PTR>s it to a
C<< const frx_abi * >>, and checks C<< ->abi_version >= >> the version
whose entries it calls. At least, never exactly: the table is append-only
from the first release onwards, so a provider newer than the consumer is
always safe, and an equality check would turn every append into a breaking
change. Not intended to be called from Perl for any other purpose.
C<File::Raw::XML::_abi_selftest> and
C<File::Raw::XML::_abi_selftest_full> walk every entry end to end in C and
are what F<t/20-abi.t> runs.

=head2 Functions and ownership

C<parse> returns a document the consumer frees with C<doc_free>, or
C<NULL> with a mortal message SV in C<*err>; it never croaks. Every string
the tree accessors return is borrowed from the document, NUL-terminated,
and valid until C<doc_free>; C<ns> and C<prefix> return C<""> when there is
none, and C<local> on a processing instruction is its target. Every node
is borrowed from its document: B<a consumer that holds a node holds the
document>. C<attr_value> and C<find> take C<NULL> for any namespace and
C<""> for none; C<find> iterates by passing the previous match as
C<after>. C<by_id> answers exactly one element or C<NULL>, over the
attribute names given in C<id_attrs> at parse. C<text> and C<c14n> return
an SV with a reference count of one owned by the caller, or C<NULL> on an
allocation failure; C<c14n>'s bytes carry no character flag.

Two lifetimes are shorter than the document's, and both are the reader's:
a string from C<reader_str> or C<reader_attr> is valid until the next
C<reader_next> and not after, because the reader releases what a record
held when the record ends, and the C<< frx_err * >> from C<reader_error>
is valid while the reader is. A message never is borrowed:
C<< frx_err.what >> and the refusal from C<xpath_compile> are static
strings, so a consumer can free what failed and then report it.

C<reader_new>, C<xpath_compile> and C<xpath_result_new> each hand out
something the consumer frees with the matching entry. C<new_document> and
C<reader_subtree> hand out documents, freed with C<doc_free>.

=head2 The SV bridge

Everything above hands a consumer handles. Four entries, added at version
2, cross between a handle and the blessed object the Perl surface uses, so
a consumer can parse in C and hand the result to Perl code, or take a
document back from Perl code and serialise it in C without a method call.

    SV *(*doc_to_sv)(pTHX_ frx_doc *d);
    frx_doc *(*doc_from_sv)(pTHX_ SV *sv);
    const frx_node *(*node_from_sv)(pTHX_ SV *sv, frx_doc **owner);
    SV *(*node_to_sv)(pTHX_ SV *doc_sv, const frx_node *n);

C<doc_to_sv> B<takes ownership> of the document, and it is the only entry
that does: the blessed SV's magic frees it when the last reference goes,
so a consumer that also calls C<doc_free> has freed it twice.

C<doc_from_sv> and C<node_from_sv> are the type test as well as the
unwrap. They answer C<NULL> for anything that is not the object they name
- a plain reference, an unblessed one, a different class, an C<undef> -
rather than croaking, so a consumer can ask "is this a document?" of every
value it is handed. What they return is borrowed from the SV and lives as
long as it does; C<node_from_sv> fills C<*owner> with the node's document,
which the node borrows from and which outlives it.

C<node_to_sv> takes the blessed Document the node belongs to, not a
handle, because the node it returns keeps that document alive - which is
what makes the borrow safe.

=head2 Example: a consumer walking an Assertion

Vendor nothing - add File::Raw::XML via ExtUtils::Depends (above), resolve
the table at boot, then use it wherever needed:

    #include "frx_abi.h"   /* found via ExtUtils::Depends, not copied */

    static const frx_abi *FRX = NULL;

    /* at BOOT */
    {
        dSP; IV p;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        call_pv("File::Raw::XML::_abi_ptr", G_SCALAR);
        SPAGAIN; p = POPi; PUTBACK; FREETMPS; LEAVE;
        FRX = INT2PTR(const frx_abi *, p);
        if (!FRX || FRX->abi_version < 1)
            croak("File::Raw::XML with a compatible C ABI is required");
    }

    /* later: the signed element, canonicalised without its signature */
    static SV *
    signed_bytes(pTHX_ const char *xml, STRLEN len, const char *id)
    {
        static const char *const ids[] = { "ID" };
        frx_opts o; frx_c14n c; SV *err = NULL, *out;
        frx_doc *d;
        const frx_node *elem, *sig;

        FRX->opts_init(&o);
        o.id_attrs = ids; o.n_id_attrs = 1;
        d = FRX->parse(aTHX_ xml, len, &o, &err);
        if (!d) croak_sv(err);

        elem = FRX->by_id(d, "ID", id, strlen(id));
        sig  = elem ? FRX->find(elem, "http://www.w3.org/2000/09/xmldsig#",
                                "Signature", NULL) : NULL;
        if (!elem || !sig || FRX->parent(sig) != elem) {
            FRX->doc_free(aTHX_ d);
            croak("no signed element with that ID");
        }
        c.mode = FRX_C14N_EXC; c.comments = 0;
        c.prefix_list = NULL; c.n_prefix = 0;
        c.without = &sig; c.n_without = 1;
        out = FRX->c14n(aTHX_ elem, &c);
        FRX->doc_free(aTHX_ d);
        return out;                        /* +1, the caller's */
    }

=head1 SEE ALSO

L<File::Raw>, L<File::Raw::XML::Document>, L<File::Raw::XML::Node>,
L<Punk::SAML>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
