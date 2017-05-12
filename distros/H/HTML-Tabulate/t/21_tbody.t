# tbody testing

use Test::More tests => 15;
use HTML::Tabulate;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t21";
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

# tbody scalar
$table = $t->render($d, {
  tbody => 1,
});
report $table, "tbody1";
is($table, $result{tbody1}, "tbody scalar, no labels");

# tbody scalar, with labels
$table = $t->render($d, {
  tbody => 1,
  labels => 1,
});
report $table, "tbody2";
is($table, $result{tbody2}, "tbody scalar, with labels");

# tbody hashref, with attributes
$table = $t->render($d, {
  tbody => { class => 'tbody1', style => 'background-color: #eee' },
});
report $table, "tbody3";
is($table, $result{tbody3}, "tbody hashref, with attributes");

# tbody with -field 1
$table = $t->render($d, {
  tbody => { '-field' => 'emp_gender' },
});
report $table, "tbody_field";
is($table, $result{tbody_field}, "tbody with -field 1");

# tbody with -field 2
$table = $t->render($d, {
  tbody => { '-field' => 'emp_xx' },
});
report $table, "tbody_field2";
is($table, $result{tbody_field2}, "tbody with -field 2");

# tbody with -field 3
$table = $t->render($d, {
  tbody => { '-field' => 'emp_xx', class => 'tbody_field3' },
});
report $table, "tbody_field3";
is($table, $result{tbody_field3}, "tbody with -field, with attributes");

# tbody with -rows 1
$table = $t->render($d, {
  tbody => { '-rows' => 2 }
});
report $table, "tbody_rows1";
is($table, $result{tbody_rows1}, "tbody with -rows 1 (-rows => 2)");

push @$d, [ '000', 'Pebbles', 'Child', 'F' ];

# tbody with -rows 2
$table = $t->render($d, {
  tbody => { '-rows' => 2 }
});
report $table, "tbody_rows2";
is($table, $result{tbody_rows2}, "tbody with -rows 2 (-rows => 2)");

# tbody with -rows 3
$table = $t->render($d, {
  tbody => { '-rows' => 3 }
});
report $table, "tbody_rows3";
is($table, $result{tbody_rows3}, "tbody with -rows 3 (-rows => 3)");

# tbody with -rows 4
$table = $t->render($d, {
  tbody => { '-rows' => 1 }
});
report $table, "tbody_rows4";
is($table, $result{tbody_rows4}, "tbody with -rows 4 (-rows => 1)");

# tbody with -rows 5
$table = $t->render($d, {
  tbody => { '-rows' => 1 },
  thead => 1,
});
report $table, "tbody_rows5";
is($table, $result{tbody_rows5}, "tbody with -rows 5 (-rows => 1, thead => 1)");

# tbody with -rows 6
$table = $t->render($d, {
  tbody => { '-rows' => 0 }
});
report $table, "tbody_rows6";
is($table, $result{tbody_rows6}, "tbody with -rows 6 (-rows => 0)");

# tbody with -rows 7
$table = $t->render($d, {
  tbody => { '-rows' => 7 }
});
report $table, "tbody_rows7";
is($table, $result{tbody_rows7}, "tbody with -rows 7 (-rows => 7)");

# tbody with -rows 8
$table = $t->render($d, {
  tbody => { '-rows' => 20 }
});
report $table, "tbody_rows7";
is($table, $result{tbody_rows7}, "tbody with -rows 8 (-rows => 20)");

# tbody with -rows, with attributes
$table = $t->render($d, {
  tbody => { '-rows' => 3, class => 'tbody_rows_attr', style => 'color: #666' }
});
report $table, "tbody_rows_attr";
is($table, $result{tbody_rows_attr}, "tbody with -rows with attributes");

