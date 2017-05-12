#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::SDP;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81427';
$TITLE = 'SOFTWARE DEVELOPMENT PLAN (SDP)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. Document style, layout,
etc., shall conform to the Documentation Standard
and an example is provided by Software Development Plan - Model Text.

=head1 1. TITLE

SOFTWARE DEVELOPMENT PLAN (SDP)

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81427

=head1 3. DESCRIPTION/PURPOSE

The Software Development Plan (SDP) describes a developer's
plans for conducting a software development effort. The term 'software
development' in this DID is meant to include new development,
modification, reuse, reengineering, maintenance, and all other
activities resulting in software products. 

The SDP provides the acquirer insight into, and a
tool for monitoring, the processes to be followed for software
development, the methods to be used, the approach to be followed
for each activity, and project schedules, organization, and resources.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
develop and record plans for conducting software development activities.

Portions of this plan may be bound separately if
this approach enhances their usability. Examples include plans
for software configuration management and software quality assurance.

The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-MCCR-80030A, DI-MCCR-80297,
DI-MCCR-80298, DI-MCCR-80299, DI-MCCR-80300, and DI-MCCR-80319.

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

=head2 1.1 Identification.

This paragraph shall contain a full
identification of the system and the software to which this document
applies, including, as applicable, identification number(s), title(s),
abbreviation(s), version number(s), and release number(s).

=head2 1.2 System overview.

This paragraph shall briefly state
the purpose of the system and the software to which this document
applies. It shall describe the general nature of the system and
software; summarize the history of system development, operation,
and maintenance; identify the project sponsor, acquirer, user,
developer, and support agencies; identify current and planned
operating sites; and list other relevant documents.

=head2 1.3 Document overview.

This paragraph shall summarize the
purpose and contents of this document and shall describe any security
or privacy considerations associated with its use.

=head2 1.4 Relationship to other plans.

This paragraph shall describe the
relationship, if any, of the SDP to other project management plans.

=head1 2 Referenced documents.

This section shall list the number,
title, revision, and date of all documents referenced in this
plan. This section shall also identify the source for all documents
not available through normal Government stocking activities.

=head1 3 Overview of required work.

This section shall be divided into
paragraphs as needed to establish the context for the planning
described in later sections. It shall include, as applicable,
an overview of:

=over 4

=item 1

Requirements and constraints on the system
and software to be developed

=item 2

Requirements and constraints on project documentation

=item 3

Position of the project in the system life
cycle

=item 4

The selected program/acquisition strategy
or any requirements or constraints on it

=item 5

Requirements and constraints on project schedules
and resources

=item 6

Other requirements and constraints, such as
on project security, privacy, methods, standards, interdependencies
in hardware and software development, etc.

=back

=head1 4 Plans for performing general software
development activities. 

This section shall be divided into
the following paragraphs. Provisions corresponding to non-required
activities may be satisfied by the words 'Not applicable.'
If different builds or different software on the project require
different planning, these differences shall be noted in the paragraphs.
In addition to the content specified below, each paragraph shall
identify applicable risks/uncertainties and plans for dealing
with them.

=head2 4.1 Software development process.















This paragraph shall describe the
software development process to be used. The planning shall cover
all contractual clauses concerning this topic, identifying planned
builds, if applicable, their objectives, and the software development
activities to be performed in each build.

=head2 4.2 General plans for software development.

This paragraph shall be divided into
the following subparagraphs.

=head2 4.2.1 Software development methods.

This paragraph shall describe or reference
the software development methods to be used. Included shall be
descriptions of the manual and automated tools and procedures
to be used in support of these methods. The methods shall cover
all contractual clauses concerning this topic. Reference may be
made to other paragraphs in this plan if the methods are better
described in context with the activities to which they will be
applied.

=head2 4.2.2 Standards for software products.

This paragraph shall describe or reference
the standards to be followed for representing requirements, design,
code, test cases, test procedures, and test results. The standards
shall cover all contractual clauses concerning this topic. Reference
may be made to other paragraphs in this plan if the standards
are better described in context with the activities to which they
will be applied. Standards for code shall be provided for each
programming language to be used. They shall include at a minimum:

