#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::STP;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81438';
$TITLE = 'SOFTWARE TEST PLAN (STP)';
$REVISION = '-';
$REVISION_DATE = '';

1

__END__


=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. TITLE

SOFTWARE TEST PLAN (STP) 

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81438 

=head1 3. DESCRIPTION/PURPOSE 

The Software Test Plan (STP) describes plans for
qualification testing of Computer Software Configuration Items
(CSCIs) and software systems. It describes the software test environment
to be used for the testing, identifies the tests to be performed,
and provides schedules for test activities. 

There is usually a single STP for a project. The
STP enables the acquirer to assess the adequacy of planning for
CSCI and, if applicable, software system qualification testing.

=head1 7. APPLICATION/INTERRELATIONSHIP 

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
develop and record plans for conducting CSCI qualification testing
and/or system qualification testing of a software system. 

The Contract Data Requirements List (L<CDRL>) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-MCCR-80014A, DI-IPSC-80697,
DI-MCCR-80307, DI-MCCR-80308, and DI-MCCR-80309. 

=head1 10. PREPARATION INSTRUCTIONS

=head2 10.1 General instructions.

=head2 10.1.1 Automated techniques. 

Use of automated techniques
is encouraged. The term 'document' in this DID means
a collection of data regardless of its medium. 

=head2 10.1.2 Alternate presentation styles. 

Diagrams, tables,
matrices, and other presentation styles are acceptable substitutes
for text when data required by this DID can be made more readable
using these styles. c. Title page or identifier. The document
shall include a title page containing, as applicable: document
number; volume number; version/revision indicator; security markings
or other restrictions on the handling of the document; date; document
title; name, abbreviation, and any other identifier for the system,
subsystem, or item to which the document applies; contract number;
CDRL item number; organization for which the document has been
prepared; name and address of the preparing organization; and
distribution statement. For data in a database or other alternative
form, this information shall be included on external and internal
labels or by equivalent identification methods. 

=head2 10.1.3 Title page or identifier with signature blocks.

The document shall include a title page containing, as applicable:
document number; volume number; version/revision indicator; security
markings or other restrictions on the handling of the document;
date; document title; name, abbreviation, and any other identifier
for the systems, subsystems, or items to which the document applies;
contract number; CDRL item number; organization for which the
document has been prepared; name and address of the preparing
organization; distribution statement; and signature blocks for
the developer representative authorized to release the document,
the acquirer representative authorized to approve the document,
and the dates of release/approval. For data in a database or other
alternative form, this information shall be included on external
and internal labels or by equivalent identification methods.

=head2 10.1.4 Table of contents. 

The document shall contain
a table of contents providing the number, title, and page number
of each titled paragraph, figure, table, and appendix. For data
in a database or other alternative form, this information shall
consist of an internal or external table of contents containing
pointers to, or instructions for accessing, each paragraph, figure,
table, and appendix or their equivalents. 

=head2 10.1.5 Page numbering/labeling. 

Each page shall contain
a unique page number and display the document number, including
version, volume, and date, as applicable. For data in a database
or other alternative form, files, screens, or other entities shall
be assigned names or numbers in such a way that desired data can
be indexed and accessed. 

=head2 10.1.6 Response to tailoring instructions. 

If a paragraph
is tailored out of this DID, the resulting document shall contain
the corresponding paragraph number and title, followed by 'This
paragraph has been tailored out.' For data in a database
or other alternative form, this representation need occur only
in the table of contents or equivalent. 

=head2 10.1.7 Multiple paragraphs and subparagraphs.

Any section, paragraph, or subparagraph in this DID may be written
as multiple paragraphs or subparagraphs to enhance readability.

=head2 10.1.8 Standard data descriptions. 

If a data description
required by this DID has been published in a standard data element
dictionary specified in the contract, reference to an entry in
that dictionary is preferred over including the description itself.

=head2 10.1.9  Substitution of existing documents. 

Commercial or other existing documents may be substituted for all or part
of the document if they contain the required data. 

=head2 10.2 Content requirements.

Content requirements begin on the following page. The numbers
shown designate the paragraph numbers to be used in the document.
Each such number is understood to have the prefix '10.2'
within this DID. For example, the paragraph numbered 1.1 is understood
to be paragraph 10.2.1.1 within this DID.


=head1 1. Scope.
This section shall be divided into the following paragraphs.

=head2 1.1 Identification.

This paragraph shall contain a full identification of the
system and the software to which this document applies, including,
as applicable, identification number(s), title(s), abbreviation(s),
version number(s), and release number(s). 

=head2 1.2 System overview.

This paragraph shall briefly state the purpose of the system
and the software to which this document applies. It shall describe
the general nature of the system and software; summarize the history
of system development, operation, and maintenance; identify the
project sponsor, acquirer, user, developer, and support agencies;
identify current and planned operating sites; and list other relevant
documents. 

