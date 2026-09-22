#!/usr/bin/env perl
# D10: the emitter renders a generated class set as house-style Perl source
# from the registry. The rendered source must compile into working classes
# that round-trip the same document as the generated originals.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use re ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;

my ($crd) = @{ IO::K8s::CRD->load("$FindBin::Bin/data/crd-knob.yaml") };
my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_emit');
my $root = $classes->{'opts.example.com/v1'};

my $emitter = IO::K8s::CRD::Emitter->new(
    base  => 'TestEmit::V1',
    names => { "$root\::Spec::Limit" => 'RateLimit' },
);
my $files = $emitter->render($root);

subtest 'one file per class, named from the base and the name map' => sub {
    is_deeply([ sort keys %$files ], [
        'TestEmit/V1/Knob.pm',
        'TestEmit/V1/KnobSpec.pm',
        'TestEmit/V1/KnobSpecRoutesItem.pm',
        'TestEmit/V1/KnobStatus.pm',
        'TestEmit/V1/RateLimit.pm',
    ], 'root, nested, and the renamed class');
    is($emitter->package_for("$root\::Spec::Limit"), 'TestEmit::V1::RateLimit', 'name map wins');
    is($emitter->package_for("$root\::Spec"), 'TestEmit::V1::KnobSpec', 'default: base + path joined');
};

