#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Raw::XML qw(file_xml_decode);

# The W3C XML Conformance Test Suite, over the partitions claimed below.
# The suite lives under t/xmlconf/xmlconf/ when
# tools/xmlconf/fetch.sh has put it there and is never shipped, so this
# test skips by name without it.
#
# xmlconf.xml is itself an XML document whose catalogue is pulled in by
# entities, which is a DOCTYPE feature this parser refuses under strict,
# so the catalogue is read by a regex walker: the ENTITY SYSTEM
# declarations name the catalogue files, and inside each the TEST elements
# are flat - one element, a few attributes, a text body - with TESTCASES
# wrappers that may carry an xml:base. The walker stays after the full
# profile can parse the catalogue itself, as the cross-check that the real
# parse found every case.
#
# Selection is by partition (a directory prefix of the URI), TYPE,
# ENTITIES and RECOMMENDATION. A partition is claimed by adding its
# selector to @PARTITIONS. Outcomes: valid parses; not-wf refuses; invalid
# parses with a validity error and no well-formedness error under
# validate => 'collect'; error is the "at user option" class and
# passes either way, with the choice noted. t/xmlconf/expected-fail.txt
# lists known failures one id per line with a reason; a listed case that
# passes is a failure too, so the list only shrinks.

my $ROOT = 't/xmlconf/xmlconf';
plan skip_all => "the conformance suite is not under $ROOT; run tools/xmlconf/fetch.sh"
    unless -f "$ROOT/xmlconf.xml";