=head2 1.3 Document overview.

This paragraph shall summarize the purpose and contents of
this document and shall describe any security or privacy considerations
associated with its use. 

=head2 1.4 Relationship to other plans.

This paragraph shall describe the relationship, if any, of
the STP to related project management plans. 

=head1 Referenced documents.

This section shall list the number, title, revision, and date
of all documents referenced in this plan. This section shall also
identify the source for all documents not available through normal
Government stocking activities. 

=head1 3. Software test environment.

This section shall be divided into the following paragraphs
to describe the software test environment at each intended test
site. Reference may be made to the Software Development Plan (SDP)
for resources that are described there. 

=head2 3.x (Name of test site(s)).

This paragraph shall identify one or more test sites to be
used for the testing, and shall be divided into the following
subparagraphs to describe the software test environment at the
site(s). If all tests will be conducted at a single site, this
paragraph and its subparagraphs shall be presented only once.
If multiple test sites use the same or similar software test environments,
they may be discussed together. Duplicative information among
test site descriptions may be reduced by referencing earlier descriptions.

=head2 3.x.1 Software items.

This paragraph shall identify by name, number, and version,
as applicable, the software items (e.g., operating systems, compilers,
communications software, related applications software, databases,
input files, code auditors, dynamic path analyzers, test drivers,
preprocessors, test data generators, test control software, other
special test software, post-processors) necessary to perform the
planned testing activities at the test site(s). This paragraph
shall describe the purpose of each item, describe its media (tape,
disk, etc.), identify those that are expected to be supplied by
the site, and identify any classified processing or other security
or privacy issues associated with the software items. 

=head2 3.x.2 Hardware and firmware items.

This paragraph shall identify by name, number, and version,
as applicable, the computer hardware, interfacing equipment, communications
equipment, test data reduction equipment, apparatus such as extra
peripherals (tape drives, printers, plotters), test message generators,
test timing devices, test event records, etc., and firmware items
that will be used in the software test environment at the test
site(s). This paragraph shall describe the purpose of each item,
state the period of usage and the number of each item needed,
identify those that are expected to be supplied by the site, and
identify any classified processing or other security or privacy
issues associated with the items. 

=head2 3.x.3 Other materials.

This paragraph shall identify and describe any other materials
needed for the testing at the test site(s). These materials may
include manuals, software listings, media containing the software
to be tested, media containing data to be used in the tests, sample
listings of outputs, and other forms or instructions. This paragraph
shall identify those items that are to be delivered to the site
and those that are expected to be supplied by the site. The description
shall include the type, layout, and quantity of the materials,
as applicable. This paragraph shall identify any classified processing
or other security or privacy issues associated with the items.

=head2 3.x.4 Proprietary nature, acquirer's rights, and licensing.

This paragraph shall identify the proprietary nature, acquirer's
rights, and licensing issues associated with each element of the
software test environment. 

=head2 3.x.5 Installation, testing, and control.

This paragraph shall identify the developer's plans for performing
each of the following, possibly in conjunction with personnel
at the test site(s): 

=over 4

=item 1

Acquiring or developing each element of the software test
environment

=item 2

Installing and testing each item of the software test environment
prior to its use

=item 3

Controlling and maintaining each item of the software test
environment 

=back

=head2 3.x.6 Participating organizations.

This paragraph shall identify the organizations that will
participate in the testing at the test sites(s) and the roles
and responsibilities of each. 

=head2 3.x.7 Personnel.

This paragraph shall identify the number, type, and skill
level of personnel needed during the test period at the test site(s),
the dates and times they will be needed, and any special needs,
such as multishift operation and retention of key skills to ensure
continuity and consistency in extensive test programs. 

=head2 3.x.8 Orientation plan.

This paragraph shall describe any orientation and training














to be given before and during the testing. This information shall
be related to the personnel needs given in 3.x.7. This training
may include user instruction, operator instruction, maintenance
and control group instruction, and orientation briefings to staff
personnel. If extensive training is anticipated, a separate plan
may be developed and referenced here. 

=head2 3.x.9 Tests to be performed.

This paragraph shall identify, by referencing section 4, the
tests to be performed at the test site(s). 

=head1 4. Test identification.

This section shall be divided into the following paragraphs
to identify and describe each test to which this STP applies.

=head2 4.1 General information.

This paragraph shall be divided into subparagraphs to present
general information applicable to the overall testing to be performed.

=head2 4.1.1 Test levels.

This paragraph shall describe the levels at which testing
will be performed, for example, CSCI level or system level.

=head2 4.1.2 Test classes.

This paragraph shall describe the types or classes of tests
that will be performed (for example, timing tests, erroneous input
tests, maximum capacity tests). 

