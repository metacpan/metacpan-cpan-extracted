# Miscellaneous links testing

use Test::More tests => 2;
use HTML::Tabulate;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t17";
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
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  labels => 1,
});
my $table;

# Link attributes
$table = $t->render($d, {
  fields => [ qw(emp_id emp_name emp_title edit delete) ],
  field_attr => {
    emp_id => {
      link => 'emp_details.html?id=%s',
      link_title => '[Employee Details]',
      link_target => '_blank',
    },
    edit => {
      value => 'Edit',
      link => sub { my ($x, $r) = @_; 'edit.html?id=' . $r->[0] },
      link_title => '[Edit Employee Record]',
      link_style => 'font-weight: bold',
    },
    delete => {
      value => 'Delete',
      link => sub { my ($x, $r) = @_; 'delete.html?id=' . $r->[0] },
      link_title => '[Delete Employee Record]',
      link_class => sub { my ($d, $r, $f) = @_; "emp_$f" },
    },
  },
});
report $table, "links1";
is($table, $result{links1}, "links1");

# Label link attributes
$table = $t->render($d, {
  fields => [ qw(emp_id emp_name emp_title) ],
  field_attr => {
    -defaults => {
      label_link => sub { my ($x, $r, $f) = @_; "?order=$f" },
      label_link_class => sub { shift; shift; shift },
      label_link_target => '_blank',
    },
    emp_id => {
      link => 'emp_details.html?id=%s',
      link_target => '_blank',
    },
  },
});
report $table, "links2";
is($table, $result{links2}, "links2");

