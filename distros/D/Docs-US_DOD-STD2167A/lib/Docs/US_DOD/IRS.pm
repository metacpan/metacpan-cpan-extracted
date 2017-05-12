#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::IRS;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81434';
$TITLE = 'INTERFACE REQUIREMENTS SPECIFICATION (IRS)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION 

The following establishes the data general and content
requirements for the identified data item.

=head1 1. TITLE

INTERFACE REQUIREMENTS SPECIFICATION (IRS) 

=head1 2. IDENTIFICATION NUMBER 

DI-IPSC-81434 

=head1 3. DESCRIPTION/PURPOSE 

The Interface Requirements Specification (IRS) specifies
the requirements imposed on one or more systems, subsystems, Hardware
Configuration Items (L<HWCI>), Computer Software Configuration Items
(L<CSCI>), manual operations, or other system components to achieve
one or more interfaces among these entities. An IRS can cover
any number of interfaces. 

The IRS can be used to supplement the System/Subsystem Specification (L<SSS>)
(DI-IPSC-81431) and Software Requirements Specification (L<SRS>)
(DI-IPSC-81433) as the basis for design and qualification testing
of systems and CSCIs.

=head1 7. APPLICATION/INTERRELATIONSHIP 

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
define and record the interface requirements for one or more systems,
subsystem, HWCIs, CSCIs, manual operations, or other system components.

The IRS can be used to supplement the SSS and the SRS. 

The Contract Data Requirements List (L<CDRL>) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-MCCR-80026A and DI-MCCR-80303.

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

=head1 1. Scope.

This section shall be divided into
the following paragraphs.

=head2 1.1 Identification.

This paragraph shall contain a full
identification of the systems, the interfacing entities, and the
interfaces to which this document applies, including, as applicable,
identification number(s), title(s), abbreviation(s), version number(s),
and release number(s). 

=head2 1.2 System overview.

This paragraph shall briefly state
the purpose of the system(s) and software to which this document
applies. It shall describe the general nature of the system and
software; summarize the history of system development, operation,
and maintenance; identify the project sponsor, acquirer, user,
developer, and support agencies; identify current and planned
operating sites; and list other relevant documents. 

=head2 1.3 Document overview.

This paragraph shall summarize the
purpose and contents of this document and shall describe any security
or privacy considerations associated with its use. 

=head1 2. Referenced documents.

This section shall list the number, title, revision, and date
of all documents referenced in this specification. This section
shall also identify the source for all documents not available
through normal Government stocking activities. 

=head1 3. Requirements.

This section shall be divided into
the following paragraphs to specify the requirements imposed on
one or more systems, subsystems, configuration items, manual operations,
or other system components to achieve one or more interfaces among
these entities. Each requirement shall be assigned a project-unique
identifier to support testing and traceability and shall be stated
in such a way that an objective test can be defined for it. Each
requirement shall be annotated with associated qualification method(s)
(see section 4) and traceability to system (or subsystem, if applicable)
requirements (see section 5.a) if not provided in those sections.
The degree of detail to be provided shall be guided by the following
rule: Include those characteristics of the interfacing entities
that are conditions for their acceptance; defer to design descriptions
those characteristics that the acquirer is willing to leave up
to the developer. If a given requirement fits into more than one
paragraph, it may be stated once and referenced from the other
paragraphs. If an interfacing entity included in this specification
will operate in states and/or modes having interface requirements
different from other states and modes, each requirement or group
of requirements for that entity shall be correlated to the states
and modes. The correlation may be indicated by a table or other
method in this paragraph, in an appendix referenced from this
paragraph, or by annotation of the requirements in the paragraphs
where they appear.

=head2 3.1 Interface identification and diagrams.

For each interface identified in 1.1,
this paragraph shall include a project-unique identifier and shall
designate the interfacing entities (systems, configuration items,
users, etc.) by name, number, version, and documentation references,
as applicable. The identification shall state which entities have
fixed interface characteristics (and therefore impose interface
requirements on interfacing entities) and which are being developed
or modified (thus having interface requirements imposed on them).
One or more interface diagrams shall be provided to depict the
interfaces.

=head2 3.x (Project-unique identifier of interface).

This paragraph (beginning with 3.2)
shall identify an interface by project-unique identifier, shall
briefly identify the interfacing entities, and shall be divided
into subparagraphs as needed to state the requirements imposed
on one or more of the interfacing entities to achieve the interface.
If the interface characteristics of an entity are not covered
by this IRS but need to be mentioned to specify the requirements
for entities that are, those characteristics shall be stated as
assumptions or as 'When [the entity not covered] does this,
the [entity being specified] shall...,' rather than as requirements
on the entities not covered by this IRS. This paragraph may reference
other documents (such as data dictionaries, standards for communication
protocols, and standards for user interfaces) in place of stating
the information here. The requirements shall include the following,
as applicable, presented in any order suited to the requirements,
and shall note any differences in these characteristics from the
point of view of the interfacing entities (such as different expectations
about the size, frequency, or other characteristics of data elements):

=head2 3.x.1

Priority that the interfacing entity(ies)
must assign the interface

=head2 3.x.2

Requirements on the type of interface (such
as real-time data transfer, storage-and-retrieval of data, etc.)
to be implemented

=head2 3.x.3

Required characteristics of individual data
elements that the interfacing entity(ies) must provide, store,
send, access, receive, etc., such as: 

=over 4

=item 1 Names/identifiers

=over 4

=item *

Project-unique identifier

=item *

Non-technical (natural-language) name

=item *

DoD standard data element name

=item *

Technical name (e.g., variable or field name
in code or database)

