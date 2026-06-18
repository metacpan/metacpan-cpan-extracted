use strict;
use warnings;

use HTTP::Response;
use JMAP::Tester;
use JMAP::Tester::Response;
use JSON::Typist 0.005; # $typist->number

use Scalar::Util 'blessed';
use Test::Deep ':v1';
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::Fatal;
use Test::More;
use Test::Abortable 'subtest';

# ATTENTION:  You're really not meant to just create Response objects.  They're
# supposed to come from Testers.  Doing that in the tests, though, would
# require mocking up a remote end.  Until we're up for doing that, this is
# simpler for testing. -- rjbs, 2016-12-15

my $DUMPER = sub { "(@_)" };

subtest "the basic basics" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ jstr('atePies'),
        { howMany => jnum(100), tastiestPieId => jstr(123) },
        jstr('a') ],
      [ jstr('platesDiscarded'),
        { notDiscarded => [] },
        jstr('a') ],

      [ jstr('drankBeer'),
        { abv => jnum(0.02) },
        jstr('b') ],

      [ jstr('tookNap'),
        { successfulDuration => jnum(2) },
        jstr('c') ],
      [ jstr('dreamed'),
        { about => jstr("more pie") },
        jstr('c') ],
    ],
  });

  for my $pair (
    [ response  => sub { my $meth = shift; $res->$meth->[0] } ],
    [ paragraph => sub { my $meth = shift; $res->paragraph(0)->$meth->[0] } ],
    [ sentence  => sub { my $meth = shift; $res->sentence(0)->$meth } ],
  ) {
    subtest "structure tests on $pair->[0]" => sub {
      my $call = $pair->[1];

      my $triple_method = $pair->[0] eq 'sentence' ? 'triple' : 'triples';
      jcmp_deeply(
        $call->("as_${triple_method}"),
        [
          jstr('atePies'),
          { howMany => jnum(100), tastiestPieId => jstr(123) },
          jstr('a'),
        ],
        "as_${triple_method}",
      );

      my $pair_method = $pair->[0] eq 'sentence' ? 'pair' : 'pairs';
      jcmp_deeply(
        $call->("as_${pair_method}"),
        [
          jstr('atePies'),
          { howMany => jnum(100), tastiestPieId => jstr(123) },
        ],
        "as_${pair_method}",
      );

      jcmp_deeply(
        $call->("as_stripped_${triple_method}"),
        [ 'atePies', { howMany => 100, tastiestPieId => 123 }, 'a' ],
        "as_stripped_${triple_method}",
      );

      jcmp_deeply(
        $call->("as_stripped_${pair_method}"),
        [ 'atePies', { howMany => 100, tastiestPieId => 123 } ],
        "as_stripped_${pair_method}",
      );
    }
  }

  is($res->sentences,   5, "there are five sentences");
  is($res->paragraphs,  3, "there are three paragraphs");

  ok($res->is_success, "a JMAP::Tester::Response is a success");

  is($res->sentence(0)->name, "atePies",         "s0 name");
  is($res->sentence(1)->name, "platesDiscarded", "s1 name");
  is($res->sentence(2)->name, "drankBeer",       "s2 name");
  is($res->sentence(3)->name, "tookNap",         "s3 name");
  is($res->sentence(4)->name, "dreamed",         "s4 name");
  aborts_ok(
    sub { $res->sentence(5) },
    re('no sentence for index'),
    "s5 does not exist",
  );

  ok($res->sentence(0)->assert_named('atePies'), "assert_named (Sentence)");
  aborts_ok(
    sub { $res->sentence(0)->assert_named("eatedPies") },
    re('expected sentence named "eatedPies" but got "atePies"'),
    "assert_named aborts when it should",
  );

  ok($res->sentence(0)->assert_named('atePies'), "assert_named works");

  my ($p0, $p1, $p2) = $res->assert_n_paragraphs(3);

  is($p0->sentence(0)->name, "atePies",         "p0 s0 name");
  is($p0->sentence(1)->name, "platesDiscarded", "p0 s1 name");
  is($p1->sentence(0)->name, "drankBeer",       "p1 s0 name");
  is($p2->sentence(0)->name, "tookNap",         "p2 s0 name");
  is($p2->sentence(1)->name, "dreamed",         "p2 s1 name");
  aborts_ok(
    sub { $p2->sentence(2) },
    re('no sentence for index 2'),
    "p2 s2 does not exist",
  );

  is($res->paragraph(0)->client_id, 'a',    "p0 cid");
  aborts_ok(
    sub { $res->paragraph(3) },
    re('no paragraph for index 3'),
    "p3 does not exist",
  );

  my @p2_sentences = $p2->sentences;
  is(@p2_sentences, 2, "p2 sentences");

  is($res->sentence_named('dreamed')->name, "dreamed", "res->sentence_named");
  is($p2->sentence_named('dreamed')->name,  "dreamed", "p2->sentence_named");
  aborts_ok(
    sub { $res->sentence_named('poundedSand') },
    re('no sentence found with name "poundedSand"'),
    "no sentence in response",
  );

  aborts_ok(
    sub { $p1->sentence_named('poundedSand') },
    re('no sentence found with name "poundedSand"'),
    "no sentence in paragraph",
  );
};

