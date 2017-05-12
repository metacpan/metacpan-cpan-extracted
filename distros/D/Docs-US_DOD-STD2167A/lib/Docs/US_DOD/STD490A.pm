#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package Docs::US_DOD::STD490A;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.08';
$DATE = '2003/06/14';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'MIL-STD-490A';
$TITLE = 'Specification Practices';
$REVISION = 'A';
$REVISION_DATE = '';

1


__END__

=head1 MIL-STD-490A SPECIFICATION PRACTICES

4 JUNE 1985

SUPERSEDING

MIL-STD-490

30 OCTOBER 1968

DISTRIBUTION STATEMENT A. Approved for public release;
distribution is unlimited.
Specification Practices

=over 4

=item 1

This Military Standard has not been approved its
use has to be with caution

=item 2

Recommended corrections, additions, or deletions
should be addressed to:

=back

=head1 Foreword

This Standard was prepared to establish uniform specification
practices in response to the need for a document comparable to
DOD-STD-100 covering engineering drawing practices and in recognition
of the configuration identification concepts.

This Standard is arranged in six sections and 15
appendixes.

=over 4

=item *

Section 1 states the scope of the standard.

=item *

Section 2 lists the referenced documents.

=item *

Section 3 states broad requirements, concepts,
and practices applicable to specifications in general.

=item *

Section 4 states general requirements for each
of the six sections of a specification. The second digit of the
paragraph numbering of Section 4 corresponds with the numbering
of the six specification sections.

=item *

Section 5 invokes the detailed requirements of
the appendixes which are outlines for various types of specifications.

=item *

Section 6 contains a list of Data Item Descriptions
(DIDs) applicable to this standard.

=back

This Standard, although primarily intended for use
in preparation of program-peculiar specifications, recognizes
the probability that some items, processes, or materials covered
by specifications prepared to this Standard will be subject to
conversion on a project by project basis. Therefore, specifications
prepared in accordance with this Standard, when subject to all
pertinent conversion requirements.

Although this standard is specifically applicable
to MIL-S-83490 Form 1a specifications only, its use as a guidance
document for the preparation of other forms is encouraged.

=head1 1.0 SCOPE

=head2 1.1 Scope.

This standard establishes the format and contents
of specifications for program-peculiar configuration items, processes,
and materials.

=head2 1.2 Purpose.

The purpose of this standard is to establish uniform
practices for specification preparation, to ensure the inclusion
of essential requirements, and to aid in the use and analysis
of specification content.

=head2 1.3 Classification.

Specifications covered by this standard may be prepared
as military, Federal, contracting agency, or contractor specifications.
The types of specifications are as follows:

=over 4

=item *

Type A - System/Subsystem Specification

=item *

Type B - Development Specifications

=over 4

=item 1

B1 Prime Item

=item 2

B2 Critical Item

=item 3

B3 Non-Complex Item

=item 4

B4 Facility or Ship

=item 5

B5 Software

=back

=item *

Type C- Product Specifications




=over 4

=item 1

C1a Prime Item Function

=item 2

C1b Prime Item Fabrication

=item 3

C2a Critical Item Function

=item 4

C2b Critical Item Fabrication

=item 5

C3 Non-Complex Item Fabrication

=item 6

C4 Inventory Item

=item 7

C5 Software

=back

=item *

Type D - Process Specification

=item *

Type E - Material Specification

=back

=head2 1.4 Definitions.

=head2 1.4.1 Program-peculiar.

Configuration items, processes
and materials as used in this standard, include all configuration
items, processes and materials conceived, developed, reduced to
practice or first documented for the development, procurement,
production, assembly, installation, testing or support of the
system/equipment/software/end product (including their components
and supporting configuration items) developed or initially procured
under a specific program. 

For all Army applications of this standard,
this paragraph shall read as follows:

PROGRAM-PECULIAR items, processes and materials
as used in this standard, include only those items, processes
and materials conceived, developed, reduced to practice or first
documented for the development, procurement, production, assembly,
installation, testing and support of the system/ equipment/end
item (including their components and supporting items) developed
or initially procured under a specific program for which there
would be judged to be no potential for use by subsequently developed
systems. In other words, program-peculiar items, processes and
materials will be only those which are obviously only one-of-a-kind
and, therefore, little or no potential exists for elimination
through Item Reduction Studies or for any future use.'

=head2 1.4.2 Configuration item.

Hardware or software, or an aggregation of both,
which is designated by the contracting agency for configuration
management.

=head2 1.4.3 Hardware Configuration Item (HWCI).

See Configuration item.

=head2 1.4.4 Computer Software Configuration Item (CSCI).

See Configuration item.

1.4.5 Other definitions. For definitions of other
terms used in this standard, see DOD-STD-480, Appendix E and DOD-STD-2167.

=head1 2.0 REFERENCED DOCUMENTS

=head2 2.1 Government documents. 

The following documents
of the issue in effect on date of invitation for bids or request
for proposal, form a part of the specification to the extent specified
herein.

SPECIFICATIONS

Military

DOD-D-1000 Drawings, Engineering and Associated Lists
STANDARDS

Federal

FED-STD-102 Preservation, Packaging, and Packing
Levels
Military

MIL-STD-12 Abbreviations for Use on Drawings, Specifications
Standards and in Technical Documents

DOD-STD-100 Engineering Drawing Practices

MIL-STD-109 Quality Assurance Terms and Definitions

MIL-STD-129 Marking for Shipment and Storage

MIL-STD-130 Identification Marking of US Military
Property MIL-STD-1472 Human Engineering Design Criteria for Military
Systems, Equipment, and Facilities

DOD-STD-480 Configuration Control - Engineering Changes,
Deviations and Waivers
OTHER PUBLICATIONS

Cataloging Federal Supply Classification Handbook
H2

Cataloging Federal Supply, Code for Handbook H4 Manufacturers

Cataloging Federal Item Identification Handbook H6
Guides for Supply Cataloging

DOD 4120.3-M Standardization Policies

Procedures and Instructions

DOD 5220.22-M Industrial Security Manual for Safeguarding
Classified Information

GPO Style Manual

=head2 2.2 Non-Government document. 

The following document
forms a part of this specification to the extent specified herein.
Unless otherwise indicated, the issue in effect on date of invitation
for bids or request for proposal shall apply.

Merriam-Webster's New International Dictionary

Copies of listed federal and military standards,
specifications and handbooks are available through the DOD Single
Stock Point, Commanding Officer, U.S. Naval Publications and Forms
Center (Attn: NPFC 1032), 5801 Tabor Avenue Philadelphia, Pennsylvania
19120. Applications for copies of DOD Manuals 4120.3-M and 5220.22-M
and the GPO Style Manual should be addressed to the Superintendent
of Documents, U.S. Government Printing Office, Washington, D.C.
20402.

=head1 3.0 REQUIREMENTS

=head2 3.1 Introduction.

Specifications prepared in accordance with this standard
are intended for use in design and procurement of configuration
items and for services required for program- peculiar application.

=head2 3.1.1 Configuration identification.

Current configuration identification is established
by baseline configuration identification documents and all effected
changes. Configuration identification documents include all those
necessary to provide a full technical description of the characteristics
of the configuration item that require control at the time that
the baseline is established (see 6.2).

=head2 3.1.1.1 Functional Configuration Identification
(FCI).

Functional configuration identification (functional
baseline and approved changes) will normally include a Type A
specification or a Type B specification supplemented by other
specification types as necessary to specify: (1) all essential
system functional characteristics; (2) necessary interface characteristics;
(3) specific designation of the functional characteristics of
key configuration items; and (4) all of the tests required to
demonstrate achievement of each specified characteristic (see
6.2).

=head2 3.1.1.2 Allocated Configuration Identification
(ACI).

Allocated configuration identification (allocated
baseline and approved changes) normally consists of a series of
Type B specifications defining the requirements including functional,
for each major configuration item. These may be supplemented by
other types of specifications, engineering drawings and related
data, as necessary, to specify: (1) all of the essential configuration
item characteristics including delineation of interfaces;(2) physical
characteristics necessary to assure compatibility with associated
systems, configuration items and inventory items; and (3) all
of the tests required to demonstrate achievement of each specified
functional characteristic (see 6.2).

=head2 3.1.1.3 Product Configuration Identification (PCI).

The product configuration identification (product
baseline and approved changes) will normally include specification
Types C, D, and E, engineering drawings and related data, as necessary,
to provide a set of documents adequate for the procurement, production,
test, evaluation, and acceptance of a configuration item without
requiring further development work. This set of documents provides
that technical description which describes the required physical
characteristics of a configuration item; the functional characteristics
designated for production acceptance testing; and required acceptance
tests.

=head2 3.1.2 Coverage of specifications.

Specifications may be prepared to cover a group of
products, services or materials, or a single product, service
or material, and are general or detail specifications, respectively,
and either may be prepared as any of the types specified herein.

3.1.2.1 General specification.
A general specification covers requirements common
to two or more types, classes, grades, or styles of products,
services, or materials; this avoids repetition of common requirements
in detail specifications. It also permits changes to common requirements
to be readily effected. General specifications may also be used
to cover common requirements for weapon systems and subsystems.

=head2 3.1.2.2 Detail specification.

A detail specification covers all requirements for
one or more types of configuration items or services so as not
to require preparation and reference to a general specification
for the common requirements. A detail specification may also take
the form of a specification sheet, which is incomplete without
reference to a general specification. The detail and referenced
general specification (which contains the requirements common
to the family configuration items) then constitute the total requirements.
In either instance, detail specifications shall be prepared in
six-section format described in Section 3 and 4 of this standard.

=head2 3.1.3 Types.

General Requirements for specification types are
as follows:

=head2 3.1.3.1 Type A - System/subsystem specification.

This type of specification states the technical and
mission requirements for a system/subsystem as an entity, allocates
requirements to functional areas, documents design constraints,
and defines the interfaces between or among the functional areas.
Normally, the initial version of a system/subsystem specification
is based on parameters developed during the Concept Exploration
phase. This specification (initial version) is used to establish
the general nature of the system that is to be further defined
and finalized during the Demonstration and Validation phase. The
system/subsystem specification is maintained current during the
Demonstration and Validation phase, culminating in a revision
that forms the future performance base for the development and
production of the prime items and configuration items. The System/Subsystem
Specification shall be prepared by the contractor and shall be
in accordance with the format and content of the System/ Subsystem
Specification Data Item Description (see 6.2).

=head2 3.1.3.2 Type B - Development specifications.

Development specifications state the requirements
for the design or engineering development of a product during
the development period. Each development specification shall be
in sufficient detail to describe effectively the performance characteristics
that each configuration item is to achieve when a developed configuration
item is to evolve into a detail design for production. The development
specification should be maintained current during production when
it is desired to retain a complete statement of performance requirements.
Since the breakdown of a system into its elements involves configuration
items of various degrees of complexity which are subject to different
engineering disciplines or specification content, it is desirable
to classify development specifications by sub-types. The characteristics
and some general statements regarding each sub-type are given
in the following paragraphs (see 6.2).

=head2 3.1.3.2.1 Type B1 - Prime item development specification.

(See Appendix II for outline of form). A prime item
development specification is applicable to a complex item such
as an aircraft, missile, launcher equipment, fire control equipment,
radar set, training equipment, etc. A prime item development specification
may be used as the functional baseline for a single configuration
item development program or as part of the allocated baseline
where the configuration item covered is part of a larger system
development program. Normally configuration items requiring a
Type B1 specification meet the following criteria:

=over 4

=item 1

The prime item will be received or formally
accepted by the contracting agency on a DD Form 250, sometimes
subject to limitations prescribed thereon.

=item 2

Provisioning action will be required.

=item 3

Technical manuals or other instructional material
covering operation and maintenance of the prime item will be required.

=item 4

Quality conformance inspection of each prime item, as
opposed to sampling, will be required.

=back

3.1.3.2.2. Type B2 - Critical item development
specification. (See Appendix III for outline of form.) A Type
B2 specification is applicable to a configuration item which is
below the level of complexity of a prime item but which is engineering
critical or logistics critical.

=over 4

=item 1

A critical item is engineering critical where
one or more of the following applies:

=over 4

=item *

The technical complexity warrants an individual
specification.

=item *

Reliability of the critical item significantly
affects the ability of the system or prime item to perform its
overall function, or safety is a consideration.

=item *

The prime item cannot be adequately evaluated
without separate evaluation and application suitability testing
of the critical item.

=back

=item 2

A critical item is logistics critical where
the following apply:

=over 4

=item *

Repair parts will be provisioned for the
item.

=item *

The contracting agency has designated the item
for multiple source reprocurement.

=back

=back

=head2 3.1.3.2.3 Type B3 - Non-Complex item development
specification.

(See Appendix IV for outline of form.) This type
of specification is applicable to configuration items of relatively
simple design which meet all of the following criteria:

=over 4

=item 1

During development of the system or configuration
item, the non-complex item can be shown to be suitable for its
intended application by inspection or demonstration.

=item 2

Acceptance testing to verify performance is
not required.

=item 3

Acceptance can be based on verification that
the item, as fabricated, conforms to the drawings.

=item 4

The end product is not software.

=back

Examples of configuration items which normally meet
the above criteria are: special tools, work stands, fixtures,
dollies, and brackets. Many such simple configuration items can
be defined adequately during the development phase by a sketch
and during production by a drawing or set of drawings. If drawings
will suffice to cover all requirements, and unless a specification
is required by the Government contracting agency, a specification
for a particular non-complex item need not be prepared. However,
when it is necessary to specify several performance requirements
in a formal manner to ensure development of a satisfactory configuration
item or when it is desirable to specify detailed verification
procedures, the use of a specification of this type is appropriate.

=head2 3.1.3.2.4 Type B4 - Facility or ship development
specification. 

(See Appendix V for outline of form.) A facility
or ship development specification is applicable to each HWCI which
is both a fixed (or floating) installation and an integral part
of a system. Examples of facility/ship requirements are: basic
structural, architectural or operational features designed specifically
to accommodate the requirements unique to the system and which
must be developed in close coordination with the system; the facility
or ship services which form complex interfaces with the system;
facility or ship hardening to decrease the total system's vulnerability;
and ship speed, manoeuvrability, etc. A development specification
for a facility or ship establishes the requirements and basic
restraints/constraints imposed on the development of an architectural
and engineering design for such facility or ship. The product
specifications for the facility or ship are prepared by the architectural/engineering
activity, and their type and format are not prescribed by this
standard.

=head2 3.1.3.2.5 Type B5 - Software development specification

(see 6.2). Software development specifications are applicable
to the development of computer software and consist of a Software
Requirements Specification and Interface Requirements Specification(s)..

=head2 3.1.3.2.5.1 Software Requirements Specification.

This type of specification describes in detail the
functional, interface, quality factor, special, and qualification
requirements necessary to design, develop, test, evaluate and
deliver the required Computer Software Configuration Item (CSCI).
The Software Requirements Specification shall be prepared by the
contractor and shall be in accordance with the format and content
of the Software Requirements Specification Data Item Description
(See 6.1). .

=head2 3.1.3.2.5.2 Interface Requirements Specification.

This type of specification describes in detail the
requirements for one or more CSCI interfaces in the system, subsystem,
or prime item. The specified requirements are those necessary
to design, develop, test, evaluate, and deliver the required CSCI.
The interface requirements may be included in the associated Software
Requirements Specifications under the following conditions: (1)
there are few interfaces, (2) few development groups are involved
in implementing the interface requirements, (3) the interfaces
are simple, or (4) there is one contractor developing the software.
The Interface Requirements Specification shall be prepared by
the contractor(s) and shall be in accordance with the format and
content of the Interface Requirements Specification Data Item
Description (see 6.2). .

=head2 3.1.3.3 Type C - Product Specifications.

Product specifications are applicable to any configuration
item below the system level, and may be oriented toward procurement
of a product through specification of primarily functional (performance)
requirements or primarily fabrication (detailed design) requirements.
Sub-types of product specifications to cover equipments of various
complexities or requiring different outlines of form are covered
in paragraphs 3.1.3.3.1 through 3.1.3.3.5.

=over 4

=item 1

A product function specification states (1)
the complete performance requirements of the product for the intended
use, and (2) necessary interface and interchangeability characteristics.
It covers form, fit, and function. Complete performance requirements
include all essential functional requirements under service environmental
conditions or under conditions simulating the service environment.
Quality assurance provisions for hardware include one or more
of the following inspections: qualification evaluation, preproduction,
periodic production, and quality conformance.

=item 2

A product fabrication specification will normally
be prepared when both development and production of the HWCI are
procured. In those cases where a development specification (Type
B) has been prepared, specific reference to the document containing
the performance requirements for the HWCI shall be made in the
product fabrication specification. These specifications shall
state: (1) a detailed description of the parts and assemblies
of the product, usually by prescribing compliance with a set of
drawings, and (2) those performance requirements and corresponding
tests and inspections necessary to assure proper fabrication,
adjustment, and assembly techniques. Tests normally are limited
to acceptance tests in the shop environment. Selected performance
requirements in the normal shop or test area environment and verifying
tests therefore may be included. Preproduction or periodic tests
to be performed on a sampling basis and requiring service, or
other, environment may reference the associated development specification.
Product fabrication specifications may be prepared as Part II
of a two-part specification (See 3.1.4) when the contracting agency
desires close relationships between the performance and fabrication
requirements.

=back

=head2 3.1.3.3.1 Type C1 -Prime item product specifications.

Prime item product specifications are applicable
to configuration items meeting the criteria for prime item development
specifications (Type B1) as stated in paragraph 3.1.3.2.1. They
may be prepared as function or fabrication specifications as determined
by the procurement conditions..

=head2 3.1.3.3.1.1 Type C1a - Prime item product function
specification.

(See Appendix VII for outline of form.) A type C1a
specification is applicable to the procurement of prime items
when a 'form, fit and function' description is acceptable.
Normally, this type of specification would be prepared only when
a single procurement is anticipated and training and logistic
considerations are unimportant..

=head2 3.1.3.3.1.2 Type C1b - Prime item product fabrication
specification.

(See Appendix VIII for outline of form.) Type C1b
specifications are normally prepared for procurement of prime
items when: a detailed design disclosure package needs to be made
available; it is desired to control the interchangeability of
lower level components and parts; and service maintenance and
training are significant factors..

=head2 3.1.3.3.2 Type C2 - Critical item product specifications.

Type C2 specifications are applicable to engineering
or logistic critical items as specified in paragraph 3.1.3.2.2,
and may be prepared as function or fabrication specifications..

=head2 3.1.3.3.2.1 Type C2a - Critical item product function
specification.

(See Appendix IX for outline of form.) A type C2a
specification is applicable to a critical item where the critical
item performance characteristics are of greater concern than part
interchangeability or control over the details of design, and
a 'form, fit and function' description is adequate.


=head2 3.1.3.3.2.2. Type C2b - Critical item product fabrication
specification.

(See Appendix X for outline of form.) A C2b specification
is applicable to a critical item when a detailed design disclosure
needs to be made available or where it is considered that adequate
performance can be achieved by adherence to a set of detail drawings
and required processes..

=head2 3.1.3.3.3 Type C3 - Non-complex item product fabrication
specification.

(See Appendix XI for outline of form.)
A non-complex
item product fabrication specification is applicable to non-complex
items as specified in paragraph 3.1.3.2.3. Where acquisition of
a non-complex item to a detailed design is desired, a set of detail
drawings may be prepared in lieu of a specification..

=head2 3.1.3.3.4 Type C4 - Inventory item specification.

(See Appendix XII for outline of form.) 
This type
of specification identifies applicable inventory items (including
their pertinent characteristics) that exist in the DOD inventory
and which will be incorporated in a prime item or in a system
being developed. The purpose of the inventory specification is
to stabilize the configuration of inventory items in the DOD inventory
on the basis of both current capabilities of each inventory item
and the requirements of the specific application, or to achieve
equipment/component item standardization between or within a system
or prime item. This puts the Government on notice as to the performance
and interface characteristics that are required, so that when
ECP's for an inventory item are evaluated the needs of the various
applications may be kept in mind. If this is not done, design
changes may make an inventory item unsuitable for the system.
A separate inventory item specification should be prepared, as
required, for each system, subsystem, prime item or critical item
in which inventory items are to be installed or which require
the support of inventory items..

=head2 3.1.3.3.5 Type C5 - Software Product Specification
(see 6.2).

The Software Product Specification is applicable
to the delivered CSCI and is sometimes referred to as the 'as
built' software specification. This specification consists
of the final updated version of the Software Design Description,
the Software Design Description, the Data Base Design Description(s),
the Interface Design Description(s), and the source and object
listings of the software. The Software Product Specification shall
be prepared by the contractor and shall be in accordance with
the format and content of the Software Product Specification Data
Item Description (see 6.2)..

=head2 3.1.3.3.5.1 Software Design Description.

