use strict;
use warnings;
use Getopt::Long;
use File::Spec;

use constant TEST_COUNT => 37;  # number printed in expect line of test harness output.
our ($quiet, $verbose);
my $failcount;


BEGIN {
   use File::Basename;
   unshift @INC, dirname(__FILE__);  # look in same directory for helper modules.
   $verbose= $ENV{TEST_VERBOSE};
   GetOptions ('quiet' => \$quiet, 'verbose' => \$verbose) or die "bad options\n";
   unless ($verbose) {
      # silence the --verbose and --dump stuff
      open (my $f, '>', File::Spec->devnull());
      require Exporter::VA;
      *Exporter::VA::VERBOSE= $f;
      }
   print "1..", TEST_COUNT, "\n" unless ($quiet);  # format used by Test::Harness.
   }

sub verify
 {
 my ($code, $answer)= @_;
 my $result= eval ($code);
 if ($@) {
    print "not ok - Error calling { $code }, produces $@";
    ++$failcount;
    }
 else {
    if ($result eq $answer) {
       print "ok - calling { $code } => $result\n"  unless $quiet;
       }
    else {
       print "not ok - calling { $code }, returns \"$result\",  expected \"$answer\"\n";
       ++$failcount;
       }
    }
 }


## Test basic export features.
package C1;
use M1 v1.0 qw/--verbose_import &foo bar baz quux bazola $ztesch --dump/;
sub verify;
*verify= \&main::verify;
verify "C1::foo (5)", "Called M1::foo (5).";
verify "C1::bar (6)", "Called M1::internal_bar (6).";
verify "C1::baz (7)", "Called M1::baz (7).";
verify "C1::quux (8)", "Called M1::quux (8).";
verify "C1::bazola (9)", "Called dynamically-generated M1::&bazola asked for by C1, with parameters (9).";
verify '$C1::ztesch=10; ++$M1::ztesch; $C1::ztesch == 11', "1";


## Test .plain and tags
package C2;
use M2 v1.0 qw/ foo baz $ztesch :tag1/;
sub verify;
*verify= \&main::verify;
verify "C2::foo (12)", "Called M2::foo (12).";
verify "C2::baz (13)", "Called M2::baz (13).";
verify '$C2::ztesch=14; ++$M2::ztesch; $C2::ztesch == 15', "1";
verify "C2::quux (16)", "Called M2::quux (16).";
verify "C2::bazola (17)", "Called M2::baz (17).";
verify "C2::thud (18)", "Called M2::baz (18).";
verify "C2::grunt (19)", "Called M2::baz (19).";


## Test version-list exports
package C3;
use M3 qw/--verbose_import foo :blarg/;
sub verify;
*verify= \&main::verify;
verify "C3::foo (20)", "Called M3::old_foo (20).";
verify "C3::bar (22)", "Called M3::bar (22).";


## Make sure different clients can use different versions
package C4;
use M3 v2.1 qw/:tag/;  # more levels of indirection
sub verify;
*verify= \&main::verify;
verify "C4::foo (21)", "Called M3::new_foo (21).";
package C5;
use M3 v1.5.1 qw/foo/;
sub verify;
*verify= \&main::verify;
verify "C5::foo (23)", "Called M3::middle_foo (23).";


## Make sure we use a :DEFAULT.
# >> need to see what version was actually taken.
package C6;
use M2;
sub verify;
*verify= \&main::verify;
verify "C6::foo (24)", "Called M2::foo (24).";
verify "C6::thud (25)", "Called M2::baz (25).";


## Pragma names may be non-identifiers
# (also tests pragma extracting arguments)
# (also tests that return value from callback is ignored if symbol begins with dash)
package C7;
our $output;
use M2 'foo', '-pra#ma!', \$output, 'baz';
sub verify;
*verify= \&main::verify;
verify "C7::foo (26)", "Called M2::foo (26).";
verify "C7::baz (27)", "Called M2::baz (27).";
verify "\$C7::output",  "-pra#ma!";

