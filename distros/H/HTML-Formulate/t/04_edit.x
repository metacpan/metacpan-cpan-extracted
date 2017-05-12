# Simple dataset handling

use Test::More tests => 5;
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
  emp_salutation => 'Sir' };

# Minimal edit table
print($t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt) ],
})) if 0;
is($t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt) ],
}), $result{render1}, 'edit1, minimal');
is($t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt) ],
  xhtml => undef,
}), $result{render1b}, 'edit1, minimal, no xhtml');
is($t->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_addr_id emp_birth_dt) ],
  submit => undef,
}), $result{render1c}, 'edit1, minimal no submit');
is($t->render($d, {
  fields => [ qw(emp_id emp_salutation emp_name emp_title emp_addr_id emp_birth_dt) ],
  submit => [ qw(save cancel) ],
  field_attr => {
    -submit => {
      name => 'op',
    },
    emp_addr_id => { type => 'display' },
    emp_birth_dt => { type => 'hidden' },
    emp_id => {
      format => 'E%d',
    },
    emp_salutation => {
      type => 'select',
      datatype => [ qw(NONE Mr Ms Mrs Miss Dr Sir Prof) ],
      vlabels => { NONE => 'None', Prof => 'Professor' },
    },
  },
}), $result{render2}, 'edit2, medium');



exit;
# Nested arrayrefs
$d = [ [ '123', 'Fred Flintstone', 'CEO' ] ];
is($t->render($d), $result{fred}, 'nested arrayrefs1');
$d = [ [ '123', 'Fred Flintstone', 'CEO' ], [ '456', 'Barney Rubble', 'Lackey' ] ];
is($t->render($d), $result{fredbarney}, "nested arrayrefs2");
$d = [ [ '123', 'Fred Flintstone', 'CEO' ], 
       [ '456', 'Barney Rubble', 'Lackey' ],
       [ '789', 'Wilma Flintstone   ', 'CFO' ], 
       [ '777', 'Betty Rubble', '' ], ];
is($t->render($d), $result{fbwb}, "nested arrayrefs4");

# Nested hashrefs
$d = [ { emp_id => '123', name => 'Fred Flintstone', title => 'CEO' } ];
is($t->render($d), $result{fred}, "nested hashrefs1");
$d = [ { emp_id => '123', name => 'Fred Flintstone', title => 'CEO' }, 
       { emp_id => '456', name => 'Barney Rubble', title => 'Lackey' }, ];
is($t->render($d), $result{fredbarney}, "nested hashrefs2");
$d = [ { emp_id => '123', name => 'Fred Flintstone', title => 'CEO' }, 
       { emp_id => '456', name => 'Barney Rubble', title => 'Lackey' },
       { emp_id => '789', name => 'Wilma Flintstone   ', title => 'CFO' },
       { emp_id => '777', name => 'Betty Rubble', title => '' }, ];
is($t->render($d), $result{fbwb}, "nested hashrefs4");




# arch-tag: 7ae7c6d8-938a-4b25-a061-c8bf1700a8b1
