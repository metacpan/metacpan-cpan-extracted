#!/usr/local/bin/perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use HTML::Clean;
$loaded = 1;
$test = 1;
print "ok 1\n";

foreach $page ('hairy', 'altavista', 'microsoft', 'ibm', 'yahoo', 'infoseek', 'itu', 'cnn') {
  $test ++;
  my $h = new HTML::Clean("t/testpages/$page.html");
  print "not ok $test\n" if (! defined($h));
  # compat changes the 'look' of the page for lynx..
  # $h->compat();
  $h->strip();
  
  if (open(OUTFILE, ">t/testpages/t$page.html")) {
    print OUTFILE ${$h->data()};
    close(OUTFILE);
  } else {
    print "not ok $test\n";
  }
  # if we can open lynx test that..
  if (open(P, "lynx -nolist -dump t/testpages/$page.html |")) {
     my $cvtpage = '';
     my $origpage = '';

     while (<P>) {
        $origpage .= $_;
     }
     close(P);

     if (open(P, "lynx -nolist -dump t/testpages/t$page.html |")) {
       while (<P>) {
          $cvtpage .= $_;
       } 
       close(P);

       if (abs(length($origpage) - length($cvtpage)) > 30) {
          print STDERR "\nWarning, lynx detects different page sizes for $page " .
		length($origpage) . ", " . length($cvtpage) . "\n";
        
       }
     }
  }
	
  print "ok $test\n";
}

