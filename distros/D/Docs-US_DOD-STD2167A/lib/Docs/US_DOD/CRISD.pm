#!perl
#
#
package  Docs::US_DOD::CRISD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/09/15';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-MCCR-80024A';
$TITLE = 'Computer Resources Integrated Support Document (CRISD)';
$REVISION = 'A';
$REVISION_DATE = '2/29/1988';

1

__END__

=head1 DATA ITEM DESCRIPTION

 Form Approved
 OMB No. 0704-0188

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. TITLE

COMPUTER RESOURCES INTEGRATED SUPPORT DOCUMENT (CRISD)

=head1 2. IDENTIFICATION NUMBER

DI-MCCR-80024A

=head1 3. DESCRIPTION/PURPOSE

=head2 3.1  

The Computer Resources Integrated Support Document        
(CRISD) provides the information needed to plan for life cycle 
support of deliverable software.  The CRISD documents the      
contractor's plans for transitioning support of deliverable    
software to the support agency.

=head2 3.2  

The CRISD is used by the Government for updating the      
Computer Resource Life Cycle Management Plan.

=head1 4. APPROVAL DATE

(YYMMDD) 880229

=head1 5. OFFICE OF PRIMARY RESPONSIBILITY

(ORR) EC

=head1 6a. DTIC

APPLICABLE

=head1 6b. GIDEP

APPLICABLE

=head1 7. APPLICATION/INTERRELATIONSHIP

=head2 7.1

This Data Item Description (DID) contains the format and  
content preparation instructions for data generated under the  
work task described by paragraphs 4.6.4 and 4.6.4 of           
DOD-STD-2167A.

=head2 7.2

The Contract Data Requirements List should specify        
whether this document is to be prepared and delivered on bound 
8 1/2 by 11 inch  bond paper or electronic media.  If          
electronic media is selected, the precise format must be       
specified.

=head2 7.3

This DID supersedes DI-MCCR-80024 dated 4 June 1985.

=head1 9b. AMSC NUMBER

N4339

=head1 10. PREPARATION INSTRUCTIONS 

=head2 10.1 Content and format instructions.

Production of this     
document using automated techniques is encouraged.  Specific   
content and format instructions for this document are          
identified below.

=over 4

=item a. Response to tailoring instructions.  

In the event     
that a paragraph or subparagraph has been tailored out, a 
statement to that effect shall be added directly          
following the heading of each such (sub)paragraph. If a   
paragraph and all of its subparagraphs are tailored out,  
only the highest level paragraph heading need be          
included.

=item b. Use of alternate presentation styles.

Charts, tables, matrices, or other presentation styles are        
acceptable when the information required by the           
paragraphs and subparagraphs of this DID can be made more 
readable.

=item c.  Page numbering.

Each page prior to Section 1 shall   
be numbered in lower-case roman numerals beginning with   
page ii for the Table of Contents.  Each page starting    
from Section 1 to the beginning of the appendixes shall   
be consecutively numbered in arabic numerals.  If t he    
document is divided into volumes, each such volume shall  
restart the page numbering sequence.

=item d.  Document control numbers.

For hardcopy formats, this 
document may be printed on one or both sides of each page 
(single-sided/double-sided).  All printed pages shall     
contain the document control number and the date of the   
document centered at the top of the page. Document   
control numbers shall include revision and volume 
identification, as applicable.

=item e.  Multiple (sub)paragraphs.

All paragraphs and         
subparagraphs starting with the phrase "This              
(sub)paragraph shall..." may be written as multiple       
subparagraphs to enhance readability.  These              
subparagraphs shall be numbered sequentially.

=item f.  Document structure.

This document shall consist of   
the following:

 (1)  Cover
 (2)  Title page
 (3)  Table of contents
 (4)  Scope
 (5)  Referenced documents
 (6)  Support information
 (7)  Transition planning
 (8)  Notes
 (9)  Appendixes.

=back

=head2 10.1.1 Title page.

