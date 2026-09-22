#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Encode qw(decode_utf8);
use IO::K8s;
use IO::K8s::Api::Core::V1::ConfigMap ();

my $k8s = IO::K8s->new;

# Helper to decode UTF-8 bytes for pattern matching
sub decode_utf8_checked {
    my ($str) = @_;
    return eval { decode_utf8($str, Encode::FB_CROAK) } // $str;
}

# Test UTF-8 in ConfigMap data
subtest 'ConfigMap with UTF-8 characters' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'utf8-test', namespace => 'default' },
        data => {
            'german.txt' => 'Grüße aus München: ä ö ü ß',
            'french.txt' => 'Ça va bien!',
            'japanese.txt' => 'こんにちは',
            'emoji.txt' => '🚀⭐❤️🎉',
            'chinese.txt' => '你好世界',
            'special.txt' => '"quotes" and \'apostrophes\' and backslash \\',
        },
    });

    # Test to_json with UTF-8
    my $json = $k8s->object_to_json($cm);
    ok $json, 'to_json returns content';

    # Verify UTF-8 characters are preserved in JSON
    my $json_decoded = decode_utf8_checked($json);
    like $json_decoded, qr/Grüße/, 'German umlauts in JSON';
    like $json_decoded, qr/こんにちは/, 'Japanese in JSON';
    like $json_decoded, qr/🚀/, 'Emoji in JSON';

    # Round-trip: JSON -> Object
    my $decoded = $k8s->json_to_object($json);
    is $decoded->data->{'german.txt'}, 'Grüße aus München: ä ö ü ß', 'German survived round-trip';
    is $decoded->data->{'japanese.txt'}, 'こんにちは', 'Japanese survived round-trip';
    is $decoded->data->{'emoji.txt'}, '🚀⭐❤️🎉', 'Emoji survived round-trip';

    # Test to_yaml with UTF-8
    my $yaml = $cm->to_yaml;
    ok $yaml, 'to_yaml returns content';

    # YAML round-trip: YAML -> Object
    my $yaml_objs = $k8s->load_yaml($yaml);
    is scalar(@$yaml_objs), 1, 'YAML round-trip returned 1 object';
    my $yaml_decoded = $yaml_objs->[0];
    is $yaml_decoded->data->{'german.txt'}, 'Grüße aus München: ä ö ü ß', 'German survived YAML round-trip';
    is $yaml_decoded->data->{'japanese.txt'}, 'こんにちは', 'Japanese survived YAML round-trip';
};

# Test UTF-8 in Pod annotations and labels
subtest 'Pod with UTF-8 in metadata' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => {
            name => 'utf8-pod',
            namespace => 'default',
            annotations => {
                'description' => 'Pod with German: Grüße, French: Ça va',
            },
            labels => {
                'app' => 'test-app',
                'environment' => 'développement',
            },
        },
        spec => {
            containers => [{
                name => 'main',
                image => 'nginx',
            }],
        },
    });

    my $json = $k8s->object_to_json($pod);
    my $json_decoded = decode_utf8_checked($json);
    like $json_decoded, qr/Grüße/, 'Annotation with German in JSON';
    like $json_decoded, qr/développement/, 'Label with French in JSON';

    my $decoded = $k8s->json_to_object($json);
    is $decoded->metadata->annotations->{'description'}, 'Pod with German: Grüße, French: Ça va', 'Annotation round-trip OK';
    is $decoded->metadata->labels->{'environment'}, 'développement', 'Label round-trip OK';
};

# Test Secret with UTF-8 data
subtest 'Secret with UTF-8 data' => sub {
    my $secret = $k8s->new_object('Secret', {
        metadata => { name => 'utf8-secret', namespace => 'default' },
        type => 'Opaque',
        data => {
            'password.txt' => 'töpsecret123',
        },
    });

    my $json = $k8s->object_to_json($secret);
    ok $json, 'Secret to_json returns content';

    my $decoded = $k8s->json_to_object($json);
    is $decoded->data->{'password.txt'}, 'töpsecret123', 'Secret data round-trip OK';
};

# Test that JSON output is valid UTF-8
subtest 'JSON output is valid UTF-8' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'utf8-verify' },
        data => { 'test' => 'äöü' },
    });

    my $json = $k8s->object_to_json($cm);

    my $decoded = $k8s->json_to_object($json);
    is $decoded->data->{'test'}, 'äöü', 'UTF-8 round-trip successful';
};

# Test Container env vars with UTF-8
subtest 'Container with UTF-8 env vars' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => { name => 'env-utf8' },
        spec => {
            containers => [{
                name => 'app',
                image => 'myapp:latest',
                env => [
                    { name => 'GREETING', value => 'Hällö Wörld!' },
                    { name => 'CHINESE', value => '你好' },
                ],
            }],
        },
    });

    my $json = $k8s->object_to_json($pod);
    my $json_decoded = decode_utf8_checked($json);
    like $json_decoded, qr/Hällö/, 'UTF-8 env value in JSON';
    like $json_decoded, qr/你好/, 'Chinese env value in JSON';

    my $decoded = $k8s->json_to_object($json);
    my $env = $decoded->spec->containers->[0]->env;
    is $env->[0]->value, 'Hällö Wörld!', 'German env var round-trip';
    is $env->[1]->value, '你好', 'Chinese env var round-trip';
};