=over 4

=item 1

Standards for format (such as indentation,
spacing, capitalization, and order of information)

=item 2

Standards for header comments (requiring,
for example, name/identifier of the code; version identification;
modification history; purpose; requirements and design decisions
implemented; notes on the processing (such as algorithms used,
assumptions, constraints, limitations, and side effects); and
notes on the data (inputs, outputs, variables, data structures,
etc.)

=item 3

Standards for other comments (such as required
number and content expectations)

=item 4

Naming conventions for variables, parameters,
packages, procedures, files, etc.

=item 5

Restrictions, if any, on the use of programming
language constructs or features

=item 6

Restrictions, if any, on the complexity of
code aggregates

=back

=head2 4.2.3 

Reusable software products.
This paragraph shall be divided into the
following subparagraphs.

=head2 4.2.3.1 Incorporating reusable software
products.

This paragraph shall describe the
approach to be followed for identifying, evaluating, and incorporating
reusable software products, including the scope of the search
for such products and the criteria to be used for their evaluation.
It shall cover all contractual clauses concerning this topic.
Candidate or selected reusable software products known at the
time this plan is prepared or updated shall be identified and
described, together with benefits, drawbacks, and restrictions,
as applicable, associated with their use.

=head2 4.2.3.2 Developing reusable software products.

This paragraph shall describe the
approach to be followed for identifying, evaluating, and reporting
opportunities for developing reusable software products. It shall
cover all contractual clauses concerning this topic.

=head2 4.2.4 Handling of critical requirements.



This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for handling requirements designated critical. The planning in
each subparagraph shall cover all contractual clauses concerning
the identified topic.

=head2 4.2.4.1 Safety assurance



=head2 4.2.4.2 Security assurance



=head2 4.2.4.3 Privacy assurance



=head2 4.2.4 .4 Assurance of other critical requirements



=head2 4.2.5 Computer hardware resource utilization.

This paragraph shall describe the
approach to be followed for allocating computer hardware resources
and monitoring their utilization. It shall cover all contractual
clauses concerning this topic.

=head2 4.2.6 Recording rationale.

This paragraph shall describe the
approach to be followed for recording rationale that will be useful
to the support agency for key decisions made on the project. It
shall interpret the term 'key decisions' for the project
and state where the rationale are to be recorded. It shall cover
all contractual clauses concerning this topic.

=head2 4.2.7 Access for acquirer review.

This paragraph shall describe the
approach to be followed for providing the acquirer or its authorized
representative access to developer and subcontractor facilities
for review of software products and activities. It shall cover
all contractual clauses concerning this topic.

=head1 5 Plans for performing detailed software
development activities. 

This section shall be divided into
the following paragraphs. Provisions corresponding to non-required
activities may be satisfied by the words 'Not applicable.'
If different builds or different software on the project require
different planning, these differences shall be noted in the paragraphs.
The discussion of each activity shall include the approach (methods/procedures/tools)
to be applied to: 1) the analysis or other technical tasks involved,
2) the recording of results, and 3) the preparation of associated
deliverables, if applicable. The discussion shall also identify
applicable risks/uncertainties and plans for dealing with them.
Reference may be made to 4.2.1 if applicable methods are described
there.

=head2 5.1 Project planning and oversight.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for project planning and oversight. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.1.1 Software development planning (covering
updates to this plan)



=head2 5.1.2 CSCI test planning



=head2 5.1.3 System test planning



=head2 5.1.4 Software installation planning



=head2 5.1.5 Software transition planning



=head2 5.1.6 Following and updating plans, including
the intervals for management review



=head2 5.2 Establishing a software development
environment.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for establishing, controlling, and maintaining a software development
environment. The planning in each subparagraph shall cover all
contractual clauses regarding the identified topic.

=head2 5.2.1 Software engineering environment



=head2 5.2.2 Software test environment



=head2 5.2.3 Software development library



=head2 5.2.4 Software development files



=head2 5.2.5 Non-deliverable software



