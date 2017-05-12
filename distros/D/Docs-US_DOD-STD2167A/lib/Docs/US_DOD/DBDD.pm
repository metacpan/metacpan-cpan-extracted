#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::DBDD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$VERSION = '1.07';
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81437';
$TITLE = 'DATABASE DESIGN DESCRIPTION (DBDD)';
$REVISION = '-';
$DATE = '2003/06/10';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 1.TITLE

DATABASE DESIGN DESCRIPTION (DBDD) 

=head1 2. IDENTIFICATION NUMBER

 DI-IPSC-81437 

=head1 3. DESCRIPTION/PURPOSE

The Database Design Description (DBDD) describes
the design of a database, that is, a collection of related data
stored in one or more computerized files in a manner that can
be accessed by users or computer programs via a database management
system (DBMS). It can also describe the software units used to
access or manipulate the data. 

The DBDD is used as the basis for implementing the
database and related software units. It provides the acquirer
visibility into the design and provides information needed for
software support.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
define and record the design of one or more databases. 

Software units that access or manipulate the database
may be described here or in Software Design Descriptions (SDDs)
(DI-IPSC-81435). Interfaces may be described here or in Interface Design Descriptions
(IDDs) (DI-IPSC-81436). 

The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-IPSC-80692 and DI-MCCR-80305.

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
database to which this document applies, including, as applicable,
identification number(s), title(s), abbreviation(s), version number(s),
and release number(s). 

=head2 1.2 Database overview.

This paragraph shall briefly state the purpose of the database
to which this document applies. It shall describe the general
nature of the database; summarize the history of its development,
use, and maintenance; identify the project sponsor, acquirer,
user, developer, and support agencies; identify current and planned
operating sites; and list other relevant documents. 

=head2 1.3 Document overview.

This paragraph shall summarize the purpose and contents
of this document and shall describe any security or privacy considerations
associated with its use. 

=head1 2. 

Referenced documents.

This section shall list the number, title, revision, and
date of all documents referenced in this manual. This section
shall also identify the source for all documents not available
through normal Government stocking activities. 

=head1 3. Database-wide design decisions.

This section shall be divided into paragraphs as needed
to present database-wide design decisions, that is, decisions
about the database's behavioral design (how it will behave, from
a user's point of view, in meeting its requirements, ignoring
internal implementation) and other decisions affecting further
design of the database. If all such decisions are explicit in
the system or CSCI requirements, this section shall so state.
Design decisions that respond to requirements designated critical,
such as those for safety, security, or privacy, shall be placed
in separate subparagraphs. If a design decision depends upon system
states or modes, this dependency shall be indicated. If some or
all of the design decisions are described in the documentation
of a custom or commercial database management system (DBMS), they
may be referenced from this section. Design conventions needed
to understand the design shall be presented or referenced. Examples
of database-wide design decisions are the following: 

=over 4

=item 1

Design decisions regarding queries or other inputs the
database will accept and outputs (displays, reports, messages,
responses, etc.) it will produce, including interfaces with other
systems, HWCIs, CSCIs, and users (5.x.d of this DID identifies
topics to be considered in this description). If part or all of
this information is given in Interface Design Descriptions (IDDs),
they may be referenced.

=item 2

Design decisions on database behavior in response to each
input or query, including actions, response times and other performance
characteristics, selected equations/algorithms/rules, disposition,
and handling of unallowed inputs

=item 3

Design decisions on how databases/data files will appear
to the user (4.x of this DID identifies topics to be considered
in this description)

=item 4

Design decisions on the database management system to be
used (including name, version/release) and the type of flexibility
to be built into the database for adapting to changing requirements

=item 5

Design decisions on the levels and types of availability,
security, privacy, and continuity of operations to be offered
by the database

=item 6

Design decisions on database distribution (such as client/server),
master database file updates and maintenance, including maintaining
consistency, establishing/ reestablishing and maintaining synchronization,
enforcing integrity and business rules

=item 7

Design decisions on backup and restoration including data
and process distribution strategies, permissible actions during
backup and restoration, and special considerations for new or
non-standard technologies such as video and sound

=item 8

Design decisions on repacking, sorting, indexing, synchronization,
and consistency including automated disk management and space
reclamation considerations, optimizing strategies and considerations,
storage and size considerations, and population of the database
and capture of legacy data.

=back

=head1 4 Detailed design of the database.

This section shall be divided into paragraphs as needed
to describe the detailed design of the database. The number of
levels of design and the names of those levels shall be based
on the design methodology used. Examples of database design levels
include conceptual, internal, logical, and physical. If part or
all of the design depends upon system states or modes, this dependency
shall be indicated. Design conventions needed to understand the
design shall be presented or referenced. 
Note: This DID uses the term 'data element assembly'
to mean any entity, relation, schema, field, table, array, etc.,
that has structure (number/order/grouping of data elements) at
a given design level (e.g., conceptual, internal, logical, physical)
and the term 'data element' to mean any relation, attribute,
field, cell, data element, etc. that does not have structure at
that level. 

=head2 4.x (Name of database design level)

This paragraph shall identify a database design level and
shall describe the data elements and data element assemblies of
the database in the terminology of the selected design method.
The information shall include the following, as applicable, presented
in any order suited to the information to be provided:

=over 4

=item 1

Characteristics of individual data elements in the database
design, such as:

=over 4

=item *

Names/identifiers

=over 4

=item *

Project-unique identifier

=item *

Non-technical (natural-language) name

