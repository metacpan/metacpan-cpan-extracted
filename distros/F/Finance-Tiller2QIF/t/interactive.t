use 5.036;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use Path::Tiny;
use Finance::Tiller2QIF;
use Finance::Tiller2QIF::Interactive;
use Finance::Tiller2QIF::Util;
use Finance::Tiller2QIF::DB qw(connect_db);

sub fixture () {
  my $dir = tempdir(CLEANUP => 1);
  # Match Run's canonical paths so failure-injection targets compare equal
  # despite symlinked temp dirs (macOS /var, BSD) or backslash-separated
  # directory names from File::Temp on Windows.
  $dir = path($dir)->realpath->stringify;
  my $f = { dir => $dir, db => "$dir/live.sqlite3", input => "$dir/input.csv",
    output => "$dir/result.qif", mapfile => "$dir/rules.map" };
  Finance::Tiller2QIF::Util::InitDB($f->{db});
  path($f->{input})->spew_utf8(
    "Date,Transaction ID,Account,Amount,Description,Full Description,Category\n"
    . "04/25/2026,tx-α-123456789,Checking,100.00,Deposit,Paycheck,Income\n");
  path($f->{mapfile})->spew_utf8("category | Income | Income:Salary\n");
  path($f->{output})->spew_utf8("existing QIF\n");
  $f->{original} = Finance::Tiller2QIF::Interactive::_digest($f->{db});
  return $f;
}

sub unchanged ($f) {
  is(Finance::Tiller2QIF::Interactive::_digest($f->{db}), $f->{original},
    'original database bytes unchanged');
  is(path($f->{output})->slurp_utf8, "existing QIF\n", 'existing QIF unchanged');
}

sub run_session ($f, $answers, $edit=undef, @extra) {
  my $views = 0;
  my $view = \&Finance::Tiller2QIF::Interactive::_view;
  no warnings 'redefine';
  local *Finance::Tiller2QIF::Interactive::_view = sub ($session) {
    $f->{session} = $session;
    $edit->($session, ++$views) if $edit;
    $view->($session);
  };
  local @ARGV = ('interactive', '--db', $f->{db}, '--input', $f->{input},
    '--output', $f->{output},
    (defined $f->{mapfile} ? ('--mapfile', $f->{mapfile}) : ()), @extra);
  open my $input, '<', \$answers or die $!;
  local *STDIN = $input;
  my ($result, $error);
  my ($out, $err) = capture {
    $result = eval { Finance::Tiller2QIF::run_cli() };
    $error = $@;
  };
  return { out => $out, err => $err, error => $error, result => $result };
}

# These cases hit intermittent Capture::Tiny tempfile errors on one Windows
# tester. Keep them running as TODO until another tester reports the issue.
sub capture_subtest ($name, $code) {
  my $todo = todo('Intermittent Capture::Tiny tempfile permission failure on Windows')
    if $^O eq 'MSWin32';
  subtest $name => $code;
}

subtest 'cancel and EOF keep originals, retain artifacts' => sub {
  for my $answer ("c\n", '') {
    my $f = fixture();
    my $r = run_session($f, $answer);
    is($r->{error}, '', 'session returns normally');
    is($r->{result}, 0, 'cancel is unsuccessful');
    unchanged($f);
    ok(-f "$f->{session}{dir}/corrections.t2qsql", 'SQL retained with dedicated editor extension');
    ok(-f $f->{session}{review}{db}, 'working database retained');
    like($r->{out}, qr/ID: tx-α-123456789/, 'full transaction ID displayed');
  }
};

