use Pod::Text;

if ($ARGV[0] eq "-help") {
  print "Usage: perl QuickInst.pl [install dir]\n";
}

$instdir = $ARGV[0];

mkdir $instdir, umask;
mkdir "$instdir/Math", umask;

foreach $file ("Fraction", "FractionDemo") {
  print qq~Copying "$file.pm" to "$instdir/Math/$file.pm".\n~;
  open IN, "$file.pm";
  open OUT, ">$instdir/Math/$file.pm";
  print OUT <IN>;
  print qq~Creating Manual Page for $file ($instdir/$file.txt).\n~;
  open OUT, ">$instdir/$file.txt";
  pod2text "$file.pm", *OUT;
}