The Software Design Description describes how the
top-level software units implement requirements allocated from
the Software Requirements Specification and, if applicable, Interface
Requirements Specification(s). The Software Design Description
shall be prepared by the contractor and shall be in accordance
with the format and content of the Software Design Description
Data Item Description (see 6.2). .

=head2 3.1.3.3.5.2 Software Design Description.

The Software Design Description shall also describe
the detailed decomposition of high level software units to lower
level software units. The Software Design Description shall be
prepared by the contractor and shall be in accordance with the
format and content of the Software Design Description Data Item
Description (see 6.2)..

=head2 3.1.3.3.5.3 Data Base Design Description.

The Data Base Design Description describes one or
more data base(s) used by the CSCI. If there is more than one
data base, each data base may be described in a separate Data
Base Design Description. The Data Base Design Description(s) shall
be prepared by the contractor and shall be in accordance with
the format and content of the Data Base Design Description Data
Item Description (see 6.2)..

=head2 3.1.3.3.5.4 Interface Design Description.

The Interface Design Description provides the detailed
design of one or more CSCI interfaces. When Interface Requirements
Specifications have been prepared, associated Interface Design
Descriptions shall be prepared as well. The Interface Design Description
shall be prepared by the contractor and shall be in accordance
with the format and content of the Interface Design Description
Data Item Description (see 6.2). .

=head2 3.1.3.4 Type D - Process specifications. 

(See Appendix
XIV for outline of form.) This type of specification is applicable
to a service which is performed on a product or material. Examples
of processes are: heat treatment, welding, plating, packing, microfilming,
marking etc. Process specifications cover manufacturing techniques
which require a specific procedure in order that a satisfactory
result may be achieved. Where specific processes are essential
to fabrication or procurement of a product or material, a process
specification is the means of defining such specific processes.
Normally, a process specification applies to production but may
be prepared to control the development of a process..

=head2 3.1.3.5 Type E - Material specifications. 

(See Appendix
XV for outline of form.) This type of specification is applicable
to a raw material (chemical compound), mixtures (cleaning agents,
paints), or semi-fabricated material (electrical cable, copper
tubing) which are used in the fabrication of a product. Normally,
a material specification applies to production but may be prepared
to control the development of a material..

=head2 3.1.4 Two-part specifications.

Two-part specifications,
which combine both development (performance) and product fabrication
(detail design) specifications under a single specification number
as Part I and Part II respectively, may be selected as a contracting
agency option. This practice requires both parts for a complete
definition of both performance requirements and detailed design
requirements governing fabrication. Under this practice, the development
specification remains alive during the life of the HWCI as the
complete statement of performance requirements. Proposed design
changes must be evaluated against both the product fabrication
and the development parts of the specification. To emphasize the
fact that two parts exist, both parts shall be identified by the
same specification number and each part shall be further identified
as Part I or Part II, as appropriate. Two-part specifications
are not applicable when the product specification is a product
function specification or when it is a computer software specification..

=head2 3.2 Style, format and identification of
specifications.

=head2 3.2.1 General.

This section covers style, format, and general instructions
for preparing a specification. This includes material arrangement,
paragraphing, numbering, heading, and concluding material..

=head2 3.2.2 Sectional arrangement of specifications.

Specifications shall contain six numbered sections,
and appendixes as required, titled and numbered as shown below.

  1. SCOPE
  2. APPLICABLE DOCUMENTS
  3. REQUIREMENTS
  4. QUALIFICATION REQUIREMENTS (for software)
     or QUALITY ASSURANCE PROVISIONS (for hardware)
  5. PREPARATION FOR DELIVERY
  6. NOTES,
 10. APPENDIX

Subject matter shall be kept within the scope of
the sections so that the same kind of requirements or information
will always appear in the same section of every specification.
Except for appendixes, if there is no information pertinent to
a section, the following shall appear below the section heading:.

'This section is not applicable to this specification.'.

=head2 3.2.3 Language style.

The paramount consideration in a specification is
its technical essence, and this should be presented in language
free of vague and ambiguous terms and using the simplest words
and phrases that will convey the intended meaning. Inclusion of
essential information shall be complete, whether by direct statements
or references to other documents (See 3.1.4). Consistency in terminology
and organization of material will contribute to the specification's
clarity and usefulness. Sentences shall be as short and concise
as possible. Punctuation should aid in reading and prevent misreading.
Well-planned word order requires a minimum of punctuation. When
extensive punctuation is necessary for clarity, the sentence(s)
shall be rewritten. Sentences with compound clauses shall be converted
into short and concise sentences..

=head2 3.2.3.1 Capitalization, spelling, etc.

Except where DOD requirements differ, the United
States Government Printing Office Style Manual shall be used as
a guide for capitalization, spelling, punctuation, syllabification,
etc. Merriam-Webster's New International dictionary (latest revision)
will be consulted when the Style Manual does not provide the guidance
needed. .

=head2 3.2.3.2 Abbreviations.

The applicable standard abbreviations listed in MIL-STD-12
shall be used, except that abbreviations in titles of specifications
shall be in accordance with Cataloging Handbook H6-1. The only
other abbreviations employed shall be those in common usage and
not subject to misinterpretation. The first time an abbreviation
is used in text, it shall be placed in parentheses following the
word or term spelled out in full; e.g., pounds per square inch
(psi). This rule does not apply to abbreviations used for the
first time in tables and equations; uncommon abbreviations so
used shall be explained in the text or footnotes..

=head2 3.2.3.3 Symbols.

Symbols shall not be used in text, but may be used
in equations and tables. Graphic symbols, when used in figures
shall be in accordance with military standards. (Any symbol formed
by a single character should be avoided if practicable, since
an error destroys the intended meaning.).

=head2 3.2.3.4 Proprietary names.

Trade names, copyrighted names, or other proprietary
names applying exclusively to the product of one company shall
not be used unless the configuration item(s) require source control
or cannot be adequately described because of the technicality
involved, construction, or composition. In such instances, one,
and if all pertinent requirements are specified, several, commercial
products may be included by inserting the words 'or equal'
after the trade name to assure wider competition and that bidding
will not be limited to a particular make specified. The same applies
to manufacturer's part numbers or drawing numbers for minor parts
when it is impractical to specify all detail requirements in the
specification. In all instances where 'or equal' is
permitted, the particular characteristics required shall be included
to define 'or equal'. .

=head2 3.2.3.5 Commonly used words and phrasing.

Certain words and phrases are frequently used in
a specification. The following rules shall be followed:

=over 4

=item 1

Referenced documents shall be cited thus 'conforming
to ...' 'as specified in ...' or 'in accordance
with ...'.

=item 2

'Unless otherwise specified' shall
be used to indicate an alternative course of action. The phrase
shall always come at the beginning of the sentence, and if possible,
at the beginning of the paragraph. This phrase shall be used only
when it is possible to clarify its meaning by providing a reference
such as to Section 6 of the specification for further clarification
in the contract or order or otherwise.

=item 3

When making reference to a requirement in
the specification and the requirement referenced is rather obvious
or not difficult to locate, the simple phrase 'as specified
herein' is sufficient and should be used.

=item 4

The phrase '... to determine compliance
with ...' or '... to determine conformance to ...'
should be used in place of '... to determine compliance to
...'. In any case use the same wording throughout.

=item 5

In stating positive limitations, the phrase
shall be stated thus: 'The diameter shall be no greater than
...'.

=item 6

The emphatic form of verb shall be used throughout
the specification; i.e., state in the requirements section that
'The indicator shall be designated to indicate ...',
and in the section containing test provisions 'The indicator
shall be turned to zero and 230 volts alternating current applied.'
For specific test procedures, the imperative form may be used
provided the entire method is preceded by 'the following
tests shall be performed,' or related wording. Thus, 'Turn

the indicator to zero and apply 230 volts alternating current.'

=item 7

Capitalize the words 'drawing,'
'bulletin,' etc., only when they are used immediately
preceding the number of a document. However, Federal and military
standards, and handbooks shall be identified in the text only
by their symbol and number; thus 'MIL-E-000,' not, 'specification
MIL-E-OOO.'

=back

=head2 3.2.3.6

Use of 'shall,' will,' 'should,'
and 'may'. Use 'shall' whenever a specification
expresses a provision that is binding. Use 'should'
and 'may' wherever it is necessary to express non-mandatory
provisions. 'Will' may be used to express a declaration
of purpose on the part of the contracting agency. It may be necessary
to use 'will' in cases where the simple future tense
is required, i.e., power for the motor will be supplied by the
ship..

=head2 3.2.3.7

Use of 'flammable' and 'non-flammable'.
The terms 'flammable' and 'non-flammable'
shall be used in specifications in lieu of the terms 'inflammable',
'uninflammable', and 'non-flammable'..

=head2 3.2.4

Paragraph numbering. Each paragraph and subparagraph
shall be numbered consecutively within each section of the specification,
using a period to separate the number representing each breakdown.
Example for Section 3 of specification:.

 3. REQUIREMENTS

 3.1 First Paragraph.

 3.1.1 First Subparagraph.

 3.2 Second Paragraph.

 3.2.1 First Subparagraph.

 3.2.2 Second Subparagraph.

 Or:.

 3. REQUIREMENTS.

 3.1 First Paragraph.

 3.1.1 First Subparagraph.

 3.2 Second Paragraph.

 3.2.1 First Subparagraph.

 3.2.2 Second Subparagraph.

Itemization with a paragraph or subparagraph shall
be identified by lowercase letters to avoid confusion with paragraph
numerals. For clarity of text, paragraph numbering shall be limited
to seven levels..

=head2 3.2.5 Paragraph identification.

If practicable, each paragraph and subparagraph shall
be given a subject identification. The first letter of the first
word in the paragraph identification shall be capitalized. Paragraph
identifications in any one section shall not be duplicated. Primary
paragraphs identifications shall be in boldfaced type and subparagraph
identifications italicized when typeset. When typewritten, paragraph
identification shall be underlined.

=head2 3.2.6 Underlining.

Do not underline any portion of a paragraph or capitalize
phrases or words for the sake of emphasis with the exceptions
noted in 3.2.5. All of the requirements are important in obtaining
the desired product or service. .

=head2 3.2.7 Cross references.

Cross references, that is references to parts within
the specification, shall be held to a minimum. Cross references
shall be used only to clarify the relationship of requirements
within the specification and to avoid inconsistencies and unnecessary
repetition. When the cross reference is to a paragraph, subparagraph,
etc., within the specification, the cross reference shall be only
to the specific paragraph number. The word paragraph shall not
appear..

=head2 3.2.8 Figures.

A figure is a picture or graph, and constitutes an
integral part of the specification. It shall be clearly related
to, and consistent with, the text of the associated paragraph.
Figures should not be confused with numbered and dated drawings
referenced in the text which shall be listed in Section 2 and
not physically incorporated in the specification..

=head2 3.2.8.1 Location of figures in specification.

Each figure shall be placed following, or within,
the paragraph containing a reference to it. If figures are numerous
and their location, as indicated above, would interfere with correct
sequencing of paragraphs and cause difficulty in understanding
or interpretation, they may be placed in numerical sequence at
the end of the specification before any appendix or index..

=head2 3.2.8.2 Preparation of figures.

All figures shall be titled, and they shall be numbered
consecutively with Arabic numerals in the order in which they
are initially referenced in the specification..

=head2 3.2.9 Tables.

A table is an arrangement of data in lines and columns.
It shall be used when data can thus be presented more clearly
than text. Elaborate or complicated tables shall be avoided. References
in the text shall be sufficiently detailed to make the purpose
of the table clear, and the table shall be restricted to data
pertinent to the associated text..

=head2 3.2.9.1 Location of tables in specifications.

A table shall be placed following, or within, the
paragraph containing a reference to it. If space does not permit,
a table shall be placed at the beginning of the succeeding page,
or if extensive, on a separate page. If tables are numerous and
their location, as indicated above, would interfere with correct
sequencing of paragraphs and cause difficulty in understanding
or interpretation, they may be placed in numerical sequence at
the end of the specification before any appendix or index. .


=head2 3.2.9.2 Preparation of tables.

The tables shall be numbered consecutively with Roman
numerals in the order in which they are initially referenced in
the specification. The number and title shall be placed above
the table. The contents of a table shall be organized and arranged
to show clearly the significance and relationship of the data.
Data included in the text shall not be repeated in the table.
Tables shall be boxed in and ruled. When a table is of such width
as to make it impracticable to place it in normal position on
the page, it shall be rotated counterclockwise 90 degrees..

=head2 3.2.10 Foldouts.

Foldouts shall be avoided except where required for
legibility. Large tables or figures may be broken out so that
they may be printed on facing pages. Where foldouts are required,
they should be grouped in one place, preferably at the end of
the specification (in the same location as figures) and suitable
reference to their location shall be included in the text. .

=head2 3.2.11 Footnotes.

=head2 3.2.11.1 Footnotes to text.

Footnotes to the text shall be avoided if possible.
Their purpose is to convey additional information that is not
properly a part of the text. A footnote to the text shall be placed
at the bottom of the page containing the reference to it..

=head2 3.2.11.2 Footnotes to tables and figures.

Footnotes
to a table or figure shall be placed below the table or figure.
The footnotes may contain mandatory information that cannot be
presented as data within a table. Footnotes shall be numbered
separately for each table. Where numerals will lead to ambiguity
(for example in connection with a chemical formula), superior
letters, asterisks, daggers, and other symbols may be used..

=head2 3.2.12 Contractual and administrative requirements.

A specification shall not include contractual requirements which
are properly a part of the contract; such as cost, time of delivery,
instructions on reworking or resubmitting rejected items or lots
method of payment, liquidated damages, provision for configuration
items damaged or destroyed in tests, etc. Contractual, administrative,
and warranty provisions such as those covered in general provisions
of contracts, shall not be made part of the requirements in the
specification. Contractual and administrative provisions not covered
in the general provisions, but considered essential for procurement,
may be indicated as 'ordering data' or 'features
to be included in bids or in contract' in Section 6. This
provision shall be exercised with caution and limited to essential
matters. .

=head2 3.2.13 Definitions in specifications.

The inclusion
of a definition can be avoided if requirements are properly stated.
When the meaning of one or more terms must be established in the
specification, definitions shall be placed in the text. However,
it is often clearer to list one or more definitions in Section
6, especially where the terms are used in many places throughout
the specification. When this is done, a parenthetical reference
to the applicable paragraph in Section 6 shall follow the terms
to indicate the existence of a definition..

=head2 3.2.14 References to other documents.

Referencing
is the approved method for including requirements in specifications
where this eliminates the repetition of requirements and tests
that are adequately set forth elsewhere. However, chain referencing
should be avoided. References shall be restricted to documents
that are specifically and clearly applicable to the specification,
and are current and available. Care shall be taken in writing
the specification to indicate in a positive manner the extent
to which a referenced document is applicable. The specification
shall also include any special details called for by the referenced
document. Reference to paragraph numbers in other documents shall
not be made. The reference shall be to a title, method number,
specifically identified requirement, or other definitive designation..

=head2 3.2.14.1 Limitation on references. 

A specification
shall not contain anything in conflict with provisions in referenced
documents unless it is desirable to make special exceptions to
such provisions, in which case the specific provision to which
exception is made shall be stipulated or the application of a
specific portion of the referenced document shall be clearly defined.
It is not intended that other documents be made a part of a specification
by reference unless the items, materials, tests, or other services
in the referenced documents are required in the quality and detail
which these documents are designed to produce. The applicability
of all referenced documents listed in Section 2 of a specification
shall be defined in Section 3, 4, or 5, as appropriate. The extent
of applicability of referenced documents shall also be specifically
indicated. The whole of a referenced document shall not be made
applicable by reference unless all of its provisions are clearly
required..


=head2 3.2.15 Security marking of specifications.

Specifications
containing classified information shall be marked and handled
in accordance with current security regulations as specified in
the DOD 5220.22-M..

=head2 3.2.16 Identification of specifications.

Each specification
shall be numbered and dated on each page. The identification number,
with the date below it shall always appear at the top of the page
opposite the binding edge..

=head2 3.2.16.1 Identification of Government activity specifications.

This series of specifications shall be identified
by the code identification of the Government design agency as
listed in Cataloging Handbook H4 and by a number assigned by the
Government design agency. Such number may be either a number or
a combination of letters, numbers and dashes. The number shall
not contain more than fifteen characters, excluding dashes and
revision letter. Specifications for HWCIs, materials or processes
intended for multiple application may be identified by a military
specification number. In such instances, the number shall be applied
in accordance with Defense Standardization Manual 4120.3-M and
no design agency code identification is used..

=head2 3.2.16.2 Identification of contractor specifications.

This series of specifications shall be identified by the manufacturer's
code identification of the design contractor as listed in Cataloging
Handbook H4 and by a number assigned by the contractor. The assigned
number shall not contain more than fifteen characters, excluding
dashes and revision letter..

=head2 3.2.16.3 Revision symbols.

Revision letters, starting
with 'A' for the first revision, and assigned alphabetically
for each succeeding revision, shall follow the specification number.
Letters, such as I, O, Z, which can be confused with numerals
shall not be used. .

=head2 3.2.16.4 Identification of two-part specifications.

When a two-part specification concept (See 3.1.4) is used, the
parts shall be identified on the title page and both parts shall
be assigned the same specification number (See figure 1). Revision
status of each part shall be separately maintained..

=head2 3.2.16.5 Identification of specification sheet.

The specification sheet is identified by the same number and code
identification, as the associated applicable general specification
followed by a virgule (slant) and a sequentially assigned Arabic
numeral for the sheet. The sheet number shall be assigned by the
contracting agency for the general specification and the total
number of characters for the specification excluding specification
sheet numbers shall not exceed fifteen..

Example: Code Ident 10001 WS 1967B/1A designates
revision A of sheet 1 issued for the B revision of general specification,
numbered WS 1967..

=head2 3.2.16.6 Designation of FSC Code.

If applicable,
Federal Supply Classification (FSC) code shall appear in the lower
right-hand corner of the first page of the specification. FSC
codes shall be as assigned in Cataloging Handbook H2..

=head2 3.2.16.7 Titling the specification. 

The approved
basic name of the material, product or service covered by the
specification shall be the first part of the title. Configuration
item names in titles shall make maximum use of Cataloging Handbook
H6. However, the basic noun in the title shall be in the singular
form if the specification covers only one product, and in the
plural form if the specification covers more than one product,
i.e., various types, grades, classes, sizes or capacities, etc.
except where SPECIFICATION NUMBER 12345B CODE IDENT XXXXX.

 PART I OF TWO PARTS.

 (Date).

 PRIME ITEM DEVELOPMENT SPECIFICATION.

 FOR.

 (APPROVED TITLE) .















 (TYPE DESIGNATOR, CONFIGURATION ITEM NUMBER, ETC.).

 Example of Identification for Part I.

 SPECIFICATION NUMBER 12345B.

 CODE IDENT XXXXX .

 PART II OF TWO PARTS.

 (Date).

 PRIME ITEM FABRICATION SPECIFICATION.

 FOR.

 (APPROVED TITLE).

 (TYPE DESIGNATOR, CONFIGURATION ITEM NUMBER, ETC.)

 Example of Identification for Part II.

The only form is plural or where the nature of the
product unavoidably requires the plural form. Where there is no
approved configuration item name, the title shall be developed
in accordance with DOD-STD-100. For general specifications the
words 'General Specifications For' shall be the closing
phrase of the title..

=head2 3.2.16.7.1 Modifiers.

The title of the specification
shall include, where appropriate, and in addition to the approved
basic name, the minimum number of modifiers, including Type Designators,
as are necessary for distinction and ready identification of the
coverage of the specification. Nondefinitive modifiers shall not
be used. Modifiers shall be arranged in reverse order and separated
from each other and the noun name by punctuation. .

=head2 3.2.16.7.1 Type of specification.

The type of specification
shall be included above the specification title. As a minimum,

the type shall be specified as 'SYSTEM/SUBSYSTEM,' 'DEVELOPMENT,'
'PRODUCT,' 'PROCESS,' or 'MATERIAL.'
Subtype may be specified when desired by the contracting agency.

=head2 3.3 CHANGES AND REVISIONS.

=head2 3.3.1 General.

Specifications shall be corrected
or updated when necessary, by means of either a change or revision.
A change is accomplished by the issue of a Specification Change

Notice (SCN) and attached change pages. A revision consists of
a complete reissue of the entire specification, all pages being
identified by the same applicable revision letter. In general,
corrections to only a small portion of a specification should
be accomplished by a change, whereas extensive corrections requiring
revision occur when: (a) over 50 percent of the pages have been,
or will be involved in the intended correction plus outstanding
SCNs; or (b) a revision is economically more practicable than
issue of page changes by SCN. As a general rule, no more than
five (5) SCNs shall be issued against a particular revision (or
original issue); when the sixth modification or correction is
required the outstanding changes should normally be incorporated
in a revision of the specification (see 6.2)..

=head2 3.3.2 Changes.

