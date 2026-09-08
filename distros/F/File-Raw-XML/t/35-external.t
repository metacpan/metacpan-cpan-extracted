#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use File::Raw qw(slurp spew);
use File::Raw::XML qw(file_xml_decode);

# External entities and the external subset under the full profile: a
# coderef resolver serving from a hash, every kind of reference, the
# refusal without a resolver, a die inside one, the fetch cache, the
# budgets, the standalone validity constraints, and the file resolver's
# confinement to the document's own directory.

my %files;
my @calls;
my $resolver = sub {
    my %r = @_;
    push @calls, { %r };
    my $p = $r{system_id};
    die "no such file: $p\n" unless exists $files{$p};
    return $files{$p};
};
sub full    { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', resolve => $resolver, %o) }
sub refused { my ($b, %o) = @_; my $ok = eval { full($b, %o); 1 }; $ok ? '' : $@ }
sub attrs   { my ($n) = @_; join ' ', map { "$_->[2]=$_->[3]" } @{ $n->attrs } }

# the deliverable: an external subset through a resolver
{
    %files = ('doc.dtd' => qq{<!ATTLIST doc a CDATA "d" b NMTOKENS "  x  y  ">\n<!ENTITY e "external">\n<!ELEMENT doc ANY>\n});
    @calls = ();
    my $doc = full(qq{<!DOCTYPE doc SYSTEM "doc.dtd">\n<doc>&e;</doc>});
    is(attrs($doc->root), 'a=d b=x y', 'the external subset\'s defaults are materialised, typed');
    is($doc->root->text, 'external', 'and its entities expand');
    is(scalar @calls, 1, 'one fetch');
    is($calls[0]{kind}, 'subset', 'of kind subset');
    is($calls[0]{system_id}, 'doc.dtd', 'with the system identifier as written when there is no base');
    ok(!defined $calls[0]{public_id} && !defined $calls[0]{base}, 'no public identifier, no base');
    is($doc->doctype->{system_id}, 'doc.dtd', 'and the DOCTYPE records it');

    like(refused(qq{<!DOCTYPE doc SYSTEM "doc.dtd"><doc/>}, resolve => undef),
         qr/^File::Raw::XML: the external subset cannot be read without a resolver; the resolve option .* at byte offset 21 /,
         'no resolver: refused at the system literal, naming the option');
    ok(!eval { file_xml_decode(qq{<!DOCTYPE doc SYSTEM "doc.dtd"><doc/>}, profile => 'full'); 1 }, 'and with the option absent');

    $doc = full(qq{<!DOCTYPE doc SYSTEM "doc.dtd" [<!ENTITY e "internal"><!ATTLIST doc a CDATA "i">]><doc>&e;</doc>});
    is($doc->root->text, 'internal', 'an internal entity declaration takes precedence over the external one (2.9)');
    is(attrs($doc->root), 'a=i b=x y', 'so does an internal attribute definition; the rest still come from outside');
}

# the resolver's arguments, and relative resolution against the base
{
    %files = (
        'http://x.org/a/c.dtd'   => qq{<!ENTITY t SYSTEM "d/t.txt"><!ENTITY % p SYSTEM "../p.ent">%p;},
        'http://x.org/a/d/t.txt' => 'T',
        'http://x.org/p.ent'     => qq{<!ENTITY q "Q">},
    );
    @calls = ();
    my $doc = full(qq{<!DOCTYPE doc SYSTEM "c.dtd"><doc>&t;&q;</doc>}, base => 'http://x.org/a/b.xml');
    is($doc->root->text, 'TQ', 'entities from the subset and from an external parameter entity');
    is_deeply([ map { [ @$_{qw(kind system_id base)} ] } @calls ],
              [ [ subset => 'http://x.org/a/c.dtd', 'http://x.org/a/b.xml' ],
                [ entity => 'http://x.org/p.ent',   'http://x.org/a/c.dtd' ],
                [ entity => 'http://x.org/a/d/t.txt', 'http://x.org/a/c.dtd' ] ],
              'each identifier resolved against the entity that declared it (4.2.2), the base passed along');
}

# external parsed entities in content: text declarations, encodings, versions, balance
{
    my $dtd = sub { '<!DOCTYPE doc [' . join('', @_) . ']>' };
    %files = (
        'plain.xml'  => '<c>plain</c>',
        'decl.xml'   => qq{<?xml version="1.0" encoding="UTF-8"?><c>declared</c>},
        'latin.xml'  => qq{<?xml encoding="ISO-8859-1"?><c>caf\xE9</c>},
        'utf16.xml'  => do { require Encode; "\xFF\xFE" . Encode::encode('UTF-16LE', qq{<?xml encoding="UTF-16"?><c>wide</c>}) },
        'noenc.xml'  => qq{<?xml version="1.0"?><c>x</c>},
        'v11.xml'    => qq{<?xml version="1.1" encoding="UTF-8"?><c>eleven</c>},
        'wrong.xml'  => qq{<?xml encoding="UTF-16"?><c>x</c>},
        'open.xml'   => '<c>never closed',
        'close.xml'  => '</doc>',
        'text.txt'   => 'just text &amp; &lt; more',
        'empty.xml'  => '',
        'lt.xml'     => '<',
        'big.xml'    => '<c>' . ('x' x 100) . '</c>',
    );
    my $d = sub { my ($name, $body) = @_; $dtd->(qq{<!ENTITY x SYSTEM "$name">}) . "<doc>$body</doc>" };
    is(full($d->('plain.xml', '&x;'))->root->text, 'plain', 'an external entity with no text declaration');
    is(full($d->('decl.xml',  '&x;'))->root->text, 'declared', 'a text declaration is stripped');
    is(full($d->('latin.xml', '&x;'))->root->text, "caf\x{e9}", 'each entity is transcoded from its own declaration');
    is(full($d->('utf16.xml', '&x;'))->root->text, 'wide', 'and from its own byte order mark');
    is(full($d->('text.txt',  '[&x;]'))->root->text, '[just text & < more]', 'text content with references, merged with the surrounding text');
    is(scalar(() = full($d->('plain.xml', '&x;&x;'))->root->elements), 2, 'referenced twice, included twice, fetched once');
    is(full($d->('empty.xml', 'a&x;b'))->root->text, 'ab', 'an empty entity contributes nothing');
    like(refused($d->('noenc.xml', '&x;')), qr/text declaration must name its encoding \(section 4\.3\.1\) at byte offset 52 /, 'a text declaration without encoding, at the reference');
    like(refused($d->('v11.xml', '&x;')), qr/XML 1\.1 entity cannot be referenced from an XML 1\.0 document \(section 4\.3\.4\)/, 'a 1.1 entity in a 1.0 document');
    is(full(qq{<?xml version="1.1"?>} . $d->('v11.xml', '&x;'))->root->text, 'eleven', 'and in a 1.1 document it is fine');
    like(refused($d->('wrong.xml', '&x;')), qr/encoding declaration contradicts the encoding it arrived in/, 'a declaration that lies about the encoding');
    like(refused($d->('open.xml', '&x;')), qr/opened inside an entity must close inside it/, 'WFC: Parsed Entity: an element opened in the entity');
    like(refused($d->('close.xml', '&x;')), qr/must not close an element opened outside it/, 'and one closed by it');
    like(refused($d->('lt.xml', '&x;')), qr/expected a name|unterminated start tag/, 'a lone < in an entity: the frame ends after it');
    like(refused($dtd->('<!ENTITY x SYSTEM "plain.xml">') . '<doc a="&x;"/>'), qr/must not refer to an external entity/, 'WFC: No External Entity References');
    like(refused($dtd->('<!ENTITY x SYSTEM "plain.xml" NDATA n><!NOTATION n SYSTEM "n">') . '<doc>&x;</doc>'), qr/unparsed entity/, 'an unparsed entity is still refused');
    like(refused($d->('missing.xml', '&x;')), qr/the resolver died: no such file: missing\.xml at byte offset 54 /, 'a die in the resolver is the refusal, at the reference');
    like(refused($d->('plain.xml', '&x;'), resolve => sub { undef }), qr/the resolver returned undef at byte offset 52 /, 'and so is undef');
    like(refused($d->('big.xml', '&x;'), max_bytes => 70), qr/fetched entity exceeds max_bytes/, 'max_bytes bounds each fetched text');
    ok(full($d->('plain.xml', '&x;'), max_bytes => 200), 'when both fit');
}

# the fetch cache and max_fetches
{
    %files = ('a.txt' => 'A', 'b.txt' => 'B', 'd.dtd' => qq{<!ENTITY a SYSTEM "a.txt"><!ENTITY a2 SYSTEM "a.txt"><!ENTITY b SYSTEM "b.txt">});
    @calls = ();
    my $doc = full(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&a;&a2;&b;&a;</doc>});
    is($doc->root->text, 'AABA', 'four references, three entities, two targets');
    is_deeply([ map { $_->{system_id} } @calls ], [qw(d.dtd a.txt b.txt)], 'one fetch per resolved identifier: the cache');
    like(refused(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&a;&b;</doc>}, max_fetches => 2), qr/more external fetches than max_fetches/, 'max_fetches counts the DTD too');
    ok(full(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&a;&a2;</doc>}, max_fetches => 2), 'and cache hits are free');
    ok(!eval { file_xml_decode('<r/>', max_fetches => 1); 1 }, 'max_fetches is refused under strict');
    like($@, qr/options of profile => 'full'/, 'naming full');
    ok(!eval { file_xml_decode('<r/>', resolve => sub { }); 1 }, 'so is resolve');
    ok(!eval { file_xml_decode('<r/>', base => 'x'); 1 }, 'and base');
    ok(!eval { file_xml_decode('<r/>', profile => 'full', resolve => 'sideways'); 1 }, 'resolve must be a coderef or "file"');
    like($@, qr/resolve must be a coderef or 'file'/, 'saying so');
}

