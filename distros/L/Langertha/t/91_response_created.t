#!/usr/bin/env perl
# ABSTRACT: Langertha::Moment and Response.created — sub-seconds in, epoch out
#
# GitHub issue #3 / karr #92 / karr #117. Ollama sends `created_at` as RFC3339
# with nanosecond precision; Response.created was a Maybe[Int], so every
# non-streaming Ollama chat died in the constructor. karr #92 fixed that by
# flattening the stamp to epoch seconds inside the engine — which cost the
# sub-seconds. Response.created is now a Langertha::Moment (a Time::Moment
# subclass), so nothing is thrown away on the way in.
#
# Two contracts are locked here, and they pull in opposite directions:
#
#   * PRECISION — the nanoseconds a provider sends survive the whole path from
#     the wire into the object, and the stamp round-trips byte for byte.
#   * BACK-COMPAT — numeric context still yields exactly the Int this
#     attribute yielded for its whole life, and the bounded Response hash
#     (TO_JSON, karr #50) still serializes `created` as a JSON number.
#
# The karr #92 hardenings (epoch-shaped shim values, the "0001-01-01T00:00:00Z"
# zero-value sentinel, unreadable stamps dropping the field instead of killing
# the response) are locked in t/70_response.t against the real server fixtures;
# what is tested here is the value object those hardenings now live in.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Scalar::Util qw( blessed reftype looks_like_number );

use Langertha::Moment;
use Langertha::Response;
use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new->canonical(1);

# The stamp from the actual bug report (heince, GH #3, 2026-05-05).
my $GH3_STAMP = '2026-05-05T02:53:03.138043625Z';
my $GH3_EPOCH = 1777949583;
my $GH3_NANO  = 138043625;

# --- The value object -------------------------------------------------------

subtest 'Langertha::Moment is a Time::Moment, and stays one' => sub {
  my $m = Langertha::Moment->from_string($GH3_STAMP);

  isa_ok($m, 'Langertha::Moment');
  isa_ok($m, 'Time::Moment');
  is(ref $m, 'Langertha::Moment',
    'an inherited constructor blesses into the subclass, not the parent');

  # Time::Moment derives new instances from inside XS. If that did not carry
  # the invocant class along, every derivation would silently drop back to a
  # plain Time::Moment and lose the overloads this class exists for.
  is(ref $m->plus_days(1), 'Langertha::Moment',
    'a derived instance is still a Langertha::Moment');
  is(ref $m->with_offset_same_instant(60), 'Langertha::Moment',
    'an offset-shifted instance is still a Langertha::Moment');

  is($m->year, 2026, 'inherited accessors work');
};

subtest 'the overload contract: 0+ is the epoch, "" is the full stamp' => sub {
  my $m = Langertha::Moment->from_string($GH3_STAMP);

  # This is THE back-compat clause. Everything that read Response.created as a
  # Unix timestamp keeps reading a Unix timestamp.
  is(0 + $m, $GH3_EPOCH, 'numeric context is the Unix epoch');
  is($m->epoch, $GH3_EPOCH, 'and matches ->epoch');

  is("$m", $GH3_STAMP, 'string context is the full ISO-8601 stamp');
  is($m->nanosecond, $GH3_NANO, 'nanoseconds are on the object');

  # Time::Moment overloads '<=>' with a compare() that dies on anything that
  # is not a Time::Moment — exactly what `$response->created > $cutoff` is.
  # The subclass has to take that operator over, or old numeric comparisons
  # blow up instead of merely losing precision.
  ok($m > $GH3_EPOCH - 1, 'numeric comparison against a plain number works');
  ok($m < $GH3_EPOCH + 1, 'numeric comparison the other way works');
  is($m <=> $GH3_EPOCH, 0, 'whole-second compare against a number is equal');
  is($GH3_EPOCH <=> $m, 0, 'and is symmetric with the operands swapped');

  # Against another moment it must be the full-precision compare, not the
  # truncated epoch — otherwise two stamps in the same second sort as equal.
  my $earlier = Langertha::Moment->from_string('2026-05-05T02:53:03.000000001Z');
  ok($m > $earlier, 'moment-vs-moment comparison is nanosecond-exact');
  is($earlier <=> $m, -1, 'and orders correctly');

  is(($m cmp $earlier), 1, 'cmp compares the ISO-8601 strings');

  # Left to autogeneration perl derives bool from '0+' here, which makes the
  # epoch-0 moment false. It is a real instant; the class declares bool as a
  # constant true instead, the same call Langertha::Response makes for its own
  # empty-content case (karr #100). This is a deliberate departure from the
  # old Int, where `created => 0` was false.
  ok(Langertha::Moment->from_epoch(0), 'the epoch-0 moment is true');
  ok(Langertha::Moment->from_wire($GH3_STAMP), 'and so is any other');
};