Changes to specifications shall be
proposed by SCN and issued by SCN. Specification sheets shall
be changed by revision only. As required by DOD-STD-480, a separate
SCN shall be submitted as an enclosure with an Engineering Change
Proposal (ECP) for each specification to be changed. SCNs so submitted
will be issued and incorporated only after approval of the ECP
and the engineering change ordered. An SCN shall also be used

to issue corrections to a specification unrelated to an ECP (see
6.2)..

=head2 3.3.2.1 Specification change notice.

The SCN is a
document used to propose, transmit and record changes to a specification.
The SCN form (figure 2) is used as a cover sheet and letter of
transmittal, the page changes associated with that SCN shall be
attached and shall constitute an integral part of the SCN (see
6.2). .



=head2 3.3.2.1.1 Proposed SCN.

A proposed SCN shall be used
to propose to the specification approving agency the exact change
in specification paragraphs, figures or other content that will
be distributed to users if the SCN is approved. Such modification
in content in this proposed form of the SCN may be submitted in
final specification change form or as an enclosure on which the
proposed changes in sentences, paragraphs, figures, tables, etc.,
are described..

=head2 3.3.2.1.2 Approved SCN.

An approved SCN, is used
to transmit the change after approval by the contracting agency.
It also provides a summary of pages affected by all approved changes.
SCNs are not cumulative insofar as transmittal of previous changes
is concerned, and changes distributed with previous SCNs remain
in effect unless changed or canceled by a SCN of later issue.
However, the summary of current changes is a cumulative summary
as of date of approval of the latest SCN..

=head2 3.3.2.2 Changed pages.

Updated and reissued pages
shall be complete reprints of pages suitable for incorporation
by removal of old pages and insertion of new pages. All portions
affected by the change shall be indicated by a symbol in the right
hand margin adjacent to, and encompassing all changed portions.
When change pages are issued for specifications with pages printed
on both sides of a sheet, and only the page on one side of a sheet
is affected by the change, both sides of the sheet shall be reissued.
The unaffected page side shall be reprinted without change and
shall not carry the date of the change or be included in the change
summary as being affected by the change..


=head2 3.3.2.3 Change numbering.

SCN numbers shall be assigned
in sequence, beginning with 1, against the original issue or current
revision of a specification. Thus, when a specification is revised,
the SCN numbers begin again with 1. The proposed SCN, and approved
SCN shall carry the same number. Once an SCN has been submitted
to the contracting agency, its SCN sequence number shall not thereafter
be changed or assigned to another SCN. However, SCNs may be approved
by the contracting agency out of sequence. Hence, an SCN, proposed
after a previously proposed but not yet approved SCN, may require
revision if the later one is approved prior to the earlier one
or an earlier SCN is not approved; in which case the numbers assigned
will not change, however, the contents of the change pages may
require a change (see 6.2)..

=head2 3.3.2.4 Identification and numbering of changed pages.

=head2 3.3.2.4.1 Identification.

Each changed page shall
be identified by means of the specification number and the applicable
revision letter. Under such number shall be entered the date of
issue of the SCN, which shall agree with the date entered in the
upper right hand corner of the SCN form..

Example: Assume that the current revision of the
specification is A, the date of issue of such revision is 20 June
1966, and two SCNs have been approved. If SCN-2 is issued on 5
June 1967, the pages changed by SCN-2 would carry the following
identification on each page..

18D4739A.

5 June 1967.

=head2 3.3.2.4.2 Page numbers.

The changed pages furnished
with an SCN shall be numbered with the same page numbers as the
pages they replace. If it is necessary to replace one page with
more than one, the additional pages shall carry the same number
as the affected page plus a suffix letter in alphabetical order
beginning with 'a'. Thus, the numbers of changed pages
to change page 5, would be 5, 5a, 5b, etc. If a page is deleted,
that number shall be omitted in the current page sequence. .

=head2 3.3.3 Revisions.

A revision of a specification is
a reissue of a complete specification and shall be prepared, issued,
and identified in the same manner as the specification that it
supersedes, except that the identification number shall be followed
by an appropriate revision letter. Letters shall be assigned in
alphabetical order for each succeeding revision. Revision letter
'A' shall be assigned to the first revision. Each revision
shall incorporate all outstanding approved changes against the
previous issue as well as approved changes proposed by the SCN
that creates the need for revision. Revisions of specification
will include symbols in the right hand margins of the pages to
indicate where changes have been made with respect to the prior
issue, including changes. The following note will be included
in the Notes, Section 6, of the specifications:.

'The margins of this specification are marked
with a (symbol) to indicate where changes (additions, modifications,
corrections, deletions) from the previous issue were made. This
was done as a convenience only and the Government assumes no liability
whatsoever for any inaccuracies in these notations. Bidders and
contractors are cautioned to evaluate the requirements of this
document based on the entire content irrespective of the marginal
notation and relationship to the last previous issue.'.

The following note may be used in lieu of the above,
if applicable..

'Symbols are not used in this revision to identify
changes with respect to the previous issue, due to the extensiveness
of the changes.'.

Specification revisions shall be issued in the same
manner as the original issue and do not require an SCN for promulgation
(see 6.2)..

=head1 4.0 GENERAL REQUIREMENTS FOR SECTIONS
OF SPECIFICATIONS

=head2 4.1 Specification 1 - SCOPE.

General information
pertaining to the extent of applicability of a configuration item,
material or process covered by a given specification and, when
necessary, specific detailed classification thereof, shall be
placed in the appropriate subdivision of Section 1 of specifications.
However, this section shall not contain requirements properly
part of other sections of the specification..

=head2 4.1.1 Scope.

A statement of the scope shall consist
of a clear, concise abstract of the coverage of the specification
and may include, where necessary, information as to the use of
the configuration item other than specific detailed applications
covered under 'Intended use' in Section 6 of the specification.
This brief statement shall be sufficiently complete and comprehensive
to describe generally the configuration item, material or process
covered by the specification in terms that may be easily interpreted
by manufacturers, contractors, suppliers, or others familiar with
applicable terminology and trade practices. As applicable, reference
may be made to information contained in Section 6 of the specification..

=head2 4.1.2 Classification.

Where a specification covers

more than one category of a configuration item, designations of
classification such as types, grades, classes, etc. shall be listed
under this heading and shall be in accordance with accepted industry
practice. The same designation shall be used throughout the specification.
The name of the configuration item covered by the specification
shall be followed by the words 'shall be of the following
types, grades, classes, etc., as specified', listing only
the applicable designations. When more than one type, grade, class,
etc., is listed, each shall be briefly defined. When only one
(type, grade or other) is covered, a statement to this effect
shall be included in the scope paragraph, and the classification
paragraph omitted. The types, grades, classes, etc., shall not
change when the specification is changed or revised except when
industry practice changes, or for other good reason a change is
required. Where the characteristics of a configuration item change
enough to affect inter- changeability, the original designation
shall be deleted and a new type, grade, class, etc. shall be added.
Whenever it becomes necessary to change the designation without
changing the characteristics of the configuration item, a cross
reference shall be included in Section 6 indicating the relationship
between the new and old designations. Since such changes may require
cataloging and other record changes, such changes shall be kept
to a minimum..

=head2 4.1.2.1 Classification definitions.

For the purpose
of preparing specifications, 'type,' 'class,'
'grade,' 'composition,' and 'style'
are defined as indicated below. However, the actual classification

used in a specific specification will be in accordance with accepted
practice as indicated in 4.1.2..

=head2 4.1.2.1.1 Type.

This term implies differences in
like configuration items or processes as to design, model, shape,
etc., and generally will be designated by Roman numerals, thus
'type I,' etc..

=head2 4.1.2.1.2 Class.

This term provides additional categorization
of differences in characteristics other than afforded by type
classification that do not constitute a difference in quality
or grade; but are for specific, equally important uses, and generally
will be designated by Arabic numerals; thus; 'class 1,'
'class 2,' etc..

=head2 4.1.2.1.3 Grade.

This term implies differences in
quality of a configuration item and generally will be designated
by capital letters; thus 'grade A,' 'grade B,'
etc..

=head2 4.1.2.1.4 Composition.

This term is used in classifying
configuration items that are differentiated strictly by their
respective chemical composition, and generally will be designated
in accordance with accepted trade practice when satisfactory to
the Government design agency..

=head2 4.1.2.1.5 Style.

This term is used to denote differences
in design or appearance..

=head2 4.1.2.1.6 Other classifications.

If the terms `types,'
`grades,' and `classes' do not serve accurately to classify the
differences as indicated above, other terms such as color, form,
weight, size, power supply, temperature rating, condition, unit,
enclosure, rating, duty, insulation, kind, variety, etc., suitable
for reference, may be used..

=head2 4.1.2.2 

Classification for reliability level identification.
When a specification contains a multilevel reliability requirement,
Section 1 of the specification shall identify the levels covered.

=head2 4.2 Section 2 - APPLICABLE DOCUMENTS.

All and only
those documents referenced in Section 3, 4, 5 and Appendixes of
the specification shall be listed in Section 2 of the specification.
If numerous, Section 2 may reference an appendix or other appropriate
document containing a complete listing. References shall be confined
to documents currently available at the time of issuance of the
current revision of the specification. Figures bound integrally
with the specification shall not be listed in Section 2..

=head2 4.2.1 Government documents.

Federal and military
specifications (as well as Government design agency specifications),
standards, drawings, and other Government publications may be
referenced in specifications. Government regulations or codes
that are mandatory on the military services (such as: Federal
Insecticide, Fungicide, and Rodenticide Act; Drug and Cosmetic
Act; Federal Hazardous Substances Labeling Act; Atomic Energy
Act; Department of Transportation Regulations; and Screw-Thread
Standards for Federal Services) shall be referenced in specifications,
where applicable..

=head2 4.2.2 Non-Government documents.

Reference may be
made to non-Government specifications, standards, and publications
promulgated by commercial organizations, technical societies and
other non-Governmental agencies when such documents are accepted
by the using Governmental agency. Care shall be taken in referencing
non-Governmental publications so as to assure the availability
of copies and prior approval of the copyright owner..

=head2 4.2.3 Listing of references.

References shall be
listed by document numbers and titles, and may include specific
issue or revision where necessary to rigidly control the configuration
or implementation of the configuration item, material or process.
The title of each document shall be that appearing on the document
itself rather than that shown in an index..

=head2 4.2.3.1 Government documents.

Government SPECIFICATIONS
STANDARDS, DRAWINGS, and other PUBLICATIONS intended to be made
available to bidders shall be listed under the appropriate preceding
headings and in alphabetical-numerical order in individual groups,
such as Federal, Military, and Departmental agency (such as Weapons
Command, etc.). These listings shall be included under a paragraph
similar to one of the following:.

Example 1:.

2.1 Government documents. The following documents
of the issue in effect on date of invitation for bids or request
for proposal, form a part of the specification to the extent specified
herein..

Example 2:.

2.1 Government documents. The following documents
of the exact issue shown form a part of this specification to
the extent specified herein. In the event of conflict between
the documents referenced herein and the contents of this specification,
the contents of this specification shall be considered a superseding
requirement..

Government documents shall be listed in the following
order:.

SPECIFICATIONS:

Federal

Military

Other Government Agency

STANDARDS:

Federal

Military

Other Government Agency

DRAWINGS:

(Where detailed drawings referred to in a specification
are listed on an assembly drawing, it is only necessary to list
the assembly drawing.)

OTHER PUBLICATIONS:

Manuals

Regulations

Handbooks

Bulletins

etc.

(Copies of specifications, standards, drawings, and
publications required by suppliers in connection with specified
procurement functions should be obtained from the contracting
agency or as directed by the contracting officer).

=head2 4.2.3.2. Non-Government documents.

Non-Government
documents shall be listed in appropriate order under a paragraph
similar to one of the following subparagraphs:

Example 1:

2.2 Non-Government documents. The following documents
form a part of this specification to the extent specified herein.
Unless otherwise indicated the issue in effect on date of invitation
for bids or request for proposal shall apply.

Example 2:

2.2 Non-Government documents. The following documents
of the exact issue shown form a part of this specification to
the extent specified herein. In the event of conflict between
the documents referenced herein and the contents of this specification,
the contents of the specification shall be considered a superseding
requirement.

Non-Government documents shall be listed in the following
order:

SPECIFICATIONS:

STANDARDS:

DRAWINGS:

OTHER PUBLICATIONS:

(list source for all documents not available through
normal Government stocking activities.)

The following source paragraph shall be placed at
the bottom of the list when applicable.

'Technical society and technical association
specifications and standards are generally available for reference
from libraries. They are also distributed among technical groups
and using Federal agencies.'



=head2 4.3 Section 3 - REQUIREMENTS.

The essential requirements
and descriptions that apply to performance, design, reliability,
personnel subsystems, etc. of the configuration item, material
or process covered by the specification shall be stated in this
section. These requirements and descriptions shall define as applicable,
the character or quality of the materials, formula, design, construction,
performance, reliability, transportability, and product characteristics,
chemical, electrical, and physical requirements, dimensions, weight,
color, nameplates, product marking, workmanship, etc. This section
is intended to indicate, as definitively as practicable, the minimum
requirements that a configuration item, material or process must
meet to be acceptable. The Requirements section shall be so written
that compliance with all requirements will assure the suitability
of the configuration item, material or process for its intended
purpose, and non-compliance with any requirement will indicate
unsuitability for the intended purpose. Only those requirements
shall be specified that are necessary and practicably attainable.

=over 4

=item 1

Section 3 of a general specification shall
contain all requirements that are common to a family of systems,
configurations items, materials or processes. When detail specifications
are to be prepared to supplement the general specification to
fully define an individual configuration item, etc., the following
paragraph shall be included in Section 3 of the general specification:

3.x.x Detail Specification. Requirements for individual
(insert the proper term from among the following) parts, configuration
items, materials, process, systems shall be as specified herein
and in accordance with the applicable detail specification.

=item 2

Section 3 of a detail specification shall
contain the requirements only for the particular system, configuration
item, material or process covered by that specification. However,
if the specification does cover more than one type, class, grade,
etc., it should first specify the general requirements for all
types, classes, grades, etc. The differentiating requirements
may then be specified for the individual types, classes, grades,
etc., in the proper sequence. In general, each requirement shall
be covered in a separate paragraph; and where one requirement
differs for the various types, classes, grades, etc., a separate
paragraph immediately following the general requirements shall
be devoted to each type, class, grade, etc. The various detailed
requirements shall be contained in appropriate subparagraphs.
Where it is necessary to include additional data, descriptive
and appropriate headings shall be used and assigned in logical
order.

=item 3

Section 3 of system or development specifications
(Type A or B) shall set forth requirements in terms or performance,
reliability, design constraints, functional interfaces, etc.,
that are necessary to assure a practical and reasonable development
effort. Development specifications may include design goals in
addition to minimum requirements, but in such case, goals and
requirements shall be clearly identified to avoid confusion. Only
essential design constraints shall be included as requirements,
such as restriction of use of certain materials due to toxicity,
dimensional or functional restrictions to assure compatibility
with associated equipments, etc.

=item 4

Section 3 of a product, process or material
specification (Type C,D,E) shall contain all requirements necessary
to assure delivery of an acceptable end product. Requirements
in product function specifications shall include both physical
(dimensional and interface characteristics) and performance requirements
in sufficient detail to assure procurement of interchangeable,
but not necessarily identical HWCIs. Requirements in a product
fabrication specification shall include all requirements necessary
to assure delivery of identical HWCIs from suppliers. This is
normally accomplished by invoking a set of drawings (DOD-D-1000
Level 3) as a primary requirement. Product fabrication specification
requirements may also set forth requirements for performance,
reliability, workmanship, etc., when such features or characteristics
are not completely controlled by detail drawings.

=back

=head2 4.3.1 Definition.

Where applicable, a definition
of the system or configuration item shall be provided in the form
of a brief description, and shall: identify major physical parts,
functional areas and functional and physical interfaces; and shall
include system logic diagrams, block diagrams, schematic diagrams,
and pertinent operational, organizational and logistic considerations
and concepts.

=head2 4.3.2 Characteristics.

Development, product and material
specifications, shall specify all required performance characteristics,
physical characteristics, and requirements for reliability, maintainability,
environmental consideration, and, as appropriate, relative priority
of design disciplines or characteristics.

=head2 4.3.2.1

Performance characteristics. These characteristics
shall include general and detail requirements, under appropriate
sub-headings, for all performance requirements, i.e., what is
expected of the system, configuration item, or material.

=head2 4.3.2.2 Physical characteristics.

These characteristics
in a development, product, or material specification shall set
forth requirements such as weight limits, dimensional limits,
etc., necessary to assure physical compatibility with other elements
and not determined by other design and construction features or
referenced drawings. They shall also include considerations such
as transportation and storage requirements, security criteria,
durability factors, health and safety criteria, command control
requirements, and vulnerability factors.

=head2 4.3.2.2.1 Protective coating.

Where applicable, protective
coating requirements shall be specified under this heading to
assure protection from corrosion, abrasion, or other deleterious
action. Where feasible, color and protective coating should be
combined.

=head2 4.3.2.3 Reliability. 

Reliability requirements shall
be stated numerically with confidence levels, if appropriate,
in terms of mission success or hardware mean time between failures.
Initially, reliability may be stated as a goal and a lower minimum
acceptable requirement. During contract definition, or equivalent
period, realistic requirements shall be determined and incorporated
in the specification with requirements for demonstration. Reliability
requirements shall never be stated as a goal in Type C (product)

specifications.

=head2 4.3.2.4 Maintainability. 

Numerical maintainability
requirements shall be stated in such terms as mean-time-to- repair
(MTTR) or maintenance man-hours per flight/operational hour. Determination
of realistic requirements shall be made as discussed in 4.3.2.3
for reliability. Qualitative requirements for accessibility, modular
construction, test points, and other design requirements may be
specified as required.

=head2 4.3.2.5 Environmental conditions. 


Environments that
the system or equipment is expected to experience in shipment,
storage, service, and use shall be specified. Where applicable,
it shall be specified whether the equipment will be required to
meet or be protected against specified environmental conditions.
Subparagraphs shall be included as necessary to cover environmental
conditions such as: climate, shock, vibration, noise, noxious
gases, etc.

=head2 4.3.2.6 Transportability.

Any special requirements
for transportability and materials handling shall be specified
under this heading.

=head2 4.3.3 Design and construction.

Minimum or essential
requirements that are not controlled by performance characteristics,
interface requirements, or referenced documents shall be specified.
They shall include appropriate design standards, requirements
governing the use or selection of materials, parts and processes,
interchangeability requirements, safety requirements, and the
like.

=head2 4.3.3.1 Materials. 

Requirements for materials to
be used in the item or service covered by the specification shall
be stated under this heading, except where it is more practicable
to include the information in other paragraphs. Requirements of
a general nature should be first, followed by specific requirements
for the material. Definitive documents shall be referenced for
the material when such documents cover materials of the required
quality.

=head2 4.3.3.1.1 Toxic products and formulations.

Specifications
requiring or permitting toxic products and formulations shall
demand compliance with the requirements of the applicable regulations
promulgated by the appropriate Federal regulatory agency or the
official compendia governing such products and formulations.

=head2 4.3.3.2. Electromagnetic radiation.

Where applicable,
requirements pertaining to electromagnetic radiation shall be
stated in terms of the environment which the item must accept
and the environment which it generates.

=head2 4.3.3.3. Nameplates or product markings.

The nameplate
or markings in some cases may be the only means of identification
of a product after delivery. Such identification is important
from the standpoint of stock, replacements, and repair parts.
All requirements pertaining to nameplates or markings shall be
placed under this, or other appropriate heading, referencing applicable
specifications (e.g., MIL-STD-130), drawings, or standards.

=head2 4.3.3.4 Workmanship. 

Where applicable, reference
to workmanship shall be stated and shall include the necessary
requirements relative to the standard of workmanship desired,
uniformity, freedom from defects, and general appearance of the
finished product. This paragraph is intended to indicate as definitively
as practicable the standard of workmanship quality that the product
must meet to be acceptable. The requirements shall be so worded
as to provide a logical basis for rejection in those cases where
workmanship is such that the time is unsuitable for the purpose
intended. Generally, no definite tests other than visual examination
of workmanship will be applicable to the requirements of this
paragraph.

=head2 4.3.3.5 Interchangeability.

This paragraph shall
specify the requirements for the level at which components shall
be interchangeable or replaceable. Entries in this paragraph are
for the purpose of establishing a condition of design, and are
not to define the conditions of interchangeability that are required
by the assignment of a part number.

=head2 4.3.3.6 Safety.

This paragraph shall specify requirements
to preclude or limit hazard to personnel, equipment, or both.
To the extent practicable, these requirements shall be imposed
by citing established and recognized standards. Limiting safety
characteristics peculiar to the item due to hazards in assembly,
disassembly, test, transport, storage, operation or maintenance
shall be stated when covered neither by standard industrial or
service practices nor the system specification. 'Fail-safe'
and emergency operating restrictions shall be included when applicable.
These shall include interlocks and emergency and standby circuits
required to either prevent injury or provide for recovery of the
item in the event of failure.