# the partitions claimed: [ catalogue-entity, uri-prefix, type, entities, recommendation, profile ]
# Every partition runs under the full profile: the strict profile's
# refusal of every DOCTYPE is pinned by t/30 and tested by t/33, and a
# case listed in expected-fail.txt is keyed by id alone, so one case runs
# under one profile. Cases the catalogue marks NAMESPACE="no" are not
# namespace-well-formed, which this parser refuses by design (decision G),
# and are left out by the walker.
my @PARTITIONS = (
    # every partition is open to the cases that need external entities
    # ('any'), served by a file resolver over the suite's own tree
    [ 'jclark-xmltest', 'valid/',   'valid',   'any', 'XML1.0', 'full' ],
    [ 'jclark-xmltest', 'not-wf/',  'not-wf',  'any', 'XML1.0', 'full' ],
    [ 'jclark-xmltest', 'invalid/', 'invalid', 'any', 'XML1.0', 'full' ],
    [ 'jclark-xmltest', 'not-wf/',  'error',   'any', 'XML1.0', 'full' ],
    [ 'ibm-valid',   'valid/',   'valid',   'any', 'XML1.0', 'full' ],
    [ 'ibm-not-wf',  'not-wf/',  'not-wf',  'any', 'XML1.0', 'full' ],
    [ 'ibm-not-wf',  '',         'error',   'any', 'XML1.0', 'full' ],
    [ 'ibm-invalid', 'invalid/', 'invalid', 'any', 'XML1.0', 'full' ],
    [ 'ibm-invalid', '',         'error',   'any', 'XML1.0', 'full' ],
    [ 'sun-valid',   'valid/',   'valid',   'any', 'XML1.0', 'full' ],
    [ 'sun-not-wf',  'not-wf/',  'not-wf',  'any', 'XML1.0', 'full' ],
    [ 'sun-invalid', 'invalid/', 'invalid', 'any', 'XML1.0', 'full' ],
    [ 'sun-error',   '',         'error',   'any', 'XML1.0', 'full' ],
    [ 'nist-oasis',  '',         'valid',   'any', 'XML1.0', 'full' ],
    [ 'nist-oasis',  '',         'not-wf',  'any', 'XML1.0', 'full' ],
    [ 'nist-oasis',  '',         'invalid', 'any', 'XML1.0', 'full' ],
    # the encodings partition: the two the specification requires of every
    # processor are parsed, and the legacy Japanese ones are refused by
    # name, which is the "at user option" class and a pass either way
    [ 'xerox-japanese', '', 'valid', 'any', 'XML1.0', 'full' ],
    [ 'xerox-japanese', '', 'error', 'any', 'XML1.0', 'full' ],
    [ 'eduni-errata2e', '', 'valid',   'any', 'XML1.0-errata2e', 'full' ],
    [ 'eduni-errata2e', '', 'not-wf',  'any', 'XML1.0-errata2e', 'full' ],
    [ 'eduni-errata2e', '', 'invalid', 'any', 'XML1.0-errata2e', 'full' ],
    [ 'eduni-errata2e', '', 'error',   'any', 'XML1.0-errata2e', 'full' ],
    [ 'eduni-errata3e', '', 'valid',   'any', 'XML1.0-errata3e', 'full' ],
    [ 'eduni-errata3e', '', 'not-wf',  'any', 'XML1.0-errata3e', 'full' ],
    [ 'eduni-errata3e', '', 'invalid', 'any', 'XML1.0-errata3e', 'full' ],
    [ 'eduni-errata4e', '', 'valid',   'any', 'XML1.0-errata4e', 'full' ],
    [ 'eduni-errata4e', '', 'not-wf',  'any', 'XML1.0-errata4e', 'full' ],
    [ 'eduni-errata4e', '', 'invalid', 'any', 'XML1.0-errata4e', 'full' ],
    [ 'eduni-errata4e', '', 'error',   'any', 'XML1.0-errata4e', 'full' ],
    [ 'eduni-misc',  '', 'not-wf',  'any', 'XML1.0', 'full' ],
    [ 'eduni-misc',  '', 'invalid', 'any', 'XML1.0', 'full' ],
    # XML 1.1, both suites: eduni's and IBM's
    [ 'eduni-xml11', '', 'valid',   'any', 'XML1.1', 'full' ],
    [ 'eduni-xml11', '', 'invalid', 'any', 'XML1.1', 'full' ],
    [ 'eduni-xml11', '', 'not-wf',  'any', 'XML1.1', 'full' ],
    [ 'eduni-xml11', '', 'error',   'any', 'XML1.1', 'full' ],
    [ 'ibm-xml1.1-valid',   '', 'valid',   'any', 'XML1.1', 'full' ],
    [ 'ibm-xml1.1-not-wf',  '', 'not-wf',  'any', 'XML1.1', 'full' ],
    [ 'ibm-xml1.1-invalid', '', 'invalid', 'any', 'XML1.1', 'full' ],
    # Namespaces in XML: this parser resolves namespaces at parse and
    # refuses what is not namespace-well-formed, so these cases are its
    # own rather than a layer above it. 1.1 goes with XML 1.1, which is
    # what selects prefix undeclaration.
    [ 'eduni-ns10', '', 'valid',   'any', 'NS1.0', 'full' ],
    [ 'eduni-ns10', '', 'not-wf',  'any', 'NS1.0', 'full' ],
    [ 'eduni-ns10', '', 'invalid', 'any', 'NS1.0', 'full' ],
    [ 'eduni-ns10', '', 'error',   'any', 'NS1.0', 'full' ],
    [ 'eduni-ns11', '', 'valid',   'any', 'NS1.1', 'full' ],
    [ 'eduni-ns11', '', 'not-wf',  'any', 'NS1.1', 'full' ],
    [ 'eduni-nse',  '', 'not-wf',  'any', 'NS1.0-errata1e', 'full' ],
);

# the resolver the partitions share: the file named, read raw; a case's
# base is its own absolute path, so every system identifier arrives
# resolved against the file that declared it
sub resolve_file {
    my %r = @_;
    my $p = $r{system_id};
    open my $fh, '<:raw', $p or die "cannot read $p: $!\n";
    local $/;
    return <$fh>;
}

# ---- the catalogue walker -------------------------------------------------

sub slurp { my ($f) = @_; open my $fh, '<:raw', $f or die "$f: $!"; local $/; <$fh> }

sub catalogues {
    my $top = slurp("$ROOT/xmlconf.xml");
    my %cat;
    while ($top =~ /<!ENTITY\s+([\w.-]+)\s+SYSTEM\s+"([^"]+)"/g) {
        $cat{$1} = "$ROOT/$2";
    }
    return \%cat;
}

