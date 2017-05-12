#!/usr/bin/perl

package Lab::Data::PDL;
our $VERSION = '3.542';

use strict;
use PDL;

sub DATA_to_cols {

    # filename von datenfile als argument
    # gibt spalten als einzelne listen
    # also matrix, die genauso aussieht, wie das file
    # blöcke nicht aufgelöst
    my @cols   = rcols shift;
    my $piddle = cat @cols;
    return $piddle;
}

sub DATA_to_matrix {
    my $filename = shift;
    my @zeilen;
    my @xvalues;
    my @yvalues;
    open IN, "<$filename" or die "file not found: $filename";
    my $blocknum = 0;
    my $linenum  = 0;
    my $numlines;
    my $started = 0;

    #   0 - nicht gestartet: leerzeilen ignorieren, dann 1
    #   1 - gestartet: ersten block lesen (1 zeilenname, alle yvalues), dann 2
    #   2 - neuer block gestartet: 1 zeilenname lesen; spaltenname vergleichen, dann 3
    #   3 - innerhalb block größer erstem: spalten- und zeilenname vergleichen
    while (<IN>) {
        chomp;
        if (/^\s*$/) {

            #leerzeile => neuer block
            if ($started) {
                warn
                    "Letzter Block hatte falsche Zeilenzahl: $linenum statt $numlines"
                    unless ( $numlines == $linenum - 1 );
                $started = 2;
                $blocknum++;
                $linenum = 0;
            }
        }
        elsif (/^([\d\-+\.Ee]+\t?)+$/) {
            my @value = split "\t";
            my ( $spaltenname, $zeilenname ) = ( shift @value, shift @value );

            #print "$spaltenname  ***  $zeilenname\n";

            $started = 1 unless $started;
            if ( $started == 3 ) {
                warn
                    "Nicht rechteckig: In Block $blocknum, Zeile $linenum ist erste Spalte $spaltenname anstatt $yvalues[$blocknum]"
                    unless ( $yvalues[$blocknum] == $spaltenname );
            }
            if ( $started > 1 ) {
                warn
                    "Nicht rechteckig: In Block $blocknum, Zeile $linenum ist die zweite Spalte $zeilenname anstatt $xvalues[$linenum]"
                    unless ( $xvalues[$linenum] == $zeilenname );
            }
            if ( $started < 3 ) {
                $yvalues[$blocknum] = $spaltenname;
            }
            $started = 3 if ( $started == 2 );
            if ( $started == 1 ) {
                $xvalues[$linenum] = $zeilenname;
                $numlines = $linenum;
            }
            push( @{ $zeilen[$blocknum] }, [@value] );
            $linenum++;
        }
        else {
            # kommentarzeile oder sonst was
        }
    }
    close IN;
    my $ma = pdl [@zeilen];
    my $zn = pdl(@xvalues);
    my $sn = pdl(@yvalues);
    return ( $ma, $zn, $sn );
}

sub matrix_to_DATA {
    my ( $filename, $matrix, $xvalues, $yvalues ) = @_;
    open OUT, ">$filename" or die;

    my $xl = $xvalues->nelem();
    my $yl = $yvalues->nelem();

    for ( my $blocknum = 0; $blocknum < $yl; $blocknum++ ) {
        my $s1 = $yvalues->at($blocknum) * ones($xl);
        my $s2 = $xvalues;
        my $s3 = $matrix->slice(":,:,($blocknum)");

        my @s3s;
        for ( 0 .. ( -1 + $s3->dim(0) ) ) {
            push( @s3s, $s3->slice("($_),:") );
        }

        wcols $s1, $s2, @s3s, *OUT;
        print OUT "\n";
    }
    close OUT;
}

sub import_gpplus {

    #should not be used
    #just for the memory
    my $basename = shift;
    $basename =~ s/_$//;

    my @files = sort {
        ( $a =~ /$basename\_(\d+)\.TSK/ )[0]
            <=> ( $b =~ /$basename\_(\d+)\.TSK/ )[0]
    } glob $basename . "_*.TSK";
    ( my $path ) = ( $basename =~ m{((/?[^/]+/)+)?[^/]+$} )[0];
    $basename =~ s{(/?[^/]+/)+}{};

    my $cols;
    my $blocknum = -1;
    for (@files) {
        $blocknum++;
        print "\rProcessing file: $_    ";
        my @fcols;
        open IN, "<$_" or die $!;
        while ( <IN> !~ /DATA MEASURED/ ) { }
        while (<IN>) {
            s/[\n\r]+$//g;
            my @values = split ";";
            for ( 0 .. $#values ) {
                push( @{ $fcols[$_] }, $values[$_] );
            }
        }
        for my $colnum ( 0 .. $#fcols ) {
            $cols = zeroes(
                scalar @fcols,
                scalar @files,
                scalar @{ $fcols[$colnum] }
            ) unless ( defined $cols );
            ( my $pdl = $cols->slice("$colnum,($blocknum),:") )
                .= pdl( @{ $fcols[$colnum] } )
                ->reshape( 1, scalar @{ $fcols[$colnum] } );
        }
        close IN;
    }
    print $cols->info("\rDim: %D Memory: %M                         \n");
    return $cols;
}

sub coord_transform {
    my ( $piddle, $o, $t ) = @_;

    # performs a coordinate transform
    # of the $piddle (in place)
    # the piddle is assumed to be in column-ordered style
    # as created by TSKload
    #
    # ^a_i is the basis of the old columns
    # ^b_i is the basis of the new columns
    #
    # you supply the coefficients to
    # express ^b in terms of ^a:
    # @t=(t_11,t_12,...,t_21,t_22,...,t_nn)
    # with ^b_i = sum_j t_ij ^a_j
    #
    # example:
    # 3 columns named x,y,color
    # transform data to a new coordinate system
    # xx = 4  +   0.3 * x  +  0.1 * y  +  0 * color
    # yy = 5  +  -0.2 * x  +  1.8 * y  +  0 * color
    # cc = 0  +  0         +  0        +  1 * color
    # ($piddle,
    #   [ 4   , 5   , 0 ],
    #   [ 0.3 , 0.1 , 0 ,
    #    -0.2 , 1.8 , 0 ,
    #     0   , 0   , 1 ]
    # )
    my $off   = pdl($o);
    my $mat   = pdl($t)->reshape( sqrt(@$t), sqrt(@$t) );
    my $lines = $piddle->clump( 2, 3 );
    $lines = $off + $mat * $lines;
}

1;