=head2 4.3.3.7 Human engineering. 

Human engineering requirements
for the system/configuration item should be specified herein and
applicable documents (e.g., MIL-STD-1472) included by reference.
This paragraph should also specify any special or unique requirements,
e.g., constraints on allocation or functions to personnel, and
communications and personnel/ equipment interactions. Included,
should be those specified areas, stations, or equipment that require
concentrated human engineering attention due to the sensitivity
of the operation or criticality of the task, i.e., those areas
where the effects of human error would be particularly serious.

=head2 4.3.4 Documentation.

Where applicable, requirements
for documenting the design shall be specified in general terms
in development specifications. Requirements shall specify types
of documents required for design review and approval, manufacture
or procurement, testing, inspection installation, operation, maintenance,
and logistic support as appropriate. This paragraph is not intended
as a requirement for procurement or delivery of data, which shall
be accomplished by use of DD Form 1423.

=head2 4.3.5 Logistics.

Where applicable, logistic considerations
and conditions that will apply to the system or configuration
item shall be specified in development specifications and, if
applicable, in product specifications. Logistic conditions such
as maintenance considerations, modes of transportation, supply
system requirements, and impact on existing facilities and equipments
shall be considered.

=head2 4.3.6 Personnel and training.

Where applicable, requirements
imposed by or limited by personnel or training considerations
shall be specified in development specifications. Training considerations
shall include existing facilities, equipment, special/emergency
procedures (associated with hazardous tasks) and training simulators,

as well as the need for additional facilities, equipment, and
simulators.

=head2 4.3.7 Characteristics of subordinate elements.

Subsequent
paragraphs shall be added as necessary to system, development,
or product specifications to specify requirements for subordinate
elements of the subject system or configuration item. Requirements
for each selected subordinate element shall be grouped under a
major heading titled with the name of the subordinate element
and shall include all of the pertinent types of requirements discussed
in previous paragraphs for the parent system or configuration
item. Requirements imposed directly on the subelement by a requirement
on the parent system or configuration item shall not be repeated.
Allocation or apportionment of a parent system (or configuration
item) requirement may be specified for the subelement. Subelements
may be functionally or physically integrated portions of the parent
system (or configuration item), but would not usually be both
in a single specification.

=head2 4.3.8 Precedence. 

A paragraph shall specify the order
or precedence of requirements; such as, specification over drawings,
functional requirements over physical requirements, adherence
to specified processes over other requirements, etc. The paragraph

shall also require that the contractor notify the contracting
agency of each instance of conflicting, or apparently conflicting,
requirements.

Alternatively, this paragraph may specify that the
requirements of the specification shall take precedence over referenced
documents. In system or development specifications, this paragraph
shall specify the relative importance of requirements (or goals)
to be achieved by the design.

=head2 4.3.9 Qualification.

Qualification, as used in this
Standard, refers to the verification or validation of item performance
in a specific application. This qualification results from design
review, test data review, and configuration audits. Where performance
qualification of a design or an end configuration item (including
its components) is required, either on a one-time basis or a periodic
basis, to achieve design approval, proof of producibility, assessment
of production or other reason, provisions for such qualification
testing shall be stated in this paragraph. Requirements shall
be included which state the conditions for testing, the time (program
phase) of testing, period of testing, number of units to be tested,
and other requirements relating to qualification or requalification.

Qualification, as used in Defense Standardization
Manual 4120.3-M, refers to the testing or review of test data
to judge configuration items from various sources as being suitable
for general application, and is intended to lead to the establishment
of a Qualified Products List (QPL). Therefore, this type of qualification
is subject to the provisions of Manual 4120.3-M and is not within
the scope of this Standard.


=head2 4.3.10 Standard sample.

A standard sample is one
considered essential to supplement or illustrate certain requirements
of the specification. Use of standard samples should be kept to
a minimum, since their use can create problems in determining
the acceptability of HWCIs subsequently produced. Adequate inspection
requires that all requirements be made available such as the approved
tolerances of dimensions, performance, etc. A standard sample
does not provide all this information but must be supported by
specification requirements and drawings. The use of the standard
sample shall be limited to the illustration of qualities and characteristics
that cannot be readily described because detailed test procedures
or design data are not available, or because certain qualities
and characteristics cannot be definitely expressed, such as the
texture of fur, the color of cloth, or the grain of wood. Further,
the specification should state the specific characteristics and
the degree to which these characteristics are to be observed in
the standard sample. When a standard sample is to be furnished,
it shall be so stated in Section 3. Means of obtaining or viewing
standard samples shall be specified in Section 6.

=head2 4.3.11 Preproduction sample, periodic production
sample, pilot, or pilot lot.

Where it is essential that a preproduction
or periodic production sample, a pilot model, or a pilot lot be
tested for design approval prior to or during regular production
on a contract or order, the requirements shall be specified in
this section under the appropriate paragraph identification.

=head2 4.4. Section 4 - QUALITY ASSURANCE PROVISIONS.


For software, this section shall be titled Qualification Requirements
and shall specify the qualification requirements, including methods,
levels of testing, tools, facilities, test formulas, algorithms,
and acceptance tolerance limits required to show that the requirements
stated in Section 3 and 5 have been met. The Software Requirements
and Interface Requirements Specification Data Item Descriptions

contain further information for specifying qualification requirements
(See 6.2). For software embedded in firmware devices, the application
of quality assurance provisions or requirements depends on whether
the software is designated as a CSCI or part of an HWCI. When
the software is designated as a CSCI, Qualification Requirements
apply, but when designated as part of an HWCI, Quality Assurance
Provisions apply. For hardware, this section shall include all
of the examinations and tests (by reference where applicable)
to be performed in order to ascertain that the product, material
or process to be developed or offered for acceptance conforms
to the requirements in Sections 3 and 5 of the specification.
Section 4 shall be arranged in an orderly sequence which will
indicate clearly which inspections (examinations and tests) apply
directly to the process, material, HWCIs, or lots of HWCIs that
were developed or produced and which apply to requirements such
as evaluation, qualification (See 4.3.9), preproduction sample,
pilot model, or pilot lot. The order of presentation of Section
4 material shall, insofar as practicable, follow the order of
requirements as presented in Section 3 of the specification, or
alternatively in the most logical order of conducting the examinations
and tests listed.

=head2 4.4.1 General.

Where applicable, the general test
and inspection philosophy shall be described with a statement
of responsibility for inspection, classification of examinations
and tests, sampling, lot formation, and other information pertinent
to the quality assurance provisions but not directly associated
with a specific test or examination.

=head2 4.4.1.1 Responsibility for inspection.

The DOD concept
of quality assurance places primary responsibility for quality
assurance of delivered products, materials or services on the
supplier who is responsible for offering to the contracting agency
only those products, materials or services that conform to all
specified requirements. In system specifications, however, where
assembly of the system/subsystem is at a Government facility or
on a Government-owned vessel involving Government-furnished property
and personnel, responsibility for the conduct of tests will probably
be split between the contracting agency and the contractor. Accordingly,
the supplier's responsibility for inspection shall be clearly
stated and the contracting agency's role, either as a partner
or monitor, shall be specified. A typical statement of responsibility
is as follows:

=head2 4.1.1 Responsibility for inspection.

Unless otherwise
specified in the contract or order, the supplier is responsible
for the performance of all inspection requirements as specified
herein. Except as otherwise specified, the supplier may utilize
his own facilities or any commercial laboratory acceptable to
the contracting agency. The contracting agency reserves the right
to perform any of the inspections set forth in the specification
where such inspections are deemed necessary to assure supplies
and services conform to prescribed requirements.

=head2 4.4.1.2 Special tests and examinations.

Any special
tests and examinations or associated actions required for sampling,
lot formation, qualification evaluation, etc., shall be covered
under an appropriate heading, for example:

=head2 4.1.2 Preproduction sample, pilot model, or pilot
run.

When Section 3 specifies a requirement for preproduction
sample, pilot model, or pilot run, Section 4 shall include under
an appropriate identification, a description of the testing routine,
sequence of tests, number of units to be tested, data required,
and the criteria for determining conformance to specified requirements.

=head2 4.1.2 Qualification provisions.

When the requirements
for HWCIs covered in Section 3 contain a qualification provision,
the applicable examinations and tests shall be listed under appropriate
headings in Section 4.

These inspections shall be specified for initial
and higher levels (reliability levels) of qualification including
the test methods for continuous testing, and periodic qualification
re-evaluation as covered in Section 3 of the specification.

When a tabular form of presentation will provide
a better understanding of the correlation between tests of Section
4 and requirements of Section 3, or would clarify the test requirements
for acceptance, performance, qualification, preproduction, etc.,
a tabular presentation similar to that below shall be made.

 Test Procedure

 Requirement Pre-Prod Acceptance Periodic Prod

 3.3.1   4.2.1 4.2.1 4.2.1 3.3.2.1 4.2.2.1 3.3.2.2 4.2.2.2
 4.2.2.1 4.2.2.1 3.3.2.3 4.2.2.3 3.3.2.4 4.2.2.3 4.2.2.3 4.2.2.3
 3.3.3.1 4.2.3.1 4.2.3.1 4.2.3.1 3.3.3.2 4.2.3.2 5.2.1 4.2.5

=head2 4.4.2 Quality conformance inspections.

This section
shall list all examinations and tests required to verify that
all requirements of Section 3 and 5 have been achieved in the
HWCI, material, or process offered for acceptance. These examinations,
and tests shall include, or reference as appropriate:

=over 4

=item 1

Tests and checks of the performance and reliability
requirements.

=item 2

A measurement of comparison of specified physical
characteristics.

=item 3

Verification, with specific criteria, for
workmanship.

=item 4

Test and inspection methods for assuring compliance,
including environmental conditions for performance.

=item 5

Classification of characteristics as critical,
major or minor, as defined in MIL-STD-109. When required for reference
purposes in reporting inspection results, the characteristics
may be numbered. When numbered, numbers shall be in accordance
with the following:
1 through 99 - critical characteristics
101 through 199 - major characteristics
201 through 299 - minor characteristics

=back

=head2 4.5 Section 5 - PREPARATION FOR DELIVERY.

This section
is generally applicable to product specifications only, and shall
include applicable requirements for preservation, packaging, and
packing the configuration item, and markings of packages and containers.

=head2 4.5.1 General.

This section shall state the general
requirements for preservation, packaging, packing, and package
marking. If more than one level of preservation and packaging
is included, the conditions for selection of levels shall be explained.
See FED-STD-102.

=head2 4.5.2 Specific requirements.

The specific requirements
for materials to be used in preservation, packaging, and packing
a product shall be covered in Section 5, either directly or by
reference to other specifications, publications, or drawings.

=head2 4.5.3 Detailed preparation.

Requirements may be included
by reference to other specifications and applicable standards
or, where these do not exist or are not applicable, by detailed
instructions. The requirements shall be included with appropriate
headings, as required, for disassembly, cleaning, drying, preservation,
packaging, packing, and shipment marking. These requirements shall
be specifically related to each required level of preparation
in a manner which will leave no doubt regarding requirements applicable
to such level. Detailed preparation for delivery requirements
should be covered as far as practicable in four basic categories,
as follows.

=head2 4.5.3.1 Preservation and packaging.

The requirements
for preservation and packaging shall cover cleaning, drying, and
preservation methods adequate to prevent deterioration, appropriate
protective wrapping, package cushioning, interior containers,
and package identification-marking up to but not including, the
shipping container. Where no suitable reference is available,
step-by-step procedures for preservation and packaging shall be
included.

=head2 4.5.3.2 Packing.

The requirements for packing shall
cover the exterior shipping container, the assembly of configuration
items or packages therein, necessary blocking, bracing, cushioning,
and weatherproofing.

=head2 4.5.3.3 Marking for Shipment.

Normally, marking requirements
shall be established by reference to MIL-STD-129. Markings essential
to safety and to the protection or identification of the configuration
item which are not required by MIL-STD-129, or are required on
a 'When specified' basis by that standard, shall be

specified in detail under this heading. In any instance where
reference to MIL-STD-129 is not applicable, requirements in detail
or by reference to recognized documents shall include: appropriate
identification of the product, both on packages and shipping containers;
all markings necessary for delivery and for storage, if applicable;
all markings required by regulations, statutes, and common carriers;
and all markings necessary for safety and safe delivery.

=head2 4.6 Section 6 - NOTES.

Section 6 of specifications
shall contain information of a general or explanatory nature,
and no requirements shall appear therein. It shall contain information,
not contractually binding, designed to assist in determining the
applicability of the specification and the selection of appropriate
type, grade, or class of the configuration item, such as additional
supersession data, changes in product designations (grades, class,
etc.), standard sample (if required), etc. This section should
include the following, as applicable, in the order listed:

 Intended use

 Ordering data

 Preproduction sample, pilot model, or pilot lot,
 if any

 Standard sample, if any

 Definitions, if any

 Qualification provisions

 Cross reference of classifications

Miscellaneous notes

=head2 4.6.1 Intended use.

Information relative to the use
of the configuration item covered by the specification should
be included under this heading. The difference among types, grades,
and classes in the specification shall be explained herein. If
particular applications exist for which the material is not well
adapted, this information also may be included.

=head2 4.6.2 Ordering data.

Detailed information to be incorporated
in invitations for bids, contracts, or other purchasing documents
shall be stated in this paragraph. Reference shall be made to
all parts of the specification where it is required that options
be exercised, such as requirements for preproduction sample for
qualification, selection of grade, type, class, level of preservation
and packaging, etc. When helpful, further information shall be
furnished.

=head2 4.6.3 Instructions for models and samples.

=head2 4.6.3.1 Instructions for preproduction sample, pilot
model, etc.

If Section 3 specifies a preproduction sample, a pilot
model, or a pilot lot, the necessary instructions for the arranging
for its examination, test, and approval shall be stated in this
section under an appropriate paragraph identification.

=head2 4.6.3.2 Standard sample.

If Section 3 specifies a
standard sample, information for obtaining or examining the standard
sample (source and address) shall be stated under this paragraph
identification.

=head2 4.6.4 Qualification provisions.

Where provisions
for qualification of a product is a requirement of the specification,
information concerning such qualification shall be stated in this
section.

=head2 4.6.5 Cross-reference of classifications.

A cross-reference
of old to new classification (types, grades, classes, etc.) of
configuration item, material or service shall be included if such
changes are made by specification revision. If new classes, grades
or types or configuration items or materials are being added to,
and others are being removed from, the coverage of the specification,
a cross-reference showing substitutability relationships shall
be included.

=head2 4.7 APPENDIX AND INDEX

=head2 4.7.1 General.

Where required, Appendixes and an
Index may be included as an integral part of a specification.

=head2 4.7.2 Appendix.

An appendix, identified by the heading
'APPENDIX', is a section of provisions added at the end of a specification.
An appendix may be used to append large (multi-page) data tables,
plans pertinent to the submittal of the configuration item, management
plans pertinent to the subject of the specification, classified
information or other information or requirement related to the
subject configuration item, material or process that would normally
be invoked by the specification but would, by its bulk or content,
tend to degrade the usefulness of the specification. In all cases
where an appendix is used, reference to the appendix shall be
included in the body of the specification.

=head2 4.7.2.1 Numbering.

Appendixes to a specification
shall be numbered as Sections 10, 20, etc. in multiples of 10
for each succeeding appendix. Divisions and paragraphs within
an appendix shall be numbered, such as 10.1, 10.1.1, etc. Page
numbers for the appendixes normally will be consecutive and in
sequential order with the page numbers used throughout the specification.
Each page of the appendix shall be identified with the specification
number as in the specification.

=head2 4.7.2.2 Scope.

An appendix shall have a statement
of scope to indicate the limitations of the appendix and to insure
its proper application and use.

=head2 4.7.2.3 Headings.

Headings should be used as necessary,
but need not duplicate the structure of the specification of which
the appendix is a part.

=head2 4.7.2.4 References.

References which may be required
and which relate to the appendix shall be listed in Section 2
of the basic specification and may also be listed in a section
of applicable documents in the appendix itself.

=head2 4.7.3 Index. 

An alphabetical index may be placed
at the end of a specification to permit ready reference to contents.
Its use shall be limited to lengthy specifications.

=head1 5.0 DETAIL REQUIREMENTS



=head2 5.1 General.

Detail requirements for the various
types and subtypes of specifications are contained in Appendixes
I through XV. Requirements for any configuration item, material,
or process that do not properly fall under a paragraph number
or title in the applicable appendix may be added as additional
paragraphs in the appropriate section. If the outline of the applicable
appendix is not made mandatory by contract provisions (Form 1a),
the additional paragraphs may be inserted at any point in the
proper section, and paragraph headings and numbers not applicable
may be omitted. If the outline of the applicable appendix is made
mandatory by contract provisions, additional necessary requirements
headings shall be inserted at the end of the proper section, except
for Types A and B1, where such requirements shall be inserted
between 3.6 and 3.7 (3.7 and subsequent paragraphs being suitably
renumbered), for requirements limited to a single functional area
or major component. The notation 'Not applicable' shall
be entered after each paragraph number and title that is not applicable.
Subordinate paragraph headings may be added under the most suitable
major paragraph heading in the outline prescribed by any appendix.

=head1 6.0 NOTES



=head2 6.1 Intended use.

This standard is to be used in
the establishment of uniform practices for specification preparation,
to ensure the inclusion of essential requirements, and to aid
in the use and analysis of specification content.

=head2 6.2 Data requirements list and cross reference.

When this standard is used in an acquisition which incorporates a DD
Form 1423, Contract Data Requirements List (CDRL), the data requirements
identified below shall be developed as specified by an approved
Data Item Description (DD Form 1664) and delivered in accordance
with the approved CDRL incorporated into the contract. When the
provisions of the DOD FAR clause on data requirements (currently
DOD FAR Supplement 52.227-7031) are invoked and the DD Form 1423
is not used, the data specified below shall be delivered by the
contractor in accordance with the contract or purchase order requirements.
Deliverable data required by this standard is cited in the following
paragraphs.

 Paragraph No.  Data Requirement Title                     Applicable DID

 3.3.1,         Notice of Revision/Specification           DI-E-1126
 3.3.2,         Change Notice
 3.3.2.1,
 3.3.2.3   


 3.1.1,                                                    DI-E-3102
 3.1.1.1, 
 3.1.1.2,
 3.1.3.2


 3.1.1.3,       Configuration Item Product Fabrication     DI-E-3103
 3.1.3.3,       Specification


 3.1.3.3.1,     Inventory Item Specification               DI-E-3105
 3.1.3.3.1.2,
 3.1.3.3.3
 3.1.3.3.4 


 3.3.2          Engineering Change Proposals               DI-E-3128


 3.1.1.3,       Process Specification                      DI-E-3130
 3.1.3.4


 3.1.1.3,       Material Specification                     DI-E-3131
 3.1.3.5


 3.1.1.3,       Configuration Item Product Specification   DI-E-3132
 3.1.3.3,       Function Specification Revision Pages      DI-E-21430
 3.1.3.3.1,     
 3.1.3.3.1.1,
 3.1.3.3.2,
 3.1.3.3.2.1
 3.3.1, 
 3.3.3 


 3.3.1,         Changes to General Specifications for      DI-E-23159
 3.3.2,         Ships 
 3.3.3


 3.1.1.3,       Critical Item Product                      DI-E-30132
 3.1.3.3,
 3.1.3.3.2,
 3.1.3.3.2.2 


 3.1.1.1,      Fabrication Specification System/Subsystem  DI-
 3.1.3.1,      Specification 
 50.3.1.2, 
 50.3.2

               Software Development Specification
               (consists of)

 3.1.3.2.5,    Software Requirements Specification          DI-MCCR-80025
 3.1.3.2.5.1, 
 3.1.3.2.5.2,
 3.1.3.3.5.1,
 4.4


 3.1.3.2.5,    Interface Requirements                       DI-MCCR-80026
 3.1.3.2.5.2,  Specification
 3.1.3.3.5.1,
 3.1.3.3.5.4,


 3.1.3.3.5,    Software Product Specification               DI-MCCR-80029 
 3.1.3.3.5,    (includes)
 3.1.3.3.5.1,  Software Design Description                  DI-MCCR-80012
 130.1


 3.1.3.3.5,    Software Design Description                  DI-MCCR-80031
 3.1.3.3.5.2, 
 130.1


 3.1.3.3.5,    Interface Design Description                 DI-MCCR-80027
 3.1.3.3.5.4, 
 130.1


 3.1.3.3.5,    Data Base Design Description                 DI-MCCR-80028
 3.1.3.3.5.3, 
 130.1

