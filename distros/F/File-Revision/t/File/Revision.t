#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.02';   # automatically generated file
$DATE = '2004/04/29';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Revision.t
#
# UUT: File::Revision
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::File::Revision;
#
# Don't edit this test script file, edit instead
#
# t::File::Revision;
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
   plan(tests => 26);

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
    use File::AnySpec;
    use File::Package;
    use File::Path;
    use File::Copy;
    my $fp = 'File::Package';
    my $uut = 'File::Revision';
    my ($file_spec, $from_file, $to_file);
    my ($backup_file, $rotate) = ('','');
    my $loaded = '';

ok(  $loaded = $fp->is_package_loaded($uut), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);

skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      "",
      "Load UUT");
 
#  ok:  2

   # Perl code from QC:
    my @revisions = (

    #  letter    number
    # -----------------
       ['-'   ,     0],
       ['Y'   ,    20],
       ['AA'  ,    21],
       ['WY'  ,   400],
       ['YY'  ,   420],
       ['AAA' ,   421],
    );

    my ($revision_letter, $revision_number);
    foreach (@revisions) {
       ($revision_letter, $revision_number) = @$_;

ok(  $uut->revision2num($revision_letter), # actual results
     $revision_number, # expected results
     "",
     "revision2num(\'$revision_letter\')");

#  ok:  3,5,7,9,11,13

ok(  $uut->num2revision($revision_number), # actual results
     $revision_letter, # expected results
     "",
     "num2revision(\'$revision_number\')");

#  ok:  4,6,8,10,12,14

   # Perl code from QC:
};

ok(  $uut->parse_options( 'myfile.myext', revision => 'AA', places => 3), # actual results
     bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '_',
   places => 3,
   pre_revision => '-',
   rev_letters => 1,
   revision => 'AA',
   revision_number => 21,
   top_revision_number => 8000,
   vol => '',
 }, 'Data::Startup'), # expected results
     "",
     "parse_options( 'myfile.myext', revision => 'AA', places => 3)");

#  ok:  15

ok(  $uut->parse_options( 'myfile.myext', revision => 'WW'), # actual results
     bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '',
   places => '',
   pre_revision => '-',
   rev_letters => 1,
   revision => 'WW',
   revision_number => 399,
   top_revision_number => '',
   vol => '',
 }, 'Data::Startup'), # expected results
     "",
     "parse_options( 'myfile.myext', revision => 'WW')");

#  ok:  16

ok(  $uut->parse_options( 'myfile.myext', revision => 10, places => 3), # actual results
     bless( { 
   base => 'myfile',
   dir => '',
   ext => '.myext', 
   lead_places => '0',
   places => 3,
   pre_revision => '-',
   rev_letters => 0,
   revision => 10,
   revision_number => 10,
   top_revision_number => '1000',
   vol => '',
 }, 'Data::Startup'), # expected results
     "",
     "parse_options( 'myfile.myext', revision => 10, places => 3)");

#  ok:  17

ok(       $uut->revision_file( 7, $uut->parse_options( 'myfile.myext',
     pre_revision => '', revision => 'AA')), # actual results
     'myfileG.myext', # expected results
     "",
     "revision_file( 7, parse_options( 'myfile.myext', pre_revision => '', revision => 'AA') )");

#  ok:  18

   # Perl code from C:
$file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');

ok(      [$uut->new_revision($file_spec, ext => '.bak', revision => 1,
    places => 6, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Drawings_/Erotica000001.bak'), '2'], # expected results
     "",
     "new_revision(ext => '.bak', revision => 1, places => 6, pre_revision => '')");

#  ok:  19

ok(  [$uut->new_revision($file_spec,  revision => 1000, places => 3, )], # actual results
     [undef, "Revision number 1000 overflowed limit of 1000.\n"], # expected results
     "",
     "new_revision(ext => '.htm' revision => 5, places => 6, pre_revision => '')");

#  ok:  20

ok(       [$uut->new_revision($file_spec,  base => 'SoftwareDiamonds', 
     ext => '.htm', revision => 5, places => 6, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Drawings_/SoftwareDiamonds000005.htm'), '6'], # expected results
     "",
     "new_revision(base => 'SoftwareDiamonds', ext => '.htm', places => 6, pre_revision => '')");

#  ok:  21

   # Perl code from C:
$file_spec = File::AnySpec->fspec2os('Unix', '_Drawings_/original.htm');

ok(  [$uut->new_revision($file_spec, revision => 0,  pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Drawings_/original.htm'), '1'], # expected results
     "",
     "new_revision($file_spec, revision => 0,  pre_revision => '')");

#  ok:  22

   # Perl code from C:
     rmtree( '_Revision_');
     mkpath( '_Revision_');
     $from_file = File::AnySpec->fspec2os('Unix', '_Drawings_/Erotica.pm');
     $to_file = File::AnySpec->fspec2os('Unix', '_Revision_/Erotica.pm');

ok(  [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Revision_/Erotica0.pm'),0], # expected results
     "",
     "$uut->rotate($to_file, rotate => 2) 1st time");

#  ok:  23

   # Perl code from C:
copy($from_file,$backup_file);

ok(  [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Revision_/Erotica1.pm',1),1], # expected results
     "",
     "$uut->rotate($to_file, rotate => 2) 2nd time");

#  ok:  24

   # Perl code from C:
copy($from_file,$backup_file);

ok(  [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2], # expected results
     "",
     "$uut->rotate($to_file, rotate => 2) 3rd time");

#  ok:  25

   # Perl code from C:
copy($from_file,$backup_file);

ok(  [($backup_file,$rotate) = $uut->rotate($to_file, rotate => 2, pre_revision => '')], # actual results
     [File::AnySpec->fspec2os('Unix','_Revision_/Erotica2.pm'),2], # expected results
     "",
     "$uut->rotate($to_file, rotate => 2) 4th time");

#  ok:  26

   # Perl code from C:
rmtree( '_Revision_');


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

Revision.t - test script for File::Revision

=head1 SYNOPSIS

 Revision.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Revision.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

/=over 4

/=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

/=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

/=back

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