=head2 5.3 System requirements analysis.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for participating in system requirements analysis. The planning
in each subparagraph shall cover all contractual clauses regarding
the identified topic.

=head2 5.3.1 Analysis of user input



=head2 5.3.2 Operational concept



=head2 5.3.3 System requirements



=head2 5.4 System design.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for participating in system design. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.4.1 System-wide design decisions



=head2 5.4.2 System architectural design



=head2 5.5 Software requirements analysis.

This paragraph shall describe the
approach to be followed for software requirements analysis. The
approach shall cover all contractual clauses concerning this topic.

=head2 5.6 Software design.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for software design. The planning in each subparagraph shall cover
all contractual clauses regarding the identified topic.

=head2 5.6.1 CSCI-wide design decisions



=head2 5.6.2 CSCI architectural design



=head2 5.6.3 CSCI detailed design



=head2 5.7 Software implementation and unit testing.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for software implementation and unit testing. The planning in
each subparagraph shall cover all contractual clauses regarding
the identified topic.

=head2 5.7.1 Software implementation



=head2 5.7.2 Preparing for unit testing



=head2 5.7.3 Performing unit testing



=head2 5.7.4 Revision and retesting



=head2 5.7.5 Analyzing and recording unit test results



=head2 5.8 Unit integration and testing.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for unit integration and testing. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.8.1 Preparing for unit integration and testing



=head2 5.8.2 Performing unit integration and testing



=head2 5.8.3 Revision and retesting



=head2 5.8.4 Analyzing and recording unit integration
and test results



=head2 5.9 CSCI qualification testing.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for CSCI qualification testing. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.9.1 Independence in CSCI qualification testing



=head2 5.9.2 Testing on the target computer system



=head2 5.9.3 Preparing for CSCI qualification testing



=head2 5.9.4 Dry run of CSCI qualification testing



=head2 5.9.5 Performing CSCI qualification testing



=head2 5.9.6 Revision and retesting



=head2 5.9.7 Analyzing and recording CSCI qualification
test results



=head2 5.10 CSCI/HWCI integration and testing.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for participating in CSCI/HWCI integration and testing. The planning
in each subparagraph shall cover all contractual clauses regarding
the identified topic.

=head2 5.10.1 Preparing for CSCI/HWCI integration and
testing

=head2 5.10.2 Performing CSCI/HWCI integration and testing



=head2 5.10.3 Revision and retesting



=head2 5.10.4 Analyzing and recording CSCI/HWCI integration
and test results



=head2 5.11 System qualification testing.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for participating in system qualification testing. The planning
in each subparagraph shall cover all contractual clauses regarding
the identified topic.

=head2 5.11.1 Independence in system qualification testing



=head2 5.11.2 Testing on the target computer system



=head2 5.11.3 Preparing for system qualification testing



=head2 5.11.4 Dry run of system qualification testing



=head2 5.11.5 Performing system qualification testing



=head2 5.11.6 Revision and retesting



=head2 5.11.7 Analyzing and recording system qualification
test results

=head2 5.12 Preparing for software use.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for preparing for software use. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.12.1 Preparing the executable software



=head2 5.12.2 Preparing version descriptions for user
sites



=head2 5.12.3 Preparing user manuals



=head2 5.12.4 Installation at user sites



=head2 5.13 Preparing for software transition.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for preparing for software transition. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.13.1 Preparing the executable software



=head2 5.13.2 Preparing source files



=head2 5.13.3 Preparing version descriptions for the
support site



=head2 5.13.4 Preparing the 'as built' CSCI
design and other software support information



=head2 5.13.5 Updating the system design description



=head2 5.13.6 Preparing support manuals



=head2 5.13.7 Transition to the designated support site



=head2 5.14 Software configuration management.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for software configuration management. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.14.1 Configuration identification



=head2 5.14.2 Configuration control



=head2 5.14.3 Configuration status accounting



=head2 5.14.4 Configuration audits



=head2 5.14.5 Packaging, storage, handling, and delivery



=head2 5.15 Software product evaluation.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for software product evaluation. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.15.1 In-process and final software product
evaluations

