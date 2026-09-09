#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Raw::XML qw(file_xml_decode);

# The writer: each option on one fixture with the expected bytes inline,
# the refusals, and the round-trip property over every document under t/
# and every valid conformance case: parse, to_string, parse, equal under
# the data model, and the exclusive canonical bytes identical.

sub full { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', %o) }

my $FIXTURE = qq{<?xml version="1.0"?>\n<!DOCTYPE r [\n<!ENTITY e "E">\n<!ATTLIST r d CDATA "dv">\n]>\n<!-- c -->\n<r xmlns="urn:r" a="1&#xD;2">t&e;<![CDATA[x]]>y<b p:q="&lt;" xmlns:p="urn:p"/><?pi da?></r>\n<?after?>};

# the defaults: declaration, DOCTYPE as recorded, entities gone, CDATA back
{
    my $doc = full($FIXTURE);
    my $out = $doc->to_string;
    is($out, qq{<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE r [\n<!ENTITY e "E">\n<!ATTLIST r d CDATA "dv">\n]>\n<!-- c -->\n<r xmlns="urn:r" a="1&#xD;2" d="dv">tE<![CDATA[x]]>y<b xmlns:p="urn:p" p:q="&lt;"/><?pi da?></r>\n<?after?>},
       'to_string with the defaults: the subset as written, the default materialised, the entity as text, the CDATA section back');
    ok(!utf8::is_utf8($out), 'bytes, no character flag');
    ok(full($out)->equals($doc), 'and it parses to an equal document');
    is($doc->to_string(declaration => 0, doctype => 0), qq{<!-- c -->\n<r xmlns="urn:r" a="1&#xD;2" d="dv">tE<![CDATA[x]]>y<b xmlns:p="urn:p" p:q="&lt;"/><?pi da?></r>\n<?after?>}, 'declaration and doctype off');
    my ($b) = $doc->root->elements;
    is($b->to_string, qq{<b xmlns:p="urn:p" xmlns="urn:r" p:q="&lt;"/>}, 'a node on its own: its declarations, then the bindings in scope, no declaration');
    is($b->to_string(declaration => 1), qq{<?xml version="1.0" encoding="UTF-8"?>\n<b xmlns:p="urn:p" xmlns="urn:r" p:q="&lt;"/>}, 'with the declaration when asked');
    is(full($b->to_string)->root->c14n, $b->c14n, 'the node written alone canonicalises as it did in place');
    is($doc->root->to_string(empty_short => 0), qq{<r xmlns="urn:r" a="1&#xD;2" d="dv">tE<![CDATA[x]]>y<b xmlns:p="urn:p" p:q="&lt;"></b><?pi da?></r>}, 'empty_short off');
}

# indentation
{
    my $doc = full('<a><b><c/>x</b><d/><!-- k --></a>');
    is($doc->to_string(indent => 2, declaration => 0), qq{<a>\n  <b><c/>x</b>\n  <d/>\n  <!-- k -->\n</a>}, 'indent lays out element children; an element with text is left alone');
    my $ws = full(qq{<a>\n  <b/>\n</a>});
    is($ws->to_string(indent => 4, declaration => 0), qq{<a>\n  <b/>\n</a>}, 'whitespace-only text keeps the element as it is');
    is($ws->to_string(indent => 4, declaration => 0, drop_ws => 1), qq{<a>\n    <b/>\n</a>}, 'unless drop_ws drops it');
    my $pre = full('<a><pre><b/></pre><p xml:space="preserve"><q/><r xml:space="default"><s/></r></p><o><t/></o></a>');
    is($pre->to_string(indent => 1, declaration => 0, preserve => ['pre']),
       qq{<a>\n <pre><b/></pre>\n <p xml:space="preserve"><q/><r xml:space="default">\n   <s/>\n  </r></p>\n <o>\n  <t/>\n </o>\n</a>},
       'preserve by name and by xml:space, with xml:space="default" turning it back on');
}

# quotes and escaping
{
    my $doc = full(qq{<a b='"x"' c="it's">"q" &amp; 'a' &lt; &gt;</a>});
    is($doc->to_string(declaration => 0), qq{<a b="&quot;x&quot;" c="it's">"q" &amp; 'a' &lt; &gt;</a>}, 'the minimum: & < > and the double quote in values');
    is($doc->to_string(declaration => 0, quote => "'"), qq{<a b='"x"' c='it&#39;s'>"q" &amp; 'a' &lt; &gt;</a>}, 'quote => \' escapes the apostrophe instead');
    is($doc->to_string(declaration => 0, escape_all => 1), qq{<a b="&quot;x&quot;" c="it's">&quot;q&quot; &amp; &#39;a&#39; &lt; &gt;</a>}, 'escape_all escapes both quotes in text');
    my $ws = full(qq{<a b=" &#x9;&#xA;&#xD; ">x&#xD;y\n</a>});
    is($ws->to_string(declaration => 0), qq{<a b=" &#x9;&#xA;&#xD; ">x&#xD;y\n</a>}, 'tab, line feed and carriage return in a value, and a carriage return in text, stay references');
    ok(!eval { $doc->to_string(quote => 'x'); 1 }, 'a quote that is neither dies');
    ok(!eval { $doc->to_string(bogus => 1); 1 }, 'an unknown option dies');
}

# encodings
{
    my $doc = full(qq{<r a="\xC3\xA9">caf\xC3\xA9 \xF0\x9F\x98\x80</r>});
    my $u16 = $doc->to_string(encoding => 'UTF-16');
    like($u16, qr/^\xFF\xFE</, 'UTF-16 opens with a little-endian byte order mark');
    require Encode;
    is(Encode::decode('UTF-16LE', substr($u16, 2)), qq{<?xml version="1.0" encoding="UTF-16LE"?>\n<r a="\x{e9}">caf\x{e9} \x{1F600}</r>}, 'and holds the document');
    ok(full($u16)->equals($doc), 'which parses back equal under the full profile');
    like($doc->to_string(encoding => 'UTF-16BE'), qr/^\xFE\xFF\x00</, 'UTF-16BE, big-endian');
    is($doc->to_string(encoding => 'ISO-8859-1'), qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n<r a="\xE9">caf\xE9 &#x1F600;</r>}, 'ISO-8859-1: a byte for what it holds, a reference for what it cannot');
    is($doc->to_string(encoding => 'US-ASCII'), qq{<?xml version="1.0" encoding="US-ASCII"?>\n<r a="&#xE9;">caf&#xE9; &#x1F600;</r>}, 'US-ASCII: references beyond 127');
    ok(full($doc->to_string(encoding => 'US-ASCII'))->equals($doc), 'and that parses back equal');
    my $chars = $doc->to_string(encoding => 'perl');
    ok(utf8::is_utf8($chars), 'encoding => perl returns characters');
    is($chars, qq{<?xml version="1.0"?>\n<r a="\x{e9}">caf\x{e9} \x{1F600}</r>}, 'with no encoding in the declaration');
    my $cm = full(qq{<r><!-- \xF0\x9F\x98\x80 --></r>});
    ok(!eval { $cm->to_string(encoding => 'US-ASCII'); 1 }, 'a character the encoding cannot hold in a comment dies');
    like($@, qr/cannot be written in the output encoding stands where no reference can/, 'saying why');
    ok(!eval { $doc->to_string(encoding => 'EBCDIC'); 1 }, 'an unknown encoding dies');
}

# XML 1.1 and standalone
{
    my $doc = full(qq{<?xml version="1.1" standalone="yes"?><r>a&#x1;b</r>});
    is($doc->to_string, qq{<?xml version="1.1" encoding="UTF-8" standalone="yes"?>\n<r>a&#x1;b</r>}, 'the version and standalone as declared; a restricted character as a reference');
    ok(full($doc->to_string)->equals($doc), 'and it parses back equal');
}

# equals
{
    my $a = full('<r xmlns="urn:a" x="1" y="2"><s>t</s></r>');
    ok($a->equals(full('<z:r xmlns:z="urn:a" y="2" x="1"><z:s>t</z:s></z:r>')), 'equal across prefixes and attribute order');
    ok(!$a->equals(full('<r xmlns="urn:a" x="1" y="3"><s>t</s></r>')), 'not with a different value');
    ok(!$a->equals(full('<r xmlns="urn:b" x="1" y="2"><s>t</s></r>')), 'nor namespace');
    ok(!$a->equals(full('<r xmlns="urn:a" x="1" y="2"><s>t</s><u/></r>')), 'nor an extra child');
    ok(!$a->equals(full('<r xmlns="urn:a" x="1" y="2"><s>t<!-- c --></s></r>')), 'nor a comment');
    ok(full('<r><![CDATA[a]]>b</r>')->equals(full('<r>ab</r>')), 'CDATA boundaries do not count');
    ok(!eval { $a->equals('x'); 1 }, 'equals wants a document');
}

# the round trip over every document under t/, and the conformance suite's
# valid cases when it is here
{
    my @files = sort glob('t/pinned/*.xml');
    my $root = 't/xmlconf/xmlconf';
    my %opts_for;
    if (-f "$root/xmlconf.xml") {
        for my $cat (qw(xmltest/xmltest.xml ibm/ibm_oasis_valid.xml sun/sun-valid.xml oasis/oasis.xml eduni/xml-1.1/xml11.xml)) {
            my $text = do { open my $fh, '<:raw', "$root/$cat" or next; local $/; <$fh> };
            my $dir  = $cat;
            $dir =~ s{/[^/]+$}{};
            while ($text =~ m{<TEST\b([^>]*)>}g) {
                my $attrs = $1;
                my %a;
                while ($attrs =~ /([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g) { $a{$1} = defined $2 ? $2 : $3 }
                next unless ($a{TYPE} // '') eq 'valid';
                next if ($a{NAMESPACE} // 'yes') eq 'no';
                next if defined $a{EDITION} && $a{EDITION} !~ /(?:^|\s)5(?:\s|$)/;
                my $p = "$root/$dir/$a{URI}";
                next unless -f $p;
                push @files, $p;
            }
        }
    }
    my $resolve = sub { my %r = @_; open my $fh, '<:raw', $r{system_id} or die "cannot read $r{system_id}\n"; local $/; <$fh> };
    my ($n, $bad) = (0, 0);
    for my $path (@files) {
        my $bytes = do { open my $fh, '<:raw', $path or die; local $/; <$fh> };
        my %o = (base => abs_path($path), resolve => $resolve);
        my $doc = eval { full($bytes, %o) } or next;   # a case this build refuses is run.t's business
        $n++;
        for my $variant ([], [indent => 2, drop_ws => 1], [encoding => 'UTF-16'], [empty_short => 0, quote => "'"]) {
            my $again = eval { full($doc->to_string(@$variant), %o) };
            if (!$again) { $bad++; diag("$path (@$variant): reparse failed: $@"); next }
            my $equal = $again->equals($doc) || (@$variant && $variant->[0] eq 'indent');
            my $c14n  = $variant->[0] && $variant->[0] eq 'indent' ? 1 : $again->c14n eq $doc->c14n;
            if (!$equal || !$c14n) { $bad++; diag("$path (@$variant): not equal after the round trip") }
        }
    }
    cmp_ok($n, '>=', 10, "$n documents round-tripped");
    is($bad, 0, 'every one parses back equal, with identical exclusive canonical bytes');
}

done_testing;