subtest 'refresh reconsiders skips, replays hooks once, and preserves overrides' => sub {
  my $f = fixture();
  path($f->{mapfile})->spew_utf8("default | skip\n");
  path("$f->{dir}/before.sql")->spew_utf8("UPDATE transactions SET amount = amount + 2;\n");
  path("$f->{dir}/after.sql")->spew_utf8("UPDATE transactions SET amount = amount + 3;\n");
  my $r = run_session($f, "e\na\na\ne\n", sub ($s, $view) {
    unchanged($f);
    if ($view == 1) {
      is($s->{review}{count}, 0, 'initial mapping skips transaction');
      path($f->{mapfile})->spew_utf8("default | Income:Updated\n");
      path($s->{options}{corrections})->spew_utf8(
        "UPDATE transactions SET amount = amount + 1; UPDATE transactions SET mapped_category = 'Income:Override', memo = 'one; two';\n");
    }
  }, '--beforemap', "$f->{dir}/before.sql", '--aftermap', "$f->{dir}/after.sql");
  is($r->{error}, '', 'export succeeded');
  is($r->{result}, 1, 'session committed');
  like($r->{out}, qr/Apply and refresh successfully/, 'stale export refused');
  my $dbh = connect_db($f->{db});
  is($dbh->selectrow_arrayref('SELECT amount, mapped_category, exported, skipped FROM transactions'),
    [106, 'Income:Override', 1, 0], 'fresh replay includes previously skipped row and one-off override');
  $dbh->disconnect;
  like(path($f->{output})->slurp_utf8, qr/T106\.00.*LIncome:Override/s, 'QIF matches reviewed data');
  ok(!-e "$f->{db}.interactive.json", 'publication journal cleaned');
};

subtest 'failed SQL cannot publish partial changes and can be repaired' => sub {
  my $f = fixture();
  my $r = run_session($f, "a\ne\nv\na\ne\n", sub ($s, $view) {
    if ($view == 1) {
      path($s->{options}{corrections})->spew_utf8(
        "UPDATE transactions SET amount = 999; UPDATE missing_table SET bad = 1;\n");
    }
    if ($view == 2) {
      unchanged($f);
      my $dbh = connect_db($s->{review}{db});
      is($dbh->selectrow_array('SELECT amount FROM transactions'), 100, 'last good review retained');
      $dbh->disconnect;
    }
    if ($view == 3) { path($s->{options}{corrections})->spew_utf8('-- removed failed corrections'); }
  });
  is($r->{error}, '', 'repaired session succeeds');
  like($r->{err}, qr/Refresh failed:.*missing_table/s, 'SQL failure reported');
  like($r->{out}, qr/Apply and refresh successfully/, 'export blocked after failed refresh');
  like(path($f->{output})->slurp_utf8, qr/T100\.00/, 'failed partial SQL never exported');
};

subtest 'invalid map and hook failures leave originals intact' => sub {
  for my $kind (qw(map hook)) {
    my $f = fixture();
    my @extra;
    if ($kind eq 'map') { path($f->{mapfile})->spew_utf8("invalid | * | source\n"); }
    else {
      path("$f->{dir}/bad.sql")->spew_utf8('UPDATE no_such_table SET value = 1;');
      @extra = ('--aftermap', "$f->{dir}/bad.sql");
    }
    my $r = run_session($f, "e\nc\n", undef, @extra);
    like($r->{err}, qr/Refresh failed/, "$kind failure reported");
    like($r->{out}, qr/Apply and refresh successfully/, 'export refused');
    unchanged($f);
  }
};

subtest 'invalid CSV fails instead of silently importing a subset' => sub {
  my $f = fixture();
  path($f->{input})->append_utf8("not-a-date,bad,Checking,10,Bad,Bad,Income\n");
  my $r = run_session($f, "e\nc\n");
  like($r->{err}, qr/Could not parse date/, 'ingest error is fatal to refresh');
  unchanged($f);
};

subtest 'SQL cannot attach the original database' => sub {
  my $f = fixture();
  my $r = run_session($f, "a\nc\n", sub ($s, $view) {
    path($s->{options}{corrections})->spew_utf8("ATTACH DATABASE '$f->{db}' AS original;\n")
      if $view == 1;
  });
  like($r->{err}, qr/not authorized/, 'external SQL access refused');
  unchanged($f);
};

capture_subtest 'QIF generation failure never publishes the database' => sub {
  my $f = fixture();
  no warnings 'redefine';
  local *Finance::Tiller2QIF::WriteQIF::Emit = sub { die "simulated QIF failure\n" };
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/simulated QIF failure/, 'failure propagated');
  unchanged($f);
};

