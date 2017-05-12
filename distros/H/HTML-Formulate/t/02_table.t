# formtype => 'table' testing

use Test::More tests => 8;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't02';
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

my $t = HTML::Formulate->new({ formtype => 'table' });
my $d = { emp_id => '123', name => 'Fred Flintstone', title => 'CEO' };

# The following tests straight from Tabulate/t/01_data.t
# Minimal edit table
is($t->render($d), $result{fred}, 'simple hashref');

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



# arch-tag: eba35ad3-7673-42fe-8ef6-8b3ae7358b95