(Data item descriptions related to this standard,
and identified in section 6, will be approved and listed as such
in DOD 5000.19-L., Vol. II, AMSDL. Copies of data item descriptions
required by the contractors in connection with specific acquisition
functions should be obtained from the Naval Publications and Forms
Center or as directed by the contracting officer.)'

=head2 6.3 Changes from previous issue.

Asterisks or vertical
lines are not used in this revision to identify changes with respect
to the previous issue due to the extensiveness of the changes.

=head1 10.0 APPENDIX I - TYPE A, SYSTEM/SUBSYSTEM SPECIFICATION



=head2 10.1 Scope. 

The System/Subsystem Specification shall
be prepared in accordance with the System/Subsystem Specification
Data Item Description (see 6.2).

=head1 20.0 APPENDIX II - TYPE B1, PRIME ITEM DEVELOPMENT SPECIFICATION



=head2 20.1 Section 1, Scope. 

The content of Section 1 of
a prime item development specification shall be as defined in
the following example:

Example:

1. SCOPE

1.1 This specification establishes the performance,
design, development, and test requirements for the (insert nomenclature)
prime item.

=head2 20.2 Section 2, Applicable documents.

The content of Section 2 of the specification shall be in accordance with
4.2.

=head2 20.3 Section 3, Requirements.

This section shall contain the following:

=over 4

=item 1

The performance and design requirements for
the prime item.

=item 2

The performance requirements related to manning,
operating, maintaining, and logistically supporting the prime
item to the extent these requirements define or constrain design
of the prime item.

=item 3

The design constraints and standards necessary
to assure compatibility of prime item components.

=item 4

The principal interfaces between the prime
item being specified and other configuration items with which
it must be compatible.

=item 5

The major components of the prime item and
the principal interfaces between such major components. (Examples
of major components are: (a) a unit of an electronic set, (b)
an engine for a vehicle, (c) a power drive for a rocket or missile
launcher.)

=item 6

The allocation of performance to, and the
specific design constraints peculiar to, each major component.

=item 7

The identification and relationship of major
components which comprise the prime item.

=item 8

The identification and use of Government-furnished
property to be designed into and delivered with the prime item,
or to be used with the prime item.

=back

Unless purely descriptive by nature, requirements
shall be stated in quantitative physical terms with tolerances
which can be verified by subsequent analytical test, demonstrative
data, or inspection of the prime item and related supporting engineering
data. Requirements stated herein shall be the basis for, and verifiable
by the tests specified in Section 4 of the specification.

=head2 20.3.1 Paragraph 3.1, Prime item definition.

This paragraph shall incorporate (directly or by reference) specific
products of systems engineering and analysis which graphically
portray the functions of the prime item and the relationship of
the prime item to be developed to other configuration items in
the system. It shall identify (a) the major components of this
configuration item and (b) the individual components which must
be developed. Essentially, this is a translation of operational
requirements into item development tasks.

=head2 20.3.1.1 Paragraph 3.1.1, Prime item diagrams.

This paragraph shall incorporate, where applicable, either directly
or by reference, the prime item level functional schematics. This
paragraph will cover the top-level functional flow diagrams of
the configuration item and include diagrammatic presentations
to the level required to identify all essential functions.

=head2 20.3.1.2 Paragraph 3.1.2, Interface definition.

This paragraph shall cover the functional and physical interfaces between
(a) this prime item and other configuration items, and (b) the
major components within this prime item. The functional interfaces
shall be specified in quantitative terms of input/ output voltages,
accelerations, temperature ranges, shock limitations, loads, speeds,
pitch and roll rates, etc. Where interfaces differ due to a change
in operational mode, the requirements shall be specified in a
manner which identifies specific functional interface requirements
for each different mode. Physical interface relationships shall
be expressed in terms of dimensions with tolerances. This paragraph
shall incorporate, either directly or by reference, interface
control drawings, and other engineering data as necessary to define
all functional and physical interfaces required to make the prime
item compatible with other configuration items and to make its
major components compatible within the prime item.

=head2 20.3.1.3 Paragraph 3.1.3, Major component list. 

This paragraph shall include a complete list of all major components,
as they become known, which comprise the prime item with their
identification documents arranged in an indentured relationship.

=head2 20.3.1.4 Paragraph 3.1.4, Government furnished property list. 

This paragraph shall list the Government furnished property
which the prime item shall be designed to incorporate. This list
shall identify the property by reference to its nomenclature,
specification number, and/or part number.

=head2 20.3.1.5 Paragraph 3.1.5, Government loaned property
list.

This paragraph shall list the Government property which
will be loaned to the contractor.

=head2 20.3.2 Paragraph 3.2, Characteristics.



=head2 20.3.2.1 Paragraph 3.2.1, Performance. T

he performance
characteristics paragraph shall state what the prime item shall
do, including both upper and lower performance limits. As a general
guide include such considerations as:

=over 4

=item 1

Dynamic actions or changes that occur (rates,
velocities, movements, and noise levels).

=item 2

Quantitative criteria covering endurance capabilities
of the prime item required to meet user needs under stipulated
environmental and other conditions, including minimum total life
expectancy. Indicate required mission duration and planned utilization
rate.

=back

=head2 20.3.2.2 Paragraph 3.2.2, Physical characteristics.

This paragraph shall include the following as applicable:

=over 4

=item 1

Weight limits of the prime item.

=item 2

Dimensional and cube limitations, crew space,
operator station layout, ingress, egress, and access for maintenance.

=item 3

Requirements for transport and storage, such
as tiedowns, pallets, packaging, and containers.

=item 4

Durability factors to indicate degree of ruggedness.


=item 5

Health and safety criteria, including consideration
of adverse explosive, mechanical, and biological effects. Included
in these criteria are the toxicological effects of the prime item
or components thereof on the user and the adverse effects of any
electromagnetic radiation that might emanate therefrom. For prime
items with nuclear warheads, include general requirements as to
peacetime operations, troop safety in handling and firing, and
other considerations as required.

=item 6

Security criteria.

=item 7

Command control requirements.

=item 8

Vulnerability factors including consideration
of atomic, chemical, biological, and radiological operations,
electromagnetic radiation, fire and impact.

=back

=head2 20.3.2.3 Paragraph 3.2.3, Reliability. 

Reliability shall be stated in quantitative terms, defining the conditions
under which the requirements are to be met. This paragraph may
include a reliability apportionment model to support apportionment
of reliability values assigned to major components for their share
in achieving desired prime item reliability.

=head2 20.3.2.4 Paragraph 3.2.4, Maintainability.

This paragraph
shall specify the quantitative maintainability requirements. The
requirements shall apply to maintenance in the planned maintenance
and support environment and shall be stated in quantitative terms.

Examples are:

=over 4

=item 1

Time (e.g., mean and maximum downtime, reaction
time, turnaround time, mean and maximum time to repair, mean time
between maintenance actions).

=item 2

Rate (e.g., maintenance manhours per flying
hour, maintenance manhours per specific maintenance action, operational
ready rate, maintenance hours per operating hours, frequency of
preventive maintenance).

=item 3

Maintenance complexity (e.g., number of people
and skill levels, variety of support equipment).

=back

=head2 20.3.2.5 Paragraph 3.2.5, Environmental conditions.

This paragraph shall include both induced and natural environmental
conditions expected to be encountered by this prime item during
storage, shipment, and operation. It shall include factors such
as climate, shock, vibration, noise, and noxious gases.

=head2 20.3.2.6 Paragraph 3.2.6, Transportability. 

This paragraph shall include requirements for transportability which
are common to all components to permit employment and logistic
support. All components that, due to operational characteristics,
will be unsuitable for normal transportation methods shall be
identified.

=head2 20.3.3 Paragraph 3.3, Design and construction. 

This paragraph shall specify minimum prime item design and construction
standards which have general applicability and are applicable
to major classes of equipment (e.g., aerospace vehicle equipment
and support equipment) or are applicable to particular design
standards. To the maximum extent possible, these requirements
shall be specified by reference to the established military standards
and specifications. In addition, this paragraph shall specify
criteria for the selection and imposition of Federal, military,
and contractor specifications and standards.

=head2 20.3.3.1 Paragraph 3.3.1, Materials, processes, and
parts.

This paragraph shall specify those prime item-peculiar
requirements governing use of materials, parts, and processes
to be used in the design of the prime item. It shall also contain
specifications as necessary for particular materials and processes
to be utilized in the design of the prime item. Special attention
shall be directed to prevent unnecessary use of strategic or critical
materials, or toxic products and formulation. A strategic and
critical materials list can be obtained from the contracting agency.
In addition, requirements for the use of standard and commercial
parts for which qualified products lists have been established
shall be specified in this paragraph.

=head2 20.3.3.2 Paragraph 3.3.2, Electromagnetic radiation.

This paragraph shall contain requirements pertaining to electromagnetic
radiation. It shall cover both the environment in which the prime
item operates as well as that which it generates.

=head2 20.3.3.3 Paragraph 3.3.3, Nameplates and product
marking.

This paragraph shall contain requirements for nameplates,
part marking, serial and lot number marking, and all other identifying
markings required for the prime item and its component parts.
Requirements shall usually be stated in general terms and reference
made to existing standards on the content and application of such
markings.


=head2 20.3.3.4 Paragraph 3.3.4, Workmanship.

This paragraph
shall contain workmanship requirements for development models
of equipments to be produced during development, including requirements
for manufacture by production techniques, if applicable.

=head2 20.3.3.5 Paragraph 3.3.5, Interchangeability.

This paragraph shall identify those components to be interchangeable
and replaceable. Entries in this paragraph are for the purpose
of establishing a condition of design, and are not to define the
conditions of interchangeability that are required by the assignment
of a part number.

=head2 20.3.3.6 Paragraph 3.3.6, Safety.

This paragraph
shall specify requirements to preclude or limit hazards to personnel
and equipment. To the extent practicable, these requirements shall
be imposed by citing established and recognized standards. For
prime items directly supporting a system, appropriate paragraphs
of the system specification shall be cited, such paragraphs being
amended on 'add' or 'delete' basis for applicability
to the prime item. Limiting safety characteristics peculiar to
the prime item due to hazards in assembly, disassembly, test,
transport, storage, operation or maintenance shall be stated when
covered neither by standard industrial or service practices nor
by the system specification. 'Fail-safe' and emergency
operating restrictions shall be included where applicable. These
shall include interlocks and emergency and standby circuits required
to either prevent injury or provide for recovery of the prime
item in the event of failure.

=head2 20.3.3.7 Paragraph 3.3.7, Human performance/human
engineering.

Human engineering requirements for the configuration
item should be specified herein and applicable documents (e.g.,
MIL-STD-1472) included by reference. This paragraph should also
specify any special or unique requirements, e.g., constraints
on allocation of functions to personnel and communications and
personnel/equipment interactions. Included should be those specific
areas, stations, or equipment which would require concentrated

human engineering attention due to the sensitivity of the operation
or criticality of the task, i.e., those areas where the effects
of human error would be particularly serious.

=head2 20.3.4 Paragraph 3.4, Documentation.

This paragraph
shall specify the plan for prime item documentation such as: specifications,
drawings, technical manuals, test plans and procedures, installation
instruction data.

=head2 20.3.5 Paragraph 3.5, Logistics.



=head2 20.3.5.1 Paragraph 3.5.1, Maintenance.

This paragraph
shall include considerations such as: (a) use of multipurpose
test equipment, (b) use of module vs. part replacement, (c) maintenance
and repair cycles, (d) accessibility, and (e) level of repairability
by the Government.

=head2 20.3.5.2 Paragraph 3.5.2, Supply.

This paragraph
shall specify the impact of the prime item on the supply system
and the influence of the supply system on prime item design and
use. Considerations shall include: (a) introduction of new components
into the supply system, (b) supply and resupply methods, (c) distribution
and location of prime item stocks.

=head2 20.3.5.3 Paragraph 3.5.3, Facilities and facility
equipment.

This paragraph shall specify the impact of the prime
item on existing facilities and facility equipment. It also shall
specify requirements for new facilities or ancillary equipment
to support the prime item.

=head2 20.3.6 Paragraph 3.6, Personnel and training.

=head2 20.3.6.1 Paragraph 3.6.1, Personnel.

This paragraph
shall specify personnel requirements which must be integrated
into the prime item design. Requirements shall be specified in
a positive sense, assuming that the numbers and skill levels of
personnel will be made available. Requirements stated in this
paragraph shall be the basis for ultimate complete determination
of item personnel training and training equipment/facility requirements.
It shall include but not be limited to: number and types of operational
crew personnel for each deployment mode and the intended duty
cycles, both normal and emergency; numbers and types of maintenance
crew personnel for each operational deployment mode and the intended
duty cycle, both normal and emergency; and types and total number
of personnel which may be allocated to the operation, maintenance,
and control of the prime item. It should describe in general qualitative
terms the personnel resources expected to be available for the
scheduled beginning of training on the item.

=head2 20.3.6.2 Paragraph 3.6.2, Training.

This paragraph shall consider:

=over 4

=item 1

Training requirements that will be generated
by new equipment to include, if possible, the concept of how training
should be accomplished, e.g., school, unit, or contractor training.

=item 2

Estimates of quantities of equipment being
developed that will be required solely for training purposes.

=item 3

The need to develop associated training devices,
including types required. Prepare actual detailed statements of
requirements for characteristics of training devices.

=item 4

Training time and locations available for
effective training programs.

=back

=head2 20.3.7 Paragraph 3.7, Major component characteristics.

This paragraph shall include a subparagraph for each major component
listed in paragraph 3.1.3. In stating requirements for the various
major components, it should be recognized that verification may
necessarily need to be accomplished following the delivery, installation,
and checkout of the parts constituting the major components. The
functional relationship may be such that verification of requirements
specified for a major component can only be accomplished when
the units, assemblies, or parts which comprise the major component
are assembled into the prime item. For each major component, a
separate paragraph shall be prepared specifying the performance
and physical characteristics.

=head2 20.3.8 Paragraph 3.8, Precedence. 

This paragraph
shall either specify the order of precedence of requirements or
assign weights to indicate the relative importance of characteristics
and other requirements. These include requirements allocated from
prime item requirements as well as requirements which are peculiar
to the major component and cannot be directly referenced to prime
item requirements. It shall also establish the order of precedence
of this specification relative to referenced documents.

=head2 20.4 Section 4, Quality Assurance provisions.

Requirements for formal tests/verifications of prime item performance
and design
characteristics and operability shall be specified in this paragraph.
Tests/verifications specified herein shall include prime item
and component design evaluation and operational capability verification.
Subparagraphs under this section shall include:

=over 4

=item 1

Reliability testing with respect to prime
item and component reliability. Requirements shall be specified
for collection and recording of data during all testing which
is to be part of the reliability analysis.

=item 2

Engineering evaluation and test requirements
to the level of detail necessary to define the extent of the test
program and the objectives of the tests. The specific elements
to be included in the test shall be specified. If data generated
during the progress of tests specified herein is to be recognized
as formal verification that specified requirements in Section
3 of the specification have been satisfied, the test objectives
shall so state.

=item 3

Qualification testing of the prime item and
critical components.

=item 4

Installation testing and checkout, such as
continuity checking, interface mating, major component operation
in the installed environment, support equipment compatibility,
and documentation verification.

=item 5

Formal test verification of performance characteristics
to demonstrate that prime item requirements in Section 3 of the
specification have been satisfied.

=back

=head2 20.4.1 Paragraph 4.1, General.

This paragraph shall
discuss the philosophy of testing, location for performance of
tests, and other information related to prime item testing not
covered elsewhere.

=head2 20.4.1.1 Paragraph 4.1.1, Responsibility for tests.

This paragraph shall assign responsibilities for performance of
tests to each agency, Government or contractor, as applicable.

=head2 20.4.1.2 Paragraph 4.1.2, Special tests and examinations.

This paragraph is optional in the development specification, and,
when used, would generally cover testing requirements for qualification
evaluation for selection of parts, components, or equipments to
be used in the system.

=head2 20.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall cover, or reference, test and inspection
requirements necessary to determine if all requirements of Section
3 of the specification have been achieved. Insofar as practical,
tests shall be arranged in a logical order for sequential performance.

=head2 20.5 Section 5, Preparation for delivery.

This section shall provide guidance for the preparation of equipment
for delivery.
Such guidance will be peculiar to the prime item being specified
and other than standard practice. It shall include specific requirements
to incorporate such non-standard practices in appropriate item
descriptions. It may impose requirements to comply with standard
practices by referencing appropriate military specifications and
standards.

20.6 Section 6, Notes. The contents of this section
are not contractually binding. Any information which should be
made known as background information or as instructions to the
contracting officer may be included herein.

=head2 20.10 Section 10, Appendix I.

This section of the specification
shall contain requirements which are contractually a part of the
specification but which, for convenience in specification maintenance,
are incorporated herein; e.g., requirements of a temporary nature
or for limited effectivity. Appendixes may be bound as separate
documents for convenience in handling, e.g., when only a few parameters
of the prime item are classified, an appendix containing only
the classified material may be established. Where parameters are
placed in an appendix, the paragraph of Section 10 shall be referenced
in the main body of the prime item specification in the place
where the parameter would normally have been specified.


=head1 30.0 APPENDIX III - TYPE B2, CRITICAL ITEM DEVELOPMENT SPECIFICATION

=head2 30.1 Section 1, Scope.

The content of Section 1 of
a critical item development specification shall be a statement
similar to the following example:

Example:

1. SCOPE

1.1 This specification establishes the performance,
design, development, and test requirements for the (insert identifier
and nomenclature) critical item.

=head2 30.2 Section 2, Applicable documents.

The content
of Section 2 shall be in accordance with 4.2.

=head2 30.3 Section 3, Requirements.



=head2 30.3.1 Paragraph 3.1, Critical item definition.

This paragraph shall contain a comprehensive definition of the critical
item to be developed.

=head2 30.3.2 Paragraph 3.2, Characteristics.

=head2 30.3.2.1 Paragraph 3.2.1, Performance.

Performance characteristics paragraph shall state what the critical item shall
do, including both upper and lower performance limits. As a general
guide include such considerations as:

=over 4

=item 1

Dynamic actions or changes that occur (rates,
velocities, movements, and noise levels).

=item 2

Quantitative criteria covering endurance capabilities
of the critical item required to meet user needs under stipulated
environmental and other conditions, including minimum total life
expectancy. Indicate required mission duration and planned utilization
rate.

=back

30.3.2.2 Paragraph 3.2.2, Physical characteristics.
This paragraph shall include the following, as applicable:

=over 4

=item 1

Weight limits of the critical item.


=item 2

Dimensional and cube limitations, crew space,
operator station layout, ingress, egress, and access for maintenance.

=item 3

Requirements for transport and storage, such
as tie-downs, pallets, packaging, and containers.

=item 4

Durability factors to indicate degree of ruggedness.

=item 5

Health and safety criteria, including consideration
of adverse explosive, mechanical, and biological effects. Included
in this criteria are the toxicological effects of the critical
item on the user and the adverse effects of any electromagnetic
radiation that might emanate therefrom.

=item 6

Vulnerability factors including consideration
of atomic, chemical, biological, and radiological operations,
electromagnetic radiation, fire and impact.

=back

=head2 30.3.2.3 Paragraph 3.2.3, Reliability.

This paragraph shall state the requirements for reliability
in quantitative terms,
defining the conditions under which the requirements are to be
met.

=head2 30.3.2.4 Paragraph 3.2.4, Maintainability. 

This paragraph
shall specify the quantitative maintainability requirements. The
requirements shall apply to maintenance in the planned maintenance
and support environment and shall be stated in quantitative terms.

=head2 30.3.2.5 Paragraph 3.2.5, Environmental conditions.

This paragraph shall include both induced and natural environmental
conditions expected to be encountered by this critical item during
storage, shipment, and operation. It shall include factors such
as climate, shock, vibration, noise, and noxious gases.

=head2 30.3.2.6 Paragraph 3.2.6, Transportability.

This paragraph shall include requirements for transportability which
are common to all components to permit employment, deployment,
and logistic support. All components that, due to operational
or functional characteristics, will be unsuitable for normal transportation
methods shall be identified.

=head2 30.3.3 Paragraph 3.3, Design and construction.

This paragraph shall specify minimum critical item design and construction
standards which have general applicability and are applicable
to major classes of equipment (e.g., aerospace vehicle equipment,
support equipment) or are applicable to particular design standards.
To the maximum extent possible, these requirements shall be specified
by reference to the established military standards and specifications.
In addition, this paragraph shall specify criteria for the selection
and imposition of Federal, military, and contractor specifications
and standards.

=head2 30.3.3.1 Paragraph 3.3.1, Materials, processes, and
parts.

This paragraph shall specify those configuration item-peculiar
requirements governing use of materials, parts, and processes
to be utilized in the design of the critical item. It shall also
contain specifications as necessary for particular materials and
processes to be utilized in the design of the critical item. Special
attention shall be directed to prevent unnecessary use of strategic
or critical materials. A strategic and critical materials list
can be obtained from the contracting agency. In addition, requirements
for the use of standard and commercial parts for which qualified
products lists have been established shall be specified in this
paragraph.

