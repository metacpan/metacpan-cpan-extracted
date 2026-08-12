use strict;
use warnings;
use Test::More;
use Tie::Hash;
use Tie::Array;
use Tie::Scalar;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# Tied data was mishandled by both encoders: a tied hash has HeVAL() == NULL
# (segfault), and tied array elements and scalars arrive unresolved (null).

{ package TH; our @ISA = ('Tie::StdHash');   }
{ package TA; our @ISA = ('Tie::StdArray');  }

# FETCH deliberately returns something different from what STORE was given:
# sv_setsv writes the value into the SV body before calling STORE, so a tie
# class that echoes the stored value cannot tell a real FETCH apart from that
# stale copy.
{
    package TS;
    sub TIESCALAR { my $v; bless \$v, shift }
    sub STORE     { ${$_[0]} = $_[1] }
    sub FETCH     { 'fetched:' . (defined ${$_[0]} ? ${$_[0]} : '') }
}

sub tied_hash   { tie my %h, 'TH'; %h = @_; \%h }
sub tied_array  { tie my @a, 'TA'; @a = @_; \@a }

# --- tied hash ---
{
    my $h = tied_hash(a => 1, b => 'two');
    is_deeply decode_json(encode_json($h)), { a => 1, b => 'two' },
        'encode_json: tied hash';
    is_deeply decode_json(JSON::YY->new(utf8 => 1)->encode($h)), { a => 1, b => 'two' },
        'OO encode: tied hash';
    is_deeply decode_json(JSON::YY->new(utf8 => 1, pretty => 1)->encode($h)),
        { a => 1, b => 'two' }, 'OO pretty encode: tied hash (yyjson path)';
    is_deeply decode_json("" . (jfrom $h)), { a => 1, b => 'two' },
        'jfrom: tied hash';   # stringified, so decode rather than compare text
}

# --- tied array ---
{
    my $a = tied_array(1, 'two', 3);
    is_deeply decode_json(encode_json($a)), [1, 'two', 3],
        'encode_json: tied array';
    is_deeply decode_json(JSON::YY->new(utf8 => 1, pretty => 1)->encode($a)),
        [1, 'two', 3], 'OO pretty encode: tied array';
    is "" . (jfrom $a), '[1,"two",3]', 'jfrom: tied array';
}

# --- tied scalar, including as a bare top-level argument ---
{
    tie my $s, 'TS';
    $s = 'x';
    is encode_json($s), '"fetched:x"', 'encode_json: bare tied scalar';
    is_deeply decode_json(encode_json({ k => $s })), { k => 'fetched:x' },
        'encode_json: tied scalar as hash value';
    is_deeply decode_json(encode_json([$s])), ['fetched:x'],
        'encode_json: tied scalar as array element';
    is_deeply decode_json(JSON::YY->new(utf8 => 1, pretty => 1)->encode([$s])),
        ['fetched:x'], 'OO pretty encode: tied scalar';
}

# --- nested tied containers ---
{
    my $doc = { list => tied_array(1, 2), map => tied_hash(x => 'y') };
    is_deeply decode_json(encode_json($doc)),
        { list => [1, 2], map => { x => 'y' } },
        'encode_json: tied containers nested inside a plain structure';
}

# --- get-magic must run exactly once per value ---
# The encoders SvGETMAGIC on entry, so the reads must be _nomg. Fetching twice
# also let the yyjson path emit a different string than the one it validated.
{
    package TCount;
    our $N = 0;
    sub TIESCALAR { my $v = $_[1]; bless \$v, $_[0] }
    sub FETCH { $N++; ${ $_[0] } }
    sub STORE { ${ $_[0] } = $_[1] }
}
{
    my @cases = (
        ['encode_json'  => sub { encode_json($_[0]) }],
        ['OO encode'    => sub { JSON::YY->new(utf8 => 1, allow_nonref => 1)->encode($_[0]) }],
        ['pretty encode'=> sub { JSON::YY->new(utf8 => 1, allow_nonref => 1, pretty => 1)->encode($_[0]) }],
        ['jfrom'        => sub { "" . jfrom $_[0] }],
    );
    for my $c (@cases) {
        my ($name, $enc) = @$c;
        tie my $t, 'TCount', 'val';
        local $TCount::N = 0;
        my $out = $enc->($t);
        is $TCount::N, 1, "$name: FETCH called exactly once";
        like $out, qr/val/, "$name: and the fetched value is what got encoded";
    }
}

# --- other magic: %ENV-style and regex captures still work ---
{
    "hello world" =~ /(\w+)/;
    is encode_json([$1]), '["hello"]', 'regex capture variable';
    like encode_json({ p => $ENV{PATH} }), qr/^\{"p":"/, 'magical %ENV value';
}

done_testing;
