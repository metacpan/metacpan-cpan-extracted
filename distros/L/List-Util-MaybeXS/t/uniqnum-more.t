use strict;
use warnings;
use Test::More;

use Config ();
use List::Util::PP qw(max);

use constant MAXUINT => ~0;
use constant MAXINT => ~0 >> 1;
use constant MININT => -(~0 >> 1) - 1;

use constant INF => 9**9**9**9;
use constant NAN => 0*9**9**9**9;
use constant INF_NAN_SUPPORT => (
  INF == 10 * INF
  and !(NAN == 0 || NAN == 0.1 || NAN + 0 == 0)
);

sub iterate_uniqnum {
  my @uniq;
  sub {
    my ($in) = @_;
    local $@;
    my $dupe;
    for my $uniq (@uniq) {
      # this can't do a simple == comparison, due to conflicts between
      # floating point and unsigned int comparisons.  In particular:
      # maxuint     == maxuint converted to float
      # maxunit-1   == maxuint converted to float
      # maxunit     != maxuint-1
      #
      # It isn't possible to combine these into any concept of uniqueness that
      # doesn't depend either heavily on order, or could result in less
      # outputs by adding additional inputs.
      #
      # To work around this, we isolate the different numeric formats using
      # pack with perl's internal native formats (j for IV, J for UV, F for
      # NV).  Values are considered equal if all parts are equal.  The values
      # will truncate in the same way if they don't fit in the requested size.
      #
      # evals are needed to handle Inf and NaN, since they may die in
      # int/uint conversions.

      my ($uj) = eval { unpack 'j', pack 'j', $uniq };
      my ($uJ) = eval { unpack 'J', pack 'J', $uniq };
      my ($uF) =        unpack 'F', pack 'F', $uniq;
      my ($ij) = eval { unpack 'j', pack 'j', $in };
      my ($iJ) = eval { unpack 'J', pack 'J', $in };
      my ($iF) =        unpack 'F', pack 'F', $in;

      # Inf/NaN
      if ($uniq != $uniq || $in != $in || !defined $uj || !defined $ij) {
        # some platforms may stringify NaN and -NaN differently, and others
        # will not, even if the internal representation is different.  We just
        # use the stringification for the identity, rather than trying to peek
        # further into if the NaN is negative or has a payload.
        if ($uF eq $iF) {
          $dupe = 1;
          last;
        }
      }
      elsif ($uj == $ij && $uJ == $iJ && $uF == $iF) {
        $dupe = 1;
        last;
      }
    }
    push @uniq, $in;
    return !$dupe;
  }
}

my @forced;
my $uniqnum;
{
  my $IMPL = 'List::Util::PP';
  my $sub = 'uniqnum';
  while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg eq '--xs') {
      $IMPL = 'List::Util';
    }
    elsif ($arg eq '--pp') {
      $IMPL = 'List::Util::PP';
    }
    elsif ($arg eq '--') {
      push @forced, @ARGV;
      last;
    }
    elsif ($arg =~ /\A-/) {
      die "Invalid argument '$arg'!\n";
    }
    else {
      push @forced, $arg;
    }
  }
  (my $f = "$IMPL.pm") =~ s{::}{/}g;
  require $f;
  $uniqnum = \&{"${IMPL}::${sub}"};
  print "# Testing ${IMPL}::${sub}\n";
}

my $nvmantbits = $Config::Config{nvmantbits} || do {
  my $nvsize = $Config::Config{nvsize} * 8;
    $nvsize == 16  ? 11
  : $nvsize == 32  ? 24
  : $nvsize == 64  ? 53
  : $nvsize == 80  ? 64
  : $nvsize == 128 ? 113
  : $nvsize == 256 ? 237
                   : 237 # i dunno
};
my $precision = 2 + int( log(2)/log(10)*$nvmantbits );

