#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::File_Where;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.05';
$DATE = '2004/05/04';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/File_Where.pm' => [qw(0.05 2004/05/04), 'revised 0.04'],
    'MANIFEST' => [qw(0.05 2004/05/04), 'generated, replaces 0.04'],
    'Makefile.PL' => [qw(0.05 2004/05/04), 'generated, replaces 0.04'],
    'README' => [qw(0.05 2004/05/04), 'generated, replaces 0.04'],
    'lib/File/Where.pm' => [qw(1.16 2004/05/04), 'revised 1.15'],
    't/File/Where.d' => [qw(0.04 2004/05/04), 'revised 0.03'],
    't/File/Where.pm' => [qw(0.04 2004/05/04), 'revised 0.03'],
    't/File/Where.t' => [qw(0.04 2004/05/04), 'revised 0.03'],
    't/File/_Drivers_/Driver.pm' => [qw(0.02 2004/05/04), 'new'],
    't/File/_Drivers_/Generate.pm' => [qw(0.02 2004/05/04), 'new'],
    't/File/_Drivers_/IO.pm' => [qw(0.02 2004/05/04), 'new'],
    't/File/File/Package.pm' => [qw(1.16 2004/05/04), 'revised 1.15'],
    't/File/Test/Tech.pm' => [qw(1.22 2004/05/04), 'revised 1.17'],
    't/File/Data/Secs2.pm' => [qw(1.19 2004/05/04), 'revised 1.15'],
    't/File/Data/SecsPack.pm' => [qw(0.04 2004/05/04), 'new'],
    't/File/Data/Startup.pm' => [qw(0.04 2004/05/04), 'new'],

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



=head1 Title Page

 Software Version Description

 for

  File::Where - find the absolute file for a program module; dir for a repository

 Revision: D

 Version: 0.05

 Date: 2004/05/04

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>

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

The system is the Perl programming language software.
As established by the Perl referenced documents,
program modules, such the 
"L<File::Where|File::Where>" module, extend the Perl language.

The subroutines in File::Where program module finds the absolute file or dir for a
program module, program module repository, relative file, relative directory
by searching the directories in the @INC array of directories or an
override array of directories. The File::Where program module 
supercedes the File::PM2File program module.

=head2 1.3 Document overview.

This document releases File::Where version 0.05
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 File-Where-0.05.tar.gz

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
 lib/Docs/Site_SVD/File_Where.pm                              0.05    2004/05/04 revised 0.04
 MANIFEST                                                     0.05    2004/05/04 generated, replaces 0.04
 Makefile.PL                                                  0.05    2004/05/04 generated, replaces 0.04
 README                                                       0.05    2004/05/04 generated, replaces 0.04
 lib/File/Where.pm                                            1.16    2004/05/04 revised 1.15
 t/File/Where.d                                               0.04    2004/05/04 revised 0.03
 t/File/Where.pm                                              0.04    2004/05/04 revised 0.03
 t/File/Where.t                                               0.04    2004/05/04 revised 0.03
 t/File/_Drivers_/Driver.pm                                   0.02    2004/05/04 new
 t/File/_Drivers_/Generate.pm                                 0.02    2004/05/04 new
 t/File/_Drivers_/IO.pm                                       0.02    2004/05/04 new
 t/File/File/Package.pm                                       1.16    2004/05/04 revised 1.15
 t/File/Test/Tech.pm                                          1.22    2004/05/04 revised 1.17
 t/File/Data/Secs2.pm                                         1.19    2004/05/04 revised 1.15
 t/File/Data/SecsPack.pm                                      0.04    2004/05/04 new
 t/File/Data/Startup.pm                                       0.04    2004/05/04 new


=head2 3.3 Changes

The changes to the previous version are as follows:

=over 4

=item File-Where-0.01

Originated.

=item File-Where-0.02

Added code to where_pm for the boundary case where

  where_pm('File::Where') # subroutine interface
  'File::Where'->where_pm('File::Where') # class interface

This bug was discovered because the obsoleted File::PM2File
module now uses File::Where for backwards compatibility.

=item File-Where-0.03

 Subject: FAIL Test-Tech-0.18 i586-linux 2.4.22-4tr 
 From: cpansmoke@alternation.net 
 Date: Thu,  8 Apr 2004 15:09:35 -0300 (ADT) 

 PERL_DL_NONLAZY=1 /usr/bin/perl5.8.0 "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
 t/Test/Tech/Tech....Can't locate FindBIN.pm

 Summary of my perl5 (revision 5.0 version 8 subversion 0) configuration:
   Platform:
     osname=linux, osvers=2.4.22-4tr, archname=i586-linux

This is capitalization problem. The program module name is 'FindBin' not 'FindBIN' which
is part of Perl. Microsoft does not care about capitalization differences while linux
does. This error is in the test script automatically generated by C<Test::STDmaker>
and was just introduced when moved test script libraries from C<tlib> to the directory
of the test script. Repaired C<Test::STDmaker> and regenerated the distribution.

=item File-Where-0.04

Subject: FAIL File-Where-0.03 ppc-darwin-thread-multi 7.2.0 
From: nothingmuch@woobling.org 
Date: Fri,  9 Apr 2004 21:59:10 +0300 (IDT) 

# Test 19 got: '/private/var/cpanplus/5.8.3/build/File-Where-0.03/blib/lib/File/Where.pm' (t/File/where.t at line 277)

