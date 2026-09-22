#!/usr/bin/env perl
# D3: per-field options in the k8s DSL -- forms, registry, client-side
# constraints, and the load-time checks that reject options a field cannot
# carry.
use strict;
use warnings;
use Test::More;
use Test::Exception;

# --- every accepted form, one class -------------------------------------

{
    package TestOpt::Widget;
    use IO::K8s::Resource;

    k8s name     => Str, { required => 1, pattern => qr/\A[a-z][a-z0-9-]*\z/, description => 'DNS-1123 label' };
    k8s policy   => Str, { enum => [qw(Retain Delete)], default => 'Retain' };
    k8s replicas => Int, { minimum => 0, maximum => 10, default => 1 };
    k8s ratio    => Num, { minimum => 0.5 };
    k8s tags     => [Str], { enum => [qw(web db)] };
    k8s ports    => [Int], { minimum => 1, maximum => 65535 };
    k8s limits   => { Quantity => 1 }, { description => 'per-container limits' };
    k8s weights  => { Int => 1 }, { maximum => 100 };
    k8s labels   => { Str => 1 }, { preserve_unknown => 1 };
    k8s note     => Str, { nullable => 1 };
    k8s soft     => Str, { required => 'schema' };
    k8s legacy   => Str, 'required';
    k8s bang     => 'Str!';
    k8s spec     => {
        mode     => [ Str, { enum => [qw(fast safe)], required => 1 } ],
        retries  => [ Int, { minimum => 0 } ],
        hosts    => [ [Str], { pattern => '^[a-z.]+$' } ],
        plain    => Str,
    };
}

# required (via the '!' suffix) and pattern together on one field.
{
    package TestOpt::ReqPattern;
    use IO::K8s::Resource;

    k8s x => 'Str!', { pattern => '^a' };
}

# Inline struct fields using the legacy '!' suffix through the
# [ Type, {opts} ] and [ [Type], {opts} ] forms.
{
    package TestOpt::InlineReq;
    use IO::K8s::Resource;

    k8s outer => {
        m => [ 'Str!', { enum => ['a'] } ],
        n => [ ['Str!'], {} ],
    };
}

# legacy and bang are unrelated required fields (declared only to exercise
# the legacy 'required' marker and the '!' suffix in the registry subtest
# below) -- every successful construction has to satisfy them too.
sub widget { TestOpt::Widget->new(name => 'w', legacy => 'ok', bang => 'ok', spec => { mode => 'fast' }, @_) }

subtest 'registry carries required and the other options' => sub {
    my $info = TestOpt::Widget->_k8s_attr_info;
    is($info->{name}{required}, 1, 'required recorded');
    is_deeply([ sort keys %{ $info->{name}{options} } ], [qw(description pattern)], 'options without required');
    is($info->{name}{options}{description}, 'DNS-1123 label', 'description kept verbatim');
    is(ref $info->{name}{options}{pattern}, 'Regexp', 'pattern kept as given');
    is_deeply($info->{policy}{options}{enum}, [qw(Retain Delete)], 'enum kept');
    is($info->{policy}{options}{default}, 'Retain', 'default kept');
    ok(!exists $info->{policy}{required}, 'not required: key absent');
    is($info->{legacy}{required}, 1, "legacy 'required' marker still records required");
    ok(!exists $info->{legacy}{options}, 'and adds no options');
    is($info->{bang}{required}, 1, "'Str!' suffix still records required");
    is($info->{note}{options}{nullable}, 1, 'nullable is schema-only but recorded');
    is($info->{labels}{options}{preserve_unknown}, 1, 'preserve_unknown recorded');
    is($info->{soft}{required}, 1, "required => 'schema' still records required => 1 (Critical 1)");
    ok(!exists $info->{soft}{options}, 'and adds no options');

    my $spec = $IO::K8s::Resource::_attr_registry{'TestOpt::Widget::_Spec'};
    is($spec->{mode}{required}, 1, 'inline [Type, {opts}] form: required');
    is_deeply($spec->{mode}{options}{enum}, [qw(fast safe)], 'inline form: enum');
    is($spec->{retries}{options}{minimum}, 0, 'inline form: minimum');
    ok($spec->{hosts}{is_array_of_str}, 'inline [[Str], {opts}] form keeps the array flag');
    ok(!exists $spec->{plain}{options}, 'inline field without options has none');
};

subtest 'required is enforced through the options hash' => sub {
    throws_ok { TestOpt::Widget->new(legacy => 'ok', bang => 'ok', spec => { mode => 'fast' }) } qr/Missing required arguments: name/, 'required => 1';
    throws_ok { TestOpt::Widget->new(name => 'w', legacy => 'ok', bang => 'ok', spec => {}) } qr/Missing required arguments: mode/, 'inline required';
    lives_ok { widget() } 'both present';
    lives_ok { widget() } "required => 'schema' (soft) is not enforced -- constructs fine without it (Critical 1)";
};

