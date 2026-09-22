#!/usr/bin/env perl
# k114: maint/crd-drift-check.pl's _slurp repairs a cache file that was
# UTF-8-encoded twice (a manifest fetched by a pre-k94 version of the script,
# which wrote undecoded HTTP bytes through a '>:encoding(UTF-8)' handle).
#
# The repair is a heuristic guarded by a strict round trip, and BOTH halves
# need holding down: the signature has to recognise a doubled character of
# any length -- before k114 it only knew doubled 2-byte originals, so an en
# dash slipped through and --check reported a permanent false difference
# against a perfectly good checked-in class -- while the round trip has to
# keep text that merely LOOKS like the signature completely untouched. That
# second half is the one a widened signature puts at risk, so it is a test
# case here, not an argument in a comment.
#
# The script has no `unless caller` guard and its main body runs on load, so
# _slurp is lifted out of the source text and evaluated on its own. That is
# deliberate and it is also an assertion: rename or restructure the sub and
# this test says so instead of quietly testing nothing.
use strict;
use warnings;
use Test::More;
use Encode ();
use File::Temp ();
use FindBin;

my $script = "$FindBin::Bin/../maint/crd-drift-check.pl";
ok(-f $script, 'maint/crd-drift-check.pl is there to test');

my $source = do {
    open my $fh, '<:raw', $script or die "cannot read $script: $!";
    local $/;
    <$fh>;
};

# The signature qr// and the sub, each taken whole: from its opening line to
# the first line that is just a closing brace at column 0.
my ($signature) = $source =~ /^(my \$DOUBLE_ENCODED_RUN = qr\{.*?^\}x;)$/ms;
ok($signature, 'found the $DOUBLE_ENCODED_RUN signature in the script')
    or BAIL_OUT('maint/crd-drift-check.pl no longer defines $DOUBLE_ENCODED_RUN');

my ($sub) = $source =~ /^(sub _slurp \{.*?^\})$/ms;
ok($sub, 'found sub _slurp in the script')
    or BAIL_OUT('maint/crd-drift-check.pl no longer defines sub _slurp');

{
    package T89;
    use strict;
    use warnings;
    require Encode;
    ## no critic
    eval "$signature\n$sub\n1;" or die "cannot eval _slurp out of the script: $@";
}

# Writes raw bytes to a temp file and reads them back through the real
# _slurp, which is what the drift check does with a cached manifest.
my $tmpdir = File::Temp->newdir;
my $n      = 0;
sub slurped {
    my ($bytes) = @_;
    my $path = "$tmpdir/case" . ++$n . '.yaml';
    open my $fh, '>:raw', $path or die $!;
    print $fh $bytes;
    close $fh;
    return T89::_slurp($path);
}

# The bytes a character ends up as when its UTF-8 is misread as Latin-1 and
# re-encoded -- exactly what the pre-k94 fetch path produced on disk.
sub doubled { Encode::encode('UTF-8', Encode::decode('iso-8859-1', Encode::encode('UTF-8', $_[0]))) }

subtest 'a doubled character is repaired, whatever its length' => sub {
    my %cases = (
        'MICRO SIGN (2-byte, U+00B5)'  => "\x{00B5}",
        'u-umlaut (2-byte, U+00FC)'    => "\x{00FC}",
        'EN DASH (3-byte, U+2013)'     => "\x{2013}",
        'LEFT DOUBLE QUOTE (3-byte)'   => "\x{201C}",
        'CJK (3-byte, U+4E00)'         => "\x{4E00}",
        'emoji (4-byte, U+1F600)'      => "\x{1F600}",
    );
    for my $what (sort keys %cases) {
        my $char = $cases{$what};
        my $text = "description: io.kubernetes.pod.name $char the Pod's name\n";
        is(slurped('description: io.kubernetes.pod.name ' . doubled($char) . " the Pod's name\n"),
            $text, "$what: read back as the character upstream wrote");
    }

    # The exact bytes the shipped Cilium cache holds, spelled out rather
    # than generated, so this fails if the repair stops covering the case
    # that motivated k114.
    is(slurped("  io.kubernetes.pod.name \xC3\xA2\xC2\x80\xC2\x93 the Pod's name\n"),
        "  io.kubernetes.pod.name \x{2013} the Pod's name\n",
        'the CiliumPodIPPool line: C3 A2 C2 80 C2 93 -> a single U+2013');
};

subtest 'text that only LOOKS like the signature comes back untouched' => sub {
    # Every case here carries a byte run the signature matches. None of them
    # is double-encoded, and the strict FB_CROAK round trip is what has to
    # notice -- so each must come back exactly as decoded, character for
    # character, and in particular must not be mangled into U+FFFD.

    # 1. A codepoint above U+00FF anywhere else in the file: encode() to
    #    iso-8859-1 croaks, the repair is refused for the WHOLE text.
    my $with_emoji = "note: \x{1F600}\ndash: \x{00E2}\x{0080}\x{0093}\n";
    is(slurped(Encode::encode('UTF-8', $with_emoji)), $with_emoji,
        'a real emoji elsewhere keeps the signature run as the three characters it is');

    # 2. The same, with an ALREADY-correct en dash beside the run -- the
    #    realistic shape of a manifest someone half-repaired by hand.
    my $mixed = "a: \x{2013}\nb: \x{00E2}\x{0080}\x{0093}\n";
    is(slurped(Encode::encode('UTF-8', $mixed)), $mixed,
        'a correct en dash elsewhere refuses the repair rather than doubling down');

    # 3. Everything is Latin-1-representable, but the reinterpreted bytes
    #    are not valid UTF-8 (a trailing lone lead byte): decode() croaks.
    my $invalid = "x: \x{00E2}\x{0080}\x{0093} y: \x{00E2}\n";
    is(slurped(Encode::encode('UTF-8', $invalid)), $invalid,
        'a Latin-1 reinterpretation that is not valid UTF-8 is refused');

    # 4. The round-2 regression the narrow signature was written for: a
    #    legitimately cached 'Grüße'/'Delai' must not become U+FFFD. It
    #    does not even reach the round trip -- 'ü' alone is not the run.
    my $german = "summary: Grenzwert fur Gru\x{00DF}e und Delai\n";
    is(slurped(Encode::encode('UTF-8', $german)), $german,
        'a lone Latin-1 letter is not the signature at all');

    # 5. Plain ASCII: nothing to do, byte for byte.
    my $ascii = "apiVersion: apiextensions.k8s.io/v1\nkind: CustomResourceDefinition\n";
    is(slurped($ascii), $ascii, 'ASCII passes through unchanged');
};

subtest 'the boundaries the signature deliberately does not cross' => sub {
    # The 2-byte row stays narrowed to a doubled C2/C3 lead. Widening it to
    # the full C2-DF would make 'A-umlaut' + 'left guillemet' (C3 84 C2 AB)
    # match -- and that text DOES survive the round trip, so it would be
    # silently rewritten to a single U+012B. It must not be touched.
    my $latvian = "label: \x{00C4}\x{00AB}\n";
    is(slurped(Encode::encode('UTF-8', $latvian)), $latvian,
        q{'\x{00C4}\x{00AB}' is left alone: the 2-byte row is not widened past C2/C3});

    # A doubled lead byte with too FEW following pairs is not a doubled
    # character either -- a 3-byte original leaves two of them behind.
    my $short = "x: \x{00E2}\x{0080}z\n";
    is(slurped(Encode::encode('UTF-8', $short)), $short,
        'a C3 A2 run with only one C2 pair is not the 3-byte signature');
};

done_testing;
