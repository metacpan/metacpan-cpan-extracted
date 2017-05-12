#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::File_SmartNL;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.05';
$DATE = '2004/05/13';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/File_SmartNL.pm' => [qw(0.05 2004/05/13), 'revised 0.04'],
    'MANIFEST' => [qw(0.05 2004/05/13), 'generated, replaces 0.04'],
    'Makefile.PL' => [qw(0.05 2004/05/13), 'generated, replaces 0.04'],
    'README' => [qw(0.05 2004/05/13), 'generated, replaces 0.04'],
    'lib/File/SmartNL.pm' => [qw(1.16 2004/05/13), 'revised 1.14'],
    't/File/SmartNL.d' => [qw(0.01 2004/05/03), 'unchanged'],
    't/File/SmartNL.pm' => [qw(0.01 2004/05/03), 'unchanged'],
    't/File/SmartNL.t' => [qw(0.11 2004/05/13), 'revised 0.1'],
    't/File/File/Package.pm' => [qw(1.17 2004/05/13), 'revised 1.16'],
    't/File/Test/Tech.pm' => [qw(1.25 2004/05/13), 'revised 1.22'],
    't/File/Data/Secs2.pm' => [qw(1.23 2004/05/13), 'revised 1.19'],
    't/File/Data/SecsPack.pm' => [qw(0.08 2004/05/13), 'revised 0.04'],
    't/File/Data/Startup.pm' => [qw(0.06 2004/05/13), 'revised 0.04'],

);

########
# The ExtUtils::SVDmaker module uses the data after the __DATA__ 
# token to automatically generate this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time ExtUtils::SVDmaker generates this file.
#
#



=head1 NAME

Docs::Site_SVD::File_SmartNL - translates any combination of CR and NL to the site \nl

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::File_SmartNL - translates any combination of CR and NL to the site \nl

 Revision: D

 Version: 0.05

 Date: 2004/05/13

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright © 2003 Software Diamonds

 Classification: NONE

=head1 1.0 SCOPE

This paragraph identifies and provides an overview
of the released files.

=head2 1.1 Identification

This release,
identified in L<3.2|/3.2 Inventory of software contents>,
is a collection of Perl modules that
extend the capabilities of the Perl language.

=head2 1.2 System overview

Different operating systems have different sequences for new-lines.
Historically when computers where first being born, 
one of the mainstays was the teletype. 
The teletype understood L<ASCII|http:://ascii.computerdiamonds.com>.
The teletype was an automated typewriter that would perform a 
carriage return when it received an ASCII Carriage Return (CR), \015,  character
and a new line when it received a Line Feed (LF), \012 character.

After some time came Unix. Unix had a tty driver that had a raw mode that
sent data unprocessed to a teletype and a cooked mode that performed all
kinds of translations and manipulations. Unix stored data internally using
a single NL character at the ends of lines. The tty driver in the cooked
mode would translate the NL character to a CR,LF sequence. 
When driving a teletype, the physicall action of performing a carriage
return took some time. By always putting the CR before the LF, the
teletype would actually still be performing a carriage return when it
received the LF and started a line feed.

After some time came DOS. Since the tty driver is actually one of the largest
peices of code for UNIX and DOS needed to run in very cramp space,
the DOS designers decided, that instead of writing a tailored down tty driver,
they would stored a CR,LF in the internal memory. Data internally would be
either 'text' data or 'binary' data.

Needless to say, after many years and many operating systems about every
conceivable method of storing new lines may be found amoung the various
operating systems.
This greatly complicates moving files from one operating system to
another operating system.

The smart NL methods in this package are designed to take any combination
of CR and NL and translate it into the special NL seqeunce used on the
site operating system. Thus, by using these methods, the messy problem of 
moving files between operating systems is mostly hidden in these methods.
The one thing not hidden is that the methods need to know if the data is
'text' data or 'binary' data. Normally, the assume the data is 'text' and
are overriden by setting the 'binary' option.

Note that Perl 5.6 introduced a built-in smart nl functionality as an IO discipline :crlf.
See I<Programming Perl> by Larry Wall, Tom Christiansen and Jon Orwant,
page 754, Chapter 29: Functions, open function.
For Perl 5.6 or above, the :crlf IO discipline may be preferable over the
smart_nl method of this package.
However, when moving code from one operating system to another system,
there will be target operating systems for the near and probable far future
that have not upgraded to Perl 5.6.

