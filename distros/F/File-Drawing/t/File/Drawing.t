#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/04';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Drawing.t
#
# UUT: File::Drawing
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::File::Drawing;
#
# Don't edit this test script file, edit instead
#
# t::File::Drawing;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 

   use FindBin;
   use File::Spec;
   use Cwd;

   ########
   # The working directory for this script file is the directory where
   # the test script resides. Thus, any relative files written or read
   # by this test script are located relative to this test script.
   #
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Pick up any testing program modules off this test script.
   #
   # When testing on a target site before installation, place any test
   # program modules that should not be installed in the same directory
   # as this test script. Likewise, when testing on a host with a @INC
   # restricted to just raw Perl distribution, place any test program
   # modules in the same directory as this test script.
   #
   use lib $FindBin::Bin;

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes expected and actual references and stringify
   # them by using "Data::Secs2" before passing them to the "&Test::ok"
   # Thus, almost any time of Perl data structures may be
   # compared by passing a reference to them to Test::Tech::ok
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(finish is_skip ok plan skip skip_tests tech_config) );
   plan(tests => 61);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}


=head1 comment_out

###
# Have been problems with debugger with trapping CARP
#

####
# Poor man's eval where the test script traps off the Carp::croak 
# Carp::confess functions.
#
# The Perl authorities have Core::die locked down tight so
# it is next to impossible to trap off of Core::die. Lucky 
# must everyone uses Carp to die instead of just dieing.
#
use Carp;
use vars qw($restore_croak $croak_die_error $restore_confess $confess_die_error);
$restore_croak = \&Carp::croak;
$croak_die_error = '';
$restore_confess = \&Carp::confess;
$confess_die_error = '';
no warnings;
*Carp::croak = sub {
   $croak_die_error = '# Test Script Croak. ' . (join '', @_);
   $croak_die_error .= Carp::longmess (join '', @_);
   $croak_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once croak can not continue
};
*Carp::confess = sub {
   $confess_die_error = '# Test Script Confess. ' . (join '', @_);
   $confess_die_error .= Carp::longmess (join '', @_);
   $confess_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once confess can not continue

};
use warnings;
=cut


   # Perl code from C:
    use File::Package;
    use File::SmartNL;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Drawing';
    my $loaded;
    my $artists1;

ok(  $loaded = $fp->is_package_loaded($uut), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);


####
# verifies requirement(s):
# L<Data::Filer/general [1] - load>
# 

#####
skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      "",
      "Load UUT");
 
#  ok:  2

ok(  $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','_Drawings_::Repository0'), # actual results
     'Artists_M::Madonna::Erotica', # expected results
     "",
     "pm2number");

#  ok:  3

ok(  $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica',''), # actual results
     '_Drawings_::Repository0::Artists_M::Madonna::Erotica', # expected results
     "",
     "pm2number, empty repository");

#  ok:  4

ok(  $uut->pm2number('Etc::Artists_M::Madonna::Erotica'), # actual results
     'Artists_M::Madonna::Erotica', # expected results
     "",
     "pm2number, no repository");

#  ok:  5

ok(  $uut->number2pm('Artists_M::Madonna::Erotica','_Drawings_::Repository0'), # actual results
     '_Drawings_::Repository0::Artists_M::Madonna::Erotica', # expected results
     "",
     "number2pm");

#  ok:  6

ok(  $uut->number2pm('Artists_M::Madonna::Erotica',''), # actual results
     'Artists_M::Madonna::Erotica', # expected results
     "",
     "number2pm, empty repository");

#  ok:  7

ok(  $uut->number2pm('Artists_M::Madonna::Erotica'), # actual results
     'Etc::Artists_M::Madonna::Erotica', # expected results
     "",
     "number2pm, no repository");

#  ok:  8

ok(  $uut->dod_date(25, 34, 36, 5, 1, 104), # actual results
     '2004/02/05 36:34:25', # expected results
     "",
     "dod_date");

#  ok:  9

ok(  length($uut->dod_drawing_number()), # actual results
     11, # expected results
     "",
     "dod_drawing_number");

#  ok:  10

   # Perl code from C:
   ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #;

skip_tests( 1 ) unless ok(
      -d (File::Spec->catfile( qw(_Drawings_ Repository0))), # actual results
      1, # expected results
      "",
      "Repository0 exists"); 

#  ok:  11

   # Perl code from C:
   ####
   # Drawing must find the below directory in the @INC paths
   # in order to perform this test.
   #     
   rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));
   mkpath (File::Spec->catdir( qw(_Drawings_ Repository1) ));

skip_tests( 1 ) unless ok(
      -d (File::Spec->catfile( qw(_Drawings_ Repository1))), # actual results
      1, # expected results
      "",
      "Created Repository1"); 

#  ok:  12

   # Perl code from C:
my $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository0');

