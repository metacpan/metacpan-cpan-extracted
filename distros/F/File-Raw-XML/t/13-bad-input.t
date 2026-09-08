#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Every way to cut a document. For each sample: every prefix is parsed, and
# must be refused - with the prefix, and a byte offset no greater than the
# cut - unless the bytes removed were nothing but trailing misc after the
# root, in which case it must parse; the whole sample parses; every
# single-byte deletion parses or is refused with the prefix; and every
# prefix of the sample's exclusive canonical output is treated the same
# way, because the serialiser's output is the input a signature check
# re-reads. Nothing here may die any other way, and nothing may crash.
#
# The hand-written sample exercises every token kind. Samples under t/data
# are included when present and under 64 KiB, so the file stays quick on a
# smoker. Failures are counted per pass and the first few are shown,
# rather than one assertion per cut.

my $SAMPLE = join '',
    qq{<?xml version="1.0" encoding="UTF-8"?>\n},
    qq{<!-- a leading comment -->\n},
    qq{<?lead some data?>\r\n},
    qq{<r xmlns="urn:d" xmlns:p="urn:p" ID="root" a="1 &amp; 2" p:b="&#10;x&#x3C;" xml:lang="en">\n},
    qq{  <p:e ID="e1" p:z="&quot;q&quot;">text &lt; &gt; &amp; &quot; &apos; &#169; &#xA9; \xc3\xa9 \xe6\x97\xa5\xe6\x9c\xac</p:e>\r\n},
    qq{  <f xmlns=""><g xmlns:p="urn:q"><p:h/><![CDATA[<x> & y ]] ]]></g></f>\n},
    qq{  <!-- inside --><?pi inside data?><?bare?>\n},
    qq{  <d1><d2><d3><d4><d5 attr='single'>deep\ttext</d5></d4></d3></d2></d1>\n},
    qq{  <empty/><p:empty ID="e2"/>\n},
    qq{</r>\n},
    qq{<!-- a trailing comment -->\n},
    qq{<?done?>\n};

# misc after the root: whitespace, comments, processing instructions
my $MISC = qr/\A(?:\s|<!--(?:(?!--).)*-->|<\?(?:(?!\?>).)*\?>)*\z/s;

our %OPTS = (id_attrs => ['ID']);

sub attempt {
    my ($bytes) = @_;
    my $doc = eval { file_xml_decode($bytes, %OPTS) };
    return ($doc, $doc ? '' : $@);
}