=head2 1.3 Document overview.

This document releases File::SmartNL version 0.05
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 File-SmartNL-0.05.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=item License.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

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

=back

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

=back

=head2 3.2 Inventory of software contents

The content of the released, compressed, archieve file,
consists of the following files:

 file                                                         version date       comment
 ------------------------------------------------------------ ------- ---------- ------------------------
 lib/Docs/Site_SVD/File_SmartNL.pm                            0.05    2004/05/13 revised 0.04
 MANIFEST                                                     0.05    2004/05/13 generated, replaces 0.04
 Makefile.PL                                                  0.05    2004/05/13 generated, replaces 0.04
 README                                                       0.05    2004/05/13 generated, replaces 0.04
 lib/File/SmartNL.pm                                          1.16    2004/05/13 revised 1.14
 t/File/SmartNL.d                                             0.01    2004/05/03 unchanged
 t/File/SmartNL.pm                                            0.01    2004/05/03 unchanged
 t/File/SmartNL.t                                             0.11    2004/05/13 revised 0.1
 t/File/File/Package.pm                                       1.17    2004/05/13 revised 1.16
 t/File/Test/Tech.pm                                          1.25    2004/05/13 revised 1.22
 t/File/Data/Secs2.pm                                         1.23    2004/05/13 revised 1.19
 t/File/Data/SecsPack.pm                                      0.08    2004/05/13 revised 0.04
 t/File/Data/Startup.pm                                       0.06    2004/05/13 revised 0.04


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Test-TestUtil-0.01

Originated

=item Test-TestUtil-0.02

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
test run

t/Test/TestUtil/TestUtil....Bareword "fspec_dirs" not allowed 
while "strict subs" in use at 

  /net/sunu991/disc1/.cpanplus/5.8.0/build/Test-TestUtil-0.01/blib/lib/Test/TestUtil.pm line 56.

Changed line 56 from

 my @dirs = (fspec_dirs) ? $from_package->splitdir( $fspec_dirs ) : ();

to

 my @dirs = ($fspec_dirs) ? $from_package->splitdir( $fspec_dirs ) : ();

This error is troublesome since the test passed on my system using Active Perl
under Microsoft NT. It should never have passed. 
This error is in a core method, I<fspec2fspec>,
that changes file specifications from one operating system
to another operating system.
This method has been in service unchanged for some time.

=item Test-TestUtil-0.03

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
test run

PERL_DL_NONLAZY=1 /usr/local/perl/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/TestUtil/TestUtil.t
t/Test/TestUtil/TestUtil....# Test 18 got: '$VAR1 = '';
' (t/Test/TestUtil/TestUtil.t at line 540 fail #17)
#    Expected: '$VAR1 = '\\=head1 Title Page

The I<pm2datah> method is not returning any data for Test 18. This will also cause
the test of I<pm2data>, test 19 to fail.
The I<pm2datah> is searching for the string "\n__DATA__\n".

The "\n" character on Perl is a logical end of line character sequence.
The "\n" end of line is different on Mr. Smokehouse's Unix operating system
than on my Windows NT operating system.
The test file was created under MSWin32 and uses a MSWin32 "\n".
Under UNIX, I<pm2datah> method will look for the Unix "\n"
and there will not be any.

Changed "\n__DATA__\n" to /[\012\015]__DATA__/. 

During the clean-up for CPAN, broke the I<format_hash_table>
method for tables in hash of hash format. 
Fixed the break, added test 29 to the I<t/Test/TestUtil/TestUtil.t>
test script for this
feature, and added a discusssion of this feature in
POD discription for I<format_hash_table>

=item Test-TestUtil-0.04

item our old friend visits again - DOS and UNIX text file incompatibility

This impacts other modules. We have to examine all modules for
this portability defect and correct any found defects.

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
and Kingpin <mthurn@carbon> test runs.