subtest 'deliberately not a Moose class' => sub {
  # Langertha's house rule is "Moose exclusively, always make_immutable". This
  # class is the documented exception: Time::Moment is XS, its instances are
  # blessed SCALARs, and its constructors never route through
  # Moose::Object::new. A metaclass here would describe an object system
  # nothing uses. Asserted rather than merely commented, so a well-meant
  # "convert this to Moose" is caught by the suite and not by a user.
  ok(!Langertha::Moment->can('meta'), 'no Moose metaclass');
  ok(!Langertha::Moment->can('BUILDARGS'), 'no Moose constructor hooks');
  is(reftype(Langertha::Moment->from_epoch(0)), 'SCALAR',
    'instances are the parent XS SCALARs, not Moose hashrefs');
};

# --- from_wire: the one lenient inbound door --------------------------------

subtest 'from_wire accepts every shape a provider actually sends' => sub {
  my %accepted = (
    'Ollama RFC3339 with nanoseconds' => [ $GH3_STAMP,                    $GH3_EPOCH ],
    'whole-second UTC'                => [ '2026-02-22T04:00:45Z',        1771732845 ],
    'positive offset'                 => [ '2026-02-22T05:00:45+01:00',   1771732845 ],
    'negative offset'                 => [ '2026-02-22T03:00:45-01:00',   1771732845 ],
    'offset without a colon'          => [ '2026-02-22T03:00:45-0100',    1771732845 ],
    'space instead of the T'          => [ '2026-02-22 04:00:45Z',        1771732845 ],
    'lowercase t and z'               => [ '2026-02-22t04:00:45z',        1771732845 ],
    'OpenAI epoch integer'            => [ 1771732845,                    1771732845 ],
    'epoch seconds as text'           => [ '1771732845',                  1771732845 ],
    'fractional epoch'                => [ '1771732845.5',                1771732845 ],
    # A bare integer is an epoch, whatever else it might look like: '2026' is
    # 1970-01-01T00:33:46Z, not the year. The ambiguity is in the wire, not in
    # the parser, and it resolves exactly the way karr #92's regex resolved it.
    'a small integer is still an epoch' => [ '2026',                      2026 ],
  );
  for my $name (sort keys %accepted) {
    my ( $input, $epoch ) = @{ $accepted{$name} };
    my $m = Langertha::Moment->from_wire($input);
    isa_ok($m, 'Langertha::Moment') or next;
    is(0 + $m, $epoch, "$name: numifies to the expected epoch");
  }

  # The list above is not decoration: every string form in it was accepted by
  # the hand-rolled RFC3339 regex from karr #92 that from_wire replaces. The
  # replacement must not quietly narrow the door.
};

