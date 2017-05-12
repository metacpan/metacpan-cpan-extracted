#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::SDD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$VERSION = '1.07';
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81435';
$TITLE = 'SOFTWARE DESIGN DESCRIPTION (SDD)';
$REVISION = '-';
$DATE = '2003/06/10';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. TITLE

SOFTWARE DESIGN DESCRIPTION (SDD)

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81435

=head1 3. DESCRIPTION/PURPOSE

The Software Design Description (SDD) describes the
design of a Computer Software Configuration Item (CSCI). It describes
the CSCI-wide design decisions, the CSCI architectural design,
and the detailed design needed to implement the software. The
SDD may be supplemented by Interface Design Descriptions
(IDDs) (DI-IPSC-81436) and Database Design Descriptions (DBDDs)
(DI-IPSC-81437)

The SDD, with its associated IDDs and DBDDs, is used
as the basis for implementing the software. It provides the acquirer
visibility into the design and provides information needed for
software support.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
define and record the design of a CSCI.

Design pertaining to interfaces may be presented
in the SDD or in IDDs. Design pertaining to databases may be presented
in the SDD or in DBDDs.

The Contract Data Requirements List (L<CDRL>) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document.

This DID supersedes DI-MCCR-80012A, DI-IPSC-80691,
DI-MCCR-80304, and DI-MCCR-80306.

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

=head1 2 Referenced documents.

This section shall list the number, title, revision, and date
of all documents referenced in this document. This section shall
also identify the source for all documents not available through
normal Government stocking activities.

=head1 3 CSCI-wide design decisions.

This section shall be divided into paragraphs as needed
to present CSCI-wide design decisions, that is, decisions about
the CSCI's behavioral design (how it will behave, from a user's
point of view, in meeting its requirements, ignoring internal
implementation) and other decisions affecting the selection and
design of the software units that make up the CSCI. If all such
decisions are explicit in the CSCI requirements or are deferred
to the design of the CSCI's software units, this section shall
so state. Design decisions that respond to requirements designated
critical, such as those for safety, security, or privacy, shall
be placed in separate subparagraphs. If a design decision depends
upon system states or modes, this dependency shall be indicated.
Design conventions needed to understand the design shall be presented
or referenced. Examples of CSCI-wide design decisions are the
following:

=over 4

=item 1

Design decisions regarding inputs the CSCI will accept
and outputs it will produce, including interfaces with other systems,
HWCIs, CSCIs, and users (4.3.x of this DID identifies topics to
be considered in this description). If part or all of this information
is given in Interface Design Descriptions (IDDs), they may be
referenced.

=item 2

Design decisions on CSCI behavior in response to each input
or condition, including actions the CSCI will perform, response
times and other performance characteristics, description of physical
systems modeled, selected equations/algorithms/rules, and handling
of unallowed inputs or conditions.

=item 3

Design decisions on how databases/data files will appear
to the user (4.3.x of this DID identifies topics to be considered
in this description). If part or all of this information is given
in Database Design Descriptions (DBDDs), they may be referenced.

=item 4

Selected approach to meeting safety, security, and privacy
requirements.

=item 5

Other CSCI-wide design decisions made in response to requirements,
such as selected approach to providing required flexibility, availability,
and maintainability.

=back

=head1 4 CSCI architectural design.

This section shall be divided into the following paragraphs
to describe the CSCI architectural design. If part or all of the
design depends upon system states or modes, this dependency shall
be indicated. If design information falls into more than one paragraph,
it may be presented once and referenced from the other paragraphs.
Design conventions needed to understand the design shall be presented
or referenced.

=head2 4.1 CSCI components.

This paragraph shall:

=head2 4.1.1

Identify the software units that make up the CSCI. Each
software unit shall be assigned a project-unique identifier. 

Note: A software unit is an element in the design of a CSCI;
for example, a major subdivision of a CSCI, a component of that
subdivision, a class, object, module, function, routine, or database.
Software units may occur at different levels of a hierarchy and
may consist of other software units. Software units in the design
may or may not have a one-to-one relationship with the code and
data entities (routines, procedures, databases, data files, etc.)
that implement them or with the computer files containing those
entities. A database may be treated as a CSCI or as a software
unit. The SDD may refer to software units by any name(s) consistent
with the design methodology being used.

=head2 4.1.2

Show the static (such as 'consists of') relationship(s)
of the software units. Multiple relationships may be presented,
depending on the selected software design methodology (for example,
in an object-oriented design, this paragraph may present the class
and object structures as well as the module and process architectures
of the CSCI).

=head2 4.1.3

State the purpose of each software unit and identify the
CSCI requirements and CSCI-wide design decisions allocated to
it. (Alternatively, the allocation of requirements may be provided
in 6.a.)

=head2 4.1.4

Identify each software unit's development status/type (such
as new development, existing design or software to be reused as
is, existing design or software to be reengineered, software to
be developed for reuse, software planned for Build N, etc.) For
existing design or software, the description shall provide identifying
information, such as name, version, documentation references,
library, etc.

=head2 4.1.5