On Mr. Smokehouse's run email the got: VAR1 clearly showed extra white space
line that is not present in the expected: VAR1. 
In Mr. Kingpin's run the got: VAR1 and expected: VAR1 look visually the same.
However, the Unix found a difference(s) and failed the test.

For Mr. Smokehouse's run:

PERL_DL_NONLAZY=1 /usr/local/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/TestUtil/TestUtil.t
t/Test/TestUtil/TestUtil....NOK 18# Test 18 got: '$VAR1 = '\\=head1 Title Page


 Software Version Description


 for


 Docs::Site_SVD::File_SmartNL - translates any combination of CR and NL to the site \nl


 Revision: D

[snip]


(t/Test/TestUtil/TestUtil.t at line 565 fail #17)
#    Expected: '$VAR1 = '\\=head1 Title Page


 Software Version Description


 for


 Docs::Site_SVD::File_SmartNL - translates any combination of CR and NL to the site \nl

What we have before, was a totally "failure to communicate." aka Cool Hand Luke. 
VAR1 was empty. Now VAR1 has something. It is not completely dead.
One probable cause is the Unix operating system must be producing two Unix \012 new lines 
for a Microsoft single newline \015\012.
Without being able to examine the test with a debugger, the only way to verify
this is to provide the fix and see if the problem goes away when this great group
of testers try for the fourth time. 

Revised I<fin> method to take a handle, change I<pm2datah> method handle,  I<$fh>, 
to binary by adding a I<binmode $fh> statement, and pass the actual
thru the I<fin> method for test 18.

Use I<fin($fh)> to read in the data for I<pm2data>, test 19 Unit Under Test (UUT),
instead of using the raw file handle.

The I<fin> method takes any \015\012 combination and changes it into the 
logical Perl new line, I<"\n">, for the current operating system.

=item File-FileUtil-0.01

=over 4

=item *

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote:
A second thing that I would like you to reconsider is the naming of
"Test::TestUtil" respectively "Test::Tech" - neither of those is descriptive
of what the routines actually do or what the module implements. I would
recommend renaming them to something closer to your other modules, maybe
"Test::SVDMaker::Util" and "Test::SVDMaker::Tech", as some routines do not
seem to be specific to the Test::-suite but rather general
(format_array_table). Some parts (the "scrub" routines) might even better
live in another module namespace, "Test::Util::ScrubData" or something like
that.

Broke away all the file related methods from Test::TestUtil and
created this module File::FileUtil so the module name is
more descriptive of the methods within the module.

=item *

Broke the smart nl code out of the fin method and made it
is own separate method, smart_nl method. 

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote:
Perl, as Perl already does smart newline handling, (even though with the
advent of 5.8 even Unix-people have to learn the word "binmode" now :-)) 

The only place where I see Perl does smart newline handling is
the crlf IO displine introduce in Perl 5.6.  The File::FileUtil has
a use 5.001 so that 5.6 Perl built-ins cannot be used. Added comment
to smart_nl that for users with 5.6 Perl that it may be better to
use the built-in crlf IO discipline.

=item *

For the load_package method that uses a eval "require $package" to load the
package, the $@ does not capture all the warnings and error messages,
at least not with ActiveState Perl.  Added code the captures also the
warnings, by temporaily reassigning  $SIG(__WARN__), and added these
to the $@ error messages.

=item *

Added two new tests to verify the NOGO paths for the for the load_package
method.  One tests for load module failure looking for all the possilbe
information on why the module did not load. The other verifies that
the vocabulary is present after the loading the module.
This information is very helpful when you must remote debug a load
failure from CPAN testing whose is running on a different platform.

=back

=item File:-FileUtil-0.02

Added the method I<hex_dump>.

=item File-FileUtil-0.03

=over 4

=item test_lib2inc

Returns to parent directory of
the first t directory going up
from the test script instead of the
t directory.

=item find_t_roots

Added the function find_t_roots that
returns the parent directory of all
the directories in @INC

=back

=item File-SmartNL-0.01

Removed the methods for addressing the different CR LF 
combinations for NL between operating systems
 from the "File::FileUtil" module to their own module
"File::SmartNL" module.
The module name is now much more descriptive
of the routines in the module.

=item File-SmartNL-0.02