sub decode_attr {
    my ($v) = @_;
    $v =~ s/&lt;/</g; $v =~ s/&gt;/>/g; $v =~ s/&quot;/"/g; $v =~ s/&apos;/'/g;
    $v =~ s/&#(\d+);/chr($1)/ge; $v =~ s/&#x([0-9a-fA-F]+);/chr(hex $1)/ge;
    $v =~ s/&amp;/&/g;
    return $v;
}

# every TEST in a catalogue file, with its URI resolved against the
# catalogue's directory and any enclosing TESTCASES xml:base
sub tests_in {
    my ($file) = @_;
    my $text = slurp($file);
    my $dir  = dirname($file);
    my @base = ('');
    my @out;
    while ($text =~ m{<(/?)(TESTCASES|TEST)\b([^>]*)>}g) {
        my ($close, $tag, $attrs) = ($1, $2, $3);
        if ($tag eq 'TESTCASES') {
            if ($close) { pop @base; next }
            my ($b) = $attrs =~ /xml:base="([^"]*)"/;
            push @base, defined $b ? $base[-1] . decode_attr($b) : $base[-1];
            next;
        }
        next if $close;
        my %a;
        while ($attrs =~ /([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g) { $a{$1} = decode_attr(defined $2 ? $2 : $3) }
        $a{RECOMMENDATION} //= 'XML1.0';
        $a{ENTITIES}       //= 'none';
        $a{NAMESPACE}      //= 'yes';
        $a{SECTIONS}       //= '';
        next if $a{NAMESPACE} eq 'no';
        # Appendix B of XML 1.0 editions one to four enumerated the name
        # character classes; the fifth edition deleted it and replaced the
        # tables with section 2.3's ranges, which admit most of what the
        # appendix excluded. The ibm not-wf cases filed under "B." test the
        # deleted appendix's boundaries, and a fifth edition processor
        # accepts most of them; they are not selected.
        next if $a{SECTIONS} eq 'B.' && $a{RECOMMENDATION} eq 'XML1.0';
        # the errata catalogues mark each case with the editions it holds
        # for; this is a fifth edition processor, so a case written for
        # editions one to four only is not its business
        next if defined $a{EDITION} && $a{EDITION} !~ /(?:^|\s)5(?:\s|$)/;
        $a{path} = "$dir/$base[-1]$a{URI}";
        push @out, \%a;
    }
    return @out;
}

# ---- the cases the specifications leave to the processor --------------------

# TYPE="error" is the class a conforming processor may report or not, so
# either outcome conforms and neither is a result on its own. What is worth
# pinning is that the choice is the one that was made on purpose: each id
# below records what this parser does and the sentence it follows, and a
# build that changes its mind fails here rather than changing a diagnostic
# nobody reads. An error case with no line is not a failure, but it is a
# case whose choice was never written down, so it says so.
my %AT_USER_OPTION = (
    'rmt-008' => ['refused',
        'a version this processor does not implement: 1.0 and 1.1 are the two sets of rules it has, and guessing which a "1.9" document meant is worse than saying so'],
    'rmt-009' => ['refused',
        'the same in an external general entity, where the text declaration names the version'],
    'rmt-055' => ['refused',
        'a lone 0x85 byte is not UTF-8, and the encoding is settled before 2.11 line ends are'],
    'rmt-056' => ['accepted',
        'NEL encoded in UTF-8 is a line end in XML 1.1 (section 2.11), including in the declaration'],
    'rmt-057' => ['accepted',
        'and so is LSEP'],
    'rmt-ns10-004' => ['refused',
        'a relative namespace name, deprecated by Namespaces in XML and refused here at parse, because a canonical form over a name that resolves differently per reader is not a signature anyone can check'],
    'rmt-ns10-005' => ['refused',
        'a same-document relative name, the same rule'],
    'rmt-ns10-006' => ['accepted',
        'an IRI that is not a URI: absolute is what is required, and no further syntax is imposed on a name used only for comparison'],
);

# ---- expected failures ------------------------------------------------------

