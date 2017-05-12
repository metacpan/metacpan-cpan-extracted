# Link tests

use Test::More tests => 2;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't04';
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

my $d = { emp_id => '123', emp_name => 'Fred Flintstone', 
  emp_title => 'CEO', addr_id => '225', emp_birth_dt => '20-10-55',
  emp_salutation => 'Sir' };
# Add some base link arguments e.g for a Tabulate table
my $f = HTML::Formulate->new({
  field_attr => {
    emp_id => {
      link => 'emp.html?id=%s',
      label_link => 'me.html?sort=emp_id',
    },
    addr_id => {
      type => 'display',
      link => 'addr.html?id=%s',
    },
  },
});

# Minimal edit table
my $form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt addr_id) ],
});
# print $form, "\n";
is($form, $result{links}, "link handling");
