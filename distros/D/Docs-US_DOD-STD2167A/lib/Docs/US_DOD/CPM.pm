#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::US_DOD::CPM;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$VERSION = '1.07';
$IDENTIFICATION_NUMBER  = 'DI-IPSC-81447';
$TITLE = 'COMPUTER PROGRAMMING MANUAL (CPM)';
$REVISION = '-';
$DATE = '2003/06/10';
$REVISION_DATE = '';

1


__END__


=head1 DATA ITEM DESCRIPTION

The following establishes the data general and content
requirements for the identified data item. 

=head1 TITLE

COMPUTER PROGRAMMING MANUAL (CPM) 

=head1 2. IDENTIFICATION NUMBER

DI-IPSC-81447 

=head1 3. DESCRIPTION/PURPOSE

The Computer Programming Manual (CPM) provides
information needed by a programmer to understand how to program
a given computer. This manual focuses on the computer itself,
not on particular software that will run on the computer. 
The CPM is intended for newly developed computers,
special-purpose computers, or other computers for which commercial
or other programming manuals are not readily available 

=head1 7. APPLICATION/INTERRELATIONSHIP

This Data Item Description (DID) contains the format
and content preparation instructions for the data product generated
by specific and discrete task requirements as delineated in the
contract.

This DID is used when the developer is tasked to
identify and record information needed to program the computer(s)
on which software was developed or on which it will run. 

The Contract Data Requirements List (CDRL)
should specify whether deliverable data are to be delivered on
paper or electronic media; are to be in a given electronic form
(such as ASCII, CALS, or compatible with a specified word processor
or other support software); may be delivered in developer format
rather than in the format specified herein; and may reside in
a computer-aided software engineering (CASE) or other automated
tool rather than in the form of a traditional document. 

This DID supersedes DI-MCCR-80021A. 

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

=head1 Scope.

This section shall be divided into the following paragraphs.

=head2 1.1 Identification.

This paragraph shall contain the manufacturer's name, model
number, and any other identifying information for the computer
system to which this document applies. 

=head2 1.2 Computer system overview.

This paragraph shall briefly state the purpose of the computer
system to which this document applies. 

=head2 1.3 Document overview.

This paragraph shall summarize the purpose and contents of
this manual and shall describe any security or privacy considerations
associated with its use. 

=head1 2.Referenced documents.

This section shall list the number, title, revision, and date
of all documents referenced in this manual. This section shall
also identify the source for all documents not available through
normal Government stocking activities. 

=head1 3. Programming environment.

This section shall be divided into paragraphs as appropriate
to provide the following information. 

=over 4

=item 1

The components and configuration of the computer system

=item 2

Operating characteristics, capabilities, and limitations,
including, as applicable:

=over 4

=item *

Machine cycle time

=item *

Word length

=item *

Memory capacity and characteristics

=item *

Instruction set characteristics

=item *

Interrupt capabilities

=item *

Modes of operation (e.g., batch, interactive, privileged,
non-privileged)

=item *

Operational registers

=item *

Error indicators

=item *



Input/output characteristics

=item *

Special features

=back

=item 3

Description of the equipment (e.g., tapes, disks, other
peripheral equipment) necessary to perform compilations and assemblies
on the computer system. Identify (as applicable) by name and version
number the editor, linker, link-editor, compiler, assembler, cross-compilers,
cross-assemblers, and other utilities used, and reference appropriate
manuals describing their use. Highlight any special flags or instructions
necessary for loading, executing, or recording the results. 

=back

=head1 4. Programming information.

This section shall be divided into paragraphs as appropriate
to provide the following information.

=over 4

=item 1

Description of the programming features of the computer's
instruction set architecture, including, as applicable:

=over 4

=item *

Data representation (e.g., byte, word, integer, floating-point,
double precision)

=item *

Instruction formats and addressing modes

=item *

Special registers and words (e.g., stack pointer, program
counter)

=item *

Control instructions (e.g., branch, jump, subroutine and
procedure call instructions, privileged instructions, and the
modes they operate in)

=item *

Subroutines and procedures (e.g., non-reentrant, reentrant,
macrocode routines, argument lists, parameter passing conventions)

=item *

Interrupt processing

=item *

Timers and clocks

=item *

Memory protection features (e.g., read-only memory)

=item *

Additional features, such as instruction or data cache
architecture 

=back

=item 2

Description of each instruction, including, as applicable:

=over 4

=item *

Use
=item *


Syntax

=item *

Condition codes set

=item *

Execution time

=item *

Machine-code format

=item *

Mnemonic conventions

=item *

Other characteristics

=back

=item 3

Description of input and output control programming, including,
as applicable:

=over 4

=item *

Initial loading and verification of computer memory

=item *

Serial and parallel data channels

=item *

Discrete inputs and outputs

=item *

Interface components

=item *

Device numbers, operational codes, and memory locations
for peripheral equipment

=back

=item 4

Additional, restricted, or special programming techniques
associated with the computer system (e.g., a concise description
of the microprogram control section)

=item 5

Examples that demonstrate the programming features described
above, including examples of the proper use of all categories
of instructions on the computer system 

=item 6

Error detection and diagnostic features associated with
the computer system, including condition codes, overflow and addressing
exception interrupts, and input and output error status indicators

=back

=head1 5.Notes.

This section shall contain any general information that aids
in understanding this document (e.g., background information,
glossary, rationale). This section shall include an alphabetical
listing of all acronyms, abbreviations, and their meanings as
used in this document and a list of terms and definitions needed
to understand this document. 

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
