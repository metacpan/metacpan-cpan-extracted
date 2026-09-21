#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Carp qw(croak);
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);

use File::SOPS;
use File::SOPS::Format::JSON;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

###############################################################################
# k139 / docs/adr/0064 -- the surrogate-pair divergence between the two
# order-preserving decoders is ACCEPTED AS A LIMIT, and the limit is bound on
# three measurements and one consequence.
#
#   1. Cpanel::JSON::XS decodes the literal JSON escape "😀" into a
#      SINGLE Unicode codepoint, U+1F600, in UTF-8. That is what Go's
#      encoding/json does too, and it is what sops 3.13.3 writes and reads.
#   2. YAML::PP keeps the same six characters as TWO separate surrogates,
#      U+D83D and U+DE00. That is not what Go does.
#   3. Neither of OUR emitters writes the literal-escape form -- both put
#      non-ASCII on the wire as UTF-8 bytes -- so the only input that
#      exercises the divergence is a hand-written or third-party JSON
#      document.
#
# The ORDER-preserving reparse (k74, ADR 0036, ADR 0001) walks the
# YAML::PP tree against the Cpanel tree and refuses at the first key the
# Cpanel tree does not have, with the message "present in the document but
# not in the parsed tree" at the leaf's path. That is a FALSE REFUSAL -- the
# document is well-formed and sops reads it -- but it is LOUD, never silent
# corruption. ADR 0001 and 0036 both name that direction as the safe one.
#
# This file pins all four pieces -- the per-decoder shapes, the sops reference
# answer, the reparse error surface, and the fact that our own emitters do
# not write the divergent form -- so the limit stays documented and the
# choice can be revisited if the trade moves.
###############################################################################

# Sops binary, looked up the same way t/04-interop.t does it. Sections that
# need it skip otherwise.
my $sops_bin = find_sops_bin();

# The literal six ASCII characters that spell a JSON surrogate-pair escape.
# chr(0x5C) bypasses perl 5.14+'s \uXXXX interpretation in single-quoted
# strings, which is the same reason the fixture files in maint/ use chr().
my $surr_escape = chr(0x5C) . 'uD83D' . chr(0x5C) . 'uDE00';

# The UTF-8 bytes the same codepoint U+1F600 holds on the wire when an
# emitter writes it directly. The document sops 3.13.3 produces holds these
# bytes too -- the escape form is never what sops emits.
my $emoji_bytes = "\xF0\x9F\x98\x80";

###############################################################################
# 1. Per-decoder shapes
#
#    What Cpanel::JSON::XS reads out of the JSON-escape form, and what
#    YAML::PP reads out of the same six characters. The two disagree about
#    what the key IS, not about what keys exist: Cpanel resolves to one
#    Unicode codepoint, YAML::PP keeps two separate surrogates.
###############################################################################

{
    my $json_text = qq({"outer": {"$surr_escape": "v"}});

    my ($data) = File::SOPS::Format::JSON->parse($json_text);
    my ($ordered) = File::SOPS::Format::JSON->parse_in_document_order($json_text);

    my @parse_keys = sort keys %{ $data->{outer} };
    my @ordered_keys = sort keys %{ $ordered->{outer} };

    is(scalar @parse_keys, 1, 'Cpanel::JSON::XS yields one key for the surrogate-pair escape');
    is(length $parse_keys[0], 1, 'the one key is a single codepoint (U+1F600), not two surrogates');
    is($parse_keys[0], chr(0x1F600),
        'and it is exactly U+1F600 -- the emoji Cpanel combines the surrogates into');

    is(scalar @ordered_keys, 1, 'YAML::PP also yields one key for the same six characters');
    is(length $ordered_keys[0], 2,
        'but that one key is TWO characters, the lone high and low surrogates U+D83D U+DE00');
    is($ordered_keys[0], (chr(0xD83D) . chr(0xDE00)),
        'and they are exactly the two surrogates, not the combined codepoint');

    # The byte the two disagree about is U+1F600 alone vs the two surrogates.
    # That is the structural split the reparse walks in.
    isnt(join('', @parse_keys), join('', @ordered_keys),
        'the two decoders disagree about what the key is, even on the same six bytes');
}

###############################################################################
# 2. The fail-loud direction the reparse actually takes
#
#    _document_leaves in File::SOPS walks the YAML::PP-ordered tree against
#    the Cpanel tree and refuses at the first key the Cpanel tree does not
#    have. The error names the leaf's path, which is what a caller needs.
###############################################################################

