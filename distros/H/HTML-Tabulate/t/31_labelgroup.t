# colgroups testing

use Test::More;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);
use strict;

# Load result strings
my %result = ();
my $test = "$Bin/t31";
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
  labels => {
    id          => 'ID',
    givenname   => 'Given'
  },
  labelgroups => {
    Names       => [ qw(givenname surname) ],
  },
  field_attr => {
    id          => { label_class => 'id', label_valign => 'bottom', },
    surname     => { label_class => 'surname' },
    Names       => { label_class => 'names' },
    title       => { label_valign => 'bottom' },
  },
});
report $table, "labelgroups1";
is($table, $result{labelgroups1}, "labelgroups1");

done_testing;