subtest 'the root file is a house-style APIObject class' => sub {
    my $src = $files->{'TestEmit/V1/Knob.pm'};
    like($src, qr/^package TestEmit::V1::Knob;\n# ABSTRACT: /m, 'package + ABSTRACT');
    like($src, qr/^our \$VERSION = '1\.108';$/m, 'version line');
    like($src, qr/^use IO::K8s::APIObject\n    api_version     => 'opts\.example\.com\/v1',\n    resource_plural => 'knobs';$/m, 'APIObject import');
    like($src, qr/^with 'IO::K8s::Role::Namespaced';$/m, 'Namespaced');
    like($src, qr/^k8s spec\s+=> '\+TestEmit::V1::KnobSpec', \{ required => 'schema' \};$/m, 'required object field, renamed, recorded not enforced');
    like($src, qr/^k8s status\s+=> '\+TestEmit::V1::KnobStatus';$/m, 'status');
    like($src, qr/^=attr spec\n/m, 'attr POD for spec');
    like($src, qr/\n1;\n\z/, 'ends with 1;');
    unlike($src, qr/_AUTOGEN/, 'no generated namespace leaks into the source');
};

subtest 'field lines render every type form and the options' => sub {
    my $src = $files->{'TestEmit/V1/KnobSpec.pm'};
    like($src, qr/^use IO::K8s::Resource;$/m, 'nested class is a Resource');
    like($src, qr/^k8s mode\s+=> Str, \{ required => 'schema', enum => \[qw\(fast safe\)\], default => 'safe' \};$/m, 'enum + default + schema-required');
    like($src, qr/^k8s replicas\s+=> Int, \{ minimum => 0, maximum => 5 \};$/m, 'range');
    like($src, qr/^k8s limit\s+=> '\+TestEmit::V1::RateLimit';$/m, 'nested object via the name map');
    like($src, qr/^k8s routes\s+=> \['\+TestEmit::V1::KnobSpecRoutesItem'\];$/m, 'array of objects');
    like($src, qr/^k8s size\s+=> IntOrStr;$/m, 'int-or-string');
    like($src, qr/^k8s extra\s+=> \{ Str => 1 \}, \{ preserve_unknown => 1 \};$/m, 'opaque map with a schema-only option');
    like($src, qr/^=attr mode\n\nOperating mode\.\n/m, 'description becomes the =attr text');
    like($src, qr/^=attr replicas\n\nNo description in the upstream schema\.\n/m, 'fallback text');
    unlike($src, qr/description =>/, 'description is not repeated as an option');
    my $limit = $files->{'TestEmit/V1/RateLimit.pm'};
    like($limit, qr/^package TestEmit::V1::RateLimit;\n# ABSTRACT: Rate limit applied to the knob\.$/m, 'ABSTRACT from the object description');
    like($limit, qr/^k8s period\s+=> Str, \{ pattern => qr\/\^\[0-9\]\+\[smh\]\$\/ \};$/m, 'pattern as qr//');
    my $item = $files->{'TestEmit/V1/KnobSpecRoutesItem.pm'};
    like($item, qr/^k8s match\s+=> Str, \{ required => 'schema' \};$/m, 'required alone still renders the schema form');
};

subtest 'the rendered source compiles and round-trips the same document' => sub {
    for my $path (sort keys %$files) {
        my $src = $files->{$path};
        ok(eval "$src\n1;", "compiles: $path") or diag $@;
    }
    my $k8s = IO::K8s->new;
    $k8s->add({ Knob => '+TestEmit::V1::Knob' });
    my $doc = {
        apiVersion => 'opts.example.com/v1', kind => 'Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec => { mode => 'fast', replicas => 2, limit => { average => 1, period => '5s' },
                  routes => [ { match => 'a', weight => 1 } ], size => 3, extra => { x => 1 } },
        status => { ready => JSON::PP::true() },
    };
    require JSON::PP;
    my $hand = $k8s->inflate($doc);
    isa_ok($hand->spec->limit, 'TestEmit::V1::RateLimit');
    my $gen = do { my $g = IO::K8s->new; $g->add({ Knob => "+$root" }); $g->inflate($doc) };
    is_deeply($hand->TO_JSON, $gen->TO_JSON, 'emitted classes and generated classes agree on the wire');
    throws_ok { $k8s->inflate({ %$doc, spec => { mode => 'slow' } }) } qr/not one of: fast, safe/, 'constraints survive the round-trip into source';
};

subtest 'patterns needing escaping, an empty-string enum, and unfriendly descriptions render safely' => sub {
    my $schema = {
        type => 'object',
        # No trailing '.': the multi-line-with-no-sentence-end case that used
        # to leave a raw newline in the # ABSTRACT comment (uncompilable).
        description => "A resource for exercising the emitter's escaping\nlogic across several lines",
        'x-kubernetes-group-version-kind' => [ { group => 'esc.example.com', version => 'v1', kind => 'Escaper' } ],
        properties => {
            spec => {
                type => 'object',
                properties => {
                    email => {
                        type        => 'string',
                        pattern     => '^[a-z]+@example\.com$',
                        description => "Contact address.\n=head1 not a real POD command\n\n\n\nTrailing paragraph.",
                    },
                    path    => { type => 'string', pattern => '^\/api\/v1$' },
                    slash   => { type => 'string', pattern => '^https?://x$' },
                    single  => { type => 'string', pattern => '^a$' },
                    alt     => { type => 'string', pattern => '^(a|b)$' },
                    atparen => { type => 'string', pattern => '(a@$)' },
                    atalt   => { type => 'string', pattern => '(a@$|b)' },
                    mode    => { type => 'string', enum => [ '', 'Always', 'IfNotPresent' ] },
                },
            },
        },
    };
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.esc.v1.Escaper', $schema, {}, 'IO::K8s::_AUTOGEN_esc',
        api_version => 'esc.example.com/v1', kind => 'Escaper', resource_plural => 'escapers', is_namespaced => 1);
    my $esc_files = IO::K8s::CRD::Emitter->new(base => 'TestEscape::V1')->render($gen);
    for my $path (sort keys %$esc_files) {
        ok(eval "$esc_files->{$path}\n1;", "compiles: $path") or diag "$path:\n" . $esc_files->{$path} . "\n$@";
    }

    like($esc_files->{'TestEscape/V1/Escaper.pm'},
        qr/^# ABSTRACT: A resource for exercising the emitter's escaping logic across several lines$/m,
        'a multi-line, period-less description collapses to one ABSTRACT line instead of interpolating raw');

    # k114: a pattern whose qr// rendering would not reproduce the pattern
    # text byte for byte goes to the plain-string path instead, so what
    # reaches a CRD is upstream's own text and not this emitter's Perl
    # escaping. The escaping itself is still what decides that (an
    # unescaped '@' would interpolate away and the round-trip check would
    # then see a different pattern) -- it just no longer ships.
    my $spec_src = $esc_files->{'TestEscape/V1/EscaperSpec.pm'};
    like($spec_src, qr/^k8s email\s+=> Str, \{ pattern => '\^\[a-z\]\+\@example\\\\\.com\$' \};$/m,
        'an @ that a qr// would have to escape renders as a plain string, @ intact');
    like($spec_src, qr/^k8s path\s+=> Str, \{ pattern => '\^\\\\\/api\\\\\/v1\$' \};$/m,
        "an escaped slash upstream wrote itself is kept -- a qr// would lose it to the delimiter");
    like($spec_src, qr/^k8s slash\s+=> Str, \{ pattern => qr\/\^https\?:\\\/\\\/x\$\/ \};$/m,
        'a BARE slash still renders as qr/.../: escaping it for the delimiter is undone on compile, so nothing is lost');
    like($spec_src, qr/^k8s single\s+=> Str, \{ pattern => qr\/\^a\$\/ \};$/m,
        'a $ anchoring end-of-string is left alone');
    like($spec_src, qr/^k8s alt\s+=> Str, \{ pattern => qr\/\^\(a\|b\)\$\/ \};$/m,
        'a $ before the closing delimiter is left alone');
    like($spec_src, qr/^k8s atparen\s+=> Str, \{ pattern => '\(a\@\$\)' \};$/m,
        'an @ immediately before a ) -anchored $ takes the string path too, not just ones before \w or {');
    like($spec_src, qr/^k8s atalt\s+=> Str, \{ pattern => '\(a\@\$\|b\)' \};$/m,
        'an @ immediately before a |-anchored $ likewise');
    like($spec_src, qr/^k8s mode\s+=> Str, \{ enum => \['',\s*'Always',\s*'IfNotPresent'\] \};$/m,
        'an enum containing the empty string renders as a Dumper list');
    unlike($spec_src, qr/qw\(/, 'no qw() form once one entry needs quoting');
    like($spec_src,
        qr/^=attr email\n\nContact address\.\nE<61>head1 not a real POD command\n\nTrailing paragraph\.\n/m,
        'a description line starting with = is escaped and a blank-line run collapses to one');

    my $hand = IO::K8s->new; $hand->add({ Escaper => '+TestEscape::V1::Escaper' });
    my $orig = IO::K8s->new; $orig->add({ Escaper => "+$gen" });
    my %cases = (
        email  => { ok => 'a@example.com', bad => 'not-an-email' },
        path   => { ok => '/api/v1',       bad => '/api/v2' },
        slash  => { ok => 'https://x',     bad => 'https://y' },
        single => { ok => 'a',             bad => 'b' },
        alt    => { ok => 'a',             bad => 'c' },
        mode   => { ok => '',              bad => 'Sometimes' },
    );
    for my $field (sort keys %cases) {
        for my $which (qw( ok bad )) {
            my $value = $cases{$field}{$which};
            my $doc = {
                apiVersion => 'esc.example.com/v1', kind => 'Escaper',
                metadata => { name => 'e' }, spec => { $field => $value },
            };
            my $hand_lived = eval { $hand->inflate($doc); 1 };
            my $orig_lived = eval { $orig->inflate($doc); 1 };
            is(!!$hand_lived, !!$orig_lived, "$field/$which ('$value'): emitted and generated classes agree");
        }
    }

    # '(a@$)' and '(a@$|b)': the '@' sits directly before a '$' that is
    # itself in an anchor position (before ')' or '|'), which a narrower
    # "escape @ only before \w or {" rule left bare -- '@$)'/'@$|' then
    # interpolated away to nothing, so the emitted class silently accepted
    # values ('a', 'zzza') the generated class rejects. Same four values
    # against both fields: only 'a@' should be accepted by '(a@$)', 'a@'
    # and 'b' by '(a@$|b)' -- but the assertion is agreement, not a fixed
    # accept/reject table, so a regression shows up either way.
    for my $field (qw( atparen atalt )) {
        for my $value ('a@', 'a', 'zzza', 'b') {
            my $doc = {
                apiVersion => 'esc.example.com/v1', kind => 'Escaper',
                metadata => { name => 'e' }, spec => { $field => $value },
            };
            my $hand_lived = eval { $hand->inflate($doc); 1 };
            my $orig_lived = eval { $orig->inflate($doc); 1 };
            is(!!$hand_lived, !!$orig_lived, "$field ('$value'): emitted and generated classes agree");
        }
    }
};

# k94 review (Important 2): a codepoint above ASCII interpolated raw into
# 'qr/.../ ' or a quoted literal only round-trips through the emitted .pm
# file under conditions this emitter does not control (the file saved as
# UTF-8 bytes AND compiled under 'use utf8') -- \x{HEX} escapes make a
# pattern/enum/default correct independent of that. A schema's free-form
# 'description' is the one place non-ASCII text still lands in the file
# unescaped (verbatim, in POD, by design), and it is the only thing that
# should trigger 'use utf8' + '=encoding UTF-8' in the rendered source.
# t/data/crd-utf8.yaml is loaded from a real file (through
# IO::K8s::CRD->load's ':encoding(UTF-8)' read), not built as a Perl
# literal in this test, so its strings carry the UTF8 flag the same way a
# real CRD manifest's do -- the bug this guards against (Perl's \w matching
# a Unicode letter like 'µ' only when that flag is set) would not
# reproduce against an unflagged literal.
subtest 'non-ASCII patterns, enum values and descriptions render UTF-8-safely' => sub {
    my ($u_crd) = @{ IO::K8s::CRD->load("$FindBin::Bin/data/crd-utf8.yaml") };
    my $u_classes = IO::K8s::CRD->generate($u_crd, 'IO::K8s::_AUTOGEN_utf8emit');
    my $u_root = $u_classes->{'utf8.example.com/v1'};
    my $u_emitter = IO::K8s::CRD::Emitter->new(base => 'TestUtf8::V1');
    my $u_files = $u_emitter->render($u_root);

    is_deeply([ sort keys %$u_files ], [
        'TestUtf8/V1/Utf8Thing.pm',
        'TestUtf8/V1/Utf8ThingSpec.pm',
        'TestUtf8/V1/Utf8ThingSpecExtra.pm',
    ], 'one file per class');

    for my $path (sort keys %$u_files) {
        ok(eval "$u_files->{$path}\n1;", "compiles: $path") or diag "$path:\n" . $u_files->{$path} . "\n$@";
    }

    my $spec_src = $u_files->{'TestUtf8/V1/Utf8ThingSpec.pm'};
    # k114: a non-ASCII pattern takes the plain-string path, so the value
    # that reaches a CRD is the µ upstream wrote rather than the seven
    # characters '\x{b5}'. The SOURCE still carries only ASCII -- a
    # double-quoted \x{HEX} escape, the same spelling the enum member below
    # gets -- so the file needs no `use utf8` either way.
    like($spec_src, qr/^k8s interval\s+=> Str, \{ pattern => "\^\[0-9\]\+\\x\{b5\}s\\\$" \};$/m,
        'the µ in the pattern renders as an ASCII-safe \x{HEX} escape in a string literal, not a raw byte');
    like($spec_src, qr/^k8s mode\s+=> Str, \{ enum => \['safe',"\\x\{b5\}s"\] \};$/m,
        'the µ-only enum member switches to a double-quoted \x{HEX} literal; its ASCII sibling keeps single quotes');
    unlike($spec_src, qr/^use utf8;$/m, 'no description anywhere in this class -- the pattern/enum are already ASCII-safe -- so no use utf8');
    unlike($spec_src, qr/^=encoding/m, '...and no =encoding either');

    my $extra_src = $u_files->{'TestUtf8/V1/Utf8ThingSpecExtra.pm'};
    like($extra_src, qr/^use utf8;$/m, "the ü in this class's field description triggers use utf8");
    like($extra_src, qr/^our \$VERSION = '1\.108';\nuse utf8;$/m, 'use utf8 lands right after the VERSION line');
    like($extra_src, qr/^=encoding UTF-8$/m, '...and =encoding UTF-8');
    like($extra_src, qr/^=attr note\n\nNote with a \x{fc} character in its description\.\n/m,
        'the description keeps its real ü character, verbatim, not escaped');

    my $hand = IO::K8s->new; $hand->add({ Utf8Thing => '+TestUtf8::V1::Utf8Thing' });
    my $gen  = IO::K8s->new; $gen->add({ Utf8Thing => "+$u_root" });
    for my $value ("100\x{b5}s", '100ms', 'bogus') {
        my $doc = { apiVersion => 'utf8.example.com/v1', kind => 'Utf8Thing', metadata => { name => 'u' }, spec => { interval => $value } };
        my $hand_lived = eval { $hand->inflate($doc); 1 };
        my $gen_lived  = eval { $gen->inflate($doc); 1 };
        is(!!$hand_lived, !!$gen_lived, "interval matching '$value': emitted and generated classes agree");
    }
    for my $value ('safe', "\x{b5}s", 'bogus') {
        my $doc = { apiVersion => 'utf8.example.com/v1', kind => 'Utf8Thing', metadata => { name => 'u' }, spec => { mode => $value } };
        my $hand_lived = eval { $hand->inflate($doc); 1 };
        my $gen_lived  = eval { $gen->inflate($doc); 1 };
        is(!!$hand_lived, !!$gen_lived, "mode '$value': emitted and generated classes agree");
    }
};

# k94/long names: cert-manager's CRDs inline a full PodTemplateSpec several
# levels into a Challenge/ClusterIssuer 'spec', and the path-derived name
# for the deepest levels ran past Perl's 251-character identifier limit
# inside AutoGen's own (namespace-prefixed) class names. This emitter's own
# `base` is normally much shorter than that namespace prefix, so its joined
# package name usually still fits within 200 characters even when AutoGen's
# own name did not (see t/72's subtest for that case) -- this schema is
# deep enough that even the emitter's own joined name runs past 200,
# exercising its <Kind>_<hash> fallback too.
subtest 'a path-derived name past 200 chars still renders, with its own fallback and a names override' => sub {
    IO::K8s::AutoGen::clear_cache();

    my @keys = map {
        my $base = "level$_";
        $base . ('x' x (30 - length($base)));
    } 1 .. 8;

    my $leaf = { type => 'object', properties => { value => { type => 'string' } } };
    my $eight_deep = $leaf;
    $eight_deep = { type => 'object', properties => { $_ => $eight_deep } } for reverse @keys;

    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'deep.example.com', version => 'v1', kind => 'Deep' } ],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { type => 'object' },
            spec => { type => 'object', properties => { branch => $eight_deep } },
        },
    };

    my $deep_root = IO::K8s::AutoGen::get_or_generate('com.example.deep.v1.Deep', $schema, {}, 'IO::K8s::_AUTOGEN_karr_deepemit',
        api_version => 'deep.example.com/v1', kind => 'Deep', resource_plural => 'deeps', is_namespaced => 1);

    my $deepest = $deep_root->_k8s_attr_info->{spec}{class}->_k8s_attr_info->{branch}{class};
    $deepest = $deepest->_k8s_attr_info->{$_}{class} for @keys;
    like($deepest, qr/::_[0-9a-f]{10}$/, 'AutoGen itself had to shorten the deepest class');

    my $emitter = IO::K8s::CRD::Emitter->new(base => 'TestDeepEmit::V1');
    my $deep_files = $emitter->render($deep_root);
    for my $path (sort keys %$deep_files) {
        ok(eval "$deep_files->{$path}\n1;", "compiles: $path") or diag "$path:\n" . $deep_files->{$path} . "\n$@";
    }

    my $deepest_package = $emitter->package_for($deepest);
    like($deepest_package, qr/^TestDeepEmit::V1::Deep_[0-9a-f]{10}$/,
        "the emitter's own joined name also runs past 200 chars, so it falls back to <Kind>_<hash> too");

    my $doc = { value => 'leaf-value' };
    $doc = { $_ => $doc } for reverse @keys;
    my $full_doc = {
        apiVersion => 'deep.example.com/v1', kind => 'Deep',
        metadata   => { name => 'd' },
        spec       => { branch => $doc },
    };
    my $hand = IO::K8s->new; $hand->add({ Deep => '+TestDeepEmit::V1::Deep' });
    my $gen  = IO::K8s->new; $gen->add({ Deep => "+$deep_root" });
    is_deeply($hand->inflate($full_doc)->TO_JSON, $gen->inflate($full_doc)->TO_JSON,
        'the emitted (hash-fallback-named) class round-trips the same document as the generated one');

    # A names entry for the deepest class is honoured -- under a different
    # base, so its package names do not collide with the ones just eval'd.
    my $emitter2 = IO::K8s::CRD::Emitter->new(base => 'TestDeepNamed::V1', names => { $deepest => 'DeepLeaf' });
    my $named_files = $emitter2->render($deep_root);
    ok(exists $named_files->{'TestDeepNamed/V1/DeepLeaf.pm'}, 'a names entry for the deepest class is honoured');
    is($emitter2->package_for($deepest), 'TestDeepNamed::V1::DeepLeaf', 'package_for reflects the name map, not the fallback');
};