The title page shall contain the          
information identified below in the indicated format:

 [Document control number and date: Volume x of y (if multi-volume)]

 [Rev. indicator: date of Rev.]

 COMPUTER RESOURCES INTEGRATED SUPPORT DOCUMENT FOR THE

 [SYSTEM NAME]

 CONTRACT NO. [contract number]

 CDRL SEQUENCE NO. [CDRL number]

 Prepared for:

 [Contracting Agency Name, department code]

 Prepared by:

 [contractor name and address]

=head2 10.1.2  Table of contents.

This document shall contain a      
table of contents listing the title and page number of each    
titled paragraph and subparagraph.  The table of contents      
shall then list the title and page number of each figure,      
table, and appendix, in that order.

=head2 10.1.3  Scope.

This section shall be numbered 1 and shall be  
divided into the following paragraphs.

=head2 10.1.3.1  Identification.

This paragraph shall be numbered    
1.1 and shall contain the approved identification number(s),   
title(s), and abbreviation(s), if applicable, or the CSCI(s),  
if applicable, of the CSCI(s) and the system to which this     
CRISD applies.  If the document applies to all CSCIs in the    
system, this shall be stated.

=head2 10.1.3.2  System overview.

This paragraph shall be numbered   
1.2 and shall briefly state the purpose of the system and the  
software to which this CRISD applies.

=head2 10.1.3.3  Document overview.

This paragraph shall be numbered 
1.3 and shall summarize the purpose and contents of this       
document.

=head2 10.1.4  Referenced documents.

This section shall be numbered  
2 and shall list by document number and title all documents    
referenced in this document.  This section shall also identify 
the source for all documents not available through normal      
Government stocking activities.

=head2 10.1.5  Support information.

This section shall be numbered 3 
and shall be divided into the following paragraphs and         
subparagraphs to provide the support information.

=head2 10.1.5.1  Software support resources.

This paragraph shall be 
numbered 3.1. and shall be divided into subparagraphs to       
identify and describe the components of the software           
engineering and test environments required to support the      
deliverable software. This paragraph shall identify the        
interrelationships of the components.  A figure may be used to 
show the interrelationships.  The following subparagraphs      
shall include items necessary to modify the software,          
perform testing, and copy software for distribution.

=head2 10.1.5.1.1  Software.

This subparagraph shall be numbered     
3.1.1  and shall identify and describe all of the software and 
associated documentation required to support the deliverable   
software.  Each  item of software shall be identified as       
Government furnished software, commercially available          
software, deliverable software, or non-deliverable software,   
as appropriate.

=head2 10.1.5.1.2  Hardware.

This subparagraph shall be numbered     
3.1.2 and shall identify and describe the hardware and the     
associated documentation necessary to support the deliverable  
software.  Rationale for the selected hardware shall be        
provided.  A figure may be included to show the                
interrelationship of hardware.

=head2 10.1.5.1.3  Facilities.

This subparagraph shall be numbered   
3.1.3, shall describe the facilities required to support the   
deliverable software and shall identify their purpose.

=head2 10.1.5.1.4  Personnel.

This subparagraph shall be numbered    
3.1.4 and shall identify the personnel required to support the 
deliverable software, including the types of skills, number of 
personnel, security clearance, and skill level.

=head2 10.1.5.1.5  Other resources.

This subparagraph shall be       
numbered 3.1.5 and shall identify any other resources required 
for the support environment not discussed above.

=head2 10.1.5.2  Operations.

This paragraph shall be numbered 3.2    
and shall be divided into the following subparagraphs to       
describe the operations necessary to support the deliverable   
software.

=head2 10.1.5.2.1  Software modification.

This subparagraph shall be 
numbered 3.2.1 and shall describe the procedures necessary to 
modify deliverable operational and support software.  This     
subparagraph shall also describe (either directly or by        
reference) the procedures for accommodating revisions to       
commercially available and reusable computer resources.

=head2 10.1.5.2.2  Software integration and testing.

This subparagraph shall be numbered 3.2.2 and shall describe the    
procedures necessary to integrate and fully test all software  
modifications.  It shall include procedures to identify        
portions of changes that need further testing in the           
operational environment and to establish guidelines for        
determining, developing, and verifying the amount of testing   
required.

