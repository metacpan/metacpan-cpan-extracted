#!perl
#
#
package Docs::US_DOD::VDD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.07';
$DATE = '2003/09/15';

use vars qw($IDENTIFICATION_NUMBER $TITLE $REVISION $REVISION_DATE);
$IDENTIFICATION_NUMBER  = 'DI-MCCR-80013A';
$TITLE = 'Version Description Document (VDD)';
$REVISION = 'A';
$REVISION_DATE = '2/29/1988';

1

__END__

=head1 DATA ITEM DESCRIPTION

Form Approved OMB No. 0704-0188 1.

The following establishes the data general and content
requirements for the identified data item. 

=head1 1. Title

VERSION DESCRIPTION DOCUMENT (VDD)

=head1 2. IDENTIFICATION NUMBER

DI-MCCR-80013A

=head1 3. DESCRIPTION/PURPOSE

=head2 3.1  

The Version Description Document (VDD) identifies and describes 
a version of a Computer Software Configuration Item (CSCI).

=head2 3.2

The VDD is used by the contractor to release CSCI versions to the 
Government.  The term "version" may be applied to the initial release 
of a CSCI, to a subsequent release of that CSCI, or to one of multiple 
forms of the CSCI released at approximately the same time (e.g., to  
different sites).

=head2 3.3

The VDD is used by the Government to track and control versions 
of software to be released to the operational environment.

=head1 4. APPROVAL DATE 

(YYMMDD) 880229

=head1 5. OFFICE OF PRIMARY RESPONSIBILITY

(OPR) EC

=head1 6.

6a. DTIC APPLICABLE

6b. GIDEP APPLICABLE

=head1 7. APPLICATION/INTERRELATIONSHIP

=head2 7.1  

This Data Item Description (DID) contains the format and content 
preparation instructions for data generated under the work tasks     
described by paragraph 5.7.5.1 of DOD-STD-2167A and 80.5.4 of MILSTD- 
483.

=head2 7.2

The Contract Data Requirements List should specify whether this 
document is to be prepared and delivered on bound 8 1/2 by 11 inch   
bond paper or electronic media. If electronic media is selected, the 
precise format must be specified.

=head2 7.3

The VDD is used as part of the Configuration Management applied 
to a CSCI.

=head2 7.4

The VDD identifies, by reference to the applicable Engineering  
Change Proposal (ECP), DI-E-3128, and Specification Change Notice    
(SCN), DI-E-3134, all changes to the software since the last VDD was 
issued.

=head2 7.5  This DID supersedes DI-MCCR-80013 dated 4 June 1985.

8. APPROVAL LIMITATION

9a. APPLICABLE FORMS

9b. AMSC NUMBER

N4331

=head1 10. PREPARATION INSTRUCTIONS

=head2 10.1  Reference document.  

The applicable issue of the document cited 
herein, including its approval date and dates of any applicable      
amendments, notices, and revisions, shall be as specified in the     
contract.

=head2 10.2  Content and format instructions.

Production of this document  
using automated techniques is encouraged. Specific content and format 
nstructions for this document are identified below.

=over 4

=item a. Response to tailoring instructions.

In the event that a    
paragraph or subparagraph has been tailored out, a statement 
to that effect shall be added directly following the heading 
of each such (sub)paragraph.  If a paragraph and all of its 
subparagraphs are tailored out, only the highest level      
paragraph heading need be included.

=item b. Use of alternate presentation styles.

Charts, tables,      
matrices, or other presentation styles are acceptable when  
the information required by the paragraphs and subparagraphs 
of this DID can be made more readable.

=item c. Page numbering. 

Each page prior to Section 1 shall be       
numbered in lower-case roman numerals beginning with page ii 
for the Table of Contents.  Each page starting from Section 
1 to the beginning of the appendixes shall be consecutively 
numbered in arabic numerals.  If the document is divided into 
volumes, each such volume shall restart the page numbering  
sequence.

=item d.  Document control numbers.

For hardcopy formats, this       
document may be printed on one or both sides of each page   
(single-sided/double-sided).  All printed pages shall contain 
the document control number and the date of the document    
centered at the top of the page. Document control numbers   
shall include revision and volume identification as         
applicable.

=item e.  Multiple (sub)paragraphs.

All paragraphs and subparagraphs 
starting with the phrase "This (sub)paragraph shall..." may 
be written as multiple subparagraphs to enhance readability. 
These subparagraphs shall be numbered sequentially.

=item f.  Document structure. This document shall consist of the      
following:

 (1) Cover
 (2) Title page
 (3) Table of contents
 (4) Scope
 (5) Referenced documents
 (6) Version description
 (7) Notes
 (8) Appendixes.

=back

=head2 10.2.1  Title page.  

The title page shall contain the information    
identified below in the indicated format:


   [Document control number and date: Volume x of y (if multi-volume)]

                      [Rev.indicator: date of Rev.]


                      VERSION DESCRIPTION DOCUMENT

                                 FOR THE

                               [CSCI NAME]

                                   OF

                              [SYSTEM NAME]


                     CONTRACT NO. [contract number]

                     CDRL SEQUENCE NO. [CDRL number]

                              Prepared for:

               [Contracting Agency Name, department code]

                              Prepared by:

                      [contractor name and address]