# k112: the registry already carries is_array_of_num/quantity/time/
# int_or_string (added for k96 task-2, read by IO::K8s::CRD's to_crd
# _type_schema), but this emitter's own _type_source -- the reverse,
# registry -> DSL-source direction -- still had no branch for any of the
# four and croaked. Unreachable today via any bundled provider or AutoGen
# schema path (AutoGen's array-item dispatch never produces one of these
# four flags from a schema; see the comment above IO::K8s::CRD::_type_schema),
# so reproduce with a hand-declared class exercising the DSL forms
# directly, the same way t/63_k66_array_of_hash.t does for [ {} ] / [ [] ].
{
    package Test::Karr112::Thing;
    use IO::K8s::Resource;
    k8s numbers    => [Num];
    k8s quantities => [Quantity];
    k8s times      => [Time];
    k8s flexes     => [IntOrStr];
}

subtest 'array-of-scalar Num/Quantity/Time/IntOrStr fields emit instead of croaking (k112)' => sub {
    my $emitter = IO::K8s::CRD::Emitter->new(base => 'TestKarr112::V1');
    my $files;
    lives_ok { $files = $emitter->render('Test::Karr112::Thing') }
        '_type_source no longer croaks on [Num]/[Quantity]/[Time]/[IntOrStr]';

    my $src = $files->{'TestKarr112/V1/Thing.pm'};
    like($src, qr/^k8s numbers\s+=> \[Num\];$/m,      'array of Num');
    like($src, qr/^k8s quantities\s+=> \[Quantity\];$/m, 'array of Quantity');
    like($src, qr/^k8s times\s+=> \[Time\];$/m,        'array of Time');
    like($src, qr/^k8s flexes\s+=> \[IntOrStr\];$/m,   'array of IntOrStr');

    ok(eval "$src\n1;", 'emitted source compiles') or diag $@;

    my $doc = {
        numbers    => [1, 2.5],
        quantities => ['100Mi', '2'],
        times      => ['2024-01-01T00:00:00Z'],
        flexes     => [1, '20%'],
    };
    my $hand    = Test::Karr112::Thing->new(%$doc);
    my $emitted = TestKarr112::V1::Thing->new(%$doc);
    is_deeply($emitted->TO_JSON, $hand->TO_JSON,
        'emitted class round-trips the same wire shape as the hand-written original');
};

