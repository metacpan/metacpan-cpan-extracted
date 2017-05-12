# $Id$
package TestDetails;
use strict;
use Test;
use Exporter;
use Cwd;

use vars qw(@EXPORT @EXPORT_OK $VERSION @ISA);
@ISA=qw(Exporter);
@EXPORT=qw(do_test fail_tests test_callback $test_user $test_pass $test_url $test_cwd);

# This package is designed to simplify testing.
# It allows you to enter multiple URL's (and 
# credentials) for the different tests.

# You need to manually edit the %details hash below.

# A test script may tell us that it is about to do a propfind.
# It would do this by calling TestDetails::method('PROPFIND');
# Then when the test script calls TestDetails::url() you will 
# get the URL specificed in the PROPFIND hash below.
# But, if you haven't specified any details in the hash below 
# specific for PROPFIND it will use the DEFAULT entries instead.

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

# Configure these details:

my %details = (
#   'default' => {
#      'url'=> 'http://localhost/dav/',
#      'user' => 'username',
#      'pass' => 'pass',
#   },

);

# End of configuration section
######################################################################

my $method = "";
my $PERLDAV_TEST = 'default';
if (defined $ENV{'PERLDAV_TEST'}) {
    $PERLDAV_TEST = lc $ENV{'PERLDAV_TEST'} || 'default';
}

our $test_user = user();
our $test_pass = pass();
our $test_url  = url();
our $test_cwd  = getcwd(); # If the user wants to remember where they started.

######################################################################

sub fail_tests {
   my ($num) = @_;
   print  "You need to set a test url in the t/TestDetails.pm module.\n";
   for(1..$num) { skip("no test server",1); }
   exit;
}

sub user { 
   no warnings; 
   $details{$PERLDAV_TEST}{'user'} || 
   $details{'DEFAULT'}{'user'} || 
   '' 
}
sub pass { 
   no warnings; 
   $details{$PERLDAV_TEST}{'pass'} || 
   $details{'DEFAULT'}{'pass'} || 
   '' 
}
sub url { 
   no warnings; 
   $details{$PERLDAV_TEST}{'url'} || 
   $details{'DEFAULT'}{'url'} || 
   ''
}

######################################################################
# UTILITY FUNCTIONS: 
#    do_test <op_result>, <expected_result>, <message>
# It was getting tedious doing the error handling so 
# I built this little routine, Makes the test cases easier to read.
sub do_test {
   my($dav,$result,$expected,$message,$resp) = @_;
   $expected = 1 if !defined $expected;
   my $ok;
   my $respobj ="";

   my $davmsg;
   if (ref($result) =~ /Response/ ) {
      $davmsg = $result->message .
         "REQUEST>>".$result->request()->as_string() .
         "RESPONS>>".$result->as_string;
      $result=$result->is_success;
   } else {
      my $resp = $dav->get_last_response;
      $davmsg = $dav->message;# . join("\n",@{$resp->messages()});
   }

   if ($expected) {
      if ( $ok = ok($result,$expected) ) {
         print "TEST $message succeeded\n";
      } else {
         print "TEST $message failed: $davmsg\n";
      }
   } else {
      if ( $ok = ok($result,$expected) ) {
         print "TEST $message failed (as expected): \"$davmsg\"\n";
      } else {
         print "TEST $message succeeded (unexpectedly): \"$davmsg\"\n";
      }
   }
   return $ok;
}

sub test_callback {
    my($success,$mesg) = @_;
    if ($success) {
        print "$mesg\n"
    } else {
        print "Failed: $mesg\n"
    }
}

1;
