#!perl
#
#
package Docs::US_DOD::CSOM;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/09/15';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-MCCR-80018A';
$TITLE = 'Computer System Operator\'s Manual (CSOM)';
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

Computer System Operator's Manual (CSOM)

=head1 2. IDENTIFICATION NUMBER

DI-MCCR-80018A

=head1 3. DESCRIPTION/PURPOSE

=head2 3.1  

The Computer System Operator's Manual (CSOM) provides    
information and detailed procedures for initiating, operating,
monitoring, and shutting down a computer system and for
identifying/isolating a malfunctioning component in a computer
system.

=head2 3.2

A CSOM is developed for each computer system in which one 
or more CSCIs execute.

=head1 4. APPROVAL DATE

(YYMMDD) 880229

=head1 5. OFFICE OF PRIMARY RESPONSIBILITY

(OPR) EC

=head1 6.

6a. DTIC APPLICABLE

6b. GIDEP APPLICABLE

=head1 7. APPLICATION/INTERRELATIONSHIP

=head2 7.1

This Data Item Description (DID) contains the format and  
content preparation instructions for data generated under the  
task described by paragraph 4.6.4 of DOD-STD-2167A.

=head2 7.2  

The Contract Data Requirements List should specify        
whether this document is to be prepared and delivered on bound 
8 1/2 by 11 inch bond paper or electronic media.  If           
electronic media is selected, the precise format must be       
specified.

=head2 7.3  

This DID supersedes DI-MCCR-80018 and DI-MCCR-80020 dated 
4 June 1985.

=head1 9.

9a. APPLICABLE FORMS

9b. AMSC NUMBER

N4335

=head1 10. PREPARATION INSTRUCTIONS


=head2 10.1  Content  and format instructions.

Production of this    
manual using automated techniques is encouraged.  Specific     
content and format instructions for this manual are identified 
below.

=over 4

=item a. Response to tailoring instructions.

In the event that a paragraph or subparagraph has been tailored out, a 
statement to that effect shall be added directly          
following heading of each such (sub)paragraph.  If a      
paragraph and all of its subparagraphs are tailored out,  
only the highest level paragraph heading need be          
included.

=item b. Use of alternate presentation styles.

Charts, tables, matrices, or other presentation styles are        
acceptable when the information required by the           
paragraphs and subparagraphs of this DID can de made more 
readable.

=item c. Page numbering.

Each page prior to Section 1 shall   
be numbered in lower-case roman numerals beginning with   
page ii for the Table of Contents.  Each page starting    
from Section 1 to the beginning of the appendixes shall   
be consecutively numbered in arabic numerals.  If the     
document is into volumes, each such volume shall restart  
the numbering sequence.

=item d. Document control numbers.

For hardcopy formats, this 
document may be printed on one or both sides of each page
(single-sided/double-sided).  All printed pages shall  
contain the document control number and the date of the   
document centered at the top of the page. Document        
control numbers shall include revision and volume         
identification as applicable.

=item e. Multiple (sub)paragraphs.

All paragraphs and         
subparagraphs starting with the phrase "This              
(sub)paragraph shall..." may be written as multiple       
subparagraphs to enhance readability. These subparagraphs 
shall be numbered sequentially.

=item f. Identifiers.

The letter "X" serves as an identifier  
for a  series of descriptions.  For example, the          
subparagraphs of paragraph 10.1.6.2 describes diagnostic  
procedures and is presented in the following structure:

 4.2    Diagnostic procedures.
 4.2.1  (Name of the e first diagnostic procedure).
 4.2.2  (Name of the second diagnostic procedure).
 4.2.3  etc.

=item g.  Document structure.

This manual shall consist of the following:

 (1)  Cover
 (2)  Title page
 (3)  Table of contents
 (4)  Scope
 (5)  Referenced documents
 (6)  Computer system operation
 (7)  Diagnostic features
 (8)  Notes
 (9)  Appendixes.

