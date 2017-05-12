#!/usr/bin/perl -w

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.


use strict ;

use vars qw( $Loaded $Count $TestImage $DEBUG $TRIMWIDTH %File ) ;

BEGIN { 
    $| = 1 ; 
    print "1..19\n"
}
END   { print "not ok 1\n" unless $Loaded ; }

use File::Spec qw();
use File::Temp qw(tempdir);

use Image::Xpm ;
$Loaded = 1 ;
use Symbol () ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 256 ;

report( "loaded module ", 0, '', __LINE__ ) ;

my( $i, $j, $k ) ;
my $fp = tempdir(CLEANUP => 1);
die "Can't create tempory directory: $!" if !$fp;
$fp = File::Spec->catfile($fp, 'image-xpm');
 

eval {
    $i = Image::Xpm->new( -width => 4, -height => 5 ) ;
    for( my $x = 0 ; $x < 4 ; $x++ ) {
        for( my $y = 0 ; $y < 5 ; $y++ ) {
            $i->xy( $x, $y, sprintf "#%06x", $x * $y + 0xf000 * $y ) ;
        }
    }
    die "Failed to create image correctly"
    unless $i->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

eval {
    $j = $i->new ;
    die "Failed to create image correctly" unless
    $j->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

eval {
    $i->save( "$fp-test1.xbm" ) ;
    die "Failed to save image" unless -e "$fp-test1.xbm" ;
} ;
report( "save()", 0, $@, __LINE__ ) ;

eval {
    $i = undef ;
    die "Failed to destroy image" if defined $i ;
    $i = Image::Xpm->new( -file => "$fp-test1.xbm" ) ;
    die "Failed to load image correctly" 
    unless $i->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "load()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -file ) eq "$fp-test1.xbm" ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -width ) == 4 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -height ) == 5 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die "xy(0,0) ne #000000" unless $i->xy( 0, 0 ) eq '#000000';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "vec(0) ne #000000" unless $i->vec( 0 ) eq '#000000';
} ;
report( "vec() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(1,2) ne #01e002" unless $i->xy( 1, 2 ) eq '#01e002';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "vec(9) ne #01e002" unless $i->vec( 9 ) eq '#01e002';
} ;
report( "vec() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(3,1) ne #00f003" unless $i->xy( 3, 1 ) eq '#00f003';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "vec(7) ne #00f003" unless $i->vec( 7 ) eq '#00f003';
} ;
report( "vec() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(3,1,'violet') ne 4" unless $i->xy( 3, 1, 'violet' ) eq '4';
} ;
report( "xy() - set", 0, $@, __LINE__ ) ;

eval {
    die "vec(7) ne violet" unless $i->vec( 7 ) eq 'violet';
} ;
report( "vec() - get", 0, $@, __LINE__ ) ;

eval {
    die "vec(7, 'violet') ne 4" unless $i->vec( 7, 'violet' ) eq '4';
} ;
report( "vec() - set", 0, $@, __LINE__ ) ;

eval {
    my $file = "$fp-test2.xpm" ;
    my $fh = Symbol::gensym ;
    open $fh, ">$file" or die $! ;
    print $fh $TestImage ;
    close $fh ;
    $j = Image::Xpm->new( -file => $file ) ;
    my $pixels = $j->get( -pixels ) ;
    $file = "$fp-test3.xpm";
    $j->save( $file ) ;
    $j->load ;
    die "Failed to new/save/load correctly" 
    unless $j->get( -pixels ) eq $pixels ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

# Tests for Image::Base

eval {
    my $q = $i->new_from_image( ref $i, -cpp => 2 ) ;
    my $pixels = $q->get( -pixels ) ;
    $pixels =~ s/ //go ;
    $pixels =~ s/0/4/go ; # One colour was in the palette but unused (overwritten)
    die unless $pixels eq $i->get( -pixels ) ;
} ;
report( "new_from_image", 0, $@, __LINE__ ) ;



unlink( "$fp-test1.xbm", "$fp-test2.xpm", "$fp-test3.xpm" ) unless $DEBUG ;


sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}

BEGIN {
# This image was copied from the Perl/Tk distribution.
$TestImage = <<EOT ;
/* XPM */
static char * ColorEditor_xpm[] = {
"48 48 6 1",
" 	c #0000FFFF0000",
".	c #FFFFFFFF0000",
"X	c #FFFF00000000",
"o	c #000000000000",
"O	c #0000FFFFFFFF",
"+	c #00000000FFFF",
"                   . . ......X..XXXXXXXXXXXXXXXX",
"                      . .X.X. X...XX.XXXXXXXXXXX",
"                   .  . .  ... ...XXXXXXXXXXXXXX",
"                .   .    .. .....XX.XXXXXXXXXXXX",
"                    .   .X.X...XXX..XXXXXXXXXXXX",
"                       .. .  ....X...X.XXXXXXXXX",
"                       ..  ..X.. . ..X..XXXXXXXX",
"                          ....  ..X.X..X.XXXXXXX",
"                         ...  .X. X...X...XX.XXX",
"                     .    .. ... XX...XXXX..XXXX",
"      ooo o         ooo.   .  .. .X...X..X.XXXXX",
"    oo   oo          oo.    . .  . .......X.X.XX",
"    oo    o          oo   . . .. ........XX.XXXX",
"   oo         ooo   oo   ooo Xooo.oo..... X XX.X",
"   oo        o  oo  oo  o  oo  ooo o.. . X...X X",
"   oo       oo  oo  oo oo  oo .oo  . X.X.....XX ",
"O  oo     o oo  oo oo  oo  oo oo.  ...  X..... .",
"O O oo   oo oo  o  oo ooo  o. oo     . ... .X..X",
"O OOOooooO   ooo   ooo  ooo   oo  ... ....... X ",
"  O OOO                         .  . ..  ...  ..",
"OOO OOOO OO O                    . .... . . .. .",
" +  O  O   O  O                        .. .. . .",
"   O  OOO  OO                    .    ..   .... ",
"OOOOO    O   OO                  .   ..  .  ... ",
"+OOOO OOOO  OO    O                  ...   .. ..",
" O+OO OO      O                            .    ",
"OOOOOOOOoooooooOOOO  ooo  oo               .... ",
"OO++ OOO ooO OoOO     oo  oo  oo           ..   ",
"+OOOOOOOOooOOOo O O   oo      oo               .",
"++OOO   +oo+oOO O oo oo ooo ooooo  ooo  ooo oo. ",
"+OO O OOoooooO O o  ooo  oo  oo   o  oo  ooo o  ",
"++++ O OooOOoO Ooo  Ooo  oo  oo  oo  oo  oo     ",
"+++OOOO ooOOOoOOooOOooO oo  oo   oo  oo oo      ",
"++++++ Ooo OOoOOooOooo ooo ooo o oo  o  oo      ",
"+++O+++oooooooOOOooOoooOooo ooo  Oooo   oo      ",
"++++++++O++OOOO   O OOOOOOO                     ",
"++O++++O+O+OOOOOOO O O OOOOOO  O                ",
"+++O+++OOO+OO OOOO O   OO  O O O                ",
"++++++++O++O OO OO OO  OOO OO O   O             ",
"+++++++++++++ OOOOOO OOOO OO OO                 ",
"+++++++++++++O+ +O OOOO OOO  OOO OOO            ",
"++++++++++++++ OOOOO O OOOOOOOOOO               ",
"+++++++++++++ ++  OO  +O OOOOO O  O   O         ",
"+++++++++++++++O+++O+O+O OOOOOOOOOO    O        ",
"+++++++++++++O++++O++  O OOO O OOO OO           ",
"++++++++++++++++O+++O+O+OOOO OOOO  O  OO        ",
"+++++++++++++++++++O+++ +++O OOOOOO OO   O      ",
"++++++++++++++++++++++ +++ O OOOOOOOOO          "};
EOT
}

