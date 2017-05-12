#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/25';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Original.t
#
# UUT: ExtUtils::SVDmaker
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::ExtUtils::SVDmaker::Original;
#
# Don't edit this test script file, edit instead
#
# t::ExtUtils::SVDmaker::Original;
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
   Test::Tech->import( qw(finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );
   plan(tests => 11);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}




   # Perl code from C:
    use vars qw($loaded);
    use File::Glob ':glob';
    use File::Copy;
    use File::Path;
    use File::Spec;

    use File::Package;
    use File::SmartNL;
    use Text::Scrub;

    my $loaded = 0;
    my $snl = 'File::SmartNL';
    my $fp = 'File::Package';
    my $s = 'Text::Scrub';
    my $w = 'File::Where';
    my $fs = 'File::Spec';



ok(  $fp->is_package_loaded('ExtUtils::SVDmaker'), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package( 'ExtUtils::SVDmaker' );




####
# verifies requirement(s):
# L<ExtUtils::SVDmaker/load [1]>
# 

#####
skip_tests( 1 ) unless
  skip( $loaded, # condition to skip test   
      $errors, # actual results
      '', # expected results
      "",
      "Load UUT");

#  ok:  2

   # Perl code from C:
    ######
    # Add the SVDmaker test lib and test t directories onto @INC
    #
    unshift @INC, File::Spec->catdir( cwd(), 't');
    unshift @INC, File::Spec->catdir( cwd(), 'lib');
    rmtree( 't' );
    rmtree( 'lib' );
    mkpath( 't' );
    mkpath( 'lib' );
    mkpath( $fs->catfile( 't', 'Test' ));
    mkpath( $fs->catfile( 't', 'Data' ));
    mkpath( $fs->catfile( 't', 'File' ));

    copy ($fs->catfile('expected','SVDtest0A.pm'),$fs->catfile('lib','SVDtest1.pm'));
    copy ($fs->catfile('expected','module0A.pm'),$fs->catfile('lib','module1.pm'));
    copy ($fs->catfile('expected','SVDtest0A.t'),$fs->catfile('t','SVDtest1.t'));
    copy ($fs->catfile('expected','Test','Tech.pm'),$fs->catfile('t','Test','Tech.pm'));
    copy ($fs->catfile('expected','Data','Startup.pm'),$fs->catfile('t','Data','Startup.pm'));
    copy ($fs->catfile('expected','Data','Secs2.pm'),$fs->catfile('t','Data','Secs2.pm'));
    copy ($fs->catfile('expected','Data','SecsPack.pm'),$fs->catfile('t','Data','SecsPack.pm'));
    copy ($fs->catfile('expected','File','Package.pm'),$fs->catfile('t','File','Package.pm'));

    rmtree 'packages';



   # Perl code from C:
    unlink 'SVDtest1.log';
    no warnings;
    open SAVE_OUT, ">&STDOUT";
    open SAVE_ERR, ">&STDERR";
    use warnings;
    open STDOUT,'> SVDtest1.log';
    open STDERR, ">&STDOUT";
    my $svd = new ExtUtils::SVDmaker( );
    my  $success = $svd->vmake( {pm => 'SVDtest1'} );
    close STDOUT;
    close STDERR;
    open STDOUT, ">&SAVE_OUT";
    open STDERR, ">&SAVE_ERR";
    my $output = $snl->fin( 'SVDtest1.log' );



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$output",
     "Vmake new");

#  ok:  3

ok(  $output =~ /All tests successful/, # actual results
     1, # expected results
     "",
     "All tests successful");

#  ok:  4

ok(  $s->scrub_date( $snl->fin( File::Spec->catfile( 'lib', 'SVDtest1.pm' ) ) ), # actual results
     $s->scrub_date( $snl->fin( File::Spec->catfile( 'expected', 'SVDtest2.pm' ) ) ), # expected results
     "",
     "generated SVD POD");

#  ok:  5

ok(  $s->scrub_date( $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'lib', 'SVDtest1.pm' ) ) ), # actual results
     $s->scrub_date( $snl->fin( File::Spec->catfile( 'expected', 'SVDtest2.pm' ) ) ), # expected results
     "",
     "generated packages SVD POD");

#  ok:  6

ok(  $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'MANIFEST' ) ), # actual results
     $snl->fin( File::Spec->catfile( 'expected','MANIFEST2' ) ), # expected results
     "",
     "generated MANIFEST");

#  ok:  7

ok(  $snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'Makefile.PL' ) ), # actual results
     $snl->fin( File::Spec->catfile('expected', 'Makefile2.PL') ), # expected results
     "",
     "generated Makefile.PL");

#  ok:  8

ok(  $s->scrub_date($snl->fin( File::Spec->catfile( 'packages', 'SVDtest1-0.01', 'README' ) )), # actual results
     $s->scrub_date($snl->fin( File::Spec->catfile('expected','README2') )), # expected results
     "",
     "generated README");

#  ok:  9

ok(  $s->scrub_architect($s->scrub_date($snl->fin( File::Spec->catfile( 'packages', 'SVDtest1.ppd' ) ))), # actual results
     $s->scrub_architect($s->scrub_date($snl->fin( File::Spec->catfile('expected','SVDtest2.ppd') ))), # expected results
     "",
     "generated ppd");

#  ok:  10

ok(  -e File::Spec->catfile( 'packages', 'SVDtest1-0.01.tar.gz' ), # actual results
     1, # expected results
     "",
     "generated distribution");

#  ok:  11

   # Perl code from C:
    #####
    # Clean up
    #
    unlink 'SVDtest1.log';
    unlink File::Spec->catfile('lib','SVDtest1.pm'),File::Spec->catfile('lib', 'module1.pm');
    rmtree 'packages';
    rmtree 't';




    finish();

__END__

=head1 NAME

Original.t - test script for ExtUtils::SVDmaker

=head1 SYNOPSIS

 Original.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Original.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


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

