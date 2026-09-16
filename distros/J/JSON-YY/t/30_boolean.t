use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed refaddr);
use JSON::YY qw(encode_json decode_json is_bool true false);
use JSON::PP ();

# --- Default behavior: booleans decode as 1/0 ---
{
    my $d = decode_json('[true, false]');
    ok !blessed($d->[0]), 'default decode true is unblessed';
    ok !blessed($d->[1]), 'default decode false is unblessed';
    is $d->[0], 1, 'default true is 1';
    ok !$d->[1], 'default false is false';
    cmp_ok $d->[1], '==', 0, 'default false is numerically 0';
    is encode_json($d), '[1,0]', 're-encoded default booleans are 1 and 0';

    my $coder = JSON::YY->new;
    my $d2 = $coder->decode('[true, false]');
    ok !blessed($d2->[0]), 'default OO decode true is unblessed';
    ok !blessed($d2->[1]), 'default OO decode false is unblessed';
}

# --- Opt-in OO API: bool => 1 ---
{
    my $coder = JSON::YY->new(bool => 1);
    my $d = $coder->decode('{"t":true,"f":false,"n":null}');

    is blessed($d->{t}), 'JSON::PP::Boolean', 'decoded true is JSON::PP::Boolean';
    is blessed($d->{f}), 'JSON::PP::Boolean', 'decoded false is JSON::PP::Boolean';
    is refaddr($d->{t}), refaddr($JSON::PP::true), 'decoded true is JSON::PP::true singleton';
    is refaddr($d->{f}), refaddr($JSON::PP::false), 'decoded false is JSON::PP::false singleton';

    ok $d->{t}, 'true is truthy';
    ok !$d->{f}, 'false is falsy';
    ok !defined $d->{n}, 'null is undef';

    ok is_bool($d->{t}), 'is_bool on decoded true';
    ok is_bool($d->{f}), 'is_bool on decoded false';
    ok !is_bool($d->{n}), 'is_bool on null is false';
    ok !is_bool(1), 'is_bool on 1 is false';
    ok !is_bool(0), 'is_bool on 0 is false';
    ok !is_bool("true"), 'is_bool on "true" is false';

    # Re-encode preserves booleans
    my $json = $coder->encode($d);
    like $json, qr/"t":true/, 'encode with bool=>1 emits "t":true';
    like $json, qr/"f":false/, 'encode with bool=>1 emits "f":false';
    like $json, qr/"n":null/, 'encode with bool=>1 emits "n":null';

    is encode_json([$d->{t}, $d->{f}]), '[true,false]',
        'encode_json preserves JSON::PP::Boolean';

    my $fresh = $coder->decode('{"t":true}');
    ok $fresh->{t}, 'subsequent decode still produces valid true';
}

# --- Tied values: one FETCH per encode, whatever FETCH returns ---
{
    package CountTie;
    sub TIESCALAR { my ($c, $v) = @_; bless { v => $v, n => 0 }, $c }
    sub FETCH {
        my $s = shift;
        $s->{n}++;
        ref $s->{v} eq 'CODE' ? $s->{v}->() : $s->{v};
    }
}
{
    for my $coder ([encode_json => \&encode_json],
                   [pretty => sub { JSON::YY->new(pretty => 1)->encode($_[0]) }]) {
        my %h;
        tie $h{x}, 'CountTie', $JSON::PP::true;
        like $coder->[1]->(\%h), qr/"x":\s*true/, "$coder->[0]: tied boolean encodes as true";
        is tied($h{x})->{n}, 1, "$coder->[0]: tied value fetched once";
    }

    my %h;
    tie $h{x}, 'CountTie', sub { bless \(my $v = 0), 'JSON::PP::Boolean' };
    is(JSON::YY->new(convert_blessed => 1)->encode(\%h), '{"x":false}',
        'a FETCH returning a fresh boolean each time encodes as that boolean');
}

