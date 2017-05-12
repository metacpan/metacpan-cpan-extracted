#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::File_Revision;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.03';
$DATE = '2004/05/03';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/File_Revision.pm' => [qw(0.03 2004/05/03), 'revised 0.02'],
    'MANIFEST' => [qw(0.03 2004/05/03), 'generated, replaces 0.02'],
    'Makefile.PL' => [qw(0.03 2004/05/03), 'generated, replaces 0.02'],
    'README' => [qw(0.03 2004/05/03), 'generated, replaces 0.02'],
    'lib/File/Revision.pm' => [qw(1.04 2004/05/03), 'revised 1.03'],
    't/File/Revision.d' => [qw(0.03 2004/05/03), 'revised 0.02'],
    't/File/Revision.pm' => [qw(0.01 2004/04/29), 'unchanged'],
    't/File/Revision.t' => [qw(0.01 2004/04/29), 'unchanged'],
    't/File/_Drawings_/Erotica.pm' => [qw(0.02 2004/05/03), 'revised 0.01'],
    't/File/File/Package.pm' => [qw(1.16 2004/05/03), 'unchanged'],
    't/File/File/AnySpec.pm' => [qw(1.14 2004/05/03), 'revised 1.13'],
    't/File/File/Where.pm' => [qw(1.15 2004/05/03), 'unchanged'],
    't/File/Test/Tech.pm' => [qw(1.22 2004/05/03), 'unchanged'],
    't/File/Data/Secs2.pm' => [qw(1.19 2004/05/03), 'revised 1.18'],
    't/File/Data/SecsPack.pm' => [qw(0.04 2004/05/03), 'revised 0.03'],
    't/File/Data/Startup.pm' => [qw(0.04 2004/05/03), 'revised 0.03'],

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

  File::Revision - return a name of non-existing backup file with a revision id

 Revision: B

 Version: 0.03

 Date: 2004/05/03

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright © 2004 Software Diamonds

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

The C<File::Revision> program modules provides the name of a non-existing file
with a revision identifier
based on the a file name $file.
This has many uses backup file uses. 

The C<File::Revision> program module provides options for many different
capabilites.

There can no restrictions on the number of backup files or the time to live
of the backup files. The revision identifier may limited to a maximum
number of places or unlimited. The revision identifier may be numeric
or comply to the capital letter drafting revision standards.

=head2 1.3 Document overview.

This document releases File::Revision version 0.03
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 File-Revision-0.03.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2004 Software Diamonds

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
 lib/Docs/Site_SVD/File_Revision.pm                           0.03    2004/05/03 revised 0.02
 MANIFEST                                                     0.03    2004/05/03 generated, replaces 0.02
 Makefile.PL                                                  0.03    2004/05/03 generated, replaces 0.02
 README                                                       0.03    2004/05/03 generated, replaces 0.02
 lib/File/Revision.pm                                         1.04    2004/05/03 revised 1.03
 t/File/Revision.d                                            0.03    2004/05/03 revised 0.02
 t/File/Revision.pm                                           0.01    2004/04/29 unchanged
 t/File/Revision.t                                            0.01    2004/04/29 unchanged
 t/File/_Drawings_/Erotica.pm                                 0.02    2004/05/03 revised 0.01
 t/File/File/Package.pm                                       1.16    2004/05/03 unchanged
 t/File/File/AnySpec.pm                                       1.14    2004/05/03 revised 1.13
 t/File/File/Where.pm                                         1.15    2004/05/03 unchanged
 t/File/Test/Tech.pm                                          1.22    2004/05/03 unchanged
 t/File/Data/Secs2.pm                                         1.19    2004/05/03 revised 1.18
 t/File/Data/SecsPack.pm                                      0.04    2004/05/03 revised 0.03
 t/File/Data/Startup.pm                                       0.04    2004/05/03 revised 0.03


=head2 3.3 Changes

The changes to the previous version are as follows:

=over 4

=item File-Revision-0.01

Originated.

=item File-Revision-0.02

Bad problems with C<$options> being init. Seems running with Exporter masks
problems. Need to make sure make a dry run without Exporter between final
distribution run, and triple check with Exporter.

=item File-Revision-0.03

In the C<parse_options> subroutine, supply an revision if there is none.
Also make sure pick out a valid revision when from the revision string.

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

Right click on 'File-Revision-0.03.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip File-Revision-0.03.tar.gz
 tar -xf File-Revision-0.03.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install C<unxutils> from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Data::Startup' => '0.03'


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/File/Revision.t

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

=item L<File::Revision|File::Revision> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD>

=item L<Extutils::SVDmaker|Extutils::SVDmaker> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: File-Revision^
REPOSITORY_DIR: packages^

VERSION : 0.03^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.02^
REVISION: B^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^

ABSTRACT: 
The C<File::Revision> program modules provides the name of a non-existing file
with a revision identifier
based on the a file name $file.
This has many uses backup file uses. 
^

TITLE   :  File::Revision - return a name of non-existing backup file with a revision id^
END_USER: General Public^
COPYRIGHT: copyright © 2004 Software Diamonds^
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
lib/File/Revision.pm
t/File/Revision.*
t/File/_Drawings_/Erotica.pm
lib/File/Package.pm => t/File/File/Package.pm
lib/File/AnySpec.pm => t/File/File/AnySpec.pm
lib/File/Where.pm => t/File/File/Where.pm
lib/Test/Tech.pm => t/File/Test/Tech.pm
lib/Data/Secs2.pm => t/File/Data/Secs2.pm
lib/Data/SecsPack.pm => t/File/Data/SecsPack.pm
lib/Data/Startup.pm => t/File/Data/Startup.pm
^

PREREQ_PM: 
'Data::Startup' => '0.03'
^

README_PODS: lib/File/Revision.pm^
TESTS: t/File/Revision.t^
EXE_FILES:  ^

CHANGES:
The changes to the previous version are as follows:

\=over 4

\=item File-Revision-0.01

Originated.

\=item File-Revision-0.02

Bad problems with C<$options> being init. Seems running with Exporter masks
problems. Need to make sure make a dry run without Exporter between final
distribution run, and triple check with Exporter.

\=item File-Revision-0.03

In the C<parse_options> subroutine, supply an revision if there is none.
Also make sure pick out a valid revision when from the revision string.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The C<File::Revision> program modules provides the name of a non-existing file
with a revision identifier
based on the a file name $file.
This has many uses backup file uses. 

The C<File::Revision> program module provides options for many different
capabilites.

There can no restrictions on the number of backup files or the time to live
of the backup files. The revision identifier may limited to a maximum
number of places or unlimited. The revision identifier may be numeric
or comply to the capital letter drafting revision standards.
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
not install, download and install C<unxutils> from

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

\=item L<File::Revision|File::Revision> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD>

\=item L<Extutils::SVDmaker|Extutils::SVDmaker> 

\=back
^


HTML:

^
~-~


