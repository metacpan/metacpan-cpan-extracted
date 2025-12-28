#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;

my $str = 'H-H	432
N-H 	391
I-I 	149
C=C 	614
H-F 	565
N-N 	160
I-Cl 	208
C≡C 	839
H-Cl 	427
N-F 	272
I-Br 	175
O=O 	495
H-Br 	363
N-Cl 	200
C=O* 	745
H-I 	295
N-Br 	243
S-H 	347
C≡O 	1072
N-O 	201
S-F 	327
N=O 	607
C-H 	413
O-H 	467
S-Cl 	253
N=N 	418
C-C 	347
O-O 146
S-Br 	218
N≡N 	941
C-N 	305
O-F 190
S-S 	266
C≡N 	891
C-O 	358
O-Cl 	203
C=N 	615
C-F 	485
O-I 	234
Si-Si 	340
C-Cl 	339
Si-H 	393
C-Br 	276
F-F 	154
Si-C 	360
C-I 	240
F-Cl 	253
Si-O 	452
C-S 	259
F-Br 	237
Cl-Cl 	239
Cl-Br 	218
Br-Br 	193';
my %bond_dissociation = (
    Br =>  {
        Br =>  193
    },
    C  =>  {
        Br =>  276,
        C  =>  347,
        Cl =>  339,
        F   => 485,
        H  =>  413,
        I  =>  240,
        N  =>  305,
        O  =>  358,
        S  =>  259
    },
    Cl =>  {
        Br =>  218,
        Cl =>  239
    },
    F =>   {
        Br =>  237,
        Cl  => 253,
        F   => 154
    },
    H  =>  {
        Br =>  363,
        Cl =>  427,
        F  =>  565,
        H   => 432,
        I   => 295
    },
    I  =>  {
        Br  => 175,
        Cl =>  208,
        I  =>  149
    },
    N  =>  {
        Br =>  243,
        Cl  => 200,
        F   => 272,
        H  =>  391,
        N  =>  160,
        O  =>  201
    },
    O =>   {
        Cl =>  203,
        F  =>  190,
        H  =>  467,
        I  =>  234,
        O  =>  146
    },
    S  =>  {
        Br => 218,
        Cl => 253,
        F  => 327,
        H  => 347,
        S  => 266
    },
    Si => {
        C  =>  360,
        H  => 393,
        O  => 452,
        Si => 340
    }
);
=my @l = split /\n/, $str;
foreach my $l (grep {/\-/} @l) {
	p $l;
	my $bond;
	if ($l =~ m/([\-=≡])/) {
		$bond = $1;
	} else {
		die "$l failed regex.";
	}
	my @line = split /\h+/, $l;
	my @atom = grep {$_ ne ''} split /\h*[-=≡]\h*/, $line[0];
	$bond_dissociation{$atom[0]}{$atom[1]} = $line[1];
#	$bond_dissociation{$atom[1]}{$atom[0]} = $line[1];
}
=cut
colored_table({
	data          => \%bond_dissociation,
	cblabel       => 'Average Dissociation Energy (kJ/mol)',
	'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
	mirror        => 1,
	'output.file' => '/tmp/single.bonds.svg',
	'row.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
	'show.numbers'=> 1,
#	'undef.color' => 'gray'
});