=head2 4.1.3 General test conditions.

This paragraph shall describe conditions that apply to all
of the tests or to a group of tests. For example: 'Each test
shall include nominal, maximum, and minimum values;' 'each
test of type x shall use live data;' 'execution size
and time shall be measured for each CSCI.' Included shall
be a statement of the extent of testing to be performed and rationale
for the extent selected. The extent of testing shall be expressed
as a percentage of some well defined total quantity, such as the
number of samples of discrete operating conditions or values,
or other sampling approach. Also included shall be the approach
to be followed for retesting/regression testing. 

=head2 4.1.4 Test progression.

In cases of progressive or cumulative tests, this paragraph
shall explain the planned sequence or progression of tests. 

=head2 4.1.5 Data recording, reduction, and analysis.

This paragraph shall identify and describe the data recording,
reduction, and analysis procedures to be used during and after
the tests identified in this STP. These procedures shall include,
as applicable, manual, automatic, and semi-automatic techniques
for recording test results, manipulating the raw results into
a form suitable for evaluation, and retaining the results of data
reduction and analysis. 

=head2 4.2 Planned tests.

This paragraph shall be divided into the following subparagraphs
to describe the total scope of the planned testing. 

=head2 4.2.x (Item(s) to be tested).

This paragraph shall identify a CSCI, subsystem, system, or
other entity by name and project-unique identifier, and shall
be divided into the following subparagraphs to describe the testing
planned for the item(s). (Note: the 'tests' in this



plan are collections of test cases. There is no intent to describe
each test case in this document.) 

=head2 4.2.x.y (Project-unique identifier of a test).

This paragraph shall identify a test by project-unique identifier
and shall provide the information specified below for the test.
Reference may be made as needed to the general information in
4.1. 

=over 4

=item 1

Test objective

=item 2

Test level

=item 3

Test type or class

=item 4

Qualification method(s) as specified in the requirements
specification 

=item 5

Identifier of the CSCI requirements and, if applicable,
software system requirements addressed by this test. (Alternatively,
this information may be provided in Section 6.) 

=item 6

Special requirements (for example, 48 hours of continuous
facility time, weapon simulation, extent of test, use of a special
input or database)

=item 7

Type of data to be recorded

=item 8

Type of data recording/reduction/analysis to be employed

=item 9

Assumptions and constraints, such as anticipated limitations
on the test due to system or test conditions--timing, interfaces,
equipment, personnel, database, etc.

=item 10

Safety, security, and privacy considerations associated
with the test 

=back

head1 5. Test schedules.

This section shall contain or reference the schedules for
conducting the tests identified in this plan. It shall include:

=over

=item 1

A listing or chart depicting the sites at which the testing
will be scheduled and the time frames during which the testing
will be conducted 

=item 2

A schedule for each test site depicting the activities
and events listed below, as applicable, in chronological order
with supporting narrative as necessary: 

=over 4

=item *

On-site test period and periods assigned to major portions
of the testing 

=item *

Pretest on-site period needed for setting up the software
test environment and other equipment, system debugging, orientation,
and familiarization 

=item *

Collection of database/data file values, input values,
and other operational data needed for the testing 

=item *

Conducting the tests, including planned retesting

=item *

Preparation, review, and approval of the Software Test Report (STR)

=back

=back

=head1 6. Requirements traceability.

This paragraph shall contain: 

=over 4

=item 1

Traceability from each test identified in this plan to
the CSCI requirements and, if applicable, software system requirements
it addresses. (Alternatively, this traceability may be provided
in 4.2.x.y and referenced from this paragraph.) 

=item 2

Traceability from each CSCI requirement and, if applicable,
each software system requirement covered by this test plan to
the test(s) that address it. The traceability shall cover the
CSCI requirements in all applicable Software Requirements Specifications
(SRSs) and associated Interface Requirements Specifications (IRSs),
and, for software systems, the system requirements in all applicable
System/ Subsystem Specifications (SSSs) and associated system-level
IRSs.

=back

=head1 7. Notes.

This section shall contain any general information that aids
in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of any terms and definitions
needed to understand this document.


=head1 A Appendixes. 

Appendixes may be used to provide information
published separately for convenience in document maintenance (e.g.,
charts, classified data). As applicable, each appendix shall be
referenced in the main body of the document where the data would
normally have been provided. Appendixes may be bound as separate
documents for ease in handling. Appendixes shall be lettered alphabetically
(A, B, etc.).


=head1 Copyright

This Perl Plain Old Documentation (POD) version is
copyright © 2001 2003 Software Diamonds.
This POD version was derived from
the hard copy public domain version freely distributed by
the United States Federal Government.

=head1 License

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

=head1 Copyright Holder Contact

E<lt>support@SoftwareDiamonds.comE<gt>

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

## end of file ##


