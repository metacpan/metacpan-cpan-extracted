#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package Docs::US_DOD::SIP;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81428';
$TITLE = 'SOFTWARE INSTALLATION PLAN (SIP)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item.

=head1 1. TITLE

SOFTWARE INSTALLATION PLAN (SIP)

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81428

=head1 3. DESCRIPTION/PURPOSE

The Software Installation Plan (SIP) is a plan for
installing software at user sites, including preparations, user
training, and conversion from existing systems.

The SIP is developed when the developer will be involved
in the installation of software at user sites and when the installation
process will be sufficiently complex to require a documented plan.
For software embedded in a hardware-software system, a fielding
or deployment plan for the hardware-software system may make a
separate SIP unnecessary.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked
to develop and record plans for performing software installation
and training at user sites.
The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document.
This DID supersedes DI-IPSC-80699.

=head1 10. PREPARATION INSTRUCTIONS 


=head2 10.1 General instructions.


=head2 10.1.1 Automated techniques

Use of automated techniques
is encouraged. The term 'document' in this DID means
a collection of data regardless of its medium. 

=head2 10.1.2 Alternate presentation styles

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

This section shall be divided into
the following paragraphs.

=head2 1.1 Identification

This paragraph shall contain a full
identification of the system and the software to which this document
applies, including, as applicable, identification number(s), title(s),
abbreviation(s), version number(s), and release number(s).

=head2 1.2 System overview

This paragraph shall briefly state
the purpose of the system and the software to which this document
applies. It shall describe the general nature of the system and
software; summarize the history of system development, operation,
and maintenance; identify the project sponsor, acquirer, user,
developer, and support agencies; identify current and planned
operating sites; and list other relevant documents.

=head2 1.3 Document overview

This paragraph shall summarize the
purpose and contents of this plan and shall describe any security
or privacy considerations associated with its use.

=head2 1.4 Relationship to other plans

This paragraph shall describe the
relationship, if any, of the SIP to other project management plans.

=head1 2 Referenced documents.

This section shall list the number,
title, revision, and date of all documents referenced in this
plan. This section shall also identify the source for all documents
not available through normal Government stocking activities.

=head1 3 Installation overview.

This section shall be divided into
the following paragraphs to provide an overview of the installation
process.

=head2 3.1 Description

This paragraph shall provide a general
description of the installation process to provide a frame of
reference for the remainder of the document. A list of sites for
software installation, the schedule dates, and the method of installation
shall be included.

=head2 3.2 Contact point

This paragraph shall provide the organizational
name, office symbol/code, and telephone number of a point of contact
for questions relating to this installation.

=head2 3.3 Support materials

This paragraph shall list the type,
source, and quantity of support materials needed for the installation.
Included shall be items such as magnetic tapes, disk packs, computer
printer paper, and special forms.

=head2 3.4 Training.

This paragraph shall describe the
developer's plans for training personnel who will operate and/or
use the software installed at user sites. Included shall be the
delineation between general orientation, classroom training, and
'hands-on' training.

=head2 3.5 Tasks.

This paragraph shall list and describe
in general terms each task involved in the software installation.
Each task description shall identify the organization that will
accomplish the task, usually either the user, computer operations,
or the developer. The task list shall include such items as:

=over 4

=item 1

Providing overall planning, coordination,
and preparation for installation

=item 2

Providing personnel for the installation team

=item 3

Arranging lodging, transportation, and office
facilities for the installation team

=item 4

Ensuring that all manuals applicable to the
installation are available when needed

=item 5

Ensuring that all other prerequisites have
been fulfilled prior to the installation

=item 6

Planning and conducting training activities

=item 7

Providing students for the training

=item 8

Providing computer support and technical assistance
for the installation

=item 9

Providing for conversion from the current
system

=back

=head2 3.6 Personnel.

This paragraph shall describe the
number, type, and skill level of the personnel needed during the
installation period, including the need for multishift operation,
clerical support, etc.

=head2 3.7 Security and privacy.

This paragraph shall contain an overview
of the security and privacy considerations associated with the
system.

=head1 4

