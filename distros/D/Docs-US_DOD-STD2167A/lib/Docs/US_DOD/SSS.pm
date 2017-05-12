#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package Docs::US_DOD::SSS;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81431';
$TITLE = 'SYSTEM/SUBSYSTEM SPECIFICATION (SSS)';
$REVISION = '-';
$REVISION_DATE = '';

1


__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. SYSTEM/SUBSYSTEM SPECIFICATION (SSS)

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81431

=head1 3. DESCRIPTION/PURPOSE

The System/Subsystem Specification (SSS) specifies
the requirements for a system or subsystem and the methods to
be used to ensure that each requirement has been met. Requirements
pertaining to the system or subsystem's external interfaces may
be presented in the SSS or in one or more Interface Requirements Specifications
(IRSs) (DI-IPSC-81434) referenced from the SSS.

The SSS, possibly supplemented by IRSs, is used as
the basis for design and qualification testing of a system or
subsystem. Throughout this DID, the term 'system' may
be interpreted to mean 'subsystem' as applicable. The
resulting document should be titled System Specification or Subsystem
Specification (SSS).

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
define and record the requirements to be met by a system or subsystem.

Requirements pertaining to system or subsystem interfaces
may be presented in the SSS or in IRSs.

The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document.

This DID supersedes DI-CMAN-80008A and DI-IPSC-80690.

APPROVAL LIMITATION Limited Approval as specified
in the CDRL.

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
identification of the system to which this document applies, including,
as applicable, identification number(s), title(s), abbreviation(s),
version number(s), and release number(s).

=head2 1.2 System overview.

This paragraph shall briefly state
the purpose of the system to which this document applies. It shall
describe the general nature of the system; summarize the history
of system development, operation, and maintenance; identify the
project sponsor, acquirer, user, developer, and support agencies;
identify current and planned operating sites; and list other relevant
documents.

=head2 1.3 Document overview.

This paragraph shall summarize the
purpose and contents of this document and shall describe any security
or privacy considerations associated with its use.

=head1 2 Referenced documents.

This section shall list the number,
title, revision, and date of all documents referenced in this
specification. This section shall also identify the source for
all documents not available through normal Government stocking
activities.

=head1 3 Requirements.

This section shall be divided into
the following paragraphs to specify the system requirements, that
is, those characteristics of the system that are conditions for
its acceptance. Each requirement shall be assigned a project-unique
identifier to support testing and traceability and shall be stated
in such a way that an objective test can be defined for it. Each
requirement shall be annotated with associated qualification method(s)
(see section 4) and, for subsystems, traceability to system requirements
(see section 5.a), if not provided in those sections. The degree
of detail to be provided shall be guided by the following rule:
Include those characteristics of the system that are conditions
for system acceptance; defer to design descriptions those characteristics
that the acquirer is willing to leave up to the developer. If
there are no requirements in a given paragraph, the paragraph
shall so state. If a given requirement fits into more than one
paragraph, it may be stated once and referenced from the other
paragraphs.

=head2 3.1 Required states and modes.

If the system is required to operate
in more than one state or mode having requirements distinct from
other states or modes, this paragraph shall identify and define
each state and mode. Examples of states and modes include: idle,
ready, active, post-use analysis, training, degraded, emergency,
backup, wartime, peacetime. The distinction between states and
modes is arbitrary. A system may be described in terms of states
only, modes only, states within modes, modes within states, or
any other scheme that is useful. If no states or modes are required,
this paragraph shall so state, without the need to create artificial
distinctions. If states and/or modes are required, each requirement
or group of requirements in this specification shall be correlated
to the states and modes. The correlation may be indicated by a
table or other method in this paragraph, in an appendix referenced
from this paragraph, or by annotation of the requirements in the
paragraphs where they appear.

=head2 3.2 System capability requirements.

This paragraph shall be divided into
subparagraphs to itemize the requirements associated with each
capability of the system. A 'capability' is defined
as a group of related requirements. The word 'capability'
may be replaced with 'function,' 'subject,'
'object,' or other term useful for presenting the requirements.

=head2 3.2.x (System capability).

This paragraph shall identify a required
system capability and shall itemize the requirements associated
with the capability. If the capability can be more clearly specified
by dividing it into constituent capabilities, the constituent
capabilities shall be specified in subparagraphs. The requirements
shall specify required behavior of the system and shall include
applicable parameters, such as response times, throughput times,
other timing constraints, sequencing, accuracy, capacities (how
much/how many), priorities, continuous operation requirements,
and allowable deviations based on operating conditions. The requirements
shall include, as applicable, required behavior under unexpected,
unallowed, or 'out of bounds' conditions, requirements
for error handling, and any provisions to be incorporated into
the system to provide continuity of operations in the event of
emergencies. Paragraph 3.3.x of this DID provides a list of topics
to be considered when specifying requirements regarding inputs
the system must accept and outputs it must produce.

