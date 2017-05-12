# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use English::Reference;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$hashref = {
    ary=>[1,1,2,3,5],
    cod=>sub { return "Hello World\n"; },
    glb=>\*123,
    hsh=>{a=>"alpha", b=>"beta", z=>"omega"},
    scl=>\'Shameless plug: pthbb.org'
};

print join(',', ARRAY $hashref->{ary}) eq "1,1,2,3,5" ? "ok 2\n" : "not ok 2\n";
print CODE  ($hashref->{cod}) eq "Hello World\n" ? "ok 3\n" : "not ok 3\n";
print GLOB  ($hashref->{glb}) == *main::123 ? "ok 4\n" : "not ok 4\n";
%F =  HASH  ($hashref->{hsh});
print join('', sort %F) eq "aalphabbetaomegaz" ? "ok 5\n" : "not ok 5\n";
print SCALAR($hashref->{scl}) eq "Shameless plug: pthbb.org" ? "ok 6\n" : "not ok 6\n";
print( (sprintf "%s", SCALAR \"Hello World", "\n" eq "Hello World\n")? "ok 7\n" : "not ok 7\n");
