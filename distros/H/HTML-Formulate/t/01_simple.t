# Minimal edit test

use Test::More tests => 3;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't01';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
opendir DATADIR, $test or die "can't open directory $test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<$test/$_" or die "can't read $test/$_";
  {
    local $/ = undef;
    $result{$_} = <FILE>;
  }
  close FILE;
}
close DATADIR;

my $print = shift @ARGV || 0;
my $t = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $t += $inc;
}

my ($f, $form);

$f = HTML::Formulate->new();
my $d = { emp_id => '123', emp_name => 'Fred "Rocky" Flintstone',
  emp_title => 'CEO', emp_addr_id => '225', emp_birth_dt => '20-10-55',
  emp_modify_uid => 12, emp_modify_ts => 20031231,
  emp_create_uid => 6,  emp_create_ts => 20020804,
};

# Minimal edit table
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt
    emp_modify_ts emp_modify_uid) ],
  field_attr => {
    emp_id => { type => 'static' },
    qr/_uid$/ => { type => 'hidden', value => '1003', },
    qr/_ts$/ => { type => 'hidden', value => '', },
  },
});
report $form, "simple1";
is($form, $result{simple1}, "simple edit");

# Minimal delete table
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title) ],
  field_attr => {
    -defaults => { type => 'display' },
    emp_id => { type => 'static' },
  },
});
report $form, "simple2";
is($form, $result{simple2}, "simple delete");


# arch-tag: dae0b8ad-eb1d-43bd-8442-cc5956fc3460
