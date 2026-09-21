#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS;
use Encode qw(encode_utf8);

use File::SOPS;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;

# ----------------------------------------------------------------------------
# k35. decrypt_file and edit used to emit the plaintext document through an
# emitter of their own: a private JSON::MaybeXS->new(utf8/pretty/canonical) with
# the option values copied across by hand, and a YAML::XS::Dump that at first
# did not set the boolean mode at all and wrote `true` rather than
# `!!perl/scalar:JSON::PP::Boolean 1` only because loading
# File::SOPS::Format::YAML assigned $YAML::XS::Boolean process-wide.
#
# A twin like that is invisible for exactly as long as the two copies agree, and
# these options are not cosmetic. Sorted key emission is what makes the MAC's
# encrypt-side walk -- which hashes in sorted order -- agree with the order the
# document actually presents; the boolean mode decides whether a round trip
# through decrypt_file and back is still the same document.
#
# So this file does not assert that the two emitters agree. They did agree, all
# along, which is why nothing caught the dependency on a process-global. It
# asserts that there is only ONE emitter:
#
#   * replacing the format handler's emit() replaces what decrypt_file writes,
#     what edit hands to the editor, and what serialize() puts on the wire -- so
#     a re-introduced private copy shows up as a failure here rather than as a
#     document that fails its own MAC;
#   * the properties that must not drift are asserted on that one emit();
#   * and the bytes decrypt_file writes are compared against emit()'s output.
# ----------------------------------------------------------------------------

my ($public, $secret) = Crypt::Age->generate_keypair();
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

my %HANDLER = (
    yaml => 'File::SOPS::Format::YAML',
    json => 'File::SOPS::Format::JSON',
);

# Everything the emitter options decide, in one document: booleans (the YAML
# boolean mode), non-ASCII in a key and in a value (utf8 emission), and eight
# top-level ASCII keys whose insertion order is not their sorted order
# (canonical emission).
my %DOC = (
    zulu     => 'last',
    alpha    => 'first',
    mike     => 'middle',
    bravo    => 'second',
    flag_on  => JSON->true,
    flag_off => JSON->false,
    count    => 42,
    nested   => { b => 2, a => 1 },
    "gr\x{fc}sse" => "wei\x{df}e r\x{f6}sen \x{263a}",
);

# `on:` and `off:` are deliberately not used as key names: they are YAML 1.1
# booleans, and what an emitter does with them is a different question from the
# one this file asks.

sub scratch {
    my $sub = "$dir/case-" . ++$serial;
    mkdir $sub or die "mkdir $sub: $!";
    return $sub;
}

sub encrypted_file {
    my ($format) = @_;
    my $file = scratch() . "/secrets.$format";

    write_binary($file, File::SOPS->encrypt(
        data       => { %DOC },
        recipients => [$public],
        format     => $format,
    ));

    return $file;
}

sub decrypted_tree {
    my ($format, $file) = @_;
    return File::SOPS->decrypt(
        encrypted  => read_binary($file),
        identities => [$secret],
        format     => $format,
    );
}

# An "editor" that changes nothing and copies what it was given to
# $ENV{FILE_SOPS_EDIT_CAPTURE}, so the text edit put in front of it can be
# looked at. Leaving the file untouched makes edit stop and return 0, which
# keeps this about the emitter and not about re-encryption.
my @CAPTURING_EDITOR = (
    $^X, '-e',
    'open my $in, "<:raw", $ARGV[0] or die "$ARGV[0]: $!"; '
  . 'my $text = do { local $/; <$in> }; '
  . 'open my $out, ">:raw", $ENV{FILE_SOPS_EDIT_CAPTURE} or die $!; '
  . 'print {$out} $text or die $!; close $out or die $!;'
);

