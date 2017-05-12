use strict ;
use IO::Handle ;

use Test::More tests => 59 ;
BEGIN { use_ok('IO::Mux') } ;
BEGIN { use_ok('IO::Mux::Handle') } ;

pipe(R, W) ;

my $mr = new IO::Mux(\*R) ;
is($mr->get_handle(), \*R) ;
my $mw = new IO::Mux(*W{IO}) ;
is($mw->get_handle(), *W{IO}) ;

my $rc = undef ;
my $r = new IO::Mux::Handle($mr) ;
my $w = new IO::Mux::Handle($mw) ;
$rc = $r->open(1) ;
is($rc, 1) ;
$rc = $w->open(1) ;
is($rc, 1) ;

# Type testing
ok($r->isa('IO::Mux::Handle')) ;

my $buf = undef ;

# One packet tests
$rc = print $w "test1" ;
is($rc, 5) ;
$buf = '' ;
$rc = sysread($r, $buf, 4) ;
is($rc, 4) ;
is($buf, 'test') ;

# Read the numbers
$buf = '' ;
$rc = sysread($r, $buf, 1) ;
is($rc, 1) ;
is($buf, 1) ;

# Read lines
print $w "line1\n" ;
is(<$r>, "line1\n") ;
# Setting $/ ;
print $w "line1" ;
print $w "line2" ;
print $w "line3*" ;
print $w "line4*" ;
print $w "line5*" ;
print $w "line6*" ;
{
	local $/ = '*' ;
	is(<$r>, "line1line2line3*") ;
}
# Slurping
close($w) ;
{
	local $/ = undef ;
	is(<$r>, "line4*line5*line6*") ;
}
$rc = $r->open(1) ;
is($rc, 1) ;
$rc = $w->open(1) ;
is($rc, 1) ;
print $w "line1\n" ;
print $w "line2\n" ;
close($w) ;
$buf = join('', <$r>) ;
is($buf, "line1\nline2\n") ;
is(<$r>, undef) ;
$buf = join('', <$r>) ;
is(<$r>, undef) ;
close($r) ;

# Invalid Data
$rc = $r->open(1) ;
is($rc, 1) ;
$rc = print W "123456" ; # 6 is exactly the length of the header
ok($rc) ;
is(<$r>, undef) ;
like($r->get_error(), qr/mismatch/) ;
close($r) ;

# Reads that span multiple packets.
$rc = $r->open(1) ;
is($rc, 1) ;
$rc = $w->open(1) ;
is($rc, 1) ;
$rc = print $w "p11" ;
is($rc, 3) ;
$rc = print $w "p21" ;
is($rc, 3) ;

$buf = '' ;
$rc = sysread($r, $buf, 8) ;
is($rc, 6) ;
is($buf, 'p11p21') ;

# We are done.
$rc = close($w) ;
is($rc, 1) ;
# Close again
$rc = close($w) ;
is($rc, 0) ;

# Read from EOF handle
$buf = '' ;
$rc = sysread($r, $buf, 1) ;
is($rc, 0) ;
ok(eof($r)) ;
# Read from EOF handle again
$buf = '' ;
$rc = sysread($r, $buf, 1) ;
is($rc, 0) ;
ok(eof($r)) ;

# Read from closed handle
$rc = close($r) ;
ok($rc) ;
ok(eof($r)) ;
$rc = close($r) ;
ok(! $rc) ;
$rc = sysread($r, $buf, 1) ;
is($rc, undef) ;
is(<$r>, undef) ;

# Print to closed handle
$rc = print $w "test" ;
is($rc, undef) ;
# Print to read-only handle
$rc = print $r "test" ;
is($rc, undef) ;


# Use standard open to re-open using same handle
$rc = open($r, 1) ;
is($rc, 1) ;
$rc = open($w, 1) ;
ok($rc) ;
$buf = "reopened\n" ;
$rc = syswrite($w, $buf, length($buf) - 2, 2) ;
is($rc, length($buf) - 2) ;
is(<$r>, "opened\n") ;


# Failed re-open
my $r2 = $mr->new_handle() ;
$rc = $r2->open(1) ;
is($rc, undef) ;
like($r2->get_error(), qr/already in use/) ;


# Various system calls
$r->open('id') ;
$rc = tell($r) ;
is($rc, 0) ;
$rc = seek($r, 5, 1) ;
is($rc, 0) ;
$rc = binmode($r) ;
is($rc, 1) ;
$rc = fileno($r) ;
is($rc, 'id') ;

# Handle not opened
$r2 = $mr->new_handle() ;
$rc = print $r2 "test" ;
is($rc, undef) ;

# Close on real handle
close(W) ;
is(<$r>, undef) ;

close($r) ;
# Various system calls on closed handle
$rc = tell($r) ;
is($rc, -1) ;
$rc = seek($r, 5, 1) ;
is($rc, 0) ;
$rc = binmode($r) ;
is($rc, undef) ;
$rc = fileno($r) ;
is($rc, 'id') ;