subtest 'k110: a flagged pattern renders as a string with the flags inlined, not qr/../i' => sub {
    # Upstream's own spelling. AutoGen compiles it with qr/$p/, and Perl
    # hoists the leading (?i) into the compiled regex's FLAGS while leaving
    # it in the text -- which is how the emitter used to write back a
    # qr/..../i that IO::K8s::CRD then refused to turn into a CRD again.
    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'flag.example.com', version => 'v1', kind => 'Flagged' } ],
        properties => {
            spec => {
                type       => 'object',
                properties => {
                    strategy => { type => 'string', pattern => '^(?i)(abort|warn)?$' },
                    plain    => { type => 'string', pattern => '^[a-z]+$' },
                },
            },
        },
    };
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.flag.v1.Flagged', $schema, {}, 'IO::K8s::_AUTOGEN_flag',
        api_version => 'flag.example.com/v1', kind => 'Flagged', resource_plural => 'flaggeds', is_namespaced => 1);
    my $flag_files = IO::K8s::CRD::Emitter->new(base => 'TestFlag::V1')->render($gen);

    my $spec_src = $flag_files->{'TestFlag/V1/FlaggedSpec.pm'};
    like($spec_src, qr/^k8s strategy\s+=> Str, \{ pattern => '\^\(\?i\)\(abort\|warn\)\?\$' \};$/m,
        'the flagged pattern renders as the plain string upstream wrote, flags inlined');
    unlike($spec_src, qr{qr/\^\(\?i\)},
        'and specifically NOT as qr/..../i, which IO::K8s::CRD cannot emit back');
    like($spec_src, qr{^k8s plain\s+=> Str, \{ pattern => qr/\^\[a-z\]\+\$/ \};$}m,
        'an unflagged pattern still renders as qr/.../ -- the default is unchanged');

    ok(eval "$spec_src\n1;", 'emitted source compiles') or diag $@;

    # Success condition: the rendered class survives the trip back into a
    # CRD, with the upstream text intact. Before k110 this croaked.
    my $props = IO::K8s::CRD::_schema_for_class('TestFlag::V1::FlaggedSpec')->{properties};
    is($props->{strategy}{pattern}, '^(?i)(abort|warn)?$',
        'to_crd re-emits the upstream pattern text verbatim');
    is($props->{plain}{pattern}, '^[a-z]+$', 'and the unflagged one alongside it');

    # Perl-side validation must not have shifted: a string pattern is
    # compiled by Resource.pm with qr/$p/, which carries no flags, so the
    # case-insensitivity has to live in the text.
    lives_ok { TestFlag::V1::FlaggedSpec->new(strategy => 'ABORT') }
        'the inlined (?i) still accepts an upper-case value';
    lives_ok { TestFlag::V1::FlaggedSpec->new(strategy => 'warn') } '...and a lower-case one';
    throws_ok { TestFlag::V1::FlaggedSpec->new(strategy => 'nope') }
        qr/does not match the pattern/, '...and still rejects a non-member';
};