Removed the dump_hex method. This was a quite diagnostic.
If need to permanently dump_hex, use the "Data::HexDump"
or the "Data::Hexdumper" module.

=item File-SmartNL-0.03

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item File-SmartNL-0.04

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/File, the same directory as the test script
and deleting the test library File::TestPath program module.

Added better option support by using the C<Data::Startup> program module.

Added a subroutine interface.

=item File-SmartNL-0.05

Better test for a file handle. Do not close a file handle.

Changed C<$options->warn>, function, to C<$options->{warn}>, a value.

=back

=head2 3.4 Adaptation data.

This installation requires that the installation site
has the Perl programming language installed.
There are no other additional requirements or tailoring needed of 
configurations files, adaptation data or other software needed for this
installation particular to any installation site.

=head2 3.5 Related documents.

There are no related documents needed for the installation and
test of this release.

=head2 3.6 Installation instructions.

Instructions for installation, installation tests
and installation support are as follows:

=over 4

=item Installation Instructions.

To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Right click on 'File-SmartNL-0.05.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip File-SmartNL-0.05.tar.gz
 tar -xf File-SmartNL-0.05.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 None.


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/File/SmartNL.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There is still much work needed to ensure the quality 
of this module as follows:

=over 4

=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

=item *

All the tests are GO path tests. Should add
NOGO tests.

=item *

Add the requirements addressed as I<# R: >
comment to the tests

=back

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=item POD

Plain Old Documentation

=back

=head1 2.0 SEE ALSO

=over 4

=item L<File::SmartNL|File::SmartNL> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: File-SmartNL^
REPOSITORY_DIR: packages^

VERSION : 0.05^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.04^
REVISION: D^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: translates any combination of CR and NL to the site \nl^
TITLE   : Docs::Site_SVD::File_SmartNL - translates any combination of CR and NL to the site \nl^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/File/SmartNL.pm
t/File/SmartNL.*
lib/File/Package.pm => t/File/File/Package.pm
lib/Test/Tech.pm => t/File/Test/Tech.pm
lib/Data/Secs2.pm => t/File/Data/Secs2.pm
lib/Data/SecsPack.pm => t/File/Data/SecsPack.pm
lib/Data/Startup.pm => t/File/Data/Startup.pm
^

PREREQ_PM:  ^
README_PODS: lib/File/SmartNL.pm^
TESTS: t/File/SmartNL.t^
EXE_FILES:  ^

CHANGES:

Changes are as follows:

\=over 4

\=item Test-TestUtil-0.01

Originated

\=item Test-TestUtil-0.02

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
test run

t/Test/TestUtil/TestUtil....Bareword "fspec_dirs" not allowed 
while "strict subs" in use at 

  /net/sunu991/disc1/.cpanplus/5.8.0/build/Test-TestUtil-0.01/blib/lib/Test/TestUtil.pm line 56.

Changed line 56 from

 my @dirs = (fspec_dirs) ? $from_package->splitdir( $fspec_dirs ) : ();

to

 my @dirs = ($fspec_dirs) ? $from_package->splitdir( $fspec_dirs ) : ();

This error is troublesome since the test passed on my system using Active Perl
under Microsoft NT. It should never have passed. 
This error is in a core method, I<fspec2fspec>,
that changes file specifications from one operating system
to another operating system.
This method has been in service unchanged for some time.

\=item Test-TestUtil-0.03

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
test run

PERL_DL_NONLAZY=1 /usr/local/perl/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/TestUtil/TestUtil.t
t/Test/TestUtil/TestUtil....# Test 18 got: '$VAR1 = '';
' (t/Test/TestUtil/TestUtil.t at line 540 fail #17)
#    Expected: '$VAR1 = '\\=head1 Title Page

The I<pm2datah> method is not returning any data for Test 18. This will also cause
the test of I<pm2data>, test 19 to fail.
The I<pm2datah> is searching for the string "\n__DATA__\n".

The "\n" character on Perl is a logical end of line character sequence.
The "\n" end of line is different on Mr. Smokehouse's Unix operating system
than on my Windows NT operating system.
The test file was created under MSWin32 and uses a MSWin32 "\n".
Under UNIX, I<pm2datah> method will look for the Unix "\n"
and there will not be any.