# parameter entities in external markup: inside declarations, in literals,
# supplying whole declarations, with 4.4.8's padding; conditional sections
{
    %files = ('d.dtd' => <<'DTD');
<!ENTITY % type "CDATA">
<!ENTITY % dflt '"dv"'>
<!ATTLIST doc a %type; %dflt;>
<!ENTITY % model "(#PCDATA|b)*">
<!ELEMENT doc %model;>
<!ENTITY % w "world">
<!ENTITY hw "hello %w;">
<!ENTITY % decls "<!ENTITY d1 'one'> <!ENTITY d2 'two'>">
%decls;
<!ENTITY % draft "INCLUDE">
<![%draft;[
  <!ENTITY inc "included">
  <![IGNORE[ <!ENTITY ign1 "no"> <![ <!ENTITY ign2 "no"> ]]> <!ENTITY ign3 "no"> ]]>
]]>
<![IGNORE[ <!ENTITY ign4 "no"> ]]>
DTD
    my $doc = full(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&hw; &d1; &d2; &inc;</doc>});
    is($doc->root->attr('a'), 'dv', 'a PE supplies an attribute type and another the default');
    is($doc->root->text, 'hello world one two included', 'a PE in an entity value, PEs holding whole declarations, an INCLUDE section');
    # IGNORE hid these declarations, and the way that shows is not a
    # refusal: this document has an external subset and is not standalone,
    # which is exactly the case WFC: Entity Declared does not cover, so an
    # undeclared name is a validity error and not a well-formedness one.
    # The reference stands for nothing, and a validating parse names it.
    for my $n (qw(ign1 ign2 ign3 ign4)) {
        my $d = full(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&$n;</doc>});
        is($d->root->text, '', "IGNORE hides $n, nested or not: the reference stands for nothing");
    }
    like(refused(qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&ign1;</doc>}, validate => 1),
         qr/names no declared entity \(VC: Entity Declared\)/,
         'and a validating parse reports it as the validity error it is');
    like(refused(q{<!DOCTYPE doc [<!ELEMENT doc ANY>}
               . q{<!ENTITY % pe "<!ENTITY ent1 'text'>">%pe;]><doc>&nope;</doc>}, validate => 1),
         qr/names no declared entity \(VC: Entity Declared\)/,
         'a parameter entity REFERENCE in the internal subset opens the same exemption (erratum E13)');
    like(refused(q{<!DOCTYPE doc [<!ELEMENT doc ANY>}
               . q{<!ENTITY % pe "<!ENTITY ent1 'text'>">]><doc>&nope;</doc>}),
         qr/undeclared entity/,
         'declaring one without referencing it does not: the constraint names the reference');
    like(refused(q{<!DOCTYPE doc [<!ELEMENT doc ANY>]><doc>&nope;</doc>}),
         qr/undeclared entity/,
         'but an internal subset with no parameter entity reference is still a refusal');
    like(refused(qq{<?xml version="1.0" standalone="yes"?>}
               . qq{<!DOCTYPE doc SYSTEM "d.dtd"><doc>&ign1;</doc>}),
         qr/undeclared entity/,
         'and standalone="yes" keeps the well-formedness constraint whatever the DTD did');
    like(refused(qq{<!DOCTYPE doc [<!ENTITY % t "CDATA"><!ATTLIST doc a %t; "x">]><doc/>}), qr/PEs in Internal Subset/, 'inside a declaration in the internal subset it is still refused');
    %files = ('bad.dtd' => '<![INCLUDE[ <!ENTITY x "y"> ');
    like(refused(qq{<!DOCTYPE doc SYSTEM "bad.dtd"><doc/>}), qr/unterminated INCLUDE section at byte offset 21 /, 'an unterminated section, reported at the system literal');
    %files = ('bad.dtd' => ']]>');
    like(refused(qq{<!DOCTYPE doc SYSTEM "bad.dtd"><doc/>}), qr/\]\]> outside a conditional section/, 'a stray ]]>');
    %files = ('bad.dtd' => '<![ FOO [ ]]>');
    like(refused(qq{<!DOCTYPE doc SYSTEM "bad.dtd"><doc/>}), qr/expected INCLUDE or IGNORE/, 'an unknown keyword');
    %files = ('bad.dtd' => '<!ENTITY x "y"> ]');
    like(refused(qq{<!DOCTYPE doc SYSTEM "bad.dtd"><doc/>}), qr/\] is not allowed in the external subset/, 'a ] in the external subset');
    %files = ('bad.dtd' => '<!ELEMENT x ANY');
    like(refused(qq{<!DOCTYPE doc SYSTEM "bad.dtd"><doc/>}), qr/unterminated ELEMENT declaration/, 'a declaration cut off by the end of the subset');
    %files = ('v.dtd' => qq{<?xml version="1.1" encoding="UTF-8"?><!ENTITY x "y">});
    like(refused(qq{<!DOCTYPE doc SYSTEM "v.dtd"><doc/>}), qr/1\.1 external subset cannot be used by an XML 1\.0 document/, 'a 1.1 external subset under a 1.0 document');
    ok(full(qq{<?xml version="1.1"?><!DOCTYPE doc SYSTEM "v.dtd"><doc>&x;</doc>}), 'and under a 1.1 one');
}