skip_tests( 1 ) unless ok(
      ref($erotica2), # actual results
      'File::Drawing', # expected results
      "$erotica2",
      "Retrieve erotica source control drawing"); 

#  ok:  13

   # Perl code from C:
 my $error= $erotica2->release(revise_repository => '_Drawings_::Repository1::' );

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Release erotica to different repository"); 

#  ok:  14

   # Perl code from C:
my $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica"); 

#  ok:  15

ok(   $erotica1->[0], # actual results
      $erotica2->[0], # expected results
     "",
     "Erotica contents unchanged");

#  ok:  16

   # Perl code from C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{file} = $erotica1->[1]->{file};

ok(   $erotica1->[1], # actual results
      $erotica2->[1], # expected results
     "",
     "Erotica rev - white tape date changed");

#  ok:  17

   # Perl code from C:
    $error= $erotica2->revise( );

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise erotica unchanged"); 

#  ok:  18

   # Perl code from C:
     $erotica2 = $erotica1;
     $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica unchanged"); 

#  ok:  19

ok(  $erotica1->[0], # actual results
     $erotica2->[0], # expected results
     "",
     "Erotica unchanged contents unchanged");

#  ok:  20

ok(  $erotica1->[1], # actual results
     $erotica2->[1], # expected results
     "",
     "Erotica unchanged white tape unchanged");

#  ok:  21

   # Perl code from C:
    my $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $erotica2->[0]->{in_house}->{num_media} =  1;
    $error = $erotica2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise erotica contents"); 

#  ok:  22

ok(  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm))), # actual results
     $file_contents2, # expected results
     "",
     "Obsolete erotica");

#  ok:  23

   # Perl code from C:
$erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica, revision 1"); 

#  ok:  24

ok(  $erotica1->[0], # actual results
     $erotica2->[0], # expected results
     "",
     "Erotica Revision 1 contents revised");

#  ok:  25

   # Perl code from C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.02';
     $erotica2->[1]->{revision} = '1';

ok(   $erotica1->[1], # actual results
      $erotica2->[1], # expected results
     "",
     "Erotica Revision 1 white tape revised");

#  ok:  26

   # Perl code from C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $erotica2->[1]->{classification} = 'Top Secret';
    $error = $erotica2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise erotica revision 1 white tape"); 

#  ok:  27

ok(  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-1.pm))), # actual results
     $file_contents2, # expected results
     "",
     "Obsolete erotica revision 1");

#  ok:  28

   # Perl code from C:
$erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica revision 2"); 

#  ok:  29

ok(  $erotica1->[0], # actual results
     $erotica2->[0], # expected results
     "",
     "Erotica revision 2 contents unchanged");

#  ok:  30

   # Perl code from C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.03';
     $erotica2->[1]->{revision} = '2';

ok(   $erotica1->[1], # actual results
      $erotica2->[1], # expected results
     "",
     "Erotica revision 2 white tape revised");

#  ok:  31

   # Perl code from C:
$erotica2 = $uut->retrieve('_Drawings_::Erotica', repository => '');

skip_tests( 1 ) unless ok(
      ref($erotica2), # actual results
      'File::Drawing', # expected results
      "$erotica2",
      "Retrieve _Drawings_::Erotica"); 

#  ok:  32

   # Perl code from C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise erotica revision 2"); 

#  ok:  33

ok(  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm))), # actual results
     $file_contents2, # expected results
     "",
     "Obsolete erotica revision 2");

#  ok:  34

   # Perl code from C:
$erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica revision 3"); 

#  ok:  35

ok(  $erotica1->[0], # actual results
     $erotica2->[0], # expected results
     "",
     "Erotica revision 3 contents unchanged");

#  ok:  36

   # Perl code from C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.04';
     $erotica2->[1]->{revision} = '3';

ok(   $erotica1->[1], # actual results
      $erotica2->[1], # expected results
     "",
     "Erotica revision 3 white tape revised");

#  ok:  37

ok(   $erotica1->[3], # actual results
     '#!/usr/bin/perl
#
#
package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->
#<-- /BLK -->

#####
# This section may be used for Perl subroutines and expressions.
#
print "Hello world from _Drawings_::Erotica\n";


1
', # expected results
     "",
     "Erotica revision 3 file contents revised");

#  ok:  38

   # Perl code from C:
   unshift @INC,'_Sandbox_';
   $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica2), # actual results
      'File::Drawing', # expected results
      "$erotica2",
      "Retrieve Sandbox erotica"); 

#  ok:  39

   # Perl code from C:
    $file_contents2 =  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Artists_M Madonna Erotica.pm)));
    shift @INC;
    $error = $erotica2->revise( );

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise erotica revision 3"); 

#  ok:  40

