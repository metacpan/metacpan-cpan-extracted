# 'required' presentation tests

use Test::More tests => 9;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't05';
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

my $d = { emp_id => '123', emp_name => 'Fred Flintstone', 
  emp_title => 'CEO', addr_id => '225', emp_birth_dt => '20-10-55',
  emp_salutation => 'Sir' };
# Add some base link arguments e.g for a Tabulate table
my $f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  required => [ qw(emp_name emp_title) ],
  field_attr => {
    emp_id => { type => 'hidden' },
  },
});

# Default required formatting
my $form = $f->render($d);
report $form, "req1";
is($form, $result{req1}, "default th required");

# Explicit required formatting 1
$form = $f->render($d, {
  field_attr => {
    -required => { th => { class => 'blue' }, label_format => '%s', },
  },
});
report $form, "req2";
is($form, $result{req2}, "explicit th required");

# Explicit required formatting 2
$form = $f->render($d, {
  field_attr => {
    -required => { label_format => '%s [*]' },
  },
});
report $form, "req3";
is($form, $result{req3}, "explicit required string marker");

# Turn off required formatting
$form = $f->render($d, {
  field_attr => {
    -required => { th => {}, label_format => '%s' },
  },
});
report $form, "no_required";
is($form, $result{no_required}, "turn off required markup");

# Bad required arg
ok(! defined eval { $form = $f->render($d, { required => {} }) }, 
  "die on bad required arg");

# Required scalar
$form = $f->render($d, {
  required => 'emp_name',
});
report $form, "req_scalar";
is($form, $result{req_scalar}, "scalar required - emp_name");

# Required scalar ALL
$form = $f->render($d, {
  required => 'ALL',
});
report $form, "req_scalar_all";
is($form, $result{req_scalar_all}, "scalar required - ALL");

# Required scalar ALL
$form = $f->render($d, {
  required => 'NONE',
});
report $form, "req_scalar_none";
is($form, $result{req_scalar_none}, "scalar required - NONE");

# Required handling of displays - TODO
$form = $f->render($d, {
  required => 'ALL',
  field_attr => { 
    emp_birth_dt => { type => 'display' },
  },
});
# report $form, "req_scalar_all";
# is($form, $result{req_scalar_all}, "scalar required - ALL");

# arch-tag: 4473bda7-ee03-4e97-8850-91d9be789581
