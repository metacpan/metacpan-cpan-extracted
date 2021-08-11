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

subtest "the basic basics" => sub {
  my $res = JMAP::Tester::Response->new({
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
        items => [
          [ atePies => { howMany => jnum(100), tastiestPieId => jstr(123) }, 'a' ],
        ],
      });

      my $s = $res->single_sentence('piesEt');
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

subtest "calling as_set on non-set sentence" => sub {
  my $res = JMAP::Tester::Response->new({
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

subtest "miscellaneous error conditions" => sub {
  my $res_1 = JMAP::Tester::Response->new({
    items => [
      [ welcome => { all => jstr('refugees') }, jstr('xyzzy') ],
    ],
  });

  my $res_2 = JMAP::Tester::Response->new({
    items => [
      [ welcome => { all  => jstr('refugees') }, jstr('xyzzy') ],
      [ goodBye => { blue => jstr('skye') }, jstr('a') ],
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
    my $ok = eval {
      $res_2->paragraph_by_client_id('xyzzy')->single('welcome');
      $res_2->paragraph_by_client_id('a')->single('goodBye');
      1;
    };

    my $error = $@;
    ok($ok, "paragraph_by_client_id") or diag $error;
  }

  my $res_3 = JMAP::Tester::Response->new({
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