my %expected_fail;
if (open my $fh, '<', 't/xmlconf/expected-fail.txt') {
    while (<$fh>) {
        next if /^\s*(?:#|$)/;
        my ($id, $why) = /^(\S+)\s+(.*)$/ or next;
        $expected_fail{$id} = $why;
    }
}

# ---- the run ------------------------------------------------------------------

my $cat = catalogues();
my ($ran, $passed, $xfail, $xpass) = (0, 0, 0, 0);

# TYPE="error" cases whose choice is not yet written down in
# %AT_USER_OPTION. Each is a pass either way, so they are counted and
# said in one line at the end rather than one line each: twenty-odd
# diagnostics scrolling past is how a real one gets missed.
# FRX_XMLCONF_CHOICES=1 lists them, which is what you want when you are
# about to write them down.
my %unrecorded;

for my $p (@PARTITIONS) {
    my ($entity, $prefix, $type, $entities, $rec, $profile) = @$p;
    my $file = $cat->{$entity} or do { fail("catalogue entity $entity is in xmlconf.xml"); next };
    my @cases = grep {
        index($_->{URI}, $prefix) == 0
        && $_->{TYPE} eq $type
        && ($entities eq 'any' || $_->{ENTITIES} eq $entities)
        && $_->{RECOMMENDATION} eq $rec
    } tests_in($file);
    ok(scalar @cases, "$entity $prefix $type/$entities/$rec: " . scalar(@cases) . " cases selected");

    for my $c (@cases) {
        my $bytes = -f $c->{path} ? slurp($c->{path}) : undef;
        my $outcome;
        if (!defined $bytes) {
            $outcome = "missing file $c->{path}";
        } else {
            my %opts = (profile => $profile, base => abs_path($c->{path}), resolve => \&resolve_file);
            $opts{validate} = 'collect' if $type eq 'valid' || $type eq 'invalid';
            my $doc = eval { file_xml_decode($bytes, %opts) };
            my $err = $@;
            if ($type eq 'valid') {
                my @e = $doc ? $doc->errors : ();
                $outcome = !$doc ? "refused: $err"
                         : @e   ? "valid, but reported: $e[0]"
                         :        'pass';
            } elsif ($type eq 'invalid') {
                my @e = $doc ? $doc->errors : ();
                $outcome = $doc && @e            ? 'pass'
                         : $doc                  ? 'accepted an invalid document with no validity error'
                         : $err =~ /\(VC: /      ? 'pass'
                         : "refused for well-formedness: $err";
            } elsif ($type eq 'not-wf') {
                $outcome = $doc ? 'accepted a document that is not well-formed' : 'pass';
            } else {
                my $did  = $doc ? 'accepted' : 'refused';
                my $said = $AT_USER_OPTION{ $c->{ID} };
                if (!$said) {
                    $outcome = 'pass';
                    push @{ $unrecorded{$did} }, $c->{ID};
                } elsif ($said->[0] eq $did) {
                    $outcome = 'pass';
                } else {
                    $outcome = "at user option this parser $did, but the recorded choice is "
                             . "$said->[0]: $said->[1]";
                }
            }
        }
        $ran++;
        my $why = $expected_fail{ $c->{ID} };
        if ($outcome eq 'pass') {
            if (defined $why) {
                $xpass++;
                fail("$c->{ID} is in expected-fail.txt ($why) but passes: remove the line");
            } else {
                $passed++;
                pass("$c->{ID}");
            }
        } else {
            if (defined $why) {
                $xfail++;
                pass("$c->{ID} fails as expected: $why");
            } else {
                fail("$c->{ID} [$c->{SECTIONS}] $c->{path}");
                diag($outcome);
            }
        }
    }
}

if (%unrecorded) {
    my $acc = @{ $unrecorded{accepted} || [] };
    my $ref = @{ $unrecorded{refused}  || [] };
    diag(sprintf "xmlconf: %d error-class cases have no recorded choice (%d accepted, %d refused);"
               . " FRX_XMLCONF_CHOICES=1 lists them", $acc + $ref, $acc, $ref);
    if ($ENV{FRX_XMLCONF_CHOICES}) {
        for my $did (sort keys %unrecorded) {
            diag("  $did: $_") for @{ $unrecorded{$did} };
        }
    }
}
diag("xmlconf: $ran run, $passed passed, $xfail expected failures, $xpass unexpected passes");
done_testing;
