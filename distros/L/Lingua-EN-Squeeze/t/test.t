#! perl
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use English;
use Lingua::EN::Squeeze qw( :ALL );
use Test::More tests => 7;

$OUTPUT_AUTOFLUSH = 1;

my $str =
    "This is piece of text to demonstrate the Squeezing algorhithm "
    . "which is based on text matches and vowel deletion rules. The "
    . "performance of the module is not impressive, because each line "
    . "is treated several times with various test.\n"
    ;

my $levelString =
    "With or without piece translate differently, LEVEL is adjustable\n";

{
    print "ORIGINAL TEXT\n" . $str;
    $ARG = SqueezeText($str);

    print "RESULT: $ARG";
    ok( $ARG ,  'SqueezeText()' ) ;
}

{
    my $val	= "piece";
    my $cnv	= "TO_MY_CNV";
    my %myHash	=
    (
	$val => $cnv
    );

    SqueezeHashSet( \%myHash );

    $ARG =  SqueezeText($str);

    ok( /$cnv/ ,  'SqueezeText() + custom SqueezeHashSet()' ) ;
}

{
    my $len = length $str;

    SqueezeControl( "noconv" );
    $ARG = SqueezeText($str);

    ok( $len == length, "SqueezeControl(noconv)" );
}

{
    SqueezeControl( "med" );
    $ARG = SqueezeText($str);
    my $ratio = sprintf "%0.2f%",  1 - length($ARG)/length $str;

    ok( m!w/! , "SqueezeControl(med) with ratio $ratio");
}

{
    # SqueezeDebug(1, "without");
    SqueezeControl( "max" );
    $ARG =  SqueezeText($str);

    # print "KEYS >>", join ' ', keys %Lingua::EN::Squeeze::wordXlate, "\n\n";

    my $lenA = length $ARG;
    my $lenB = length $str;
    my $ratio = sprintf("%0.2f",  1 - $lenA/$lenB);

    ok( m!w/! , "SqueezeControl(max) with ratio $ratio");

}

{
    my $obj = new Lingua::EN::Squeeze;
    ok ( ref($obj) eq 'Lingua::EN::Squeeze', "new Lingua::EN::Squeeze");

    $ARG = $obj->SqueezeText($str);

    ok ( $ARG , "\$obj->SqueezeText(str) using Object call");
}

# End of file