=head2 10.2.2  Table of contents.

This document shall contain a table of   
contents listing the title and page number of each titled paragraph  
and subparagraph. The table of contents shall then list the title and 
page number of each figure, table, and appendix, in that order.

=head2 10.2.3  Scope.

This section shall be numbered 1 and shall be divided 
into the following paragraphs.

=head2 10.2.3.1  Identification.

This paragraph shall be numbered 1.1 and  
shall contain the approved identification number, title, and         
abbreviation, if applicable, of the CSCI and the system to which this 
VDD applies.

=head2 10.2.3.2  System overview.

This paragraph shall be numbered 1.2 and 
shall briefly state the purpose of the system and the CSCI to which  
this VDD applies.

=head2 10.2.3.3  Documentation overview.

This paragraph shall be numbered  
1.3 and shall summarize the purpose and contents of this document.

=head2 10.2.4  Referenced documents.

This section shall be numbered 2 and  
shall list by document number and title all documents referenced in  
this document.  This section shall also identify the source for all  
documents not available through normal Government stocking activities.

=head2 10.2.5  Version description.

This section shall be numbered 3 and   
shall be divided into the following paragraphs.

=head2 10.2.5.1  Inventory of materials released.

This paragraph shall be  
numbered 3.1 and shall list all physical media (e.g., listings, tapes, 
cards, disks) and associated documentation that make up the new      
version.  This paragraph shall also identify all operation and support 
documents that are not a part of the delivered package, but that are 
required to operate, load, or regenerate the CSCI.

=head2 10.2.5.2  Inventory of CSCI contents.

This paragraph shall be       
numbered 3.2 and shall identify all computer software that is part of 
the delivered CSCI.  This software shall be identified in the same   
sequence as is used to organize the source code listings for delivery.

=head2 10.2.5.3  Class I changes installed.

This paragraph shall be numbered 
3.3 and shall contain a list of all Class II changes (as defined in  
DOD-STD-480) incorporated into the CSCI since the previous version,  
with a cross reference to the affected CSCI specifications.  This    
paragraph shall also indicate for each entry in this list the ECP    
number and date and the related SCN number and date.  Note: This     
paragraph does not apply to the initial version of a CSCI.

=head2 10.2.5.4  Class II changes installed.

This paragraph shall numbered 
3.4 and shall contain a list of all Class II changes (as defined in  
DOD-STD-480) incorporated into the CSCI since the previous version,  
with a cross reference to the affected CSCI specifications.  This    
paragraph shall also indicate for each entry in this list the ECP    
number and date, and the related SCN number and date. Note: This     
paragraph does not apply to the initial version of a CSCI.

=head2 10.2.5.5  Adaptation data.

This paragraph shall be numbered 3.5.  For 
the initial release of a CSCI, this paragraph shall identify or      
reference all unique-to-site data contained in the items being       
delivered. For subsequent CSCI versions, this paragraph shall contain 
the information necessary to identify changes made to the adaptation 
data.

=head2 10.2.5.6  Interface compatibility.

This paragraph shall be numbered  
3.6 and shall indicate other systems and configuration items affected 
by the changes incorporated in this version. Note: This paragraph does 
not apply to the initial version of a CSCI.

=head2 10.2.5.7  Bibliography of reference documents.

This paragraph shall be 
numbered 3.7. For the initial version of a CSCI, this paragraph shall 
list all documents pertinent to the CSCI. For subsequent CSCI        
versions, this paragraph shall identify changes to the listed        
documents.

=head2 10.2.5.8  Summary of change.

This paragraph shall be numbered 3.8 and 
shall contain a subparagraph describing the operational effect of each 
ECP listed in 3.3 and 3.4 above.

=head2 10.2.5.9  Installation instructions.

This paragraph shall be numbered 
3.9 and shall provide the instructions (either directly or by        
reference) for installing the CSCI version.

=head2 10.2.5.10  Possible problems and known errors.

This paragraph shall 
be numbered 3.10 and shall identify any possible problems or known   
errors with the CSCI version and any steps being taken to resolve the 
problems or errors.

=head2 10.2.6  Notes.

This section shall be numbered 4 and shall contain any 
general information that aids in understanding this document (e.g.,  
background information, glossary).  This section shall include an    
alphabetical listing of all acronyms, abbreviations, and their       
meanings as used in this document.

=head2 10.2.7  Appendixes.

Appendixes may be used to provide information   
published separately for convenience in document maintenance (e.g.,  
charts, classified data). As applicable, each appendix shall be      
referenced in the main body of the document where the data would     
normally have been provided. Appendixes may be bound as separate     
documents for ease in handling.  Appendixes shall be lettered        
alphabetically (A, B, etc.), and the paragraphs within each appendix 
be numbered as multiples of 10 (e.g., Appendix A, paragraph 10, 10.1, 
10.2, 20, 20.1, 20.2, etc.). Pages within each appendix shall be     
numbered alpha-numerically as follows:  Appendix A pages shall be    
numbered A-1, A-2, A-3, etc.  Appendix B pages shall be numbered B-1, 
B-2, B-3, etc.

=head1 11. DISTRIBUTION STATEMENT

Approved for public release;
distribution is unlimited.

DD Form 1664, JUN 86 Previous editions are obsolete

=cut

## end of file ##
