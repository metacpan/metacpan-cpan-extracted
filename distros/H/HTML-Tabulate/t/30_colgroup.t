# colgroups testing

use Test::More;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);
use strict;

# Load result strings
my %result = ();
my $test = "$Bin/t30";
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
  { id => '123', givenname => 'Fred',   surname => 'Flintstone', title => 'CEO', }, 
  { id => '456', givenname => 'Barney', surname => 'Rubble', title => 'Lackey', },
  { id => '999', givenname => 'Dino', title => 'Pet', },
  { id => '888', givenname => 'Bam Bam', title => 'Child', },
  { id => '789', givenname => 'Wilma', surname => 'Flintstone', title => 'CFO', },
  { id => '777', givenname => 'Betty', surname => 'Rubble', },
];
my $t = HTML::Tabulate->new({ 
  labels => {
    id => 'ID',
    givenname => 'Given Name',
  },
});
my $table;

# Simple colgroups
$table = $t->render($d, {
  fields => [ qw(id givenname surname title) ],
  labels => 1,
  colgroups => [
    { align => 'center' },
    { align => 'left', span => 2 },
    { align => 'right' },
  ],
});
report $table, "colgroups1";
is($table, $result{colgroups1}, "colgroups1");

# XHTML colgroups
$table = $t->render($d, {
  fields => [ qw(id givenname surname title) ],
  labels => 1,
  xhtml  => 1,
  colgroups => [
    { align => 'center' },
    { align => 'left', span => 2 },
    { align => 'right' },
  ],
});
report $table, "colgroups2";
is($table, $result{colgroups2}, "colgroups2");

# colgroups with embedded cols
$table = $t->render($d, {
  fields => [ qw(id givenname surname title) ],
  labels => 1,
  xhtml  => 1,
  colgroups => [
    { align => 'center' },
    { align => 'left', cols => [
      { class => 'col1', span => '2' },
      { id => 'col2', width => 20 },
    ] },
  ],
});
report $table, "colgroups3";
is($table, $result{colgroups3}, "colgroups3");

done_testing;