#    Expected: '/private/var/cpanplus/5.8.3/build/File-Where-0.03/lib/File/Where.pm'

If doing a target site install, the install software going to place
the C<blib> directory up front in @INC
Changed the file test to locate the include directory with high 
probability of having the first C<File::Where> in the include path
in determining the expected value.

Really does not cheapen test by doing a quasi
where search where actual does the same.
The object of the test to validate boundary condition where
the class, 'File::Where', is the same as the program module 'File::Where
that the 'where' subroutine/method is locating. 
There are plenty of successful test where C<where> finds
directories and files as expected.

=item File-Where-0.05

Rework the POD NOTES and QUALITY ASSURANCE sections.

=item File-Where-0.06

Added the C<is_module>, C<program_modules>, C<repository_pms> and
C<dir_pms> subroutines.

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

Right click on 'File-Where-0.05.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip File-Where-0.05.tar.gz
 tar -xf File-Where-0.05.tar
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

 t/File/Where.t

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

=item L<File::Where|File::Where> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html
<hr>
<p><br>
<!-- BLK ID="PROJECT_MANAGEMENT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

1;

__DATA__

DISTNAME: File-Where^
REPOSITORY_DIR: packages^

VERSION : 0.05^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.04^
REVISION: D^

AUTHOR  : SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>^

ABSTRACT: 
The subroutines in C<File::Where> program module finds the absolute file or dir for a
program module, program module repository, relative file, or relative directory
by searching the directories in the @INC array of directories or an
override array of directories. The C<File::Where> program module also contains
subroutines to find all the program modules in a repository or directory.
The File::Where supercedes the C<File::PM2File>
program module and the C,File::SubPM program module>.
^

TITLE   :  File::Where - find the absolute file for a program module; dir for a repository^
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
lib/File/Where.pm
t/File/Where.*
t/File/_Drivers_/*
lib/File/Package.pm => t/File/File/Package.pm
lib/Test/Tech.pm => t/File/Test/Tech.pm
lib/Data/Secs2.pm => t/File/Data/Secs2.pm
lib/Data/SecsPack.pm => t/File/Data/SecsPack.pm
lib/Data/Startup.pm => t/File/Data/Startup.pm
^

PREREQ_PM:  ^
README_PODS: lib/File/Where.pm^
TESTS: t/File/Where.t^
EXE_FILES:  ^

CHANGES:
The changes to the previous version are as follows:

\=over 4

\=item File-Where-0.01

Originated.

\=item File-Where-0.02

Added code to where_pm for the boundary case where

  where_pm('File::Where') # subroutine interface
  'File::Where'->where_pm('File::Where') # class interface

This bug was discovered because the obsoleted File::PM2File
module now uses File::Where for backwards compatibility.

\=item File-Where-0.03

 Subject: FAIL Test-Tech-0.18 i586-linux 2.4.22-4tr 
 From: cpansmoke@alternation.net 
 Date: Thu,  8 Apr 2004 15:09:35 -0300 (ADT) 

 PERL_DL_NONLAZY=1 /usr/bin/perl5.8.0 "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
 t/Test/Tech/Tech....Can't locate FindBIN.pm

 Summary of my perl5 (revision 5.0 version 8 subversion 0) configuration:
   Platform:
     osname=linux, osvers=2.4.22-4tr, archname=i586-linux

This is capitalization problem. The program module name is 'FindBin' not 'FindBIN' which
is part of Perl. Microsoft does not care about capitalization differences while linux
does. This error is in the test script automatically generated by C<Test::STDmaker>
and was just introduced when moved test script libraries from C<tlib> to the directory
of the test script. Repaired C<Test::STDmaker> and regenerated the distribution.

\=item File-Where-0.04

Subject: FAIL File-Where-0.03 ppc-darwin-thread-multi 7.2.0 
From: nothingmuch@woobling.org 
Date: Fri,  9 Apr 2004 21:59:10 +0300 (IDT) 

# Test 19 got: '/private/var/cpanplus/5.8.3/build/File-Where-0.03/blib/lib/File/Where.pm' (t/File/where.t at line 277)

#    Expected: '/private/var/cpanplus/5.8.3/build/File-Where-0.03/lib/File/Where.pm'

If doing a target site install, the install software going to place
the C<blib> directory up front in @INC
Changed the file test to locate the include directory with high 
probability of having the first C<File::Where> in the include path
in determining the expected value.

Really does not cheapen test by doing a quasi
where search where actual does the same.
The object of the test to validate boundary condition where
the class, 'File::Where', is the same as the program module 'File::Where
that the 'where' subroutine/method is locating. 
There are plenty of successful test where C<where> finds
directories and files as expected.

\=item File-Where-0.05

Rework the POD NOTES and QUALITY ASSURANCE sections.

\=item File-Where-0.06

Added the C<is_module>, C<program_modules>, C<repository_pms> and
C<dir_pms> subroutines.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The system is the Perl programming language software.
As established by the Perl referenced documents,
program modules, such the 
"L<File::Where|File::Where>" module, extend the Perl language.

The subroutines in File::Where program module finds the absolute file or dir for a
program module, program module repository, relative file, relative directory
by searching the directories in the @INC array of directories or an
override array of directories. The File::Where program module 
supercedes the File::PM2File program module.

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

\=item L<File::Where|File::Where> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back
^



HTML:
<hr>
<p><br>
<!-- BLK ID="PROJECT_MANAGEMENT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^
~-~


