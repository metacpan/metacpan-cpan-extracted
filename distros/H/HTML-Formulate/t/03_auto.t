# Auto field tests

use Test::More tests => 1;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't3';
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

my $t = HTML::Formulate->new();
my $d = { emp_id => '123', emp_name => 'Fred Flintstone', 
  emp_title => 'CEO', emp_addr_id => '225', emp_birth_dt => '20-10-55',
  emp_modify_uid => 12, emp_modify_ts => 20031231, 
  emp_create_uid => 6,  emp_create_ts => 20020804,
};

# Minimal edit table
print($t->render($d, {
  form => { name => 'new' },
  formtype => 'new',
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt
    emp_modify_ts emp_modify_uid emp_create_ts emp_create_uid) ],
  field_attr => {
    qr/_ts$/ => {
      type => 'omit',
    },
    qr/_uid$/ => {
      type => 'omit',
    },
  }
}));

# Minimal edit table
print($t->render($d, {
  form => { name => 'edit' },
  formtype => 'edit',
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt
    emp_modify_ts emp_modify_uid emp_create_ts emp_create_uid) ],
  field_attr => {
    qr/_ts$/ => {
      type => 'omit',
    },
    qr/_uid$/ => {
      type => 'omit',
    },
  }
})) if 0;
