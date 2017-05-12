#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::STR;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81440';
$TITLE = 'SOFTWARE TEST REPORT (STR)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__


=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item.

=head1 1.0 TITLE

SOFTWARE TEST REPORT (STR)

=head1 2.0 Identification number 

DI-IPSC-81440

=head1 3.0 DESCRIPTION/PURPOSE

The Software Test Report (STR) is a record of the qualification testing 
performed on a Computer Software Configuration Item (L<CSCI>), 
a software system or subsystem, or other software-related item.

The STR enables the acquirer to assess the testing and its results.

=head1 7.0 APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format and
content preparation instructions for the data product generated 
by specific and discrete task requirements as delineated in the contract. 

This DID is used when the developer is tasked to analyze and record
the results of CSCI qualification testing, system qualification testing
of a software system, or other testing identified in the contract.

The Contract Data Requirements List (L<CDRL>) (DD 1423) should specify
whether deliverable data are to be delivered on paper or electronic media;
are to be in a given electronic form (such as ASCII, CALS, or compatible
with a specified word processor or other support software);
may be delivered in developer format rather than in the format specified herein;
and may reside in a computer-aided software engineering (CASE) or
other automated tool rather than in the form of a traditional document.

This DID supersedes DI-MCCR-80017A, DI-IPSC-80698, and DI-MCCR-80311.

=head1 10.0 PREPARATION INSTRUCTIONS

=head2 10.1 General instructions.

=head2 10.1.1 Automated techniques 

Use of automated techniques is encouraged. The term 'document' 
in this DID means a collection of data regardless of its medium.

=head2 10.1.2 Alternate presentation styles.

Diagrams, tables, matrices, and other presentation styles 
are acceptable substitutes for text when data required by 
this DID can be made more readable using these styles.

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

Each page shallcontain a unique page number and display the document number,
including version, volume, and date, as applicable. For data in
a database or other alternative form, files, screens, or other
entities shall be assigned names or numbers in such a way that
desired data can be indexed and accessed.

=head2 10.1.6 Response to tailoring instructions.

If a paragraph is tailored out of this DID, the resulting document
shall contain the corresponding paragraph number and title, followed
by 'This paragraph has been tailored out.' For data
in a database or other alternative form, this representation need
occur only in the table of contents or equivalent.

=head2 10.1.7 Multiple paragraphs and subparagraphs.

Any section, paragraph, or subparagraph in this DID may be written
as multiple paragraphs or subparagraphs to enhance readability.

=head2 10.1.8 Standard data descriptions.

If a data description
required by this DID has been published in a standard data element
dictionary specified in the contract, reference to an entry in
that dictionary is preferred over including the description itself.

=head2 10.1.9 Substitution of existing documents.

Commercial
or other existing documents may be substituted for all or part
of the document if they contain the required data.

=head2 10.2 Content requirements.

Content requirements begin on the following page. The numbers
shown designate the paragraph numbers to be used in the document.
Each such number is understood to have the prefix '10.2'
within this DID. For example, the paragraph numbered 1.1 is understood
to be paragraph 10.2.1.1 within this DID.

=head1 1.0 Scope

This section shall be divided into
the following paragraphs.

=head2 1.1 Identification.

This paragraph shall contain
a full identification of the system and the software to which
this document applies, including, as applicable, identification
number(s), title(s), abbreviation(s), version number(s), and release
number(s).

=head2 1.2 System overview.

This paragraph shall
briefly state the purpose of the system and the software to which
this document applies. It shall describe the general nature of
the system and software; summarize the history of system development,
operation, and maintenance; identify the project sponsor, acquirer,
user, developer, and support agencies; identify current and planned
operating sites; and list other relevant documents.

=head2 1.3 Document overview.

This paragraph shall summarize the purpose and contents of this
document and shall describe any security or privacy considerations
associated with its use.

=head1 2.0 Referenced documents

This section shall list the number, title, revision, and date
of all documents referenced in this report. This section shall
also identify the source for all documents not available through
normal Government stocking activities.


=head1 3.0 Overview of test results

This section
shall be divided into the following paragraphs to provide an overview
of test results.

=head2 3.1 Overall assessment of the software tested.

