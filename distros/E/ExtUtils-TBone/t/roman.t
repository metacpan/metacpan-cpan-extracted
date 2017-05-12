use ExtUtils::TBone;
use strict;  

### START REAL TEST:
my $T = typical ExtUtils::TBone;
$T->begin(3);

# Setup simulated test files:  
my $tlog = "./testout/roman-sim.tlog";
my $tout = "./testout/roman-sim.tout";
open TOUT, ">$tout" or die "open $tout: $!";

# 1: Create simulated test object:
my $ST = new ExtUtils::TBone ">$tlog";
$T->ok($ST, "Created ST",
       TLOG => $tlog,
       TOUT => $tout);
$ST->{OUT} = \*TOUT;

# 2: Run simulated test:
$ST->begin(3);
$ST->msg("before 1\nor 2");
$ST->ok(1, "one");
$ST->ok(1, "Two");
$ST->ok(1, "Three", 
	Roman  =>'III',
	Arabic =>[3, '03'], 
	Misc   =>"3\nor 3");
$ST->ok(0, "This failed",
	Why    => 'dunno');
$ST->end;
$T->ok(1, "Ran simulated test");
close TOUT;

# 3: Examine output:
my $expect_out = <<EOF;
1..3
ok 1
ok 2
ok 3
not ok 4
# END
EOF
open TOUT, "<$tout" or die "open $tout: $!";
my $got_out = join '', <TOUT>;
close TOUT;
$T->ok($expect_out eq $got_out, 
       "Check simulated output",
       Expected => $expect_out,
       Got      => $got_out);

### END REAL TEST:
$T->end;