=item *

Abbreviation or synonymous names

=back

=item 2

Data type (alphanumeric, integer, etc.)

=item 3

Size and format (such as length and punctuation
of a character string)

=item 4

 Units of measurement (such as meters, dollars,
nanoseconds)

=item 5

Range or enumeration of possible values (such
as 0-99)

=item 6

Accuracy (how correct) and precision (number
of significant digits)

=item 7

Priority, timing, frequency, volume, sequencing,
and other constraints, such as whether the data element may be
updated and whether business rules apply

=item 8

Security and privacy constraints

=back

Sources (setting/sending entities) and recipients
(using/receiving entities) 

=head2 3.x.4

Required characteristics of data element assemblies
(records, messages, files, arrays, displays, reports, etc.) that
the interfacing entity(ies) must provide, store, send, access,
receive, etc., such as:

=over 

=item 1

Project-unique identifier
=item *

Non-technical (natural language) name

=item 2

Technical name (e.g., record or data structure
name in code or database)

=item 3

Abbreviations or synonymous names

=item 4

Names/identifiers

=item 5

Data elements in the assembly and their structure
(number, order, grouping)

=item 6

Medium (such as disk) and structure of data
elements/assemblies on the media

=item 7

Visual and auditory characteristics of displays
and other outputs (such as colors, layouts, fonts, icons and other
display elements, beeps, lights)

=item 8

Relationships among assemblies, such as sorting/access
characteristics

=item 9

Priority, timing, frequency, volume, sequencing,
and other constraints, such as whether the assembly may be updated
and whether business rules apply

=item 10

Security and privacy constraints

=item 11

Sources (setting/sending entities) and recipients
(using/receiving entities) 

=back


=head2 3.x.5

Required characteristics of communication
methods that the interfacing entity(ies) must use for the interface,
such as:

=over 4

=item 1

Project-unique identifier(s)

=item 2

Communication links/bands/frequencies/media
and their characteristics

=item 3

Message formatting

=item 4

Flow control (such as sequence numbering and
buffer allocation)

=item 5

Data transfer rate, whether periodic/aperiodic,
and interval between transfers 

=item 6

Routing, addressing, and naming conventions

=item 7

Transmission services, including priority
and grade

=item 8

Safety/security/privacy considerations, such
as encryption, user authentication, compartmentalization, and
auditing

=back

=head2 3.x.6

Required characteristics of protocols the
interfacing entity(ies) must use for the interface, such as:

=over 4

=item 1

Project-unique identifier(s) 

=item 2

Priority/layer of the protocol

=item 3

Packeting, including fragmentation and reassembly,
routing, and addressing

=item 4

Legality checks, error control, and recovery
procedures

=item 5

Synchronization, including connection establishment,
maintenance, termination 

=item 6

Status, identification, and any other reporting
features

=back

=head2 3.x.7

Other required characteristics, such as physical
compatibility of the interfacing entities (dimensions, tolerances,
loads, plug compatibility, etc.), voltages, etc.

=head2 3.y Precedence and criticality of requirements.

This paragraph shall be numbered as
the last paragraph in Section 3 and shall specify, if applicable,
the order of precedence, criticality, or assigned weights indicating
the relative importance of the requirements in this specification.
Examples include identifying those requirements deemed critical
to safety, to security, or to privacy for purposes of singling
them out for special treatment. If all requirements have equal
weight, this paragraph shall so state. 

=head1 4. Qualification provisions.

This section shall define a set of
qualification methods and shall specify, for each requirement
in Section 3, the qualification method(s) to be used to ensure
that the requirement has been met. A table may be used to present
this information, or each requirement in Section 3 may be annotated
with the method(s) to be used. Qualification methods may include:

=over 4

=item 1

Demonstration: The operation of interfacing
entities that relies on observable functional operation not requiring
the use of instrumentation, special test equipment, or subsequent
analysis.

=item 2

Test: The operation of interfacing entities
using instrumentation or special test equipment to collect data
for later analysis.

=item 3

Analysis: The processing of accumulated data
obtained from other qualification methods. Examples are reduction,
interpretation, or extrapolation of test results. 

=item 4

Inspection: The visual examination of interfacing
entities, documentation, etc. 

=item 5

Special qualification methods: Any special
qualification methods for the interfacing entities, such as special
tools, techniques, procedures, facilities, and acceptance limits.

=back


=head1 5. Requirements traceability.

For system-level interfacing entities,
this paragraph does not apply. For each subsystem- or lower-level
interfacing entity covered by this IRS, this paragraph shall contain:

=over 4

=item 1

Traceability from each requirement imposed
on the entity in this specification to the system (or subsystem,
if applicable) requirements it addresses. (Alternatively, this
traceability may be provided by annotating each requirement in
Section 3.) 
Note: Each level of system refinement may result in requirements
not directly traceable to higher-level requirements. For example,
a system architectural design that creates multiple CSCIs may
result in requirements about how the CSCIs will interface, even
though these interfaces are not covered in system requirements.
Such requirements may be traced to a general requirement such
as 'system implementation' or to the system design decisions
that resulted in their generation. 

=item 2

Traceability from each system (or subsystem,
if applicable) requirement that has been allocated to the interfacing
entity and that affects an interface covered in this specification
to the requirements in this specification that address it.

=back

=head1 6. Notes.

This section shall contain any general
information that aids in understanding this document (e.g., background
information, glossary, rationale). This section shall include
an alphabetical listing of all acronyms, abbreviations, and their
meanings as used in this document and a list of any terms and
definitions needed to understand this document. 

=head1 A. Appendixes. 

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