=head2 30.3.3.2 Paragraph 3.3.2, Electromagnetic radiation.

This paragraph shall contain requirements pertaining to electromagnetic
radiation. It shall cover both the environment in which it operates
as well as that which it generates.

=head2 30.3.3.3 Paragraph 3.3.3, Nameplates and product
marking. 

This paragraph shall contain requirements for nameplates,
part marking, serial and lot number marking, and all other identifying
markings required for the critical item and its component parts.
Requirements shall usually be stated in general terms and reference
made to existing standards on the content and application of such
markings.

=head2 30.3.3.4 Paragraph 3.3.4, Workmanship.

This paragraph
shall contain workmanship requirements for development models
of critical items to be produced during development, including
requirements for manufacture by production techniques, if applicable.

=head2 30.3.3.5 Paragraph 3.3.5, Interchangeability.

This paragraph shall identify those components to be interchangeable
and replaceable. Entries in this paragraph are for the purpose
of establishing a condition of design, and are not to define the
conditions of interchangeability that are required by the assignment
of a part number.

=head2 30.3.3.6 Paragraph 3.3.6, Safety.

This paragraph
shall specify requirements to preclude or limit hazard to personnel
and equipment. To the extent practicable, these requirements shall
be imposed by citing established and recognized standards. Limiting
safety characteristics peculiar to the critical item due to hazards
in assembly, disassembly, test, transport, storage, operation
and maintenance shall be stated when covered neither by standard
industrial or service practices nor by a higher level specification.
'Fail safe' and emergency operating restrictions shall
be included when applicable. These shall include interlocks and
emergency and standby circuits required to either prevent injury
or provide for recovery of the critical item in the event of failure.

=head2 30.3.3.7 Paragraph 3.3.7, Human performance/human
engineering.

Human engineering requirements for the critical item
should be specified herein and applicable documents (e.g., MIL-STD-1472)
included by reference. This paragraph should also specify any
special or unique requirements, e.g., constraints on allocation
of functions to personnel and communications and personnel/equipment
interactions. Included should be those specific areas, stations,
or equipment which would require concentrated human engineering
attention due to the sensitivity of the operation or criticality
of the task, i.e., those areas where the effects of human error
would be particularly serious.

=head2 30.3.4 Paragraph 3.4, Documentation.

This paragraph shall specify the plan for critical item documentation such as:
specifications, drawings, technical manuals, test plans and procedures,
installation instruction data.

=head2 30.3.5 Paragraph 3.5, Logistics.




=head2 30.3.5.1 Paragraph 3.5.1, Maintenance.

This paragraph
shall include considerations such as: (a) use of multipurpose
test equipment, (b) use of module vs. part replacement, (c) maintenance
and repair cycles, (d) accessibility, and (e) level of repairability
by the Government.

=head2 30.3.5.2 Paragraph 3.5.2, Supply.

This paragraph
shall specify the impact of the critical item on the supply system
and the influence of the supply system on critical item design
and use. Considerations shall include: (a) introduction of new
components in the supply system, (b) supply and resupply methods,
(c) distribution and location of critical item stocks.

=head2 30.3.6 Paragraph 3.6, Precedence.

This paragraph
shall either specify the order of precedence of requirements or
assign weights to indicate the relative importance of characteristics
and other requirements. It shall also establish the order of precedence
of this specification relative to referenced documents.

=head2 30.4 Section 4, Quality Assurance provisions. 

Requirements for formal tests/verifications of critical item performance and
design characteristics and operability shall be specified in this
paragraph. Tests/verifications to be specified herein shall include
critical item and component design evaluation, and operational
capability verification. Subparagraphs under this section shall
include:

=over 4

=item 1

Reliability testing with respect to critical
item and component reliability. Requirements shall be specified
for collection and recording of data during all testing which
is to be part of the reliability analysis.

=item 2

Engineering evaluation and test requirements
to the level of detail necessary to define the extent of the test
program and the objectives of the tests. The specific elements
to be included in the test shall be specified. If data generated
during the progress of tests specified herein is to be recognized
as formal verification that specified requirements in Section
3 of the specification have been satisfied, the test objectives
shall so state.


=item 3

Qualification testing of the critical item
and selected components.

=item 4

Installation testing and checkout such as
checking, interface mating, support equipment compatibility, and
documentation verification.

=item 5

Formal test verification of performance characteristics
to demonstrate that critical item requirements in Section 3 have
been satisfied.

=back

=head2 30.4.1 Paragraph 4.1, General.

This paragraph shall
discuss the philosophy of testing, location for performance of
tests, and other information related to testing not covered elsewhere.

=head2 30.4.1.1 Paragraph 4.1.1, Responsibility for tests.

This paragraph shall assign responsibilities for performance of
tests to each agency, Government or contractor, as applicable.

=head2 30.4.1.2 Paragraph 4.1.2, Special tests and examinations.

This paragraph is optional in a development specification, and
when used, would generally cover testing requirements for qualification
evaluation for selection of parts, components, or equipments to
be used in the item.

=head2 30.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall cover, or reference, test and inspection
requirements necessary to determine if all requirements of Section
3 of the specification have been achieved. Insofar as practical,
tests shall be arranged in a logical order for sequential performance.

=head2 30.5 Section 5, Preparation for delivery.

This section
shall provide guidance for the preparation of the critical item
for delivery. Such guidance will be peculiar to the critical item
being specified and other than standard practice. It shall include
specific requirements to include such non-standard practices in
appropriate configuration item descriptions. It may impose requirements
to comply with standard practices by referencing appropriate military
specifications and standards.

=head2 30.6 Section 6, Notes.

The contents of this section
are not contractually binding. Any information which should be
made known as background information or as instructions to the
contracting officer may be included herein.

=head2 30.10 Section 10, Appendix I.

This section of the specification
shall contain requirements which are contractually a part of the
specification but which, for convenience in specification maintenance,
are incorporated herein, e.g., requirements of a temporary nature
or for limited effectivity. Appendixes may be bound as separate
documents for convenience in handling, e.g., when only a few parameters
of the critical item are classified, an appendix containing only
the classified material may be established. Where parameters are
placed in an appendix, the paragraph of Section 10 shall be referenced
in the main body of the critical item specification in the place
where the parameter would normally have been specified.

=head1 40.0 APPENDIX IV - TYPE B3, NON-COMPLEX ITEM DEVELOPMENT SPECIFICATION



=head2 40.1 Section 1, Scope.

The content of Section 1 of
a non- complex item development specification shall be as defined
in the following example.

Example:

1. SCOPE

1.1 This specification establishes the performance,
design, development, and test requirements for the (insert nomenclature)
non-complex item.

=head2 40.2 Section 2, Applicable documents.



The content
of Section 2 shall be in accordance with 4.2.

=head2 40.3 Section 3, Requirements.

=head2 40.3.1 Paragraph 3.1, Item Definition.

This paragraph
shall contain a brief description of the non-complex item and
shall, in general terms, state its purpose. For non-complex items
where the general characteristics are commonly known, the description
should consist of no more than the non-complex item name with
appropriate modifiers. Where the non-complex item is not commonly
recognized by its name, the description should consist of no more
than two or three brief sentences describing its principal characteristics.

=head2 40.3.2 Paragraph 3.2, Characteristics.

=head2 40.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall state what the non-complex item shall do including both
upper and lower performance limits.

=head2 40.3.2.2 Paragraph 3.2.2, Physical characteristics.

This paragraph shall include such physical requirements as necessary
to ensure form and fit, including weight, mounting and mating
dimensions, color, protective coating, etc.

=head2 40.4 Section 4, Quality assurance provisions.

(See 4.4)

=head2 40.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 40.6 Section 6, Notes.

(See 4.6)

=head1 50.0 APPENDIX V - TYPE B4, FACILITY OR SHIP DEVELOPMENT SPECIFICATION

=head2 50.1 Section 1, Scope.

The content of Section 1 of
a facility or ship development specification shall be as defined
in the following example:

Example:

1. SCOPE

1.1 This specification establishes the requirements
and basic constraints imposed on the development of an architectural
and engineering design for (insert nomenclature); add, 'in
support of (insert system nomenclature),' if applicable.

=head2 50.2 Section 2, Applicable documents.

The content of Section 2 shall be in accordance with 4.2.

=head2 50.3 Section 3, Requirements.

=head2 50.3.1 Paragraph 3.1, Facility or ship definition.

Describe in detail the mission of the facility or ship; describe
the flow of personnel, material, and functions to be performed
in or by the facility or ship, including time elements, etc; identify
the maintenance and logistics policies to be employed; establish
design useful life requirements; establish facility or ship self-sufficiency
requirements and any special survival requirements.

=head2 50.3.1.1 Paragraph 3.1.1, Facility or ship drawings.

For a facility, include topographical and geographical diagrams
as well as plot drawings, if applicable. For a ship, include preliminary
deck layouts and profiles, as well as schematic drawings, if applicable.
Functional diagrams should also be included, as well as equipment
layout and processing flow diagrams, if applicable.

=head2 50.3.1.2 Paragraph 3.1.2, Interface Definition.

Interfaces of the facility or ship with the system or functional areas of
the system will be defined by the system/subsystem specification
and those interfaces defined here must be consistent with the
system/subsystem specification. Both functional and physical interfaces
with other systems and between the major subsystems or components
of this facility or ship shall be defined in this paragraph.

=head2 50.3.1.3 Paragraph 3.1.3, Major subsystems and component
list.

This paragraph shall include a complete list of all subsystems
and major components which comprise the facility or ship, or are
required by the facility or ship to support the system. If necessary,
it shall include a specification tree or indentured listing showing
the relationships of the identification documents for the subsystems
and major components of the facility or ship.

=head2 50.3.2 Paragraph 3.2, Characteristics.

Wherever practicable,
characteristics shall be specified in terms of the facility or
ship itself and not by reference to equipment with which the facility
or ship must be compatible. The integrated performance and design
requirements shall be allocated from, identical with, or in recognition
of the requirements established by the system/subsystem specification.
The following represents an outline of specific information normally
required to define a facility or ship; however, it is not intended
that non-pertinent requirements be specified nor is it to be construed
as preventing the addition of such additional information as may
be required to properly identify the peculiar facility or ship
requirements. Facility characteristics shall include consideration
of the following, as necessary.

=over 4

=item 1

Civil

=over 4

=item 1

Axle or wheel loads on roads.

=item 2

Special lane width.

=item 3

Turn and weight provisions for special vehicles.

=item 4

Jack loads, transfer requirements.

=item 5

Parking (number of vehicles).

=item 6

Grades on roads, types pavement (flexible
or rigid), type walks (flexible or rigid).

=item 7

Special water and sewage requirements. Quantity
and nature of water and sewage, if special.

=item 8

Special fire protection requirements (exterior).

=item 9


Fencing and security.

=item 10

Location and types of existing utilities
if any (water, gas, sewer, electrical, storm drainage).

=back

=item 2

Architectural.

=over 4

=item 1

Personnel occupancy, types, hours per day.

=item 2

Designation of use of areas within facility.
Partition layout. Hazard areas. Special treatment areas.

=item 3

Types of special doors required.

=item 4

Floor level requirements. Floor drainage.

=item 5

Window requirements, if any.

=item 6

Controlling dimension requirements.

=item 7

Clear ceiling heights.

=item 8

Exterior architectural treatment (concrete,
masonry, brick, etc.). Indicate whether treatment is to match
existing, if applicable.

=item 9

Explosive safety requirements for construction.

=back

=item 3

Structural

=over 4

=item 1

Crane and hoist location and loads. Control
requirements.

=item 2

Floor and roof loads. Special loads, seismic
loads wind loads.

=item 3

Clear span and column-free areas.

=item 4

Blast loads, shielding requirements.

=item 5

Personnel ladders, elevators.

=item 6

Transfer piers, dock loads.

=item 7

General configuration of building, number
of stories.

=item 8


Barricades and shielding for explosive blast areas.

=back

=item 4

Mechanical

=over 4

=item 1

Interior potable water.

=item 2

Environment limits, temperature, humidity,
ventilation.

=item 3

Compressed air.

=item 4

Fire protection.

=item 5

Vibration and acoustical requirements.

=item 6

Equipment cooling requirements.

=back

=item 5

Electrical

=over 4

=item 1

Power requirements - types and magnitude.

=item 3

Light intensities.

=item 4

Communications requirements.

=item 5

Grounding.

=back

=item 6

Equipment (Provide layout and list each piece
of equipment):

=over 4

=item 1

Equipment name.

=item 2

Units required (number).

=item 3

Purpose of equipment.

=item 4

Size of equipment (governing dimensions, weight).

=item 5

Power requirements - heat gain, BUT's per
hour, type cooling, in-out temperatures, relative humidities.

=item 6

Minimum access requirements - front, back
sides.

=back

=back

Ship characteristics shall include the consideration
of the following as necessary.

=over 4

=item 1

General

=over 4

=item 1

Limiting dimensions

=item 2

Weight control

=item 3

Reliability and maintainability

=item 4

Environmental conditions

=item 5

Standardization and interchangeability

=item 6

Shock, noise, and vibration

=item 7

Navy or commercial marine standards, including
certification of the latter.

=back

=item 2

Hull structure

=over 4

=item 1

Structural loading and configuration

=item 2

Basic structural materials

=item 3

Welding, riveting and fastenings

=item 4

Access features

=back

=item 3

Propulsion plant

=over 4

=item 1

Type and number of propulsion units

=item 2

Type and number of propellers

=item 3

Propulsion control equipment

=back

=item 4

Electric plant

=over 4

=item 1

Type and number of generator units

=item 2

Power distribution system

=item 3

Lighting system

=back

=item 5

Communications and control

=over 4



=item 1

Navigation equipment

=item 2

Interior communication systems and equipment

=item 3

Electronics systems

=item 4

Weapon control systems

=back

=item 6

Auxiliary system

=over 4

=item 1

Air conditioning system

=item 2

Fuel systems

=item 3

Fresh and sea water systems

=item 4

Steering system

=item 5

Aircraft handling system

=item 6

Underway replenishment system

=item 7

Cargo handling system

=back

=item 7

Outfit and furnishings

=over 4

=item 1

Hull fittings, boat storage and rigging

=item 2

Painting, deck covering, and insulation

=item 3

Special stowages

=item 4

Workshops and utility spaces

=item 5

Living spaces and habitability

=back

=item 8

Armament

=over 4

=item 1

Guns and ammunition stowage and handling

=item 2

Ship-launched weapon systems

=item 3

Cargo munitions handling and stowage

=back

=back

=head2 50.3.3 Paragraph 3.3, Documentation.

Requirements
for documenting the design shall be specified in general terms.
Requirements shall specify the types of documents (such as specifications,
drawings, studies, and calculations) required for design review
and approval, for procurement, and for historical records.

=head2 50.4 Section 4, Quality assurance provisions.

This section shall identify special testing, quality control procedures,
and quality conformance inspections necessary to assure the adequacy
of special or unique facility or ship features.

=head2 50.5 Section 5, Preparation for delivery.

This section
is normally not applicable. But when used shall provide guidance
to the architect/engineer regarding any delivery preparation requirements
for the facility or ship.

=head2 50.6 Section 6, Notes.

The contents of this section
are not contractually binding. Any information which should be
made known as background information or instructions to the contracting
officer may be included herein.

=head2 50.10 Section 10, Appendix I.

(See 4.7)

=head1 60.0 APPENDIX VI - TYPE B5, SOFTWARE DEVELOPMENT SPECIFICATION

=head2 60.1 Scope.

This specification shall consist of the
Software Requirements Specification and the Interface Requirements
Specification(s). These specifications shall be prepared in accordance
with the Software Requirements Specification Data Item Description
and the Interface Requirements Specification Data Item Description
(see 6.2).

=head1 70.0 APPENDIX VII - TYPE Cla, PRIME ITEM PRODUCT FUNCTION SPECIFICATION

=head2 70.1 Section 1, Scope.

The content of Section 1 of
a prime item product function specification shall be as defined
in the following example:

Example:

1. SCOPE

1.1 This specification establishes the performance,
design, test, manufacture, and acceptance requirements for the
(insert nomenclature) prime item.

1.2 Classification. (when applicable, see 4.1.2)

=head2 70.2 Section 2, Applicable documents.

The content of Section 2 shall be in accordance with 4.2.

=head2 70.3 Section 3, Requirements.

=head2 70.3.1 Paragraph 3.1, Item definition.

This paragraph
shall contain a comprehensive definition of the functional characteristics
of the configuration item which is covered by this specification.
For a prime item which directly supports a system, the relationship
of the configuration item to the system shall be defined. This
paragraph shall identify the major components to be produced.

=head2 70.3.1.1 Paragraph 3.1.1, Prime item diagrams.

This paragraph shall incorporate functional schematic and flow diagrams.
Applicable layout drawing or other graphic portrayals which establish
the general relationship of major components shall be included.

=head2 70.3.1.2 Paragraph 3.1.2, Interface definition.

This paragraph shall cover the functional and physical interfaces between
(a) the prime item and other configuration items, and (b) the
major components within the prime item. The functional interfaces
shall be specified in quantitative terms of input/output voltages,
accelerations, temperature ranges, shock limitations, loads, speeds,
pitch and roll rates, etc. Where interfaces differ due to a change
in operational mode, the requirements shall be specified in a
manner which identifies specific functional interface requirements
with each different mode. Physical interface relationships shall
be expressed in terms of dimensions with tolerances. This paragraph
shall incorporate, either directly or by reference, interface
control drawings and other engineering data as necessary to define
all functional and physical interfaces required to make the prime
item compatible with other configuration items and to make its
major components compatible within the prime item.

=head2 70.3.1.3 Paragraph 3.1.3, Major component list.

This
paragraph shall include a complete list of all major components
which comprise the prime item. It shall include a specification
tree showing the indentured relationship among the components

making up the prime item.

=head2 70.3.1.4 Paragraph 3.1.4, Government-furnished property
list.

This paragraph shall list the Government furnished property
which the prime item shall be designed to incorporate or which
is required for prime item fabrication. This list shall identify
the property by reference to its nomenclature, specification number,
part number, and other pertinent identifiers.

=head2 70.3.2 Paragraph 3.2, Characteristics.

All characteristics
in Section 3 of the specification shall be capable of being measured
and such measurement will be the basis for the inspections of
Section 4 of the specification.

=head2 70.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall state what the prime item shall do in terms of complete
functional characteristics only and shall specify upper and lower
limits for each performance characteristic. These characteristics
shall be expressed as requirements that must be achieved, and
not as goals or best efforts.

=head2 70.3.2.2 Paragraph 3.2.2, Physical characteristics.

This paragraph shall include the following, as applicable:

=over 4

=item 1

Weight limits of the prime item.

=item 2

Dimensional and cube limitations, crew space,
operator station layout, ingress, egress, and access for maintenance.

=item 3

Requirements for transport and storage, such as
tiedowns, palletization, packaging, and containers.

=item 4

Durability factors to indicate degree of ruggedness.

=item 5

Health and safety criteria, including consideration
of adverse explosive, mechanical, and biological effects. Included
in this criteria are the toxicological effects of the prime item
or component thereof on the user and the adverse effects of any
electromagnetic radiation that might emanate therefrom. For prime
items with nuclear warheads, include general requirements as to
peacetime operations, troop safety in handling and firing, and
other considerations as required.

=item 6

Safety criteria.

=item 7

Command control requirements.

=item 8

Vulnerability factors including consideration
of atomic and chemical, biological, and radiological operations,
electromagnetic radiation, fire and impact.

=back

=head2 70.3.2.3 Paragraph 3.2.3, Reliability.

Reliability shall be stated in quantitative terms,
defining the conditions under which the requirements are to be
met. This paragraph may include a reliability apportionment model
to support apportionment of reliability values assigned to major
components for their share in achieving desired prime item reliability.

=head2 70.3.2.4 Paragraph 3.2.4, Maintainability.

This paragraph shall specify the quantitative maintainability
requirements. The requirements shall apply to maintenance in the
planned maintenance and support environment and shall be stated
in quantitative terms.

Examples are:

=over 4

=item 1

Time (e.g., mean and maximum downtime, reaction
time, turnaround time, mean and maximum to repair, mean time between
maintenance actions).

=item 2

Rate (e.g., maintenance manhours per flying
hour, maintenance, manhours per specific maintenance action, operational
ready rate, maintenance hours per operating hours, frequency of
preventive maintenance).

=item 3

Maintenance complexity (e.g., number of people
and skill levels, variety of support equipment).

=item 4

Maintenance costs (e.g., maintenance costs
per operation hours, manhours per overhaul).

=back

=head2 70.3.2.5 Paragraph 3.2.5, Environmental conditions.

