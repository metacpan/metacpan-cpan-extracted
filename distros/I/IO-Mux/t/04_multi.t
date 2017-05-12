use strict ;
use IO::Handle ;

use Test::More tests => 28 ;
BEGIN { use_ok('IO::Mux') } ;
BEGIN { use_ok('IO::Mux::Handle') } ;

pipe(R, W) ;

my $mr = new IO::Mux(\*R) ;
my $mw = new IO::Mux(\*W) ;
my $buf = undef ;
my $rc = undef ;

my $r1 = new IO::Mux::Handle($mr) ;
$rc = open($r1, 1) ;
is($rc, 1) ;
my $r2 = new IO::Mux::Handle($mr) ;
$rc = open($r2, 2) ;
is($rc, 1) ;
my $w1 = new IO::Mux::Handle($mw) ;
$rc = open($w1, 1) ;
is($rc, 1) ;
my $w2 = new IO::Mux::Handle($mw) ;
$rc = open($w2, 2) ;
is($rc, 1) ;

# One packet tests
$rc = print $w1 "test1" ;
is($rc, 5) ;
$rc = print $w2 "test2" ;
is($rc, 5) ;

$buf = '' ;
$rc = sysread($r1, $buf, 4) ;
is($rc, 4) ;
is($buf, 'test') ;
$buf = '' ;
$rc = sysread($r2, $buf, 4) ;
is($rc, 4) ;
is($buf, 'test') ;

# Read the numbers
$buf = '' ;
$rc = sysread($r1, $buf, 1) ;
is($rc, 1) ;
is($buf, 1) ;
$buf = '' ;
$rc = sysread($r2, $buf, 1) ;
is($rc, 1) ;
is($buf, 2) ;

# Read lines
print $w1 "line1\n" ;
print $w2 "line2\n" ;
is(<$r1>, "line1\n") ;
is(<$r2>, "line2\n") ;

# Reads that span multiple packets.
print $w1 "p11" ;
print $w2 "p12" ;
print $w1 "p21" ;
print $w2 "p22" ;

$buf = '' ;
$rc = sysread($r1, $buf, 6) ;
is($rc, 6) ;
is($buf, 'p11p21') ;
$rc = close($w1) ;
is($rc, 1) ;

$buf = '' ;
$rc = sysread($r2, $buf, 6) ;
is($rc, 6) ;
is($buf, 'p12p22') ;
$rc = close($w2) ;
is($rc, 1) ;

# Read EOF
$buf = '' ;
$rc = sysread($r1, $buf, 1) ;
is($rc, 0) ;
ok(eof($r1)) ;
$buf = '' ;
$rc = sysread($r2, $buf, 1) ;
is($rc, 0) ;
ok(eof($r2)) ;