Describe the CSCI's (and as applicable, each software unit's)
planned utilization of computer hardware resources (such as processor
capacity, memory capacity, input/output device capacity, auxiliary
storage capacity, and communications/network equipment capacity).
The description shall cover all computer hardware resources included
in resource utilization requirements for the CSCI, in system-level
resource allocations affecting the CSCI, and in resource utilization
measurement planning in the Software Development Plan. If all
utilization data for a given computer hardware resource are presented
in a single location, such as in one SDD, this paragraph may reference
that source. Included for each computer hardware resource shall
be:

=over 4

=item 1

The CSCI requirements or system-level resource allocations
being satisfied

=item 2

The assumptions and conditions on which the utilization
data are based (for example, typical usage, worst-case usage,
assumption of certain events)

=item 3

Any special considerations affecting the utilization (such
as use of virtual memory, overlays, or multiprocessors or the
impacts of operating system overhead, library software, or other
implementation overhead)

=item 4

The units of measure used (such as percentage of processor
capacity, cycles per second, bytes of memory, kilobytes per second)

=item 5

The level(s) at which the estimates or measures will be
made (such as software unit, CSCI, or executable program)

=back

=head2 4.1.6

Identify the program library in which the software that
implements each software unit is to be placed

=head2 4.2 Concept of execution.

This paragraph shall describe the concept of execution among
the software units. It shall include diagrams and descriptions
showing the dynamic relationship of the software units, that is,
how they will interact during CSCI operation, including, as applicable,
flow of execution control, data flow, dynamically controlled sequencing,
state transition diagrams, timing diagrams, priorities among units,
handling of interrupts, timing/sequencing relationships, exception
handling, concurrent execution, dynamic allocation/deallocation,
dynamic creation/deletion of objects, processes, tasks, and other
aspects of dynamic behavior.

=head2 4.3 Interface design.

This paragraph shall be divided into the following subparagraphs
to describe the interface characteristics of the software units.
It shall include both interfaces among the software units and
their interfaces with external entities such as systems, configuration
items, and users. If part or all of this information is contained
in Interface Design Descriptions (IDDs), in section 5 of the SDD,
or elsewhere, these sources may be referenced.

=head2 4.3.1 Interface identification and diagrams.

This paragraph shall state the project-unique identifier
assigned to each interface and shall identify the interfacing
entities (software units, systems, configuration items, users,
etc.) by name, number, version, and documentation references,
as applicable. The identification shall state which entities have
fixed interface characteristics (and therefore impose interface
requirements on interfacing entities) and which are being developed
or modified (thus having interface requirements imposed on them).
One or more interface diagrams shall be provided, as appropriate,
to depict the interfaces.

=head2 4.3.x (Project-unique identifier of interface).

This paragraph (beginning with 4.3.2) shall identify an
interface by project-unique identifier, shall briefly identify
the interfacing entities, and shall be divided into subparagraphs
as needed to describe the interface characteristics of one or
both of the interfacing entities. If a given interfacing entity
is not covered by this SDD (for example, an external system) but
its interface characteristics need to be mentioned to describe
interfacing entities that are, these characteristics shall be
stated as assumptions or as 'When [the entity not covered]
does this, [the entity that is covered] will ....' This paragraph
may reference other documents (such as data dictionaries, standards
for protocols, and standards for user interfaces) in place of
stating the information here. The design description shall include
the following, as applicable, presented in any order suited to
the information to be provided, and shall note any differences
in these characteristics from the point of view of the interfacing
entities (such as different expectations about the size, frequency,
or other characteristics of data elements):

=head2 4.3.x.1

Priority assigned to the interface by the interfacing entity(ies)

=head2 4.3.x.2

Type of interface (such as real-time data transfer, storage-and-retrieval
of data, etc.) to be implemented

=head2 4.3.x.3

Characteristics of individual data elements that the interfacing
entity(ies) will provide, store, send, access, receive, etc.,
such as:

=over 4

=item 1

Names/identifiers

=over 4

=item *


Project-unique identifier

=item *

Non-technical (natural-language) name

=item *

DoD standard data element name

=item *




Technical name (e.g., variable or field name in code or
database)

=item *

Abbreviation or synonymous names

=back

=item 2

Data type (alphanumeric, integer, etc.)

=item 3

Size and format (such as length and punctuation of a character
string)

=item 4

Units of measurement (such as meters, dollars, nanoseconds)

=item 5

Range or enumeration of possible values (such as 0-99)

=item 6

Accuracy (how correct) and precision (number of significant
digits)

=item 7

Priority, timing, frequency, volume, sequencing, and other
constraints, such as whether the data element may be updated and
whether business rules apply

=item 8

Security and privacy constraints

=item 9

Sources (setting/sending entities) and recipients (using/receiving
entities)

=back

=head2 4.3.x.4

Characteristics of data element assemblies (records, messages,
files, arrays, displays, reports, etc.) that the interfacing entity(ies)
will provide, store, send, access, receive, etc., such as:

=over 4

=item 1

Names/identifiers

=over 4

=item *

Project-unique identifier

=item *

Non-technical (natural language) name

=item *

Technical name (e.g., record or data structure name in
code or database)

=item *

Abbreviations or synonymous names

