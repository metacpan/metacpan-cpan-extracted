# xhtml mode testing

use Test::More;
use HTML::Tabulate;
use Data::Dumper;
use FindBin qw($Bin);
use strict;

# Load result strings
my %result = ();
my $test = "$Bin/t24";
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
  { id => '123', name => 'Fred Flintstone', title => 'CEO', }, 
  { id => '456', name => 'Barney Rubble', title => 'Lackey', },
  { id => '999', name => 'Dino', title => 'Pet', },
  { id => '888', name => 'Bam Bam', title => 'Child', },
  { id => '789', name => 'Wilma Flintstone', title => 'CFO', },
  { id => '777', name => 'Betty Rubble', },
];
my $t = HTML::Tabulate->new({ 
  fields => [ qw(id name title) ],
  labels => {
    id => 'ID',
  },
  field_attr => {
    id => {
      data_id => '',
    },
    name => {
      nowrap => '',
    },
  },
});
my $table;

# Standard HTML mode
$table = $t->render($d);
report $table, "html1";
is($table, $result{html1}, "html1");

# XHTML mode
$table = $t->render($d, { xhtml => 1 });
report $table, "xhtml1";
is($table, $result{xhtml1}, "xhtml1");

done_testing;

