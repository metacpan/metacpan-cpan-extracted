use File::Tail;
$| = 1; print "1..2\n";

$debug=0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $fnbase="./test$$";
open(TESTA,">$fnbase.a");
print TESTA "This is test file A\n";
close TESTA;

sub newname {
    return "$fnbase.b";
}

my $file=File::Tail->new(name=>"$fnbase.a",
                         name_changes=>\&newname,maxinterval=>10,
	                 debug=>$debug,
			 tail=>1,
			 adjustafter=>2);
if ($file->read eq "This is test file A\n") {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}

open(TESTB,">$fnbase.b");
print TESTB "This is test file B (yes, B, not A: A was the other file)\n";
close TESTB;
print "ok 2\n" if ($file->read eq 
	"This is test file B (yes, B, not A: A was the other file)\n");
unlink "$fnbase.a","$fnbase.b";

