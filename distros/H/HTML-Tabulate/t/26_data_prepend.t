# Data prepend testing

use strict;
use Test::More tests => 6;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t26";
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

my $d = [ 
  [ '123', 'Fred Flintstone', 'CEO', 'M', 1 ], 
  [ '456', 'Barney Rubble', 'Lackey', 'M', 2 ],
  [ '999', 'Dino', 'Pet', 'M', 0 ],
  [ '888', 'Bam Bam', 'Child', 'M', 0 ],
  [ '789', 'Wilma Flintstone   ', 'CFO', 'F', undef ], 
  [ '777', 'Betty Rubble', '', 'F', undef ],
];
my $t = HTML::Tabulate->new({ 
  fields => [ qw(emp_id emp_name emp_title emp_gender emp_xx) ],
  fields_omit => [ qw(emp_gender emp_xx) ],
});
my $table;
my @prepend;

# No data_prepend
$table = $t->render($d);
report $table, "simple1";
is($table, $result{simple1}, "no data_prepend");

# Empty data_prepend
$table = $t->render($d, {
  data_prepend => [],
});
report $table, "simple1";
is($table, $result{simple1}, "empty data_prepend");

# Single-row data_prepend
@prepend = ( shift @$d );
$table = $t->render($d, {
  data_prepend => \@prepend,
});
report $table, "simple1";
is($table, $result{simple1}, "single-row data_prepend");

# Multi-row data_prepend
push @prepend, shift @$d;
push @prepend, shift @$d;
is(scalar @prepend, 3, "three rows to data_prepend");
$table = $t->render($d, {
  data_prepend => \@prepend,
});
report $table, "simple1";
is($table, $result{simple1}, "multi-row data_prepend");

# Hashref rows in data_prepend
my @prepend2 = ();
for my $row (@prepend) {
  my $new_row = {};
  for (qw(emp_id emp_name emp_title emp_gender emp_xx)) {
    $new_row->{$_} = shift @$row;
  }
  push @prepend2, $new_row;
}
$table = $t->render($d, {
  data_prepend => \@prepend2,
});
report $table, "simple1";
is($table, $result{simple1}, "multi-row hashref data_prepend");