This paragraph shall include both induced and natural environmental
conditions expected to be encountered by this prime item during
storage, shipment, and operation. It shall include factors such
as climate, shock, vibration, noise, and noxious gases.

=head2 70.3.2.6 Paragraph 3.2.6, Transportability.

This paragraph shall include requirements for transportability which
are common to all components to permit employment, deployment,
and logistic support. All components that, due to operational
or functional characteristics, will be unsuitable for normal transportation
methods shall be identified.

=head2 70.3.3 Paragraph 3.3, Design and construction.

This paragraph shall specify minimum prime item design and construction
standards which have general applicability and are applicable
to major classes of equipment (e.g., aerospace vehicle equipment,
support equipment) or are applicable to particular design standards.
To the maximum extent possible, these requirements shall be specified
by reference to the established military standards and specifications.
In addition, this paragraph shall specify criteria for the selection
and imposition of Federal, military, and contractor specifications
and standards.

=head2 70.3.3.1 Paragraph 3.3.1, Materials, processes, and
parts.

This paragraph shall specify those prime item peculiar
requirements governing use of materials, parts, and processes
to be utilized in the design of the prime item. It shall also
contain specifications as necessary for particular materials and
processes to be utilized in the design of the prime item. Special
attention shall be directed to prevent unnecessary use of strategic
and critical materials. A strategic and critical materials list
can be obtained from the contracting agency. In addition, requirements
for the use of standard and commercial parts listed in the qualified
products lists shall be specified in this paragraph.

=head2 70.3.3.2 Paragraph 3.3.2, Electromagnetic radiation.

This paragraph shall specify requirements related to electromagnetic
radiation both the radiation in which the prime item must operate
as well as radiation emanating from the prime item which could
inadvertently activate or explode ordnance, or interfere with
associated communications/ electronics equipment.

=head2 70.3.3.3 Paragraph 3.3.3, Identification and marking.

This paragraph shall cover the requirements for the use of color
function and identification coding of electrical and hydraulic
lines. This paragraph shall also cover the requirements for nameplates
for identification and for operation or safety. Requirements for
serialization and nomenclature shall not be included in this paragraph.


=head2 70.3.3.4 Paragraph 3.3.4, Workmanship.

This paragraph
shall specify the general requirements for workmanship which are
incident to the manufacture of the prime item. Although general
in nature the requirement stated herein relates to the finesse
of manufacture which should be provided by the craftsman or the
manufacturing technique.

=head2 70.3.3.5 Paragraph 3.3.5, Interchangeability.

This paragraph shall specify the requirements for the prime item and
those components to be interchangeable and replaceable. Entries
in this paragraph are for the purpose of establishing a condition
of design, and are not to define the conditions of interchangeability
that are required by the assignment of a part number.

=head2 70.3.3.6 Paragraph 3.3.6, Safety.

This paragraph shall specify requirements to preclude or limit hazards to personnel
and equipment. To the extent practicable, these requirements shall
be imposed by citing established and recognized standards. For
prime items directly supporting a system, appropriate paragraphs
of the system specification shall be cited, such paragraphs being
amended on 'add' or 'delete' basis for applicability
to this prime item. Limiting safety characteristics peculiar to
the prime item due to hazards in assembly, disassembly, test,
transport, storage, operation or maintenance shall be stated when
covered neither by standard industrial or service practices nor
by the system specification. 'Fail-safe' and emergency
operating restrictions shall be included where applicable. These
shall include interlocks and emergency and standby circuits required
to either prevent injury or provide for recovery of the prime
item in the event of failure.

=head2 70.3.3.7 Paragraph 3.3.7, Human performance/human
engineering.

Human engineering requirements for the configuration
item should be specified herein and applicable documents (e.g.,
MIL-STD-1472) included by reference. This paragraph should also
specify any special or unique requirements, e.g., constraints
on allocation of functions to personnel and communications and
personnel/equipment interactions. Included should be those specific
areas, stations, or equipment which would require concentrated
human engineering attention due to the sensitivity of the operation
or criticality of the task, i.e., those areas where the effects
of human error would be particularly serious.

=head2 70.3.3.8 Paragraph 3.3.8, Standards of manufacture.

This paragraph, when applicable, shall include those standards
or essential processes that, because of their significance, must
be set forth as a requirement for the manufacture of the prime
item. Requirements specified herein shall be to the level of detail
necessary to clearly establish limits for the inspections included
in Section 4 of the specification.

=head2 70.3.4 Paragraph 3.4, Major component characteristics.

This paragraph shall include a subparagraph for each major component
listed in 3.1.3. In stating requirements for the various major
components, it should be recognized that verification may necessarily
need to be accomplished following the delivery, installation,
and checkout of the major components constituting the prime item.
The functional relationship may be such that verification of requirements
specified for a major component can only be accomplished when
the units, assemblies or parts which comprise the major component
are assembled into the prime item. For each listed major component,
a separate paragraph shall be prepared specifying the performance
and physical characteristics.

=head2 70.3.5 Paragraph 3.5, Qualification (Preproduction)
(Periodic production) inspection.

(See 4.3.9 and 4.3.11)

=head2 70.3.6 Paragraph 3.6, Standard sample.

(See 4.3.10)

=head2 70.4 Section 4, Quality Assurance Provisions.

Requirements
for formal tests/verifications of the item performance and physical
characteristics shall be specified in this section.

=head2 70.4.1 Paragraph 4.1, General.

This paragraph shall,
as applicable, provide general information pertinent to tests
and inspections not covered elsewhere in Section 4, such as location
or conditions for qualification testing, requirements for special
testing of prime item components, etc.

=head2 70.4.1.1 Paragraph 4.1.1, Responsibility for inspection.

This paragraph shall usually state that the responsibility for
performing all specified tests/verifications rests with the supplier,
and that the Government reserves the right to witness or separately
perform all tests specified or otherwise inspect any or all tests
and inspections.

=head2 70.4.1.2 Paragraph 4.1.2, Special tests and examinations.

(See 4.4.1.2). This paragraph shall cover the testing routine,
sequence of tests, number of prime items to be tested, data required,
etc. for all testing requirements for other than acceptance inspection.
It shall also include, preferably in tabular form, a correlation
between each requirement, its test, and the type of unit on which
the test shall be performed.

=head2 70.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall include, or reference test and examination
procedures for all requirements covered in Section 3 and 5. All
characteristics shall be classified as critical, major or minor,
and other requirements of 4.4.2 shall be included or referenced.
In addition, this paragraph shall specify the method of confirming
that the prime item, as fabricated and assembled, complies with
the requirements of the prime item product function specification
and the drawings.

=head2 70.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 70.6 Section 6, Notes.

(See 4.6)

=head2 70.10 Section 10, Appendix I.

This section of the
specification shall contain requirements which are contractually
a part of the specification but which, for convenience in specification
maintenance, are incorporated herein, e.g., requirements of a
temporary nature or for limited effectivity. Appendixes may be
bound as separate documents for convenience in handling, e.g.,
when only a few parameters of the prime item are classified, an
appendix containing only the classified material may be established.
When parameters are placed in an appendix, the paragraph of Section
10 shall be referenced in the main body of the prime item specification
in the place where the parameter would normally have been specified.

=head1 80.0 APPENDIX VIII - TYPE Clb, PRIME ITEM PRODUCT FABRICATION SPECIFICATION

=head2 80.1 Section 1, Scope. The content of Section 1 of
a prime item fabrication specification shall be as defined in
the following example:

Example:

1. SCOPE

1.1. Scope.


This specification establishes the requirements
for manufacture and acceptance of the (insert identifier and nomenclature)
prime item.

1.2 Classification. (When applicable, see 4.1.2).

=head2 80.2 Section 2, Applicable documents.

The content of Section 2 shall be in accordance with 4.2.

=head2 80.3 Section 3, Requirements.

=head2 80.3.1 Paragraph 3.1, Prime item definition.

This paragraph shall provide a brief description of the subject prime

item. It shall identify: (a) the major components of the prime
item and (b) the individual components that must be manufactured.

=head2 80.3.1.1 Paragraph 3.1.1, Major component list.

This
paragraph shall include a complete list of all major components
that comprise the prime item.

=head2 80.3.1.2 Paragraph 3.1.2, Government furnished property
list.

This paragraph shall list the Government furnished property
required for fabrication of the prime item. This list shall identify
the property by reference to its nomenclature, specification number
and part number. If the list is extensive, it may be included
in an appendix, which shall be referenced in this paragraph.

=head2 80.3.2 Paragraph 3.2, Characteristics.

=head2 80.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall include those performance requirements that are to be demonstrated
by the quality conformance inspections in Section 4 of the specification.
It may also include requirements for performance, reliability,
etc., when such requirements are not completely controlled by
drawings. In no instance should contradicting requirements be
specified.

All requirements included herein shall, in most cases
and as excepted by 80.3.4, be limited to performance at environmental
conditions normal to the place of acceptance and shall not attempt
to simulate service environment. Requirements included herein
shall be specified in physically measurable quantitative terms
with tolerances. Such performance shall be in terms of the prime
item itself without reference to equipments or facilities with
which it must be compatible.

=head2 80.3.3 Paragraph 3.3, Design and construction. This
paragraph shall include any essential requirements that are not
controlled by the drawings or referenced documents.

=head2 80.3.3.1 Paragraph 3.3.1, Production drawings.

This paragraph shall contain a statement similar to the following:
'This (prime item name) shall be fabricated and assembled
in accordance with the drawings, parts lists, and other documents
listed on (insert identification of data lists, index lists, parts
lists or top drawing depending on which is the highest level listing
of the applicable data).'

=head2 80.3.3.2 Paragraph 3.3.2, Standards of manufacture.

This paragraph shall include those standards or essential processes
that, because of their significance, must be set forth as a requirement
for the manufacture of the prime item. Requirements specified
herein shall be to the level of detail necessary to clearly establish
limits for the inspections included in Section 4 of the specification.

=head2 80.3.3.3 Paragraph 3.3.3, Workmanship.

This paragraph
shall specify the general requirements for workmanship that are
incident to the manufacture of the prime item. Although general
in nature, the requirement stated here relates to the finesse
of manufacture that should be provided by the craftsman and is
not always specifically covered by the drawings. The requirements
of this paragraph shall generally cover features that can be verified
by visual examination. When applicable and logical, this paragraph
should cover:

=over 4

=item 1

Burrs and sharp edges

=item 2

Presence of foreign matter

=item 3

Uniformity and general appearance.

=back



=head2 80.3.4 Paragraph 3.4, Preproduction sample. (See
4.3.11) 

This paragraph, if appropriate, shall specify that a preproduction
sample(s) shall be tested prior to regular production to demonstrate
the adequacy and suitability of the contractor's processes and
procedures in achieving the performance that is inherent in the
design. Whereas in a function specification the purpose of preproduction
tests is to provide a basis for design approval, in a fabrication
specification preproduction tests, like periodic production tests,
are intended to show that the manufacturing and production techniques
employed do not degrade the design. Preproduction tests in a fabrication
specification are particularly necessary when a contract is awarded
to a new source that has not previously produced the prime item.
Selected performance requirements in the service environment may
be added to paragraph 3.2 of a fabrication specification to provide
requirements upon which preproduction tests in Section 4 of the
specification are to be based. However, since all such performance
requirements should be in the development specification for the
prime item, it will reduce the bulk of the fabrication specification
if performance requirements in the service environment are invoked

by referencing the associated development specification. In addition,
the titles and requirements of this paragraph may be made to cover
samples for periodic production tests if such tests are considered
necessary.

=head2 80.4 Section 4, Quality Assurance Provisions.

Requirements
for formal tests/verifications of the prime item performance and
physical characteristics shall be specified in this section. In

general, this section shall conform to the requirements of 4.4.

=head2 80.4.1 Paragraph 4.1, General.

This paragraph shall,
as applicable, provide general information pertinent to tests
and inspections not covered elsewhere in section 4, such as location
or conditions for preproduction and periodic production testing,
requirements for special testing of prime item components, etc.

=head2 80.4.1.1 Paragraph 4.1.1, Responsibility for inspection.

This paragraph shall usually state that the responsibility for
performing all specified tests/verifications rests with the supplier,
and that the contracting agency reserves the right to witness
or separately perform all tests specified or otherwise inspect
any or all tests and inspections.

=head2 80.4.1.2 Paragraph 4.1.2, Special tests and examinations.

This paragraph shall cover the testing routine, sequence of tests,
number of prime items to be tested, data required, etc. for all
testing requirements for other than acceptance inspection. It
shall also include, preferably in tabular form, a correlation
between each requirement, its test, and the type of unit on which
the test shall be performed.

=head2 80.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall include, or reference, test and examination
procedures for all requirements covered in Sections 3 and 5. All
characteristics shall be classified as critical, major or minor,
and other requirements of 4.4.2 shall be included or referenced.

In addition, this paragraph shall specify the method
of confirming that the prime item, as fabricated and assembled,
complies with requirements of the prime item product fabrication
specification and drawings.


=head2 80.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 80.6 Section 6, Notes.

(See 4.6)

=head2 80.6.1 Paragraph 6.1, Intended use.

(See 4.6.1)

=head2 80.6.2 Paragraph 6.2, Ordering data.

(See 4.6.2)

This paragraph shall contain the following:

=over 4

=item 1

If preproduction inspection is specified,
a paragraph shall be provided suggesting the number of samples
to order for such tests. The ordering of samples for preproduction
tests may be limited to contracts awarded to new sources with
no previous production or development experience on the prime
item. Disposition of the preproduction models after testing should
be covered, e.g., replace all damaged parts and deliver for service
use, scrap, or hold for use in future development programs, etc.

=item 2

If preproduction tests are based on requirements
in a development specification (Type B1), the fact that the development
specification as well as this specification must be supplied to
bidders should be stated.

=back

80.7 Section 10, Appendix I. This section of the
specification shall contain requirements which are contractually
a part of the specification but which, for convenience in specification
maintenance, are incorporated herein, e.g., requirements of a
temporary nature or for limited effectivity. Appendixes may be
bound as separate documents for convenience in handling, e.g.,
where only a few parameters of the prime item are classified,
an appendix containing only the classified material may be established.
Where parameters are placed in an appendix, the appropriate paragraph
of Section 10 shall be referenced in the main body of the prime
item specification in the place where the parameter would normally
have been specified.


=head1 90.0 APPENDIX IX - TYPE C2a, CRITICAL ITEM PRODUCT FUNCTION SPECIFICATION

=head2 90.1 Section 1, Scope.

The content of Section 1 of
a critical item product function specification shall be as defined
in the following example:

1. SCOPE

1.1 This specification establishes the performance,
design, test, manufacture and acceptance requirements for the
(insert nomenclature) critical item.

=head2 90.2 Section 2, Applicable documents.

The content of Section 2 shall be in accordance with 4.2.

=head2 90.3 Section 3, Requirements.

=head2 90.3.1 Paragraph 3.1, Critical item definition.

This paragraph shall contain a comprehensive definition of the functional
characteristics of the critical item covered by the specification.

=head2 90.3.2 Paragraph 3.2, Characteristics.

All characteristics
in Section 3 of the specification shall be capable of being measured
and such measurement will be the basis for the inspections in
Section 4 of the specification.

=head2 90.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall state what the critical item shall do in terms of complete
functional characteristics with upper and lower limits for each
performance characteristic. These characteristics shall be expressed
as values that must be achieved and not as goals or best efforts.

=head2 90.3.2.2 Paragraph 3.2.2, Physical characteristics.

This paragraph shall include the following as applicable:

=over 4

=item 1

Weight limits of the critical item.

=item 2

Dimensional and cube limitations, crew space,
operator panel layout, ingress, egress, and access for maintenance.

=item 3

Requirements for transport and storage, such
as packaging, and containers.

=item 4

Durability factors to indicate degree of ruggedness.

=item 5

Health and safety criteria, including consideration
of adverse explosive, mechanical, and biological effects. Included
in this criteria are the toxicological effects of the critical
item on the user and the adverse effects of any electromagnetic
radiation that might emanate therefrom.

=item 6

Vulnerability factors including consideration
of atomic, chemical, biological, and radiological operations,
electromagnetic radiation, fire and impact.

=back

=head2 90.3.2.3 Paragraph 3.2.3, Reliability.

Reliability
shall be stated in quantitative terms, defining the conditions
under which the requirements are to be met.

=head2 90.3.2.4 Paragraph 3.2.4, Maintainability.

This paragraph
shall specify the quantitative maintainability requirements. The
requirements shall apply to maintenance in the planned maintenance
and support environment and shall be stated in quantitative terms.

=head2 90.3.2.5 Paragraph 3.2.5, Environmental conditions.

This paragraph shall include both induced and natural environmental
conditions expected to be encountered by this critical item during
storage, shipment, and operation. It shall include factors such
as climate, shock, vibration, noise, and noxious gases.

=head2 90.3.2.6 Paragraph 3.2.6, Transportability.

This paragraph shall include requirements for transportability which
are common to all components to permit employment, deployment,
and logistic support. All components that, due to operational
or functional characteristics, will be unsuitable for normal transportation
methods shall be identified.

=head2 90.3.3 Paragraph 3.3, Design and construction.

This paragraph shall specify minimum critical item design and construction
standards that have general applicability and are applicable to
major classes of equipment (e.g., aerospace vehicle equipment,
support equipment) or are applicable to particular design standards.
To the maximum extent possible, these requirements shall be specified
by reference to the established military standards and specifications.
In addition, this paragraph shall specify criteria for the selection
and imposition of Federal, military, and contractor specifications
and standards.

=head2 90.3.3.1 Paragraph 3.3.1, Materials, processes, and
parts.

This paragraph shall specify those critical item-peculiar
requirements governing use of materials, parts, and processes
to be utilized in the design of the critical item. It shall also
contain specifications as necessary for particular materials and
processes to be utilized in the design of the critical item. Special
attention shall be directed to prevent unnecessary use of strategic
and critical materials. A strategic and critical materials list
can be obtained from the contracting agency. In addition, requirements
for the use of standard and commercial parts for which qualified
products lists have been established shall be specified in this
paragraph.

=head2 90.3.3.2 Paragraph 3.3.2, Electromagnetic radiation.

This paragraph shall specify requirements related to electromagnetic
radiation both the radiation in which the critical item must operate
as well as radiation emanating from the critical item which could
inadvertently activate or explode ordnance, or interfere with
associated communications/ electronics equipment.

=head2 90.3.3.3 Paragraph 3.3.3, Identification and marking.

This paragraph shall cover the requirements for the use of color
function and identification coding of electrical and hydraulic
lines. This paragraph shall also cover the requirements for nameplates
for identification and for operation or safety. Requirements for
serialization and nomenclature shall not be included in this paragraph.

=head2 90.3.3.4 Paragraph 3.3.4, Workmanship.

This paragraph
shall specify the general requirements for workmanship which are
incident to the manufacture of the critical item. Although general
in nature the requirement stated herein relates to the finesse
of manufacture which should be provided by the craftsman or the
manufacturing technique.

=head2 90.3.3.5 Paragraph 3.3.5, Interchangeability.

This paragraph shall cover all requirements for interchangeability
or replaceability of the critical item or its components.

=head2 90.3.3.6 Paragraph 3.3.6, Safety.

This paragraph
shall specify requirements to preclude or limit hazards to personnel
and equipment. To the extent practicable, these requirements shall
be imposed by citing established and recognized standards. Limiting
safety characteristics peculiar to the critical item due to hazards
in assembly, disassembly, test, transport, storage, operation
or maintenance shall be stated when covered neither by standard
industrial or service practices nor by a higher level specification.
'Fail-safe' and emergency operating restrictions shall
be included where applicable. These shall include interlocks and
emergency and standby circuits required to either prevent injury
or provide for recovery of the critical item in the event of failure.

=head2 90.3.3.7 Paragraph 3.3.7, Human performance/human
engineering.

Human engineering requirements for the critical item
should be specified herein and applicable documents (e.g., MIL-STD-1472)
included by reference. This paragraph should also specify any
special or unique requirements, e.g., constraints or allocation
of functions to personnel and communications and personnel/equipment
interactions. Included should be those specific areas which would
require concentrated human engineering attention due to the sensitivity
of the operation or criticality of the task, i.e., those areas
where the effects of human error would be particularly serious.

=head2 90.3.3.8 Paragraph 3.3.8, Standards of manufacture.

This paragraph, when applicable, shall include those standards
or essential processes that, because of their significance, must
be set forth as a requirement for the manufacture of the critical
item. Requirements specified herein shall be to the level of detail
necessary to clearly establish limits for the inspections included
in Section 4 of the specification.

=head2 90.3.4 Paragraph 3.4, Qualification (Preproduction)
(Periodic production) inspection.

(See 4.3.9 and 4.3.11)

=head2 90.3.5 Paragraph 3.5, Standard sample.

(See 4.3.10)

=head2 90.4 Section 4, Quality Assurance Provisions.

