use strict;
use warnings;
use Test::More;
use JSON::YY qw(decode_json);
use JSON::YY ':doc';

# convert_blessed called TO_JSON unconditionally, so a class without one died
# even with allow_blessed set; JSON::XS falls through instead. The Doc API had
# the reverse problem: it never called TO_JSON at all.

{ package YYT::Plain; sub new { bless { a => 1 }, shift } }
{ package YYT::Conv;  sub new { bless { a => 1 }, shift }
                      sub TO_JSON { { converted => $_[0]{a} } } }
{ package YYT::Dies;  sub new { bless {}, shift }
                      sub TO_JSON { die "boom\n" } }

my $plain = YYT::Plain->new;
my $conv  = YYT::Conv->new;

# --- convert_blessed with a TO_JSON ---
{
    my $c = JSON::YY->new(utf8 => 1, convert_blessed => 1);
    is $c->encode({ o => $conv }), '{"o":{"converted":1}}', 'TO_JSON is used';
    is_deeply decode_json(JSON::YY->new(utf8 => 1, convert_blessed => 1, pretty => 1)
                            ->encode({ o => $conv })),
        { o => { converted => 1 } }, 'TO_JSON is used on the pretty path too';
}

# --- convert_blessed without a TO_JSON falls through, it does not die ---
{
    my $both = JSON::YY->new(utf8 => 1, convert_blessed => 1, allow_blessed => 1);
    is $both->encode({ o => $plain }), '{"o":null}',
        'no TO_JSON + allow_blessed encodes null instead of dying';
    is_deeply decode_json(JSON::YY->new(utf8 => 1, convert_blessed => 1,
                                        allow_blessed => 1, pretty => 1)
                            ->encode({ o => $plain })),
        { o => undef }, 'same on the pretty path';

    my $conv_only = JSON::YY->new(utf8 => 1, convert_blessed => 1);
    eval { $conv_only->encode({ o => $plain }) };
    like $@, qr/encountered object 'YYT::Plain'/,
        'no TO_JSON and no allow_blessed still croaks';
    unlike $@, qr/locate object method/,
        'and the error is about the object, not a missing method';
}

# --- a TO_JSON that dies still propagates ---
{
    my $c = JSON::YY->new(utf8 => 1, convert_blessed => 1);
    eval { $c->encode({ o => YYT::Dies->new }) };
    like $@, qr/boom/, 'a dying TO_JSON is reported';
}

# --- plain allow_blessed is unchanged ---
{
    my $c = JSON::YY->new(utf8 => 1, allow_blessed => 1);
    is $c->encode({ o => $conv }), '{"o":null}',
        'allow_blessed alone ignores TO_JSON';
    my $strict = JSON::YY->new(utf8 => 1);
    eval { $strict->encode({ o => $plain }) };
    like $@, qr/encountered object/, 'neither flag: croaks';
}

# --- Doc API now honours TO_JSON ---
{
    is "" . (jfrom { o => $conv }), '{"o":{"converted":1}}', 'jfrom uses TO_JSON';
    is "" . (jfrom { o => $plain }), '{"o":null}', 'jfrom: no TO_JSON gives null';

    my $doc = jfrom {};
    jset $doc, "/o", $conv;
    is "$doc", '{"o":{"converted":1}}', 'jset uses TO_JSON';
    jset $doc, "/p", $plain;
    is_deeply decode_json("$doc"), { o => { converted => 1 }, p => undef },
        'jset: no TO_JSON gives null';

    is "" . (jfrom [$conv, $conv]), '[{"converted":1},{"converted":1}]',
        'jfrom: TO_JSON inside an array';
}

# --- TO_JSON returning something unencodable still croaks (and is caught) ---
{
    { package YYT::Nested; sub new { bless {}, shift }
                           sub TO_JSON { { inner => YYT::Plain->new } } }
    my $c = JSON::YY->new(utf8 => 1, convert_blessed => 1);
    eval { $c->encode(YYT::Nested->new) };
    like $@, qr/encountered object 'YYT::Plain'/,
        'unencodable TO_JSON result croaks';
}

done_testing;
