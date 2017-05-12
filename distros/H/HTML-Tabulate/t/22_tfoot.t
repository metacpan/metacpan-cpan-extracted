# tfoot testing

use Test::More tests => 3;
use HTML::Tabulate;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t22";
die "missing data dir $test" unless -d $test;
opendir my $datadir, $test or die "can't open directory $test";
for (readdir $datadir) {
  next if m/^\./;
  open my $fh, "<$test/$_" or die "can't read $test/$_";
  { 
    local $/ = undef;
    $result{$_} = <$fh>;
  }
  close $fh;
}
close $datadir;

my $print = shift @ARGV || 0;
my $n = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $n) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $n += $inc;
}

my ($table, $total_debit, $total_credit);

my $d = [
  { txn => 1, desc => 'Wages', debit => '5000' },
  { txn => 2, desc => 'Groceries', credit => '110.12' },
];
my $t = HTML::Tabulate->new({ 
  fields => [ qw(txn desc debit credit) ],
  labels => 1,
  field_attr => {
    desc => {
      label => 'Description',
      tfoot_value => 'Total',
      tfoot_class => 'total',
    },
    debit => {
      value => sub {
        my ($v, $r) = @_;
        $total_debit += $v if $v;
        $v;
      },
      tfoot_id => 'total_debit',
      tfoot_value => sub { $total_debit },
    },
    credit => {
      value => sub {
        my ($v, $r) = @_;
        $total_credit += $v if $v;
        $v;
      },
      tfoot_id => 'total_credit',
      tfoot_value => sub { $total_credit },
    },
  },
});

# tfoot scalar
$total_debit = 0;
$total_credit = 0;
$table = $t->render($d, {
  tfoot => 1,
});
report $table, "tfoot1";
is($table, $result{tfoot1}, "tfoot scalar");

# tfoot scalar with thead
$total_debit = 0;
$total_credit = 0;
$table = $t->render($d, {
  tfoot => 1,
  thead => 1,
});
report $table, "tfoot2";
is($table, $result{tfoot2}, "tfoot scalar with thead");

# tfoot hashref
$total_debit = 0;
$total_credit = 0;
$table = $t->render($d, {
  tfoot => { id => 'tfoot', align => 'right' },
});
report $table, "tfoot3";
is($table, $result{tfoot3}, "tfoot hashref");