Requirements for formal tests/verifications of the critical item performance
and physical characteristics shall be specified in this section.
In general, this section shall conform to the requirements of
4.4.

=head2 90.4.1 Paragraph 4.1, General.

This paragraph shall,
as applicable, provide general information pertinent to tests
and inspections not covered elsewhere in Section 4 of the specification,
such as location or conditions for qualification testing, requirements
for special testing of critical item components, etc.

=head2 90.4.1.1 Paragraph 4.1.1, Responsibility for inspection.

This paragraph shall usually state that the responsibility for
performing all specified tests/verifications rests with the supplier,
and that the contracting agency reserves the right to witness
or separately perform all tests specified or otherwise inspect
any or all tests and inspections.

=head2 90.4.1.2 Paragraph 4.1.2, Special tests and examinations.

This paragraph shall cover the testing routine, sequence of tests,
number of critical items to be tested, data required, etc. for
all testing requirements for other than acceptance inspection.
It shall also include, preferably in tabular form, a correlation
between each requirement, its tests, and the type of unit on which
the test shall be performed.

=head2 90.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall include, or reference, test and examination
procedures for all requirements covered in Sections 3 and 5. All
characteristics shall be classified as critical, major or minor,
and other requirements of 4.4.2 shall be included or referenced.
In addition, this paragraph shall specify the method of confirming
that the critical item as fabricated and assembled, complies with
requirements of the critical item product function specification
and the drawings.

=head2 90.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 90.6 Section 6, Notes.

(See 4.6)

=head2 90.10 Section 10, Appendix I.

(See 4.7)

APPENDIX X

=head1 100.0 APPENDIX X - TYPE C2b, CRITICAL ITEM PRODUCT FABRICATION
SPECIFICATION

=head2 100.1 Section 1, Scope.

The content of Section 1
of a critical item product fabrication specification shall be
as defined in the following example:

Example:

1. SCOPE

1.1. This specification establishes the requirements
for manufacture and acceptance of the (insert identifier and nomenclature)
critical item.

(*)1.2 Classification. (See 4.1.2)

=head2 100.2 Section 2, Applicable documents.

The content
of Section 2 of the specification shall be in accordance with
paragraph 4.2.

=head2 100.3 Section 3, Requirements.

=head2 100.3.1 Paragraph 3.1, Critical item definition.

This paragraph shall provide a brief description of the subject
critical item. It shall, as appropriate, identify: (a) the major
components of the critical item and (b) the individual components
that must be manufactured.

=head2 100.3.1.1 Paragraph 3.1.1, Government furnished

property list.


This paragraph shall list the Government furnished
property which the critical item shall be designed to incorporate.
This list shall identify the property by reference to its nomenclature,
specification number and part number. If the list is extensive,
it may be included in an appendix which shall be referenced in
this paragraph.

=head2 100.3.2 Paragraph 3.2, Characteristics.

=head2 100.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall include those performance requirements which are to be demonstrated
by the quality conformance inspections in Section 4 of the specification.
It may also include requirements for performance, reliability,
etc., when such requirements are not completely controlled by
detail drawings. In no instance should contradicting requirements
be specified. All requirements included herein shall, in most
cases, be limited to performance at environmental conditions normal
to the place of acceptance and shall not attempt to simulate service
environment. Requirements included herein shall be specified in
physically measurable quantitative terms with tolerances. Such
performance shall be in terms of the critical item itself without
reference to equipments or facilities with which it must be compatible.

=head2 100.3.3 Paragraph 3.3, Design and construction.

This paragraph shall include any essential requirements that are not
controlled by the drawings or referenced documents.

=head2 100.3.3.1 Paragraph 3.3.1, Production drawings.

This paragraph shall contain a statement similar to the following:
'This (critical item name) shall be fabricated and assembled
in accordance with the drawings, parts list, and other documents
listed on (insert identification of data lists, index lists, parts
lists or top drawing depending on which is the highest level listing
of the applicable data).'

=head2 100.3.3.2 Paragraph 3.3.2, Standards of manufacture.

This paragraph shall include those standards or essential processes
that, because of their significance, must be set forth as a requirement
for the manufacture of the critical item. Requirements specified
herein shall be to the level of detail necessary to clearly establish
limits for the inspections included in Section 4 of the specification.

=head2 100.3.3.3 Paragraph 3.3.3, Workmanship.

This paragraph shall specify the general requirements for workmanship
that are
incident to the manufacture of the critical item. Although general
in nature the requirement stated herein relates to the finesse
of manufacture which should be provided by the craftsman and is
not always specifically covered by the drawings. The requirements
of this paragraph shall generally cover features that can be verified
by visual examination. When applicable and logical this paragraph
may cover:

=over 4

=item 1

Burrs and sharp edges

=item 2

Presence of foreign matter

=item 3

Uniformity and general appearance.

=back

=head2 100.3.4 Paragraph 3.4, Preproduction sample.

(See 4.3.11)

This paragraph, if provided, shall specify that a preproduction
sample(s) shall be tested prior to regular production to demonstrate
the adequacy and suitability of the contractor's processes and
procedures in achieving the performance that is inherent in the
design. Although in a function specification, the purpose of preproduction
tests is to provide a basis for design approval, in a fabrication
specification preproduction tests, like periodic production tests
are intended to show that the techniques employed do not degrade
the design. Preproduction tests in a fabrication specification
are particularly necessary when a contract is awarded to a new
source that has not previously produced the critical item. Selected
performance requirements in the service environment may be added
to paragraph 3.2 of a fabrication specification to provide requirements
upon which preproduction tests in Section 4 of the specification
are to be based. However, since all such performance requirements
should be in the development specification for the critical item,
it will reduce the bulk of the fabrication specification if performance
requirements in the service environment are invoked by referencing
the associated development specification. In addition, the titles
and requirements of this paragraph may be made to cover samples
for periodic production tests if such tests are considered necessary.

=head2 100.4 Section 4, Quality Assurance Provisions.

Requirements for formal tests/verifications of the critical item performance
and physical characteristics shall be specified in this section.
In general, this section shall conform to the requirements of
4.4.

=head2 100.4.1 Paragraph 4.1, General.

This paragraph shall,
as applicable, provide general information pertinent to tests
and inspections not covered elsewhere in Section 4, such as location
or conditions for preproduction and periodic production testing,
requirements for special testing of critical item components,
etc.

=head2 100.4.1.1 Paragraph 4.1.1, Responsibility for inspection.

This paragraph shall usually state that the responsibility for
performing all specified tests/verifications rests with the supplier,
and that the Government reserves the right to witness or separately
perform all tests specified or otherwise inspect any or all tests
and inspections.

=head2 100.4.1.2 Paragraph 4.1.2, Special tests and examinations.

This paragraph shall cover the testing routine, sequence of tests,
number of critical items to be tested, data required, etc. for
all testing requirements for other than acceptance inspection.
It shall also include, preferably in tabular form, a correlation
between each requirement, its test, and the type of unit on which
the test shall be performed.

=head2 100.4.2 Paragraph 4.2, Quality conformance inspections.

This paragraph shall include, or reference, test and examination
procedures for all requirements covered in Sections 3 and 5. All
characteristics shall be classified as critical, major or minor,
and other requirements of 4.4.2 shall be included or referenced.

In addition, this paragraph shall specify the method
of confirming that the critical item, as fabricated and assembled,
complies with requirements of the critical item product fabrication
specification and the drawings.

=head2 100.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 100.6 Section 6, Notes.

(See 4.6)

=head2 100.6.1 Paragraph 6.1, Intended use.

(See 4.6.1)

=head2 100.6.2 Paragraph 6.2, Ordering data.

(See 4.6.2)

This paragraph shall contain the following:

=over 4

=item 1

If preproduction inspection is specified a
paragraph should be provided suggesting the number of samples
to be ordered for such tests. The ordering of samples for preproduction
tests may be limited to contracts awarded to new sources, with
no previous production or development experience on the critical
item. Disposition of the preproduction models after testing should
be covered (e.g., replace all damaged parts and deliver for intended
issue for service use, scrap, or hold for use in future development
programs, etc.).

=back

=head2 100.10 Section 10, Appendix I.

(See 4.7)

=head1 110.0 APPENDIX XI - TYPE C3, NON-COMPLEX ITEM PRODUCT FABRICATION
SPECIFICATION

=head2 110.1 Section 1, Scope.

The content of Section 1
shall be as defined in one of the following examples:

Example (1):

1. SCOPE

1.1 This specification establishes the requirements
for manufacture and Government acceptance of the (insert nomenclature)
non-complex item.

Example (2):

1. SCOPE

1.1 This specification establishes the performance,
design, development, test, manufacture and acceptance requirements
for the (insert nomenclature) non-complex item.

=head2 110.2 Section 2, Applicable documents.

The content
of Section 2 shall be in accordance with 4.2.

=head2 110.3 Section 3, Requirements.

This section shall
include those performance requirements which are to be demonstrated
by the quality conformance inspections in Section 4 of the specification.
In most cases for a non-complex item this section shall callout
the production drawings and associated data that are to be followed
in the manufacture of the non- complex item. In such instances,
the drawings should be a full statement of the requirements.


=head2 110.3.1 Paragraph 3.1, Non-complex item definition.

This paragraph shall provide a brief description of the non-complex
item.

=head2 110.3.2 Paragraph 3.2, Characteristics.

=head2 110.3.2.1 Paragraph 3.2.1, Performance.

This paragraph
shall state what the non-complex item shall do including both
upper and lower performance limits. When a complete set of drawings

is invoked, performance characteristics shall be limited to those
that are not completely controlled by the drawings.

=head2 110.3.2.2 Paragraph 3.2.2, Physical characteristics.

This paragraph shall include physical requirements, as necessary,
including weight, mounting and mating dimensions, color, protective
coating, etc. when a set of manufacturing drawings is not available.
When a set of drawings is invoked, this paragraph shall include
a statement similar to the following: 'The (non-complex item
name) shall be fabricated and assembled in accordance with the
drawings, parts lists, and other documents listed on (insert identification
of data lists, index lists, parts list or assembly drawing depending
on which is the highest level listing of the applicable data).'

=head2 110.3.3 Paragraph 3.3, Workmanship.

This paragraph
shall specify the general requirements for workmanship which are
incident to the manufacture of the non-complex item. Although
general in nature the requirement stated herein relates to the
finesse of manufacture which should be provided by the craftsman
and is not always specifically covered by the drawings. The requirements
of this paragraph shall generally cover features that can be verified
by visual examination. When applicable and logical, the paragraph
may cover:

=over 4

=item 1

Burrs and sharp edges

=item 2

Presence of foreign matter

=item 3

Uniformity and general appearance.

=back

=head2 110.3.4 Paragraph 3.4, Qualification inspection and
samples.

This paragraph shall, as applicable, cover requirements
for qualification inspection (see 4.3.9), standard sample (See
4.3.10), and preproduction sample, periodic sample, pilot model
or pilot lot (See 4.3.11).

=head2 110.4 Section 4, Quality Assurance Provisions.

=head2 110.4.1 Paragraph 4.1, General.

This paragraph shall,
if necessary, provide any information relative to quality assurance
provisions not covered in other paragraphs of Section 4 of the
specification.

=head2 110.4.1.1 Paragraph 4.1.1, Responsibility for inspection.

(See 4.4.1.1)

=head2 110.4.1.2 Paragraph 4.1.2, Special tests and examinations.

(See 4.4.1.2)

=head2 110.4.2 Paragraph 4.2, Quality conformance inspections.

(See 4.4.2)

=head2 110.5 Section 5, Preparation for delivery.

(See 4.5)

=head2 110.6 Section 6, Notes.

(See 4.6)

=head2 110.10 Section 10, Appendix I.

(See 4.7)


=head1 120.0 APPENDIX XII =TYPE C4, INVENTORY ITEM SPECIFICATION

=head2 120.1 Section 1, Scope.

The content of Section 1
of an inventory item specification shall be as defined in the
following example:

Example:

1. SCOPE

1.1 This specification covers the requirements for
inventory items that are available in the Government inventory
for use in or with (include name and specification number of the
system/configuration item in or with which these inventory items
will be used).

=head2 120.2 Section 2, Applicable documents.

If certain
documents are applicable to all inventory items covered by this
specification, such documents should be listed in accordance with
4.2. Otherwise, each appendix of the inventory item specification
shall list document applicable to that particular inventory item.
When no such documents are to be listed in Section 2 of the inventory
item specification, this section shall contain the following note:

'See appendixes for applicable documents.'

=head2 120.3 Section 3, Requirements.

This section shall
include a paragraph for each inventory item covered by the specification.
Each paragraph shall reference an appendix for characteristics
of the inventory item. Each appendix shall include all of the
functional and physical requirements of the inventory item that
must be satisfied to assure compatibility with the system/configuration
item.

=head2 120.4 Section 4, Quality Assurance Provisions.

This
section shall invoke the quality assurance provisions contained
in the appendix applicable to each inventory item.

=head2 120.5 Section 5, Preparation for Delivery.

This section
shall invoke the requirements of the applicable appendix.

=head2 120.6 Section 6, Notes.

This section may refer to
the appendixes and may also contain information to the contracting
officer when such information relates to the entire group of inventory
items.

=head2 120.10 Section 10, 20, etc., Appendixes.

These sections
shall include a function specification for each inventory item.
A separate appendix shall be prepared for each required inventory
item and requirements and quality assurance provisions specified
shall be limited to those necessary to ensure the form, fit, and
function required to achieve its intended purpose in the system/configuration
item. The function specification shall be prepared in accordance
with the applicable appendix of this standard.

=head1 130.0 APPENDIX XIII - TYPE C5, SOFTWARE PRODUCT SPECIFICATION

=head2 130.1 Scope.

This specification shall consist of
the final up-dated versions of the Software Design Description,

the Software Design Description(s), the Data Base Design Description(s),
the Interface Design Description(s) and source and object code
listings of the software that has successfully undergone formal
testing. These documents shall be prepared in accordance with
the Software Design Description Data Item Description, the Software
Description Data Item Description, the Data Base Design Description
Data Item Description, and the Interface Design Description Data
Item Description. The Software Product Specification shall be
prepared in accordance with the Software Product Specification
Data Item Description.

=head1 140.0 APPENDIX XIV - TYPE D, PROCESS SPECIFICATION

=head2 140.1 Section 1, Scope.

The content of Section 1
shall be as defined in the following example:

Example:

1. SCOPE

1.1 Scope.

This paragraph shall contain a statement
of the technical coverage of this specification and of the general
use of the process.

1.2 Classification. This paragraph shall designate
and define various types, classes, etc.

=head2 140.2 Section 2, Applicable documents.

The content
of Section 2 of the specification shall be in accordance with
4.2.

=head2 140.3 Section 3, Requirements.

This section shall
cover actual minimum needs and describe equipment, materials,
and processing requirements for maximum application and eliminate
as far as practical features that restrict the process to one,
or a relatively few suppliers.

=head2 140.3.1 Paragraph 3.1, Equipment.

This paragraph
shall list or describe equipment such as heating media, control
devices, etc.

=head2 140.3.2 Paragraph 3.2, Materials.

This paragraph
shall list and reference specifications for prime or basic materials,
secondary materials, solutions, etc., as required.

=head2 140.3.3 Paragraph 3.3, Required procedures and operations.

This paragraph shall provide detailed procedures that must be
followed to assure that when the process is performed, the resulting
item or material will be in accordance with its requirements.

=head2 140.3.4 Paragraph 3.4, Recommended procedures and
operations.

This paragraph covers optional or permitted procedures
that would result in items or materials conforming to their specifications.

=head2 140.3.5 Paragraph 3.5, Certification.

This paragraph
shall specify the requirements for certification of operators
or process technique.

=head2 140.4 Section 4, Quality assurance provisions.

This
paragraph shall cover all examinations and tests to be performed
in order to decide that the processes, as well as the equipment,
used in the process conform to the requirements in Section 3.

=head2 140.4.1 Paragraph 4.1, Responsibility for inspection.

(See 4.4.1.1)

=head2 140.4.2 Paragraph 4.2, Monitoring procedures for
equipment used in process.

This paragraph shall include requirements
for periodic checking and calibrating equipments used in the process
to assure process control.

=head2 140.4.3 Paragraph 4.3, Monitoring procedures for
materials.

This paragraph shall include inspection requirements
and sampling plans for materials used in the process to assure
proper quality prior to use.

=head2 140.4.4 Paragraph 4.4, Certification.

This paragraph
shall specify sampling and procedures for certification of operators
or process technique.

=head2 140.4.5 Paragraph 4.5, Test methods.

This paragraph
shall provide procedures for testing items or materials subjected
to the process to ascertain that the process was properly performed.

=head2 140.5 Section 5, Preparation for delivery.

This section
is not applicable to this specification.

=head2 140.6 Section 6, Notes.

=head2 140.6.1 Paragraph 6.1, Intended use.

This paragraph
shall contain a complete and detailed description of the intended
use of the process described herein.

=head2 140.6.2 Paragraph 6.2, General information.

=head2 140.6.3 Paragraph 6.3, Definitions.

This paragraph
shall define any terminology used in this specification which
may not be recognized by the anticipated recipients of this specification.

=head2 140.10 Section 10, Appendix I.

(See 4.7)

(*) (Omit if not applicable)
APPENDIX XV

=head1 150.0 TYPE E, MATERIAL SPECIFICATION

=head2 150.1 Section 1, Scope.

The contents of Section 1
shall be as defined in the following example:

Example:

1. SCOPE

1.1 Scope. This paragraph shall contain a statement
of the technical coverage of this specification and of the general
use of the material.

(*)1.2 Classification. This paragraph shall contain
the designations of types, classes, grades, sizes, compositions,
and the definitive characteristics applicable to such designation.

=head2 150.2 Section 2, Applicable documents.

The content
of Section 2 shall be in accordance with 4.2.

=head2 150.3 Section 3, Requirements.

This section shall
cover the actual minimum functional, physical, chemical, electrical,
and mechanical requirements of the material. These requirements
shall be complete and to the level of detail necessary to reproduce
the same material without recourse to the original manufacturer.

=head2 150.3.1 Paragraph 3.1, General material requirements.

This paragraph shall include those requirements which the material
must meet.

=head2 150.3.1.1 Paragraph 3.1.1, Character or quality.

This paragraph shall contain qualitative statements as to the
general condition or property of the material.

=head2 150.3.1.2 Paragraph 3.1.2, Formulation.

This paragraph
shall contain the quantitative values with upper and lower limits
for material and each component of the material.

=head2 150.3.1.3 Paragraph 3.1.3, Product characteristics.

This paragraph shall cover specific conditions and properties
such as color, protective coating, waviness, surface finish, dimensions,
weight, etc.

=head2 150.3.1.4, Paragraph 3.1.4, Chemical, electrical
and mechanical properties.

This paragraph shall cover composition,
concentration, hardness, tensile strength, elongation, thermal
expansion, electrical resistivity, etc.

=head2 150.3.1.5, Paragraph 3.1.5, Environment conditions.

This paragraph shall specify both induced and natural environmental
conditions which the materials must withstand. These conditions
and their effects on the material must be stated in measurable
quantitative terms with limits.

=head2 150.3.1.6, Paragraph 3.1.6, Stability.

This paragraph
shall cover the requirements for shelf life, ageing, etc.

=head2 150.3.1.7 Paragraph 3.1.7, Toxic products and safety.

This paragraph shall specify requirements concerning effects on
the health and safety of the user and include adequate safety
provisions where applicable.

=head2 150.3.1.8 Paragraph 3.1.8, Identification and marking.

This paragraph shall cover the requirements for the use of color
for function or identification coding, for stamping or imprinting
information on the material, etc.

=head2 150.3.1.9 Paragraph 3.1.9, Workmanship.

This paragraph
shall specify the general requirements for workmanship which are
incident to the manufacture or processing of the material. Although
general in nature the requirements stated herein relate to the
finesse of manufacture processing that should be provided by the
craftsman or by the manufacturing process. Requirements stated
herein generally cover features that can be verified by visual
examination.

=head2 150.3.2 Paragraph 3.2, Qualification (Preproduction)
(Periodic production) inspection.

(See 4.3.9 and 4.3.11)

=head2 150.3.3 Paragraph 3.3, Differentiating requirements.

This paragraph shall include the differentiating requirements
for each type, class, grade, etc.

=head2 150.4 Section 4, Quality assurance provisions.

=head2 150.4.1 Paragraph 4.1, Responsibility for inspection.

(See 4.4.1.1)

=head2 150.4.2 Paragraph 4.2, Special tests and examinations.

(See 4.4.1.2)

=head2 150.4.3 Paragraph 4.3, Quality conformance inspection.

(See 4.4.2)

=head2 150.4.4 Paragraph 4.4, Test methods.

=head2 150.5 Section 5, Preparation for delivery.

(See 4.5)


=head2 150.6 Section 6, Notes.

(See 4.6)

=head2 150.10 Section 10, Appendix I.

(See 4.7)

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