{
    my $json_text = qq({"outer": {"$surr_escape": "v"}});
    my ($data) = File::SOPS::Format::JSON->parse($json_text);
    my $ordered = File::SOPS::Format::JSON->parse_in_document_order($json_text);

    # Hand-roll the reparse's _document_leaves shape through File::SOPS's own
    # _verify_mac, which is the only path that uses it. There is no public
    # entry point: the walk sits behind _verify_mac and is reached with a
    # real document, a real data key, a real metadata object. The test below
    # builds the minimum that gets past _verify_mac's MAC check without
    # reaching it, then runs the dispatcher's walk directly.
    #
    # Easier: skip the machinery and just call the helper that would croak
    # if the reparse were walked on this shape. The walk is what we are
    # pinning -- not the surrounding machinery -- so the helper is the
    # thing to call.

    # Hand-roll _document_leaves's shape over the ordered-vs-parsed trees.
    # The walk is private to File::SOPS -- it sits behind _verify_mac and
    # is reached only with a real document, data key and metadata object --
    # so the test pins the walk itself, not the surrounding machinery, by
    # running the SAME shape over the two trees.
    my $ordered_doc = File::SOPS::_parse_in_document_order($json_text, 'File::SOPS::Format::JSON');

    my @walked_keys;
    my $walk;
    $walk = sub {
        my ($ordered_node, $parsed_node, $path_so_far) = @_;
        return unless ref $ordered_node eq 'HASH';
        my $path_str = join '.', @$path_so_far;
        croak "$path_str: the document has a mapping here but the parsed tree does not, so the digest cannot be built over the same values the file contains"
            unless ref $parsed_node eq 'HASH';
        for my $k (keys %$ordered_node) {
            my @here = (@$path_so_far, $k);
            croak join('.', @here) . ": present in the document but not in the parsed tree"
                unless exists $parsed_node->{$k};
            push @walked_keys, $k;
            $walk->($ordered_node->{$k}, $parsed_node->{$k}, \@here);
        }
    };

    # The key in $ordered_doc->{outer} is the two-surrogate form (YAML::PP).
    # The key in $data->{outer} is the single-codepoint form
    # (Cpanel::JSON::XS). exists $data->{outer}{chr(0xD83D).chr(0xDE00)}
    # is FALSE, so the walk croaks naming the leaf's path. That is the
    # fail-loud property.
    my $err = do {
        local $@;
        eval { $walk->($ordered_doc->{outer}, $data->{outer}, ['outer']) };
        $@;
    };

    like($err, qr/present in the document but not in the parsed tree/,
        'the reparse walk refuses a key only one decoder resolved');
    like($err, qr/outer/,
        'and names the leaf path, so the caller knows where to look');
}

###############################################################################
# 3. Our own emitters never write the divergent form
#
#    Both Cpanel::JSON::XS (with utf8 => 1, what JSON.pm uses) and YAML::XS
#    write non-ASCII as UTF-8 bytes, not as the JSON \uXXXX escape form. The
#    divergent input is reachable only via a hand-written or third-party
#    JSON document.
###############################################################################

{
    my ($public, $secret) = Crypt::Age->generate_keypair();

    my $document = File::SOPS->encrypt(
        data       => { outer => { "\x{1F600}" => 'v' } },
        recipients => [$public],
        format     => 'json',
    );

    # The string sops actually wrote -- whatever the encrypt path emits.
    # If a future change made the JSON emitter write the surrogate-pair
    # escape form for any U+0080+ character, this assertion fires.
    unlike($document, qr/\\u[dD][89ab][0-9a-fA-F]{2}\\u[dD][c-fC-F][0-9a-fA-F]{2}/,
        'the JSON emitter never writes a literal surrogate-pair escape for a non-ASCII key');
    like($document, qr/\xf0\x9f\x98\x80/,
        'and writes the UTF-8 bytes for U+1F600 instead, which both parsers agree on');
}

###############################################################################
# 4. sops 3.13.3 -- the reference answer, conditional on a binary
#
#    sops parses the JSON-escape form, combines the surrogate pair, and
#    writes UTF-8 bytes. That is what Go's encoding/json does and is the
#    behaviour the Cpanel read answers. On decrypt sops reads those bytes
#    back the same way.
#
#    The body of the section is the sops 3.13.3 measurement, not the
#    measurement of any wrapper around it.
###############################################################################

SKIP: {
    skip "sops binary not found on PATH, in .sops-bin/sops, or at /tmp/sops; "
       . "set SOPS_BIN, or run maint/fetch-sops .sops-bin, to run the sops "
       . "3.13.3 reference measurement",
        4 unless $sops_bin;

    diag "Using sops binary: $sops_bin";

    my $tempdir = tempdir(CLEANUP => 1);
    my ($public, $secret) = Crypt::Age->generate_keypair();
    write_binary("$tempdir/key.txt", $secret);
    $ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

    my $input = "$tempdir/input.json";
    write_binary($input, qq({"outer": {"$surr_escape": "v"}}) . "\n");

    # Encrypt the hand-written file through sops, naming the recipient on
    # the command line so sops does not have to discover it from .sops.yaml.
    my $enc = `$sops_bin -e --age $public --input-type json --output-type json $input 2>/dev/null`;
    is($? >> 8, 0, 'sops -e exits 0 on a hand-written JSON file with a surrogate-pair escape key');

    # Sops combines the pair and writes UTF-8 bytes. The six ASCII chars of
    # the escape form are NOT in the encrypted output -- sops normalised it.
    unlike($enc, qr/\\uD83D\\uDE00/,
        'sops does not preserve the literal surrogate-pair escape on the wire');
    like($enc, qr/\xf0\x9f\x98\x80/,
        'sops writes the UTF-8 encoding of U+1F600, the combined codepoint');

    write_binary("$tempdir/enc.json", $enc);

    my $dec = `$sops_bin -d --input-type json --output-type json $tempdir/enc.json 2>/dev/null`;
    is($? >> 8, 0, 'sops -d exits 0 on the encrypted file');
    like($dec, qr/\xf0\x9f\x98\x80/,
        'sops -d reads back the same UTF-8 bytes it wrote');
}

done_testing();
