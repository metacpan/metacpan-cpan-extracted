# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Image::XFace;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$me = '
"kUA_=&I|(by86eXgYc|U}5`O%<xlo,~+JN9uk"Z`A.UCf2\1KKZ{FY-IIOqH/IS"=5=cb`
 U,mDyyf8a6BzVgYT~pRtqze]%s#\(J{/um"(r,Ol^4J*Y%aWe-9`ZKGEYjG}d?#u2jzP,x37.%A~Qa
 ;Yy6Fz`i/vu{}?y8%cI)RJpLnW=$yTs=TDM\'MGjX`/LDw%p;EK;[ww;9_;UnRa+JZYO}[-j]O08X\N
 m/K>M(P#,)y`g7N}Boz4b^JTFYHPz:s%idl@t$\Vv$3OL6:>GEGwFHrV$/bfnL=6uO/ggqZfet:&D3
 Q=9c
';

# decode and recode image, check that we get the same result.
@data = Image::XFace::uncompface($me);
if (@data != 48) {
    print "not ok 2\n";
    exit 1;
} else {
    print "ok 2\n";
}

$me2 = Image::XFace::compface(@data);

$me  =~ s/\s*//;
$me2 =~ s/\s*//;

if ($me ne $me2) {
    print "not ok 3\n";
    exit 1;
} else {
    print "ok 3\n";
}