# --- Subclasses of the boolean classes encode as booleans ---
{
    package My::Bool;
    our @ISA = ('JSON::PP::Boolean');
}
{
    is encode_json([bless(\(my $t = 1), 'My::Bool'), bless(\(my $f = 0), 'My::Bool')]),
        '[true,false]', 'a JSON::PP::Boolean subclass encodes as a boolean';
}

# --- Chaining setter: $coder->bool ---
{
    my $coder = JSON::YY->new;
    is refaddr($coder->bool), refaddr($coder), 'bool() returns $self for chaining';
    my $d = $coder->decode('[true, false]');
    is blessed($d->[0]), 'JSON::PP::Boolean', 'bool() enables boolean objects';

    $coder->bool(0);
    my $d0 = $coder->decode('[true, false]');
    ok !blessed($d0->[0]), 'bool(0) disables boolean objects';

    $coder->bool(1);
    my $d1 = $coder->decode('[true, false]');
    is blessed($d1->[0]), 'JSON::PP::Boolean', 'bool(1) re-enables boolean objects';

    # Aliases
    my $c_alias = JSON::YY->new(boolean => 1);
    is blessed($c_alias->decode('[true]')->[0]), 'JSON::PP::Boolean',
        'new(boolean => 1) works';

    my $c_alias2 = JSON::YY->new(boolean_object => 1);
    is blessed($c_alias2->decode('[true]')->[0]), 'JSON::PP::Boolean',
        'new(boolean_object => 1) works';
}

# --- Scalar roots ---
{
    my $coder = JSON::YY->new(bool => 1, allow_nonref => 1);
    my $t = $coder->decode('true');
    is blessed($t), 'JSON::PP::Boolean', 'scalar root true is JSON::PP::Boolean';
    is refaddr($t), refaddr($JSON::PP::true), 'scalar root true matches singleton';

    my $f = $coder->decode('false');
    is blessed($f), 'JSON::PP::Boolean', 'scalar root false is JSON::PP::Boolean';
    is refaddr($f), refaddr($JSON::PP::false), 'scalar root false matches singleton';
}

# --- Pretty encode with boolean objects ---
{
    my $coder = JSON::YY->new(bool => 1, pretty => 1);
    my $json = $coder->encode({ active => $JSON::PP::true, disabled => $JSON::PP::false });
    like $json, qr/"active": true/, 'pretty encode emits true';
    like $json, qr/"disabled": false/, 'pretty encode emits false';
}

# --- Exported true and false helpers ---
{
    is refaddr(true()), refaddr($JSON::PP::true), 'true() returns JSON::PP::true';
    is refaddr(false()), refaddr($JSON::PP::false), 'false() returns JSON::PP::false';
    is encode_json([true(), false()]), '[true,false]', 'true/false encode to [true,false]';
}

