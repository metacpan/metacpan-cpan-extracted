use strict;
use warnings;

use utf8;

use Test::More;
use JSCalendar::Duration qw(
  seconds_to_duration
  duration_to_seconds
  seconds_to_signed_duration
  signed_duration_to_seconds
);
use Sub::Util ();

binmode(Test::More->builder->$_, q{:encoding(UTF-8)})
  for qw(output failure_output todo_output);

# Call $code, but die if it runs too long, so that a conversion stuck in a loop
# fails one test instead of hanging the whole run.
sub timed (&) {
  my ($code) = @_;

  local $SIG{ALRM} = sub { die "conversion timed out\n" };
  alarm 5;
  my $ok = eval { $code->(); 1 };
  my $error = $@;
  alarm 0;

  die $error unless $ok;
  return;
}

# Like is(), but gets the value by calling $code, and treats an exception as a
# failure of this test rather than the end of the whole file.
sub is_lived {
  my ($code, $expect, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $got;
  unless (eval { timed { $got = $code->() }; 1 }) {
    my $error = $@;
    fail($desc);
    diag("died: $error");
    return;
  }

  return is($got, $expect, $desc);
}

# Check that $seconds converts to $duration, and that $duration converts back
# to the same number of seconds.
sub round_trip {
  my ($seconds, $duration) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is_lived(
    sub { seconds_to_duration($seconds) },
    $duration,
    sprintf("%-10s -> %s", $seconds, $duration),
  );

  is_lived(
    sub { duration_to_seconds($duration) + 0 },
    $seconds + 0,
    sprintf("%-10s <- %s", $seconds, $duration),
  );
}

# Check only that $duration parses to $seconds; for valid durations that are
# not what seconds_to_duration would produce, like P1W1D.
sub duration_parses {
  my ($duration, $seconds) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is_lived(
    sub { duration_to_seconds($duration) + 0 },
    $seconds + 0,
    sprintf("%-10s -> %s", $duration, $seconds),
  );
}

# Like round_trip, but for the signed conversions.
sub signed_round_trip {
  my ($seconds, $duration) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is_lived(
    sub { seconds_to_signed_duration($seconds) },
    $duration,
    sprintf("%-10s -> %s (signed)", $seconds, $duration),
  );

  is_lived(
    sub { signed_duration_to_seconds($duration) + 0 },
    $seconds + 0,
    sprintf("%-10s <- %s (signed)", $seconds, $duration),
  );
}

# Like duration_parses, but for signed durations.
sub signed_duration_parses {
  my ($duration, $seconds) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is_lived(
    sub { signed_duration_to_seconds($duration) + 0 },
    $seconds + 0,
    sprintf("%-10s -> %s (signed)", $duration, $seconds),
  );
}

# Check that calling $func with $input throws an error matching $error_re.
sub is_rejected {
  my ($func, $input, $error_re) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $ok = eval { timed { $func->($input) }; 1 };
  my $error = $@;

  (my $desc = $input) =~ s/\n/\\n/g;
  (my $name = Sub::Util::subname($func)) =~ s/\A.*:://;

  ok(!$ok, "'$desc' is rejected by $name")
    and like($error, $error_re, "...with the expected error");
}

sub duration_rejected {
  my ($input, $error_re) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_rejected(\&duration_to_seconds, $input, $error_re);
}

sub seconds_rejected {
  my ($input, $error_re) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_rejected(\&seconds_to_duration, $input, $error_re);
}

sub signed_duration_rejected {
  my ($input, $error_re) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_rejected(\&signed_duration_to_seconds, $input, $error_re);
}

sub signed_seconds_rejected {
  my ($input, $error_re) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_rejected(\&seconds_to_signed_duration, $input, $error_re);
}

subtest "round trips" => sub {
  round_trip('0',        'P0D');
  round_trip('0.0',      'P0D');
  round_trip('0.00',     'P0D');
  round_trip('0.050',    'PT0.05S');
  round_trip('0.1',      'PT0.1S');
  round_trip('.1',       'PT0.1S');
  round_trip('1',        'PT1S');
  round_trip('1.0',      'PT1S');
  round_trip('1.1',      'PT1.1S');
  round_trip('1.01',     'PT1.01S');
  round_trip('1.10',     'PT1.1S');
  round_trip('1.50',     'PT1.5S');
  round_trip('59',       'PT59S');
  round_trip('59.8',     'PT59.8S');
  round_trip('60',       'PT1M');
  round_trip('60.5',     'PT1M0.5S');
  round_trip('60.00',    'PT1M');
  round_trip('61',       'PT1M1S');
  round_trip('61.1',     'PT1M1.1S');
  round_trip('3599',     'PT59M59S');
  round_trip('3599.9',   'PT59M59.9S');
  round_trip('3600',     'PT1H');
  round_trip('3600.000', 'PT1H');
  round_trip('3600.10',  'PT1H0M0.1S');
  round_trip('3600.5',   'PT1H0M0.5S');
  round_trip('3601',     'PT1H0M1S');
  round_trip('3659',     'PT1H0M59S');
  round_trip('3660.5',   'PT1H1M0.5S');
  round_trip('7200',     'PT2H');
  round_trip('7201.1',   'PT2H0M1.1S');
  round_trip('86399',    'PT23H59M59S');
  round_trip('86400',    'P1D');
  round_trip('86400.0',  'P1D');
  round_trip('86400.5',  'P1DT0.5S');
  round_trip('86401',    'P1DT1S');
  round_trip('86460.25', 'P1DT1M0.25S');
  round_trip('90001',    'P1DT1H0M1S');
  round_trip('90000.5',  'P1DT1H0M0.5S');
  round_trip('172799',   'P1DT23H59M59S');
  round_trip('172800',   'P2D');
  round_trip('172801',   'P2DT1S');
  round_trip('172801.1', 'P2DT1.1S');
  round_trip('604800',   'P1W');
  round_trip('604800.0', 'P1W');
  round_trip('604800.5', 'P7DT0.5S');
  round_trip('604801',   'P7DT1S');
  round_trip('691200',   'P8D');
  round_trip('1209600',    'P2W');
  round_trip('1209600.25', 'P14DT0.25S');
};

subtest "valid but non-canonical durations" => sub {
  duration_parses('P0W',              0);
  duration_parses('P1W0D',            604800);
  duration_parses('P1W1D',            691200);
  duration_parses('P1WT1H',           608400);
  duration_parses('P1WT0.5S',         604800.5);
  duration_parses('P2W3DT4H5M6.7S',   1483506.7);
  duration_parses('P1W1DT1H0M1S',     694801);
  duration_parses('P1DT5H0M3.1S',     104403.1);
};

subtest "misplaced weeks" => sub {
  duration_rejected('P1D1W',  qr{expected T here: '1W'});
  duration_rejected('P1W1W',  qr{expected T here: '1W'});
  duration_rejected('PT1W',   qr{confused by '1W'});
  duration_rejected('P1W1DT', qr{no components after 'T'});
  duration_rejected('P1WT',   qr{no components after 'T'});
};

subtest "seconds directly after hours" => sub {
  my $no_minutes = qr{seconds may not follow hours without minutes};

  duration_rejected('PT1H1S',   $no_minutes);
  duration_rejected('PT1H0.5S', $no_minutes);
  duration_rejected('PT0H0S',   $no_minutes);
  duration_rejected('P1DT1H1S', $no_minutes);
  duration_rejected('P1WT1H1S', $no_minutes);

  duration_parses('PT1H0M1S', 3601);
  duration_parses('PT0H0M0S', 0);
  duration_parses('PT1M1S',   61);
};

subtest "trailing zeros in fractions" => sub {
  my $zero_frac = qr{fractional seconds may not end in zero};

  duration_rejected('PT1.0S',       $zero_frac);
  duration_rejected('PT0.0S',       $zero_frac);
  duration_rejected('PT1.50S',      $zero_frac);
  duration_rejected('PT1.000S',     $zero_frac);
  duration_rejected('PT1M0.10S',    $zero_frac);
  duration_rejected('P1DT1H0M1.0S', $zero_frac);

  duration_parses('PT1.05S', 1.05);
  duration_parses('PT10S',   10);
  duration_parses('PT0S',    0);
};

subtest "non-ASCII" => sub {
  # ๓ - U+00E53 - THAI DIGIT THREE
  duration_rejected("P\N{THAI DIGIT THREE}D", qr/ASCII/);
};

subtest "empty components" => sub {
  duration_rejected('P',    qr{no components after 'P'});
  duration_rejected('PT',   qr{no components after 'T'});
  duration_rejected('P1DT', qr{no components after 'T'});
};

subtest "trailing zero" => sub {
  duration_rejected('P1D0',    qr{expected T here: '0'});
  duration_rejected('PT1H0',   qr{confused by '0'});
  duration_rejected('P1DT1H0', qr{confused by '0'});
};

subtest "malformed durations" => sub {
  duration_rejected('',          qr{must start with 'P'});
  duration_rejected('1D',        qr{must start with 'P'});
  duration_rejected(' P1D',      qr{must start with 'P'});
  duration_rejected('p1d',       qr{must start with 'P'});
  duration_rejected('-P1D',      qr{must start with 'P'});
  duration_rejected('+P1D',      qr{must start with 'P'});

  duration_rejected("P1D\n",     qr{expected T here});
  duration_rejected("PT1S\n",    qr{confused by});
  duration_rejected("P1W\n",     qr{expected T here});
  duration_rejected("P0D\n",     qr{expected T here});
  duration_rejected('P1D ',      qr{expected T here});

  duration_rejected('P1',        qr{expected T here: '1'});
  duration_rejected('PT1',       qr{confused by '1'});
  duration_rejected('P1H',       qr{expected T here: '1H'});
  duration_rejected('P1DT1D',    qr{confused by '1D'});
  duration_rejected('PT1S1M',    qr{confused by '1M'});
  duration_rejected('PT1M1H',    qr{confused by '1H'});
  duration_rejected('PT1H1H',    qr{confused by '1H'});
  duration_rejected('PT1S1S',    qr{confused by '1S'});
  duration_rejected('PT1.5M',    qr{confused by '1.5M'});
  duration_rejected('P1.5D',     qr{expected T here: '1.5D'});
  duration_rejected('PT.5S',     qr{confused by '.5S'});
  duration_rejected('PT1.S',     qr{confused by '1.S'});
  duration_rejected('PT1,5S',    qr{confused by '1,5S'});
  duration_rejected('PT-1S',     qr{confused by '-1S'});
  duration_rejected('P1Y',       qr{expected T here: '1Y'});
  duration_rejected('PT1h',      qr{confused by '1h'});
};

subtest "invalid seconds" => sub {
  my $non_number = qr{Non-number value provided};

  seconds_rejected("",       $non_number);
  seconds_rejected("60\n",   $non_number);
  seconds_rejected("60.5\n", $non_number);
  seconds_rejected(" 60",    $non_number);
  seconds_rejected("60 ",    $non_number);
  seconds_rejected("-60",    $non_number);
  seconds_rejected("+60",    $non_number);
  seconds_rejected("1e3",    $non_number);
  seconds_rejected("1.2.3",  $non_number);
  seconds_rejected("1.",     $non_number);
  seconds_rejected("abc",    $non_number);
  seconds_rejected("abc.5",  $non_number);

  seconds_rejected("\N{THAI DIGIT THREE}",   $non_number);
  seconds_rejected("1.\N{THAI DIGIT THREE}", $non_number);
};

subtest "large seconds" => sub {
  my $too_big        = qr{Whole seconds exceed 9007199254740991};
  my $signed_too_big = qr{seconds_to_signed_duration.*Whole seconds exceed};

  seconds_rejected('9007199254740992',   $too_big);
  seconds_rejected('1' . '0' x 30,       $too_big);
  seconds_rejected('9' x 400,            $too_big);
  seconds_rejected('9007199254740992.5', $too_big);

  signed_seconds_rejected('-9007199254740992', $signed_too_big);
  signed_seconds_rejected('-1' . '0' x 30,     $signed_too_big);
  signed_seconds_rejected('-' . '9' x 400,     $signed_too_big);

  round_trip('9007199254740991',    'P104249991374DT7H36M31S');
  round_trip('0009007199254740991', 'P104249991374DT7H36M31S');

  # One second short of a whole day, where an inexact quotient would be most
  # likely to round up to the next day.
  round_trip('9007199254713599', 'P104249991373DT23H59M59S');

  signed_round_trip('-9007199254740991', '-P104249991374DT7H36M31S');

  # Round-tripping would compare the fraction as a float, where it's lost.
  is_lived(
    sub { seconds_to_duration('9007199254740991.5') },
    'P104249991374DT7H36M31.5S',
    'fractional seconds are kept separately at the whole-seconds limit',
  );
};

subtest "large durations" => sub {
  my $too_big = qr{whole seconds exceed 9007199254740991};

  duration_rejected('PT9007199254740992S',     $too_big);
  duration_rejected('PT150119987579017M',      $too_big);
  duration_rejected('PT2501999792984H',        $too_big);
  duration_rejected('P104249991375D',          $too_big);
  duration_rejected('P14892855911W',           $too_big);
  duration_rejected('P104249991374DT7H36M32S', $too_big);
  duration_rejected('P' . '9' x 400 . 'D',     $too_big);
  duration_rejected('PT' . '9' x 400 . 'S',    $too_big);

  signed_duration_rejected(
    '-PT9007199254740992S',
    qr{Invalid duration '-PT9007199254740992S', whole seconds exceed},
  );

  duration_parses('PT9007199254740991S',       9007199254740991);
  duration_parses('PT150119987579016M',        9007199254740960);
  duration_parses('PT2501999792983H',          9007199254738800);
  duration_parses('P14892855910W',             9007199254368000);
  duration_parses('P14892855910WT103H36M31S',  9007199254740991);

  # The limit is on whole seconds, so a fraction on top of it is allowed.
  duration_parses('PT9007199254740991.5S',     9007199254740991.5);
};

subtest "signed round trips" => sub {
  signed_round_trip('0',          'P0D');
  signed_round_trip('-0',         'P0D');
  signed_round_trip('-0.0',       'P0D');
  signed_round_trip('60',         'PT1M');
  signed_round_trip('+60',        'PT1M');
  signed_round_trip('-60',        '-PT1M');
  signed_round_trip('-0.5',       '-PT0.5S');
  signed_round_trip('-.5',        '-PT0.5S');
  signed_round_trip('-1.50',      '-PT1.5S');
  signed_round_trip('-3601',      '-PT1H0M1S');
  signed_round_trip('-86400',     '-P1D');
  signed_round_trip('-604800',    '-P1W');
  signed_round_trip('-691200.25', '-P8DT0.25S');
};

subtest "valid but non-canonical signed durations" => sub {
  signed_duration_parses('+PT1M',  60);
  signed_duration_parses('-P0D',   0);
  signed_duration_parses('+P0D',   0);
  signed_duration_parses('-PT0S',  0);
  signed_duration_parses('-P1W1D', -691200);
};

subtest "malformed signed durations" => sub {
  my $no_p = qr{must start with 'P'};

  signed_duration_rejected('',        $no_p);
  signed_duration_rejected('-',       $no_p);
  signed_duration_rejected('+',       $no_p);
  signed_duration_rejected('--PT1M',  $no_p);
  signed_duration_rejected('+-PT1M',  $no_p);
  signed_duration_rejected('- PT1M',  $no_p);
  signed_duration_rejected(' -PT1M',  $no_p);
  signed_duration_rejected('-p1d',    $no_p);
  signed_duration_rejected('PT1M-',   qr{confused by '-'});
  signed_duration_rejected("-PT1M\n", qr{confused by});
  signed_duration_rejected('-P',      qr{no components after 'P'});
  signed_duration_rejected('-PT1H1S', qr{seconds may not follow hours});
  signed_duration_rejected('-PT1.0S', qr{fractional seconds may not end in zero});

  # The error should show what was passed in, sign and all.
  signed_duration_rejected('-PT1X',   qr{Invalid duration '-PT1X'});
};

subtest "invalid signed seconds" => sub {
  my $non_number = qr{Non-number value provided};

  signed_seconds_rejected('',      $non_number);
  signed_seconds_rejected('-',     $non_number);
  signed_seconds_rejected('+',     $non_number);
  signed_seconds_rejected('--5',   $non_number);
  signed_seconds_rejected('+-5',   $non_number);
  signed_seconds_rejected('- 5',   $non_number);
  signed_seconds_rejected('-5 ',   $non_number);
  signed_seconds_rejected("-5\n",  $non_number);
  signed_seconds_rejected('5-',    $non_number);
  signed_seconds_rejected('-abc',  $non_number);
  signed_seconds_rejected('-1e3',  $non_number);

  # The error should name the function called, and show the whole input.
  signed_seconds_rejected('-x', qr{seconds_to_signed_duration.*'-x'});
};

done_testing;
