use strict;
use warnings;
use Test::More;
use JSON::PP;
use JSON::Typist;

use Test::Deep;
use Test::Deep::JType;

subtest "basic functionality" => sub {
  my $content = q<{"number":5,"string":"5"}>;

  my $json   = JSON::PP->new->convert_blessed->canonical;
  my $typist = JSON::Typist->new;

  my $payload  = $json->decode( $content );
  my $typed    = $typist->apply_types( $payload );

  isa_ok( $typed->{string}, 'JSON::Typist::String', '$typed->{string}');
  isa_ok( $typed->{number}, 'JSON::Typist::Number', '$typed->{number}');

  my $sink;
  $sink = 0 + $payload->{string};
  $sink = "$payload->{number}";

  $sink = 0 + $typed->{string};
  $sink = "$typed->{number}";

  my $via_payload   = $json->encode($payload);
  my $via_typed     = $json->encode($typed);

  my $stripped      = $typist->strip_types($typed);
  my $via_stripped  = $json->encode($stripped);

  isnt($via_payload, $content, "once inspected, original won't round trip");

  is($via_typed,    $content, "typed structure, inspected, does round trip");
  is($via_stripped, $content, "typed structure, stripped, also round trips");
};

subtest "bignums in effect" => sub {
  my $content = q<{"number":2.000000000000000000000000001}>;
  my $json    = JSON::PP->new->convert_blessed->allow_bignum;
  my $payload = $json->decode( $content );
  my $typist  = JSON::Typist->new;
  my $typed   = $typist->apply_types($payload);

  isa_ok($payload->{number}, 'Math::BigFloat',        '$payload->{number}');
  isa_ok($typed->{number},   'JSON::Typist::Number',  '$typed->{number}');

  my $sink = "$typed->{number}";

  my $via_typed     = $json->encode($typed);

  my $stripped      = $typist->strip_types($typed);
  my $via_stripped  = $json->encode($stripped);

  is($via_typed,    $content, "typed structured, inspected, does round trip");
  is($via_stripped, $content, "typed structured, stripped, also round trips");
};

subtest "basic Test::Deep::JType" => sub {
  my $content = q<{
    "num":5,
    "str":"5",
    "t":true,
    "f":false,
    "b":true
  }>;

  my $typist  = JSON::Typist->new;
  my $json    = JSON::PP->new->convert_blessed->canonical;
  my $payload = $json->decode( $content );
  my $typed   = $typist->apply_types( $payload );

  jcmp_deeply(
    $typed,
    { str => 5, num => 5, t => bool(1), f => bool(0), b => bool(1) },
    "jcmp_deeply falls back to string compare",
  );

  jcmp_deeply(
    $typed,
    { str => jstr(5), num => jnum(5), t => jtrue, f => jfalse, b => jbool },
    "jcmp_deeply built-ins",
  );

  jcmp_deeply(
    $typed,
    { str => jstr(), num => jnum(), t => jtrue, f => jfalse, b => jbool },
    "jcmp_deeply built-ins without values",
  );

  # TODO: test failures, too
};

subtest "jtype routines for serialization" => sub {
  my $struct = {
    num => jnum(5),
    str => jstr(5),
    t   => jtrue(),
    f   => jfalse(),
  };

  my $typist  = JSON::Typist->new;
  my $json    = JSON::PP->new->convert_blessed->canonical;
  my $content = $json->encode( $struct );
  my $payload = $json->decode( $content );
  my $typed   = $typist->apply_types( $payload );

  cmp_ok($struct->{num}, '==', 5, "our jnum compares with ==");
  cmp_ok($struct->{str}, 'eq', 5, "our jstr compares with eq");
  ok(  $struct->{t}, "our jtrue() is true");
  ok(! $struct->{f}, "our jfalse() is false");

  jcmp_deeply(
    $typed,
    $struct,
    "jtype tests serialize to self-match",
  );

  for my $test (
    [ jnum  => jnum()  ],
    [ jstr  => jstr()  ],
    [ jbool => jbool() ],
  ) {
    my ($desc, $obj) = @$test;

    subtest "valueless $desc" => sub {
      {
        my $lived = eval { $json->encode({ value => $obj }); 1 };
        my $error = $@;
        ok(! $lived, "can't serialize a $desc that has no value");
        like($error, qr/valueless $desc/, "...and we get the expected error");
      }

      for my $use (
        [ string => sub { "$_[0]" }     ],
        [ number => sub { 0 + $_[0] }   ],
        [ bool   => sub { if($_[0]){} } ],
      ) {
        my $lived = eval { $use->[1]($obj); 1 };
        my $error = $@;
        ok(! $lived, "can't use a valuelss $desc as a $use->[0]");
        like($error, qr/valueless/, "...with a sensible-ish error message");
      }
    }
  }
};

done_testing;
