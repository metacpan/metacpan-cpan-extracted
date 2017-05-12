# thead testing

use Test::More tests => 5;
use HTML::Tabulate;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t20";
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

my $d = [ [ '123', 'Fred Flintstone', 'CEO' ], 
       [ '456', 'Barney Rubble', 'Lackey' ],
       [ '789', 'Wilma Flintstone   ', 'CFO' ], 
       [ '777', 'Betty Rubble', '' ], ];
my $t = HTML::Tabulate->new({ 
  fields => [ qw(emp_id emp_name emp_title) ],
});
my $table;

# thead scalar with labels
$table = $t->render($d, {
  thead => 1,
  labels => 1,
});
report $table, "thead1";
is($table, $result{thead1}, "thead scalar with labels");

# thead scalar w/o labels
$table = $t->render($d, {
  thead => 1,
});
report $table, "thead2";
is($table, $result{thead2}, "thead scalar w/o labels");

# thead hashref with labels
$table = $t->render($d, {
  thead => {},
  labels => 1,
});
report $table, "thead1";
is($table, $result{thead1}, "thead hashref with labels");

# thead hashref w/o labels
$table = $t->render($d, {
  thead => {},
});
report $table, "thead2";
is($table, $result{thead2}, "thead hashref w/o labels");

# thead hashref with attributes
$table = $t->render($d, {
  thead => { class => 'thead1', style => 'color: #666' },
  labels => 1,
});
report $table, "thead3";
is($table, $result{thead3}, "thead hashref with attributes");