Site-specific information for software
center operations staff.
This section applies if the software
will be installed in computer center(s) or other centralized or
networked software installations for users to access via terminals
or using batch inputs/outputs. If this type of installation does
not apply, this section shall contain the words 'Not applicable.'

=head2 4.x (Site name).

This paragraph shall identify a site
or set of sites and shall be divided into the following subparagraphs
to discuss those sites. Multiple sites may be discussed together
when the information for those sites is generally the same.

=head2 4.x.1 Schedule.

This paragraph shall present a schedule
of tasks to be accomplished during installation. It shall depict
the tasks in chronological order with beginning and ending dates
of each task and supporting narrative as necessary.

=head2 4.x.2 Software inventory.

This paragraph shall provide an inventory
of the software needed to support the installation. The software
shall be identified by name, identification number, version number,
release number, configuration, and security classification, as
applicable. This paragraph shall indicate whether the software
is expected to be on site or will be delivered for the installation
and shall identify any software to be used only to facilitate
the installation process.

=head2 4.x.3 Facilities.

This paragraph shall detail the physical
facilities and accommodations needed during the installation period.
This description shall include the following, as applicable:

=over 4

=item 1

Classroom, work space, and training aids needed,
specifying hours per day, number of days, and shifts

=item 2

Hardware that must be operational and available

=item 3

Transportation and lodging for the installation
team

=back

=head2 4.x.4 Installation team.

This paragraph shall describe the
composition of the installation team. Each team member's tasks
shall be defined.

=head2 4.x.5 Installation procedures.

This paragraph shall provide step-by-step
procedures for accomplishing the installation. References may
be made to other documents, such as operator manuals. Safety precautions,
marked by WARNING or CAUTION, shall be included where applicable.
The procedures shall include the following, as applicable:

=over 4

=item 1

Installing the software

=item 2

Checking out the software once installed

=item 3

Initializing databases and other software
with site-specific data

=item 4

Conversion from the current system, possibly
involving running in parallel

=item 5

Dry run of the procedures in operator and
user manuals

=back

=head2 4.x.6 Data update procedures.

This paragraph shall present the data
update procedures to be followed during the installation period.
When the data update procedures are the same as normal updating
or processing procedures, reference may be made to other documents,
such as operator manuals.

=head1 5

Site-specific information for software
users.
This section shall provide installation
planning pertinent to users of the software. When more than one
type of user is involved, for example, users at different positions,
performing different functions, or in different organizations,
a separate section (Sections 5 through n) may be written for each
type of user and the section titles modified to reflect each user.

=head2 5.x (Site name).

This paragraph shall identify a site
or set of sites and shall be divided into the following subparagraphs
to discuss those sites. Multiple sites may be discussed together
when the information for those sites is generally the same.

=head2 5.x.1 Schedule.

This paragraph shall present a schedule
of tasks to be accomplished by the user during installation. It
shall depict the tasks in chronological order including beginning
and ending dates for each task and supporting narrative as necessary.

=head2 5.x.2 Installation procedures.

This paragraph shall provide step-by-step
procedures for accomplishing the installation. Reference may be
made to other documents, such as user manuals. Safety precautions,
marked by WARNING or CAUTION, shall be included where applicable.
The procedures shall include the following, as applicable:

=over 4

=item 1

Performing the tasks under 4.x.5 if not performed
by operations staff

=item 2

Initializing user-specific data

=item 3

Setting up queries and other user inputs

=item 4

Performing sample processing

=item 5

Generating sample reports

=item 6

Conversion from the current system, possibly
involving running in parallel

=item 7

Dry run of procedures in user manuals

=back

=head2 5.x.3 Data update procedures.

This paragraph shall be divided into
subparagraphs to present the user's data update procedures to
be followed during the installation period. When update procedures
are the same as normal processing, reference may be made to other
documents, such as user manuals, and to Section 4 of this document

=head1 6 Notes.

This section shall contain any general
information that aids in understanding this document (e.g., background
information, glossary, rationale). This section shall include
an alphabetical listing of all acronyms, abbreviations, and their
meanings as used in this document and a list of terms and definitions
needed to understand this document. If section 5 has been expanded
into section(s) 6,...n, this section shall be numbered as the
next section following section n.

=head1 A. Appendixes

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
