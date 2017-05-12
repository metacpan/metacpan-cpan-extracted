# Miscellaneous labels testing

use Test::More tests => 5;
use HTML::Tabulate;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t16";
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

my $d = { emp_id => '123', emp_name => 'Fred Flintstone',
  emp_title => 'CEO', emp_addr_id => '225', emp_birth_dt => '20-10-55',
  emp_notes => "Started with company in 1983.\nFavourite colour: green.\n",
  emp_modify_uid => 12, emp_modify_ts => 20031231,
  emp_create_uid => 6,  emp_create_ts => 20020804,
  emp_cancel_b => 'N',
};
my $t = HTML::Tabulate->new({ 
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  labels => 1,
  null => '&nbsp;',
});
my $table;

# Auto labels
$table = $t->render($d, {
  fields => [ qw(emp_id emp_name emp_title) ],
});
report $table, "auto";
is($table, $result{auto}, "auto labels");

# Explicit label hash
$table = $t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  labels => {
    emp_name => 'Name',
    emp_title => 'Title',
    emp_birth_dt => 'Birth Date',
  },
});
report $table, "explicit";
is($table, $result{explicit}, "label hash");

# Explicit label attributes
$table = $t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  field_attr => { 
    emp_name => { label => 'Name' },
    emp_title => { label => 'Title' },
    emp_birth_dt => { label => 'Birth Date' },
  },
});
report $table, "explicit";
is($table, $result{explicit}, "label attributes");

# Empty labels
$table = $t->render($d, {
  fields => [ qw(emp_cancel_b emp_id emp_name emp_title) ],
  field_attr => { 
    emp_cancel_b => {
      label => '',
      align => 'right',
    },
  },
});
report $table, "empty";
is($table, $result{empty}, "empty label (attribute)");

# Empty labels II 
$table = $t->render($d, {
  fields => [ qw(emp_cancel_b emp_id emp_name emp_title) ],
  labels => { emp_cancel_b => '' },
  field_attr => { 
    emp_cancel_b => {
      align => 'right',
    },
  },
});
report $table, "empty";
is($table, $result{empty}, "empty label (hash)");