This paragraph shall:

=over 4

=item 1 

Provide an overall assessment of the software
as demonstrated by the test results in this report

=item 2 

Identify any remaining deficiencies, limitations,
or constraints that were detected by the testing performed. Problem/change
reports may be used to provide deficiency information. 

=item 3

For each remaining deficiency, limitation, or
constraint, describe:

=over 4

=item *

Its impact on software and system performance,
including identification of requirements not met

=item *

The impact on software and system design to correct it

=item *

A recommended solution/approach for correcting it

=back

=back

=head2 3.2 Impact of test environment.

This paragraph
shall provide an assessment of the manner in which the test environment
may be different from the operational environment and the effect
of this difference on the test results.

=head2 3.3 Recommended improvements.

This paragraph shall provide any recommended improvements in the
design, operation, or testing of the software tested. A discussion
of each recommendation and its impact on the software may be provided.
If no recommended improvements are provided, this paragraph shall
state 'None.'


=head1 4.0 Detailed test results

 This section shall
be divided into the following paragraphs to describe the detailed
results for each test. Note: The word 'test' means a
related collection of test cases.

=head2 4.x (<U>Project-unique identifier of a test)

This paragraph shall identify a test by project-unique identifier
and shall be divided into the following subparagraphs to describe
the test results.

head2 4.x.1 Summary of test results.

This paragraph
shall summarize the results of the test. The summary shall include,
possibly in a table, the completion status of each test case associated
with the test (for example, 'all results as expected,'
'problems encountered', 'deviations required').
When the completion status is not 'as expected,' this
paragraph shall reference the following paragraphs for details.


=head2 4.x.2 Problems encountered.

This paragraph
shall be divided into subparagraphs that identify each test case
in which one or more problems occurred.

=head2 4.x.2.y (Project-unique identifier of a test case.)

This paragraph shall identify by project-unique identifier a test
case in which one or more problems occurred, and shall provide:

=over 4

=item 1

A brief description of the problem(s) that occurred

=item 2

Identification of the test procedure step(s) in
which they occurred

=item 3

Reference(s) to the associated problem/change
report(s) and backup data, as applicable.

=item 4

The number of times the procedure or step was
repeated in attempting to correct the problem(s) and the outcome
of each attempt 

=item 5

Back up points or test steps where tests
were resumed for retesting

=back

=head2 4.x.3 Deviations from test cases/procedures.


This paragraph shall be divided into subparagraphs that identify
each test case in which deviations from test case/test procedures
occurred.

=head2 4.x.3.y (Project-unique identifier of a test case.

This paragraph shall identify by project-unique identifier a test
case in which one or more deviations occurred, and shall provide:

=over 4

=item 1

A description of the deviation(s) (for example,
test case run in which the deviation occurred and nature of the
deviation, such as substitution of required equipment, procedural
steps not followed, schedule deviations). (Red-lined test procedures
may be used to show the deviations)

=item 2

The rationale for the deviation(s)

=item 3

An assessment of the deviations' impact on the
validity of the test case

=back

=head1 5.0 Test log

 This section shall present, possibly
in a figure or appendix, a chronological record of the test events
covered by this report. This test log shall include: 

=over 4

=item 1

The date(s), time(s), and location(s) of the tests
performed

=item 2

The hardware and software configurations used
for each test including, as applicable, part/model/serial number,
manufacturer, revision level, and calibration date of all hardware,
and version number and name for the software components used

=item 3

The date and time of each test related activity,

=item 4

The identity of the individual(s) who performed the activity,
and the identities of witnesses, as applicable

=back

=head1 6.0 Notes.

This section shall contain any general
information that aids in understanding this document (e.g., background
information, glossary, rationale). This section shall include
an alphabetical listing of all acronyms, abbreviations, and their
meanings as used in this document and a list of any terms and
definitions needed to understand this document.

=head1 10.0 Appendixes

Appendixes may be used to provide
information published separately for convenience in document maintenance
(e.g., charts, classified data). As applicable, each appendix
shall be referenced in the main body of the document where the
data would normally have been provided. Appendixes may be bound
as separate documents for ease in handling. Appendixes shall be
lettered alphabetically (A, B, etc.).

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
