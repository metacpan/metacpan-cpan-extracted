#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::STD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81439';
$TITLE = 'SOFTWARE TEST DESCRIPTION (STD)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item.

=head1 1. TITLE

SOFTWARE TEST DESCRIPTION (STD) 

=head1 2. IDENTIFICATION NUMBER 

DI-IPSC-81439

=head1 3. DESCRIPTION/PURPOSE

The Software Test Description (STD) describes the
test preparations, test cases, and test procedures to be used
to perform qualification testing of a Computer Software Configuration
Item (L<CSCI>) or a software system or subsystem. 

The STD enables the acquirer to assess the adequacy
of the qualification testing to be performed. 

=head1 7. APPLICATION/INTERRELATIONSHIP 

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.
<P>

This DID is used when the developer is tasked to
define and record the test preparations, test cases, and test
procedures to be used for CSCI qualification testing or for system
qualification testing of a software system. 

The Contract Data Requirements List (L<CDRL>) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. </FONT>

This DID supersedes DI-MCCR-80015A and DI-MCCR-80310.

=head1 10. PREPARATION INSTRUCTIONS

=head2 10.1 General instructions.

=head2 10.1.1 Automated techniques

Use of automated techniques
is encouraged. The term 'document' in this DID means
a collection of data regardless of its medium. 

=head2 10.1.2 Alternate presentation styles

Diagrams, tables, matrices, and other presentation styles are 
acceptable substitutes for text when data required by this DID 
can be made more readable using these styles. 

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

If a paragraph is tailored out of this DID, the resulting document shall contain
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

=head2 10.1.9 Substitution of existing documents.

Commercial or other existing documents may be substituted for all or part
of the document if they contain the required data. 

=head2 10.2 Content requirements.

Content requirements begin on the following page. The numbers
shown designate the paragraph numbers to be used in the document.
Each such number is understood to have the prefix '10.2'
within this DID. For example, the paragraph numbered 1.1 is understood
to be paragraph 10.2.1.1 within this DID.

=head1 1. Scope

This section shall be divided into the following paragraphs.

=head2 1.1 Identification

This paragraph shall contain a full identification of the
system and the software to which this document applies, including,
as applicable, identification number(s), title(s), abbreviation(s),
version number(s), and release number(s). 

=head2 1.2 System overview

This paragraph shall briefly state the purpose of the system
and the software to which this document applies. It shall describe
the general nature of the system and software; summarize the history
of system development, operation, and maintenance; identify the
project sponsor, acquirer, user, developer, and support agencies;
identify current and planned operating sites; and list other relevant
documents. 

=head2 1.3 Document overview

This paragraph shall summarize the purpose and contents
of this document and shall describe any security or privacy considerations
associated with its use. 

=head1 2. Referenced documents

This section shall list the number, title, revision, and
date of all documents referenced in this document. This section
shall also identify the source for all documents. 

=head1 3. Test preparations

This section shall be divided into the following paragraphs.
Safety precautions, marked by WARNING or CAUTION, and security
and privacy considerations shall be included as applicable. 

=head2 3.x (Project-unique identifier of a test)

This paragraph shall identify a test by project-unique identifier,
shall provide a brief description, and shall be divided into the
following subparagraphs. When the information required duplicates
information previously specified for another test, that information
may be referenced rather than repeated. 

=head2 3.x.1 Hardware preparation

This paragraph shall describe the procedures necessary to
prepare the hardware for the test. Reference may be made to published
operating manuals for these procedures. The following shall be
provided, as applicable: 

=over 4

=item 1

The specific hardware to be used, identified by name and,
if applicable, number

=item 2 

Any switch settings and cabling necessary to connect the
hardware

=item 3 

One or more diagrams to show hardware, interconnecting
control, and data paths

=item 4 

Step-by-step instructions for placing the hardware in a
state of readiness 

=back

=head2 3.x.2 Software preparation

This paragraph shall describe the procedures necessary to
prepare the item(s) under test and any related software, including
data, for the test. Reference may be made to published software
manuals for these procedures. The following information shall
be provided, as applicable: 

=over 4

=item 1 

The specific software to be used in the test

=item 2 

The storage medium of the item(s) under test (e.g., magnetic
tape, diskette) 

=item 3 

The storage medium of any related software (e.g., simulators,
test drivers, databases)

=item 4 

Instructions for loading the software, including required
sequence

=item 5 

Instructions for software initialization common to more
than one test case 

=back

=head2 3.x.3 Other pre-test preparations

This paragraph shall describe any other pre-test personnel
actions, preparations, or procedures necessary to perform the
test. 

=head1 4. Test descriptions

This section shall be divided into the following paragraphs.
Safety precautions, marked by WARNING or CAUTION, and security
and privacy considerations shall be included as applicable. 

=head2 4.x (Project-unique identifier of a test)

This paragraph shall identify a test by project-unique identifier
and shall be divided into the following subparagraphs. When the
required information duplicates information previously provided,
that information may be referenced rather than repeated. 

=head2 4.x.y (Project-unique identifier of a test case)

This paragraph shall identify a test case by project-unique
identifier, state its purpose, and provide a brief description.
The following subparagraphs shall provide a detailed description
of the test case. 

=head2 4.x.y.1 Requirements addressed. 

This paragraph shall identify
the CSCI or system requirements addressed by the test case. (Alternatively,
this information may be provided in 5.a.) 

=head2 4.x.y.2 Prerequisite conditions.

This paragraph shall identify any prerequisite conditions that
must be established prior to performing the test case. The following
considerations shall be discussed, as applicable: 

=over 4

=item 1 

Hardware and software configuration

=item 2 

Flags, initial breakpoints, pointers, control parameters,
or initial data to be set/reset prior to test commencement

=item 3

