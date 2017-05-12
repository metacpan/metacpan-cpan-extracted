#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Docs_US_DOD_STD2167A;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.06';
$DATE = '2003/09/15';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Docs_US_DOD_STD2167A.pm' => [qw(0.06 2003/09/15), 'revised 0.05'],
    'MANIFEST' => [qw(0.06 2003/09/15), 'generated, replaces 0.05'],
    'Makefile.PL' => [qw(0.06 2003/09/15), 'generated, replaces 0.05'],
    'README' => [qw(0.06 2003/09/15), 'generated, replaces 0.05'],
    'lib/Docs/US_DOD/CDRL.pm' => [qw(1.07 2003/07/05), 'unchanged'],
    'lib/Docs/US_DOD/COM.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/CPM.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/CRISD.pm' => [qw(1.07 2003/09/15), 'revised 1.06'],
    'lib/Docs/US_DOD/CSCI.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/CSOM.pm' => [qw(1.07 2003/09/15), 'revised 1.06'],
    'lib/Docs/US_DOD/DBDD.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/ECP.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/FSM.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/HWCI.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/IDD.pm' => [qw(1.07 2003/09/15), 'revised 1.06'],
    'lib/Docs/US_DOD/IRS.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/OCD.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SCN.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SDD.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SDP.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SDR.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SIOM.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SIP.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SPM.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SPS.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SRS.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SSDD.pm' => [qw(1.06 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SSS.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/STD.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/STD2167A.pm' => [qw(1.08 2003/06/14), 'unchanged'],
    'lib/Docs/US_DOD/STD490A.pm' => [qw(1.08 2003/06/14), 'unchanged'],
    'lib/Docs/US_DOD/STP.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/STR.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/STrP.pm' => [qw(1.07 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/SUM.pm' => [qw(1.08 2003/06/14), 'unchanged'],
    'lib/Docs/US_DOD/SVD.pm' => [qw(1.08 2003/06/10), 'unchanged'],
    'lib/Docs/US_DOD/VDD.pm' => [qw(1.07 2003/09/15), 'revised 1.06'],
    't/Docs/US_DOD/STD2167A.t' => [qw(0.07 2003/07/05), 'unchanged'],

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

 Software Development Standards, Specifications and Data Item Description PODs

 Revision: E

 Version: 0.06

 Date: 2003/09/15

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

This release adds United States Department of Defense (US DOD) 
Perl Plain Old Documentation (POD)
derived from software related documents release by the
US DOD to the general public.

These documents and the terminology used in these documents
govern much of the Software Development including
design, test, distribution, release, installation and
use of software.

One area of praticular interest is development software that
automates development tasks freeing up designers, technicians
and other personell to concentrate on key development tasks.

Toward this end, two starting modules that make heavy references
to the these 2167A documents are the following modules:

=over 4

=item L<Test::STDmaker|Test::STDmaker>

Generates L<2167A STD DID|Docs::US_DOD::STD>, demonstration script,
and test script from a STD text database in a format consistent
with L<DataPort::FileType::FormDB>.

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

Generates L<2167A SVD DID|Docs::US_DOD::SVD>, MakeFile.PL, README,
MANIFEST, updates file versions and creates .tar.gz distribution
file from a SVD text database in a format consistent with
L<DataPort::FileType::FormDB>.

The dependency of the program modules in the US DOD STD2167A bundle is as follows:
 
 File::Package File::SmartNL File::TestPath Text::Scrub

     Test::Tech

        DataPort::FileType::FormDB DataPort::DataFile DataPort::Maker 
        File::AnySpec File::Data File::PM2File File::SubPM Text::Replace 
        Text::Column

            Test::STDmaker ExtUtils::SVDmaker


=back

=head2 1.3 Document overview.

This document releases Docs-US_DOD-STD2167A version 0.06 and
provides a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file found
at the following repository(s):

   http://www.softwarediamonds/packages/Docs-US_DOD-STD2167A-0.06
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Docs-US_DOD-STD2167A-0.06


Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

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
 lib/Docs/Site_SVD/Docs_US_DOD_STD2167A.pm                    0.06    2003/09/15 revised 0.05
 MANIFEST                                                     0.06    2003/09/15 generated, replaces 0.05
 Makefile.PL                                                  0.06    2003/09/15 generated, replaces 0.05
 README                                                       0.06    2003/09/15 generated, replaces 0.05
 lib/Docs/US_DOD/CDRL.pm                                      1.07    2003/07/05 unchanged
 lib/Docs/US_DOD/COM.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/CPM.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/CRISD.pm                                     1.07    2003/09/15 revised 1.06
 lib/Docs/US_DOD/CSCI.pm                                      1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/CSOM.pm                                      1.07    2003/09/15 revised 1.06
 lib/Docs/US_DOD/DBDD.pm                                      1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/ECP.pm                                       1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/FSM.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/HWCI.pm                                      1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/IDD.pm                                       1.07    2003/09/15 revised 1.06
 lib/Docs/US_DOD/IRS.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/OCD.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SCN.pm                                       1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/SDD.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SDP.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SDR.pm                                       1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/SIOM.pm                                      1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SIP.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SPM.pm                                       1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/SPS.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SRS.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SSDD.pm                                      1.06    2003/06/10 unchanged
 lib/Docs/US_DOD/SSS.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/STD.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/STD2167A.pm                                  1.08    2003/06/14 unchanged
 lib/Docs/US_DOD/STD490A.pm                                   1.08    2003/06/14 unchanged
 lib/Docs/US_DOD/STP.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/STR.pm                                       1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/STrP.pm                                      1.07    2003/06/10 unchanged
 lib/Docs/US_DOD/SUM.pm                                       1.08    2003/06/14 unchanged
 lib/Docs/US_DOD/SVD.pm                                       1.08    2003/06/10 unchanged
 lib/Docs/US_DOD/VDD.pm                                       1.07    2003/09/15 revised 1.06
 t/Docs/US_DOD/STD2167A.t                                     0.07    2003/07/05 unchanged


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Docs::US_DOD::STD2167A 0.03

Version 0.02 loaded test file t/Docs/US_DOD/STD2167A.t but
specified test file t/docs/US_DOD/STD2167A.t.
Works on case insensitive file specs OS such as MsDOS but
fails on case sensitive file specs OS such as Unix

Changed the test file

From:

 t/docs/US_DOD/STD2167A.t

To:

 t/Docs/US_DOD/STD2167A.t


=item Docs::US_DOD::STD2167A 0.04
=item Docs::US_DOD::STD2167A 0.05

Another case insensitive issue. The STrP has one lower case
letter. Make changes so everything should match the case.
Unix file specifications are case sensitive while
Microsoft's are not.

=item Docs::US_DOD::STD2167A 0.06

Deleted SRR and SDR which since they are review,
have not document.

Supplied contents for the following

 VDD.pm
 CRISD.pm
 CSOM.pm
 IDD.pm

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

To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

   http://www.softwarediamonds/packages/Docs-US_DOD-STD2167A-0.06
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Docs-US_DOD-STD2167A-0.06


=item Prerequistes.

 'File::Package' => '0',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Docs/US_DOD/STD2167A.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

None of the PODs contain any of the figures from the hard-copy
versions. The following PODs do not contain any documents
and an empty POD is included only to resolve links when
the converted documents converted to PODs cites documents
not converted to PODs:

 CDRL.pod
 CSCI.pod
 ECP.pod
 HWCI.pod
 SCN.pod
 SPM.pod
 SSD.pod

For Perl module releases, these documents may not be applicable.
Many of them are for large software applications and complex
systems involving both hardware and software while others 
establish format, legally binding, contractual requirements
between the supplier and consumer of the data.
Neither of these apply for this document.

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=item DID

Data Item Description

=item POD

Plain Old Documentation

extension for a Software Vesion Description database file

=back

=head1 2.0 SEE ALSO

Modules with end-user functional interfaces 
relating to US DOD 2167A automation are
as follows:

=over 4

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

=item L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>

=item L<DataPort::DataFile|DataPort::DataFile>

=item L<Test::Tech|Test::Tech>

=item L<Test|Test>

=item L<Data::Dumper|Data::Dumper>

=item L<Text::Scrub|Text::Scrub>

=item L<Text::Column|Text::Column>

=item L<Text::Replace|Text::Replace>

=item L<Data::Strify|Data::Strify>

=item L<Data::Str2Num|Data::Str2Num>

=item L<File::Package|File::Package>

=item L<File::SmartNL|File::SmartNL>

=item L<File::TestPath|File::TestPath>

=item L<File::SubPM|File::SubPM>

=item L<File::SubPM|File::Data>

=item L<Archive::TarGzip|Archive::TarGzip>

=item L<Tie::Gzip|Tie::Gzip>

=back

The design modules for L<Test::STDmaker|Test::STDmaker>
have no other conceivable use then to support the
L<Test::STDmaker|Test::STDmaker> functional interface. 
The  L<Test::STDmaker|Test::STDmaker>
design module are as follows:

=over 4

=item L<Test::STD::Check|Test::STD::Check>

=item L<Test::STD::FileGen|Test::STD::FileGen>

=item L<Test::STD::STD2167|Test::STD::STD2167>

=item L<Test::STD::STDgen|Test::STD::STDgen>

=item L<Test::STDtype::Demo|Test::STDtype::Demo>

=item L<Test::STDtype::STD|Test::STDtype::STD>

=item L<Test::STDtype::Verify|Test::STDtype::Verify>

=back


Some US DOD 2167A Software Development Standard, DIDs and
other related documents that complement the 
US DOD 2167A automation are as follows:

=over 4

=item L<US DOD Software Development Standard|Docs::US_DOD::STD2167A>

=item L<US DOD Specification Practices|Docs::US_DOD::STD490A>

=item L<Computer Operation Manual (COM) DID|Docs::US_DOD::COM>

=item L<Computer Programming Manual (CPM) DID)|Docs::US_DOD::CPM>

=item L<Computer Resources Integrated Support Document (CRISD) DID|Docs::US_DOD::CRISD>

=item L<Computer System Operator's Manual (CSOM) DID|Docs::US_DOD::CSOM>

=item L<Database Design Description (DBDD) DID|Docs::US_DOD::DBDD>

=item L<Engineering Change Proposal (ECP) DID|Docs::US_DOD::ECP>

=item L<Firmware support Manual (FSM) DID|Docs::US_DOD::FSM>

=item L<Interface Design Document (IDD) DID|Docs::US_DOD::IDD>

=item L<Interface Requirements Specification (IRS) DID|Docs::US_DOD::IRS>

=item L<Operation Concept Description (OCD) DID|Docs::US_DOD::OCD>

=item L<Specification Change Notice (SCN) DID|Docs::US_DOD::SCN>

=item L<Software Design Specification (SDD) DID|Docs::US_DOD::SDD>

=item L<Software Development Plan (SDP) DID|Docs::US_DOD::SDP> 

=item L<Software Input and Output Manual (SIOM) DID|Docs::US_DOD::SIOM>

=item L<Software Installation Plan (SIP) DID|Docs::US_DOD::SIP>

=item L<Software Programmer's Manual (SPM) DID|Docs::US_DOD::SPM>

=item L<Software Product Specification (SPS) DID|Docs::US_DOD::SPS>

=item L<Software Requirements Specification (SRS) DID|Docs::US_DOD::SRS>

=item L<System or Segment Design Document (SSDD) DID|Docs::US_DOD::SSDD>

=item L<System or Subsystem Specification (SSS) DID|Docs::US_DOD::SSS>

=item L<Software Test Description (STD) DID|Docs::US_DOD::STD>

=item L<Software Test Plan (STP) DID|Docs::US_DOD::STP>

=item L<Software Test Report (STR) DID|Docs::US_DOD::STR>

=item L<Software Transition Plan (STrP) DID|Docs::US_DOD::STrP>

=item L<Software User Manual (SUM) DID|Docs::US_DOD::SUM>

=item L<Software Version Description (SVD) DID|Docs::US_DOD::SVD>

=item L<Version Description Document (VDD) DID|Docs::US_DOD::VDD>

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


DISTNAME: Docs-US_DOD-STD2167A^
VERSION : 0.06^
REPOSITORY_DIR: packages^
FREEZE: 0^

PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE:  0.05^
REVISION: E^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: 2167A Software Development Standards, Specifications and Data Item Description PODs^
TITLE   : Software Development Standards, Specifications and Data Item Description PODs^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^ 

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
^

RESTRUCTURE:  ^

CHANGE2CURRENT:  ^

AUTO_REVISE:
lib/Docs/US_DOD/*.pm
t/Docs/US_DOD/STD2167A.t
^

PREREQ_PM: 
'File::Package' => '0',
^

TESTS: t/Docs/US_DOD/STD2167A.t^
EXE_FILES:  ^

CHANGES:

Changes are as follows:

\=over 4

\=item Docs::US_DOD::STD2167A 0.03

Version 0.02 loaded test file t/Docs/US_DOD/STD2167A.t but
specified test file t/docs/US_DOD/STD2167A.t.
Works on case insensitive file specs OS such as MsDOS but
fails on case sensitive file specs OS such as Unix

Changed the test file

From:

 t/docs/US_DOD/STD2167A.t

To:

 t/Docs/US_DOD/STD2167A.t


\=item Docs::US_DOD::STD2167A 0.04
\=item Docs::US_DOD::STD2167A 0.05

Another case insensitive issue. The STrP has one lower case
letter. Make changes so everything should match the case.
Unix file specifications are case sensitive while
Microsoft's are not.

\=item Docs::US_DOD::STD2167A 0.06

Deleted SRR and SDR which since they are review,
have not document.

Supplied contents for the following

 VDD.pm
 CRISD.pm
 CSOM.pm
 IDD.pm

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${DISTNAME} version ${VERSION} and
provides a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
This release adds United States Department of Defense (US DOD) 
Perl Plain Old Documentation (POD)
derived from software related documents release by the
US DOD to the general public.

These documents and the terminology used in these documents
govern much of the Software Development including
design, test, distribution, release, installation and
use of software.

One area of praticular interest is development software that
automates development tasks freeing up designers, technicians
and other personell to concentrate on key development tasks.

Toward this end, two starting modules that make heavy references
to the these 2167A documents are the following modules:

\=over 4

\=item L<Test::STDmaker|Test::STDmaker>

Generates L<2167A STD DID|Docs::US_DOD::STD>, demonstration script,
and test script from a STD text database in a format consistent
with L<DataPort::FileType::FormDB>.

\=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

Generates L<2167A SVD DID|Docs::US_DOD::SVD>, MakeFile.PL, README,
MANIFEST, updates file versions and creates .tar.gz distribution
file from a SVD text database in a format consistent with
L<DataPort::FileType::FormDB>.

The dependency of the program modules in the US DOD STD2167A bundle is as follows:
 
 File::Package File::SmartNL File::TestPath Text::Scrub

     Test::Tech

        DataPort::FileType::FormDB DataPort::DataFile DataPort::Maker 
        File::AnySpec File::Data File::PM2File File::SubPM Text::Replace 
        Text::Column

            Test::STDmaker ExtUtils::SVDmaker


\=back


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
To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

${REPOSITORY}
^


PROBLEMS:
None of the PODs contain any of the figures from the hard-copy
versions. The following PODs do not contain any documents
and an empty POD is included only to resolve links when
the converted documents converted to PODs cites documents
not converted to PODs:

 CDRL.pod
 CSCI.pod
 ECP.pod
 HWCI.pod
 SCN.pod
 SPM.pod
 SSD.pod

For Perl module releases, these documents may not be applicable.
Many of them are for large software applications and complex
systems involving both hardware and software while others 
establish format, legally binding, contractual requirements
between the supplier and consumer of the data.
Neither of these apply for this document.
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

NOTES:
The following are useful acronyms:

\=over 4

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=item DID

Data Item Description

\=item POD

Plain Old Documentation

extension for a Software Vesion Description database file

\=back
^

SEE_ALSO:

Modules with end-user functional interfaces 
relating to US DOD 2167A automation are
as follows:

\=over 4

\=item L<Test::STDmaker|Test::STDmaker>

\=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker>

\=item L<DataPort::FileType::FormDB|DataPort::FileType::FormDB>

\=item L<DataPort::DataFile|DataPort::DataFile>

\=item L<Test::Tech|Test::Tech>

\=item L<Test|Test>

\=item L<Data::Dumper|Data::Dumper>

\=item L<Text::Scrub|Text::Scrub>

\=item L<Text::Column|Text::Column>

\=item L<Text::Replace|Text::Replace>

\=item L<Data::Strify|Data::Strify>

\=item L<Data::Str2Num|Data::Str2Num>

\=item L<File::Package|File::Package>

\=item L<File::SmartNL|File::SmartNL>

\=item L<File::TestPath|File::TestPath>

\=item L<File::SubPM|File::SubPM>

\=item L<File::SubPM|File::Data>

\=item L<Archive::TarGzip|Archive::TarGzip>

\=item L<Tie::Gzip|Tie::Gzip>

\=back

The design modules for L<Test::STDmaker|Test::STDmaker>
have no other conceivable use then to support the
L<Test::STDmaker|Test::STDmaker> functional interface. 
The  L<Test::STDmaker|Test::STDmaker>
design module are as follows:

\=over 4

\=item L<Test::STD::Check|Test::STD::Check>

\=item L<Test::STD::FileGen|Test::STD::FileGen>

\=item L<Test::STD::STD2167|Test::STD::STD2167>

\=item L<Test::STD::STDgen|Test::STD::STDgen>

\=item L<Test::STDtype::Demo|Test::STDtype::Demo>

\=item L<Test::STDtype::STD|Test::STDtype::STD>

\=item L<Test::STDtype::Verify|Test::STDtype::Verify>

\=back


Some US DOD 2167A Software Development Standard, DIDs and
other related documents that complement the 
US DOD 2167A automation are as follows:

\=over 4

\=item L<US DOD Software Development Standard|Docs::US_DOD::STD2167A>

\=item L<US DOD Specification Practices|Docs::US_DOD::STD490A>

\=item L<Computer Operation Manual (COM) DID|Docs::US_DOD::COM>

\=item L<Computer Programming Manual (CPM) DID)|Docs::US_DOD::CPM>

\=item L<Computer Resources Integrated Support Document (CRISD) DID|Docs::US_DOD::CRISD>

\=item L<Computer System Operator's Manual (CSOM) DID|Docs::US_DOD::CSOM>

\=item L<Database Design Description (DBDD) DID|Docs::US_DOD::DBDD>

\=item L<Engineering Change Proposal (ECP) DID|Docs::US_DOD::ECP>

\=item L<Firmware support Manual (FSM) DID|Docs::US_DOD::FSM>

\=item L<Interface Design Document (IDD) DID|Docs::US_DOD::IDD>

\=item L<Interface Requirements Specification (IRS) DID|Docs::US_DOD::IRS>

\=item L<Operation Concept Description (OCD) DID|Docs::US_DOD::OCD>

\=item L<Specification Change Notice (SCN) DID|Docs::US_DOD::SCN>

\=item L<Software Design Specification (SDD) DID|Docs::US_DOD::SDD>

\=item L<Software Development Plan (SDP) DID|Docs::US_DOD::SDP> 

\=item L<Software Input and Output Manual (SIOM) DID|Docs::US_DOD::SIOM>

\=item L<Software Installation Plan (SIP) DID|Docs::US_DOD::SIP>

\=item L<Software Programmer's Manual (SPM) DID|Docs::US_DOD::SPM>

\=item L<Software Product Specification (SPS) DID|Docs::US_DOD::SPS>

\=item L<Software Requirements Specification (SRS) DID|Docs::US_DOD::SRS>

\=item L<System or Segment Design Document (SSDD) DID|Docs::US_DOD::SSDD>

\=item L<System or Subsystem Specification (SSS) DID|Docs::US_DOD::SSS>

\=item L<Software Test Description (STD) DID|Docs::US_DOD::STD>

\=item L<Software Test Plan (STP) DID|Docs::US_DOD::STP>

\=item L<Software Test Report (STR) DID|Docs::US_DOD::STR>

\=item L<Software Transition Plan (STrP) DID|Docs::US_DOD::STrP>

\=item L<Software User Manual (SUM) DID|Docs::US_DOD::SUM>

\=item L<Software Version Description (SVD) DID|Docs::US_DOD::SVD>

\=item L<Version Description Document (VDD) DID|Docs::US_DOD::VDD>

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