subtest "old style updated" => sub {
  my %kinds = (
    old => [ 'a', 'b' ],
    new => {
      a => undef,
      b => { awesomeness => jstr('high') },
    },
  );

  for my $kind (sort keys %kinds) {
    my $res = JMAP::Tester::Response->new({
      diagnostic_dumper => $DUMPER,
      items => [
        [ 'Piece/set' => { updated => $kinds{$kind} }, 'a' ]
      ],
    });

    my $s = $res->single_sentence('Piece/set')->as_set;

    is_deeply(
      [ sort $s->updated_ids ],
      [ qw(a b) ],
      "we can get updated_ids from $kind style updated",
    );

    my $want = ref $kinds{$kind} eq 'HASH'
             ? $kinds{$kind}
             : { map {; $_ => undef } @{ $kinds{$kind} } };

    is_deeply($s->updated, $want, "can get updated from $kind style updated");
  }
};

subtest "basic abort" => sub {
  my $events = Test2::API::intercept(sub {
    subtest "this will abort" => sub {
      my $res = JMAP::Tester::Response->new({
        diagnostic_dumper => $DUMPER,
        items => [
          [ atePies => { howMany => jnum(100), tastiestPieId => jstr(123) }, 'a' ],
        ],
      });

      $res->single_sentence('piesEt');
      pass("okay");
    };
  });

  my ($subtest) = grep { $_->isa('Test2::Event::Subtest') } @$events;
  my @pass = grep { $_->isa('Test2::Event::Ok') } @{ $subtest->subevents };

  is(@pass, 1, "aborted subtest emits just one ok");
  ok($pass[0]->causes_fail, "and it's a failure");
  isnt(
    index($pass[0]->name, 'single sentence has name "atePies" not "piesEt"'),
    -1,
    "and it's the abort we expect",
  );
};

subtest "set assert_named" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [
        'Piece/set' => {
          updated    => { foo => undef },
          notUpdated => { fail => { type => jstr("internalJoke") } },
          notDestroyed => { tick => { type => jstr("nighInvulnerabile") } },
        },
        'a',
      ]
    ],
  });

  my $s = $res->single_sentence('Piece/set')->as_set;

  ok($res->sentence(0)->assert_named('Piece/set'), "assert_named (Set)");
  aborts_ok(
    sub { $res->sentence(0)->assert_named("setPieces") },
    re('expected sentence named "setPieces" but got "Piece/set"'),
    "assert_named aborts when it should",
  );
};

subtest "set sentence assert_no_errors" => sub {
  my $events = Test2::API::intercept(sub {
    subtest "this will abort" => sub {
      my $res = JMAP::Tester::Response->new({
        diagnostic_dumper => $DUMPER,
        items => [
          [
            'Piece/set' => {
              updated    => { foo => undef },
              notUpdated => { fail => { type => jstr("internalJoke") } },
              notDestroyed => { tick => { type => jstr("nighInvulnerabile") } },
            },
            'a',
          ]
        ],
      });

      my $s = $res->single_sentence('Piece/set')->as_set;

      $s->assert_no_errors;

      pass("never reach me");
    };
  });

  my ($subtest) = grep { $_->isa('Test2::Event::Subtest') } @$events;
  my @subevents = @{ $subtest->subevents };
  my @pass = grep { $_->isa('Test2::Event::Ok') } @subevents;
  is(@pass, 1, "aborted subtest emits just one ok");
  ok($pass[0]->causes_fail, "and it's a failure");

  my @diags = sort {; $a->message cmp $b->message }
              grep {; $_->isa('Test2::Event::Diag') } @subevents;

  is(@diags, 2, "we got two distinct diagnostics");
  like($diags[0]->message, qr/notDestroyed/, "...one about destroys");
  like($diags[1]->message, qr/notUpdated/, "...one about destroys");
};