# a refusal in the one shape, or the reason it is not
sub refusal_fault {
    my ($msg, $cut) = @_;
    return 'no prefix'  unless $msg =~ /^File::Raw::XML: /;
    return 'no offset'  unless $msg =~ /(?:at byte offset (\d+) near "|at end of input)/;
    return "offset $1 past the cut at $cut" if defined $1 && defined $cut && $1 > $cut;
    return '';
}

sub show { my ($s) = @_; $s = substr($s, 0, 60); $s =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge; $s }

# The statement-modifier form of this, `is(...) or diag $_ for @$faults`,
# puts the whole expression under the loop, so a pass ran no assertion at
# all: keep the loop inside the block.
sub report {
    my ($name, $total, $faults) = @_;
    unless (is(scalar @$faults, 0, "$name: $total cuts, none mishandled")) {
        diag "  $_" for @$faults[0 .. ($#$faults < 4 ? $#$faults : 4)];
    }
}

sub every_prefix {
    my ($name, $bytes) = @_;
    my @faults;
    for my $i (0 .. length($bytes) - 1) {
        my $prefix = substr($bytes, 0, $i);
        my ($doc, $msg) = attempt($prefix);
        my $tail_is_misc = $i > 0 && substr($bytes, $i) =~ $MISC;
        if ($tail_is_misc) {
            push @faults, "prefix $i should parse (the tail is misc): " . show($msg) unless $doc;
        }
        elsif ($doc) {
            push @faults, "prefix $i parsed but the tail is not misc: " . show(substr $bytes, $i);
        }
        elsif (my $f = refusal_fault($msg, $i)) {
            push @faults, "prefix $i: $f: " . show($msg);
        }
    }
    report("$name: every prefix", length $bytes, \@faults);
}

sub every_deletion {
    my ($name, $bytes) = @_;
    my @faults;
    for my $i (0 .. length($bytes) - 1) {
        my $cut = substr($bytes, 0, $i) . substr($bytes, $i + 1);
        my ($doc, $msg) = attempt($cut);
        next if $doc;
        if (my $f = refusal_fault($msg, undef)) {
            push @faults, "deletion at $i: $f: " . show($msg);
        }
    }
    report("$name: every single-byte deletion", length $bytes, \@faults);
}

sub sample {
    my ($name, $bytes) = @_;
    every_prefix($name, $bytes);
    my ($doc, $msg) = attempt($bytes);
    ok($doc, "$name: the whole sample parses") or do { diag $msg; return };
    every_deletion($name, $bytes);
    my $c14n = $doc->c14n(mode => 'exclusive', comments => 1);
    ok(length $c14n, "$name: has an exclusive canonical form");
    every_prefix("$name: c14n output", $c14n);
    my ($again) = attempt($c14n);
    ok($again, "$name: the canonical form parses whole");
}

sample('hand-written', $SAMPLE);

# t/pinned holds the documents t/21 canonicalises against a recorded
# digest, so they are the shapes a signature check actually meets; t/data
# is where the release checklist puts the two real documents it obtains,
# and is empty until then.
for my $file (sort(glob 't/pinned/*.xml'), sort(glob 't/data/*.xml')) {
    my $bytes = do { open my $fh, '<:raw', $file or die "$file: $!"; local $/; <$fh> };
    if (length $bytes > 64 * 1024) {
        diag "$file: " . length($bytes) . " bytes, over the 64 KiB cap; not cut here";
        next;
    }
    sample($file, $bytes);
}


# ---- the full profile --------------------------------------------------------

# The same treatment where the surface is widest: a DOCTYPE with an
# internal subset, a parameter entity, an external subset, an external
# entity and an XInclude, all over a hash-backed resolver, so every cut is
# made with the fetch machinery running. What is being asserted is the same
# one shape - refused with the prefix, and with an offset in the document
# that was cut, never one carried in from the text a resolver handed back.
{
    my $XI = 'http://www.w3.org/2001/XInclude';
    my %files = (
        'http://x.org/t/ext.dtd' => qq{<!ELEMENT a EMPTY>\n<!ATTLIST a y CDATA #IMPLIED>\n},
        'http://x.org/t/ext.ent' => 'external &e; text',
        'http://x.org/t/inc.xml' => '<a y="1"/>',
    );
    local %OPTS = (
        %OPTS,
        profile  => 'full',
        validate => 'collect',
        xinclude => 1,
        base     => 'http://x.org/t/doc.xml',
        resolve  => sub {
            my %r = @_;
            die "no such resource: $r{system_id}\n"
                unless exists $files{ $r{system_id} };
            return $files{ $r{system_id} };
        },
    );

    my $FULL = join '',
        qq{<?xml version="1.0" encoding="UTF-8"?>\n},
        qq{<!DOCTYPE r SYSTEM "ext.dtd" [\n},
        qq{<!ELEMENT r ANY>\n},
        qq{<!ATTLIST r ID ID #IMPLIED x CDATA "dx" k (p|q) "q">\n},
        qq{<!ENTITY e "in &#38;#38; line">\n},
        qq{<!ENTITY ext SYSTEM "ext.ent">\n},
        qq{<!ENTITY % pe "<!ENTITY g 'from a parameter entity'>">\n},
        qq{%pe;\n},
        qq{<!NOTATION n PUBLIC "a public id">\n},
        qq{<!ENTITY pic SYSTEM "p.gif" NDATA n>\n},
        qq{]>\n},
        qq{<r xmlns:xi="$XI" ID="r1">&e;&g;&ext;<xi:include href="inc.xml"/></r>\n},
        qq{<!-- after -->\n};

    sample('full profile', $FULL);
}

done_testing;
