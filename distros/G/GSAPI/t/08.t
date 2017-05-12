# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('GSAPI') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $output;
{ local *FH;
  tie *FH, "GSAPI", stdout => sub { $output .= $_[0]; length $_[0]},
                   args => [ "gsapi",
                             "-sDEVICE=pdfwrite",
                             "-dNOPAUSE",
                             "-dBATCH",
                             "-sPAPERSIZE=a4",
                             "-DSAFER",
                             "-sOutputFile=/dev/null", # don't even think about Win32
                           ];

  print FH $_ for split //, "12345679 9 mul pstack quit\n";
}

ok($output =~ /111111111/);