Changed "\n__DATA__\n" to /[\012\015]__DATA__/. 

During the clean-up for CPAN, broke the I<format_hash_table>
method for tables in hash of hash format. 
Fixed the break, added test 29 to the I<t/Test/TestUtil/TestUtil.t>
test script for this
feature, and added a discusssion of this feature in
POD discription for I<format_hash_table>

\=item Test-TestUtil-0.04

item our old friend visits again - DOS and UNIX text file incompatibility

This impacts other modules. We have to examine all modules for
this portability defect and correct any found defects.

Correct failure from Josts Smokehouse" <Jost.Krieger+smokeback@ruhr-uni-bochum.de>
and Kingpin <mthurn@carbon> test runs.

On Mr. Smokehouse's run email the got: VAR1 clearly showed extra white space
line that is not present in the expected: VAR1. 
In Mr. Kingpin's run the got: VAR1 and expected: VAR1 look visually the same.
However, the Unix found a difference(s) and failed the test.

For Mr. Smokehouse's run:

PERL_DL_NONLAZY=1 /usr/local/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/TestUtil/TestUtil.t
t/Test/TestUtil/TestUtil....NOK 18# Test 18 got: '$VAR1 = '\\=head1 Title Page


 Software Version Description


 for


 ${TITLE}


 Revision: ${REVISION}

[snip]


(t/Test/TestUtil/TestUtil.t at line 565 fail #17)
#    Expected: '$VAR1 = '\\=head1 Title Page


 Software Version Description


 for


 ${TITLE}

What we have before, was a totally "failure to communicate." aka Cool Hand Luke. 
VAR1 was empty. Now VAR1 has something. It is not completely dead.
One probable cause is the Unix operating system must be producing two Unix \012 new lines 
for a Microsoft single newline \015\012.
Without being able to examine the test with a debugger, the only way to verify
this is to provide the fix and see if the problem goes away when this great group
of testers try for the fourth time. 

Revised I<fin> method to take a handle, change I<pm2datah> method handle,  I<$fh>, 
to binary by adding a I<binmode $fh> statement, and pass the actual
thru the I<fin> method for test 18.

Use I<fin($fh)> to read in the data for I<pm2data>, test 19 Unit Under Test (UUT),
instead of using the raw file handle.

The I<fin> method takes any \015\012 combination and changes it into the 
logical Perl new line, I<"\n">, for the current operating system.

\=item File-FileUtil-0.01

\=over 4

\=item *

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote:
A second thing that I would like you to reconsider is the naming of
"Test::TestUtil" respectively "Test::Tech" - neither of those is descriptive
of what the routines actually do or what the module implements. I would
recommend renaming them to something closer to your other modules, maybe
"Test::SVDMaker::Util" and "Test::SVDMaker::Tech", as some routines do not
seem to be specific to the Test::-suite but rather general
(format_array_table). Some parts (the "scrub" routines) might even better
live in another module namespace, "Test::Util::ScrubData" or something like
that.

Broke away all the file related methods from Test::TestUtil and
created this module File::FileUtil so the module name is
more descriptive of the methods within the module.

\=item *

Broke the smart nl code out of the fin method and made it
is own separate method, smart_nl method. 

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote:
Perl, as Perl already does smart newline handling, (even though with the
advent of 5.8 even Unix-people have to learn the word "binmode" now :-)) 

The only place where I see Perl does smart newline handling is
the crlf IO displine introduce in Perl 5.6.  The File::FileUtil has
a use 5.001 so that 5.6 Perl built-ins cannot be used. Added comment
to smart_nl that for users with 5.6 Perl that it may be better to
use the built-in crlf IO discipline.

\=item *

For the load_package method that uses a eval "require $package" to load the
package, the $@ does not capture all the warnings and error messages,
at least not with ActiveState Perl.  Added code the captures also the
warnings, by temporaily reassigning  $SIG(__WARN__), and added these
to the $@ error messages.

\=item *

Added two new tests to verify the NOGO paths for the for the load_package
method.  One tests for load module failure looking for all the possilbe
information on why the module did not load. The other verifies that
the vocabulary is present after the loading the module.
This information is very helpful when you must remote debug a load
failure from CPAN testing whose is running on a different platform.