subtest 'enum' => sub {
    lives_ok { widget(policy => 'Delete') } 'listed value accepted';
    throws_ok { widget(policy => 'Purge') } qr/Value "Purge" is not one of: Retain, Delete/, 'unlisted value rejected with the list';
    lives_ok { widget(tags => [qw(web db)]) } 'array elements accepted';
    throws_ok { widget(tags => [qw(web cache)]) } qr/is not one of: web, db/, 'array element rejected';
    throws_ok { widget(spec => { mode => 'slow' }) } qr/is not one of: fast, safe/, 'inline enum rejected';
    lives_ok { widget(policy => undef) } 'undef still means unset on an optional field';
};

subtest 'minimum and maximum' => sub {
    lives_ok { widget(replicas => 0) } 'minimum inclusive';
    lives_ok { widget(replicas => 10) } 'maximum inclusive';
    throws_ok { widget(replicas => -1) } qr/Value "-1" is below the minimum 0/, 'below minimum';
    throws_ok { widget(replicas => 11) } qr/Value "11" is above the maximum 10/, 'above maximum';
    lives_ok { widget(ratio => 0.5) } 'Num minimum inclusive';
    throws_ok { widget(ratio => 0.25) } qr/below the minimum 0\.5/, 'Num below minimum';
    lives_ok { widget(ratio => 1e9) } 'open maximum';
    throws_ok { widget(ports => [ 80, 70000 ]) } qr/Value "70000" is above the maximum 65535/, 'array element range';
    throws_ok { widget(weights => { a => 101 }) } qr/above the maximum 100/, 'typed map value range';
    throws_ok { widget(replicas => 'abc') } qr/replicas/, 'the base type still applies first';
};

subtest 'pattern' => sub {
    lives_ok { widget(name => 'web-1') } 'matching';
    throws_ok { widget(name => 'Web') } qr/Value "Web" does not match the pattern/, 'non-matching';
    lives_ok { widget(spec => { mode => 'fast', hosts => [ 'a.example' ] }) } 'string pattern compiled';
    throws_ok { widget(spec => { mode => 'fast', hosts => [ 'A' ] }) } qr/does not match the pattern/, 'string pattern enforced per element';
};

subtest 'schema-only options change nothing at runtime' => sub {
    my $w = widget();
    ok(!defined $w->policy, 'default is not applied client-side');
    ok(!exists $w->TO_JSON->{policy}, 'and nothing is emitted for it');
    my $n = widget(note => undef);
    ok(!exists $n->TO_JSON->{note}, 'nullable: undef is still omitted on the wire');
    is_deeply(widget(labels => { a => 'b' })->TO_JSON->{labels}, { a => 'b' }, 'preserve_unknown: opaque map unchanged');
};

subtest 'TO_JSON of a class with options is unchanged' => sub {
    my $w = widget(policy => 'Delete', replicas => 3, tags => ['web'], spec => { mode => 'safe', retries => 2 });
    is_deeply($w->TO_JSON, {
        name => 'w', legacy => 'ok', bang => 'ok', policy => 'Delete', replicas => 3, tags => ['web'],
        spec => { mode => 'safe', retries => 2 },
    }, 'options leave serialization alone');
};

subtest "required ('!' suffix) and pattern combine on the same field" => sub {
    throws_ok { TestOpt::ReqPattern->new } qr/Missing required arguments: x/, 'still required';
    throws_ok { TestOpt::ReqPattern->new(x => 'zz') } qr/does not match the pattern/, 'still pattern-checked';
    lives_ok { TestOpt::ReqPattern->new(x => 'ab') } 'both satisfied';
};

subtest "inline struct fields record required from the legacy '!' forms" => sub {
    my $info = $IO::K8s::Resource::_attr_registry{'TestOpt::InlineReq::_Outer'};
    is($info->{m}{required}, 1, "inline [ 'Str!', {opts} ] form: required recorded");
    is($info->{n}{required}, 1, "inline [ ['Str!'], {opts} ] form: required recorded");
    ok($info->{n}{is_array_of_str}, 'n keeps the array-of-str flag');
};

# --- load-time rejection -------------------------------------------------

sub declare_dies {
    my ($code, $re, $label) = @_;
    my $pkg = 'TestOpt::Bad' . ++$main::_n;
    throws_ok { eval "package $pkg; use IO::K8s::Resource; $code; 1" or die $@ } $re, $label;
}