subtest "abort diagnostics" => sub {
  # We build a Response directly and call ->abort on it, inspecting the
  # JMAP::Tester::Abort it throws.  The dumper names the type of whatever ref
  # it's handed, so the diagnostics are exact and we can tell a value that was
  # run through the dumper from one that wasn't. -- claude, 2026-06-17
  my $dumper = sub { "<<" . ref($_[0]) . ">>" };

  my $abort_diagnostics = sub {
    my (@abort_args) = @_;

    my $res = JMAP::Tester::Response->new({
      diagnostic_dumper => $dumper,
      items => [
        [ atePies => { howMany => jnum(100) }, 'a' ],
      ],
    });

    my $err = exception { $res->abort(@abort_args) };

    Carp::confess("->abort did not throw")
      unless blessed $err && $err->isa('JMAP::Tester::Abort');

    return $err->diagnostics;
  };

  my $diag_case = sub {
    my ($desc, $abort_args, $want) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_deeply($abort_diagnostics->(@$abort_args), $want, $desc);
  };

  $diag_case->(
    "a ref-valued diagnostic is run through the diagnostic dumper",
    [ "boom", [ Thing => { a => 1 } ] ],
    [ "Thing: <<HASH>>\n" ],
  );

  $diag_case->(
    "a label with no value becomes a bare diagnostic line",
    [ "boom", [ "Just a label" ] ],
    [ "Just a label\n" ],
  );

  $diag_case->(
    "multiple diagnostics are dumped in order",
    [ "boom", [ One => {}, "Two", Three => [] ] ],
    [ "One: <<HASH>>\n", "Two\n", "Three: <<ARRAY>>\n" ],
  );

  $diag_case->(
    "an explicit empty diag spec produces no diagnostics",
    [ "boom", [] ],
    undef,
  );

  $diag_case->(
    "with no diag spec, a Response defaults to dumping its sentences",
    [ "boom" ],
    [ "Response sentences: <<ARRAY>>\n" ],
  );
};

subtest "add_items aborts" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [ [ atePies => {}, 'a' ] ],
  });

  my $err = exception { $res->add_items([ more => {}, 'b' ]) };

  ok(
    (blessed $err && $err->isa('JMAP::Tester::Abort')),
    "add_items throws a proper abort",
  ) or diag("got: $err");

  like($err->message, qr/can't add items/, "...with the expected message");
};

subtest "calling as_set on non-set sentence" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [[
      error => {
        type => 'internal',
        description => 'allergic to cherries',
      }, 'a',
    ]],
  });

  aborts_ok(
    sub { $res->single_sentence->as_set },
    re(qr{\Qtried to call ->as_set on sentence named "error"\E}),
    "we cannot call ->as_set on a non-set sentence",
  );
};

subtest "miscellaneous error conditions on 1-paragraph 1-sentence response" => sub {
  my $res_1 = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ welcome => { all => jstr('refugees') }, jstr('xyzzy') ],
    ],
  });

  {
    my $error = exception { $res_1->single_sentence('foo') };
    like(
      $error,
      qr/single sentence has name "welcome"/,
      "single_sentence checks name",
    );
  }

  {
    my $error = exception { $res_1->paragraph(0)->sentence_named(undef) };
    like(
      $error,
      qr/no sentence name given/,
      "paragraph->sentence_named needs defined arg",
    );
  }
};

