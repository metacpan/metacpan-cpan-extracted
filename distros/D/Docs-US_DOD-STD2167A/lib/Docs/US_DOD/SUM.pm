#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::SUM;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.08';
$DATE = '2003/06/14';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81443';
$TITLE = 'SOFTWARE USER MANUAL (SUM)';
$REVISION = '-';
$REVISION_DATE = '';

1

__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. Document style, layout,
etc., shall conform to the Documentation Standard

=head1 1. TITLE

SOFTWARE USER MANUAL (SUM)

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81443

=head1 3. DESCRIPTION/PURPOSE

The Software User Manual (SUM) tells a hands-on software
user how to install and use a Computer Software Configuration
Item (CSCI), a group of related CSCIs, or a software system or
subsystem. It may also cover a particular aspect of software operation,
such as instructions for a particular position or task. 

The SUM is developed for software that is run by
the user and has a user interface requiring on-line user input
or interpretation of displayed output. If the software is embedded
in a hardware-software system, user manuals or operating procedures
for that system may make separate SUMs unnecessary.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract. 

This DID is used when the developer is tasked to
identify and record information needed by hands-on users of software.

The SUM is an alternative to the Software Input/Output
Manual (SIOM) (DI-IPSC-81445) and Software Center Operator Manual
(SCOM) (DI-IPSC-81444). 

The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 
This DID supersedes DI-MCCR-80019A, DI-IPSC-80694, DI-MCCR-80313,
DI-MCCR-80314, DI-MCCR-60315..

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
using these styles. 

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

=head2 10.1.9 Substitution of existing documents.

Commercial or other existing documents may be substituted for all or part
of the document if they contain the required data. 

=head2 10.2 Content requirements.

Content requirements begin on the following page. The numbers
shown designate the paragraph numbers to be used in the document.
Each such number is understood to have the prefix '10.2'
within this DID. For example, the paragraph numbered 1.1 is understood
to be paragraph 10.2.1.1 within this DID.

=head1 1 Scope. 

This section shall be divided
into the following paragraphs.

=head2 1.1 Identification. 

This paragraph
shall contain a full identification of the system(s), the interfacing
entities, and interfaces to which this document applies, including,
as applicable, identification number(s), title(s), abbreviation(s),
version number(s), and release number(s).

=head2 1.2 System overview.

This paragraph
shall briefly state the purpose of the system(s) and software
to which this document applies. It shall describe the general
nature of the system and software; summarize the history of system
development, operation, and maintenance; identify the project
sponsor, acquirer, user, developer, and support agencies; identify
current and planned operating sites; and list other relevant documents.

=head2 1.3 Document overview. 

This
paragraph shall summarize the purpose and contents of this document
and shall describe any security or privacy considerations associated
with its use.

=head1 2 Referenced documents.

This section shall list the number, title, revision, and date of all
documents referenced in this document. This section shall also
identify the source for all documents not available through normal
Government stocking activities.

=head1 3 Software summary.

This section shall be divided into the following paragraphs.

=head2 3.1 Software application.

This paragraph shall provide a brief description of the intended uses of the
software. Capabilities, operating improvements, and benefits expected
from its use shall be described.

=head2 3.2 Software inventory.

This paragraph shall identify all software files, including databases and data
files, that must be installed for the software to operate. The
identification shall include security and privacy considerations
for each file and identification of the software necessary to
continue or resume operation in case of an emergency.

=head2 3.3 Software environment.

This paragraph shall identify the hardware, software, manual operations, and
other resources needed for a user to install and run the software.
Included, as applicable, shall be identification of: 
&nbsp;

=over 4

=item 1

Computer equipment that must be present, including
amount of memory needed, amount of auxiliary storage needed, and
peripheral equipment such as printers and other input/output devices

=item 2

Communications equipment that must be present

=item 3

Other software that must be present, such as operating systems,
databases, data files, utilities, and other supporting systems

=item 4

Forms, procedures, or other manual operations that must be
present 

=item 5

Other facilities, equipment, or resources that must be present

=back

=head2 3.4 Software organization and overview of operation.

This paragraph shall provide a brief description of the organization
and operation of the software from the user's point of view. The
description shall include, as applicable: 

=over 4

=item 1

Logical components of the software, from the
user's point of view, and an overview of the purpose/operation
of each component 

=item 1

Performance characteristics that can be expected by the user,
such as: 

=over 4

=item *

Types, volumes, rate of inputs accepted 

=item *

Types, volume, accuracy, rate of outputs that the software
can produce 

=item *

Typical response time and factors that affect it 

=item *

Typical processing time and factors that affect it 

=item *

Limitations, such as number of events that can be tracked 

=item * 

Error rate that can be expected

=item *  Reliability that can be expected

=back


=item 3

Relationship of the functions performed by the software with
interfacing systems, organizations, or positions 
d. Supervisory controls that can be implemented (such as passwords)
to manage the software 

=back

=head2 3.5 Contingencies and alternate states and
modes of operation. 

This paragraph shall explain differences
in what the user will be able to do with the software at times
of emergency and in various states and modes of operation, if
applicable.

=head2 3.6 Security and privacy.

This paragraph
shall contain an overview of the security and privacy considerations
associated with the software. A warning shall be included regarding
making unauthorized copies of software or documents, if applicable.

=head2 3.7 Assistance and problem reporting.

This paragraph shall identify points of contact and procedures
to be followed to obtain assistance and report problems encountered
in using the software.

=head1 4 Access to the software.

This section shall contain step-by-step procedures oriented to the first time/occasional
user. Enough detail shall be presented so that the user can reliably
access the software before learning the details of its functional
capabilities. Safety precautions, marked by WARNING or CAUTION,
shall be included where applicable.

