# Simple dataset handling

use strict;
use Test::More tests => 8;
use FindBin qw($Bin);
BEGIN { use_ok( 'HTML::Tabulate' ) }

# Load result strings
my %result = ();
my $test = "$Bin/t1";
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

my $t = HTML::Tabulate->new();

# Simple hashref
my $d = { emp_id => '123', name => 'Fred Flintstone', title => 'CEO' };
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