subtest 'k110: the flag fold is verified, never assumed' => sub {
    # No inline modifier in the text: the flags have to be prefixed.
    is(IO::K8s::CRD::Emitter::_pattern_literal(qr/^abort$/i), q{'(?i)^abort$'},
        'a bare /i becomes a leading (?i) in the text');
    is(IO::K8s::CRD::Emitter::_pattern_literal(qr/^a$|^b$/i), q{'(?i)^a$|^b$'},
        '...and covers every alternative, as the modifier did');

    # Already inline: Perl hoisted it into the flags but left it in the
    # text, so prefixing again would emit a redundant (?i)(?i).
    is(IO::K8s::CRD::Emitter::_pattern_literal(qr/^(?i)(abort|warn)?$/i), q{'^(?i)(abort|warn)?$'},
        'a pattern that already carries the modifier is not given a second one');

    # 'u' is an artifact of the UTF8-flagged string a CRD pattern arrives
    # as, not something the schema asked for, so it must not push a pattern
    # onto the string path.
    # The pattern text is ASCII on purpose: a non-ASCII one takes the
    # string path on its own (k114), which would prove nothing about 'u'.
    my $utf8_born = do { my $p = '^[0-9]+s$'; utf8::upgrade($p); qr/$p/ };
    is((re::regexp_pattern($utf8_born))[1], 'u', 'fixture really does carry the implicit u flag');
    like(IO::K8s::CRD::Emitter::_pattern_literal($utf8_born), qr{\Aqr/},
        'an implicit u flag alone still renders as qr/.../');

    # Every modifier re::regexp_pattern actually reports (i m s x n a d l)
    # does have an inline spelling, so this drives the guard with a flag
    # letter that has none. The claim is the guard's, not the letter's: an
    # unfoldable flag must croak rather than silently disappear from a
    # pattern the caller believes still carries it.
    throws_ok { IO::K8s::CRD::Emitter::_fold_pattern_flags('^a$', 'Q') }
        qr/cannot be folded into the pattern text/,
        'a flag with no inline spelling croaks instead of being dropped';
};

