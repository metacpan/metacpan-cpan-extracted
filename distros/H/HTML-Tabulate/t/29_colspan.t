# colspan testing

use Test::More;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);
use strict;

# Load result strings
my %result = ();
my $test = "$Bin/t29";
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
  { id => 'Group1' },
  { id => '123', givenname => 'Fred',   surname => 'Flintstone', title => 'CEO', }, 
  { id => '456', givenname => 'Barney', surname => 'Rubble', title => 'Lackey', },
  { id => '999', givenname => 'Dino', title => 'Pet', },
  { id => 'Group2' },
  { id => '888', givenname => 'Bam Bam',   title => 'Child', },
  { id => '789', givenname => 'Wilma', surname => 'Flintstone   ', title => 'CFO', },
  { id => '777', givenname => 'Betty', surname => 'Rubble', },
];
my $t = HTML::Tabulate->new({ 
  labels => {
    id => 'ID',
    givenname => 'Given Name',
  },
});
my $table;

# Simple colspans
$table = $t->render($d, {
  fields => [ qw(id givenname surname title) ],
  labels => 1,
  trim => 1,
  field_attr => {
    id => {
      class => sub {
        my ($v, $r) = @_;
        $v =~ m/^Group/ ? 'group' : 'person';
      },
      colspan => sub {
        my ($v, $r) = @_;
        $v =~ m/^Group/ ? 4 : undef;
      },
    },
  },
});
report $table, "colspan1";
is($table, $result{colspan1}, "colspan1");

# Simple colspans
$table = $t->render($d, {
  fields => [ qw(id givenname surname title) ],
  labels => 1,
  trim => 1,
  field_attr => {
    id => {
      class => sub {
        my ($v, $r) = @_;
        $v =~ m/^Group/ ? 'group' : 'person';
      },
      colspan => sub {
        my ($v, $r) = @_;
        $v =~ m/^Group/ ? 3 : undef;
      },
    },
  },
});
report $table, "colspan2";
is($table, $result{colspan2}, "colspan2");

done_testing;

