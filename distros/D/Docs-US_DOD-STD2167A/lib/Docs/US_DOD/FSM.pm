#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::FSM;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$VERSION = '1.07';
$DATE = '2003/06/10';

$IDENTIFICATION_NUMBER  = 'DI-IPSC-81448';
$TITLE = 'FIRMWARE SUPPORT MANUAL (FSM)';
$REVISION = '-';
$REVISION_DATE = '';

1

__END__

=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. TITLE

 FIRMWARE SUPPORT MANUAL (FSM)

=head1 2. IDENTIFICATION NUMBER

 DI-IPSC-81448

=head1 3. DESCRIPTION/PURPOSE

The Firmware Support Manual (FSM) provides the information
needed to program and reprogram the firmware devices of a system.
It applies to read only memories (ROMs), Programmable ROMs (PROMs),
Erasable PROMs (EPROMs), and other firmware devices. 

The FSM describes the firmware devices and the equipment,
software, and procedures needed to erase firmware devices, load
software into the firmware devices, verify the load process, and
mark the loaded firmware devices.

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
identify and record information needed to program and reprogram
firmware devices in which software will be installed. 

The Contract Data Requirements List (CDRL) should
specify whether deliverable data are to be delivered on paper
or electronic media; are to be in a given electronic form (such
as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-MCCR-80022A and DI-MCCR-80318.

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
system, software, and firmware devices to which this document
applies, including, as applicable, identification number(s), title(s),
abbreviation(s), version number(s), and release number(s) of the
system and software and manufacturer's name and model number for
each firmware device.

=head2 1.2 System overview.

This paragraph shall briefly state the purpose of the system
and the software to which this document applies. It shall describe
the general nature of the system and software; summarize the history
of system development, operation, and maintenance; identify the
project sponsor, acquirer, user, developer, and support agencies;
identify current and planned operating sites; and list other relevant
documents.

=head2 1.3 Document overview.

This paragraph shall summarize the purpose and contents of this
manual and shall describe any security or privacy considerations
associated with its use.

=head1 2 Referenced documents.

This section shall list the number, title, revision, and date
of all documents referenced in this manual. This section shall
also identify the source for all documents.

=head1 3 Firmware programming instructions.

This section shall be divided into the following paragraphs.

=head2 3.x (Identifier of programmed firmware device)

This paragraph shall state the project-unique identifier of
a programmed firmware device to be used in the system and shall
be divided into the following subparagraphs.

=head2 3.x.1 Description of pre-programmed device.

This paragraph shall:

=over 4

=item 1

Identify by manufacturer's name and model number the firmware
device to be programmed

=item 2

Provide a complete physical description of the firmware
device, including the following, as applicable:

=over 4

=item *

Memory size, type, speed, and configuration (such as 64Kx1,
8Kx8)

=item *

Operating characteristics (such as access time, power requirements,
logic levels)

=item *

Pin functional descriptions

=item *

Logical interfaces (such as addressing scheme, chip selection)

=item *

Internal and external identification scheme used

=item *

Timing diagrams

=back

=item 3

Describe the operational and environmental limits to which
the firmware device may be subjected and still maintain satisfactory
operation

=back

=head2 3.x.2 Software to be programmed into the device.

This paragraph shall identify by project-unique identifier(s)
the software to be programmed into the firmware device.

=head2 3.x.3 Programming equipment.

This paragraph shall describe the equipment to be used for
programming and reprogramming the firmware device. It shall include
computer equipment, general purpose equipment, and special equipment
to be used for device erasure, loading, verification, and marking,
as applicable. Each piece of equipment shall be identified by
manufacturer's name, model number, and any other information that
is necessary to uniquely identify that piece of equipment. A description
of each piece of equipment shall be provided, including its purpose,
usage, and major capabilities.

=head2 3.x.4 Programming software.

This paragraph shall describe the software to be used for
programming and reprogramming the firmware device. It shall include
software to be used for device erasure, loading, verification,
and marking, as applicable. Each software item shall be identified
by vendor's name, software name, number, version/release, and
any other information necessary to uniquely identify the software
item. A description of each software item shall be provided, including
its purpose, usage, and major capabilities.

=head2 3.x.5 Programming procedures.

This paragraph shall describe the procedures to be used for
programming and reprogramming the firmware device. It shall include
procedures to be used for device erasure, loading, verification,
and marking, as applicable. All equipment and software necessary
for each procedure shall be identified, together with any security
and privacy measures to be applied.

=head2 3.x.6 Installation and repair procedures.

This paragraph shall contain the installation, replacement,
and repair procedures for the firmware device. This paragraph
shall also include remove-and-replace procedures, device addressing
scheme and implementation, description of the host board layout,
and any procedures for ensuring continuity of operations in the
event of emergencies. Safety precautions, marked by WARNING or
CAUTION, shall be included where applicable.

=head2 3.x.7 Vendor information.

This section shall include or reference any relevant information
supplied by the vendor(s) of the firmware device, programming
equipment, or programming software.

=head1 4 Notes.

This section shall contain any general information that aids
in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of terms and definitions needed
to understand this document. 

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