my @numbers = (
  (-20 .. 20),
  "-0.0",
  (map "'$_'", qw(00 01 .0 .1 0.0 0.00 00.00 0.10 0.101 1.0)),
  "'0 but true'",
  "'0e0'",
  (map +("1e$_", "-1e$_"), -50, -5, 0, 1, 5, 50),
  (map "1 / $_", -10 .. -2, 2 .. 10),
  (map "+(1 / 9) * $_", -9 .. -1, 1 .. 9),
  (map "'$_' x 100", 1 .. 9),
  '3.14159265358979323846264338327950288419716939937510',
  '2.71828182845904523536028747135266249775724709369995',
  'sqrt(2)',
  '1.4142135623730951',
  '1.4142135623730954',
  'sqrt(3)',
  '1.7320508075688772935274463415058722',
  '1.73205080756887729352744634150587224',
  'sqrt(5)',
  '2.2360679774997896963',
  '2.23606797749978969634',
  'MAXUINT',
  'MAXUINT - 1',
  'MAXUINT + 1',
  'MAXUINT + 2',
  'MAXINT',
  'MAXINT + 1',
  'MININT',
  '18446744073709551614.0',
  '18014398509481985',
  '1.8014398509481985e16',
  (INF_NAN_SUPPORT ? (
    'INF', '-(INF)',
    'NAN', '-(NAN)',
  ) : ()),
);

my @all_numbers = map +(
  "sprintf '%.".sprintf('%02d', $precision-3)."g', $_",
  "sprintf '%.".sprintf('%02d', $precision-2)."g', $_",
  "sprintf '%.".sprintf('%02d', $precision-1)."g', $_",
  "                 $_",
  "sprintf '%.".sprintf('%02d', $precision)."g', $_",
  "sprintf '%.".sprintf('%02d', $precision+1)."g', $_",
), @numbers;

@all_numbers = @forced
  if @forced;

my @numinfo = map {;
  use warnings FATAL => 'all';
  my $number;
  local $@;
  eval "\$number = 0 + ($_); 1" ? [
    $_,
    $number,
    sprintf('%f', $number),
    eval { unpack 'H*', pack 'j', $number },
    eval { unpack 'H*', pack 'J', $number },
    eval { unpack 'H*', pack 'F', $number },
  ] : [ $_ ];
} @all_numbers;

my $fail;

my $last_count_uniq = 0;
my $it = iterate_uniqnum();
for my $i (0 .. $#numinfo) {
  SKIP: {
    my @select = map $_->[1], @numinfo[0 .. $i];
    my ($source, $number, $sprintf, $j, $J, $F) = @{$numinfo[$i]};
    if (!defined $number) {
      skip "NOT NUMERIC : $source", 1;
    }

    my $want_uniq = $it->($number);

    my @uniqnum = $uniqnum->(map $_->[1], @numinfo[0 .. $i]);
    my $got_uniq = $last_count_uniq != @uniqnum;
    $last_count_uniq = @uniqnum;

    if ($want_uniq) {
      ok $got_uniq,
        "UNIQUE : $source"
        or $fail++;
    }
    else {
      ok !$got_uniq,
        "DUPE   : $source"
        or $fail++;
    }
  }
}

if ($fail) {
  diag table(
    ['value', '%f', 'j', 'J', 'F'],
    map [
      $_->[0],
      $_->[2] || '',
      $_->[3] || '',
      $_->[4] || '',
      $_->[5] || '',
    ], @numinfo
  );
}

sub table {
  my @rows = @_;
  my @widths = map {;
    my $col = $_;
    max(map +length $rows[$_][$col], 0 .. $#rows);
  } 0 .. $#{$rows[0]};

  my $format = join(' | ', map "%-${_}s", @widths);
  my $sep = join('-+-', map '-' x $_, @widths);

  return join('',
    sprintf("$format\n", @{shift @rows}),
    sprintf("$sep\n"),
    map sprintf("$format\n", @$_), @rows,
  );
}

done_testing;
