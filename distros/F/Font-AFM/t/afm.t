require Font::AFM;

eval {
   $font = Font::AFM->new("Helvetica");
};
if ($@) {
   if ($@ =~ /Can't find the AFM file for/) {
	print "1..0 # Skipped: Can't find required font\n";
	print "# $@";
   } else {
	print "1..1\n";
        print "# $@";
	print "not ok 1 Found font OK\n";
   }
   exit;
}
print "1..1\n";

$sw = $font->stringwidth("Gisle Aas");

if ($sw == 4279) {
    print "ok 1 Stringwith for Helvetica seems to work\n";
} else {
    print "not ok 1 The stringwidth of 'Gisle Aas' should be 4279 (it was $sw)\n";
}