# --- $JSON::PP::true/false belong to the caller ---
{
    my $coder = JSON::YY->new(bool => 1);
    local $JSON::PP::true = 'yes';
    is $coder->decode('[true]')->[0], 'yes', 'true decodes to whatever $JSON::PP::true holds';
    is $JSON::PP::true, 'yes', 'and decode leaves it as the caller set it';
}
{
    require Config;
    require File::Temp;
    my ($tfh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $tfh 'use JSON::YY qw(true); use Scalar::Util qw(refaddr); my $t = true(); '
             . 'require JSON::PP; print refaddr($t) == refaddr($JSON::PP::true) ? "same" : "replaced";';
    close $tfh;
    local $ENV{PERL5LIB} = join $Config::Config{path_sep}, @INC;
    my $out = qx{"$^X" "$script"};
    is $out, 'same', 'loading JSON::PP after true() keeps the object true() returned';
}

# --- Import flag: use JSON::YY -utf8, -bool ---
{
    package TestBoolFlag;
    use Test::More;
    use Scalar::Util qw(blessed refaddr);
    use JSON::YY -utf8, -bool;

    my $d = decode_json('[true, false]');
    is blessed($d->[0]), 'JSON::PP::Boolean', '-bool flag decodes true as JSON::PP::Boolean';
    is blessed($d->[1]), 'JSON::PP::Boolean', '-bool flag decodes false as JSON::PP::Boolean';
    is refaddr($d->[0]), refaddr($JSON::PP::true), '-bool true is singleton';
    is refaddr($d->[1]), refaddr($JSON::PP::false), '-bool false is singleton';
    is encode_json($d), '[true,false]', '-bool encode_json roundtrips';
    is decode_json(qq(["\xc3\xa9"]))->[0], "\x{e9}", '-utf8, -bool still decodes UTF-8';
}

# --- Import flag aliases: -boolean and -boolean_object ---
{
    package TestBooleanFlag;
    use Test::More;
    use Scalar::Util qw(blessed);
    use JSON::YY -boolean;

    my $d = decode_json('[true]');
    is blessed($d->[0]), 'JSON::PP::Boolean', '-boolean flag works';
}

{
    package TestBoolObjFlag;
    use Test::More;
    use Scalar::Util qw(blessed);
    use JSON::YY -boolean_object;

    my $d = decode_json('[true]');
    is blessed($d->[0]), 'JSON::PP::Boolean', '-boolean_object flag works';
}

# --- Doc API interoperability with boolean objects ---
package main;
{
    use JSON::YY ':doc';
    my $doc = jfrom {};
    jset $doc, "/active", $JSON::PP::true;
    jset $doc, "/debug", $JSON::PP::false;
    ok((jis_bool $doc, "/active"), 'jis_bool on true');
    ok((jis_bool $doc, "/debug"), 'jis_bool on false');
    is "$doc", '{"active":true,"debug":false}', 'Doc with boolean objects stringifies correctly';

    my $doc2 = jfrom [$JSON::PP::true, $JSON::PP::false];
    is "$doc2", '[true,false]', 'jfrom array with boolean objects';
}

# --- Nested structures ---
{
    my $coder = JSON::YY->new(bool => 1);
    my $nested = $coder->decode('{"arr":[{"ok":true}],"map":{"v":false}}');
    is blessed($nested->{arr}[0]{ok}), 'JSON::PP::Boolean', 'deeply nested true';
    is blessed($nested->{map}{v}), 'JSON::PP::Boolean', 'deeply nested false';
    is_deeply $coder->decode($coder->encode($nested)), $nested, 'roundtrip deeply nested';
}

# --- CPAN boolean.pm interoperability if available ---
if (eval { require boolean; 1 }) {
    my $b_true  = boolean::true();
    my $b_false = boolean::false();
    ok is_bool($b_true), 'is_bool on boolean.pm true';
    ok is_bool($b_false), 'is_bool on boolean.pm false';
    is encode_json([$b_true, $b_false]), '[true,false]',
        'encode_json encodes boolean.pm objects as true/false';
    my $c = JSON::YY->new;
    is $c->encode([$b_true, $b_false]), '[true,false]',
        'coder->encode encodes boolean.pm objects as true/false';
}

# --- CPAN Types::Serialiser interoperability if available ---
if (eval { require Types::Serialiser; 1 }) {
    no warnings 'once';
    my $ts_true  = $Types::Serialiser::true;
    my $ts_false = $Types::Serialiser::false;
    ok is_bool($ts_true), 'is_bool on Types::Serialiser true';
    ok is_bool($ts_false), 'is_bool on Types::Serialiser false';
    is encode_json([$ts_true, $ts_false]), '[true,false]',
        'encode_json encodes Types::Serialiser objects as true/false';
    my $c = JSON::YY->new;
    is $c->encode([$ts_true, $ts_false]), '[true,false]',
        'coder->encode encodes Types::Serialiser objects as true/false';
    my $pretty = JSON::YY->new(pretty => 1)->encode([$ts_true, $ts_false]);
    like $pretty, qr/true.*false/s, 'pretty encode Types::Serialiser objects';
}

done_testing;
