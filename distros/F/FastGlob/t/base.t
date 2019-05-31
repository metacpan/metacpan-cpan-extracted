#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FastGlob ();

ok( FastGlob->can('glob'),        'can glob' );
ok( FastGlob->can('recurseglob'), 'can recurseglob' );

sub globtest(;$) {

    my ( @t0, @t1, $udiffm, $sdiffm, $udiffg, $sdiffg, @list1, @list2 );
    local ($,);
    my $res = 1;

    $, = " ";
    while (<DATA>) {
        chomp;

        note "pattern: $_\n";
        if ( $_ =~ m{^\s#} ) {
          note " test skipped... TODO";
        }

        @t0     = times();
        @list1  = FastGlob::glob($_);
        @t1     = times();

        $udiffm = ( $t1[0] + $t1[2] ) - ( $t0[0] + $t0[2] );
        $sdiffm = ( $t1[1] + $t1[3] ) - ( $t0[1] + $t0[3] );

        @t0     = times();
        @list2  = glob($_);
        @t1     = times();
        $udiffg = ( $t1[0] + $t1[2] ) - ( $t0[0] + $t0[2] );
        $sdiffg = ( $t1[1] + $t1[3] ) - ( $t0[1] + $t0[3] );

        is(  join( ' ', sort(@list1) ), join( ' ', sort(@list2) ), 'results match for '.join( ' ', @list1 ) )
          or diag "GOT: ", explain \@list1, "EXPECT: ", explain \@list2;

        note "mine: [${udiffm}u\t${sdiffm}s]";
        note "glob: [${udiffg}u\t${sdiffg}s]\n";
    }
}

globtest();

pass 'done';

done_testing;

__DATA__
*
*[Gg]lob*
./*
./*[Gg]lob*
#[^F]*
../*
../../.p*
#~mengel
#~lisa
bogus{1,2,3}
#~{mengel,lisa}/../{me,li}*
#/*/tmp/*x*
/afs/fnal/products/*/ftt
/usr/tmp/*
/usr//tmp/*
.././*.c
????????.??*
{ou,????????.??}*
