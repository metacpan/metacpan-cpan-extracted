#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::File_Drawing;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/04';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/File_Drawing.pm' => [qw(0.01 2004/05/04), 'new'],
    'MANIFEST' => [qw(0.01 2004/05/04), 'generated new'],
    'Makefile.PL' => [qw(0.01 2004/05/04), 'generated new'],
    'README' => [qw(0.01 2004/05/04), 'generated new'],
    'lib/File/Drawing.pm' => [qw(0.01 2004/05/04), 'new'],
    't/File/Drawing.d' => [qw(0.01 2004/05/04), 'new'],
    't/File/Drawing.pm' => [qw(0.01 2004/05/04), 'new'],
    't/File/Drawing.t' => [qw(0.01 2004/05/04), 'new'],
    't/File/_Drawings_/Repository0/Artists_M/Madonna/Erotica.pm' => [qw(0.01 2004/05/04), 'new'],
    't/File/_Sandbox_/_Drawings_/Repository1/Artists_M/Madonna/Erotica.pm' => [qw(0.01 2004/05/04), 'new'],
    't/File/_Drawings_/Erotica.pm' => [qw(0.02 2004/05/04), 'new'],
    't/File/_Drawings_/Repository0/Artists/Index.pm' => [qw(0.01 2004/05/04), 'new'],
    't/File/_Drawings_/Repository0/Artists/IndexBad.pm' => [qw(0.05 2004/05/04), 'new'],
    't/File/File/Package.pm' => [qw(1.16 2004/05/04), 'new'],
    't/File/Test/Tech.pm' => [qw(1.22 2004/05/04), 'new'],

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

  File::Drawing - release, revise and retrieve contents to/from a drawing program module

 Revision: -

 Version: 0.01

 Date: 2004/05/04

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

The <File::Drawing> program module uses American National Standards
for drawings as a model for storing data.
The drafting displines practices
have evolved over time and have stood the test of time.
Any deviation must be a crystal clear advantage.
Many of the practices are in place to avoid common and
costly human mistakes that obviously a computerize
drafting system will not make.
A good approach is to make the computerized data structure
optimum for computers and have the computer render the
computerized data into a form that meets the
drafting standards.
The C<File::Drawing> program module, uses
the Perl program module name as a drawing repository,
drawing number combination. 
The contents of the drawing is contained in the
program module file.
The <File::Drawing> program module established methods
to retrieve contents from a program module drawing file,
create an Perl drawing object with the contents, and methods to
release and revise the contents in a program module
drawing file from a Perl drawing object.

=head2 1.3 Document overview.

This document releases File::Drawing version 0.01
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 File-Drawing-0.01.tar.gz

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
 lib/Docs/Site_SVD/File_Drawing.pm                            0.01    2004/05/04 new
 MANIFEST                                                     0.01    2004/05/04 generated new
 Makefile.PL                                                  0.01    2004/05/04 generated new
 README                                                       0.01    2004/05/04 generated new
 lib/File/Drawing.pm                                          0.01    2004/05/04 new
 t/File/Drawing.d                                             0.01    2004/05/04 new
 t/File/Drawing.pm                                            0.01    2004/05/04 new
 t/File/Drawing.t                                             0.01    2004/05/04 new
 t/File/_Drawings_/Repository0/Artists_M/Madonna/Erotica.pm   0.01    2004/05/04 new
 t/File/_Sandbox_/_Drawings_/Repository1/Artists_M/Madonna/Er 0.01    2004/05/04 new
 t/File/_Drawings_/Erotica.pm                                 0.02    2004/05/04 new
 t/File/_Drawings_/Repository0/Artists/Index.pm               0.01    2004/05/04 new
 t/File/_Drawings_/Repository0/Artists/IndexBad.pm            0.05    2004/05/04 new
 t/File/File/Package.pm                                       1.16    2004/05/04 new
 t/File/Test/Tech.pm                                          1.22    2004/05/04 new


=head2 3.3 Changes

Changes are as follows: 

=over 4

=item Test-TestUtil-0.01

Originated

.

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

Right click on 'File-Drawing-0.01.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip File-Drawing-0.01.tar.gz
 tar -xf File-Drawing-0.01.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'File::Where' => '0.04',
 'File::Revision' => '1.04',
 'File::SmartNL' => '1.14',
 'Data::Secs2' => '1.19',
 'Data::SecsPack' => '0.04',
 'Data::Startup' => '0.02',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/File/Drawing.t

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

=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
module POD.

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

=item L<File::Drawing|File::Drawing> 

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

DISTNAME: File-Drawing^
REPOSITORY_DIR: packages^

VERSION : 0.01^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE:  ^
REVISION: -^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^

ABSTRACT: release, revise and retrieve contents to/from a drawing program module^
TITLE   :  File::Drawing - release, revise and retrieve contents to/from a drawing program module^
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
lib/File/Drawing.pm
t/File/Drawing.*
t/File/_Drawings_/Repository0/Artists_M/Madonna/Erotica.pm
t/File/_Sandbox_/_Drawings_/Repository1/Artists_M/Madonna/Erotica.pm
t/File/_Drawings_/Erotica.pm
t/File/_Drawings_/Repository0/Artists/Index.pm
t/File/_Drawings_/Repository0/Artists/IndexBad.pm
lib/File/Package.pm => t/File/File/Package.pm
lib/Test/Tech.pm => t/File/Test/Tech.pm
^

PREREQ_PM:
'File::Where' => '0.04',
'File::Revision' => '1.04',
'File::SmartNL' => '1.14',
'Data::Secs2' => '1.19',
'Data::SecsPack' => '0.04',
'Data::Startup' => '0.02',
^
README_PODS: lib/File/Drawing.pm^
TESTS: t/File/Drawing.t^
EXE_FILES:  ^

CHANGES:
Changes are as follows: 

\=over 4

\=item Test-TestUtil-0.01

Originated

.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The <File::Drawing> program module uses American National Standards
for drawings as a model for storing data.
The drafting displines practices
have evolved over time and have stood the test of time.
Any deviation must be a crystal clear advantage.
Many of the practices are in place to avoid common and
costly human mistakes that obviously a computerize
drafting system will not make.
A good approach is to make the computerized data structure
optimum for computers and have the computer render the
computerized data into a form that meets the
drafting standards.
The C<File::Drawing> program module, uses
the Perl program module name as a drawing repository,
drawing number combination. 
The contents of the drawing is contained in the
program module file.
The <File::Drawing> program module established methods
to retrieve contents from a program module drawing file,
create an Perl drawing object with the contents, and methods to
release and revise the contents in a program module
drawing file from a Perl drawing object.
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

\=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
module POD.

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

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^

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

\=item L<File::Drawing|File::Drawing> 

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