subtest 'from_wire reads a 13-digit millisecond epoch, not a seconds one' => sub {
  # karr #171. Some providers report the epoch in milliseconds. Fed straight to
  # from_epoch a 13-digit value is out of Time::Moment's range (its whole span
  # through year 9999 tops out at the 12-digit 253402300799), so it used to die
  # inside the eval and the `created` field was silently dropped. It is now read
  # as milliseconds and scaled to seconds, sub-second precision kept.
  my $MS = $GH3_EPOCH * 1000 + 138;   # 1777949583138 — a real 13-digit epoch

  for my $input ( $MS, "$MS" ) {
    my $m = Langertha::Moment->from_wire($input);
    isa_ok($m, 'Langertha::Moment') or next;
    is(0 + $m, $GH3_EPOCH, "'$input': numifies to the seconds epoch, not the raw ms value");
    is($m->millisecond, 138, "'$input': the milliseconds survive as sub-seconds");
    is("$m", '2026-05-05T02:53:03.138Z', "'$input': lands on the correct instant");
  }

  # The boundary must not misclassify a normal seconds epoch. A ~10-digit
  # seconds epoch is below 1e12 and is left exactly as it was — scaling it would
  # push the instant back to 1970.
  my $secs = Langertha::Moment->from_wire($GH3_EPOCH);
  is(0 + $secs, $GH3_EPOCH, 'a 10-digit seconds epoch is not scaled');
  is($secs->millisecond, 0, 'and carries no phantom sub-seconds');

  # Leniency is unchanged: garbage still drops the field rather than dying, and
  # only the millisecond band is rescued — a 16-digit microsecond value stays
  # out of range and is dropped, exactly as before.
  ok(!$@, 'no death along the way');
  is(Langertha::Moment->from_wire('not-a-timestamp'), undef,
    'garbage still yields undef');
  is(Langertha::Moment->from_wire('1777949583138000'), undef,
    'a 16-digit microsecond epoch is still dropped (only the ms case changed)');
};

subtest 'from_wire returns undef instead of dying, for everything else' => sub {
  my %rejected = (
    'undef'                  => undef,
    'empty string'           => '',
    'free text'              => 'not-a-timestamp',
    'a bare date'            => '2026-02-22',
    'a date without offset'  => '2026-02-22T04:00:45',
    'the Go zero value'      => '0001-01-01T00:00:00Z',
    'out of representable range' => '1e30',
    'a reference'            => { created => 1 },
  );
  for my $name (sort keys %rejected) {
    my $m = eval { Langertha::Moment->from_wire( $rejected{$name} ) };
    ok(!$@, "$name: from_wire does not die") or diag($@);
    is($m, undef, "$name: yields undef");
  }

  # The sentinel deserves its own note: "0001-01-01T00:00:00Z" is a perfectly
  # valid RFC3339 string that Time::Moment parses without complaint, so
  # rejecting it is a decision, not a parse failure. It is Go's zero
  # time.Time, which is what Ollama emits when it has no timestamp to report
  # (karr #92). The strict constructor still takes it — leniency is opt-in.
  my $sentinel = Langertha::Moment->from_string('0001-01-01T00:00:00Z');
  is($sentinel->year, 1, 'from_string still parses the sentinel happily');
  is(Langertha::Moment->from_wire('0001-01-01T00:00:00Z'), undef,
    'from_wire rejects it as "no timestamp"');
};

subtest 'from_wire on objects' => sub {
  my $m = Langertha::Moment->from_wire($GH3_STAMP);
  is(Langertha::Moment->from_wire($m), $m, 'an existing moment passes through unchanged');

  my $plain = Time::Moment->from_string($GH3_STAMP);
  my $upgraded = Langertha::Moment->from_wire($plain);
  isa_ok($upgraded, 'Langertha::Moment');
  is("$upgraded", $GH3_STAMP, 'a plain Time::Moment is upgraded losslessly');
  is($upgraded->nanosecond, $GH3_NANO, 'including its nanoseconds');
};

# --- Wire to object, end to end ---------------------------------------------

sub ollama_http {
  my ( $body ) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'application/json');
  $http->content($body);
  return $http;
}