subtest "miscellaneous errors on 2-paragraph 2-sentence response" => sub {
  my $res_2 = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ welcome => { all  => jstr('refugees') }, jstr('xyzzy') ],
      [ goodBye => { blue => jstr('skye') }, jstr('a') ],
    ],
  });

  {
    my $error = exception { $res_2->single_sentence('foo') };
    like($error, qr/there are 2 sentences/, "single_sentence checks count");
  }

  {
    my $error = exception { $res_2->assert_n_paragraphs(10) };
    like(
      $error,
      qr/expected 10 paragraphs but got 2/,
      "assert_n_paragraphs",
    );
  }

  {
    # "The right thing", below, means "gives us the same sentence as we would
    # get if we gave the name of that sentence as the arg to ->single.
    my $p = $res_2->paragraph_by_client_id('xyzzy');
    ok(
      $p->single('welcome') == $p->single,
      "para->single with no arg does the right thing",
    );
  }

  {
    my $ok = eval {

      $res_2->paragraph_by_client_id('xyzzy')->single('welcome');
      $res_2->paragraph_by_client_id('a')->single('goodBye');
      1;
    };

    my $error = $@;
    ok($ok, "paragraph_by_client_id") or diag $error;
  }

  aborts_ok(
    sub { $res_2->paragraph(0)->single('wilkommen') },
    re('single sentence not of expected name'),
    "paragraph->single with wrong name aborts",
  );
};

subtest "miscellaneous errors on 1-paragraph 2-sentence response" => sub {
  my $res_3 = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ welcome => { all => jstr('refugees') }, jstr('xyzzy') ],
      [ welcome => { all => jstr('homeless') }, jstr('xyzzy') ],
    ],
  });

  aborts_ok(
    sub { $res_3->sentence_named('welcome') },
    re('found more than one sentence with name "welcome"'),
    "ambiguous by name"
  );

  aborts_ok(
    sub { $res_3->paragraph(0)->sentence_named('welcome') },
    re('found more than one sentence with name "welcome"'),
    "ambiguous by name",
  );

  aborts_ok(
    sub { $res_3->paragraph(0)->single },
    re('more than one sentence in paragraph'),
    "->single on multi-sentence paragraph",
  );

  {
    my $ok = eval { $res_3->paragraph(0)->assert_n_sentences(2); 1; };
    my $error = $@;
    ok($ok, "successful paragraph->assert_n_sentences") or diag $error;
  }

  {
    my $error = exception { $res_3->paragraph(0)->assert_n_sentences(undef) };
    like(
      $error,
      qr/no sentence count given/,
      "assert_n_sentences needs defined arg",
    );
  }

  aborts_ok(
    sub { $res_3->paragraph(0)->assert_n_sentences(8) },
    re("expected 8 sentences but got 2"),
    "assert_n_sentences aborts on count mismatch",
  );
};

subtest "construction errors" => sub {
  {
    my $error = exception {
      my $res_helper  = JMAP::Tester::Response->new({
        diagnostic_dumper => $DUMPER,
        items => [
          [ welcome => { all => jstr('refugees') }, jstr('c1') ],
          [ welcome => { all => jstr('homeless') }, jstr('c2') ],
        ],
      });

      JMAP::Tester::Response::Paragraph->new({
        sentences => [ $res_helper->sentence(0), $res_helper->sentence(1) ],
      });
    };

    like($error, qr/non-uniform client_ids/, "paragraph cids must match");
  };

  {
    my $error = exception {
      JMAP::Tester::Response::Paragraph->new({ sentences => [] });
    };

    like($error, qr/0-sentence paragraph/, "paragraphs must have sentences");
  };
};

subtest "interpreting HTTP responses" => sub {
  my $tester = JMAP::Tester->new;

  my $new_hres = sub {
    return HTTP::Response->new(
      200,
      "OK",
      [ 'Content-Type', 'application/json' ],
      $_[0],
    );
  };

  {
    my $hres = $new_hres->( '{"methodResponses": [["foo", {"a":1}, "c"]] }' );

    my $jres = $tester->_jresponse_from_hresponse($hres);

    jcmp_deeply(
      $jres->as_pairs,
      [ [ "foo", {a=>1} ] ],
      "JMAP response from Object-wrapped JSON",
    );
  }

  {
    my $hres = $new_hres->( '[["foo", {"a":1}, "c"]]' );

    my $jres = $tester->_jresponse_from_hresponse($hres);

    jcmp_deeply(
      $jres->as_pairs,
      [ [ "foo", {a=>1} ] ],
      "JMAP response from Object-wrapped JSON",
    );
  }
};