=head2 3.3 System external interface requirements.

This paragraph shall be divided into
subparagraphs to specify the requirements, if any, for the system's
external interfaces. This paragraph may reference one or more
Interface Requirements Specifications (IRSs) or other documents
containing these requirements.

=head2 3.3.1 Interface identification and diagrams.

This paragraph shall identify the
required external interfaces of the system. The identification
of each interface shall include a project-unique identifier and
shall designate the interfacing entities (systems, configuration
items, users, etc.) by name, number, version, and documentation
references, as applicable. The identification shall state which
entities have fixed interface characteristics (and therefore impose
interface requirements on interfacing entities) and which are
being developed or modified (thus having interface requirements
imposed on them). One or more interface diagrams shall be provided
to depict the interfaces.

=head2 3.3.x (Project-unique identifier of interface).

This paragraph (beginning with 3.3.2)
shall identify a system external interface by project-unique identifier,
shall briefly identify the interfacing entities, and shall be
divided into subparagraphs as needed to state the requirements
imposed on the system to achieve the interface. Interface characteristics
of the other entities involved in the interface shall be stated
as assumptions or as 'When [the entity not covered] does
this, the system shall...,' not as requirements on the other
entities. This paragraph may reference other documents (such as
data dictionaries, standards for communication protocols, and
standards for user interfaces) in place of stating the information
here. The requirements shall include the following, as applicable,
presented in any order suited to the requirements, and shall note
any differences in these characteristics from the point of view
of the interfacing entities (such as different expectations about
the size, frequency, or other characteristics of data elements):

=head2 3.3.x.1

Priority that the system must assign the interface

=head2 3.3.x.2

Requirements on the type of interface (such
as real-time data transfer, storage-and-retrieval of data, etc.)
to be implemented

=head2 3.3.x.3

Required characteristics of individual data
elements that the system must provide, store, send, access, receive,
etc., such as:

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

=item 9

Sources (setting/sending entities) and recipients
(using/receiving entities)

=back

=head2 3.3.x.4

Required characteristics of data element assemblies
(records, messages, files, arrays, displays, reports, etc.) that
the system must provide, store, send, access, receive, etc., such
as:

=over 4

=item 1

Names/identifiers

=over 4

=item *

Project-unique identifier

=item *

Non-technical (natural language) name

=item *

Technical name (e.g., record or data structure
name in code or database)

=item *

Abbreviations or synonymous names

=back

=item 2 

Data elements in the assembly and their structure
(number, order, grouping)

=item 3

Medium (such as disk) and structure of data
elements/assemblies on the medium

=item 4

Visual and auditory characteristics of displays
and other outputs (such as colors, layouts, fonts, icons and other
display elements, beeps, lights)

=item 5

Relationships among assemblies, such as sorting/access
characteristics




=item 6

Priority, timing, frequency, volume, sequencing,
and other constraints, such as whether the assembly may be updated
and whether business rules apply

=item 7

Security and privacy constraints

=item 8

Sources (setting/sending entities) and recipients
(using/receiving entities)

=back

=head2 3.3.x.5

Required characteristics of communication
methods that the system must use for the interface, such as:

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

=head2 3.3.x.6

Required characteristics of protocols the
system must use for the interface, such as:

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

=head2 3.3.x.7

Other required characteristics, such as physical
compatibility of the interfacing entities (dimensions, tolerances,
loads, plug compatibility, etc.), voltages, etc.

=head2 3.4 System internal interface requirements.

This paragraph shall specify the requirements,
if any, imposed on interfaces internal to the system. If all internal
interfaces are left to the design or to requirement specifications
for system components, this fact shall be so stated. If such requirements
are to be imposed, paragraph 3.3 of this DID provides a list of
topics to be considered.

=head2 3.5 System internal data requirements.

This paragraph shall specify the requirements,
if any, imposed on data internal to the system. Included shall
be requirements, if any, on databases and data files to be included
in the system. If all decisions about internal data are left to
the design or to requirements specifications for system components,
this fact shall be so stated. If such requirements are to be imposed,
paragraphs 3.3.x.c and 3.3.x.d of this DID provide a list of topics
to be considered.

=head2 3.6 Adaptation requirements.

This paragraph shall specify the requirements,
if any, concerning installation-dependent data that the system
is required to provide (such as site-dependent latitude and longitude
or site-dependent state tax codes) and operational parameters
that the system is required to use that may vary according to
operational needs (such as parameters indicating operation-dependent
targeting constants or data recording).