\=back

\=item File:-FileUtil-0.02

Added the method I<hex_dump>.

\=item File-FileUtil-0.03

\=over 4

\=item test_lib2inc

Returns to parent directory of
the first t directory going up
from the test script instead of the
t directory.

\=item find_t_roots

Added the function find_t_roots that
returns the parent directory of all
the directories in @INC

\=back

\=item File-SmartNL-0.01

Removed the methods for addressing the different CR LF 
combinations for NL between operating systems
 from the "File::FileUtil" module to their own module
"File::SmartNL" module.
The module name is now much more descriptive
of the routines in the module.

\=item File-SmartNL-0.02

Removed the dump_hex method. This was a quite diagnostic.
If need to permanently dump_hex, use the "Data::HexDump"
or the "Data::Hexdumper" module.

\=item File-SmartNL-0.03

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item File-SmartNL-0.04

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/File, the same directory as the test script
and deleting the test library File::TestPath program module.

Added better option support by using the C<Data::Startup> program module.

Added a subroutine interface.

\=item File-SmartNL-0.05

Better test for a file handle. Do not close a file handle.

Changed C<$options->warn>, function, to C<$options->{warn}>, a value.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
Different operating systems have different sequences for new-lines.
Historically when computers where first being born, 
one of the mainstays was the teletype. 
The teletype understood L<ASCII|http:://ascii.computerdiamonds.com>.
The teletype was an automated typewriter that would perform a 
carriage return when it received an ASCII Carriage Return (CR), \015,  character
and a new line when it received a Line Feed (LF), \012 character.

After some time came Unix. Unix had a tty driver that had a raw mode that
sent data unprocessed to a teletype and a cooked mode that performed all
kinds of translations and manipulations. Unix stored data internally using
a single NL character at the ends of lines. The tty driver in the cooked
mode would translate the NL character to a CR,LF sequence. 
When driving a teletype, the physicall action of performing a carriage
return took some time. By always putting the CR before the LF, the
teletype would actually still be performing a carriage return when it
received the LF and started a line feed.

After some time came DOS. Since the tty driver is actually one of the largest
peices of code for UNIX and DOS needed to run in very cramp space,
the DOS designers decided, that instead of writing a tailored down tty driver,
they would stored a CR,LF in the internal memory. Data internally would be
either 'text' data or 'binary' data.

Needless to say, after many years and many operating systems about every
conceivable method of storing new lines may be found amoung the various
operating systems.
This greatly complicates moving files from one operating system to
another operating system.

The smart NL methods in this package are designed to take any combination
of CR and NL and translate it into the special NL seqeunce used on the
site operating system. Thus, by using these methods, the messy problem of 
moving files between operating systems is mostly hidden in these methods.
The one thing not hidden is that the methods need to know if the data is
'text' data or 'binary' data. Normally, the assume the data is 'text' and
are overriden by setting the 'binary' option.

Note that Perl 5.6 introduced a built-in smart nl functionality as an IO discipline :crlf.
See I<Programming Perl> by Larry Wall, Tom Christiansen and Jon Orwant,
page 754, Chapter 29: Functions, open function.
For Perl 5.6 or above, the :crlf IO discipline may be preferable over the
smart_nl method of this package.
However, when moving code from one operating system to another system,
there will be target operating systems for the near and probable far future
that have not upgraded to Perl 5.6.
^

PROBLEMS:
There is still much work needed to ensure the quality 
of this module as follows:

\=over 4

\=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

\=item *

All the tests are GO path tests. Should add
NOGO tests.

\=item *

Add the requirements addressed as I<# R: >
comment to the tests

\=back

^

LICENSE:
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
^


INSTALLATION:
To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

${REPOSITORY}

Right click on '${DIST_FILE}' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip ${BASE_DIST_FILE}.tar.${COMPRESS_SUFFIX}
 tar -xf ${BASE_DIST_FILE}.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

NOTES:
The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=item POD

Plain Old Documentation

\=back
^

SEE_ALSO: 
\=over 4

\=item L<File::SmartNL|File::SmartNL> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back

^

HTML:

^
~-~