=head2 4.1 First-time user of the software.

This paragraph shall be divided into the following subparagraphs.

=head2 4.1.1 Equipment familiarization

Thisparagraph shall describe the following as appropriate: 

=over 4

=item 1

Procedures for turning on power and making
adjustments 

=item 2

Dimensions and capabilities of the visual display screen 

=item 3

Appearance of the cursor, how to identify an active cursor
if more than one cursor can appear, how to position a cursor,
and how to use a cursor

=item 4

Keyboard layout and role of different types
of keys and pointing devices 
e. Procedures for turning power off if special sequencing of operations
is needed 

=back

=head2 4.1.2 Access control

This paragraph shall present an overview of the access and security features
of the software that are visible to the user. The following items
shall be included, as applicable: 
&nbsp;

=over 4

=item 1

How and from whom to obtain a password 

=item 2

How to add, delete, or change passwords under user control

=item 3

Security and privacy considerations pertaining to the storage
and marking of output reports and other media that the user will
generate

=back

=head2 4.1.3 Installation and setup

This paragraph shall describe any procedures that the user must perform
to be identified or authorized to access or install software on
the equipment, to perform the installation, to configure the software,
to delete or overwrite former files or data, and to enter parameters
for software operation.

=head2 4.2 Initiating a session. This paragraph

shall provide step-by-step procedures for beginning work, including
any options available. A checklist for problem determination shall
be included in case difficulties are encountered.

=head2 4.3 Stopping and suspending work.

This paragraph shall describe how the user can cease or interrupt use
of the software and how to determine whether normal termination
or cessation has occurred.

=head1 5 Processing reference guide. 

This section shall provide the user with procedures for using the software.
If procedures are complicated or extensive, additional Sections
6, 7, ... may be added in the same paragraph structure as this
section and with titles meaningful to the sections selected. The
organization of the document will depend on the characteristics
of the software being documented. For example, one approach is
to base the sections on the organizations in which users work,
their assigned positions, their work sites, or the tasks they
must perform. For other software, it may be more appropriate to
have Section 5 be a guide to menus, Section 6 be a guide to the
command language used, and Section 7 be a guide to functions.
Detailed procedures are intended to be presented in subparagraphs
of paragraph 5.3. Depending on the design of the software, the
subparagraphs might be organized on a function&#173;by&#173;function,
menu&#173;by&#173;menu, transaction-by-transaction, or other basis.
Safety precautions, marked by WARNING or CAUTION, shall be included
where applicable.

=head2 5.1 Capabilities.

This paragraph shall
briefly describe the interrelationships of the transactions, menus,
functions, or other processes in order to provide an overview
of the use of the software.

=head2 5.2 Conventions.

This paragraph shall
describe any conventions used by the software, such as the use
of colors in displays, the use of audible alarms, the use of abbreviated
vocabulary, and the use of rules for assigning names or codes.

=head2 5.3 Processing procedures.

This paragraph
shall explain the organization of subsequent paragraphs, e.g.,
by function, by menu, by screen. Any necessary order in which
procedures must be accomplished shall be described.

=head2 5.3.x (Aspect of software use).

The title of this paragraph shall identify the function, menu, transaction,
or other process being described. This paragraph shall describe
and give options and examples, as applicable, of menus, graphical
icons, data entry forms, user inputs, inputs from other software
or hardware that may affect the software's interface with the
user, outputs, diagnostic or error messages or alarms, and help
facilities that can provide on-line descriptive or tutorial information.
The format for presenting this information can be adapted to the
particular characteristics of the software, but a consistent style
of presentation shall be used, i.e., the descriptions of menus


shall be consistent, the descriptions of transactions shall be
consistent among themselves.

=head2 5.4 Related processing.

This paragraph
shall identify and describe any related batch, offline, or background
processing performed by the software that is not invoked directly
by the user and is not described in paragraph 5.3. Any user responsibilities
to support this processing shall be specified.

=head2 5.5 Data backup.

This paragraph shall
describe procedures for creating and retaining backup data that
can be used to replace primary copies of data in event of errors,
defects, malfunctions, or accidents.

=head2 5.6 Recovery from errors, malfunctions, and
emergencies.

This paragraph shall present detailed procedures
for restart or recovery from errors or malfunctions occurring
during processing and for ensuring continuity of operations in
the event of emergencies.

=head2 5.7 Messages.

This paragraph shall
list, or refer to an appendix that lists, all error messages,
diagnostic messages, and information messages that can occur while
accomplishing any of the user's functions. The meaning of each
message and the action that should be taken after each such message
shall be identified and described.

=head2 5.8 Quick-reference guide.

If appropriate
to the software, this paragraph shall provide or reference a quick-reference
card or page for using the software. This quick-reference guide
shall summarize, as applicable, frequently-used function keys,
control sequences, formats, commands, or other aspects of software
use.

=head1 6 Notes.

This section shall contain
any general information that aids in understanding this document
(e.g., background information, glossary, rationale). This section
shall include an alphabetical listing of all acronyms, abbreviations,
and their meanings as used in this document and a list of terms
and definitions needed to understand this document. If section
has been expanded into section(s) 6, . . ., this section shall
be numbered as the next section following section n. 

A. Appendixes.

Appendixes may be used
to provide information published separately for convenience in
document maintenance (e.g., charts, classified data). As applicable,
each appendix shall be referenced in the main body of the document
where the data would normally have been provided. Appendixes may
be bound as separate documents for ease in handling. Appendixes
shall be lettered alphabetically (A, B, etc.).&nbsp;

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