=head2 5.15.2 Software product evaluation records, including
items to be recorded


=head2 5.15.3 Independence in software product evaluation


=head2 5.16 Software quality assurance.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for software quality assurance. The planning in each subparagraph
shall cover all contractual clauses regarding the identified topic.

=head2 5.16.1 Software quality assurance evaluations



=head2 5.16.2 Software quality assurance records, including
items to be recorded



=head2 5.16.3 Independence in software quality assurance



=head2 5.17 Corrective action.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for corrective action. The planning in each subparagraph shall
cover all contractual clauses regarding the identified topic.

=head2 5.17.1 Problem/change reports

Problem/change reports, including items
to be recorded (candidate items include project name, originator,
problem number, problem name, software element or document affected,
origination date, category and priority, description, analyst
assigned to the problem, date assigned, date completed, analysis
time, recommended solution, impacts, problem status, approval
of solution, follow-up actions, corrector, correction date, version
where corrected, correction time, description of solution implemented)

=head2 5.17.2 Corrective action system



=head2 5.18 Joint technical and management reviews.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for joint technical and management reviews. The planning in each
subparagraph shall cover all contractual clauses regarding the
identified topic.

=head2 5.18.1 

Joint technical reviews, including a proposed
set of reviews

=head2 5.18.2 

Joint management reviews, including a
proposed set of reviews


=head2 5.19 Other software development activities.

This paragraph shall be divided into
the following subparagraphs to describe the approach to be followed
for other software development activities. The planning in each
subparagraph shall cover all contractual clauses regarding the
identified topic.

=head2 5.19.1 

Risk management, including known risks
and corresponding strategies

=head2 5.19.2 

Software management indicators, including
indicators to be used

=head2 5.19.3 

Security and privacy

=head2 5.19.4 

Subcontractor management

=head2 5.19.5 

Interface with software independent verification
and validation (IV&amp;V) agents

=head2 5.19.6 

Coordination with associate developers

=head2 5.19.7 

Improvement of project processes

=head2 5.19.8 

Other activities not covered elsewhere
in the plan

=head1 6 Schedules and activity network.

This section shall present:

=over 4

=item 1

Schedule(s) identifying the activities in
each build and showing initiation of each activity, availability
of draft and final deliverables and other milestones, and completion
of each activity

=item 2

An activity network, depicting sequential
relationships and dependencies among activities and identifying
those activities that impose the greatest time restrictions on
the project

=back

=head1 7 Project organization and resources


This section shall be divided into
the following paragraphs to describe the project organization
and resources to be applied in each build.

=head2 7.1 

Project organization.
This paragraph shall describe the
organizational structure to be used on the project, including
the organizations involved, their relationships to one another,
and the authority and responsibility of each organization for
carrying out required activities.

=head2 7.2 

Project resources.
This paragraph shall describe the
resources to be applied to the project. It shall include, as applicable:

=over 4

=item 1

Personnel resources, including:

=over 4

=item *

The estimated staff-loading for the project
(number of personnel over time) 

=item *

The breakdown of the staff-loading numbers
by responsibility (for example, management, software engineering,
software testing, software configuration management, software
product evaluation, software quality assurance)

=item *

A breakdown of the skill levels, geographic
locations, and security clearances of personnel performing each
responsibility

=back

=item 2

Overview of developer facilities to be used,
including geographic locations in which the work will be performed,
facilities to be used, and secure areas and other features of
the facilities as applicable to the contracted effort.

=item 3

Acquirer-furnished equipment, software, services,
documentation, data, and facilities required for the contracted
effort. A schedule detailing when these items will be needed shall
also be included.

=item 4

Other required resources, including a plan
for obtaining the resources, dates needed, and availability of
each resource item.

=back

=head1 8 Notes.

This section shall contain any general
information that aids in understanding this document (e.g., background
information, glossary, rationale). This section shall include
an alphabetical listing of all acronyms, abbreviations, and their
meanings as used in this document and a list of any terms and
definitions needed to understand this document. 

=head1 A. Appendixes.

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