subtest 'GH #3: the reporter stamp survives the whole path with its nanoseconds' => sub {
  my $ollama = Langertha::Engine::Ollama->new(
    url   => 'http://localhost:11434',
    model => 'qwen3:8b',
  );
  my $resp = $ollama->chat_response( ollama_http( $json->encode({
    model       => 'qwen3:8b',
    created_at  => $GH3_STAMP,
    message     => { role => 'assistant', content => 'hello' },
    done        => JSON->true,
    done_reason => 'stop',
  }) ) );

  # The croak from the issue report.
  ok(defined $resp, 'the response constructs at all');

  isa_ok($resp->created, 'Langertha::Moment');
  is($resp->created->nanosecond, $GH3_NANO,
    'the nanoseconds reach the object — this is what karr #92 flattened away');
  is("" . $resp->created, $GH3_STAMP,
    'and the stamp round-trips byte for byte');

  # The back-compat clause, on the same object.
  is(0 + $resp->created, $GH3_EPOCH, 'numeric context is the old Unix timestamp');

  is($resp->raw->{created_at}, $GH3_STAMP,
    'the provider-native form is still under raw, untouched');
};

subtest 'the OpenAI epoch path lands on the same kind of object' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'testkey', model => 'gpt-4o-mini' );
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'application/json');
  $http->content( $json->encode({
    id      => 'chatcmpl-1',
    model   => 'gpt-4o-mini',
    created => $GH3_EPOCH,
    choices => [ { message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' } ],
  }) );

  my $resp = $openai->chat_response($http);
  isa_ok($resp->created, 'Langertha::Moment');
  is(0 + $resp->created, $GH3_EPOCH, 'the bare epoch integer round-trips');
  is("" . $resp->created, '2026-05-05T02:53:03Z',
    'with no sub-seconds, because the wire had none to give');

  # Both producers now hand back a comparable value — which is the point of
  # normalizing at the Response instead of once per engine.
  is($resp->created <=> Langertha::Moment->from_epoch($GH3_EPOCH), 0,
    'equal to the same instant built directly');
};

subtest 'string context is the ISO stamp — the deliberate break' => sub {
  # Not a bug and not an oversight: interpolation of `created` used to give the
  # epoch digits and now gives the full stamp. That is the new semantics, and
  # it is pinned here so nobody "fixes" it back into a number and takes the
  # sub-seconds out of reach again. Callers that want the number ask for it:
  # `0 + $response->created`.
  my $resp = Langertha::Response->new( content => 'hi', created => $GH3_STAMP );

  is("@{[ $resp->created ]}", $GH3_STAMP, 'interpolation yields the ISO-8601 stamp');
  is($resp->created . '', $GH3_STAMP, 'concatenation yields the ISO-8601 stamp');
  isnt($resp->created . '', "$GH3_EPOCH", 'and no longer the epoch digits');
  ok(!($resp->created eq "$GH3_EPOCH"), 'string equality against the epoch digits is now false');

  # ref/blessed are no longer empty — anything branching on `ref $created`
  # takes the other path now.
  is(ref $resp->created, 'Langertha::Moment', 'ref() is no longer the empty string');
  ok(blessed($resp->created), 'blessed() is no longer undef');

  # A hash key stringifies, so a keyed-by-created structure re-keys itself.
  my %by_created = ( $resp->created => 'x' );
  is((keys %by_created)[0], $GH3_STAMP, 'used as a hash key it is the ISO stamp, not the epoch');

  # looks_like_number keeps saying yes: it honours the '0+' overload rather
  # than the string one, so a numeric guard in caller code still passes.
  ok(looks_like_number($resp->created),
    'looks_like_number still true, via the 0+ overload');
};

subtest 'a bare created value encodes on its own' => sub {
  # The dangerous one. The old Int went through any encoder. An object goes
  # through only an encoder with convert_blessed — and then only lands on a
  # number because Langertha::Moment overrides Time::Moment's TO_JSON, which
  # would have returned the ISO string and silently changed the field's JSON
  # type wherever a caller serializes the value by itself.
  my $created = Langertha::Moment->from_wire($GH3_STAMP);

  my $ok = JSON::MaybeXS->new->canonical(1)->convert_blessed(1);
  is($ok->encode({ created => $created }), qq({"created":$GH3_EPOCH}),
    'convert_blessed encodes a bare moment as the epoch number');
  is($created->TO_JSON, $GH3_EPOCH, 'TO_JSON is the number, not the ISO string');
  ok(!ref $created->TO_JSON, 'and a plain scalar');
  isnt($created->TO_JSON, $GH3_STAMP,
    'Time::Moment::TO_JSON (the ISO string) is overridden, not inherited');

  # Without convert_blessed it dies. This is the break to name in the release
  # notes: it is the same failure mode GH #3 reported, moved from the Response
  # constructor to a caller's own encoder — and it is the failure mode every
  # other value object on a Response has had since they landed.
  my $strict = JSON::MaybeXS->new->canonical(1);
  my $out = eval { $strict->encode({ created => $created }) };
  ok(!defined $out, 'an encoder without convert_blessed refuses the object');
  like($@, qr/blessed|TO_JSON/i, 'and says why');
};

subtest 'the bounded Response hash still emits created as a JSON number' => sub {
  # karr #50 pinned the shape of TO_JSON. A trace consumer that has been
  # reading a number out of `created` since the class existed must keep
  # reading a number, whatever richer thing the attribute now holds. The
  # sub-seconds live on the object and under raw, not in this hash.
  my $resp = Langertha::Response->new(
    content => 'hi',
    created => $GH3_STAMP,
  );
  my $hash = $resp->to_hash;
  ok(!ref $hash->{created}, 'to_hash gives a plain scalar, not the object');
  is($hash->{created}, $GH3_EPOCH, 'and it is the epoch');

  my $encoder = JSON::MaybeXS->new->canonical(1)->convert_blessed(1);
  my $encoded = $encoder->encode($resp);
  like($encoded, qr/"created":$GH3_EPOCH(?![0-9"])/, 'TO_JSON serializes it unquoted');
  unlike($encoded, qr/\Q$GH3_STAMP\E/, 'and the ISO stamp is not what lands in the JSON');
};

subtest 'created stays optional, and an unreadable stamp is never fatal' => sub {
  my $none = Langertha::Response->new( content => 'hi' );
  ok(!$none->has_created, 'has_created is false when nothing was set');
  is($none->created, undef, 'and the accessor is undef');
  ok(!exists $none->to_hash->{created}, 'to_hash omits it entirely');

  # A timestamp is metadata. Whatever a provider puts in that field, the reply
  # the caller actually asked for must come back — that is the whole lesson of
  # GH #3, generalized from Ollama to every producer by moving the parse into
  # Response's BUILDARGS.
  for my $bad ('not-a-timestamp', '0001-01-01T00:00:00Z', '') {
    my $resp = eval { Langertha::Response->new( content => 'hi', created => $bad ) };
    ok(defined $resp, "created '$bad': the response is still built") or diag($@);
    ok(defined $resp && !$resp->has_created, "created '$bad': the field is dropped");
    is(defined $resp ? "$resp" : undef, 'hi', "created '$bad': the content is intact");
  }
};

subtest 'clone_with carries the moment across untouched' => sub {
  my $resp = Langertha::Response->new( content => 'hi', created => $GH3_STAMP );
  my $clone = $resp->clone_with( content => 'filtered' );
  isa_ok($clone->created, 'Langertha::Moment');
  is($clone->created->nanosecond, $GH3_NANO, 'nanoseconds survive the clone');
  is(0 + $clone->created, $GH3_EPOCH, 'and so does the epoch');
};

done_testing;