# k53: Class->from_json (the class-level entry point, not
# $k8s->json_to_object) used to decode without utf8 => 1, while to_json
# encodes WITH it -- so Class->from_json($obj->to_json) read to_json's UTF-8
# bytes as characters and silently mojibaked non-ASCII data (no error at
# all). Fixed by decoding with utf8 => 1, symmetric to _build__json_encoder. The
# decision recorded alongside the fix: from_json takes UTF-8 BYTES, exactly
# what to_json produces; an already-decoded character string is rejected
# loudly rather than accepted and silently mishandled (decode-tolerance was
# rejected on purpose, so from_json stays exactly as byte-oriented as
# $k8s->json_to_object always was).
subtest 'Class->from_json byte-level round-trip (k53)' => sub {
    # Built with \x{...} escapes rather than literal source bytes, so these
    # are unambiguous Unicode text regardless of this file having no `use
    # utf8` pragma -- exactly the kind of string a caller doing normal Perl
    # text handling (not raw byte juggling) would hand to to_json.
    my $umlauts  = "Gr\x{fc}\x{df}e aus M\x{fc}nchen: \x{e4} \x{f6} \x{fc} \x{df}"; # Grüße aus München: ä ö ü ß
    my $japanese = "\x{3053}\x{3093}\x{306b}\x{3061}\x{306f}";                     # こんにちは
    my $emoji    = "\x{1f680}\x{2b50}\x{2764}\x{fe0f}\x{1f389}";                   # 🚀⭐❤️🎉

    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'utf8-class-roundtrip' },
        data => {
            'german.txt'   => $umlauts,
            'japanese.txt' => $japanese,
            'emoji.txt'    => $emoji,
        },
    });

    my $bytes = $cm->to_json;
    ok(!utf8::is_utf8($bytes), 'to_json produces UTF-8 bytes, not a decoded character string');

    my $roundtripped = IO::K8s::Api::Core::V1::ConfigMap->from_json($bytes);
    isa_ok($roundtripped, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($roundtripped->data->{'german.txt'}, $umlauts,
        'German umlauts survive Class->from_json byte round-trip');
    is(length($roundtripped->data->{'german.txt'}), length($umlauts),
        'character length is correct, not the inflated mojibake length');
    is($roundtripped->data->{'japanese.txt'}, $japanese,
        'Japanese survives Class->from_json byte round-trip');
    is($roundtripped->data->{'emoji.txt'}, $emoji,
        'emoji survives Class->from_json byte round-trip');

    # An already-decoded character string must fail loudly, not silently
    # mojibake -- this is the decision half of k53, not just the fix.
    my $decoded_chars = $bytes;
    utf8::decode($decoded_chars)
        or die 'test fixture: to_json did not produce valid UTF-8 bytes';
    dies_ok { IO::K8s::Api::Core::V1::ConfigMap->from_json($decoded_chars) }
        'from_json dies loudly on an already-decoded character string, instead of round-tripping to mojibake';

    # Pure ASCII has no byte/character distinction to get wrong, so it keeps
    # working either way.
    my $ascii_cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'ascii-roundtrip' },
        data => { key => 'plain ascii value' },
    });
    my $ascii_roundtrip = IO::K8s::Api::Core::V1::ConfigMap->from_json($ascii_cm->to_json);
    is($ascii_roundtrip->data->{key}, 'plain ascii value',
        'pure ASCII round-trips through Class->from_json');
};

# k71 (P4): the two-arg $k8s->json_to_object($class, $json) entry point
# never had its own UTF-8 fixture -- every UTF-8 test above goes through
# either the 1-arg json_to_object($json) auto-detect path or the class-level
# Class->from_json path (k53). The two-arg path resolves $class through
# expand_class() rather than the wire 'kind', a different code path in
# IO::K8s::json_to_object, and must decode the same way.
subtest 'json_to_object($class, $json) two-arg path preserves UTF-8 (k71)' => sub {
    my $umlauts  = "Gr\x{fc}\x{df}e aus M\x{fc}nchen: \x{e4} \x{f6} \x{fc} \x{df}"; # Grüße aus München: ä ö ü ß
    my $japanese = "\x{3053}\x{3093}\x{306b}\x{3061}\x{306f}";                     # こんにちは
    my $emoji    = "\x{1f680}\x{2b50}\x{2764}\x{fe0f}\x{1f389}";                   # 🚀⭐❤️🎉

    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'utf8-two-arg' },
        data => {
            'german.txt'   => $umlauts,
            'japanese.txt' => $japanese,
            'emoji.txt'    => $emoji,
        },
    });

    my $bytes = $cm->to_json;
    ok(!utf8::is_utf8($bytes), 'to_json produces UTF-8 bytes, not a decoded character string');

    my $decoded = $k8s->json_to_object('ConfigMap', $bytes);
    isa_ok($decoded, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($decoded->data->{'german.txt'}, $umlauts,
        'German umlauts survive the two-arg json_to_object path');
    is($decoded->data->{'japanese.txt'}, $japanese,
        'Japanese survives the two-arg json_to_object path');
    is($decoded->data->{'emoji.txt'}, $emoji,
        'emoji survives the two-arg json_to_object path');
};

done_testing;