subtest "with optional typist" => sub {
  my $new_hres = sub {
    return HTTP::Response->new(
      200,
      "OK",
      [ 'Content-Type', 'application/json' ],
      q<{"methodResponses": [["foo", {"a":1}, "c"]] }>,
    );
  };

  {
    my $tester = JMAP::Tester->new;
    my $jres = $tester->_jresponse_from_hresponse($new_hres->());
    ok(
      $jres->as_pairs->[0][1]{a}->isa('JSON::Typist::Number'),
      'default to using a typist'
    );
  }

  {
    my $tester = JMAP::Tester->new(use_json_typist => 0);
    my $jres = $tester->_jresponse_from_hresponse($new_hres->());

    # cmp_deeply doesn't see through types, so we can use it to assert we
    # don't have them.
    cmp_deeply(
      $jres->as_pairs,
      [ [ "foo", {a=>1} ] ],
      'with false use_json_typist, we do not'
    );
  }
};

subtest "test accessors on Sentence::Set" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [
        'Widget/set' => {
          oldState => jstr('state-1'),
          newState => jstr('state-2'),
          created  => {
            cr0 => { id => 'x100', size => jnum(42) },
            cr1 => { id => 'x101', size => jnum(13) },
          },
          updated    => { 'x200' => undef, 'x201' => { color => 'red' } },
          destroyed  => [ 'x300', 'x301' ],
          notCreated   => {
            cr2 => { type => jstr('invalidProperties') },
          },
          notUpdated   => {
            x202 => { type => jstr('notFound') },
          },
          notDestroyed => {
            x302 => { type => jstr('notFound') },
          },
        },
        'a',
      ],
    ],
  });

  my $s = $res->single_sentence('Widget/set')->as_set;

  is($s->old_state, 'state-1', "old_state");
  is($s->new_state, 'state-2', "new_state");

  is($s->as_set, $s, "as_set on a Set is identity");

  jcmp_deeply(
    $s->created,
    { cr0 => superhashof({}), cr1 => superhashof({}) },
    "created gets us back the created hashref",
  );

  is($s->created_id('cr0'), 'x100', "created_id cr-0");
  is($s->created_id('cr1'), 'x101', "created_id cr-1");
  is($s->created_id('cr-nope'), undef, "created_id for unknown");

  jcmp_deeply(
    [ $s->created_creation_ids ],
    bag(qw( cr0 cr1 )),
    "created_creation_ids"
  );

  jcmp_deeply([ $s->created_ids ],   bag(qw(x100 x101)), "created_ids");
  jcmp_deeply([ $s->updated_ids ],   bag(qw(x200 x201)), "updated_ids");
  jcmp_deeply([ $s->destroyed_ids ], bag(qw(x300 x301)), "destroyed_ids");

  jcmp_deeply([ $s->not_created_ids ],   bag('cr2' ), "not_created_ids");
  jcmp_deeply([ $s->not_updated_ids ],   bag('x202'), "not_updated_ids");
  jcmp_deeply([ $s->not_destroyed_ids ], bag('x302'), "not_destroyed_ids");

  jcmp_deeply(
    $s->create_errors,
    { cr2 => { type => jstr('invalidProperties') } },
    "create_errors",
  );

  jcmp_deeply(
    $s->update_errors,
    { x202 => { type => jstr('notFound') } },
    "update_errors",
  );

  jcmp_deeply(
    $s->destroy_errors,
    { x302 => { type => jstr('notFound') } },
    "destroy_errors",
  );
};

subtest "test accessors on Sentence::Set with omitted arguments" => sub {
  # When the set response has none of the standard fields at all, we should
  # still be okay. -- claude, 2025-02-08
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ 'Thing/set' => { newState => 'state-3' }, 'a' ],
    ],
  });

  my $s = $res->single_sentence('Thing/set')->as_set;

  jcmp_deeply($s->created,        {}, "created defaults to {}");
  jcmp_deeply($s->create_errors,  {}, "create_errors defaults to {}");
  jcmp_deeply($s->update_errors,  {}, "update_errors defaults to {}");
  jcmp_deeply($s->destroy_errors, {}, "destroy_errors defaults to {}");

  is($s->created_id('anything'), undef, "created_id with bogus input yields undef");
  jcmp_deeply([ $s->created_creation_ids ], [], "no created_creation_ids");
  jcmp_deeply([ $s->created_ids ], [], "no created_ids");

  is($s->assert_no_errors, $s, "returns self with no error fields at all");
};

subtest "assert_no_errors" => sub {
  my $res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ 'Widget/set' => {
          created   => { cr0 => { id => 'x100' } },
          updated   => { x200 => undef },
          destroyed => [ 'x300' ],
        }, 'a' ],
    ],
  });

  my $s = $res->single_sentence('Widget/set')->as_set;
  is($s->assert_no_errors, $s, "returns self when clean");
};