# --- k114: the qr// form only where it carries the pattern's own bytes ----
#
# Rendering a pattern as `qr/.../ ` source means escaping whatever Perl
# would otherwise interpolate, and Perl KEEPS those backslashes in the
# compiled pattern -- so a '\@' or a '\x{b5}' this emitter wrote travels
# through the registry and out of IO::K8s::CRD into a real CRD, in a field
# whose whole point is to carry the text upstream wrote. (The one escape
# that does not survive is the delimiter's own '\/': the tokenizer strips
# it again, which is why a bare '/' can stay in a qr// and an escaped one
# upstream wrote cannot.) So the qr// form ships only where it is
# byte-exact, and everything else takes the plain-string path
# IO::K8s::CRD passes through untouched.
subtest 'k114: an emitted pattern carries upstream bytes, not the emitter\'s escaping' => sub {
    # what upstream wrote                                        => the form it must render as
    my @cases = (
        [ 'a bare @ (ExternalSecrets gcpServiceAccountEmail)', '^.*@.*\.iam\.gserviceaccount\.com$',       'str' ],
        [ 'a bare @ before a )-anchored $',                    '(a@$)',                                    'str' ],
        [ 'a $ inside a character class (GatewayAPI headers)', '^[A-Za-z0-9!#$%&\'*+\-.^_\x60|~]+$',       'str' ],
        [ 'a non-ASCII codepoint (Traefik durations)',         "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$",    'str' ],
        [ 'a \\/ upstream escaped itself (GatewayAPI paths)',  '^a\/b$',                                   'str' ],
        [ 'a BARE / (PrometheusOperator url)',                 '^https?://.+$',                            'qr'  ],
        [ 'a $ that really is the end anchor',                 '^(a|b)$',                                  'qr'  ],
        [ 'nothing that needs escaping at all',                '^[0-9]+[smh]$',                            'qr'  ],
    );
    for my $case (@cases) {
        my ($what, $text, $form) = @$case;
        my $literal = IO::K8s::CRD::Emitter::_pattern_literal(qr/$text/);
        like($literal, ($form eq 'qr' ? qr{\Aqr/} : qr{\A["']}), "$what: renders as a $form");

        my $back = eval $literal;
        ok(defined $back, "$what: the emitted literal compiles") or next;
        my $emitted = ref $back eq 'Regexp'
            ? IO::K8s::CRD::_pattern_to_ecma262($back, 'k114.case')
            : $back;
        is($emitted, $text, "$what: openAPIV3Schema.pattern gets exactly the text that came in");

        # And the Perl side must not have moved either: whatever the form,
        # Resource.pm compiles it (a string via qr/$p/) into a matcher that
        # accepts and rejects exactly what the original did.
        my $re = ref $back eq 'Regexp' ? $back : qr/$back/;
        my @probes = ('', 'a', 'a@', 'a/b', 'a@b', 'x@y.iam.gserviceaccount.com',
                      "100\x{b5}s", '100us', '5m', 'https://x/y', '`', 'A#B', 'b');
        is_deeply([ map { ($_ =~ $re) ? 1 : 0 } @probes ],
                  [ map { ($_ =~ qr/$text/) ? 1 : 0 } @probes ],
                  "$what: validation semantics unchanged");
    }
};

done_testing;