ok(  File::SmartNL->fin(File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm))), # actual results
     $file_contents2, # expected results
     "",
     "Obsolete erotica revision 3");

#  ok:  41

   # Perl code from C:
$erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($erotica1), # actual results
      'File::Drawing', # expected results
      "$erotica1",
      "Retrieve erotica revision 4"); 

#  ok:  42

ok(  $erotica1->[0], # actual results
     $erotica2->[0], # expected results
     "",
     "Erotica Revision 4 contents unchanged");

#  ok:  43

   # Perl code from C:
     $erotica2->[1]->{date_gm} = $erotica1->[1]->{date_gm};
     $erotica2->[1]->{date_loc} = $erotica1->[1]->{date_loc};
     $erotica2->[1]->{version} = '0.05';
     $erotica2->[1]->{revision} = '4';

ok(   $erotica1->[1], # actual results
      $erotica2->[1], # expected results
     "",
     "Erotica Revision 4 white tape revised");

#  ok:  44

ok(   $erotica1->[3], # actual results
     '#!/usr/bin/perl
#
#
package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->
#<-- /BLK -->

#####
# This section may be used for Perl subroutines and expressions.
#
print "Hello world from Sandbox\n";


1
', # expected results
     "",
     "Erotica Revision 4 file contents revised");

#  ok:  45

   # Perl code from C:
my $artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository0');

skip_tests( 1 ) unless ok(
      ref($artists2), # actual results
      'File::Drawing', # expected results
      "$artists2",
      "Retrieve index drawing artists"); 

#  ok:  46

   # Perl code from C:
$error= $artists2->release(revise_repository =>  '_Drawings_::Repository1::');

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Release artists to different repository"); 

#  ok:  47

   # Perl code from C:
$artists2 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($artists2), # actual results
      'File::Drawing', # expected results
      "$artists2",
      "Retrieve artists"); 

#  ok:  48

   # Perl code from C:
    $artists2->[0]->{browse} = ['Artists_M::Index'];
    $error = $artists2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise artists"); 

#  ok:  49

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm)), # actual results
     1, # expected results
     "",
     "Obsolete artists");

#  ok:  50

   # Perl code from C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index'];
    $error = $artists2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise artists revision 1"); 

#  ok:  51

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-1.pm)), # actual results
     1, # expected results
     "",
     "Obsolete artists revision 1");

#  ok:  52

   # Perl code from C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index'];
    $error = $artists2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise artists revision 2"); 

#  ok:  53

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-2.pm)), # actual results
     1, # expected results
     "",
     "Obsolete artists revision 2");

#  ok:  54

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index.pm)), # actual results
     undef, # expected results
     "",
     "Destory artists");

#  ok:  55

   # Perl code from C:
    $artists2->[0]->{browse} = ['Artists_M::Index','Artists_B::Index','Artists_E::Index','Artists_F::Index'];
    $error = $artists2->revise();

skip_tests( 1 ) unless ok(
      $error, # actual results
      '', # expected results
      "",
      "Revise artists revision 3"); 

#  ok:  56

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists Index-3.pm)), # actual results
     1, # expected results
     "",
     "Obsolete artists revision 3");

#  ok:  57

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists IndexA.pm)), # actual results
     undef, # expected results
     "",
     "Destory artists Revision 1");

#  ok:  58

   # Perl code from C:
    copy ( File::Spec->catfile(qw(_Drawings_ Repository0 Artists IndexBad.pm)),
           File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm)));
    $artists1 = $uut->retrieve('Artists::Index', repository => '_Drawings_::Repository1');

skip_tests( 1 ) unless ok(
      ref($artists1), # actual results
      '', # expected results
      "$artists1",
      "Retrieve broken artists revision 4"); 

#  ok:  59

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Artists Index.pm)), # actual results
     undef, # expected results
     "",
     "Artists Revision 4 removed");

#  ok:  60

ok(  -e  File::Spec->catfile(qw(_Drawings_ Repository1 Broken Artists Index.pm)), # actual results
     1, # expected results
     "",
     "Artists Revision 4 sequestered");

#  ok:  61

   # Perl code from C:
rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));


=head1 comment out

# does not work with debugger
CARP_DIE:
    if ($croak_die_error || $confess_die_error) {
        print $Test::TESTOUT = "not ok $Test::ntest\n";
        $Test::ntest++;
        print $Test::TESTERR $croak_die_error . $confess_die_error;
        $croak_die_error = '';
        $confess_die_error = '';
        skip_tests(1, 'Test invalid because of Carp die.');
    }
    no warnings;
    *Carp::croak = $restore_croak;    
    *Carp::confess = $restore_confess;
    use warnings;
=cut

    finish();

__END__

=head1 NAME

Drawing.t - test script for File::Drawing

=head1 SYNOPSIS

 Drawing.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Drawing.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

## end of test script file ##