subtest "assert_successful and friends" => sub {
  my $ok_res = JMAP::Tester::Response->new({
    diagnostic_dumper => $DUMPER,
    items => [
      [ 'Widget/set' => {
          created   => { cr0 => { id => 'x1' } },
          updated   => {},
          destroyed => [],
        }, 'a' ],
    ],
  });

  is($ok_res->assert_successful, $ok_res, "assert_successful on success");

  {
    my $s = $ok_res->assert_successful_set('Widget/set');
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  {
    my $s = $ok_res->assert_single_successful_set('Widget/set');
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  {
    my $s = $ok_res->assert_single_successful_set;
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  # Now for the failure cases.
  {
    my $fail = JMAP::Tester::Result::Failure->new({
      diagnostic_dumper => $DUMPER,
      http_response => HTTP::Response->new(500, "Internal Server Error"),
    });

    ok(! $fail->is_success, "failure is not success");

    my $err = exception { $fail->assert_successful };
    isa_ok($err, 'JMAP::Tester::Abort', "assert_successful's throw");
    like($err->message, qr/JMAP failure/, "default message for ident-less failure");
  }

  {
    my $fail = JMAP::Tester::Result::Failure->new({
      diagnostic_dumper => $DUMPER,
      ident         => "custom error ident",
      http_response => HTTP::Response->new(500, "Internal Server Error"),
    });

    ok($fail->has_ident, "failure has_ident");
    is($fail->ident, "custom error ident", "ident value");

    my $err = exception { $fail->assert_successful };
    isa_ok($err, 'JMAP::Tester::Abort', "assert_successful's throw");
    like($err->message, qr/custom error ident/, "abort message uses ident");
  }
};

subtest "response_payload" => sub {
  {
    my $fail = JMAP::Tester::Result::Failure->new({
      diagnostic_dumper => $DUMPER,
      http_response => HTTP::Response->new(
        500, "Oops",
        [ 'Content-Type' => 'text/plain' ],
        "something went wrong",
      ),
    });

    like(
      $fail->response_payload,
      qr/something went wrong/,
      "response_payload includes body"
    );
  }

  {
    my $fail = JMAP::Tester::Result::Failure->new({
      diagnostic_dumper => $DUMPER,
    });
    is($fail->response_payload, '', "no http_response means empty payload");
  }
};

subtest "Response methods on a Failure abort" => sub {
  my $dumper = sub { "<<" . ref($_[0]) . ">>" };

  my $aborts_with_dump = sub {
    my ($method) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $fail = JMAP::Tester::Result::Failure->new({
      diagnostic_dumper => $dumper,
      http_response => HTTP::Response->new(500, "Internal Server Error"),
    });

    my $err = exception { $fail->$method };

    isa_ok($err, 'JMAP::Tester::Abort', "->$method on a Failure aborts")
      or return;

    is(
      $err->message,
      "tried to call Response method $method on a Failure",
      "...with a message naming $method",
    );

    cmp_deeply(
      $err->diagnostics,
      [ "Result: <<JMAP::Tester::Result::Failure>>\n" ],
      "...and a diagnostic dump of the Failure",
    );
  };

  $aborts_with_dump->($_) for qw(
    sentence
    sentences
    single_sentence
    sentence_named
    assert_n_sentences
    paragraph
    paragraphs
    assert_n_paragraphs
    paragraph_by_client_id
    as_triples
    as_stripped_triples
    as_pairs
    as_stripped_pairs

    wrapper_properties
  );
};


sub aborts_ok {
  my ($code, $want, $desc);
  if (@_ == 2) {
    ($code, $desc) = @_;
  } elsif (@_ == 3) {
    ($code, $want, $desc) = @_;
  } else {
    Carp::confess("aborts_ok used wrongly");
  }

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = eval { $code->(); 1 };
  my $error = $@;

  if ($ok) {
    fail("code ran without exception: $desc");
    return;
  }

  unless (blessed $error && $error->isa('JMAP::Tester::Abort')) {
    fail("code threw non-abort: $desc");
    diag("error thrown: $error");
    return;
  }

  unless ($want) {
    pass("got an abort: $desc");
    return;
  }

  cmp_deeply(
    $error,
    $want,
    "got expected abort: $desc",
  );
}

done_testing;
