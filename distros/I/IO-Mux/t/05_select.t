use strict ;

use Test::More tests => 37 ;
BEGIN { use_ok('IO::Mux::Select') } ;

use IO::Mux ;
use Socket ;

socketpair(R, W, PF_UNIX, SOCK_STREAM, PF_UNSPEC) ;

my $mr = new IO::Mux(\*R) ;
my $mw = new IO::Mux(\*W) ;
my $rc = undef ;
my $buf = undef ;

my $r1 = $mr->new_handle() ;
$rc = $r1->open(1) ;
is($rc, 1) ;
my $r2 = $mr->new_handle() ;
$rc = $r2->open(2) ;
is($rc, 1) ;
my $w1 = $mw->new_handle() ;
$rc = $w1->open(1) ;
is($rc, 1) ;
my $w2 = $mw->new_handle() ;
$rc = $w2->open(2) ;
is($rc, 1) ;

my @ready = () ;
my $h = undef ;
my $ims = new IO::Mux::Select() ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 0) ;

$ims->add($r1) ;
ok($ims->exists($r1)) ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 0) ;

print $w1 "data\n" ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
is($ready[0], $r1) ;
$buf = 'a' ;
$rc = read($r1, $buf, 2, 1) ;
is($rc, 2) ;
is($buf, 'ada') ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
is($ready[0], $r1) ;
is(<$r1>, "ta\n") ;

# 2 handles
$ims->add($r2) ;
ok($ims->exists($r2)) ;
is($ims->count(), 2) ;
print $w1 "test1\n" ;
print $w2 "test2\n" ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 2) ;
is(<$r1>, "test1\n") ;
is(<$r2>, "test2\n") ;

# EOF
close($w1) ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
# Again?
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
$ims->remove($r1) ;
ok(! $ims->exists($r1)) ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 0) ;

# Add real handle
socketpair(RR, RW, PF_UNIX, SOCK_STREAM, PF_UNSPEC) ;
RW->autoflush(1) ;
$ims->add(\*RR) ;
ok($ims->exists(\*RR)) ;
is($ims->count(), 2) ;
print RW "testr\n" ;
print $w2 "test2\n" ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 2) ;
is(<$r2>, "test2\n") ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
is(<RR>, "testr\n") ;
close(RW) ;

@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
# Again EOF...
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;

$ims->remove(\*RR) ;
ok(! $ims->exists(\*RR)) ;
$ims->remove(\*RR) ; # coverage
@ready = $ims->can_read(0) ;

is(scalar(@ready), 0) ;
is($ims->count(), 1) ;

# Test EOF of the real handle
close(W) ;
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;
# Again
@ready = $ims->can_read(0) ;
is(scalar(@ready), 1) ;

