use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json encode_json );
use Mojo::Parameters;
use Langertha::Skeid::Protocol::Realtime;

# The wire of the realtime route (skeid k95, ADR 0029), as pure functions. The frames below are
# written by hand after OpenAI's documentation -- synthetic, not recorded from a live backend
# (t/data/realtime/README.md says why). The point is what Skeid does with each: forward it,
# rewrite the model of an alias tier, or refuse a model the key was never granted.

my $P = 'Langertha::Skeid::Protocol::Realtime';

sub frame { return encode_json($_[0]) }

subtest 'query_model: one non-empty model, nothing else names one' => sub {
  my ($m, $problem) = $P->query_model(Mojo::Parameters->new('model=whisper-rt&intent=transcription'));
  is $m, 'whisper-rt', 'the model';
  ok !defined $problem, 'no problem';

  ($m, $problem) = $P->query_model(Mojo::Parameters->new('intent=transcription'));
  ok !defined $m, 'intent=transcription alone names no model';
  like $problem, qr/'model'.*required/, 'and says so';

  ($m, $problem) = $P->query_model(Mojo::Parameters->new('model=a&model=b'));
  ok !defined $m, 'two models are refused';
  like $problem, qr/only once/, 'and says so';

  ($m, $problem) = $P->query_model(Mojo::Parameters->new('model='));
  ok !defined $m, 'an empty model is refused';
  ($m, $problem) = $P->query_model(Mojo::Parameters->new('model=' . ('x' x 1025)));
  ok !defined $m, 'a model above 1024 bytes is refused';
};