=item *

DoD standard data element name

=item *

Technical name (e.g., field name in the database)

=item *

Abbreviation or synonymous names

=back

=item *

Data type (alphanumeric, integer, etc.)

=item *

Size and format (such as length and punctuation of a character
string)

=item *

Units of measurement (such as meters, dollars, nanoseconds)

=item *

Range or enumeration of possible values (such as 0-99)

=item *

Accuracy (how correct) and precision (number of significant
digits)

=item *

Priority, timing, frequency, volume, sequencing, and other
constraints, such as whether the data element may be updated and
whether business rules apply

=item *

Security and privacy constraints

=item *

Sources (setting/sending entities) and recipients (using/receiving
entities) 

=back


=item 2

Characteristics of data element assemblies (records, messages,
files, arrays, displays, reports, etc.) in the database design,
such as:

=over 4

=item *

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

=item *

Data elements in the assembly and their structure (number,
order, grouping)

=item *

Medium (such as disk) and structure of data elements/assemblies
on the medium

=item *

Visual and auditory characteristics of displays and other
outputs (such as colors, layouts, fonts, icons and other display
elements, beeps, lights)

=item *

Relationships among assemblies, such as sorting/access
characteristics

=item *

Priority, timing, frequency, volume, sequencing, and other
constraints, such as whether the assembly may be updated and whether
business rules apply

=item *

Security and privacy constraints

=item *

Sources (setting/sending entities) and recipients (using/receiving
entities)

=back

=back


=head1 5 Detailed design of software units used for database access
or manipulation.

This section shall be divided into the following paragraphs
to describe each software unit used for database access or manipulation.
If part or all of this information is provided elsewhere, such
as in a Software Design Description (SDD), the SDD for a customized
DBMS, or the user manual of a commercial DBMS, that information
may be referenced rather than repeated here. If part or all of
the design depends upon system states or modes, this dependency
shall be indicated. If design information falls into more than
one paragraph, it may be presented once and referenced from the
other paragraphs. Design conventions needed to understand the
design shall be presented or referenced. 

=head2 5.x (Project-unique identifier of a software unit, or designator
for a group of software units).

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
a reference to user manuals or other documents that explain them

=head2 5.x.5

If the software unit contains, receives, or outputs data,
a description of its inputs, outputs, and other data elements
and data element assemblies, as applicable. Data local to the
software unit shall be described separately from data input to
or output from the software unit. Interface characteristics may
be provided here or by referencing Interface Design Description(s).
If a given interfacing entity is not covered by this DBDD (for
example, an external system) but its interface characteristics
need to be mentioned to describe software units that are, these
characteristics shall be stated as assumptions or as 'When
[the entity not covered] does this, [the software unit] will....'
This paragraph may reference other documents (such as data dictionaries,
standards for protocols, and standards for user interfaces) in
place of stating the information here. The design description
shall include the following, as applicable, presented in any order
suited to the information to be provided, and shall note any differences
in these characteristics from the point of view of the interfacing
entities (such as different expectations about the size, frequency,
or other characteristics of data elements):

=over 4

=item 1

Project-unique identifier for the interface

=item 2

Identification of the interfacing entities (software units,
configuration items, users, etc.) by name, number, version, and
documentation references, as applicable

=item 3

Priority assigned to the interface by the interfacing entity(ies)

=item 4

Type of interface (such as real-time data transfer, storage-and-retrieval
of data, etc.) to be implemented

=item 5

Characteristics of individual data elements that the interfacing
entity(ies) will provide, store, send, access, receive, etc. Paragraph
4.x.a of this DID identifies topics to be covered in this description.

=item 6

Characteristics of data element assemblies (records, messages,
files, arrays, displays, reports, etc.) that the interfacing entity(ies)
will provide, store, send, access, receive, etc. Paragraph 4.x.b
of this DID identifies topics to be covered in this description.

=item 7

Characteristics of communication methods that the interfacing
entity(ies) will use for the interface, such as:

=over 4

=item *

Project-unique identifier(s)

=item *

Communication links/bands/frequencies/media and their characteristics

=item *

Message formatting

=item *

Flow control (such as sequence numbering and buffer allocation)

=item *

Data transfer rate, whether periodic/aperiodic, and interval
between transfers

=item *

Routing, addressing, and naming conventions

=item *

Transmission services, including priority and grade

=item *

Safety/security/privacy considerations, such as encryption,
user authentication, compartmentalization, and auditing

=back

=item 8

Characteristics of protocols that the interfacing entity(ies)
will use for the interface, such as:

=over 4

=item *















Project-unique identifier(s)

=item *

Priority/layer of the protocol

=item *

Packeting, including fragmentation and reassembly, routing,
and addressing

=item *

Legality checks, error control, and recovery procedures

=item *

Synchronization, including connection establishment, maintenance,
termination

=item *

Status, identification, and any other reporting features

=item *

Other characteristics, such as physical compatibility of
the interfacing entity(ies) (dimensions, tolerances, loads, voltages,
plug compatibility, etc.)

=back

=back

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
timing variations, priority assignments

=item *

Data transfer in and out of memory

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

Traceability from each database or other software unit
covered by this DBDD to the system or CSCI requirements it addresses.
=item 2

Traceability from each system or CSCI requirement that
has been allocated to a database or other software unit covered
in this DBDD to the database or other software units that address
it.

=back

=head1 7 Notes.

This section shall contain any general information that
aids in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of any terms and definitions
needed to understand this document. 

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