## check the behavior of normalize_vstring
use Exporter::VA 'normalize_vstring';
sub vv
 {
 my ($x, $answer)= @_;
 my $result= normalize_vstring ($x);
 if ($result eq $answer) {
    printf "ok - normalizing %vd => %vd\n", $x, $result  unless $quiet;
    }
 else {
    printf "not ok - normalizing %vd, returns \"%vd\",  expected \"%vd\"\n", $x, $result, $answer;
    ++$failcount;
    }
 }
 
vv (v1.2.3, v1.2.3);
vv ('', v0);
vv (v3.2.1.0, v3.2.1);
vv (v1.0.0.0, v1.0);
vv (2.3, v2.3);
vv ('2.3.4', v2.3.4);

package main;
sub match_v
 {
 my ($x, $answer)= @_;
 if ($x eq $answer) {
    printf "ok\n"  unless $quiet;
    }
 else {
    printf "not ok - got %vd, expected %vd\n", $x, $answer;
    ++$failcount;
    }
 }

## check floating-point version specifier on use line
# also generates 2 warnings about importing things that begin with underscore, but doesn't automatically verify the presence of the warning.
# also note that importing of M3 is no longer producing trace output, since --verbose_import is a one-shot.
package C8;
sub match;
*match_v= \&main::match_v;
BEGIN { 
   if ($verbose) {
      print "This should generate two warnings about importing things beginning with underscores:\n";
      @C8::args= qw/ :_new_blarg _bar/;
      }
   }
use M3 2.4 @C8::args;
BEGIN { 
   print "The two warnings should be before this line.  No longer expecting any warnings.\n" if ($verbose);
   }
{
my $mv= M3->VERSION();
match_v ($mv, v2.4);  # took M3 as v2.4, not v2.400 or v50.46.52.
$mv= M3->VERSION(undef,'C3');
match_v ($mv, v1.3); # check peeking on other package's version of M3.
   # verifies other-package form of VERSION, and use of .default_VERSION back in C3.
}



## check .allowed_VERSIONS
eval <<'ATTEMPT';
   package C9;
   use M2 v1.1;
ATTEMPT

if ($@) {
   # as expected, won't let me.
   print "ok - checked allowed versions.\n"  unless $quiet;
   if ($verbose) {
      my $s= $@;
      $s =~ s/^BEGIN failed.*?\n//m;  # more than I need to know
      chomp $s;
      print "As expected, [[ $s ]]\n";
      }
   }
else {
   print "not ok - version not checked against .allowed_VERSIONS properly.\n";
   ++$failcount;
   }


## check working of autoload_symbol

package C10;
use M3 ('get_export_def');
my $M3_export_def= get_export_def();
die unless $$M3_export_def{'..home'} eq 'M3';  # make sure my test jig is set up correctly, thus far.
eval { M3::foo() };
if ($@ =~ /Undefined subroutine &M3::foo/) {  print "ok\n" unless $quiet }
else { print "not ok - M3::foo seems to be defined already.\n"; ++$failcount }
$M3_export_def->autoload_symbol ('foo');  # let the fun begin!
package main;

verify "package C3; M3::foo (30)", "Called M3::old_foo (30).";
verify "package C8; M3::foo (31)", "Called M3::new_foo (31).";


## check working of implicit AUTOLOAD

verify "M2::thud (32)", "Called M2::baz (32).";
verify "M2::grunt (33)", "Called M2::baz (33).";

eval { M2::no_such_function (34) };
if ($@ =~ /no_such_function/) { print "ok\n" unless $quiet }
else { print "not ok - M2::no_such_function not generating an error.\n";  ++$failcount }


####### summary report ######
print '-'x40, "\n"  unless $quiet;
if ($failcount) {
   print "* FAILED $failcount tests!!\n";
   exit 5;
   }
else {
   print "PASSED all tests.\n";
   exit 0;
   }

