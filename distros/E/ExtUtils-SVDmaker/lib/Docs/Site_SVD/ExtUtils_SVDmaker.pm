#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::ExtUtils_SVDmaker;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.10';
$DATE = '2004/05/25';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/ExtUtils_SVDmaker.pm' => [qw(0.10 2004/05/25), 'revised 0.09'],
    'MANIFEST' => [qw(0.10 2004/05/25), 'generated, replaces 0.09'],
    'Makefile.PL' => [qw(0.10 2004/05/25), 'generated, replaces 0.09'],
    'README' => [qw(0.10 2004/05/25), 'generated, replaces 0.09'],
    'lib/ExtUtils/SVDmaker.pm' => [qw(1.12 2004/05/25), 'revised 1.11'],
    't/ExtUtils/SVDmaker/Original.d' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Original.pm' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Original.t' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Revise.d' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Revise.pm' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Revise.t' => [qw(0.01 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/vmake.pl' => [qw(1.04 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Test/Tech.pm' => [qw(1.26 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Text/Scrub.pm' => [qw(1.17 2004/05/25), 'new'],
    't/ExtUtils/SVDmaker/Data/Secs2.pm' => [qw(1.26 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Data/Str2Num.pm' => [qw(0.08 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Data/Startup.pm' => [qw(0.07 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Test.pm' => [qw(0.10 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Algorithm/Diff.pm' => [qw(0.10 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/Pod/Text.pm' => [qw(0.10 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Makefile' => [qw(0.04 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Makefile2.PL' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Makefile3.PL' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/MANIFEST2' => [qw(0.04 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/module0A.pm' => [qw(0.04 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/module0B.pm' => [qw(0.04 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/module2.pm' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/README2' => [qw(0.05 2004/05/13), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/README3' => [qw(0.06 2004/05/13), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDmaker0.pm' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest-0.01.html' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest.ppd' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest0A.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest0A.t' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest0B.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest0B.t' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest1-0.01.tar.gz' => [qw(0.09 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest1.ppd' => [qw(0.09 2004/05/25), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest2-0.01.html' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest2.pm' => [qw(0.05 2004/05/13), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest2.ppd' => [qw(0.04 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest2.t' => [qw(0.04 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest3-0.02.html' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest3.pm' => [qw(0.06 2004/05/13), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/SVDtest3.ppd' => [qw(0.03 2003/08/04), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Test/Tech.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Data/Secs2.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Data/SecsPack.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/Data/Startup.pm' => [qw(0.05 2004/05/11), 'unchanged'],
    't/ExtUtils/SVDmaker/expected/File/Package.pm' => [qw(0.05 2004/05/11), 'unchanged'],

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

Docs::Site_SVD::ExtUtils_SVDmaker - Create CPAN distributions

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::ExtUtils_SVDmaker - Create CPAN distributions

 Revision: J

 Version: 0.10

 Date: 2004/05/25

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>

 Copyright: copyright 2003 Software Diamonds

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

The system is the Perl programming language software.
As established by the L<Perl referenced documents|/2.0 SEE ALSO>,
the "L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>" 
program module extends the Perl language.

The "ExtUtils::SVDmaker" module extends
the automation of releasing a Perl distribution file as
follows:

=over 4

=item *

The input data for the "ExtUtils::SVDmaker" module
is a form database in the __DATA__ section of the SVD program module.
The database is in the format of 
L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>.
This is an efficient text database that is very close in
format to hard copy forms and may be edited by text editors

=item *

The "ExtUtils::SVDmaker" module compares the contents of the current release with the previous
release and automatically updates the version and date for files that
have changed

=item *

"ExtUtils::SVDmaker" module generates a SVD program module POD from the form database data contained
in the __DATA__ section of the SVD program module.

=item *

"ExtUtils::SVDmaker" module generates the MANIFEST, README and Makefile.PL distribution
files from the form database data

=item *

"ExtUtils::SVDmaker" module builds the distribution *.tar.gz file using
Perl code instead of starting tar and gzip process via a makefile build
by MakeFile.PL. This greatly increases portability and performance.

=item *

Runs the installation tests on the distribution files using the
"Test::Harness" module directly. It does not build any makefile 
using the MakeFile.PL and starting a Test::Harness process via
the makefile. This greatly increases portability and performance.

=back

The L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> module is one of the
end user, functional interface modules for the US DOD STD2167A bundle.
Two STD2167A bundle end user modules are as follows:

=over 4

=item L<Test::STDmaker|Test::STDmaker> module

generates Test script, demo script and STD document POD from
a text database in the Data::Port::FileTYpe::FormDB format.

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> module

generates SVD document POD and distribution *.tar.gz file including
a generated Makefile.PL README and MANIFEST file from 
a text database in the Data::Port::FileTYpe::FormDB format.

=back

=head2 1.3 Document overview.

This document releases ExtUtils::SVDmaker version 0.10
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 ExtUtils-SVDmaker-0.10.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=item License.

These files are a POD derived works from the hard copy public domain version
freely distributed by the United States Federal Government.

The original hardcopy version is always the authoritative document
and any conflict between the original hardcopy version governs whenever
there is any conflict. In more explicit terms, any conflict is a 
transcription error in converting the origninal hard-copy version to
this POD format. Software Diamonds assumes no responsible for such errors.

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
 lib/Docs/Site_SVD/ExtUtils_SVDmaker.pm                       0.10    2004/05/25 revised 0.09
 MANIFEST                                                     0.10    2004/05/25 generated, replaces 0.09
 Makefile.PL                                                  0.10    2004/05/25 generated, replaces 0.09
 README                                                       0.10    2004/05/25 generated, replaces 0.09
 lib/ExtUtils/SVDmaker.pm                                     1.12    2004/05/25 revised 1.11
 t/ExtUtils/SVDmaker/Original.d                               0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Original.pm                              0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Original.t                               0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Revise.d                                 0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Revise.pm                                0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Revise.t                                 0.01    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/vmake.pl                                 1.04    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Test/Tech.pm                             1.26    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Text/Scrub.pm                            1.17    2004/05/25 new
 t/ExtUtils/SVDmaker/Data/Secs2.pm                            1.26    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Data/Str2Num.pm                          0.08    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Data/Startup.pm                          0.07    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Test.pm                                  0.10    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Algorithm/Diff.pm                        0.10    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/Pod/Text.pm                              0.10    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/expected/Makefile                        0.04    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/Makefile2.PL                    0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/Makefile3.PL                    0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/MANIFEST2                       0.04    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/module0A.pm                     0.04    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/module0B.pm                     0.04    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/module2.pm                      0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/README2                         0.05    2004/05/13 unchanged
 t/ExtUtils/SVDmaker/expected/README3                         0.06    2004/05/13 unchanged
 t/ExtUtils/SVDmaker/expected/SVDmaker0.pm                    0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest-0.01.html               0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest.ppd                     0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest0A.pm                    0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest0A.t                     0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest0B.pm                    0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest0B.t                     0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest1-0.01.tar.gz            0.09    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest1.ppd                    0.09    2004/05/25 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest2-0.01.html              0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest2.pm                     0.05    2004/05/13 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest2.ppd                    0.04    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest2.t                      0.04    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest3-0.02.html              0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest3.pm                     0.06    2004/05/13 unchanged
 t/ExtUtils/SVDmaker/expected/SVDtest3.ppd                    0.03    2003/08/04 unchanged
 t/ExtUtils/SVDmaker/expected/Test/Tech.pm                    0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/Data/Secs2.pm                   0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/Data/SecsPack.pm                0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/Data/Startup.pm                 0.05    2004/05/11 unchanged
 t/ExtUtils/SVDmaker/expected/File/Package.pm                 0.05    2004/05/11 unchanged


=head2 3.3 Changes

Changes are as follows:

=over 4

=item ExtUtils::SVDmaker-0.01

Change the name from SVD::SVDmaker to ExtUtils::SVDmaker. 
The CPAN keepers have a no new top levels unless absolutely necessary policy.

Added tests.

=item ExtUtils::SVDmaker-0.02

Drop tailing and starting white space for SEE_ALSO.
Extra lines feeds was causing pod2hmtl to misbehave
and not pick up on L< links >.

Fixed error in calculation of $formDB->{PM_File_Relative} 

Removed requirement for external Unix commands. 
Added code to replace the extenal Unix commands.
The is no longer the need for nmake, make, tar, gzip, gunzip.

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item ExtUtils::SVDmaker-0.03

Fix some more problems due to Archive::Tar does tar correctly,
(length of file contents does not match length in header) when
use non Unix "\n"

=item ExtUtils::SVDmaker-0.04

Broke out the tar and gzip software into the modules Archive::TarGzip.
Hopefully dealing with the Text '\n' problem by isolating and testing
these functions separately. They also have high probability of being
useful outside this module.

=item ExtUtils::SVDmaker-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/ExtUtils, the same directory as the test script
and deleting the test library C<File::TestPath> program module.

Added addition code to the test target to isolate the program module
under test. Before the test, the @INC directories are stipped back
to the first one contain Perl. This is to isolate the test to only
the virgin Perl distribution program modules. The test target then
creates a require directory under the same directory as the test script
and copies over all prequesite program modules to this directory.
After the test target performs the test it restores @INC and removes
the require directory tree.

Hopefully this will eliminate many time consuming distributions failure
due to using program modules that that are not part of the distributions.

SWitch from C<DataPort::Maker> to C<File::Maker>. Eliminated the use
of C<File::Data> and C<File::TestPath>

=item ExtUtils::SVDmaker-0.06

Verbatim NAME section from template. Replaced.

=item ExtUtils::SVDmaker-0.07

Escape the SVD template POD '=' commands so that they do not confuse
the CPAN to which is the real POD.

=item ExtUtils::SVDmaker-0.08

Fixed typo in the NAME section.

=item ExtUtils::SVDmaker-0.09

 Subject: FAIL ExtUtils-SVDmaker-0.08 sparc-linux 2.4.21-pre7 
 From: alian@cpan.org (alian) 

TEST 9 FAILURE

 t/ExtUtils/SVDmaker/SVDmaker....# Test 9 got: 'NAME

 [snip]

 1.0 SCOPE
    This paragraph identifies and provides an overview of the released
    files.


  1.1 Identification
    This release, identified in 3.2, is a collection of Perl modules that
    extend the capabilities of the Perl language.

 [snip] 

 ' (t/ExtUtils/SVDmaker/SVDmaker.t at line 265)
 #   Expected: 'NAME

 1.0 SCOPE
    This paragraph identifies and provides an overview of the released
    files.


  1.1 Identification


    This release, identified in 3.2, is a collection of Perl modules that
    extend the capabilities of the Perl language.

 [snip]


TEST 10 FAILURE

 # Test 10 got: '<SOFTPKG NAME="SVDtest1" VERSION="0,01,0,0">
 [snip]
                <OS NAME="linux" />
 [snip]
 </SOFTPKG>
 ' (t/ExtUtils/SVDmaker/SVDmaker.t at line 272)
 #    Expected: '<SOFTPKG NAME="SVDtest1" VERSION="0,01,0,0">
 [snip]
                <OS NAME="MSWin32" />
 [snip]
 </SOFTPKG>

TEST 12 FAILURE

 # Test 12 got: <UNDEF> (t/ExtUtils/SVDmaker/SVDmaker.t at line 315)
 #    Expected: '1' (Required SVD DB field, DISTNAME, missing.
 #Use of uninitialized value in substitution (s///) at /home/alian/.cpanplus/5.8.4/build/ExtUtils-SVDmaker-0.08/blib/lib/ExtUtils/SVDmaker.pm line 489, <DATA> line 698.

=item ExtUtils::SVDmaker-0.10

Failure: 

Failuring test 10 of both C<original.t> test script and the
C<revise.t> test script.

 Subject: FAIL ExtUtils-SVDmaker-0.09 ppc-linux 2.4.19-4a 
 From: alian@cpan.org (CPAN Tester + CPAN++ automate) 
 t/ExtUtils/SVDmaker/Original....# Test 10 got: 
 
 [snip]

 #     - "\t\t<OS NAME=\"MSWin32\" />\n"
 #     + "\t\t<OS NAME=\"linux\" />\n"

 [snip]

Analysis:

Not using the lastest version of C<Test::Scrub> which will wild card
out C<OS NAME>

Corrective:

Put lastest version in C<ExtUtils::SVDmaker use>, the C<Makerfile.PL> prerequesite
and also load the lastes in the test C<t::Test::ExtUtils::SVDmaker> repository.
(Quite a few times CPAN package does not handle prereuesites as expected)

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

To installed the release package, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Right click on 'ExtUtils-SVDmaker-0.10.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip ExtUtils-SVDmaker-0.10.tar.gz
 tar -xf ExtUtils-SVDmaker-0.10.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

VERY IMPORTANT:

The distribution package contains the cover
C<vmake.pl> perl command script.
Manually copy this into the execution path
in order to use C<SVDmaker> from the
command line. Rename it if there is a
name conflict or just do not like the name.

=item Prerequistes.

 'Archive::TarGzip' => '0.03',
 'File::AnySpec' => '1.13',
 'File::Maker' => '0.03',
 'File::Package' => '1.16',
 'File::SmartNL' => '1.14',
 'File::Where' => '0',
 'Text::Replace' => '0',
 'Text::Column' => '0',
 'Text::Scrub' => '1.17',
 'Tie::Form' => '0.01',
 'Tie::Layers' => '0.04',
 'Tie::Gzip' => '1.15',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/ExtUtils/SVDmaker/Original.t
 t/ExtUtils/SVDmaker/Revise.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

Open issues are as follows:

=over 4

=item *

Should format $svd->{PREREQ_PM_TEXT} into a table.

=item *

Need to generted the requirements and add the
addressed requirements to the tests.

=back

=head1 4.0 NOTES

This document uses the following acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a test file

=item DID

Data Item Description

=item DOD

Department of Defense

=item POD

Plain Old Documentation

=item SVD

Software Version Description

=item STD

Software Test Description

=item US

United States

=back

=head1 2.0 SEE ALSO

=over 4

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

=item L<Test::STDmaker|Test::STDmaker>

=item L<Test::Tech|Test::Tech>

=item L<Test|Test>

=item L<File::Maker|File::Maker>

=item L<Tie::Form|Tie::Form>

=item L<Tie::Layers|Tie::Layers>

=item L<Text::Column|Text::Column>

=item L<Text::Replace|Text::Replace>

=item L<Text::Scrub|Text::Scrub>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=item L<Software Version Description (SVD) DID|Docs::US_DOD::SVD>

=back

=for html


=cut

1;

__DATA__

DISTNAME: ExtUtils-SVDmaker^

VERSION : 0.10^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.09^
REVISION: J^

AUTHOR  : SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>^
ABSTRACT: 
Generate Software Version Description (SVD) program modules and 
distribution files for CPAN.
^

TITLE: Docs::Site_SVD::ExtUtils_SVDmaker - Create CPAN distributions^
END_USER: General Public^
COPYRIGHT: copyright 2003 Software Diamonds^
CLASSIFICATION: NONE^

CSS: help.css^
TEMPLATE:  ^
SVD_FSPEC: Unix^ 

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^
REPOSITORY_DIR: packages^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

CHANGE2CURRENT:  ^
RESTRUCTURE:  ^

AUTO_REVISE:
lib/ExtUtils/SVDmaker.pm
t/ExtUtils/SVDmaker/*
t/ExtUtils/SVDmaker/lib/*
bin/vmake.pl => t/ExtUtils/SVDmaker/vmake.pl
lib/Test/Tech.pm => t/ExtUtils/SVDmaker/Test/Tech.pm
lib/Text/Scrub.pm => t/ExtUtils/SVDmaker/Text/Scrub.pm
lib/Data/Secs2.pm => t/ExtUtils/SVDmaker/Data/Secs2.pm
lib/Data/Str2Num.pm => t/ExtUtils/SVDmaker/Data/Str2Num.pm
lib/Data/Startup.pm => t/ExtUtils/SVDmaker/Data/Startup.pm
^

REPLACE: 
libperl/Test.pm => t/ExtUtils/SVDmaker/Test.pm
libperl/Algorithm/Diff.pm  => t/ExtUtils/SVDmaker/Algorithm/Diff.pm
libperl/Pod/Text.pm  => t/ExtUtils/SVDmaker/Pod/Text.pm
t/ExtUtils/SVDmaker/expected/*
t/ExtUtils/SVDmaker/expected/Test/*
t/ExtUtils/SVDmaker/expected/Data/*
t/ExtUtils/SVDmaker/expected/File/*
^

PREREQ_PM:
'Archive::TarGzip' => '0.03',
'File::AnySpec' => '1.13',
'File::Maker' => '0.03',
'File::Package' => '1.16',
'File::SmartNL' => '1.14',
'File::Where' => '0',
'Text::Replace' => '0',
'Text::Column' => '0',
'Text::Scrub' => '1.17',
'Tie::Form' => '0.01',
'Tie::Layers' => '0.04',
'Tie::Gzip' => '1.15',
^

TESTS: 
t/ExtUtils/SVDmaker/Original.t
t/ExtUtils/SVDmaker/Revise.t
^

README_PODS: lib/ExtUtils/SVDmaker.pm^
EXE_FILES: ^

CHANGES:
Changes are as follows:

\=over 4

\=item ExtUtils::SVDmaker-0.01

Change the name from SVD::SVDmaker to ExtUtils::SVDmaker. 
The CPAN keepers have a no new top levels unless absolutely necessary policy.

Added tests.

\=item ExtUtils::SVDmaker-0.02

Drop tailing and starting white space for SEE_ALSO.
Extra lines feeds was causing pod2hmtl to misbehave
and not pick up on L< links >.

Fixed error in calculation of $formDB->{PM_File_Relative} 

Removed requirement for external Unix commands. 
Added code to replace the extenal Unix commands.
The is no longer the need for nmake, make, tar, gzip, gunzip.

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item ExtUtils::SVDmaker-0.03

Fix some more problems due to Archive::Tar does tar correctly,
(length of file contents does not match length in header) when
use non Unix "\n"

\=item ExtUtils::SVDmaker-0.04

Broke out the tar and gzip software into the modules Archive::TarGzip.
Hopefully dealing with the Text '\n' problem by isolating and testing
these functions separately. They also have high probability of being
useful outside this module.

\=item ExtUtils::SVDmaker-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/ExtUtils, the same directory as the test script
and deleting the test library C<File::TestPath> program module.

Added addition code to the test target to isolate the program module
under test. Before the test, the @INC directories are stipped back
to the first one contain Perl. This is to isolate the test to only
the virgin Perl distribution program modules. The test target then
creates a require directory under the same directory as the test script
and copies over all prequesite program modules to this directory.
After the test target performs the test it restores @INC and removes
the require directory tree.

Hopefully this will eliminate many time consuming distributions failure
due to using program modules that that are not part of the distributions.

SWitch from C<DataPort::Maker> to C<File::Maker>. Eliminated the use
of C<File::Data> and C<File::TestPath>

\=item ExtUtils::SVDmaker-0.06

Verbatim NAME section from template. Replaced.

\=item ExtUtils::SVDmaker-0.07

Escape the SVD template POD '=' commands so that they do not confuse
the CPAN to which is the real POD.

\=item ExtUtils::SVDmaker-0.08

Fixed typo in the NAME section.

\=item ExtUtils::SVDmaker-0.09

 Subject: FAIL ExtUtils-SVDmaker-0.08 sparc-linux 2.4.21-pre7 
 From: alian@cpan.org (alian) 

TEST 9 FAILURE

 t/ExtUtils/SVDmaker/SVDmaker....# Test 9 got: 'NAME

 [snip]

 1.0 SCOPE
    This paragraph identifies and provides an overview of the released
    files.


  1.1 Identification
    This release, identified in 3.2, is a collection of Perl modules that
    extend the capabilities of the Perl language.

 [snip] 

 ' (t/ExtUtils/SVDmaker/SVDmaker.t at line 265)
 #   Expected: 'NAME

 1.0 SCOPE
    This paragraph identifies and provides an overview of the released
    files.


  1.1 Identification


    This release, identified in 3.2, is a collection of Perl modules that
    extend the capabilities of the Perl language.

 [snip]


TEST 10 FAILURE

 # Test 10 got: '<SOFTPKG NAME="SVDtest1" VERSION="0,01,0,0">
 [snip]
                <OS NAME="linux" />
 [snip]
 </SOFTPKG>
 ' (t/ExtUtils/SVDmaker/SVDmaker.t at line 272)
 #    Expected: '<SOFTPKG NAME="SVDtest1" VERSION="0,01,0,0">
 [snip]
                <OS NAME="MSWin32" />
 [snip]
 </SOFTPKG>

TEST 12 FAILURE

 # Test 12 got: <UNDEF> (t/ExtUtils/SVDmaker/SVDmaker.t at line 315)
 #    Expected: '1' (Required SVD DB field, DISTNAME, missing.
 #Use of uninitialized value in substitution (s///) at /home/alian/.cpanplus/5.8.4/build/ExtUtils-SVDmaker-0.08/blib/lib/ExtUtils/SVDmaker.pm line 489, <DATA> line 698.

\=item ExtUtils::SVDmaker-0.10

Failure: 

Failuring test 10 of both C<original.t> test script and the
C<revise.t> test script.

 Subject: FAIL ExtUtils-SVDmaker-0.09 ppc-linux 2.4.19-4a 
 From: alian@cpan.org (CPAN Tester + CPAN++ automate) 
 t/ExtUtils/SVDmaker/Original....# Test 10 got: 
 
 [snip]

 #     - "\t\t<OS NAME=\"MSWin32\" />\n"
 #     + "\t\t<OS NAME=\"linux\" />\n"

 [snip]

Analysis:

Not using the lastest version of C<Test::Scrub> which will wild card
out C<OS NAME>

Corrective:

Put lastest version in C<ExtUtils::SVDmaker use>, the C<Makerfile.PL> prerequesite
and also load the lastes in the test C<t::Test::ExtUtils::SVDmaker> repository.
(Quite a few times CPAN package does not handle prereuesites as expected)

\=back

^

CAPABILITIES:
The system is the Perl programming language software.
As established by the L<Perl referenced documents|/2.0 SEE ALSO>,
the "L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>" 
program module extends the Perl language.

The "ExtUtils::SVDmaker" module extends
the automation of releasing a Perl distribution file as
follows:

\=over 4

\=item *

The input data for the "ExtUtils::SVDmaker" module
is a form database in the __DATA__ section of the SVD program module.
The database is in the format of 
L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>.
This is an efficient text database that is very close in
format to hard copy forms and may be edited by text editors

\=item *

The "ExtUtils::SVDmaker" module compares the contents of the current release with the previous
release and automatically updates the version and date for files that
have changed

\=item *

"ExtUtils::SVDmaker" module generates a SVD program module POD from the form database data contained
in the __DATA__ section of the SVD program module.

\=item *

"ExtUtils::SVDmaker" module generates the MANIFEST, README and Makefile.PL distribution
files from the form database data

\=item *

"ExtUtils::SVDmaker" module builds the distribution *.tar.gz file using
Perl code instead of starting tar and gzip process via a makefile build
by MakeFile.PL. This greatly increases portability and performance.

\=item *

Runs the installation tests on the distribution files using the
"Test::Harness" module directly. It does not build any makefile 
using the MakeFile.PL and starting a Test::Harness process via
the makefile. This greatly increases portability and performance.

\=back

The L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> module is one of the
end user, functional interface modules for the US DOD STD2167A bundle.
Two STD2167A bundle end user modules are as follows:

\=over 4

\=item L<Test::STDmaker|Test::STDmaker> module

generates Test script, demo script and STD document POD from
a text database in the Data::Port::FileTYpe::FormDB format.

\=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> module

generates SVD document POD and distribution *.tar.gz file including
a generated Makefile.PL README and MANIFEST file from 
a text database in the Data::Port::FileTYpe::FormDB format.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

LICENSE:
These files are a POD derived works from the hard copy public domain version
freely distributed by the United States Federal Government.

The original hardcopy version is always the authoritative document
and any conflict between the original hardcopy version governs whenever
there is any conflict. In more explicit terms, any conflict is a 
transcription error in converting the origninal hard-copy version to
this POD format. Software Diamonds assumes no responsible for such errors.

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
To installed the release package, use the CPAN module
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

VERY IMPORTANT:

The distribution package contains the cover
C<vmake.pl> perl command script.
Manually copy this into the execution path
in order to use C<SVDmaker> from the
command line. Rename it if there is a
name conflict or just do not like the name.

^


PROBLEMS:
Open issues are as follows:

\=over 4

\=item *

Should format $svd->{PREREQ_PM_TEXT} into a table.

\=item *

Need to generted the requirements and add the
addressed requirements to the tests.

\=back
^

SUPPORT:
603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^

NOTES:
This document uses the following acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a test file

\=item DID

Data Item Description

\=item DOD

Department of Defense

\=item POD

Plain Old Documentation

\=item SVD

Software Version Description

\=item STD

Software Test Description

\=item US

United States

\=back
^
SEE_ALSO:

\=over 4

\=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

\=item L<Test::STDmaker|Test::STDmaker>

\=item L<Test::Tech|Test::Tech>

\=item L<Test|Test>

\=item L<File::Maker|File::Maker>

\=item L<Tie::Form|Tie::Form>

\=item L<Tie::Layers|Tie::Layers>

\=item L<Text::Column|Text::Column>

\=item L<Text::Replace|Text::Replace>

\=item L<Text::Scrub|Text::Scrub>

\=item L<Specification Practices|Docs::US_DOD::STD490A>

\=item L<Software Development|Docs::US_DOD::STD2167A>

\=item L<Software Version Description (SVD) DID|Docs::US_DOD::SVD>

\=back

^


HTML:

^

~-~




