=head2 3.7 Safety requirements.

This paragraph shall specify the system
requirements, if any, concerned with preventing or minimizing
unintended hazards to personnel, property, and the physical environment.
Examples include restricting the use of dangerous materials; classifying
explosives for purposes of shipping, handling, and storing; abort/escape
provisions from enclosures; gas detection and warning devices;
grounding of electrical systems; decontamination; and explosion
proofing. This paragraph shall include the system requirements,
if any, for nuclear components, including, as applicable, requirements
for component design, prevention of inadvertent detonation, and
compliance with nuclear safety rules.

=head2 3.8 Security and privacy requirements.

This paragraph shall specify the system
requirements, if any, concerned with maintaining security and
privacy. The requirements shall include, as applicable, the security/privacy
environment in which the system must operate, the type and degree
of security or privacy to be provided, the security/privacy risks
the system must withstand, required safeguards to reduce those
risks, the security/privacy policy that must be met, the security/privacy
accountability the system must provide, and the criteria that
must be met for security/privacy certification/accreditation.

=head2 3.9 System environment requirements.

This paragraph shall specify the requirements,
if any, regarding the environment in which the system must operate.
Examples for a software system are the computer hardware and operating
system on which the software must run. (Additional requirements
concerning computer resources are given in the next paragraph).
Examples for a hardware-software system include the environmental
conditions that the system must withstand during transportation,
storage, and operation, such as conditions in the natural environment
(wind, rain, temperature, geographic location), the induced environment
(motion, shock, noise, electromagnetic radiation), and environments
due to enemy action (explosions, radiation).

=head2 3.10 Computer resource requirements.

This paragraph shall be divided into
the following subparagraphs. Depending upon the nature of the
system, the computer resources covered in these subparagraphs
may constitute the environment of the system (as for a software
system) or components of the system (as for a hardware-software
system).

=head2 3.10.1 Computer hardware requirements.

This paragraph shall specify the requirements,
if any, regarding computer hardware that must be used by, or incorporated
into, the system. The requirements shall include, as applicable,
number of each type of equipment, type, size, capacity, and other
required characteristics of processors, memory, input/output devices,
auxiliary storage, communications/network equipment, and other
required equipment.

=head2 3.10.2

Computer hardware resource utilization
requirements.
This paragraph shall specify the requirements,
if any, on the system's computer hardware resource utilization,
such as maximum allowable use of processor capacity, memory capacity,
input/output device capacity, auxiliary storage device capacity,
and communications/network equipment capacity. The requirements
(stated, for example, as percentages of the capacity of each computer
hardware resource) shall include the conditions, if any, under
which the resource utilization is to be measured.

=head2 3.10.3 Computer software requirements.

This paragraph shall specify the requirements,
if any, regarding computer software that must be used by, or incorporated
into, the system. Examples include operating systems, database
management systems, communications/ network software, utility
software, input and equipment simulators, test software, and manufacturing
software. The correct nomenclature, version, and documentation
references of each such software item shall be provided.

=head2 3.10.4 Computer communications requirements.

This paragraph shall specify the additional
requirements, if any, concerning the computer communications that
must be used by, or incorporated into, the system. Examples include
geographic locations to be linked; configuration and network topology;
transmission techniques; data transfer rates; gateways; required
system use times; type and volume of data to be transmitted/received;
time boundaries for transmission/reception/response; peak volumes
of data; and diagnostic features.

=head2 3.11 System quality factors.

This paragraph shall specify the requirements,
if any, pertaining to system quality factors. Examples include
quantitative requirements concerning system functionality (the
ability to perform all required functions), reliability (the ability
to perform with correct, consistent results -- such as mean time
between failure for equipment), maintainability (the ability to
be easily serviced, repaired, or corrected), availability (the
ability to be accessed and operated when needed), flexibility
(the ability to be easily adapted to changing requirements), portability
of software (the ability to be easily modified for a new environment),
reusability (the ability to be used in multiple applications),
testability (the ability to be easily and thoroughly tested),
usability (the ability to be easily learned and used), and other
attributes.

=head2 3.12 Design and construction constraints.

This paragraph shall specify the requirements,
if any, that constrain the design and construction of the system.
For hardware-software systems, this paragraph shall include the
physical requirements imposed on the system. These requirements
may be specified by reference to appropriate commercial or military
standards and specifications. Examples include requirements concerning:

=over 4

=item 1

Use of a particular system architecture or
requirements on the architecture, such as required subsystems;
use of standard, military, or existing components; or use of Government/acquirer-furnished
property (equipment, information, or software)

=item 2

Use of particular design or construction standards;
use of particular data standards; use of a particular programming
language; workmanship requirements and production techniques

=item 3

