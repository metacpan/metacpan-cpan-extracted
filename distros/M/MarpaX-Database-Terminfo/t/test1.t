#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Database::Terminfo' ) || print "Bail out!\n";
}

my $terminfo = MarpaX::Database::Terminfo->new();
my $buffer = do {local $/; <DATA>;};
ok(defined($terminfo->parse(\$buffer)->value()), "Marpa parsing of ansi/pc-term compatible with color");

__DATA__
ansi|ansi/pc-term compatible with color,
	mc5i,
	colors#8, ncv#3, pairs#64,
	cub=\E[%p1%dD, cud=\E[%p1%dB, cuf=\E[%p1%dC,
	cuu=\E[%p1%dA, dch=\E[%p1%dP, dl=\E[%p1%dM,
	ech=\E[%p1%dX, el1=\E[1K, hpa=\E[%p1%dG, ht=\E[I,
	ich=\E[%p1%d@, il=\E[%p1%dL, indn=\E[%p1%dS, .indn=\E[%p1%dT,
	kbs=^H, kcbt=\E[Z, kcub1=\E[D, kcud1=\E[B,
	kcuf1=\E[C, kcuu1=\E[A, kf1=\E[M, kf10=\E[V,
	kf11=\E[W, kf12=\E[X, kf2=\E[N, kf3=\E[O, kf4=\E[P,
	kf5=\E[Q, kf6=\E[R, kf7=\E[S, kf8=\E[T, kf9=\E[U,
	kich1=\E[L, mc4=\E[4i, mc5=\E[5i, nel=\r\E[S,
	op=\E[37;40m, rep=%p1%c\E[%p2%{1}%-%db,
	rin=\E[%p1%dT, s0ds=\E(B, s1ds=\E)B, s2ds=\E*B,
	s3ds=\E+B, setab=\E[4%p1%dm, setaf=\E[3%p1%dm,
	setb=\E[4%?%p1%{1}%=%t4%e%p1%{3}%=%t6%e%p1%{4}%=%t1%e%p1%{6}%=%t3%e%p1%d%;m,
	setf=\E[3%?%p1%{1}%=%t4%e%p1%{3}%=%t6%e%p1%{4}%=%t1%e%p1%{6}%=%t3%e%p1%d%;m,
	sgr=\E[0;10%?%p1%t;7%;%?%p2%t;4%;%?%p3%t;7%;%?%p4%t;5%;%?%p6%t;1%;%?%p7%t;8%;%?%p8%t;11%;%?%p9%t;12%;m,
	sgr0=\E[0;10m, tbc=\E[2g, u6=\E[%d;%dR, u7=\E[6n,
	u8=\E[?%[;0123456789]c, u9=\E[c, vpa=\E[%p1%dd,