Preset hardware conditions or electrical states necessary
to run the test case

=item 4

Initial conditions to be used in making timing measurements

=item 5 

Conditioning of the simulated environment

=item 6 

Other special conditions peculiar to the test case 

=back

=head2 4.x.y.3 Test inputs.

This paragraph shall describe the test inputs necessary for
the test case. The following shall be provided, as applicable:

=over 4

=item 1 

Name, purpose, and description (e.g., range of values,
accuracy) of each test input

=item 2 

Source of the test input and the method to be used for
selecting the test input

=item 3

Whether the test input is real or simulated

=item 4

Time or event sequence of test input 

=item 5

The manner in which the input data will be controlled to:

=over 4

=item * 

Test the item(s) with a minimum/reasonable number of data
types and values

=item *

Exercise the item(s) with a range of valid data types and
values that test for overload, saturation, and other 'worst
case' effects

=item * 

Exercise the item(s) with invalid data types and values
to test for appropriate handling of irregular inputs

=item * 

Permit retesting, if necessary

=back

=back 

=head2 4.x.y.4 Expected test results.

This paragraph shall identify all expected test results for
the test case. Both intermediate and final test results shall
be provided, as applicable. 

=head2 4.x.y.5 Criteria for evaluating results.

This paragraph shall identify the criteria to be used for evaluating
the intermediate and final results of the test case. For each
test result, the following information shall be provided, as applicable:

=over 4

=item 1

The range or accuracy over which an output can vary and
still be acceptable

=item 2

Minimum number of combinations or alternatives of input
and output conditions that constitute an acceptable test result

=item 3

Maximum/minimum allowable test duration, in terms of time
or number of events

=item 4

Maximum number of interrupts, halts, or other system breaks
that may occur

=item 5

Allowable severity of processing errors 

=item 6

Conditions under which the result is inconclusive and re-testing
is to be performed

=item 7

Conditions under which the outputs are to be interpreted
as indicating irregularities in input test data, in the test database/data
files, or in test procedures

=item 8

Allowable indications of the control, status, and results
of the test and the readiness for the next test case (may be output
of auxiliary test software)

=item 9 

Additional criteria not mentioned above.

=back

=head2 4.x.y.6 Test procedure.

This paragraph shall define the test procedure for the test
case. The test procedure shall be defined as a series of individually
numbered steps listed sequentially in the order in which the steps
are to be performed. For convenience in document maintenance,
the test procedures may be included as an appendix and referenced
in this paragraph. The appropriate level of detail in each test
procedure depends on the type of software being tested. For some
software, each keystroke may be a separate test procedure step;
for most software, each step may include a logically related series
of keystrokes or other actions. The appropriate level of detail
is the level at which it is useful to specify expected results
and compare them to actual results. The following shall be provided
for each test procedure, as applicable: 

=over 4

=item 1 

Test operator actions and equipment operation required
for each step, including commands, as applicable, to: 

=over 4

=item *

Initiate the test case and apply test inputs

=item *

Inspect test conditions

=item *

Perform interim evaluations of test results

=item *

Record data

=item *

Halt or interrupt the test case

=item *

Request data dumps or other aids, if needed

=item *

Modify the database/data files

=item *

Repeat the test case if unsuccessful

=item *

Apply alternate modes as required by the test case 

=item *

Terminate the test case 

=back

=item 2 

Expected result and evaluation criteria for each step 

=item 3

If the test case addresses multiple requirements, identification
of which test procedure step(s) address which requirements. (Alternatively,
this information may be provided in 5.) 

=item 4

Actions to follow in the event of a program stop or indicated
error, such as:

=over 4

=item *

Recording of critical data from indicators for reference
purposes

=item *

Halting or pausing time-sensitive test-support software
and test apparatus

=item *

Collection of system and operator records of test results

=back

=item 5

Procedures to be used to reduce and analyze test results
to accomplish the following, as applicable:

=over 4

=item *

Detect whether an output has been produced

=item *

Identify media and location of data produced by the test case

=item *

Evaluate output as a basis for continuation of test sequence

=item *

Evaluate test output against required output 

=back

=back

=head2 4.x.y.7 Assumptions and constraints.

This paragraph shall identify any assumptions made and constraints
or limitations imposed in the description of the test case due
to system or test conditions, such as limitations on timing, interfaces,
equipment, personnel, and database/data files. If waivers or exceptions
to specified limits and parameters are approved, they shall be
identified and this paragraph shall address their effects and
impacts upon the test case. 

=head1 5. Requirements traceability.

This paragraph shall contain: 

=over

=item 1

Traceability from each test case in this STD to the system
or CSCI requirements it addresses. If a test case addresses multiple
requirements, traceability from each set of test procedure steps
to the requirement(s) addressed. (Alternatively, this traceability
may be provided in 4.x.y.1.)

=item 2 

Traceability from each system or CSCI requirement covered
by this STD to the test case(s) that address it. For CSCI testing,
traceability from each CSCI requirement in the CSCI's Software
Requirements Specification (SRS) and associated Interface Requirements
Specifications (IRSs). For system testing, traceability from each
system requirement in the system's System/Subsystem Specification
(SSS) and associated IRSs. If a test case addresses multiple requirements,
the traceability shall indicate the particular test procedure
steps that address each requirement.

=back

=head1 6. Notes.

This section shall contain any general information that aids
in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of any terms and definitions
needed to understand this document. 


=head1 A Appendixes. 

Appendixes may be used to provide information published separately
for convenience in document maintenance (e.g., charts, classified
data). As applicable, each appendix shall be referenced in the
main body of the document where the data would normally have been
provided. Appendixes may be bound as separate documents for ease
in handling. Appendixes shall be lettered alphabetically (A, B,
etc.). 

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