subtest 'upstream_url: ws scheme, the served model, the rest as sent' => sub {
  my $q = Mojo::Parameters->new('intent=transcription&model=house-asr&language=de');
  is $P->upstream_url('http://node:8000/v1/realtime', 'whisper-large', $q),
    'ws://node:8000/v1/realtime?model=whisper-large&intent=transcription&language=de',
    'http becomes ws, the served model replaces the asked one';
  like $P->upstream_url('https://node/v1/realtime', 'm', Mojo::Parameters->new('model=m')),
    qr{\Awss://node/v1/realtime\?model=m\z}, 'https becomes wss';
};

subtest 'subprotocol_key: the browser convention, first entry' => sub {
  is $P->subprotocol_key('realtime, openai-insecure-api-key.sk-abc, openai-beta.realtime-v1'),
    'sk-abc', 'the key entry is found beside realtime';
  is $P->subprotocol_key('openai-insecure-api-key.sk-1,openai-insecure-api-key.sk-2'), 'sk-1',
    'the first one counts';
  ok !defined $P->subprotocol_key('realtime'), 'no key entry, no key';
  ok !defined $P->subprotocol_key(undef), 'no header, no key';
  ok !defined $P->subprotocol_key('openai-insecure-api-key.'), 'an empty key is none';
  is $P->subprotocol, 'realtime', 'the subprotocol Skeid selects is never the key entry';
};

subtest 'client_frame: the model of a session' => sub {
  # GA dialect.
  my $ga = frame({ type => 'session.update', session => { type => 'transcription',
    audio => { input => { format => { type => 'audio/pcm', rate => 24000 },
      transcription => { model => 'house-asr', language => 'de' } } } } });
  my $r = $P->client_frame($ga, 'house-asr', 'whisper-large');
  is $r->{action}, 'forward', 'GA session.update naming the requested model is forwarded';
  ok $r->{rewritten}, 'and was rewritten';
  is decode_json($r->{text})->{session}{audio}{input}{transcription}{model}, 'whisper-large',
    'to the served model';
  is decode_json($r->{text})->{session}{audio}{input}{transcription}{language}, 'de',
    'everything else is kept';

  # Beta dialect.
  my $beta = frame({ type => 'transcription_session.update',
    session => { input_audio_transcription => { model => 'house-asr', prompt => 'x' },
      turn_detection => { type => 'server_vad' } } });
  $r = $P->client_frame($beta, 'house-asr', 'whisper-large');
  is $r->{action}, 'forward', 'beta transcription_session.update is forwarded as it is spoken';
  is decode_json($r->{text})->{type}, 'transcription_session.update', 'the event is not translated';
  is decode_json($r->{text})->{session}{input_audio_transcription}{model}, 'whisper-large',
    'the beta model place is rewritten';

  # session.model, the realtime session's own.
  $r = $P->client_frame(frame({ type => 'session.update', session => { model => 'house-asr' } }),
    'house-asr', 'house-asr');
  is $r->{action}, 'forward', 'a model equal to served stays';
  ok !$r->{rewritten}, 'and is not marked rewritten';

  # A foreign model, in every place.
  for my $case (
    [ 'GA place',   { type => 'session.update', session => { audio => { input => { transcription => { model => 'gpt-4o' } } } } } ],
    [ 'beta place', { type => 'transcription_session.update', session => { input_audio_transcription => { model => 'gpt-4o' } } } ],
    [ 'session.model', { type => 'session.update', session => { model => 'gpt-4o' } } ],
    [ 'top level',  { type => 'session.update', model => 'gpt-4o', session => {} } ],
    [ 'next to the right one', { type => 'session.update',
        session => { model => 'house-asr', audio => { input => { transcription => { model => 'gpt-4o' } } } } } ],
    [ 'inside an array', { type => 'session.update', session => { extra => [ { model => 'gpt-4o' } ] } } ],
  ) {
    my ($label, $body) = @$case;
    my $out = $P->client_frame(frame({ %$body, event_id => 'evt_9' }), 'house-asr', 'whisper-large');
    is $out->{action}, 'refuse', "a foreign model is refused: $label";
    my $event = decode_json($out->{text});
    is $event->{type}, 'error', 'the answer is an error event';
    is $event->{error}{event_id}, 'evt_9', 'which names the offending event';
    unlike $out->{text}, qr/gpt-4o/, 'and does not echo the foreign model';
  }

  # The same session.update, spelled so a substring test misses it.
  my $bs = chr(92);
  my $escaped = '{"type":"session.up' . $bs . 'u0064ate","session":{"' . $bs . 'u006dodel":"gpt-4o"}}';
  unlike $escaped, qr/session\.update/, 'the spelling hides the event name from a substring test';
  $r = $P->client_frame($escaped, 'house-asr', 'whisper-large');
  is $r->{action}, 'refuse', 'a unicode-escaped session.update is decoded and refused';

  # Non-objects and garbage.
  for my $bad ('not json', '[1,2]', '"text"', '42', 'null', '', "{\"type\":\"a\"} trailing",
    "{\"a\":\"\xff\xfe\"}") {
    $r = $P->client_frame($bad, 'house-asr', 'whisper-large');
    is $r->{action}, 'close', 'closed, not forwarded: ' . encode_json([ $bad =~ /[\x00-\x7f]*/ ? $bad : 'bytes' ]);
    is $r->{code}, 1003, 'with 1003';
  }

  # Audio is decoded too, and forwarded as the document.
  my $audio = frame({ type => 'input_audio_buffer.append', audio => 'AAEC' x 100 });
  $r = $P->client_frame($audio, 'house-asr', 'whisper-large');
  is $r->{action}, 'forward', 'an audio chunk is forwarded';
  is_deeply decode_json($r->{text}), decode_json($audio), 'as the same document';
  ok !$r->{rewritten}, 'untouched';
  $r = $P->client_frame(frame({ type => 'input_audio_buffer.commit' }), 'a', 'b');
  is $r->{action}, 'forward', 'commit is forwarded';
};

subtest 'client_frame: a document with two readings is not forwarded as one' => sub {
  # The decoder is strict on duplicate keys (Cpanel::JSON::XS); on one that is not, the frame
  # is forwarded as the one document Skeid read, encoded again -- never as the client's bytes.
  my $dup = '{"type":"input_audio_buffer.append","type":"session.update","session":{"model":"gpt-4o"}}';
  my $r = $P->client_frame($dup, 'house-asr', 'whisper-large');
  if ($r->{action} eq 'forward') {
    unlike $r->{text}, qr/\A\{.*"type".*"type"/s, 'forwarded once, as the document Skeid read';
    is scalar(() = $r->{text} =~ /"type"/g), 1, 'with a single type';
  }
  else {
    ok $r->{action} eq 'close' || $r->{action} eq 'refuse', 'refused or closed, not forwarded as it came';
  }
};

subtest 'server_frame: usage, text, errors' => sub {
  my $done = $P->server_frame(frame({
    type => 'conversation.item.input_audio_transcription.completed', item_id => 'item_1',
    transcript => 'Hallo Welt',
    usage => { type => 'tokens', input_tokens => 14, output_tokens => 6, total_tokens => 20 },
  }));
  is $done->{usage}{total_tokens}, 20, 'the usage block of a completed transcription';
  ok !$done->{error}, 'no error';

  my $delta = $P->server_frame(frame({
    type => 'conversation.item.input_audio_transcription.delta', item_id => 'item_1', delta => 'Hal' }));
  is $delta->{delta_text}, 'Hal', 'the text of a delta';
  ok !$delta->{usage}, 'which has no usage';

  ok $P->server_frame(frame({ type => 'error', error => { message => 'boom' } }))->{error},
    'an error event is one';
  is_deeply $P->server_frame('not json'), { type => undef, usage => undef, delta_text => undef, error => 0 },
    'a frame that does not decode says nothing';
  ok !$P->server_frame(frame({ type => 'session.created', usage => { total_tokens => 5 } }))->{usage},
    'usage on another event is not a transcription';
};

subtest 'usage blocks are summed, and seconds read' => sub {
  my $sum;
  $sum = $P->add_usage($sum, { type => 'tokens', input_tokens => 14, output_tokens => 6, total_tokens => 20,
    input_token_details => { audio_tokens => 14, text_tokens => 0 } });
  $sum = $P->add_usage($sum, { type => 'tokens', input_tokens => 10, output_tokens => 4, total_tokens => 14,
    input_token_details => { audio_tokens => 10, text_tokens => 0 } });
  is $sum->{input_tokens}, 24, 'input tokens are summed';
  is $sum->{total_tokens}, 34, 'totals are summed';
  is $sum->{input_token_details}{audio_tokens}, 24, 'so are nested counts';
  is $sum->{type}, 'tokens', 'the type is kept';

  is $P->seconds({ type => 'duration', seconds => 12.5 }), 12.5, 'seconds of a duration block';
  ok !defined $P->seconds({ type => 'tokens', seconds => 3 }), 'not of a token block';
  ok !defined $P->seconds({ type => 'duration', seconds => -1 }), 'not a negative one';
  ok !defined $P->seconds({ type => 'duration', seconds => 'soon' }), 'not a word';
};

done_testing;