=back

=head2 10.1.1  Title page.

The title page shall contain the          
information specified below in the indicated format:

 [Document control number and data: Volume x of y (if multi-volume)]

 [Rev. indicator: date of Rev.]

 COMPUTER SYSTEM OPERATOR'S MANUAL FOR THE

 [COMPUTER SYSTEM NAME]

 OF

 [SYSTEM NAME]

 CONTRACT NO. [contract number]

 CDRL SEQUENCE NO. [RDRL number]

 Prepared for.

 [Contracting agency Name, department code]

 Prepared by.

 [contractor name and address]


=head2 10.1.2  Table of contents.

This manual shall contain a table  
of contents listing the title and page number of each titled   
paragraph and subparagraph.  The table of contents shall then  
list the title and page number of each figure, table, and      
appendix, in that order.

=head2 10.1.3  Scope.

This section shall be numbered 1 and shall be  
divided into the following paragraphs.

=head2 10.1.3.1  Identification.

This paragraph shall be numbered    
1.1 and shall contain the approved identification number,      
title, and abbreviation, if applicable, of the computer system 
to which this CSOM applies.

=head2 10.1.3.2  System overview.

This paragraph shall be numbered   
1.2 and shall briefly state the purpose of the system and the  
software to which this CSOM applies.

=head2 10.1.3.3  Document overview.

This paragraph shall be numbered 
1.3 and shall summarize the purpose and contents of this       
manual.

=head2 10.1.4  Referenced documents.

This section shall be numbered  
2 and shall list by document number and title all documents    
referenced in this manual.  This section shall also identify   
the source for all documents not available through normal      
Government stocking activities.

=head2 10.1.5  Computer system operation.

This section shall be      
numbered 3 and shall be divided into the following paragraphs  
and subparagraphs to describe the instructions for operation   
of the computer system.  This section may reference            
commercially available documents for the information required  
by the following paragraphs and subparagraphs.

=head2 10.1.5.1  Computer system preparation and shutdown.

This paragraphs shall be numbered 3.1 and shall be divided into the 
following subparagraphs to described the procedures for        
computer system preparation and setup prior to computer system 
operation.

=head2 10.1.5.1.1  Power on and off.

This subparagraph shall be      
numbered 3.1.1 and shall explain the step-by-step procedures   
required to power-on and power-off the computer system.

=head2 10.1.5.2  Initiation.

This subparagraph shall be numbered     
3.1.2 and shall contain the initiation procedures necessary to 
operate the computer system.  This subparagraph shall          
described the following:

=over

=item 1

The equipment setup and the procedures required for   
pre-operation.

=item 2

The procedures necessary to bootstrap the computer    
system and to load software and data.

=item 3

The commands typically used during computer system
initiation.

=item 4

The procedures necessary to initialize files,          
variables, or other parameters.

=back

=head2 10.1.5.1.3  Shutdown.

This subparagraph shall be numbered     
3.1.3 and shall contain the shutdown procedures necessary to   
save data files and other information and to terminate         
computer system operation.

=head2 10.1.5.2  Operating procedures.

This paragraph shall be       
numbered 3.2 and shall be divided into the following           
subparagraphs to contain the procedures necessary to operate   
the computer system once the initiation procedures are         
complete.  If more than one mode of operation is available,    
instructions for each mode shall be provided.

=head2 10.1.5.1  Input and output procedures.

This subparagraph      
shall be numbered 3.2.1, shall describe the input and output   
media (e.g., magnetic tape, disk, cartridge, etc.) relevant to 
the computer system and shall explain the procedures required  
to read and write on these media.  This subparagraph shall     
briefly describe the operating system control language and     
shall also list operator procedures for interactive messages   
and replies (e.g., which terminal to use, password use, log on 
and log off procedures).

=head2 10.1.5.2.2  Monitoring procedures.