for my $format (sort keys %HANDLER) {
    my $handler = $HANDLER{$format};

    subtest "$format: every write path emits through $handler\::emit" => sub {
        my $marker = "### emitted by $handler ($format) ###\n";

        my $enc = encrypted_file($format);
        my $out = scratch() . "/plain.$format";
        my (undef, $metadata) = $handler->parse(read_binary($enc));

        my $capture = scratch() . "/editor-saw";
        local $ENV{FILE_SOPS_EDIT_CAPTURE} = $capture;
        my $to_edit = encrypted_file($format);

        # Replacing the one emitter must replace what all three produce. At the
        # time this was written, doing it the other way round -- asserting that
        # the plaintext and the handler's output happen to match -- passed
        # against the code that had two emitters.
        no strict 'refs';
        no warnings 'redefine';
        local *{"${handler}::emit"} = sub { $marker };

        File::SOPS->decrypt_file(
            input      => $enc,
            output     => $out,
            identities => [$secret],
            format     => $format,
        );
        is(read_binary($out), $marker,
           "decrypt_file writes what $handler->emit returned");

        is($handler->serialize(data => { a => 1 }, metadata => $metadata),
           $marker,
           "serialize emits through the same sub, so the plaintext and the "
         . "wire document cannot drift apart");

        my $unchanged = File::SOPS->edit(
            file       => $to_edit,
            identities => [$secret],
            format     => $format,
            editor     => [@CAPTURING_EDITOR],
        );
        is($unchanged, 0, 'the editor changed nothing, so edit stopped');
        is(read_binary($capture), $marker,
           "edit hands the editor what $handler->emit returned");
    };

    subtest "$format: the emitter options, in their one definition" => sub {
        my $emitted = $handler->emit({ %DOC });

        ok(!utf8::is_utf8($emitted),
           'emit returns UTF-8 encoded bytes, not characters');
        like($emitted, qr/\Q@{[ encode_utf8("wei\x{df}e r\x{f6}sen \x{263a}") ]}\E/,
             'a non-ASCII value is encoded once, not doubly and not escaped');

        # Sorted keys. This is what the MAC's encrypt side assumes: it walks the
        # tree in sorted order, and that is the document's own order only
        # because the emitter sorts. For JSON it is the `canonical` option; drop
        # it and the order becomes Perl's randomized hash order, which agrees
        # with sorted order for these 8 keys once in 40320 runs.
        my @keys = $format eq 'json'
                 ? $emitted =~ /^ {3}"([a-z_]+)" :/mg
                 : $emitted =~ /^([a-z_]+):/mg;
        cmp_ok(scalar @keys, '==', 8, 'all 8 ASCII top-level keys were found');
        is_deeply(\@keys, [sort @keys], 'top-level keys are emitted sorted');

        # Booleans. Without the boolean mode YAML::XS writes a JSON::PP::Boolean
        # as `!!perl/scalar:JSON::PP::Boolean 1`, which is not a boolean to any
        # other implementation and is not what came in.
        if ($format eq 'yaml') {
            like($emitted, qr/^flag_on: true$/m,   'true is emitted as true');
            like($emitted, qr/^flag_off: false$/m, 'false is emitted as false');
            unlike($emitted, qr/perl\/scalar/,
                   'no Perl-specific tag reached the document');
        }
        else {
            like($emitted, qr/"flag_on"\s*:\s*true/,   'true is emitted as true');
            like($emitted, qr/"flag_off"\s*:\s*false/, 'false is emitted as false');
        }

        # A plaintext document, so: no metadata section of any kind.
        unlike($emitted, $format eq 'yaml' ? qr/^sops:/m : qr/"sops"/,
               'emit writes no sops section');
    };

    subtest "$format: decrypt_file writes exactly what emit returns" => sub {
        my $enc = encrypted_file($format);
        my $out = scratch() . "/plain.$format";

        File::SOPS->decrypt_file(
            input      => $enc,
            output     => $out,
            identities => [$secret],
            format     => $format,
        );

        is(read_binary($out), $handler->emit(decrypted_tree($format, $enc)),
           'byte for byte');
    };
}

# The boolean mode is a process global that changes what YAML::XS does for
# everyone in the interpreter, so emit sets it with local. Moving that `local`
# into a sub of its own is exactly the kind of edit that loses it.
subtest 'emit does not leave $YAML::XS::Boolean set' => sub {
    my $before = $YAML::XS::Boolean;
    File::SOPS::Format::YAML->emit({ flag => JSON->true });
    is($YAML::XS::Boolean, $before,
       'the boolean mode is localised around the dump, not assigned');
};

done_testing();
