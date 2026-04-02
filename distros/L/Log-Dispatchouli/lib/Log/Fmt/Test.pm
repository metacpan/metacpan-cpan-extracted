package Log::Fmt::Test 3.100;

use v5.22.0; # lexical subs too buggy before this
use warnings;

use experimental qw(lexical_subs postderef signatures);
use utf8;

use JSON::MaybeXS;
use Log::Dispatchouli;
use Test::More 0.88;
use Test::Deep;

my sub messages_ok {
  my ($logger, $lines, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level+1;

  my @messages = map {; $_->{message} } $logger->events->@*;

  my $ok = cmp_deeply(
    \@messages,
    $lines,
    $desc,
  );

  $logger->clear_events;

  unless ($ok) {
    diag "GOT: $_" for @messages;
  }

  return $ok;
}

my sub event_logs_ok {
  my ($event_type, $data, $line, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level+1;

  my $logger = Log::Dispatchouli::LogFmtTester->new_tester({
    log_pid => 0,
    ident   => 't/basic.t',
  });

  $logger->log_event($event_type, $data);

  messages_ok($logger, [$line], $desc);
}

my sub parse_event_ok {
  my ($event_string, $expect, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level+1;

  my $result = Log::Fmt->parse_event_string($event_string);

  cmp_deeply(
    $result,
    $expect,
    $desc,
  ) or note explain $result;
}

sub logger_trio {
  my $logger = Log::Dispatchouli::LogFmtTester->new_tester({
    log_pid => 0,
    ident   => 't/basic.t',
  });

  my $proxy1 = $logger->proxy({ proxy_ctx => { 'outer' => 'proxy' } });
  my $proxy2 = $proxy1->proxy({ proxy_ctx => { 'inner' => 'proxy' } });

  return ($logger, $proxy1, $proxy2);
}

sub test_logfmt_implementation ($self, $logfmt_package) {
  local $Log::Dispatchouli::LogFmtTester::LOG_FMT_PACKAGE = $logfmt_package;

  subtest "testing logfmt implementation $logfmt_package" => sub {
    subtest "very basic stuff" => sub {
      event_logs_ok(
        'world-series' => [ phl => 1, hou => 0, games => [ 'done', 'in-progress' ] ],
        'event=world-series phl=1 hou=0 games.0=done games.1=in-progress',
        "basic data with an arrayref value",
      );

      parse_event_ok(
        'event=world-series phl=1 hou=0 games.0=done games.1=in-progress',
        [
          event => 'world-series',
          phl => 1,
          hou => 0,
          'games.0' => 'done',
          'games.1' => 'in-progress',
        ],
        'we can parse something we produced'
      );

      event_logs_ok(
        'programmer-sleepiness' => {
          weary   => 8.62,
          excited => 3.2,
          motto   => q{Never say "never" ever again.},
        },
        'event=programmer-sleepiness excited=3.2 motto="Never say \\"never\\" ever again." weary=8.62',
        "basic data as a hashref",
      );

      {
        my %kv = (
          weary   => 8.62,
          excited => 3.2,
          motto   => q{Never say "never" ever again.},
        );

        my $line = $logfmt_package->format_event_string([%kv]);

        cmp_deeply(
          $logfmt_package->parse_event_string_as_hash($line),
          \%kv,
          "parse_event_string_as_hash works",
        );
      }

      parse_event_ok(
        'event=programmer-sleepiness excited=3.2 motto="Never say \\"never\\" ever again." weary=8.62',
        [
          event   => 'programmer-sleepiness',
          excited => '3.2',
          motto   => q{Never say "never" ever again.},
          weary   => '8.62',
        ],
        "parse an event with simple quotes",
      );

      event_logs_ok(
        'rich-structure' => [
          array => [
            { name => [ qw(Ricardo Signes) ], limbs => { arms => 2, legs => 2 } },
            [ 2, 4, 6 ],
          ],
        ],
        join(q{ }, qw(
          event=rich-structure
          array.0.limbs.arms=2
          array.0.limbs.legs=2
          array.0.name.0=Ricardo
          array.0.name.1=Signes
          array.1.0=2
          array.1.1=4
          array.1.2=6
        )),
        "a structured nested a few levels",
      );

      event_logs_ok(
        'empty-key' => { '' => 'disgusting' },
        'event=empty-key ~=disgusting',
        "cope with jerks putting empty keys into the data structure",
      );

      event_logs_ok(
        'bogus-subkey' => { valid => { 'foo bar' => 'revolting' } },
        'event=bogus-subkey valid.foo?bar=revolting',
        "cope with bogus key characters in recursion",
      );

      event_logs_ok(
        'has-tab' => { tabby => "\tx = 1;" },
        'event=has-tab tabby="\\tx = 1;"',
        "tabs become \\t",
      );

      parse_event_ok(
        'event=has-tab tabby="\\tx = 1;"',
        [ event => 'has-tab', tabby => "\tx = 1;" ],
        "\\t becomes a tab",
      );

      event_logs_ok(
        'has-eq' => { equals => "0=1" },
        'event=has-eq equals="0=1"',
        "including an = gets you quoted",
      );

      parse_event_ok(
        'event=has-eq equals="0=1"',
        [ event => 'has-eq', equals => "0=1" ],
        "= in input is fine",
      );

      event_logs_ok(
        'has-backslash' => { revsol => "foo\\bar" },
        'event=has-backslash revsol="foo\\\\bar"',
        "including a \\ gets you quoted",
      );

      event_logs_ok(
        'key-has-backslash' => { 'a\\b' => "foo" },
        'event=key-has-backslash a?b=foo',
        "backslash in a key becomes question mark",
      );

      parse_event_ok(
        'event=has-backslash revsol="foo\\\\bar"',
        [ event => 'has-backslash', revsol => "foo\\bar" ],
        "\\ in input is fine",
      );

      event_logs_ok(
        # Note that the ë at the end becomes UTF-8 encoded into octets.
        ctrlctl => [ string => qq{NL \x0a CR \x0d "Q" ZWJ \x{200D} \\nothing ë}, ],
        'event=ctrlctl string="NL \\n CR \\r \\"Q\\" ZWJ \\x{e2}\\x{80}\\x{8d} \\\\nothing ' . "\xc3\xab" . '"',
        'control characters and otherwise',
      );

      parse_event_ok(
        'event=ctrlctl string="NL \\n CR \\r \\"Q\\" ZWJ \\x{e2}\\x{80}\\x{8d} \\\\nothing ' . "\xc3\xab" . '"',
        [
          event   => 'ctrlctl',
          string  => qq{NL \x0a CR \x0d "Q" ZWJ \x{200D} \\nothing ë},
        ],
        "parse an event with simple quotes",
      );

      event_logs_ok(
        spacey => [ string => qq{line \x{2028} spacer} ],
        'event=spacey string="line \x{e2}\x{80}\x{a8} spacer"',
        'non-control non-ascii vertical whitespace is also escaped',
      );

      parse_event_ok(
        'event=spacey string="line \x{e2}\x{80}\x{a8} spacer"',
        [
          event   => 'spacey',
          string  => qq{line \x{2028} spacer}
        ],
        "parse an that has an escaped vertical whitespace cahracter",
      );
    };

    subtest "parsing junk input" => sub {
      parse_event_ok(
        'junkword',
        [ junk => 'junkword' ],
        "bare word with no = becomes junk",
      );

      parse_event_ok(
        'foo=bar bareword foo=baz',
        [ foo => 'bar', junk => 'bareword', foo => 'baz' ],
        "junk among valid pairs is captured with key 'junk'",
      );

      parse_event_ok(
        'key=',
        [ junk => 'key=' ],
        "key= with no value is junk",
      );

      parse_event_ok(
        'key="unclosed',
        [ junk => 'key="unclosed' ],
        "unclosed quoted string is junk",
      );
    };

    subtest "parsing empty quoted value" => sub {
      parse_event_ok(
        'key=""',
        [ key => '' ],
        "empty quoted string parses to empty string",
      );
    };

    subtest "very basic proxy operation" => sub {
      my ($logger, $proxy1, $proxy2) = logger_trio();

      $proxy2->log_event(pie_picnic => [
        pies_eaten => 1.2,
        joy_harvested => 6,
      ]);

      messages_ok(
        $logger,
        [
          'event=pie_picnic outer=proxy inner=proxy pies_eaten=1.2 joy_harvested=6'
        ],
        'got the expected log output from events',
      );
    };

    subtest "debugging in the proxies" => sub {
      my ($logger, $proxy1, $proxy2) = logger_trio();

      $proxy1->set_debug(1);

      $logger->log_debug_event(0 => [ seq => 0 ]);
      $proxy1->log_debug_event(1 => [ seq => 1 ]);
      $proxy2->log_debug_event(2 => [ seq => 2 ]);

      $proxy2->set_debug(0);

      $logger->log_debug_event(0 => [ seq => 3 ]);
      $proxy1->log_debug_event(1 => [ seq => 4 ]);
      $proxy2->log_debug_event(2 => [ seq => 5 ]);

      messages_ok(
        $logger,
        [
          # 'event=0 seq=0',                          # not logged, debugging
          'event=1 outer=proxy seq=1',
          'event=2 outer=proxy inner=proxy seq=2',
          # 'event=0 seq=3',                          # not logged, debugging
          'event=1 outer=proxy seq=4',
          # 'event=2 outer=proxy inner=proxy seq=5',  # not logged, debugging
        ],
        'got the expected log output from events',
      );
    };

    # NOT TESTED HERE:  "mute" and "unmute", which rjbs believes are probably
    # broken already.  Their tests don't appear to test the important case of "root
    # logger muted, proxy explicitly unmuted".

    subtest "recursive structure" => sub {
      my ($logger, $proxy1, $proxy2) = logger_trio();

      my $struct = {};

      $struct->{recurse} = $struct;

      $logger->log_event('recursive-thing' => [ recursive => $struct ]);

      messages_ok(
        $logger,
        [
          'event=recursive-thing recursive.recurse=&recursive',
        ],
        "an event with recursive stuff terminates",
      );
    };

    subtest "lazy values" => sub {
      my ($logger) = logger_trio();

      my $called = 0;
      my $callback = sub { $called++; return 'X' };

      $logger->log_event('sub-caller' => [
        once  => $callback,
        twice => $callback,
      ]);

      $logger->log_debug_event('sub-caller' => [
        d_once  => $callback,
        d_twice => $callback,
      ]);

      messages_ok(
        $logger,
        [
          'event=sub-caller once=X twice=X',
        ],
        "we call sublike arguments to lazily compute",
      );

      is($called, 2, "only called twice; debug events did not call sub");
    };

    subtest "lazy values in proxy context" => sub {
      my ($logger) = logger_trio();

      my $called_A = 0;
      my $callback_A = sub { $called_A++; return 'X' };

      my $called_B = 0;
      my $callback_B = sub { $called_B++; return 'X' };

      my $proxy1 = $logger->proxy({ proxy_ctx => [ outer => $callback_A ] });
      my $proxy2 = $proxy1->proxy({ proxy_ctx => [ inner => $callback_B ] });

      $proxy1->log_event('outer-event' => [ guitar => 'electric' ]);

      is($called_A, 1, "outer proxy did log, called outer callback");
      is($called_B, 0, "outer proxy did log, didn't call inner callback");

      $proxy2->log_event('inner-event' => [ mandolin => 'bluegrass' ]);

      is($called_A, 1, "inner proxy did log, didn't re-call outer callback");
      is($called_B, 1, "inner proxy did log, did call inner callback");

      $proxy2->log_event('inner-second' => [ snare => 'infinite' ]);

      messages_ok(
        $logger,
        [
          'event=outer-event outer=X guitar=electric',
          'event=inner-event outer=X inner=X mandolin=bluegrass',
          'event=inner-second outer=X inner=X snare=infinite',
        ],
        "all our laziness didn't change our results",
      );
    };

    subtest "reused JSON booleans" => sub {
      # It's not that this is extremely special, but we mostly don't want to
      # recurse into the same reference value multiple times, but we also don't
      # want the infuriating "reused boolean variable" you get from Dumper.  This
      # is just to make sure I don't accidentally break this case.
      my ($logger, $proxy1, $proxy2) = logger_trio();

      my $struct = {
        b => [ JSON::MaybeXS::true(), JSON::MaybeXS::false() ],
        f => [ (JSON::MaybeXS::false()) x 3 ],
        t => [ (JSON::MaybeXS::true())  x 3 ],
      };

      $logger->log_event('tf-thing' => [ cond => $struct ]);

      messages_ok(
        $logger,
        [
          'event=tf-thing cond.b.0=1 cond.b.1=0 cond.f.0=0 cond.f.1=0 cond.f.2=0 cond.t.0=1 cond.t.1=1 cond.t.2=1',
        ],
        "JSON bools do what we expect",
      );
    };

    subtest "JSON-ification of refrefs" => sub {
      my ($logger, $proxy1, $proxy2) = logger_trio();

      $logger->log_event('json-demo' => [
        foo =>  { a => 1 },
        bar => \{ a => 1 },
        baz => \[ 12, 34 ],
      ]);

      my @messages = map {; $_->{message} } $logger->events->@*;

      messages_ok(
        $logger,
        [
          # XS and PP versions of JSON differ on space, so we need "12, 34" and
          # "12,34" both.  Then things get weird, because the version with no
          # spaces (pure perl, at least as of today) doesn't need to be quoted to
          # be used as a logfmt value, so the quotes are now optional.  Wild.
          # -- rjbs, 2023-09-02
          any(
            'event=json-demo foo.a=1 bar="{{{\"a\": 1}}}" baz="{{[12, 34]}}"',
            'event=json-demo foo.a=1 bar="{{{\"a\": 1}}}" baz={{[12,34]}}',
          ),
        ],
        "refref becomes JSON flogged",
      );

      my $result = $logfmt_package->parse_event_string($messages[0]);

      cmp_deeply(
        $result,
        [
          event   => 'json-demo',
          'foo.a' => 1,
          bar     => "{{{\"a\": 1}}}",
          baz     => any("{{[12, 34]}}", "{{[12,34]}}"),
        ],
        "parsing gets us JSON string out, because it is just strings",
      );

      my ($json_string) = $result->[5] =~ /\A\{\{(.+)\}\}\z/;
      my $json_struct = decode_json($json_string);

      cmp_deeply(
        $json_struct,
        { a => 1 },
        "we can round trip that JSON",
      );
    };

    my sub kvstrs_ok {
      my ($pairs, $expected, $desc) = @_;
      local $Test::Builder::Level = $Test::Builder::Level + 1;

      my $got = $logfmt_package->_pairs_to_kvstr_aref($pairs);
      cmp_deeply($got, $expected, $desc) or diag explain $got;
    }

    subtest "simple key=value pairs" => sub {
      kvstrs_ok(
        [ foo => 'bar' ],
        [ 'foo=bar' ],
        "simple bare value",
      );

      kvstrs_ok(
        [ foo => 'bar', baz => 'quux' ],
        [ 'foo=bar', 'baz=quux' ],
        "multiple simple pairs",
      );

      kvstrs_ok(
        [ phl => 1, hou => 0 ],
        [ 'phl=1', 'hou=0' ],
        "numeric values",
      );
    };

    subtest "values needing quoting" => sub {
      kvstrs_ok(
        [ msg => 'hello world' ],
        [ 'msg="hello world"' ],
        "value with space gets quoted",
      );

      kvstrs_ok(
        [ eq => '0=1' ],
        [ 'eq="0=1"' ],
        "value with = gets quoted",
      );

      kvstrs_ok(
        [ q => 'say "hi"' ],
        [ 'q="say \\"hi\\""' ],
        "value with double quotes gets escaped",
      );

      kvstrs_ok(
        [ bs => 'foo\\bar' ],
        [ 'bs="foo\\\\bar"' ],
        "value with backslash gets escaped",
      );

      kvstrs_ok(
        [ tabby => "\tx = 1;" ],
        [ 'tabby="\\tx = 1;"' ],
        "tab becomes \\t",
      );

      kvstrs_ok(
        [ nl => "line1\nline2" ],
        [ 'nl="line1\\nline2"' ],
        "newline becomes \\n",
      );

      kvstrs_ok(
        [ cr => "a\rb" ],
        [ 'cr="a\\rb"' ],
        "carriage return becomes \\r",
      );
    };

    subtest "empty and invalid keys" => sub {
      kvstrs_ok(
        [ '' => 'val' ],
        [ '~=val' ],
        "empty key becomes ~",
      );

      kvstrs_ok(
        [ 'foo bar' => 'val' ],
        [ 'foo?bar=val' ],
        "space in key becomes ?",
      );

      kvstrs_ok(
        [ 'a=b' => 'val' ],
        [ 'a?b=val' ],
        "= in key becomes ?",
      );

      kvstrs_ok(
        [ 'a"b' => 'val' ],
        [ 'a?b=val' ],
        "double quote in key becomes ?",
      );

      kvstrs_ok(
        [ "a\\b" => 'val' ],
        [ 'a?b=val' ],
        "backslash in key becomes ?",
      );
    };

    subtest "undef values" => sub {
      kvstrs_ok(
        [ key => undef ],
        [ 'key=~missing~' ],
        "undef value becomes ~missing~",
      );
    };

    subtest "nested arrayrefs" => sub {
      kvstrs_ok(
        [ games => [ 'done', 'in-progress' ] ],
        [ 'games.0=done', 'games.1=in-progress' ],
        "arrayref values get flattened with numeric indices",
      );

      kvstrs_ok(
        [ arr => [ 'a', 'b', 'c' ] ],
        [ 'arr.0=a', 'arr.1=b', 'arr.2=c' ],
        "three-element array",
      );
    };

    subtest "nested hashrefs" => sub {
      kvstrs_ok(
        [ data => { alpha => 1, beta => 2 } ],
        [ 'data.alpha=1', 'data.beta=2' ],
        "hashref values get flattened with sorted keys",
      );
    };

    subtest "deeply nested structures" => sub {
      kvstrs_ok(
        [
          array => [
            { name => [ 'Ricardo', 'Signes' ], limbs => { arms => 2, legs => 2 } },
            [ 2, 4, 6 ],
          ],
        ],
        [
          'array.0.limbs.arms=2',
          'array.0.limbs.legs=2',
          'array.0.name.0=Ricardo',
          'array.0.name.1=Signes',
          'array.1.0=2',
          'array.1.1=4',
          'array.1.2=6',
        ],
        "deeply nested array/hash structure",
      );
    };

    subtest "recursive structures" => sub {
      my $struct = {};
      $struct->{recurse} = $struct;

      kvstrs_ok(
        [ recursive => $struct ],
        [ 'recursive.recurse=&recursive' ],
        "recursive hashref produces backreference",
      );
    };

    subtest "coderef (lazy) values" => sub {
      my $called = 0;
      my $cb = sub { $called++; return 'lazy_val' };

      kvstrs_ok(
        [ key => $cb ],
        [ 'key=lazy_val' ],
        "coderef is called to produce value",
      );

      is($called, 1, "coderef called exactly once");
    };

    subtest "ref-to-ref (String::Flogger)" => sub {
      kvstrs_ok(
        [ bar => \{ a => 1 } ],
        [ re(qr/^bar=/) ],
        "refref produces flogged output",
      );
    };

    subtest "UTF-8 values" => sub {
      # ë (U+00EB) is a safe non-ASCII character — should appear as UTF-8 bytes
      # in the output without \x{} escaping
      kvstrs_ok(
        [ name => "Jürgen" ],
        [ "name=\"J\xc3\xbcrgen\"" ],
        "safe non-ASCII chars (ü) are UTF-8 encoded directly",
      );
    };

    subtest "control characters and special escapes" => sub {
      # ZWJ (U+200D) is a Cf character — gets \x{} escaped
      kvstrs_ok(
        [ string => "NL \x0a CR \x0d \"Q\" ZWJ \x{200D} \\nothing \x{00EB}" ],
        [ 'string="NL \\n CR \\r \\"Q\\" ZWJ \\x{e2}\\x{80}\\x{8d} \\\\nothing ' . "\xc3\xab" . '"' ],
        "control chars, ZWJ, quotes, backslash, and ë all handled correctly",
      );
    };

    subtest "vertical whitespace" => sub {
      # LINE SEPARATOR (U+2028) should be escaped to its UTF-8 bytes
      kvstrs_ok(
        [ string => "line \x{2028} spacer" ],
        [ "string=\"line \\x{e2}\\x{80}\\x{a8} spacer\"" ],
        "LINE SEPARATOR is escaped via UTF-8 byte \x{} sequences",
      );
    };

    subtest "empty value" => sub {
      kvstrs_ok(
        [ key => '' ],
        [ 'key=""' ],
        "empty string gets quoted",
      );
    };

    subtest "bogus subkey characters" => sub {
      kvstrs_ok(
        [ valid => { 'foo bar' => 'revolting' } ],
        [ 'valid.foo?bar=revolting' ],
        "bogus key chars in recursion become ?",
      );
    };

    subtest "prefix handling" => sub {
      # Test with explicit prefix argument
      my $got = Log::Fmt->_pairs_to_kvstr_aref(
        [ alpha => 1, beta => 2 ],
        {},
        'pfx',
      );
      cmp_deeply(
        $got,
        [ 'pfx.alpha=1', 'pfx.beta=2' ],
        "explicit prefix prepended to keys",
      );
    };

    subtest "match full format_event_string output" => sub {
      # Verify XS output matches what format_event_string produces
      my @test_cases = (
        {
          input => [ phl => 1, hou => 0, games => [ 'done', 'in-progress' ] ],
          expected => 'phl=1 hou=0 games.0=done games.1=in-progress',
          desc => 'basic data with arrayref',
        },
        {
          input => [ tabby => "\tx = 1;" ],
          expected => 'tabby="\\tx = 1;"',
          desc => 'tab escape',
        },
        {
          input => [ equals => "0=1" ],
          expected => 'equals="0=1"',
          desc => 'equals sign quoted',
        },
        {
          input => [ revsol => "foo\\bar" ],
          expected => 'revsol="foo\\\\bar"',
          desc => 'backslash quoted',
        },
      );

      for my $tc (@test_cases) {
        my $got = $logfmt_package->format_event_string($tc->{input});
        is($got, $tc->{expected}, "format_event_string: $tc->{desc}");
      }
    };
  }
}

package Log::Dispatchouli::LogFmtTester 3.100 {
  use parent 'Log::Dispatchouli';
  our $LOG_FMT_PACKAGE;
  sub _log_fmt_package { $LOG_FMT_PACKAGE // die "no package supplied" }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Fmt::Test

=head1 VERSION

version 3.100

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
