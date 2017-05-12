# This is -*-Perl-*-, believe it or not.
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::WWWTheme;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $testnum = 2;

my $Theme;


# First, we'll make a string that we know is correct.  Then we'll try
# to create one with the module and compare. If it works, then all is well.
# if it doesn't, we fail.

my $goodstring = 
q{<!-- Beginning of top/bottom bar -->
<CENTER><a href="here.html">here</a><BR><a href="there.html">there</a><BR></CENTER>
<!-- End of top/bottom bar -->};


eval { 
  $Theme = new HTML::WWWTheme;

  my @array = ('<a href="here.html">here</a>', '<a href="there.html">there</a>');
  $Theme->SetTopBottomLinks(\@array);

  my $topbottom = $Theme->MakeTopBottomBar();

  if ($topbottom eq $goodstring) 
    {
      print "ok ", $testnum ++, "\n";
    }
  else
    {
      open FIRST, ">firstprinttb";
      open SECOND, ">secondprinttb";
      print FIRST $topbottom;
      print SECOND $goodstring;
      print "not ok ", $testnum ++, "\n";
      #    }
      #};
      
      #if ($@) 
      #  {
      print "...error: $@\n";
      print "Examine files called firstprint and secondprint.\n";
      print "firstprint was the generated HTML, and secondprint was the expected output.\n";
      print "If there is a difference, then there might be something wrong.  If you can't\n";
      print "figure it out yourself, email the results to chogan\@uvastro.phys.uvic.ca, \n";
      print "with a brief summary of your set-up (platform, perl version, etc)\n";
      print "and I'll see if I can figure it out.\n";
    }
};