subtest 'unknown or misplaced options die at class load, naming class and field' => sub {
    declare_dies(q{k8s x => Str, { colour => 'red' }},
        qr/k8s: unknown field option 'colour' for field 'x' of TestOpt::Bad\d+/, 'unknown option');
    declare_dies(q{k8s x => Str, 'optional'},
        qr/k8s: third argument for field 'x' of TestOpt::Bad\d+ must be 'required' or a hashref/, 'bad marker');
    declare_dies(q{k8s x => Bool, { enum => [1] }},
        qr/k8s: 'enum' is not allowed on a Bool field/, 'enum on Bool');
    declare_dies(q{k8s x => Str, { minimum => 1 }},
        qr/k8s: 'minimum' and 'maximum' need an Int or Num field, not Str/, 'minimum on Str');
    declare_dies(q{k8s x => Int, { pattern => qr/1/ }},
        qr/k8s: 'pattern' needs a string field, not Int/, 'pattern on Int');
    declare_dies(q{k8s x => Int, { minimum => 'low' }},
        qr/k8s: 'minimum' and 'maximum' for field 'x' of TestOpt::Bad\d+ must be numbers/, 'non-numeric bound');
    declare_dies(q{k8s x => Str, { enum => [] }},
        qr/k8s: 'enum' for field 'x' of TestOpt::Bad\d+ must be a non-empty arrayref/, 'empty enum');
    declare_dies(q{k8s x => Str, { pattern => '[' }},
        qr/k8s: 'pattern' for field 'x' of TestOpt::Bad\d+ does not compile/, 'uncompilable pattern');
    declare_dies(q{k8s x => Int, { default => 'abc' }},
        qr/k8s: 'default' for field 'x' of TestOpt::Bad\d+ fails the field's own type/, 'default outside the type');
    declare_dies(q{k8s x => Str, { enum => ['a'], default => 'b' }},
        qr/k8s: 'default' for field 'x' of TestOpt::Bad\d+ fails the field's own type: Value "b" is not one of: a/, 'default outside the enum');
    declare_dies(q{k8s x => 'Core::V1::PodSpec', { enum => ['a'] }},
        qr/k8s: 'enum' needs a scalar field/, 'enum on an object field');
    declare_dies(q{k8s x => { Str => 1 }, { pattern => 'a' }},
        qr/k8s: 'pattern' needs a scalar field/, 'pattern on an opaque map');
    declare_dies(q{k8s x => [ {} ], { minimum => 1 }},
        qr/k8s: 'minimum' and 'maximum' need a scalar field/, 'range on an array of opaque hashes');
    declare_dies(q{k8s x => Str, { pattern => undef }},
        qr/k8s: field option 'pattern' for field 'x' of TestOpt::Bad\d+ must not be undef/, 'undef pattern');
    declare_dies(q{k8s x => Int, { minimum => 10, maximum => 1 }},
        qr/k8s: 'minimum' \(10\) must not exceed 'maximum' \(1\) for field 'x' of TestOpt::Bad\d+/, 'minimum exceeds maximum');
    declare_dies(q{k8s x => Str, { enum => [qw(a a b)] }},
        qr/k8s: 'enum' for field 'x' of TestOpt::Bad\d+ has duplicate entries/, 'duplicate enum entries');
    declare_dies(q{k8s x => Str, { default => undef }},
        qr/k8s: field option 'default' for field 'x' of TestOpt::Bad\d+ must not be undef/, 'undef default');
};

subtest 'schema-only options are accepted on any field' => sub {
    lives_ok {
        eval q{
            package TestOpt::AnyField; use IO::K8s::Resource;
            k8s obj  => 'Core::V1::PodSpec', { description => 'd', preserve_unknown => 1, nullable => 1 };
            k8s list => [ {} ], { description => 'd', default => [] };
            k8s map  => { Str => 1 }, { default => {} };
            1;
        } or die $@;
    } 'description, nullable, preserve_unknown, default on non-scalar fields';
};

subtest 'a default on an object-bearing field is recorded, not type-checked (Important 3)' => sub {
    lives_ok {
        eval q{
            package TestOpt::ObjDefault; use IO::K8s::Resource;
            k8s s => { a => Str }, { default => {} };
            k8s o => 'Core::V1::PodSpec', { default => { containers => [] } };
            k8s l => ['Core::V1::Container'], { default => [] };
            1;
        } or die $@;
    } 'inline struct, referenced object and array-of-objects all accept a hash/array default that InstanceOf could never satisfy';
    my $info = TestOpt::ObjDefault->_k8s_attr_info;
    is_deeply($info->{s}{options}{default}, {}, 'inline struct default recorded as given');
    is_deeply($info->{o}{options}{default}, { containers => [] }, 'referenced-object default recorded as given');
    is_deeply($info->{l}{options}{default}, [], 'array-of-objects default recorded as given');
};

done_testing;