This subparagraph shall be
numbered 3.2.2 and shall contain the procedures to be followed 
for monitoring the software in operation.  Applicable trouble  
and malfunction indications shall be included.  Evaluation     
techniques for fault isolation shall be described to the       
maximum extent practical.  This subparagraph shall also        
include descriptions of conditions requiring computer system   
shutdown.  Procedures for on-line intervention, abort, and     
user communications shall also be included. 

=head2 10.1.5.2.3  Recovery procedures.

This subparagraph shall be   
numbered 3.2.3 and shall describe the automatic and manual     
procedures to be followed for each trouble occurrence (e.g.,   
have detailed instructions to obtain computer system dumps).   
This subparagraph shall describe the steps to be taken by the  
operator to restart computer system operation after an abort   
or interruption of operation. Procedures for recording         
information concerning a malfunction shall also be included.

=head2 10.1.5.2.4  Off-line routine procedures.

This subparagraph    
shall be numbered 3.2.4 and shall contain the procedures       
required to operate all relevant off-line routines of the      
computer system.

=head2 10.1.5.2.5  Other procedures.

This subparagraph shall be      
numbered 3.2.5 and shall contain any additional procedures to  
be followed by the operator (e.g., computer system alarms,     
program or computer system security considerations, switch     
over to a redundant computer system).

=head2 10.1.6 Diagnostic features.

This section shall be numbered 4  
and shall be divided into the following paragraphs and         
subparagraphs to describe the diagnostic features available to 
the computer operator.  This section may reference             
commercially available documents for the information required  
by the following paragraphs and subparagraphs.

=head2 10.1.6.1 Diagnostic features summary.

This paragraph shall   
be numbered 4.1 and shall summarize the error-detection and    
diagnostic features available in the computer system,          
including error message syntax and hierarchy for fault         
isolation.  This paragraph shall describe the purpose of each  
diagnostic feature.

=head2 10.1.6.2  Diagnostic procedures.

This paragraph shall be      
numbered 4.2 and shall be divided into t he following          
subparagraphs to identify and describe the diagnostic          
procedures.

=head2 10.1.6.2.1  (Procedure name).

This subparagraph shall be      
numbered 4.2X (beginning with 4.2.1), shall identify a         
diagnostic procedure, and shall describe its purpose.          
Reference may be made to section 3 of this document, as        
appropriate, for computer system operating instructions that   
support the diagnostic procedure.  This subparagraph shall     
describe:

=over

=item 1

Hardware, software, or firmware necessary for         
executing the procedure

=item 2

Step-by-step instructions for execution the procedure

=item 3

Diagnostic messages and the corresponding required    
action.

=back

=head2 10.1.6.3  Diagnostic tools.

This paragraph shall be numbered  
4.3 and shall be divided into the following subparagraphs to   
describe each diagnostic tool available to the computer        
operator.  A diagnostic tool may contain hardware, software,   
firmware, or a combination of these and provides diagnostic    
capabilities.

=head2 10.1.6.3.1  (Diagnostic tool name).

This subparagraph shall   
be numbered 4.3.X (beginning with 4.3.1), shall identify a     
diagnostic tool by name and shall describe the tool and its    
application.

=head2 10.1.7  Notes.

This section shall be numbered 6 and shall     
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
handling.  Appendixes shall be lettered alphabetically (A,B,   
etc.), and the paragraphs within each appendix be numbered as  
multiples of 10 (e.g., Appendix A, paragraph 10, 10.1, 10.2,   
20, 20.1, 20.2, etc.).  Pages within each appendix shall be
numbered alpha-numerically as follows:  Appendix A pages shall 
be numbered A-1, A-2, A-3, etc.  Appendix B pages shall be     
numbered B-1, B-2, B-3, etc.

=head1 11. DISTRIBUTION STATEMENT

Approved for public release;
distribution in unlimited. 

DD Form 1664, JUN 86         Previous editions are obsolete