=back

=item 2

Data elements in the assembly and their structure (number,
order, grouping)

=item 4

Medium (such as disk) and structure of data elements/assemblies
on the medium

=item 5

Visual and auditory characteristics of displays and other
outputs (such as colors, layouts, fonts, icons and other display
elements, beeps, lights)

=item 6

Relationships among assemblies, such as sorting/access
characteristics

=item 7

Priority, timing, frequency, volume, sequencing, and other
constraints, such as whether the assembly may be updated and whether
business rules apply

=item 8

Security and privacy constraints

=item 9

Sources (setting/sending entities) and recipients (using/receiving
entities)

=back

=head2 4.3.x.5

Characteristics of communication methods that the interfacing
entity(ies) will use for the interface, such as:

=over 4

=item 1

Project-unique identifier(s)

=item 2

Communication links/bands/frequencies/media and their characteristics

=item 3

Message formatting

=item 4

Flow control (such as sequence numbering and buffer allocation)

=item 5

Data transfer rate, whether periodic/aperiodic, and interval
between transfers

=item 6

Routing, addressing, and naming conventions

=item 7

Transmission services, including priority and grade

=item 8

Safety/security/privacy considerations, such as encryption,
user authentication, compartmentalization, and auditing

=back

=head2 4.3.x.6

Characteristics of protocols that the interfacing entity(ies)
will use for the interface, such as:

=over 4

=item 1

Project-unique identifier(s)

=item 2

Priority/layer of the protocol

=item 3

Packeting, including fragmentation and reassembly, routing,
and addressing

=item 4

Legality checks, error control, and recovery procedures

=item 5

Synchronization, including connection establishment, maintenance,
termination

=item 6

Status, identification, and any other reporting features

=back

=head2 4.3.x.7

Other characteristics, such as physical compatibility of
the interfacing entity(ies) (dimensions, tolerances, loads, voltages,
plug compatibility, etc.)

=head1 5 CSCI detailed design.

This section shall be divided into the following paragraphs
to describe each software unit of the CSCI. If part of all of
the design depends upon system states or modes, this dependency
shall be indicated. If design information falls into more than
one paragraph, it may be presented once and referenced from the
other paragraphs. Design conventions needed to understand the
design shall be presented or referenced. Interface characteristics
of software units may be described here, in Section 4, or in Interface
Design Descriptions (IDDs). Software units that are databases,
or that are used to access or manipulate databases, may be described
here or in Database Design Descriptions (DBDDs).

=head2 5.x (Project-unique identifier of a software unit, or designator
of a group of software units).

This paragraph shall identify a software unit by project-unique
identifier and shall describe the unit. The description shall
include the following information, as applicable. Alternatively,
this paragraph may designate a group of software units and identify
and describe the software units in subparagraphs. Software units
that contain other software units may reference the descriptions
of those units rather than repeating information.

=head2 5.x.1

Unit design decisions, if any, such as algorithms to be
used, if not previously selected

=head2 5.x.2

Any constraints, limitations, or unusual features in the
design of the software unit

=head2 5.x.3

The programming language to be used and rationale for its
use if other than the specified CSCI language

=head2 5.x.4

If the software unit consists of or contains procedural
commands (such as menu selections in a database management system
(DBMS) for defining forms and reports, on-line DBMS queries for
database access and manipulation, input to a graphical user interface
(GUI) builder for automated code generation, commands to the operating
system, or shell scripts), a list of the procedural commands and
reference to user manuals or other documents that explain them

=head2 5.x.5

If the software unit contains, receives, or outputs data,
a description of its inputs, outputs, and other data elements
and data element assemblies, as applicable. Paragraph 4.3.x of
this DID provides a list of topics to be covered, as applicable.
Data local to the software unit shall be described separately
from data input to or output from the software unit. If the software
unit is a database, a corresponding Database Design Description
(DBDD) shall be referenced; interface characteristics may be provided
here or by referencing section 4 or the corresponding Interface
Design Description(s).

=head2 5.x.6

If the software unit contains logic, the logic to be used
by the software unit, including, as applicable:

=over 4

=item 1

Conditions in effect within the software unit when its
execution is initiated

=item 2

Conditions under which control is passed to other software
units

=item 3

Response and response time to each input, including data
conversion, renaming, and data transfer operations

=item 4

Sequence of operations and dynamically controlled sequencing
during the software unit's operation, including:

=over 4

=item *

The method for sequence control

=item *

The logic and input conditions of that method, such as
timing variations, priority assignments c) Data transfer in and
out of memory

=item *

The sensing of discrete input signals, and timing relationships
between interrupt operations within the software unit

=back

=item 5

Exception and error handling

=back

=head1 6 Requirements traceability.

This section shall contain:

=over 4

=item 1

Traceability from each software unit identified in this
SDD to the CSCI requirements allocated to it. (Alternatively,
this traceability may be provided in 4.1.)

=item 2

Traceability from each CSCI requirement to the software
units to which it is allocated.

=back

=head1 7 Notes.

This section shall contain any general information that
aids in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of any terms and definitions
needed to understand this document. 

=head1 A. Appendixes. 

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