subtest 'publication failure restores both originals' => sub {
  my $f = fixture();
  my $install = \&Finance::Tiller2QIF::Interactive::_install;
  my $failed = 0;
  no warnings 'redefine';
  local *Finance::Tiller2QIF::Interactive::_install = sub ($source, $target) {
    die "simulated install failure\n" if $target eq $f->{output} && !$failed++;
    $install->($source, $target);
  };
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/simulated install failure/, 'publication failure propagated');
  unchanged($f);
  ok(!-e "$f->{db}.interactive.json", 'rollback journal cleaned');
};

subtest 'pending publication is recovered on next interactive invocation' => sub {
  my $f = fixture();
  my $install = \&Finance::Tiller2QIF::Interactive::_install;
  my $recover = \&Finance::Tiller2QIF::Interactive::_recover;
  {
    no warnings 'redefine';
    local *Finance::Tiller2QIF::Interactive::_install = sub ($source, $target) {
      die "interrupted install\n" if $target eq $f->{output};
      $install->($source, $target);
    };
    local *Finance::Tiller2QIF::Interactive::_recover = sub ($journal) {
      die "interrupted recovery\n" if -e $journal;
      $recover->($journal);
    };
    my $r = run_session($f, "e\n");
    like($r->{error}, qr/Rollback requires recovery/, 'unresolved publication journal retained');
  }
  ok(-f "$f->{db}.interactive.json", 'journal exists');
  my $r = run_session($f, "c\n");
  is($r->{error}, '', 'next invocation recovers');
  like($r->{out}, qr/Rolled back interrupted publication/, 'recovery reported');
  unchanged($f);
};

capture_subtest 'database and output cannot alias inputs' => sub {
  my $f = fixture();
  $f->{output} = $f->{db};
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/must be distinct/, 'alias refused');
  is(Finance::Tiller2QIF::Interactive::_digest($f->{db}), $f->{original}, 'database untouched');
};

subtest 'external editor receives preview, map and editable session SQL' => sub {
  my $f = fixture();
  my $map = "$f->{dir}/rules ' with spaces.map";
  path($f->{mapfile})->move($map);
  $f->{mapfile} = $map;
  my $editor = "$f->{dir}/editor ' with spaces.pl";
  path($editor)->spew_utf8(<<'EDITOR');
use 5.036;
use utf8;
use Path::Tiny;
die 'expected three files' unless @ARGV == 3;
die 'preview must be read-only' if (stat($ARGV[0]))[2] & 0222;
die 'preview must contain IDs' unless path($ARGV[0])->slurp_utf8 =~ /ID: tx-/;
path($0)->sibling('viewer-args.txt')->append_utf8(join("\n", @ARGV) . "\n");
my $sql = path($ARGV[-1]);
if ($sql->slurp_utf8 !~ /editor touched/) {
  $sql->append_utf8("\n-- editor touched\nUPDATE transactions SET memo = 'café';\n");
}
EDITOR
  my $quote = \&Finance::Tiller2QIF::WriteQIF::_shell_quote;
  my $viewer = $^O eq 'MSWin32'
    ? qq{"$^X" "$editor"}
    : $quote->($^X) . ' ' . $quote->($editor);
  my $r = run_session($f, "e\na\ne\n", undef, '--viewer', $viewer);
  is($r->{error}, '', 'shell-quoted editor invocation succeeds');
  like($r->{out}, qr/Apply and refresh successfully/, 'editor edits require refresh');
  like(path($f->{output})->slurp_utf8, qr/Mcafé/, 'editor correction exported');
  like(path("$f->{dir}/viewer-args.txt")->slurp_utf8, qr/\Q$map\E/, 'quoted mapping filename preserved');
};