=head2 10.1.5.2.3  Software generation.

This subparagraph shall be   
numbered 3.2.3 and shall provide the information necessary to  
facilitate compilations or assemblies of the contractually     
deliverable software. This subparagraph shall identify, by     
title, version, etc., all equipment and software required to   
perform this function and the appropriate manuals or reference 
documents.  This subparagraph shall also contain the necessary 
instructions for loading, executing, or recording the results  
of the compilations or assemblies. This subparagraph shall     
include any optional methods of producing new object code      
(such as partial translation), producing a new listing,        
producing a new object program on different media, and loading 
the new object programs into the target computer system(s).    
Any known scheduling information or requirements shall also be 
included.

=head2 10.1.5.2.4  Simulation.

This subparagraph shall be numbered   
3.2.4 If simulation is necessary to support the deliverable    
software, this subparagraph shall detail the hardware,         
software, and procedures necessary for the required            
simulation.  It shall include all modes of simulation          
available and any limitations imposed by the simulation        
methods.

=head2 10.1.5.2.5  Emulation.

This subparagraph shall be numbered    
3.2.5. If emulation is necessary to support the deliverable    
software, this subparagraph shall detail the hardware,         
software, and procedures  necessary for the required           
emulation.  It shall identify all modes of operation that are  
emulated, the relationships with the simulation modes          
described above, and any limitations imposed by the emulation.

=head2 10.1.5.3  Training.

This paragraph shall be numbered 3.3 and  
shall describe the contractor's plans for the training of      
personnel to manage and implement support of the deliverable   
software.  The schedule, duration, and location for all        
required training shall be provided, as the delineation        
between classroom training and "hands-on" training.  This      
paragraph shall provide (either directly or by reference)      
provisions for.

=over

=item 1  

Familiarization with the operational software and     
target computer(s) 

=item 2

Familiarization with the support software and host    
system 

=item 3

Equipment maintenance procedures.

=back

=head2 10.1.5.4  Anticipated areas of change.

This paragraph shall   
be numbered 3.4 and shall describe the anticipated areas of    
change to the deliverable software.

=head2 10.1.6 Transition planning.

This section shall be numbered 4 
and shall be divided into paragraphs and subparagraphs as      
appropriate to describe the contractor's plans for             
transitioning the deliverable software to the support agency.  
This section shall address the following:

=over 4

=item 1

Describe the resources necessary to carry out the     
transition activity and identify the source from which   
each resource will be provided.

=item 2

Identify the schedules and milestones for conducting  
the transition activities.  These schedules and           
milestones shall be compatible with the contract master   
schedule.

=item 3

Describe the procedures for installation and checkout 
of the deliverable software in the support environment    
designated by the contracting agency.

=back

=head2 10.1.7  Notes.

This section shall be numbered 5 and shall     
contain any general information that aids in understanding     
this document (e.g., background information, glossary).  This  
section shall include an alphabetical listing of all acronyms, 
abbreviations, and their meanings as used in this document.

=head2 10.1.8  Appendixes.

Appendixes may be used to provide         
information published separately for convenience in document   
maintenance (e.g., charts, classified data).  As applicable,   
each appendix shall be referenced in the main body of the      
document where the data would normally have been provided.     
Appendixes may be bound as separate documents for ease in      
handing.  Appendixes shall be lettered alphabetically (A, B,   
etc.), and the paragraphs within each appendix be numbered as  
multiples of 10 (e.g., Appendix A, paragraph 10, 10.1, 10.2,   
20, 20.1, 20.2, etc.), Pages within each appendix shall be     
numbered alpha-numerically as follows:  Appendix A pages shall 
be numbered A-1, A-2, A-3,  etc.  Appendix B pages shall be    
numbered B-1, B-2, B-3, etc. 

=head1 11. DISTRIBUTION STATEMENT

DISTRIBUTION STATEMENT A. 

Approved for public release; distribution  is unlimited.

 DD Form 1664, JUN 86 
 Previous editions are obsolete

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