# standalone="yes": validity constraints, applied under validate only
{
    %files = ('s.dtd' => qq{<!ELEMENT doc (#PCDATA)><!ENTITY ext "E"><!ATTLIST doc a CDATA "d" t NMTOKENS #IMPLIED>});
    my $sa  = qq{<?xml version="1.0" standalone="yes"?><!DOCTYPE doc SYSTEM "s.dtd">};
    my $nsa = qq{<?xml version="1.0"?><!DOCTYPE doc SYSTEM "s.dtd">};
    ok(full($sa . '<doc t=" x  y "/>'), 'without validate a standalone document uses the external attribute declarations');
    like(refused($sa . '<doc a="w">&ext;</doc>'), qr/standalone="yes" but the entity is declared in the external subset or a parameter entity \(WFC: Entity Declared\)/,
         'an externally declared entity is a well-formedness error in a standalone document, validate or not (WFC: Entity Declared)');
    like(refused(qq{<?xml version="1.0" standalone="yes"?><!DOCTYPE doc [<!ENTITY % pe "<!ENTITY pe1 'x'>">%pe;]><doc>&pe1;</doc>}),
         qr/WFC: Entity Declared/, 'so is one declared inside a parameter entity of the internal subset');
    ok(full(qq{<!DOCTYPE doc [<!ENTITY % pe "<!ENTITY pe1 'x'>">%pe;]><doc>&pe1;</doc>}), 'which is fine when the document is not standalone');
    %files = ('s2.dtd' => qq{<!ENTITY ext "E"><!ATTLIST doc a CDATA "&ext;">});
    is(full(qq{<?xml version="1.0" standalone="yes"?><!DOCTYPE doc SYSTEM "s2.dtd"><doc/>})->root->attr('a'), 'E',
       'a reference inside the external subset itself is exempt from that rule');
    %files = ('s.dtd' => qq{<!ELEMENT doc (#PCDATA)><!ENTITY ext "E"><!ATTLIST doc a CDATA "d" t NMTOKENS #IMPLIED>});
    like(refused($sa . '<doc/>', validate => 1), qr/standalone="yes" but an attribute default declared in the external subset applies/, 'an externally declared default that applies');
    like(refused($sa . '<doc a="w" t=" x  y "/>', validate => 1), qr/standalone="yes" but an attribute type declared in the external subset changed this value/, 'an externally declared type whose normalisation changed the value');
    ok(full($sa . '<doc a="w" t="x y"/>', validate => 1), 'and not when nothing changed');
    ok(full($nsa . '<doc t=" x  y ">&ext;</doc>', validate => 1), 'none of it applies without standalone="yes"');
}

# the file resolver: confined to the document's directory
{
    my $dir  = tempdir(CLEANUP => 1);
    my $out  = tempdir(CLEANUP => 1);
    my $real = abs_path($dir);
    mkdir "$dir/sub";
    file_spew("$dir/doc.dtd",   qq{<!ENTITY e "from dtd"><!ENTITY s SYSTEM "sub/s.txt">});
    file_spew("$dir/sub/s.txt", 'from sub');
    file_spew("$out/out.dtd",   qq{<!ENTITY e "outside">});
    file_spew("$dir/doc.xml",   qq{<!DOCTYPE doc SYSTEM "doc.dtd"><doc>&e; &s;</doc>});
    my $doc = file_slurp("$dir/doc.xml", plugin => 'xml', profile => 'full', resolve => 'file');
    is($doc->root->text, 'from dtd from sub', 'file_slurp with resolve => "file" reads beside the document, and below it');
    file_spew("$dir/url.xml", qq{<!DOCTYPE doc SYSTEM "file://$real/doc.dtd"><doc>&e;</doc>});
    is(file_slurp("$dir/url.xml", plugin => 'xml', profile => 'full', resolve => 'file')->root->text, 'from dtd', 'a file: identifier inside the directory');

    my $slurp_refused = sub {
        my ($xml, $name) = @_;
        file_spew("$dir/$name", $xml);
        my $ok = eval { file_slurp("$dir/$name", plugin => 'xml', profile => 'full', resolve => 'file'); 1 };
        return $ok ? '' : $@;
    };
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "../out.dtd"><doc/>}, 'up.xml'), qr/escapes the document's directory|does not name a readable file/, '.. is refused');
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "$out/out.dtd"><doc/>}, 'abs.xml'), qr/escapes the document's directory/, 'an absolute path elsewhere is refused');
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "file://$out/out.dtd"><doc/>}, 'absurl.xml'), qr/escapes the document's directory/, 'so is a file: identifier elsewhere');
  SKIP: {
        skip 'no symlinks here', 1 unless eval { symlink("$out/out.dtd", "$dir/link.dtd") };
        like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "link.dtd"><doc/>}, 'link.xml'), qr/escapes the document's directory/, 'a symbolic link out is refused at its target');
    }
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "sub"><doc/>}, 'dir.xml'), qr/not a regular file/, 'a directory is refused');
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "none.dtd"><doc/>}, 'none.xml'), qr/does not name a readable file/, 'a missing file is refused');
    like($slurp_refused->(qq{<!DOCTYPE doc SYSTEM "http://x.org/doc.dtd"><doc/>}, 'http.xml'), qr/only a file path or a file: identifier/, 'another scheme is refused');
    ok(!eval { file_xml_decode('<!DOCTYPE doc SYSTEM "doc.dtd"><doc/>', profile => 'full', resolve => 'file'); 1 }, 'the codec has no directory');
    like($@, qr/resolve => 'file' needs a document with a path; use file_slurp/, 'and says to use file_slurp');
    ok(!eval { file_slurp("$dir/doc.xml", plugin => 'xml', resolve => 'file'); 1 }, 'strict through the plugin refuses the option');
}

done_testing;
