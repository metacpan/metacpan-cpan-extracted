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
ok($terminfo->parse(\$buffer)->value(), "Marpa parsing of AT&T610;80column;98key keyboard");

__DATA__
610|610bct|ATT610|att610|AT&T610;80column;98key keyboard,
              am, eslok, hs, mir, msgr, xenl, xon,
              cols#80, it#8, lh#2, lines#24, lw#8, nlab#8, wsl#80,
              acsc=``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~,
              bel=^G, blink=\E[5m, bold=\E[1m, cbt=\E[Z,
              civis=\E[?25l, clear=\E[H\E[J, cnorm=\E[?25h\E[?12l,
              cr=\r, csr=\E[%i%p1%d;%p2%dr, cub=\E[%p1%dD, cub1=\b,
              cud=\E[%p1%dB, cud1=\E[B, cuf=\E[%p1%dC, cuf1=\E[C,
              cup=\E[%i%p1%d;%p2%dH, cuu=\E[%p1%dA, cuu1=\E[A,
              cvvis=\E[?12;25h, dch=\E[%p1%dP, dch1=\E[P, dim=\E[2m,
              dl=\E[%p1%dM, dl1=\E[M, ed=\E[J, el=\E[K, el1=\E[1K,
              flash=\E[?5h$<200>\E[?5l, fsl=\E8, home=\E[H, ht=\t,
              ich=\E[%p1%d@, il=\E[%p1%dL, il1=\E[L, ind=\ED, .ind=\ED$<9>,
              invis=\E[8m,
              is1=\E[8;0 | \E[?3;4;5;13;15l\E[13;20l\E[?7h\E[12h\E(B\E)0,
              is2=\E[0m^O, is3=\E(B\E)0, kLFT=\E[\s@, kRIT=\E[\sA,
              kbs=^H, kcbt=\E[Z, kclr=\E[2J, kcub1=\E[D, kcud1=\E[B,
              kcuf1=\E[C, kcuu1=\E[A, kfP=\EOc, kfP0=\ENp,
              kfP1=\ENq, kfP2=\ENr, kfP3=\ENs, kfP4=\ENt, kfI=\EOd,
              kfB=\EOe, kf4=\EOf, kf(CW=\EOg, kf6=\EOh, kf7=\EOi,
              kf8=\EOj, kf9=\ENo, khome=\E[H, kind=\E[S, kri=\E[T,
              ll=\E[24H, mc4=\E[?4i, mc5=\E[?5i, nel=\EE,
              pfxl=\E[%p1%d;%p2%l%02dq%?%p1%{9}%<%t\s\s\sF%p1%1d\s\s\s\s\s\s\s\s\s\s\s%;%p2%s,
              pln=\E[%p1%d;0;0;0q%p2%:-16.16s, rc=\E8, rev=\E[7m,
              ri=\EM, rmacs=^O, rmir=\E[4l, rmln=\E[2p, rmso=\E[m,
              rmul=\E[m, rs2=\Ec\E[?3l, sc=\E7,
              sgr=\E[0%?%p6%t;1%;%?%p5%t;2%;%?%p2%t;4%;%?%p4%t;5%;%?%p3%p1%|%t;7%;%?%p7%t;8%;m%?%p9%t^N%e^O%;,
              sgr0=\E[m^O, smacs=^N, smir=\E[4h, smln=\E[p,
              smso=\E[7m, smul=\E[4m, tsl=\E7\E[25;%i%p1%dx,