Physical characteristics of the system (such
as weight limits, dimensional limits, color, protective coatings);
interchangeability of parts; ability to be transported from one
location to another; ability to be carried or set up by one, or
a given number of, persons

=item 4

Materials that can and cannot be used; requirements
on the handling of toxic materials; limits on the electromagnetic
radiation that the system is permitted to generate

=item 5

Use of nameplates, part marking, serial and
lot number marking, and other identifying markings

=item 6

Flexibility and expandability that must be
provided to support anticipated areas of growth or changes in
technology, threat, or mission

=back

=head2 3.13 Personnel-related requirements.

This paragraph shall specify the system requirements, if any,
included to accommodate the number, skill levels, duty cycles,
training needs, or other information about the personnel who will
use or support the system. Examples include requirements for the
number of work stations to be provided and for built-in help and
training features. Also included shall be the human factors engineering
requirements, if any, imposed on the system. These requirements
shall include, as applicable, considerations for the capabilities
and limitations of humans, foreseeable human errors under both
normal and extreme conditions, and specific areas where the effects
of human error would be particularly serious. Examples include
requirements for adjustable-height work stations, color and duration
of error messages, physical placement of critical indicators or
buttons, and use of auditory signals.

=head2 3.14 Training-related requirements.

This paragraph shall specify the system requirements, if any,
pertaining to training. Examples include training devices and
training materials to be included in the system.

=head2 3.15 Logistics-related requirements.

This paragraph shall specify the system requirements, if any,
concerned with logistics considerations. These considerations
may include: system maintenance, software support, system transportation
modes, supply-system requirements, impact on existing facilities,
and impact on existing equipment.

=head2 3.16 Other requirements.

This paragraph shall specify additional system requirements, if
any, not covered in the previous paragraphs. Examples include
requirements for system documentation, such as specifications,
drawings, technical manuals, test plans and procedures, and installation
instruction data, if not covered in other contractual documents.

=head2 3.17 Packaging requirements.

This section shall specify the requirements, if any, for packaging,
labeling, and handling the system and its components for delivery.
Applicable military specifications and standards may be referenced
if appropriate.

=head2 3.18 Precedence and criticality of requirements.

This paragraph shall specify, if applicable, the order of precedence,
criticality, or assigned weights indicating the relative importance
of the requirements in this specification. Examples include identifying
those requirements deemed critical to safety, to security, or
to privacy for purposes of singling them out for special treatment.
If all requirements have equal weight, this paragraph shall so
state.

=head1 4 Qualification provisions.

This section shall define a set of qualification methods and shall
specify for each requirement in Section 3 the method(s) to be
used to ensure that the requirement has been met. A table may
be used to present this information, or each requirement in Section
3 may be annotated with the method(s) to be used. Qualification
methods may include:

=over 4

=item 1

Demonstration: The operation of the system,
or a part of the system, that relies on observable functional
operation not requiring the use of instrumentation, special test
equipment, or subsequent analysis.

=item 2

Test: The operation of the system, or a part
of the system, using instrumentation or other special test equipment
to collect data for later analysis.

=item 3

Analysis: The processing of accumulated data
obtained from other qualification methods. Examples are reduction,
interpolation, or extrapolation of test results.

=item 4

Inspection: The visual examination of system
components, documentation, etc.

=item 5

Special qualification methods. Any special
qualification methods for the system, such as special tools, techniques,
procedures, facilities, acceptance limits, use of standard samples,
preproduction or periodic production samples, pilot models, or
pilot lots.

=back

=head1 5 Requirements traceability.

For system-level specifications, this paragraph does not apply.
For subsystem-level specifications, this paragraph shall contain:

=over 4

=item 1

Traceability from each subsystem requirement
in this specification to the system requirements it addresses.
(Alternatively, this traceability may be provided by annotating
each requirement in Section 3.)

Note: Each level of system refinement may result in requirements
not directly traceable to higher-level requirements. For example,
a system architectural design that creates two subsystems may
result in requirements about how the subsystems will interface,
even though these interfaces are not covered in system requirements.
Such requirements may be traced to a general requirement such
as 'system implementation' or to the system design decisions
that resulted in their generation.

=item 2

Traceability from each system requirement
that has been allocated to the subsystem covered by this specification
to the subsystem requirements that address it. All system requirements
allocated to the subsystem shall be accounted for. Those that
trace to subsystem requirements contained in IRSs shall reference
those IRSs.

=back

=head1 6 Notes.

This
section shall contain any general information that aids in understanding
this document (e.g., background information, glossary, rationale).
This section shall contain an alphabetical listing of all acronyms,
abbreviations, and their meanings as used in this document and
a list of any terms and definitions needed to understand this
document.

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