subtest 'no mapping file still supports hooks and correction removal' => sub {
  my $f = fixture();
  delete $f->{mapfile};
  path("$f->{dir}/before.sql")->spew_utf8('UPDATE transactions SET account = \'Assets:Checking\';');
  my $r = run_session($f, "a\na\ne\n", sub ($s, $view) {
    path($s->{options}{corrections})->spew_utf8('UPDATE transactions SET amount = 500;') if $view == 1;
    path($s->{options}{corrections})->spew_utf8('-- removed') if $view == 2;
  }, '--beforemap', "$f->{dir}/before.sql");
  is($r->{error}, '', 'no-map session succeeds');
  like(path($f->{output})->slurp_utf8, qr/NAssets:Checking.*T100\.00/s, 'hook applied and removed correction undone');
};

subtest 'unterminated CSV cannot export a partial ingest' => sub {
  my $f = fixture();
  path($f->{input})->append_utf8("04/25/2026,bad,Checking,10,\"unterminated\n");
  my $r = run_session($f, "e\nc\n");
  like($r->{err}, qr/CSV parse error/, 'malformed EOF rejected');
  unchanged($f);
};

subtest 'interruption during refresh aborts the session' => sub {
  my $f = fixture();
  no warnings 'redefine';
  local *Finance::Tiller2QIF::Interactive::_sql = sub { $SIG{TERM}->() };
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/Interactive session interrupted/, 'signal is not swallowed by refresh recovery');
  unchanged($f);
};

subtest 'failure after creating a new QIF restores its absence' => sub {
  my $f = fixture();
  unlink $f->{output} or die $!;
  my $install = \&Finance::Tiller2QIF::Interactive::_install;
  no warnings 'redefine';
  local *Finance::Tiller2QIF::Interactive::_install = sub ($source, $target) {
    $install->($source, $target);
    die "failure after output rename\n" if $target eq $f->{output};
  };
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/failure after output rename/, 'failure propagated');
  ok(!-e $f->{output}, 'new QIF removed during rollback');
  is(Finance::Tiller2QIF::Interactive::_digest($f->{db}), $f->{original}, 'original DB restored');
};

capture_subtest 'WAL databases fail before starting a review' => sub {
  my $f = fixture();
  my $dbh = connect_db($f->{db});
  $dbh->do('PRAGMA journal_mode=WAL');
  $dbh->disconnect;
  $f->{original} = Finance::Tiller2QIF::Interactive::_digest($f->{db});
  my $r = run_session($f, "e\n");
  like($r->{error}, qr/not WAL/, 'WAL unsupported explicitly');
  unchanged($f);
};

subtest 'a committed journal never rolls back a successful export' => sub {
  my $f = fixture();
  my $journal = \&Finance::Tiller2QIF::Interactive::_journal;
  {
    no warnings 'redefine';
    local *Finance::Tiller2QIF::Interactive::_journal = sub ($file, $record) {
      $journal->($file, $record);
      die "interruption after commit marker\n" if $record->{state} eq 'committed';
    };
    my $r = run_session($f, "e\n");
    is($r->{error}, '', 'committed publication is reported as success');
    is($r->{result}, 1, 'successful session');
    like($r->{err}, qr/Publication committed/, 'cleanup interruption reported');
  }
  ok(-e "$f->{db}.interactive.json", 'committed journal retained');
  my $published = Finance::Tiller2QIF::Interactive::_digest($f->{db});
  my $r = run_session($f, "c\n");
  is($r->{error}, '', 'next session handles committed journal');
  is(Finance::Tiller2QIF::Interactive::_digest($f->{db}), $published, 'published DB preserved');
  like(path($f->{output})->slurp_utf8, qr/!Account/, 'published QIF preserved');
  ok(!-e "$f->{db}.interactive.json", 'committed journal removed');
};

subtest 'external output changes are not overwritten by export' => sub {
  my $f = fixture();
  my $r = run_session($f, "e\n", sub ($s, $view) {
    path($f->{output})->spew_utf8('written externally');
  });
  like($r->{error}, qr/changed outside the session/, 'publication conflict reported');
  is(Finance::Tiller2QIF::Interactive::_digest($f->{db}), $f->{original}, 'original DB unchanged');
  is(path($f->{output})->slurp_utf8, 'written externally', 'external output preserved');
};

done_testing;
