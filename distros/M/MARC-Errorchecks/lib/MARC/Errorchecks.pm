#!perl

package MARC::Errorchecks;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. @EXPORT = qw();

$VERSION = 1.18;

=head1 NAME

MARC::Errorchecks -- Collection of MARC 21/AACR2 error checks

=head1 DESCRIPTION

Module for storing MARC error checking subroutines,
based on MARC 21, AACR2, and LCRIs.
These are used to find errors not easily checked by
the MARC::Lint and MARC::Lintadditions modules,
such as those that cross field boundaries.

Each subroutine should generally be passed a MARC::Record object.

Returned warnings/errors are generated as follows:
push @warningstoreturn, join '', ($field->tag(), ": [ERROR TEXT]\t");
return \@warningstoreturn;

=head1 SYNOPSIS

 use MARC::Batch;
 use MARC::Errorchecks;

 #See also MARC::Lintadditions for more checks
 #use MARC::Lintadditions;

 #change file names as desired
 my $inputfile = 'marcfile.mrc';
 my $errorfilename = 'errors.txt';
 my $errorcount = 0;
 open (OUT, ">$errorfilename");
 #initialize $infile as new MARC::Batch object
 my $batch = MARC::Batch->new('USMARC', "$inputfile");
 my $errorcount = 0;
 #loop through batch file of records
 while (my $record = $batch->next()) {
  #if $record->field('001') #add this if some records in file do not contain an '001' field
  my $controlno = $record->field('001')->as_string();   #call MARC::Errorchecks subroutines

  my @errorstoreturn = ();

  # check everything

  push @errorstoreturn, (@{MARC::Errorchecks::check_all_subs($record)});

  # or only a few
  push @errorstoreturn, (@{MARC::Errorchecks::check_010($record)});
  push @errorstoreturn, (@{MARC::Errorchecks::check_bk008_vs_bibrefandindex($record)});

  # report results
  if (@errorstoreturn){
   #########################################
   print OUT join( "\t", "$controlno", @errorstoreturn, "\t\n");

   $errorcount++;
  }

 } #while

=head1 TO DO

Maintain check-all subroutine, a wrapper that calls all the subroutines in Errorchecks, to simplify calling code in .pl.

Determine whether extra tabs are being added to warnings.
Examine how warnings are returned and see if a better way is available.

Add functionality.

 -Ending punctuation (in Lintadditions.pm, and 300 dealt with here, and now 5xx (some)).
 -Matching brackets and parentheses in fields?
 -Geographical headings miscoded as subjects.
 
 Possibly rewrite as object-oriented?
 If not, optimize this and the Lintadditions.pm checks.
 Example: reduce number of repeated breaking-out of fields into subfield parts.
 So, subroutines that look for double spaces and double punctuation might be combined.

Remove local practice code or facilitate its modification/customization.

Deal with other TO DO items found below.
This includes fixing problem of "bibliographical references" being required if 008 contents has 'b'.

=cut

#########################################
########## Initial includes #############
#########################################

use MARC::Record;

#########################################
#########################################
#########################################

#########################################

=head2 check_all_subs

Calls each error-checking subroutine in Errorchecks.
Gathers all errors and returns those errors in an array (reference).

=head2 TO DO (check_all_subs)

Make sure to update this subroutine as additional subroutines are added.

=cut

sub check_all_subs {

    my $record = shift;
    my @errorstoreturn = ();

    #call each subroutine and add its errors to @errorstoreturn

    push @errorstoreturn, (@{check_internal_spaces($record)});

    push @errorstoreturn, (@{check_trailing_spaces($record)});

    push @errorstoreturn, (@{check_double_periods($record)});

    push @errorstoreturn, (@{check_006($record)});

    push @errorstoreturn, (@{check_008($record)});

    push @errorstoreturn, (@{check_010($record)});

    push @errorstoreturn, (@{check_end_punct_300($record)});

    push @errorstoreturn, (@{check_bk008_vs_300($record)});

    push @errorstoreturn, (@{check_490vs8xx($record)});

    push @errorstoreturn, (@{check_240ind1vs1xx($record)});

    push @errorstoreturn, (@{check_245ind1vs1xx($record)});

    push @errorstoreturn, (@{matchpubdates($record)});

    push @errorstoreturn, (@{check_bk008_vs_bibrefandindex($record)});

    push @errorstoreturn, (@{check_041vs008lang($record)});

    push @errorstoreturn, (@{check_5xxendingpunctuation($record)});

    push @errorstoreturn, (@{findfloatinghyphens($record)});

    push @errorstoreturn, (@{check_floating_punctuation($record)});

    push @errorstoreturn, (@{video007vs300vs538($record)});

    push @errorstoreturn, (@{ldrvalidate($record)});

    push @errorstoreturn, (@{geogsubjvs043($record)});

    push @errorstoreturn, (@{findemptysubfields($record)});

    push @errorstoreturn, (@{check_040present($record)});

    push @errorstoreturn, (@{check_nonpunctendingfields($record)});

    #push @errorstoreturn, (@{check_fieldlength($record)});



## add more here ##
##push @errorstoreturn, (@{});

    return \@errorstoreturn;

} # check_all_subs


#########################################
#########################################
#########################################
#########################################



#########################################
#########################################
#########################################
#########################################

=head2 is_RDA($record)

Checks to see if record is coded as an RDA record or not (based on 040$e).

=cut

sub is_RDA {

    #get passed MARC::Record object
    my $record = shift;
    my $is_RDA_record = 0;

    #declaration of return array
    if ($record->field('040')) {
        my $field040 = $record->field('040');
        if ($field040->subfield('e')) {
            if ($field040->subfield('e') =~ /^rda$/) {
                $is_RDA_record = 1;
            }#if 040 is rda
        } #if 040 has subfield e
    } #if 040

    return $is_RDA_record;

} #is_RDA($record)

#########################################
#########################################
#########################################
#########################################

=head2 check_double_periods($record)

Looks for more than one period within subfields after 010.
Exception: Exactly 3 periods together are treated as ellipses.

Looks for multiple commas.

=head2 TO DO (check_double_periods)

Find exceptions where double periods may be allowed.
Find exceptions where more than 3 periods can be next to each other.
Find exceptions where double commas are allowed (URI subfields, 856 field).

Deal with the exceptions. Currently, skips 856 field completely. Needs to skip URI subfields.

=cut

sub check_double_periods {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();


    #get all fields in record
    my @fields = $record->fields();

    foreach my $field (@fields) {
        my $tag = $field->tag();
        #skip non-numeric tags
        next unless ($tag =~ /^[0-9][0-9][0-9]$/);
        #skip tags lower than 011
        next if ($tag <= 10);
        #skip 856
        next if ($tag eq '856');
        my @subfields = $field->subfields();
        my @newsubfields = ();

        #break subfields into code-data array (so the entire field is in one array)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            unshift (@newsubfields, $code, $data);
        } # while

        #examine data portion of each subfield
        for (my $index = 1; $index <=$#newsubfields; $index+=2) {
            my $subdata = $newsubfields[$index];
            #report subfield data with more than one period but not exactly 3
            if (($subdata =~ /\.\.+/) && ($subdata !~ /\.\.\.[^\.]*/)) { 

                push @warningstoreturn, join '', ($tag, ": has multiple consecutive periods that do not appear to be ellipses.");

            } #if has multiple periods
            #report subfield data with more than one comma
            if ($subdata =~ /\,\,+/) { 

                push @warningstoreturn, join '', ($tag, ": has multiple consecutive commas.");

            } #if has multiple commas
        } #for each subfield
    } #for each field

    return \@warningstoreturn;


} # check_double_periods

#########################################
#########################################
#########################################
#########################################

=head2 check_internal_spaces($record)

Looks for more than one space within subfields after 010.
Ignores 035 field, since multiple spaces could be allowed.
Accounts for extra spaces between angle brackets for open date in 260c. Current version allows extra spaces in any 260 subfield containing angle brackets.


=head2 TO DO (check_internal_spaces)

Account for non-numeric tags? Will likely complain for non-numeric tags in a record, since comparisons rely upon numeric tag checking.

=cut

sub check_internal_spaces {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #get all fields in record
    my @fields = $record->fields();

    foreach my $field (@fields) {
        my $tag = $field->tag();
        #skip non-numeric tags
        next unless ($tag =~ /^[0-9][0-9][0-9]$/);
        #skip tags lower than 011
        next if ($tag <= 10);
        #skip 035 field as well
        next if ($tag eq '035');
        #skip 787 field as well
        next if ($tag eq '787');

        my @subfields = $field->subfields();
        my @newsubfields = ();

        #break subfields into code-data array (so the entire field is in one array)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            unshift (@newsubfields, $code, $data);
        } # while

        #examine data portion of each subfield
        for (my $index = 1; $index <=$#newsubfields; $index+=2) {
            my $subdata = $newsubfields[$index];

            #report subfield data with more than one space
            if (my @internal_spaces = ($subdata =~ /(.{0,10}  +?.{0,10})/g)) {
                #warn, with exception for 260c with open date in angle brackets
                push @warningstoreturn, join '', ($tag, ": has multiple internal spaces (", (join '_', @internal_spaces), ").") unless (($tag eq '260') && ($subdata =~ /\<.*?\>/));
            } #if has multiple spaces


########################################
### added check for space at beginning of field
########################################
            if ($subdata =~ /^ /) {
                #skip 016 field
                return \@warningstoreturn if ($tag eq '016');
                push @warningstoreturn, join '', ($tag, ": Subfield starts with a space.");
            } #if has multiple spaces
########################################
########################################

        } #for each subfield
    } #for each field

    return \@warningstoreturn;

} # check_internal_spaces

#########################################
#########################################
#########################################
#########################################

=head2 check_trailing_spaces($record)

Looks for extra spaces at the end of fields greater than 010.
Ignores 016 extra space at end.

=head2 TO DO (check_trailing_spaces)

Rewrite to incorporate 010 and 016 space checking.

Consider allowing trailing spaces in 035 field.

=cut

sub check_trailing_spaces {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #look at each field in record
    foreach my $field ($record->fields()) {
        my $tag = $field->tag();
        #skip non-numeric tags
        next unless ($tag =~ /^[0-9][0-9][0-9]$/);
        #skip control fields and LCCN (010)
        next if ($tag <= 10);
        #skip 016 fields
        next if ($tag eq '016');

        #create array holding arrayrefs for subfield code and data
        my @subfields= $field->subfields();

        #look at data in last subfield
        my $lastsubfield = pop (@subfields);

        #each $subfield is an array ref containing a subfield code character and subfield data
        my ($code, $data) = @$lastsubfield;

        #look for one or more instances of spaces at end of subfield data
        if ($data =~ /\s+$/) {
            #field had extra spaces
            push @warningstoreturn, join '', ($tag, ": has trailing spaces.");
        } #if had extra spaces
    } #foreach field

    return \@warningstoreturn;

} # check_trailing_spaces

#########################################
#########################################
#########################################
#########################################

=head2 check_006($record)

Code for validating 006s in MARC records.
Validates each byte of the 006, based on #MARC::Errorchecks::validate008($field008, $mattype, $biblvl)

=head2 TO DO (check_006)

Use validate008 subroutine:
 -Break byte 18-34 checking into separate sub so it can be used for 006 validation as well.
 -Optimize efficiency.

 
=cut

sub check_006 {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #get 006 fields from record
    my @fields006 = $record->field('006') if $record->field('006');
    #done if no 006
    return \@warningstoreturn unless (@fields006);

FIELD:    foreach my $field006 (@fields006) {
        my $field006_string = $field006->as_string();
        unless (length($field006_string) eq 18) {
            my $length006 = length($field006_string);
            push @warningstoreturn, "006: Must be 18 bytes long but is $length006 bytes long ($field006_string).";
            next FIELD;

        } #unless 18 bytes
        else {
            #call _validate006 subroutine from Errorchecks.pm (this package)
            push @warningstoreturn, @{MARC::Errorchecks::_validate006($field006_string)};

        } #else 18 bytes
    } #foreach 006
    
    return \@warningstoreturn;

} # check_006

#########################################
#########################################
#########################################
#########################################

=head2 check_008($record)

Code for validating 008s in MARC records.
Validates each byte of the 008, based on MARC::Errorchecks::validate008($field008, $mattype, $biblvl)

=head2 TO DO (check_008)

Improve validate008 subroutine (see that sub for more information):
 -Break byte 18-34 checking into separate sub so it can be used for 006 validation as well.
 -Optimize efficiency.

Revised 12-2-2004 to use new validate008() sub.
 
=cut

sub check_008 {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    # set variables needed for 008 validation
    my $leader = $record->leader();
    #$mattype and $biblvl are from LDR/06 and LDR/07
    my $mattype = substr($leader, 6, 1); 
    my $biblvl = substr($leader, 7, 1);
    my $field008 = $record->field('008')->as_string() if $record->field('008');
    
    #report missing 008 field
    unless ($field008) {
        push @warningstoreturn, ("008: Record lacks 008 field") ;
        return \@warningstoreturn;
    } #unless field 008 exists
    
    #call validate008 subroutine from Errorchecks.pm (this package)
    @warningstoreturn = @{MARC::Errorchecks::validate008($field008, $mattype, $biblvl)};

    return \@warningstoreturn;

} # check_008

#########################################
#########################################
#########################################
#########################################

=head2 check_010($record)

Verifies 010 subfield 'a' has proper spacing.

=head2 TO DO (check_010)

Compare efficiency of getting current date vs. setting global current date. Determine best way to establish global date.

Think about whether subfield 'z' needs proper spacing.

Deal with non-digit characters in original 010a field.
Currently these are simply reported and the space checking is skipped.

Revise local treatment of LCCN checking (invalid 8-digits pre-1980) for more universal use.

Maintain date ranges in checking validity of numbers.

Modify date ranges according to local catalog needs.

Determine whether this subroutine can be implemented in MARC::Lintadditions/Lint--I don't remember why it is here rather than there?

=cut


sub check_010 {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #set current year for validation of year portion of 10-digit LCCNs
    my $current_date = _get_current_date();
    my $current_year = substr($current_date, 0, 4);

##############################################
## Declare variables needed for each record ##
##############################################

    # $field_010 will have MARC::Field version of the 010 field of the record
    my $field_010 = '';
    #$cleaned010a will have the finished cleaned 010a data
    my $cleaned010a = '';

    #skip records with no 010 and no 010$a
    unless (($record->field('010')) && ($record->field('010')->subfield('a'))) {return \@warningstoreturn;}

    # record has an 010 with subfield a, so check for errors and then do cleanup
    else {

        $field_010 = $record->field('010');
        # $orig010a contains base subfield 'a' for comparison
        my $orig010a = $field_010->subfield('a');
        # $subfielda will be cleaned and then compared with the original
        my $subfielda = $field_010->subfield('a');

        #Get number portion of subfield
        $subfielda =~ s/^\D*(\d{8,10})\b\D*.*$/$1/;
        #report error if 8-10 digit number was not found
        unless ($1) {
            push @warningstoreturn, ("010: Could not find an 8-10 digit number in subfield 'a'.");
            #no need to continue processing 010a so return
            return \@warningstoreturn;
        } #unless 8-10 digit number found in 010a

#######################################################
# LCCN validity checks and setting of cleaned version # 
#######################################################
        #check validity of resulting digits
        if ($subfielda =~ /^\d{8}$/) {

=head2 local practice

 #this section could be implemented to validate 8-digit LCCN being between a specific set of years (1900-1980, for example).

 #code has been commented/podded out for general practice
            my $year = substr($subfielda, 0, 2);
            #should be old lccn, so first 2 digits are 00 or > 80
            #The 1980 limit is a local practice.
            #Change the date ranges according to local needs (e.g. if LC records back to 1900 exist in the catalog, do not implement this section of the error check)
            if (($year >= 1) && ($year < 80)) {push @warningstoreturn, ("010: First digits of LCCN are $year.");}

=cut

            #8 digit lccn needs 3 spaces before, 1 after, so put that in $cleaned010a
            #else year is valid
            ##used in case local practice year validation is being done
                $cleaned010a = "   $subfielda ";
            #end else if year check implemented
        } #if lccn is 8 digits

        #otherwise if $subfielda is 10 digits
        elsif ($subfielda =~ /^\d{10}$/) {
            my $year = substr($subfielda, 0, 4);
            # no valid 10 digit will be less than 2001
            if (($year < 2001) || ($year > $current_year)) {push @warningstoreturn, ("010: First digits of LCCN are $year.");}
            #otherwise, 10 digit lccn needs 2 spaces before, 0 after, so put that in $cleaned010a
            else {
                $cleaned010a = "  $subfielda";
            } #else $subfielda has valid lccn
        } #elsif lccn is 10 digits

        # lccn is not 8 or 10 digits so report error
        else {
            #should have already returned but just in case,
            push @warningstoreturn, ("010: LCCN subfield 'a' is not 8 or 10 digits");
        } #else not 8-10 digits?

        #return if warnings have been found to this point
        if (@warningstoreturn) {return \@warningstoreturn;}

###########################################
### Compare cleaned field with original ###
###########################################

        #if original and cleaned match, go to next record
        if ($orig010a eq $cleaned010a) {return \@warningstoreturn;}
        #elsif non-digits are present in 010a
        elsif ($orig010a =~ /[^ 0-9]/) {
            my $orig010a_lccn = $orig010a;
            #get uncleaned numeric portion
            $orig010a_lccn =~ s/^( *\d+ *).*/$1/;
            #report error if non-digits are in number portion 
            ##(shouldn't happen as should have returned above)
            if ($subfielda !~ /^[ \d]*$/) {push @warningstoreturn, ("010: Subfield 'a' has non-digits ($orig010a).");} #if non-digits
            elsif ($orig010a_lccn eq $cleaned010a) {return \@warningstoreturn;}
            else {
                push @warningstoreturn, ("010: Subfield 'a' has improper spacing ($orig010a).");
            } #else improper spacing
        } #elsif non-digits in 010a
        else {
            push @warningstoreturn, ("010: Subfield 'a' has improper spacing ($orig010a).");

        } #else original and cleaned 010 do not match
    } # else record has 010subfielda


    return \@warningstoreturn;


} # check_010

#########################################
#########################################
#########################################
#########################################

=head2 NAME

check_end_punct_300($record)

=head2 DESCRIPTION

Reports an error if an ending period in 300 is missing if 4xx exists, or if 300 ends with closing parens-period if 4xx does not exist.

=cut


sub check_end_punct_300 {

    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #get leader and retrieve its relevant bytes
    my $leader = $record->leader();
    #$encodelvl ('8' for CIP, ' ' [space] for 'full')
    my $encodelvl = substr($leader, 17, 1);


    #skip CIP-level records
    if ($encodelvl eq '8') {return \@warningstoreturn;}

    #retrieve any 4xx fields in record
    my @fields4xx = $record->field('4..');

    if ($record->field('300')) {
        my $field300 = $record->field('300');
        my @subfields = $field300->subfields();
        my @newsubfields = ();
    
        #break down code and data for last subfield
        my $subfield = pop(@subfields);
        my ($code, $data) = @$subfield;
        unshift (@newsubfields, $code, $data);

        #last subfield should end in period if 4xx exists
        if (@fields4xx && ($newsubfields[-1] !~ /\.$/)) {
            push @warningstoreturn, ("300: 4xx exists but 300 does not end with period.");
        }
        #last subfield should not end in closing parens-period unless 4xx exists
        elsif (($newsubfields[-1] =~ /\)\.$/) && !(@fields4xx)) {push @warningstoreturn, ("300: 4xx does not exist but 300 ends with parens-period."); 
        }
        #last subfield of RDA record should not end with period unless 4xx exists
        elsif (is_RDA($record) && ($newsubfields[-1] =~ /\.$/) && !(@fields4xx)) {
            push @warningstoreturn, ("300: 4xx does not exist but 300 ends with period.");
        }
    } #if 300 field exists

####testing ######
# see what records have no 300
    else {push @warningstoreturn, ("300: Record has no 300.");}
##########################################

    # report any errors
    return \@warningstoreturn;

} # check_end_punct_300

#########################################
#########################################
#########################################
#########################################

=head2 NAME

check_bk008_vs_300($record)

=head2 DESCRIPTION

300 subfield 'b' vs. presence of coding for illustrations in 008/18-21.

Ignores CIP records completely.
Ignores non-book records completely (for the purposes of this subroutine).

If 300 'b' has wording, reports errors if matching 008/18-21 coding is not present.
If 008/18-21 coding is present, but similar wording is not present in 300, reports errors.

Note: plates are an exception, since they are noted in $a rather than $b of the 300.
So, they need to be checked twice--once if 'f' is the only code in the 008/18-21, and again amongst other codes.

Also checks for 'p.' or 'v.' in subfield 'a'

=head2 LIMITATIONS

Only accounts for a single 300 field (300 was recently made repeatable).

Older/more specific code checking is limited due to lack of use (by our catalogers).
For example, coats of arms, facsim., etc. are usually now given as just 'ill.'
So the error check allows either the specific or just ill. for all except maps.

Depends upon 008 being coded for book monographs.

Subfield 'a' and 'c' wording checks ('p.' or 'v.'; 'cm.', 'in.', 'mm.') only look at first of each kind of subfield.

=head2 TO DO (check_bk008_vs_300($record))

Take care of case of 008 coded for serials/continuing resources.

Find exceptions to $a having 'p.' or 'v.' (and leaves, columns) for books.

Find exceptions to $c having 'cm.', 'mm.', or 'in.' preceded by digits.

Deal with other LIMITATIONS.

Account for upcoming rule change in which metric units have no punctuation.
When that rule goes into effect, move 300$c checking to check_end_punct_300($record).

Reverse checks to report missing 008 code if specific wording is present in 300.

Reverse check for plates vs. 'f'

=cut

sub check_bk008_vs_300 {

    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #declaration of variable for electronic resource vs. not
    my $is_electronic = 0;
    #determine whether record is RDA or not
    my $record_is_RDA = is_RDA($record);

    #get leader and retrieve its relevant bytes (mattype ('a' for 'books')), 
    #$encodelvl ('8' for CIP, ' ' [space] for 'full')
    #$biblvl will be useful in future version, where seriality matters

    my $leader = $record->leader();
    my $mattype = substr($leader, 6, 1); 
    #my $biblvl = substr($leader, 7, 1);
    my $encodelvl = substr($leader, 17, 1);


    #skip CIP-level records
    if ($encodelvl eq '8') {return \@warningstoreturn;
    }
#####################################
#####################################
### skip non-book records for now ###
    elsif ($mattype ne 'a') {return \@warningstoreturn;}
#####################################
#####################################
    #otherwise, match 008/18-21 vs. 300.
    else {

        my $field008 = $record->field('008')->as_string() if $record->field('008');
        return \@warningstoreturn unless $field008;

        if (($record->subfield('245', 'h')) && ($record->subfield('245', 'h') =~ /\[electronic resource\]/)) {
            $is_electronic = 1;
        } #if 245 _h has electronic resource

        #illustration codes are in bytes 18-21
        my $illcodes = substr($field008, 18, 4);
        my ($hasill, $hasmap, $hasport, $hascharts, $hasplans, $hasplates, $hasmusic, $hasfacsim, $hascoats, $hasgeneal, $hasforms, $hassamples, $hasphono, $hasphotos, $hasillumin);

        #make sure field 300 exists
        if ($record->field('300')) {
            #get 300 field as a MARC::Field object
            my $field300 = $record->field('300');
            #set variables for 
            my $subfielda = $field300->subfield('a') if ($field300->subfield('a'));
            my $subfieldb = $field300->subfield('b') if ($field300->subfield('b'));
            my $subfieldc = $field300->subfield('c') if ($field300->subfield('c'));

#######################################
### 300 subfield 'a' and 'c' checks ###
#######################################

            #Check for 'p.' or 'v.' or leaves in subfield 'a' unless electronic resource
            if ($subfielda) {
                unless ($is_electronic == 1) {
                    unless ($record_is_RDA) {
                        #error if no 'p.', 'v.', 'column', 'leaf', or 'leaves' found
                        push @warningstoreturn, ("300: Check subfield _a for p. or v.") unless (
                        ($subfielda =~  /\(?.*\b[pv]\.[,\) ]?/) ||
                        ($subfielda =~  /\(?.*\bcolumns?\)?/) ||
                        ($subfielda =~ / leaves /) ||
                        ($subfielda =~ / leaf /)
                         );
                        #error if 'p.' found after parenthetical qualifier on 'v.'
                        if (($subfielda =~  /\(((?:unpaged)|(?:various pagings))\) p\.?\b/)) {
                            push @warningstoreturn, ("300: Check subfield _a for extra p.")
                        } #if extra 'p.'
                    } #unless RDA record
                    else {
                        #error if no 'page(s)', 'volume(s)', 'column', 'leaf', or 'leaves' found
                        push @warningstoreturn, ("300: Check subfield _a for page(s) or volume(s)") unless (
                        ($subfielda =~  /\(?.*\bpages?[,\) ]?/) ||
                        ($subfielda =~  /\(?.*\bvolumes?[,\) ]?/) ||
                        ($subfielda =~  /\(?.*\bcolumns?\)?/) ||
                        ($subfielda =~ / leaves /) ||
                        ($subfielda =~ / leaf /)
                         );
                        #error if 'p.' found after parenthetical qualifier on 'v.'
                        if (($subfielda =~  /\(((?:unpaged)|(?:various pagings))\) p\.?\b/)) {
                            push @warningstoreturn, ("300: Check subfield _a for extra p.")
                        } #if extra 'p.'
                    }
                } #unless electronic resource
            } #if 300 subfielda exists
            #report missing subfield a
            else {
                push @warningstoreturn, ("300: Subfield _a is not present.");
            } #else $subfielda is undefined

            #check for 'cm.', 'mm.' or 'in.' in subfield 'c'
            if ($subfieldc) {
                unless ($record_is_RDA) {
                    push @warningstoreturn, ("300: Check subfield _c for cm., mm. or in.") unless ($subfieldc =~ /\d+ (([cm]m\.)|(in\.))/);
                } #unless RDA
                else {
                    push @warningstoreturn, ("300: Check subfield _c for cm, mm or in.") unless ($subfieldc =~ /\d+ (([cm]m)|(in\.))/);
                } #else RDA
            } #if subfield c
            #report missing subfield c
            else {
                push @warningstoreturn, ("300: Subfield _c is not present.");
            } #else $subfieldc is undefined
#######################################

            #if $subfieldb present with 'col', ensure period exists after all
            unless ($record_is_RDA) {
                if ($subfieldb && ($subfieldb =~ /col[^\.]/)) {
                    push @warningstoreturn, ("300: Check subfield _b for missing period after col.");
                } #if subfield b has 'col' with missing period
            } #unless RDA
            else {
                if ($subfieldb && ($subfieldb =~ /col\./)) {
                    push @warningstoreturn, ("300: Check subfield _b for abbreviated col.");
                } #if subfield b has 'col.' rather than colo(u)red
            }
##### 008 ill. vs. 300 wording basic checks 
            # if $illcodes not coded and no subfield 'b' no problem so move on
            if (($illcodes =~ /^\s{4}$/) && !($subfieldb)) {return \@warningstoreturn;} 
            # 008 is coded blank (4 spaces) but 300 subfield 'b' exists so error
            elsif (($illcodes =~ /^\s{4}$/) && ($subfieldb)) {push @warningstoreturn, ("008: bytes 18-21 (Illustrations) coded blank but 300 has subfield 'b'."); return \@warningstoreturn;} 
            # 008 has valid code but no 300 subfield 'b' so error
            elsif (($illcodes =~ /[a-e,g-m,o,p]/) && !($subfieldb)) {push @warningstoreturn, ("008: bytes 18-21 (Illustrations) have valid code but 300 has no subfield 'b'."); return \@warningstoreturn;} 

##############
            #otherwise, check 008/18-21 vs. 300 subfield 'b'
            # valid coding in 008/18-21 and have 300 $b
            elsif (($illcodes =~ /[a-e,g-m,o,p]/) && ($subfieldb)) {
                # start comparing
                #call subroutine to do main checking
                my $illcodewarnref = parse008vs300b($illcodes, $subfieldb, $record_is_RDA);
                push @warningstoreturn, (join "\t", @$illcodewarnref) if (@$illcodewarnref);

                #take care of special case of plates when other codes are present
                if (($illcodes =~ /f/) && ($subfielda)) {
                    #report error if 'plate' does not appear in 300$a
                    unless ($subfielda =~ /plate/) {push @warningstoreturn, ("300: bytes 18-21 (Illustrations) is coded f for plates but 300 subfield a is $subfielda "); 
                    } #unless subfield 'a' has plate(s)
                } #if 008ill. has 'f' but 300 does not have 'plate'(s) 
            } #elsif valid 008/18-21 and 300$b exists

            #elsif $illcodes is coded only 'f' (plates), which are noted in 300$a
            elsif (($illcodes =~ /f/) && ($subfielda)) {
                #report error if 'plate' does not appear in 300$a
                unless ($subfielda =~ /plate/) {
                    push @warningstoreturn, ("300: bytes 18-21 (Illustrations) is coded f for plates but 300 subfield a is $subfielda "); 
                    return \@warningstoreturn;
                } #unless subfield 'a' has plate(s)
            } #elsif 008ill. has 'f' but 300a does not have 'plate'(s)

            #otherwise, not valid 008/18-21
            else {
                push @warningstoreturn, ("008: bytes 18-21 (Illustrations) have a least one invalid character."); return \@warningstoreturn;
            } #else not valid 008/18-21
        } # if record has 300 field

        #else 300 does not exist in full book record so report error
        else {push @warningstoreturn, ("300: Record has no 300."); return \@warningstoreturn;}
    } #else (record is not CIP and is a book-type)

    return \@warningstoreturn;

} # check_bk008_vs_300($record)

#########################################
#########################################
#########################################
#########################################

=head2 NAME

 parse008vs300b($illcodes, $field300subb)
 
=head2 DESCRIPTION

008 illustration parse subroutine

checks 008/18-21 code against 300 $b

=head2 WHY?

To simplify the check_bk008_vs_300($record) subroutine, which had many if-then statements. This moves the additional checking conditionals out of the way.
It may be integrated back into the main subroutine once it works.
This was written while constructing check_bk008_vs_300($record) as a separate script.

=head2 Synopsis/Usage description

    parse008vs300b($illcodes, $field300subb)

 #$illcodes is bytes 18-21 of 008
 #$subfieldb is subfield 'b' of record's 300 field

=head2 TO DO (parse008vs300b($$))

Integrate code into check_bk008_vs_300($record)?

Verify possibilities for 300 text

Move 'm' next to 'f' since it is likely to be indicated in subfield 'e' not 'b' of the 300.
Our catalogers do not generally code for sound recordings in this way in book records.

=cut

sub parse008vs300b {

    my $illcodes = shift;
    my $subfieldb = shift;
    my $record_is_RDA = shift;
    #parse $illcodes
    my ($hasill, $hasmap, $hasport, $hascharts, $hasplans, $hasplates, $hasmusic, $hasfacsim, $hascoats, $hasgeneal, $hasforms, $hassamples, $hasphono, $hasphotos, $hasillumin);
    ($illcodes =~ /a/) ? ($hasill = 1) : ($hasill = 0);
    ($illcodes =~ /b/) ? ($hasmap = 1) : ($hasmap = 0);
    ($illcodes =~ /c/) ? ($hasport = 1) : ($hasport = 0);
    ($illcodes =~ /d/) ? ($hascharts = 1) : ($hascharts = 0);
    ($illcodes =~ /e/) ? ($hasplans = 1) : ($hasplans = 0);
    ($illcodes =~ /f/) ? ($hasplates = 1) : ($hasplates = 0);
    ($illcodes =~ /g/) ? ($hasmusic = 1) : ($hasmusic = 0);
    ($illcodes =~ /h/) ? ($hasfacsim = 1) : ($hasfacsim = 0);
    ($illcodes =~ /i/) ? ($hascoats = 1) : ($hascoats = 0);
    ($illcodes =~ /j/) ? ($hasgeneal = 1) : ($hasgeneal = 0);
    ($illcodes =~ /k/) ? ($hasforms = 1) : ($hasforms = 0);
    ($illcodes =~ /l/) ? ($hassamples = 1) : ($hassamples = 0);
    ($illcodes =~ /m/) ? ($hasphono = 1) : ($hasphono = 0);
    ($illcodes =~ /o/) ? ($hasphotos = 1) : ($hasphotos = 0);
    ($illcodes =~ /p/) ? ($hasillumin = 1) : ($hasillumin = 0);

    my @illcodewarns = ();

    # Check and report errors

    #if 008/18-21 has code 'a', 300$b needs to have 'ill.'
    if ($hasill) {
        unless ($record_is_RDA) {
            push @illcodewarns, ("300: bytes 18-21 have code 'a' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /ill\./);
        } #unless RDA
        else {
            if ($subfieldb =~ /ill\./) {
                push @illcodewarns, ("300: Check for abbreviated 'ill.'");
            }
            else {
                push @illcodewarns, ("300: bytes 18-21 have code 'a' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /illustration/);
            } #else no "illustration" in 300 with 008 coded with 'a'
        } #else RDA
    } #if hasill
    # if 300$b has 'ill.', 008/18-21 should have 'a'
    elsif (!$record_is_RDA && ($subfieldb =~ /ill\./)) {push @illcodewarns, ("008: Bytes 18-21 do not have code 'a' but 300 subfield 'b' has 'ill.'")}
    elsif ($record_is_RDA) {
        if ($subfieldb =~ /illustration/) {
            push @illcodewarns, ("008: Bytes 18-21 do not have code 'a' but 300 subfield 'b' has 'illustration'")
        } #if illustration in 300 and no 'a' in 008
        elsif ($subfieldb =~ /ill\./) {
            push @illcodewarns, ("008: Bytes 18-21 do not have code 'a' but 300 subfield 'b' has 'ill.'", "300: Check for abbreviated 'ill.'")
        }
    }

    #if 008/18-21 has code 'b', 300$b needs to have 'map' (or 'maps') 
    if ($hasmap) {push @illcodewarns, ("300: bytes 18-21 have code 'b' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /map[ \,s]/);}
    # if 300$b has 'map', 008/18-21 should have 'b'
    elsif ($subfieldb =~ /map/) {push @illcodewarns, ("008: Bytes 18-21 do not have code 'b' but 300 subfield 'b' has 'map' or 'maps'")}

    #if 008/18-21 has code 'c', 300$b needs to have 'port.' or 'ports.' (or ill.) 
    if ($hasport) {
        unless ($record_is_RDA) {
            push @illcodewarns, ("300: bytes 18-21 have code 'c' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /port\.|ports\.|ill\./);
        } #unless RDA
        else {
            if ($subfieldb =~ /port\.|ports\./) {
                push @illcodewarns, ("300: Check for abbreviated 'port(s).'");
            }
            else {
                push @illcodewarns, ("300: bytes 18-21 have code 'c' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /portrait/);
            } #else no "illustration" in 300 with 008 coded with 'c'
        } #else RDA
    } #if hasill
    # if 300$b has 'port(s).', 008/18-21 should have 'c'
    elsif (!$record_is_RDA && ($subfieldb =~ /port\.|ports\./)) {push @illcodewarns, ("008: Bytes 18-21 do not have code 'c' but 300 subfield 'b' has 'port(s).'")}
    elsif ($record_is_RDA) {
        if ($subfieldb =~ /portrait/) {
            push @illcodewarns, ("008: Bytes 18-21 do not have code 'c' but 300 subfield 'b' has 'portrait'")
        } #if illustration in 300 and no 'a' in 008
        elsif ($subfieldb =~ /port\.|ports\./) {
            push @illcodewarns, ("008: Bytes 18-21 do not have code 'c' but 300 subfield 'b' has 'port(s).'", "300: Check for abbreviated 'port(s).'")
        }
    }
   
    #if 008/18-21 has code 'd', 300$b needs to have 'chart' (or 'charts') (or ill.) 
    if ($hascharts) {push @illcodewarns, ("300: bytes 18-21 have code 'd' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /chart|ill\.|illustration/);}
    #### add cross-check ###


    #if 008/18-21 has code 'e', 300$b needs to have 'plan' (or 'plans') (or ill.) 
    if ($hasplans) {push @illcodewarns, ("300: bytes 18-21 have code 'e' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /plan|ill\.|illustration/);}
    #### add cross-check ###

    ### Skip 'f' for plates, which are in 300$a ###

    #if 008/18-21 has code 'g', 300$b needs to have 'music' (or ill.) 
    if ($hasmusic) {push @illcodewarns, ("300: bytes 18-21 have code 'g' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /music|ill\.|illustration/);}
    # if 300$b has 'music', 008/18-21 should have 'g'
    elsif ($subfieldb =~ /music/) {push @illcodewarns, ("008: Bytes 18-21 do not have code 'g' but 300 subfield 'b' has 'music'")}

    #if 008/18-21 has code 'h', 300$b needs to have 'facsim.' or 'facsims.' (or ill.) 
    if ($hasfacsim) {push @illcodewarns, ("300: bytes 18-21 have code 'h' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /facsim\.|facsims\.|facimile|ill\.|illustration/);}
    #### add cross-check ###

    #if 008/18-21 has code 'i', 300$b needs to have 'coats of arms' (or 'coat of arms'?) (or ill.) 
    if ($hascoats) {push @illcodewarns, ("300: bytes 18-21 have code 'i' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /coats of arms|ill\.|illustration/);}
    #### add cross-check ###

    #if 008/18-21 has code 'j', 300$b needs to have 'geneal. table' (or 'geneal. tables') (or ill.) 
    if ($hasgeneal) {push @illcodewarns, ("300: bytes 18-21 have code 'j' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /geneal\. table|genealogical table|ill\.|illustration/);}
    #### add cross-check ###

    #if 008/18-21 has code 'k', 300$b needs to have 'forms' or 'form' (or ill.) 
    if ($hasforms) {push @illcodewarns, ("300: bytes 18-21 have code 'k' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /form[ s]|ill\.|illustration/);}
    #### add cross-check ###

    #if 008/18-21 has code 'l', 300$b needs to have 'samples' (or ill.) 
    if ($hassamples) {push @illcodewarns, ("300: bytes 18-21 have code 'l' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /samples|ill\.|illustration/);}
    #### add cross-check ###

##########################################
##########################################
### code 'm' appears to be for 'sound disc', 'sound cartridge', 'sound tape reel', 'sound cassette', 'roll' or 'cylinder'
#these would likely appear in subfield 'e' of the 300 (as accompanying material) for book records.
#so this should be treated separately, like plates ('f')
#This code is not used by our catalogers
    #if 008/18-21 has code 'm', 300$b needs to have 'phono'? (or ill.) 
    if ($hasphono) {push @illcodewarns, ("300: bytes 18-21 have code 'm' (phonodisc, sound disc, etc.).");}
##########################################
##########################################

    #if 008/18-21 has code 'o', 300$b needs to have 'photo.' or 'photos.' (or ill.) 
    if ($hassamples) {push @illcodewarns, ("300: bytes 18-21 have code 'o' but 300 subfield b is $subfieldb") unless ($subfieldb =~ /photo\.|photos\.|photograph|ill\.|illustration/);}
    #### add cross-check ###

##########################################
##########################################
### I don't know what this is, so for this, report all
    #if 008/18-21 has code 'p', 300$b needs to have 'illumin'? (or ill.) 
    if ($hasillumin) {push @illcodewarns, ("300: bytes 18-21 have code 'p' but 300 subfield b is $subfieldb");}
    #### add cross-check ###
##########################################
##########################################

    return \@illcodewarns;

} #sub parse008vs300b


#########################################
#########################################
#########################################
#########################################

=head2 check_490vs8xx($record)

If 490 with 1st indicator '1' exists, then 8xx (800, 810, 811, 830) should exist.

=cut

sub check_490vs8xx {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    my $has_series_field = 0;
    my @series_fields = ('800', '810', '811', '830');

    $has_series_field = 1 if ($record->field(@series_fields));

    #report error if 490 1st ind is 1 but 8xx does not exist
    if ($record->field(490) && ($record->field(490)->indicator(1) eq '1')) {
        push @warningstoreturn, ("490: Indicator is 1 but 8xx does not exist.") unless ($has_series_field);
    }

    return \@warningstoreturn;

} # check_490vs8xx

#########################################
#########################################
#########################################
#########################################

#########################################
#########################################
#########################################
#########################################

=head2 check_240ind1vs1xx($record)

If 1xx exists then 240 1st indicator should be '1'. 
If 1xx does not exist then 240 should not be present.

However, exceptions to this rule are possible, so this should be considered an optional error.

=cut

sub check_240ind1vs1xx {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #report error if 240 exists but 1xx does not exist
    if (($record->field(240)) && !($record->field('1..'))) {
        push @warningstoreturn, ("240: Is present but 1xx does not exist.");
    }
    
    #report error if 240 1st ind is 0 but 1xx exists
    elsif (($record->field(240)) && ($record->field(240)->indicator(1) eq '0') && ($record->field('1..'))) {
        push @warningstoreturn, ("240: First indicator is 0 but 1xx exists.");
    }

    return \@warningstoreturn;

} # check_240ind1vs1xx

#########################################
#########################################
#########################################
#########################################

=head2 check_245ind1vs1xx($record)

If 1xx exists then 245 1st indicator should be '1'. 
If 1xx does not exist then 245 1st indicator should be '0'.

However, exceptions to this rule are possible, so this should be considered an optional error.

=head2 TODO (check_245ind1vs1xx($record))

Provide some way to easily turn off reporting of "245: Indicator is 0 but 1xx exists." errors. In some cases, catalogers may choose to code a 245 with 1st indicator 0 if they do not wish that 245 to be indexed. There is not likely a way to programmatically determine this choice by the cataloger, so in situations where catalogers are likely to choose not to index a 245, this error should be supressed.

=cut

sub check_245ind1vs1xx {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #report error if 245 1st ind is 1 but 1xx does not exist
    if (($record->field(245)->indicator(1) eq '1')) {
        push @warningstoreturn, ("245: Indicator is 1 but 1xx does not exist.") unless ($record->field('1..'));
    } #if 245 1st ind. is 1
    #report error if 245 1st ind is 0 but 1xx exists
    elsif (($record->field(245)->indicator(1) eq '0')) {
        #comment out the line below if your records have unindexed 245s by cataloger's choice
        push @warningstoreturn, ("245: Indicator is 0 but 1xx exists.") if ($record->field('1..'));
    } #elsif 245 1st ind. is 0

    return \@warningstoreturn;

} # check_245ind1vs1xx

#########################################
#########################################
#########################################
#########################################


=head2 matchpubdates($record)

Date matching 008, 050, 260

Attempts to match date of publication in 008 date1, 050 subfield 'b', and 260 subfield 'c'.

Reports errors when one of the fields does not match.
Reports errors if one of the dates cannot be found

Handles cases where 050 or 260 (or 260c) does not exist.
-Currently if the subroutine is unable to get either the date1, any 050 with $b, or a 260 with $c, it returns (exits).
-Future, or better, behavior, might be to continue processing for the other fields.

Handles cases where 050 is different due to conference dates.
Conference exception handling is currently limited to presence of 111 field or 110$d.

For RDA, checks 264 _1 $c as well as 1st 260$c.

=head2 KNOWN PROBLEMS

May not deal well with serial records (problem not even approached).

Only examines 1st 260, does not account for more than one 260 (recent addition).

Relies upon 260$c date being the first date in the last 260$c subfield.

Has problem finding 050 date if it is not last set of digits in 050$b.

Process of getting 008date1 duplicates similar check in C<validate008> subroutine.

=head2 TO DO

Improve Conference publication checking (limited to 111 field or 110$d being present for this version)
This may include comparing 110$d or 111$d vs. 050, and then comparing 008date1 vs. 260$c.

Fix parsing for 050$bdate.

For CIP, if 260 does not exist, compare only 050 and 008date1.
Currently, CIP records without 260 are skipped.

Account for undetermined dates, e.g. [19--?] in 260 and 008.

Account for older 050s with no date present.

=cut

sub matchpubdates {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();
    my $record_is_RDA = is_RDA($record);

    #get leader and retrieve its relevant bytes, 
    #$encodelvl ('8' for CIP, ' ' [space] for 'full')

    my $leader = $record->leader();
    my $encodelvl = substr($leader, 17, 1);

########################################
####### may be used in future ##########
# my $mattype = substr($leader, 6, 1); # 
# my $biblvl = substr($leader, 7, 1);  #
########################################

    #skip CIP-level records unless 260 exists
    if ($encodelvl eq '8') {return \@warningstoreturn  unless ($record->field('260', '264'));}

    my $field008 = $record->field('008')->as_string() if ($record->field('008'));
    return \@warningstoreturn unless ($field008);

    #date1 is in bytes 7-10
    my $date1 = substr($field008, 7, 4);

    #report error in getting $date1
    ## then ignore the rest of the record
    ###need to account for dates such as '19--'
    unless ($date1 && ($date1 =~ /^\d{4}$/)) {push @warningstoreturn, ("008: Could not get date 1."); return \@warningstoreturn;
    } 

    #get 050(s) if it (they) exist(s)
    my @fields050 = $record->field('050') if (($record->field('050')) && $record->field('050')->subfield('b'));
    #report error in getting at least 1 050 with subfield _b
    ##then ignore the rest of the record
    unless (@fields050) {push @warningstoreturn, ("050: Could not get 050 or 050 subfield 'b'."); return \@warningstoreturn;
    }

    #get 050 date, make sure each is the same if there are multiple fields

    my @dates050 = ();
    #look for date at end of $b in each 050
    foreach my $field050 (@fields050) {
        if ($field050->subfield('b')) {
            my $subb050 = $field050->subfield('b');
            #remove nondigits and look for 4 digits
            $subb050 =~  s/^.*?\b(\d{4}){1}\D*.*$/$1/;
            #add each found date to @dates050
            push @dates050, ($subb050) if ($subb050 =~ /\d{4}/);
        } # if 050 has $b
    } #foreach 050 field

    #compare each date in @dates050
    while (scalar @dates050 > 1) {
        #compare first and last
        ($dates050[0] == $dates050[-1]) ? (pop @dates050) : (push @warningstoreturn, ("050: Dates do not match in each of the 050s."));
        #stop comparing if dates don't match
        last if @warningstoreturn;
    } # while  @dates050 has more than 1 date

    my $date050 = '';

    #if successful, only one date will remain and @warningstoreturn will not have an 050 error
    if (($#dates050 == 0) && ((join "\t", @warningstoreturn) !~ /Dates do not match in each of the 050s/)) {

        # set $date050 to the date in @dates050 if it is exactly 4 digits
        if ($dates050[0] =~ /^\d{4}$/) {$date050 = $dates050[0];}
        else {push @warningstoreturn, ("050: Unable to find 4 digit year in subfield 'b'."); 
            return \@warningstoreturn;
        } #else
    } #if have 050 date without error 

    my $date260 = '';
    unless ($record_is_RDA) {
        #get 260 field if it exists and has a subfield 'c'
        my $field260 = $record->field('260') if (($record->field('260')) && $record->field('260')->subfield('c'));
        unless ($field260) {push @warningstoreturn, ("260: Could not get 260 or 260 subfield 'c'."); return \@warningstoreturn;
        }

        #look for date in 260 _c (starting at the end of the field)
        ##only want first date in last subfield _c

        my @subfields = $field260->subfields();
        my @newsubfields = ();
        my $wantedsubc;
        #break subfields into code-data array
        #stop when first subfield _c is reached (should be the last subfield _c of the field)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            if ($code eq 'c' ) {$wantedsubc = $data; last;}
            #should not be necessary to rebuild 260
            #unshift (@newsubfields, $code, $data);
        } # while


        #extract 4 digit date portion
        # account for [i.e. [date]]
        unless ($wantedsubc =~ /\[i\..?e\..*(\d{4}).*?\]/) {
            $wantedsubc =~ s/^.*?\b\D*(\d{4})\D*\b.*$/$1/;
        }
        else {$wantedsubc =~ s/.*?\[i\..?e\..*(\d{4}).*?\].*/$1/;
        }

        if ($wantedsubc =~ /^\d{4}$/) {$date260 = $wantedsubc;}
        # i.e. date should be 2nd string of 4 digits
        elsif ($wantedsubc =~ /^\d{8}$/) {$date260 = substr($wantedsubc,4,4);}
        else {push @warningstoreturn, ("260: Unable to find 4 digit year in subfield 'c'."); return \@warningstoreturn;
        }
    } #unless RDA
    elsif ($record_is_RDA && ($record->field('260') && $record->field('260')->subfield('c'))) {
        #get 260 field if it exists and has a subfield 'c'
        my $field260 = $record->field('260') if (($record->field('260')) && $record->field('260')->subfield('c'));
        unless ($field260) {push @warningstoreturn, ("260: Could not get 260 or 260 subfield 'c'."); return \@warningstoreturn;
        }

        #look for date in 260 _c (starting at the end of the field)
        ##only want first date in last subfield _c

        my @subfields = $field260->subfields();
        my @newsubfields = ();
        my $wantedsubc;
        #break subfields into code-data array
        #stop when first subfield _c is reached (should be the last subfield _c of the field)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            if ($code eq 'c' ) {$wantedsubc = $data; last;}
            #should not be necessary to rebuild 260
            #unshift (@newsubfields, $code, $data);
        } # while


        #extract 4 digit date portion
        # account for [i.e. [date]]
        unless ($wantedsubc =~ /\[i\..?e\..*(\d{4}).*?\]/) {
            $wantedsubc =~ s/^.*?\b\D*(\d{4})\D*\b.*$/$1/;
        }
        else {$wantedsubc =~ s/.*?\[i\..?e\..*(\d{4}).*?\].*/$1/;
        }

        if ($wantedsubc =~ /^\d{4}$/) {$date260 = $wantedsubc;}
        # i.e. date should be 2nd string of 4 digits
        elsif ($wantedsubc =~ /^\d{8}$/) {$date260 = substr($wantedsubc,4,4);}
        else {push @warningstoreturn, ("260: Unable to find 4 digit year in subfield 'c'."); return \@warningstoreturn;
        }
    } #elsif RDA has 260
    else {
        #get 264 field if it exists and has a subfield 'c'
        my @fields264 = $record->field('264') if ($record->field('264'));
        my $field264_with_c = '';
        for my $field264 (@fields264) {
            my $ind2 = $field264->indicator('2');
            if ($ind2 =~ /1/) {
                if ($record->field('264')->subfield('c')) {
                    $field264_with_c = $field264;
                } #if 264$c
            } #if indicator 2 is 1  
            last if $field264_with_c;
        } #for 264 fields
        unless ($field264_with_c) {push @warningstoreturn, ("264: Could not get 264 or 264 subfield 'c'."); return \@warningstoreturn;}

        #look for date in 264 _c (starting at the end of the field)
        ##only want first date in last subfield _c

        my @subfields = $field264_with_c->subfields();
        my @newsubfields = ();
        my $wantedsubc;
        #break subfields into code-data array
        #stop when first subfield _c is reached (should be the last subfield _c of the field)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            if ($code eq 'c' ) {$wantedsubc = $data; last;}
            #should not be necessary to rebuild 264
            #unshift (@newsubfields, $code, $data);
        } # while


        #extract 4 digit date portion
        # account for [i.e. [date]]
        unless ($wantedsubc =~ /\[i\..?e\..*(\d{4}).*?\]/) {
            $wantedsubc =~ s/^.*?\b\D*(\d{4})\D*\b.*$/$1/;
        }
        else {$wantedsubc =~ s/.*?\[i\..?e\..*(\d{4}).*?\].*/$1/;
        }

        if ($wantedsubc =~ /^\d{4}$/) {$date260 = $wantedsubc;}
        # i.e. date should be 2nd string of 4 digits
        elsif ($wantedsubc =~ /^\d{8}$/) {$date260 = substr($wantedsubc,4,4);}
        else {push @warningstoreturn, ("264: Unable to find 4 digit year in subfield 'c'."); return \@warningstoreturn;
        }
    
    } #else RDA

    #####################################
#####################################
### to skip non-book records: ###
#if ($mattype ne 'a') {return \@warningstoreturn;}
#####################################
#####################################


##############################################
### Check for conference publication here ####
##############################################
    my $isconfpub = 0;

    if (($record->field(111)) || ($record->field(110) && $record->field(110)->subfield('d'))) {$isconfpub = 1;}

    #match 008 $date1, $date050, and $date260 unless record is for conference.
    unless ($isconfpub == 1) {
        unless ($date1 eq $date050 && $date050 eq $date260) {
            push @warningstoreturn, ("Pub. Dates: 008 date1, $date1, 050 date, $date050, and 260_c date, $date260 do not match."); return \@warningstoreturn;

        } #unless all three match
    } #unless conf
    # otherwise for conf. publications match only $date1 and $date260
    else {
        unless ($date1 eq $date260) {
            push @warningstoreturn, ("Pub. Dates: 008 date1, $date1 and 260_c date, $date260 do not match."); return \@warningstoreturn;
        } #unless conf with $date1 eq $date260
    } #else conf

    return \@warningstoreturn;

} # matchpubdates


#########################################
#########################################
#########################################
#########################################

=head2 check_bk008_vs_bibrefandindex($record)

 Ignores non-book records (other than cartographic materials).
 For cartographic materials, checks only for index coding (not bib. refs.).

 Examines 008 book-contents (bytes 24-27) and book-index (byte 31).
 Compares with 500 and 504 fields.
 Reports error if 008contents has 'b' but 504 does not have "bibliographical references."
 Reports error if 504 has "bibliographical references" but no 'b' in 008contents.
 Reports error if 008index has 1 but no 500 or 504 with "Includes .* index."
 Reports error if a 500 or 504 has "Includes .* index" but 008index is 0. 
 Reports error if "bibliographical references" appears in 500.
 Allows "bibliographical reference."

=head2 TO DO/KNOWN PROBLEMS

 As with other subroutines, this one treats all 008 as being coded for monographs.
 Serials are ignored for the moment.

 Account for records with "Bibliography" or other wording in place of "bibliographical references."
 Currently 'b' in 008 must match with "bibliographical reference" or "bibliographical references" in 504 (or 500--though that reports an error).

 Reverse check for other wording (or subject headings) vs. 008 'b' in contents.

 Check for other 008contents codes.

 Check for misspelled "bibliographical references."

 Check spacing if pagination is given in 504.

=cut

sub check_bk008_vs_bibrefandindex {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();
    my $record_is_RDA = is_RDA($record);


    my $leader = $record->leader();
    my $mattype = substr($leader, 6, 1); 
    #skip non-book (other than cartographic) records
    if ($mattype !~ /^[ae]$/) {return \@warningstoreturn;}

    my $field008 = $record->field('008')->as_string() if ($record->field('008'));
    return \@warningstoreturn unless ($field008);

    my $bkindex = substr($field008,31,1);
    #report error if $bkindex is not 0 or 1
    ##this will result in dual errors if check_008 is also called.
    push @warningstoreturn, ("008: Book index must be 0 or 1.") unless $bkindex =~ /[01]/;
    
    my $bkcontents = substr($field008,24,4);

#############################
    my @fields500 = ();
    my @fields504 = ();
    my @fields6xx = ();
    foreach my $field500 ($record->field('500')){
        push @fields500, ($field500->as_string());
    }
    foreach my $field504 ($record->field('504')){
        push @fields504, ($field504->as_string());
    }

####################################
### Workaround for bibliography as form of item.
    foreach my $field6xx ($record->field('6..')){
        push @fields6xx, ($field6xx->as_string());
    }
####################################

####################################

########################
## Check index coding ##
########################
    my $hasindexin500or504 = 0;
    #count 500s and 504s with 'Includes' 'index'
    $hasindexin500or504 = grep {$_ =~ /Includes.*index/} @fields500, @fields504;

    if (grep {$_ =~ /^Includes index(es)?\.$/}  @fields504) {
        push @warningstoreturn, ("504: 'Includes index.' or 'Includes indexes.' should be 500.")
    } # if 'Includes index(es).' in 504

    #error if $bkindex is 0 but 500 or 504 "Includes" "index"
    if (($bkindex eq '0') && ($hasindexin500or504)) {
        push @warningstoreturn, ("008: Index is coded 0 but 500 or 504 mentions index.");
    } #if $bkindex is 0 but 500 or 504 "Includes" "index"

    #error if $bkindex is 1 but 500 or 504 does not have "Includes" "index"
    elsif (($bkindex eq '1') && !($hasindexin500or504)) {
        push @warningstoreturn, ("008: Index is coded 1 but 500 or 504 does not mention index.");
    } #elsif $bkindex is 1 but 500 or 504 does not have "Includes" "index"

###############################

    #return if the $mattype is 'e' (cartographic)
    if ($mattype eq 'e') {return \@warningstoreturn;}

###############################


##########################
## Check bib ref coding ##
##########################

    my $hasbibrefs = 0;
    #set $hasbibrefs to 1 if 'b' appears in 008 byte 24-27
    $hasbibrefs = 1 if ($bkcontents =~ /b/);

    #get 504s with 'bibliographical references' #modified 11-4-04 to add 's?\.?\b'
    my @bibrefsin504 = grep {$_ =~ /(?:bibliographical references?\.?\b)|(?:webliography)/} @fields504;
    #get 500s with 'bibliographical references'
    my @bibrefsin500 = grep {$_ =~ /(?:bibliographical references?\.?\b)|(?:webliography)/} @fields500;
###### Temporary/uncertain method of checking for bibliography as form of item
    my @bib6xx = grep {$_ =~ /bibliography|bibliographies/i} @fields6xx;

    my $bibrefin504 = join '', @bibrefsin504;
    my $bibrefin500 = join '', @bibrefsin500;
    my $isbibliography = join '', @bib6xx;

    #report 500 with "bibliographical references"
    if ($bibrefin500) {
        push @warningstoreturn, ("500: Bibliographical references should be in 504.");
    } #if $bibrefin500

    #report 008contents 'b' but not 504 or 500 with bib refs 
    if (($hasbibrefs == 1) && !(($bibrefin504) || ($bibrefin500) ||($isbibliography))) {
push @warningstoreturn, ("008: Coded 'b' but 504 (or 500) does not mention 'bibliographical references', and 'bibliography' is not present in 6xx.");
} # if 008cont 'b' but not 504 or 500 with bib refs
#report 504 or 500 with bib refs but no 'b' in 008contents
    elsif (($hasbibrefs == 0) && (($bibrefin504) || $bibrefin500)) {
        push @warningstoreturn, ("008: Not coded 'b' but 504 (or 500) mentions 'bibliographical references'.");
    } # if 008cont 'b' but not 504 or 500 with bib refs

    foreach my $bibref (@bibrefsin504) {
        #check spacing around parentheses
        if ($bibref =~ /[\(\)]/) {
            push @warningstoreturn, ("504: Check spacing around parentheses ($bibref).") if (($bibref =~ /\(.+?\)[^ \,\.]/) || ($bibref =~ /[^ ]\(.+?\)/));
        } #if 504 has parentheses

        unless ($record_is_RDA) {
            #check for 'p.' if pagination is present with bibliographical references
            if ($bibref =~ /bibliographical references \((?!p\. ).*?\)?/) {
                unless ($bibref =~ /bibliographical references \(t\.p\. .*?\)?/) {
                    push @warningstoreturn, ("504: Pagination may need 'p.' ($bibref).");
                } #unless 't.p. ' is page (including t.p. verso)
            } #if 'p.' is not present in 504 with bib. ref. pagination
        } #unless RDA record
        else {
            #check for 'page(s)' if pagination is present with bibliographical references
            if ($bibref =~ /bibliographical references \((?!pages? ).*?\)?/) {
                unless ($bibref =~ /bibliographical references \(title page .*?\)?/) {
                    push @warningstoreturn, ("504: Pagination may need 'page(s)' ($bibref).");
                } #unless 'title page ' is page (including title page verso)
            } #if 'page(s)' is not present in 504 with bib. ref. pagination
        } #else RDA
    } #foreach 504 field with bib. refs
    return \@warningstoreturn;
 
} # check_bk008_vs_bibrefandindex

#########################################
#########################################
#########################################
#########################################

=head2 check_041vs008lang($record)

Compares first code in subfield 'a' of 041 vs. 008 bytes 35-37.

=cut

sub check_041vs008lang {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    my $field008 = $record->field('008')->as_string() if ($record->field('008'));
    return \@warningstoreturn unless ($field008);
    my $langcode008 = substr($field008,35,3);

    #double check that lang code is present with 3 characters
    unless ($langcode008 =~ /^[\w ]{3}$/) {
        push @warningstoreturn, ("008: Could not get language code, $langcode008.");
    }

    #get first 041 subfield 'a' if it exists
    my $first041a;
    if ($record->field('041')) {
        $first041a = $record->field('041')->subfield('a') if ($record->field('041')->subfield('a'));
    }

    #skip records without 041 or 041$a
    unless ($first041a) {return \@warningstoreturn;}
    else {
        my $firstcode = substr($first041a,0,3);
        #compare 008lang vs. 1st 041a code
        unless ($firstcode eq $langcode008) {
            push @warningstoreturn, ("041: First code ($firstcode) does not match 008 bytes 35-37 (Language $langcode008).");
        }
    } # else $first041a exists

    return \@warningstoreturn;

} #check_041vs008lang

#########################################
#########################################
#########################################
#########################################

#########################################
#########################################
#########################################
#########################################

=head2 check_5xxendingpunctuation($record)

Validates punctuation in various 5xx fields.

Currently checks 500, 501, 504, 505, 508, 511, 538, 546.

For 586, see check_nonpunctendingfields($record)

=head2 TO DO (check_5xxendingpunctuation)

Add checks for the other 5xx fields. 

Verify rules for these checks (particularly 505).

=cut

sub check_5xxendingpunctuation {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    my $leader = $record->leader();
    my $encodelvl = substr($leader, 17, 1);

    #check for CIP-level
    my $isCIP = 0;
    if ($encodelvl eq '8') {
        $isCIP = 1;
    }
    # check only certain fields
    my @fieldstocheck = ('500', '501', '504', '505', '520', '538', '546', '508', '511');

    #get fields in @fieldstocheck
    my @fields5xx = $record->field(@fieldstocheck);


    #loop through set of 5xx fields to check in $record
    foreach my $field5xx (@fields5xx) {
        my $tag = $field5xx->tag();
        #skip 500s with LCCN or ISBN in PCIP
        if (($isCIP) && ($tag eq '500') && ($field5xx->subfield('a') =~ /^(LCCN)|(ISBN)|(Preassigned)/)) {
            return \@warningstoreturn;
        } #if CIP with 'LCCN' or 'ISBN' note

        else {
            #look at last subfield (unless numeric)
            my @subfields = $field5xx->subfields();
            my @newsubfields = ();

            #break subfields into code-data array (so the entire field is in one array)
            while (my $subfield = pop(@subfields)) {
                my ($code, $data) = @$subfield;
                # skip numeric subfields (5)
                next if ($code =~ /^\d$/);

                #get the first 10 and last 10 characters of the field for error reporting
                my ($firstchars, $lastchars) = ('', '');
                if (length($data) < 10) {
                    #get full subfield if length < 10)
                    $firstchars = $data;
                    #get full subfield if length < 10)
                    $lastchars = $data;
                } #if subfield length < 10
                elsif (length($data) >= 10) {
                    #get first 10 chars of subfield
                    $firstchars = substr($data,0,10);
                    #get last 10 chars of subfield
                    $lastchars = substr($data,(length($data)-10),(length($data)));
                } #elsif subfield length >= 10

# valid punctuation: /(\)?[\!\?\.]\'?\"?$)/
# so, closing parens (or not), 
# either exclamation point, question mark or period,
# and, optionally, single and/or double quote

                unless ($data =~ /(\)?[\!\?\.]\'?\"?$)/) {
                    if ($tag eq '505') {
                        #ignore error--505 may be unpunctuated
                    } #if 505
                    else {
                        push @warningstoreturn, join '', ($tag, ": Check ending punctuation, ",  $firstchars, " ___ ", $lastchars);
                    } #else not 505
                } #unless valid ending punctuation

                #report error for floating or non-floating semi-colon-period
                push @warningstoreturn, join '', ($tag, ": Check ending punctuation, ",  $firstchars, " ___ ", $lastchars) if ($data =~ /\s*;\s*\.$/);

                #report error for exclamation point or question mark-period
                push @warningstoreturn, join '', ($tag, ": Check ending punctuation (exclamation point or question mark should not be followed by period), ",  $firstchars, " ___ ", $lastchars) if ($data =~ /(\)?[\!\?]\.\'?\"?$)/);
                
                # stop after first non-numeric
                last;
            } # while subfields
        } # else tag is checkable
        
    } # foreach 5xx field

    return \@warningstoreturn;

} # check_5xxendingpunctuation


#########################################
#########################################
#########################################
#########################################

=head2 findfloatinghyphens($record)

Looks at various fields and reports fields with space-hypen-space as errors.

=head2 TO DO (findfloatinghyphens($record))

Find exceptions.

=cut

sub findfloatinghyphens {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    # add or remove fields to be examined
    my @fieldstocheck = ('245', '246', '500', '501', '505', '508', '511', '538', '546'); #some may also want to check '520'

    #look at each of the fields
    foreach my $fieldtocheck (@fieldstocheck) {
        my @fields = $record->field($fieldtocheck);
        foreach my $checkedfield (@fields) {
            #get field as a string, without subfield coding
            my $fielddata = $checkedfield->as_string();
            #report error if space-hyphen-space appears in field
            ##reporting surrounding 10 chars on either side
            if (my @floating_hyphens = ($fielddata =~ /(.{0,10} \- .{0,10})/g)) {
                push @warningstoreturn, join '', ($checkedfield->tag(), ": May have a floating hyphen, ", (join '_', @floating_hyphens) ); 
            } #if floating hyphen
        } #foreach $checkedfield
    } #foreach $fieldtocheck

    return \@warningstoreturn;

} # findfloatinghyphens

#########################################
#########################################
#########################################
#########################################

=head2 check_floating_punctuation($record)

 Looks at each non-control tag and reports an error if a floating period, comma, or question mark are found.

Example: 

    245 _aThis has a floating period .

Ignores double dash-space when preceded by a non-space (example-- [where functioning as ellipsis replacement])

=head2 TODO (check_floating_punctuation($record))

 -Add other undesirable floating punctuation.

 -Look for exceptions where floating punctuation should be allowed.

 -Merge functionality with findfloatinghyphens($record) (to reduce number of runs through the same record, especially).

 -Improve reporting. Current version reports approximately 10 characters before and after the floating text for fields longer than 80 characters, or the full field otherwise, to provide context, particularly in the case of multiple instances.
 
=cut

sub check_floating_punctuation {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #create hash of punctuation wording
    my %punct_words = (
        ',' => 'comma',
        '.' => 'period',
        '?' => 'question mark',
    );

    #look at each field in record
    foreach my $field ($record->fields()) {
        my $tag = $field->tag();
        #skip non-numeric tags
        next unless ($tag =~ /^[0-9][0-9][0-9]$/);
        #skip control fields and LCCN (010)
        next if ($tag <= 10);

        #break field into string of characters without subfield codes
        my $field_string = $field->as_string();

        #if period, comma, question mark are preceded by space and followed
        #by space or end of field, report error
        #except when preceded by ellipsis-replacement dash
        if ($field_string =~ /(?:(?![^ ]--)...) ([\.\,\?])(?: |$)/) {
            my $punct = $1;
            my $punctuation = ($punct_words{$punct} or 'punctuation mark');
            my @surrounding_text = ($field_string =~ /(.{0,10}(?![^ ]--)... [\.\,\?] ?.{0,10})/g);
            $punctuation = "punctuation marks" if (scalar @surrounding_text > 1);
            my $warning_text = join '', ($tag, ": May have floating $punctuation ");
            #add surrounding characters if field is longer than 80 chars
            $warning_text .= "\(".(length($field_string) > 80 ? join "_", substr($field_string, 0, 15), @surrounding_text : $field_string)."\).";

            push @warningstoreturn, $warning_text;
        } #if floating punctuation
        
    } #foreach field in record
    
    return \@warningstoreturn;

} #check_floating_punctuation



#########################################
#########################################
#########################################
#########################################


=head2 video007vs300vs538($record)

Comparison of 007 coding vs. 300abc subfield data and vs. 538 data for video records (VHS and DVD).

=head2 DESCRIPTION

Focuses on videocassettes (VHS) and videodiscs (DVD and Video CD).
Does not consider coding for motion pictures.

If LDR/06 is 'g' for projected medium,
(skipping those that aren't)
and 007 is present,
at least 1 007 should start with 'v'

If 007/01 is 'd', 300a should have 'videodisc(s)'.
300c should have 4 3/4 in.
Also, 538 should have 'DVD' 
If 007/01 is 'f', 300a should have 'videocassette(s)'
300c should have 1/2 in.
Also, 538 should have 'VHS format' or 'VHS hi-fi format' (case insensitive on hi-fi), plus a playback mode.

=head2 LIMITATIONS

Checks only videocassettes (1/2) and videodiscs (4 3/4).
Current version reports problems with other forms of videorecordings.

Accounts for existence of only 1 300 field.

Looks at only 1st subfield 'a' and 'c' of 1st 300 field.

=head2 TO DO

Account for motion pictures and videorecordings not on DVD (4 3/4 in.) or VHS cassettes.

Check proper plurality of 300a (1 videodiscs -> error; 5 videocassette -> error)

Monitor need for changes to sizes, particularly 4 3/4 in. DVDs.

Expand allowed terms for 538 as needed and revise current VHS allowed terms.

Update to allow SMDs of conventional terminology ('DVD') if such a rule passes.

Deal with multiple 300 fields.

Check GMD in 245$h

Clean up redundant code.

=cut

sub video007vs300vs538 {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();
    my $record_is_RDA = is_RDA($record);


    my $leader = $record->leader();
    my $mattype = substr($leader, 6, 1); 
    #my $encodelvl = substr($leader, 17, 1);

    #skip non-videos
    return \@warningstoreturn unless $mattype eq 'g';


    my @fields007 = ();

    if ($record->field('007')) {
        foreach my $field007 ($record->field('007'))
        {
            my $field007string = $field007->as_string(); 
            #skip non 'v' 007s
            next unless ($field007string =~ /^v/);
            #add 'v' 007s to @fields007 for further processing
            push @fields007, $field007string;
        } # foreach subfield 007
    } # if 007s exist
    else {
        #warn about nonexistent 007 in 'g' type records
        push @warningstoreturn, ("007: Record is coded $mattype but 007 does not exist.");
    } # else no 007s

    #report existence of multiple 'v' 007s
    if ($#fields007 > 0){
        push @warningstoreturn, ("007: Multiple 007 with first byte 'v' are present.");
    }
    #report nonexistence of 'v' 007 in 'g' type recor
    elsif ($#fields007 == -1) {
        push @warningstoreturn, ("007: Record is coded $mattype but no 007 has 'v' as its first byte.");
    }
    #else have exactly one 007 'v'
    else {
        # get bytes from the 007 for use in cross checks
        my @field007bytes = split '', $fields007[0];
        #report problem getting 'v' as first byte
        print "Problem getting first byte $fields007[0]" unless ($field007bytes[0] eq 'v');

        #declare variables for later
        my ($iscassette007, $isdisc007, $subfield300a, $subfield300b, $subfield300c, $viddiscin300, $vidcassettein300, $bw_only, $col_only, $col_and_bw, $dim300, $dvd538, $vhs538);

        #check for byte 1 having 'd'--videodisc (DVD or VideoCD) and normal pattern
        if ($field007bytes[1] eq 'd') {
            $isdisc007 = 1;
            unless ( #normal 'vd _[vsz]aiz_'
            $field007bytes[4] =~ /^[vsz]$/ && #DVD, Blu-ray or other
            $field007bytes[5] eq 'a' &&
            $field007bytes[6] eq 'i' &&
            $field007bytes[7] eq 'z'
            ) {
                push @warningstoreturn, ("007: Coded 'vd' for videodisc but bytes do not match normal pattern.");
            } # unless normal pattern
        } # if 'vd'

        #elsif check for byte 1 having 'f' videocassette
        elsif ($field007bytes[1] eq 'f') {
            $iscassette007 = 1;
            unless ( #normal 'vf _baho_'
            $field007bytes[4] eq 'b' &&
            $field007bytes[5] eq 'a' &&
            $field007bytes[6] eq 'h' &&
            $field007bytes[7] eq 'o'
            ) {
                push @warningstoreturn, ("007: Coded 'vf' for videocassette but bytes do not match normal pattern.");}
        } # elsif 'vf'

        #get 300 and 538 fields for cross-checks
        my $field300 = $record->field('300') if ($record->field('300'));

        #report nonexistent 300 field
        unless ($field300){
                push @warningstoreturn, ("300: May be missing.");        
        } #unless 300 field exists

        #get subfields 'a' 'b' and 'c' if they all exist
        elsif ($field300->subfield('a') && $field300->subfield('b') && $field300->subfield('c')) {
            $subfield300a = $field300->subfield('a');
            $subfield300b = $field300->subfield('b');
            $subfield300c = $field300->subfield('c');
        } #elsif 300a 300b and 300c exist

        #report missing subfield 'a' 'b' or 'c'
        else {
            push @warningstoreturn, ("300: Subfield 'a' is missing.") unless ($field300->subfield('a'));
            push @warningstoreturn, ("300: Subfield 'b' is missing.") unless ($field300->subfield('b'));
            push @warningstoreturn, ("300: Subfield 'c' is missing.") unless ($field300->subfield('c'));
        } # 300a or 300b or 300c is missing

######## get elements of each subfield ##########
        ######### get SMD ###########
        if ($subfield300a) {
            if ($subfield300a =~ /videodisc/) {
                $viddiscin300 = 1;
            } #300a has videodisc
            elsif ($subfield300a =~ /videocassette/) {
                $vidcassettein300 = 1;
            } #300a has videocassette
            else {
                push @warningstoreturn, ("300: Not videodisc or videocassette, $subfield300a.");
            } #not videodisc or videocassette in 300a
        } #if subfielda exists
        ###############################

        ###### get color info #######
        if ($subfield300b) {
            unless ($record_is_RDA) {
                #both b&w and color
                if (($subfield300b =~ /b.?\&.?w/) && ($subfield300b =~ /col\./)) {
                    $col_and_bw = 1;
                } #if col. and b&w 
                #both but col. missing period
                elsif (($subfield300b =~ /b.?\&.?w/) && ($subfield300b =~ /col[^.]/)) {
                    $col_and_bw = 1;
                    push @warningstoreturn, ("300: Col. may need a period, $subfield300b.");
                } #elsif b&w and col (without period after col.)
                elsif (($subfield300b =~ /b.?\&.?w/) && ($subfield300b !~ /col\./)) {
                    $bw_only = 1;
                } #if b&w only
                elsif (($subfield300b =~ /col\./) && ($subfield300b !~ /b.?\&.?w/)) {
                    $col_only = 1;
                } #if col. only
                elsif (($subfield300b =~ /col[^.]/) && ($subfield300b !~ /b.?\&.?w/)) {
                    $col_only = 1;
                    push @warningstoreturn, ("300: Col. may need a period, $subfield300b.");
                } #if col. only (without period after col.)
                else {
                    push @warningstoreturn, ("300: Col. or b&w are not indicated, $subfield300b.");
                } #not indicated
            } #unless RDA
            else {
                #both b&w and color
                if (($subfield300b =~ /black \& white/) && ($subfield300b =~ /colou?r/)) {
                    $col_and_bw = 1;
                } #if col. and b&w 
                #both but col. and b&w abbreviated
                elsif (($subfield300b =~ /b.?\&.?w/) && ($subfield300b =~ /col\./)) {
                    $col_and_bw = 1;
                    push @warningstoreturn, ("300: Check for abbreviated col. and b&w, $subfield300b.");
                } #elsif b&w and col. abbreviated
                elsif (($subfield300b =~ /black \& white/) && ($subfield300b !~ /colou?r/)) {
                    $bw_only = 1;
                } #if b&w only
                elsif (($subfield300b =~ /b.?\&.?w/) && ($subfield300b !~ /col/)) {
                    $bw_only = 1;
                    push @warningstoreturn, ("300: Check for abbreviated b&w, $subfield300b.");
                } #if b&w only
                elsif (($subfield300b =~ /colou?r/) && ($subfield300b !~ /black \& white/)) {
                    $col_only = 1;
                } #if colored only
                elsif (($subfield300b =~ /col\./) && ($subfield300b !~ /(b.?\&.?w)|(black \& white)/)) {
                    $col_only = 1;
                    push @warningstoreturn, ("300: Check for abbreviated col., $subfield300b.");
                } #if col. only
                else {
                    push @warningstoreturn, ("300: Colored or black & white are not indicated, $subfield300b.");
                } #not indicated
            } #else RDA
        } #if subfieldb exists
        ###########################

        #### get dimensions ####
        if ($subfield300c) {
            if ($subfield300c =~ /4 3\/4 in\./) {
                $dim300 = '4.75';
            } #4 3/4 in.
            elsif ($subfield300c =~ /1\/2 in\./) {
                $dim300 = '.5';
            } #1/2 in.
        #### add other dimensions here ####
        ###########################
        ### elsif ($subfield300c =~ //) {}
        ###########################
        ###########################
            else {
                push @warningstoreturn, ("300: Dimensions are not 4 3/4 in. or 1/2 in., $subfield300c.");
            } # not normal dimension
        } #if subfieldc exists
        ###########################

####################################
##### Compare SMD vs. dimensions ###
####################################
#$viddiscin300, $vidcassettein300
#$dim300
        #if notdvd_or_vhs_in538  is 1, then no 538 has the proper terminology for the format
        my $notdvd_or_vhs_in538 = 1; #declared and initialized here for later use

        ##### modify unless statement if dimensions change

        if ($viddiscin300) {
            push @warningstoreturn, ("300: Dimensions, $subfield300c, do not match SMD, $subfield300a.") unless ($dim300 eq '4.75');
        }
        elsif ($vidcassettein300) {
            push @warningstoreturn, ("300: Dimensions, $subfield300c, do not match SMD, $subfield300a.") unless ($dim300 eq '.5');
        }
####################################

###########################
####### Get 538s ##########
###########################

        
        my @fields538 = map {$_->as_string()} $record->field('538') if ($record->field('538'));
        #report nonexistent 538 field
        unless (@fields538){
                push @warningstoreturn, ("538: May be missing in video record.");
        } #unless 538 field exists
        else {
            foreach my $field538 (@fields538) {
                if ($field538 =~ /(DVD)|(Video CD)|(Blu-ray)/) {
                    $dvd538 = 1;
                } #if dvd in 538
                #################################
                ###### VHS wording in 538 is subject to change, so make note of changes
                #################################
                #538 should have VHS format and a playback mode (for our catalogers' current records)
                elsif ($field538 =~ /VHS ([hH]i-[fF]i)?( mono\.)? ?format, [ES]?L?P playback mode/) {
                    $vhs538 = 1;
                } #elsif vhs in 538
                ###
                ### Add other formats here ###
                ###
                else {
                    #current 538 doesn't have DVD or VHS
                    $notdvd_or_vhs_in538 = 1;
                } #else 
            } #foreach 538 field
        } # #else 538 exists

        ## add other formats as first condition if necessary
        if (($vhs538||$dvd538) && ($notdvd_or_vhs_in538 == 1)) {
        $notdvd_or_vhs_in538 = 0;
        } #at least one 538 had VHS or DVD

        # if $notdvd_or_vhs_in538 is 1, then no 538 had VHS or DVD
        elsif ($notdvd_or_vhs_in538 == 1) {
            push @warningstoreturn, ("538: Does not indicate VHS or DVD.");
        } #elsif 538 does not have VHS or DVD

###################################
##### Cross field comparisons #####
###################################

        #compare SMD in 300 vs. 007 and 538
        ##for cassettes
        if ($iscassette007) {
            push @warningstoreturn, ("300: 007 coded for cassette but videocassette is not present in 300a.") unless ($vidcassettein300);
            push @warningstoreturn, ("538: 007 coded for cassette but 538 does not have 'VHS format, SP playback mode'.") unless ($vhs538);
        } #if coded cassette in 007
        ##for discs
        elsif ($isdisc007) {
            push @warningstoreturn, ("300: 007 coded for disc but videodisc is not present in 300a.") unless ($viddiscin300);
            push @warningstoreturn, ("538: 007 coded for disc but 538 does not have 'DVD'.") unless ($dvd538);
        } #elsif coded disc in 007

###$bw_only, $col_only, $col_and_bw

        #compare 007/03 vs. 300$b for color/b&w
        if ($field007bytes[3] eq 'b') {
            push @warningstoreturn, ("300: Color in 007 coded 'b' but 300b mentions color, $subfield300b") unless ($bw_only);
        } #b&w
        elsif ($field007bytes[3] eq 'c') {
            push @warningstoreturn, ("300: Color in 007 coded 'c' but 300b mentions black & white, $subfield300b") unless ($col_only);
        } #col.
        elsif ($field007bytes[3] eq 'm') {
            push @warningstoreturn, ("300: Color in 007 coded 'm' but 300b mentions only color or black & white, $subfield300b") unless ($col_and_bw);
        } #mixed
        elsif ($field007bytes[3] eq 'a') {
            #not really an error, but likely rare, especially for our current videos
            push @warningstoreturn, ("300: Color in 007 coded 'a', one color.");
        } #one col.

    } # else have exactly 1 'v' 007

    return \@warningstoreturn;


} # video007vs300vs538


#########################################
#########################################
#########################################
#########################################

=head2 ldrvalidate($record)

Validates bytes 5, 6, 7, 17, and 18 of the leader against MARC code list valid characters.

=head2 DESCRIPTION

Checks bytes 5, 6, 7, 17, and 18.

$ldrbytes{$key} has keys "\d\d", "\d\dvalid" for each of the bytes checked (05, 06, 07, 17, 18)

"\d\dvalid" is a hash ref containing valid code linked to the meaning of that code.

print $ldrbytes{'05valid'}->{'a'}, "\n";
yields: 'Increase in encoding level'

=head2 TO DO (ldrvalidate)

Customize (comment or uncomment) bytes according to local needs. Perhaps allow %ldrbytes to be passed into ldrvalidate($record) so that that hash may be created by a calling program, rather than relying on the preset MARC 21 values. This would facilitate adding valid OCLC-MARC bytes such as byte 17--I, K, M, etc.

Examine other Lintadditions/Errorchecks subroutines using the leader to see if duplicate checks are being done.

Move or remove such duplicate checks.

Consider whether %ldrbytes needs full text of meaning of each byte.

=cut

##########################################
### Initialize valid ldr bytes in hash ###
##########################################

#source: MARC field list (http://www.loc.gov/marc/bibliographic/ecbdlist.htm)

#Change (comment or uncomment) according to local needs

my %ldrbytes = (
    '05' => 'Record status',
    '05valid' => {
        'a' => 'Increase in encoding level',
        'c' => 'Corrected or revised',
        'd' => 'Deleted',
        'n' => 'New',
        'p' => 'Increase in encoding level from prepublication'
    },
    '06' => 'Type of record',
    '06valid' => {
        'a' => 'Language material',
#        'b' => 'Archival and manuscripts control [OBSOLETE]',
        'c' => 'Notated music',
        'd' => 'Manuscript notated music',
        'e' => 'Cartographic material',
        'f' => 'Manuscript cartographic material',
        'g' => 'Projected medium',
#        'h' => 'Microform publications [OBSOLETE]',
        'i' => 'Nonmusical sound recording',
        'j' => 'Musical sound recording',
        'k' => 'Two-dimensional nonprojectable graphic',
        'm' => 'Computer file',
#        'n' => 'Special instructional material [OBSOLETE]',
        'o' => 'Kit',
        'p' => 'Mixed material',
        'r' => 'Three-dimensional artifact or naturally occurring object',
        't' => 'Manuscript language material'
    },
    '07' => 'Bibliographic level',
    '07valid' => {
        'a' => 'Monographic component part',
        'b' => 'Serial component part',
        'c' => 'Collection',
        'd' => 'Subunit',
        'i' => 'Integrating resource',
        'm' => 'Monograph/item',
        's' => 'Serial'
    },
    '17' => 'Encoding level',
    '17valid' => {
        ' ' => 'Full level',
        '1' => 'Full level, material not examined',
        '2' => 'Less-than-full level, material not examined',
        '3' => 'Abbreviated level',
        '4' => 'Core level',
        '5' => 'Partial (preliminary) level',
        '7' => 'Minimal level',
        '8' => 'Prepublication level',
        'u' => 'Unknown',
        'z' => 'Not applicable'
    },
    '18' => 'Descriptive cataloging form',
    '18valid' => {
        ' ' => 'Non-ISBD',
        'a' => 'AACR 2',
        'c' => 'ISBD punctuation omitted',
        'i' => 'ISBD punctuation included',
#        'p' => 'Partial ISBD (BK) [OBSOLETE]',
#        'r' => 'Provisional (VM MP MU) [OBSOLETE]',
        'u' => 'Unknown'
    },
    '19' => 'Multipart resource record level',
    '19valid' => {
        ' ' => 'Not specified or not applicable',
        'a' => 'Set',
        'b' => 'Part with independent title',
        'c' => 'Part with dependent title'
    }
); # %ldrbytes
################################

sub ldrvalidate {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();
    my $record_is_RDA = is_RDA($record);

    my $leader = $record->leader();
    my $status = substr($leader, 5, 1);
    my $mattype = substr($leader, 6, 1); 
    my $biblvl = substr($leader, 7, 1);
    my $encodelvl = substr($leader, 17, 1);
    my $catrules = substr($leader, 18, 1);

    #check LDR/05
    unless ($ldrbytes{'05valid'}->{$status}) {
        push @warningstoreturn, "LDR: Byte 05, Status $status is invalid.";
    }
    #check LDR/06
    unless ($ldrbytes{'06valid'}->{$mattype}) {
        push @warningstoreturn, "LDR: Byte 06, Material type $mattype is invalid.";
    }
    #check LDR/07
    unless ($ldrbytes{'07valid'}->{$biblvl}) {
        push @warningstoreturn, "LDR: Byte 07, Bib. Level, $biblvl is invalid.";
    }
    #check LDR/17
    unless ($ldrbytes{'17valid'}->{$encodelvl}) {
        push @warningstoreturn, "LDR: Byte 17, Encoding Level, $encodelvl is invalid.";
    }
    #check LDR/18
    unless ($ldrbytes{'18valid'}->{$catrules}) {
        push @warningstoreturn, "LDR: Byte 18, Cataloging rules, $catrules is invalid.";
    }
    #report RDA records coded 'a', AACR2
    if ($record_is_RDA) {
        push @warningstoreturn, "LDR: Byte 18, Cataloging rules, coded $catrules (AACR2), but 040 indicates RDA." if ($catrules eq 'a');
    }# RDA record leader coded as AACR2
    
    
    return \@warningstoreturn;

} # ldrvalidate 

#########################################
#########################################
#########################################
#########################################

=head2 geogsubjvs043($record)

Reports absence of 043 if 651 or 6xx subfield z is present.

=head2 TO DO (geogsubjvs043)

Update/maintain list of exceptions (in the hash, %geog043exceptions).

=cut

my %geog043exceptions = (
    'English-speaking countries' => 1,
    'Foreign countries' => 1,
);

sub geogsubjvs043 {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();
    
    #skip records with no subject headings
    unless ($record->field('6..')) {return \@warningstoreturn;}
    else {
        my $hasgeog = 0;
        #get 043 field
        my $field043 = $record->field('043') if ($record->field('043'));
        #get all 6xx fields
        my @fields6xx = $record->field('6..');
        #look at each 6xx field
        foreach my $field6xx (@fields6xx) {
            #if field is 651, it is geog
            ##may need to check these for exceptions
            if ($field6xx->tag() eq '651') {
                $hasgeog = 1
            } #if 6xx is 651
            #if field has subfield z, check for exceptions and report others
            elsif ($field6xx->subfield('z')) {
                my @subfields_z = ();
                #get all subfield 'z' in field
                push @subfields_z, ($field6xx->subfield('z'));
                #look at each subfield 'z'
                foreach my $subfieldz (@subfields_z) {
                    #remove trailing punctuation and spaces
                    $subfieldz =~ s/[ .,]$//;
                    # unless text of z is an exception, it is geog.
                    unless ($geog043exceptions{$subfieldz}) {
                        $hasgeog = 1
                    } #unless z is an exception
                } #foreach subfield z
            }# elsif has subfield 'z' but not an exception
        } #foreach 6xx field
        if ($hasgeog) {
            push @warningstoreturn, ("043: Record has 651 or 6xx subfield 'z' but no 043.") unless $field043;
        } #if record has geographic heading
    } #else 6xx exists

    return \@warningstoreturn;

} # geogsubjvs043




#########################################
#########################################
#########################################
#########################################

=head2 findemptysubfields($record)

 Looks for empty subfields.
 Skips 037 in CIP-level records and tags < 010.

=cut

sub findemptysubfields {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    my $leader = $record->leader();
    my $encodelvl = substr($leader, 17, 1);

    my @fields = $record->fields();
    foreach my $field (@fields) {
        my $tag = $field->tag();
        #skip non-numeric tags
        next unless ($tag =~ /^[0-9][0-9][0-9]$/);
        #skip control tags
        next if ($tag < 10);
        #skip CIP-level 037 fields
        if (($encodelvl eq '8') && ($tag eq '037')) {
            next;
        } #if CIP and field 037

        #get all subfields
        my @subfields = $field->subfields() if $field->subfields();
        #break subfields into code and data
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            #check for empty subfield data
            if ($data eq '') {
                push @warningstoreturn, join '', ($tag, ": Subfield $code is empty.");
            } #if data completely empty
            #check for fields with only period(s) or space(s)
            else {
                #keep original subfield data for reporting
                my $orig_data = $data;
                #remove periods and spaces
                $data =~ s/[\. ]//g;
                #report empty subfield
                push @warningstoreturn, join '', ($tag, ": Subfield $code contains only space(s) or period(s) ($orig_data).") unless ($data);
            } #else $data not empty string
        } # while subfields
    } # foreach field

    return \@warningstoreturn;

} # findemptysubfields

#########################################
#########################################
#########################################
#########################################

=head2 check_040present($record)

Reports error if 040 is not present.
Can not use Lintadditions check_040 for this since that relies upon field existing before the check is executed.

=cut

sub check_040present {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    #report nonexistent 040 fields
    unless ($record->field('040')) {
            push @warningstoreturn, ("040: Record lacks 040 field.");
    }

    return \@warningstoreturn;

} # check_040present

#########################################
#########################################
#########################################
#########################################

=head2 check_nonpunctendingfields($record)

Checks for presence of punctuation in the fields listed below.
These fields are not supposed to end in punctuation unless the data ends in abbreviation, ___, or punctuation.

Ignores initialisms such as 'Q.E.D.' Certain abbrevations and initialisms are explicitly coded.

Fields checked: 240, 246, 440, 490, 586.

=head2 TO DO (check_nonpunctendingfields)

Add exceptions--abbreviations--or deal with them.
Currently all fields ending in period are reported.

=cut

#set exceptions for abbreviation check;
#these may be useful for 6xx check of punctuation as well
my %abbexceptions = (
    'U.S.A.' => 1,
    'arr.' => 1,
    'etc.' => 1,
    'L. A.' => 1,
    'A.D.' => 1,
    'B.I.G.' => 1,
    'Co.' => 1,
    'D.C.' => 1,
    'E.R.' => 1,
    'I.Q.' => 1,
    'Inc.' => 1,
    'J.F.K.' => 1,
    'Jr.' => 1,
    'O.K.' => 1,
    'R.E.M.' => 1,
    'St.' => 1,
    'T.R.' => 1,
    'U.S.' => 1,
    'bk.' => 1,
    'cc.' => 1,
    'ed.' => 1,
    'ft.' => 1,
    'jr.' => 1,
    'mgmt.' => 1,
);

sub check_nonpunctendingfields {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    # check only certain fields
    my @fieldstocheck = ('240', '246', '440', '490', '586');

    
    my @fields = $record->field(@fieldstocheck);


    #loop through set of fields to check in $record
    foreach my $field (@fields) {
        my $tag = $field->tag();
        return \@warningstoreturn if $tag < 10;
        #look at last subfield (unless numeric?)
        my @subfields = $field->subfields();
        my @newsubfields = ();

        #break subfields into code-data array (so the entire field is in one array)
        while (my $subfield = pop(@subfields)) {
            my ($code, $data) = @$subfield;
            # skip numeric subfields (5) and other subfields (e.g. 240$o)
            next if (($code =~ /^\d$/) || ($tag eq '240' && $code =~ /o/));

# invalid punctuation: /[\.]\'?\"?$/
# so, periods should not usually be present, with some exceptions,
#and, optionally, single and/or double quote
#error prints first 10 and last 10 chars of subfield.
            my ($firstchars, $lastchars) = '';
            if (length($data) < 10) {
                #get full subfield if length < 10)
                $firstchars = $data;
                #get full subfield if length < 10)
                $lastchars = $data;
            } #if subfield length < 10
            elsif (length($data) >= 10) {
                #get first 10 chars of subfield
                $firstchars = substr($data,0,10);
                #get last 10 chars of subfield
                $lastchars = substr($data,-10,10);
            } #elsif subfield length >= 10

            if ($data =~ /[.]\'?\"?$/) {
                #get last words of subfield
                my @lastwords = split ' ', $data;
                #see if last word is a known exception
                unless ($abbexceptions{$lastwords[-1]} || ($lastwords[-1] =~ /(?:(?:\b|\W)[a-zA-Z]\.)$/)) {

                    push @warningstoreturn, join '', ($tag, ": Check ending punctuation (not normally added for this field), ", $firstchars, " ___ ", $lastchars);
                }
            }
            # stop after first non-numeric
            last;
        } # while
    } # foreach field


    return \@warningstoreturn;

} # check_nonpunctendingfields($record)

#########################################
#########################################
#########################################
#########################################

=head2 check_fieldlength($record)

Reports error if field is longer than 1870 bytes.
(1879 is actual limit, but I wanted to leave some extra room in case of miscalculation.)

This check relates to certain system limitations.

Also reports records with more than 50 fields.

=head2 TO DO (check_fieldlength($record))

Use directory information in raw MARC to get the field lengths.

=cut

sub check_fieldlength {

    #get passed MARC::Record object
    my $record = shift;
    #declaration of return array
    my @warningstoreturn = ();

    my @fields = $record->fields();
#    push @warningstoreturn, join '', ("Record: Contains ", scalar @fields, " fields.") if (@fields > 50);
    foreach my $field (@fields) {
        if (length($field->as_string()) > 1870) {
                push @warningstoreturn, join '', ($field->tag(), ": Field is longer than 1870 bytes.");
        }
    } #foreach field

    return \@warningstoreturn;

} # check_fieldlength

#########################################
#########################################
#########################################
#########################################

=head2 

Add new subs with code below.

=head2

sub  {

    #get passed MARC::Record object

    my $record = shift;

    #declaration of return array

    my @warningstoreturn = ();

    push @warningstoreturn, ("");

    return \@warningstoreturn;

} # 

=cut

#########################################
#########################################
#########################################
#########################################

##########################################
##########################################
##########################################
##########################################
##########################################
#### Validate 006 and 008 and related ####
##########################################
##########################################
##########################################
##########################################
##########################################
##########################################

##########################
##########################
##########################

=head2 _validate006($field006)

Internal sub that checks the validity of 006 bytes.
Used by the check_006 method for 006 validation.

=head2 DESCRIPTION

Checks the validity of 006 bytes.
Continuing resources/serials 006 may not work (not thoroughly tested, since 006 would usually be coded for serials, with 006 for other material types?).

=head2 OTHER INFO

Current version implements material specific validation through internal subs for each material type. Those internal subs allow for checking either 006 or 006 material specific bytes.

=cut

sub _validate006 {

    #populate subroutine $field006 variable with passed string
    my $field006 = shift;

    #declaration of return array
    my @warningstoreturn = ();

    #make sure passed 006 field is exactly 18 bytes
    if (length($field006) != 18) {push @warningstoreturn, ("006: Not 18 characters long. Bytes not validated ($field006).");}

    #return if 006 field of 18 bytes was not found
    return (\@warningstoreturn) if (@warningstoreturn);

    ######################################
    ### Material Specific Bytes, 01-17 ###
    ######################################
    ##### checked via internal subs ######
    ######################################

    #first byte will be either mattype (if not 's') or biblvl ('s' for continuing resources)
    my $mattype = substr($field006, 0, 1);
    my $biblvl = substr($field006, 0, 1);
    my $material_specific_bytes = substr($field006, 1, 17);

    ### Check continuing resources (serials) ###
    if ($biblvl =~ /^[s]$/) {
        my @warnings_returned = _check_cont_res_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #continuing resources (serials)

    #books
    elsif ($mattype =~ /^[at]$/) {
        my @warnings_returned = _check_book_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #books

    #electronic resources/computer files
    elsif ($mattype =~ /^[m]$/) {
        my @warnings_returned = _check_electronic_resources_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #electronic resources
    
    #cartographic materials/maps
    elsif ($mattype =~ /^[ef]$/) {
        my @warnings_returned = _check_cartographic_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #cartographic
    
    #music and sound recordings
    elsif ($mattype =~ /^[cdij]$/) {
        my @warnings_returned = _check_music_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #music/sound recordings

    #visual materials
    elsif ($mattype =~ /^[gkor]$/) {
        my @warnings_returned = _check_visual_material_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #visual materials

    #mixed materials
    elsif ($mattype =~ /^[p]$/) {
        my @warnings_returned = _check_mixed_material_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 006 rather than 008
            @warnings_returned = _reword_006(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #mixed materials

    return (\@warningstoreturn);

} #_validate006



##########################
##########################
##########################

=head2 NAME

parse008date($field008string)

=head2 DESCRIPTION


Subroutine parse008date returns four-digit year, two-digit month, and two-digit day.
It requres an 008 string at least 6 bytes long.
Also checks of current year, month, day vs. 008 creation date, reporting an error if creation date appears to be later than local time. Assumes 008 dates of 00mmdd to 70mmdd represent post-2000 dates.

Relies upon internal _get_current_date().

=head2 SYNOPSIS

 my ($earlyyear, $earlymonth, $earlyday);
 print ("What is the earliest create date desired (008 date, in yymmdd)? ");
 while (my $earlydate = <>) {
 chomp $earlydate;
 my $field008 = $earlydate;
 my $yyyymmdderr = MARC::Errorchecks::parse008date($field008);
 my @parsed008date = split "\t", $yyyymmdderr;
 $earlyyear = shift @parsed008date;
 $earlymonth = shift @parsed008date;
 $earlyday = shift @parsed008date;
 my $errors = join "\t", @parsed008date;
 if ($errors) {
 if ($errors =~ /is too short/) {
 print "Please enter a longer date, $errors\nEnter date (yymmdd): ";
 }
 else {print "$errors\nEnter valid date (yymmdd): ";}
 } #if errors
 else {last;}
 }

=head2 TODO parse008date

Remove local practice or revise for easier updating/customization.

=cut

sub parse008date {

    my $field008 = shift;
    if (length ($field008) < 6) { return "\t\t\t$field008 is too short";}

    #get current yyyymmdd
    my $current_date = MARC::Errorchecks::_get_current_date();
    #get current year
    my $current_year = substr($current_date, 0, 4);


    my $hasbadchars = "";
    my $dateentered = substr($field008,0,6);
    if ($dateentered =~ /^[0-9]+$/) {
        my $yearentered = substr($dateentered, 0, 2);
        #validate year portion--change dates to reflect local implementation of code 
        #(and for future use--after 2070)
        #year created less than or equal to 70 considered 20xx

        if ($yearentered <= 70) {$yearentered += 2000;}
        #year created between 71 and 99 considered 19xx
        elsif ((71 <= $yearentered) && ($yearentered <= 99)) {$yearentered += 1900;}

        #complain if year is after current year
        if ($yearentered > $current_year) {
            $hasbadchars .= "Year entered ($yearentered) is after current year ($current_year)\t";
        } #if creation year is greater than current year

        #complain if creation year is before 1980
        ###This is a local practice check. Customize according to local needs. ###
        elsif ($yearentered < 1980) {
            $hasbadchars .= "Year entered ($yearentered) is before 1980\t";
        } #if date is less than or equal to 1980
        #validate month portion
        my $monthentered = substr($dateentered, 2, 2);
        if (($monthentered < 1) || ($monthentered > 12)) {$hasbadchars .= "Month entered is greater than 12 or is 00\t";}

        #validate day portion
        my $dayentered = substr($dateentered, 4, 2);

        if (($monthentered =~ /^01$|^03$|^05$|^07$|^08$|^10$|^12$/) && (($dayentered < 1) || ($dayentered > 31))) {$hasbadchars .= "Day entered is greater than 31 or is 00\t";}
        elsif (($monthentered =~ /^04$|^06$|^09$|^11$/) && (($dayentered < 1) || ($dayentered > 30))) {$hasbadchars .= "Day entered is greater than 30 or is 00\t";}
        elsif (($monthentered =~ /^02$/) && (($dayentered < 1) || ($dayentered > 29))) {$hasbadchars .= "Day entered is greater than 29 or is 00\t";}
        elsif (($dayentered < 1) || ($dayentered > 31)) {
        $hasbadchars .= "Day entered is greater than 31 or is 00\t";
    } #elsif day is 0 or greater than 31 and month is not normal

    my $full_date_entered = join "", ($yearentered, $monthentered, $dayentered);
    if ($full_date_entered > $current_date) {
        $hasbadchars .= "Date entered ($dateentered) may be later than current date ($current_date)\t";
    } #date entered > current date

    return (join "\t", $yearentered, $monthentered, $dayentered, $hasbadchars)

    } #if date entered has only digits

    else {
        return "\t\t\tRecord creation date ($dateentered) has non-numeric characters";
    } #else creation date has non-digits

    #should never reach this point but just in case
    $hasbadchars .= 'Something is coded wrong in parse008date.';
    return "\t\t\t$hasbadchars";

} #parse008date

##########################
##########################
##########################

=head2 validate008 reworked

Reworking of the validate008 sub.
Revised to work more like other Errorchecks and Lintadditions checks.
Returns array ref of errors.
Previous version returned hash ref of 008 byte key-value pairs,
array ref of cleaned bytes, and scalar ref of errors.
New version returns only an array ref of errors.

=head2 validate008 ($field008, $mattype, $biblvl)

Checks the validity of 008 bytes.
Used by the check_008 method for 008 validation.

=head2 DESCRIPTION

Checks the validity of 008 bytes.
Depends upon 008 being based upon LDR/06,
so continuing resources/serials records may not work.
Checks LDR/07 for 's' for serials before checking material specific bytes.

=head2 OTHER INFO

Character positions 00-17 and 35-39 are defined the same across all types of material, with special consideration for position 06. 

Current version implements material specific validation through internal subs for each material type. Those internal subs allow for checking either 006 or 008 material specific bytes.


=head2 Synopsis

 use MARC::Record;
 use MARC::Errorchecks;

 #$mattype and $biblvl are from LDR/06 and LDR/07
 #my $mattype = substr($leader, 6, 1); 
 #my $biblvl = substr($leader, 7, 1);
 #my $field008 = $record->field('008')->as_string();
 my $field008 = '000101s20002000nyu                 eng d';
 my @warningsfrom008 =  @{MARC::Errorchecks::validate008($field008, $mattype, $biblvl)};

print join "\t", @warningsfrom008, "\n";

=head2 TO DO (validate008)

 Add requirement that 40 char string needs to be passed in.
 Add error checking for less than 40 char string.
 --Partially done--Less than 40 characters leads to error.
 Verify datetypes that allow multiple dates.

 Verify continuing resource checking (not thoroughly tested).

 Determine proper values for date type 'e'.


=head2 SKIP CODE for SERIALS

### This is not here for any particular reason, 
### I just wanted to save it for future use if I needed it.
    #stop checking if record is not coded 'm', monograph
    unless ($biblvl eq 'm') {
        push @warningstoreturn, ("LDR: Record coded $biblvl, not monograph. Further parsing of 008 will not be done for this record.");
        return (\@warningstoreturn);
    } #unless bib level is 'm'




=head2 TEST CODE

 #test code
 use MARC::Errorchecks;
 use MARC::Record;
 my $leader = '00050nam';
 my $field008 = '000101s20002000nyu                 eng d';
 my $mattype = substr($leader, 6, 1); 
 my $biblvl = substr($leader, 7, 1);

 print "$field008\n";
 my @warningsfrom008 =  @{validate008($field008, $mattype, $biblvl)};

print join "\t", @warningsfrom008, "\n";

=cut

#####################################


##########################################
######### Start validate008 sub ##########
##########################################

sub validate008 {

    #populate subroutine $field008 variable with passed string
    my $field008 = shift;
    #populate subroutine $mattype and $biblvl with passed strings
    my $mattype = shift;
    my $biblvl = shift;

    #declaration of return array
    my @warningstoreturn = ();

    #setup country and language code validation hashes
    #from the MARC::Lint::CodeData module
    use MARC::Lint::CodeData qw(%LanguageCodes %ObsoleteLanguageCodes %CountryCodes %ObsoleteCountryCodes);

    #make sure passed 008 field is exactly 40 bytes
    if (length($field008) != 40) {push @warningstoreturn, ("008: Not 40 characters long. Bytes not validated ($field008).");}

    #return if 008 field of 40 bytes was not found
    return (\@warningstoreturn) if (@warningstoreturn);

    #get the values of the all-format positions
    my %field008hash = (
    dateentered => substr($field008,0,6),
    datetype => substr($field008,6,1),
    date1 => substr($field008,7,4), 
    date2 => substr($field008,11,4),
    pubctry => substr($field008,15,3),
    ### format specific 18-34 ###
    langcode => substr($field008,35,3),
    modrec => substr($field008,38,1),
    catsource => substr($field008,39,1)
    );

    #validate the all-format bytes

    # Date entered on file (byte[0]-[5])
    #6 digits, yymmdd
    #parse created date
    #call parse008date to do work of date error checking
    my $yyyymmdderr = MARC::Errorchecks::parse008date($field008hash{dateentered});
    my @parsed008date = split "\t", $yyyymmdderr;
    my $yearentered = shift @parsed008date;
    my $monthentered = shift @parsed008date;
    my $dayentered = shift @parsed008date;
    my $dateerrors = join "\t", @parsed008date;

    #unless date entered is only 6 digits and no errors were found, report the errors
    unless (($field008hash{dateentered} =~ /^\d{6}$/) && $dateerrors !~ /entered/) {
        push @warningstoreturn, ("008: Bytes 0-5, Date entered has bad characters. $dateerrors.");
    } #unless date entered is 6 digits and no errors were found

    #Type of date/Publication status (byte[6])
    #my $datetype = substr($field008,6,1);
    unless ($field008hash{datetype} =~ /^[bcdeikmnpqrstu|]$/) {
        push @warningstoreturn, (join "", "008: Byte 6, Date type ($field008hash{datetype}) has bad characters.");
    } #unless date type is valid code

###### Remove the following ###########
### Remnant of writing of code ####

   #b - No dates given; B.C. date involved
   #c - Continuing resource currently published
   #d - Continuing resource ceased publication
   #e - Detailed date
   #i - Inclusive dates of collection 
   #k - Range of years of bulk of collection 
   #m - Multiple dates
   #n - Dates unknown
   #p - Date of distribution/release/issue and production/recording session when different 
   #q - Questionable date
   #r - Reprint/reissue date and original date
   #s - Single known date/probable date
   #t - Publication date and copyright date 
   #u - Continuing resource status unknown
   #| - No attempt to code 
#########################################


    #Date 1 (byte[7]-[10])
    unless (($field008hash{date1} =~ /^[u\d|]{4}$/) || (($field008hash{date1} =~ /^\s{4}$/) && ($field008hash{datetype} =~ /^b$/)))
        {push @warningstoreturn, ("008: Bytes 7-10, Date1 has bad characters ($field008hash{date1}).")}; 

    ###on date2, verify datetypes that are allowed to have only one date
    # Date 2 (byte[11]-[14])
    #check datetype for single date
    if ($field008hash{datetype} =~ /^[bqs]$/) {
        #if single, need to have four spaces as date2
        unless ($field008hash{date2} =~ /^\s{4}$/) {
            push @warningstoreturn, ("008: Bytes 11-14, Date2 ($field008hash{date2}) should be blank for this date type ($field008hash{datetype}).")
        } #unless date2 has 4 blanks for types b, q, s
    } #if date type is b, q, or s
    #may need elsif for 4 blank spaces with other datetypes or other elsifs for different datetypes (e.g. detailed date, 'e')
    elsif ($field008hash{date2} !~ /^[u\d|]{4}$/) {
        push @warningstoreturn, ("008: Bytes 11-14, Date2 ($field008hash{date2}) has bad characters or is blank which is not consistent with this date type ($field008hash{datetype}).")}


    # Place of publication, production, or execution (byte[15]-[17])
    #my $pubctry = substr($field008,15,3);
    ###Get codes from MARC Country Codes list

    #see if country code matches valid code
    my $validctrycode = 1 if $CountryCodes{$field008hash{pubctry}};
    #look for obsolete code match if valid code was not matched
    my $obsoletectrycode = 1 if $ObsoleteCountryCodes{$field008hash{pubctry}};

    unless ($validctrycode) {
        #code did not match valid code, so see if it may have been valid before
        if ($obsoletectrycode) {
            push @warningstoreturn, ("008: Bytes 15-17, Country of Publication ($field008hash{pubctry}) may be obsolete.");
        }
        else {
            push @warningstoreturn, ("008: Bytes 15-17, Country of Publication ($field008hash{pubctry}) is not valid.")
        }
    } #unless valid country code was found
    
#######################################################
#### byte[18]-[34] are format specific (see below) ####
######################################################

    # Language (byte[35]-[37])

    #%LanguageCodes %ObsoleteLanguageCodes
    my $validlang = 1 if (exists $LanguageCodes{$field008hash{langcode}});
    #look for invalid code match if valid code was not matched
    my $obsoletelang = 1 if (exists $ObsoleteLanguageCodes{$field008hash{langcode}});

    # skip valid subfields
    unless ($validlang) {
        #report invalid matches as possible obsolete codes
        if ($obsoletelang) {
            push @warningstoreturn, ("008: Bytes 35-37, Language ($field008hash{langcode}) may be obsolete.");
        } #if obsolete
        else {
            push @warningstoreturn, ("008: Bytes 35-37, Language ($field008hash{langcode}) not valid.");
        } #else code not found 
    } # unless found valid code

    #report new 'zxx' code when '   ' (3-blanks) is existing code
    if ($field008hash{langcode} eq '   ') {
        push @warningstoreturn, ("008: Bytes 35-37, Language ($field008hash{langcode}) must now be coded 'zxx' for No linguistic content.");
    } #if 008/35-37 is 3-blanks
    ##################################################

    # Modified record (byte[38])
    #my $modrec = substr($field008,38,1);
    unless ($field008hash{modrec} =~ /^[dorsx|\s]$/) {
        push @warningstoreturn, ("008: Byte 38, Modified record has bad characters ($field008hash{modrec}).");
    } #unless modrec has valid characters

    # Cataloging source (byte[39])
    #my $catsource = substr($field008,39,1);
    unless ($field008hash{catsource} =~ /^[cdu|\s]$/) {
        push @warningstoreturn, ("008: Byte 39, Cataloging source has bad characters ($field008hash{catsource}).");
    } #unless Cataloging source is valid

    ######################################
    ### Material Specific Bytes, 18-34 ###
    ######################################
    ##### checked via internal subs ######
    ######################################

    my $material_specific_bytes = substr($field008,18, 17);


    ### Check continuing resources (serials) ###
    if ($biblvl =~ /^[s]$/) {
        my @warnings_returned = _check_cont_res_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #continuing resources (serials)

    #books
    elsif ($mattype =~ /^[at]$/) {
        my @warnings_returned = _check_book_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #books

    #electronic resources/computer files
    elsif ($mattype =~ /^[m]$/) {
        my @warnings_returned = _check_electronic_resources_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #electronic resources
    
    #cartographic materials/maps
    elsif ($mattype =~ /^[ef]$/) {
        my @warnings_returned = _check_cartographic_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #cartographic
    
    #music and sound recordings
    elsif ($mattype =~ /^[cdij]$/) {
        my @warnings_returned = _check_music_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #music/sound recordings

    #visual materials
    elsif ($mattype =~ /^[gkor]$/) {
        my @warnings_returned = _check_visual_material_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #visual materials

    #mixed materials
    elsif ($mattype =~ /^[p]$/) {
        my @warnings_returned = _check_mixed_material_bytes($mattype, $biblvl, $material_specific_bytes);
        if (@warnings_returned) {
            #revise warning messages to report 008 rather than 006
            @warnings_returned = _reword_008(@warnings_returned);
            push @warningstoreturn, @warnings_returned;
        } #if bad bytes
    } #mixed materials


    return (\@warningstoreturn);

} #validate008
    
=head2 _check_cont_res_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Continuing Resources.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_cont_res_bytes {

    ########################################
    ########################################
    ########################################
    ##  Continuing Resources bytes 18-34  ##
    ########################################
    ########################################
    ########################################

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ### Check continuing resources (serials) ###
    if ($biblvl =~ /^[s]$/) {

        # Frequency (byte[18/1])
        $bytehash{frequency} = substr($material_specific_bytes, 0, 1);
        unless ($bytehash{frequency} =~ /^[abcdefghijkmqstuwz|\s]$/) {
            push @warningstoreturn, ("008: Byte 18 (006/01), Continuing resources-Frequency has bad characters ($bytehash{frequency}).");
        } #Continuing resources 18

        # Regularity (byte[19/2])
        $bytehash{regularity} = substr($material_specific_bytes, 1, 1);
        unless ($bytehash{regularity} =~ /^[nrux|]$/) {
            push @warningstoreturn, ("008: Byte 19 (006/02), Continuing resources-Regularity has bad characters ($bytehash{regularity}).");
        } #Continuing resources 19

        #Undefined (was ISSN Center) (byte[20/3])
        $bytehash{contresundef20} = substr($material_specific_bytes, 2, 1);
        unless ($bytehash{contresundef20} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 20 (006/03), Continuing resources-Undef20 has bad characters ($bytehash{contresundef20}).")
        } #Continuing resources 20

        #Type of continuing resource (byte[21/4])
        $bytehash{typeofcontres} = substr($material_specific_bytes, 3, 1);
        unless ($bytehash{typeofcontres} =~ /^[dlmnpw|\s]$/) {
            push @warningstoreturn, ("008: Byte 21 (006/04), Continuing resources-Type of continuing resource has bad characters ($bytehash{typeofcontres}).");
        } #Continuing resources 21

        #Form of original item (byte[22/5])
        $bytehash{formoforig} = substr($material_specific_bytes, 4, 1);
        unless ($bytehash{formoforig} =~ /^[abcdefoqs\s]$/) {
            push @warningstoreturn, ("008: Byte 22 (006/05), Continuing resources-Form of original has bad characters ($bytehash{formoforig}).");
        } #Continuing resources 22

        #Form of item (byte[23/6])
        $bytehash{formofitem} = substr($material_specific_bytes, 5, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 23 (006/06), Continuing resources-Form of item has bad characters ($bytehash{formofitem}).");
        } #Continuing resources 23

        #Nature of entire work (byte[24/7])
        $bytehash{natureofwk} = substr($material_specific_bytes, 6, 1);
        unless ($bytehash{natureofwk} =~ /^[abcdefghiklmnopqrstuvwyz56|\s]$/) {
            push @warningstoreturn, ("008: Byte 24 (006/07), Continuing resources-Nature of work has bad characters ($bytehash{natureofwk}).");
        } #Continuing resources 24

        #Nature of contents (byte[25/8]-[27/10])
        $bytehash{contrescontents} = substr($material_specific_bytes, 7, 3);
        unless ($bytehash{contrescontents} =~ /^[abcdefghiklmnopqrstuvwyz56|\s]{3}$/) {
            push @warningstoreturn, ("008: Bytes 25-27 (006/08-10), Continuing resources-Contents has bad characters ($bytehash{contrescontents}).");
        } #Continuing resources 25-27

        #Government publication (byte[28/11])
        $bytehash{govtpub} = substr($material_specific_bytes, 10, 1);
        unless ($bytehash{govtpub} =~ /^[acfilmosuz|\s]$/) {
            push @warningstoreturn, ("008: Byte 28 (006/11), Continuing resources-Govt publication has bad characters ($bytehash{govtpub}).");
        } #Continuing resources 28

        #Conference publication (byte[29/12])
        $bytehash{confpub} = substr($material_specific_bytes, 11, 1);
        unless ($bytehash{confpub} =~ /^[01|]$/) {
            push @warningstoreturn, ("008: Byte 29 (006/12), Continuing resources-Conference publication has bad characters ($bytehash{confpub}).");
        } #Continuing resources 29

        #Undefined (byte[30/13]-[32/15])
        $bytehash{contresundef30to32} = substr($material_specific_bytes, 12, 3);
        unless ($bytehash{contresundef30to32} =~ /^[|\s]{3}$/) {
            push @warningstoreturn, ("008: Bytes 30-32 (006/13-15), Continuing resources-Undef30to32 has bad characters ($bytehash{contresundef30to32}).");
        } #Continuing resources 30-32 

        #Original alphabet or script of title (byte[33/16])
        $bytehash{origalphabet} = substr($material_specific_bytes, 13, 1);
        unless ($bytehash{origalphabet} =~ /^[abcdefghijkluz|\s]$/) {
            push @warningstoreturn, ("008: Byte 33 (006/16), Continuing resources-Original alphabet has bad characters ($bytehash{origalphabet}).");
        } #Continuing resources 33

        #Entry convention (byte[34/17])
        $bytehash{entryconvention} = substr($material_specific_bytes, 16, 1);
        unless ($bytehash{entryconvention} =~ /^[012|]$/) {
            push @warningstoreturn, ("008: Byte 34 (006/17), Continuing resources-Entry convention has bad characters ($bytehash{entryconvention}).");
        } #Continuing resources 34

    } # Continuing Resources (biblvl 's')
    
    return @warningstoreturn;

} # _check_cont_res_bytes

=head2 _check_book_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Books.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_book_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    ########### Books bytes 18-34 ##########
    ########################################
    ########################################
    ########################################


    if ($mattype =~ /^[at]$/) {

        # Illustrations (byte [18/1]-[21/4])
        $bytehash{illustrations} = substr($material_specific_bytes, 0, 4);
        unless ($bytehash{illustrations} =~ /^[abcdefghijklmop|\s]{4}$/) {
            push @warningstoreturn, ("008: Bytes 18-21 (006/01-04), Books-Illustrations has bad characters ($bytehash{illustrations}).");
        } #Books-18-21

        # Target audience (byte 22/5)
        $bytehash{audience} = substr($material_specific_bytes, 4, 1);
        unless ($bytehash{audience} =~ /^[abcdefgj|\s]$/) {
            push @warningstoreturn, ("008: Byte 22 (006/05), Books-Audience has bad characters ($bytehash{audience}).")
        } #Books 22

        # Form of item (byte 23/6)
        $bytehash{formofitem} = substr($material_specific_bytes, 5, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 23 (006/06), Books-Form of item has bad characters ($bytehash{formofitem}).")
        } #Books 23

        # Nature of contents (byte[24/7]-[27/10])
        $bytehash{bkcontents} = substr($material_specific_bytes, 6, 4);
        unless ($bytehash{bkcontents} =~ /^[abcdefgijklmnopqrstuvwyz256|\s]{4}$/) {
            push @warningstoreturn, ("008: Bytes 24-27 (006/07-10), Books-Contents has bad characters ($bytehash{bkcontents}).")
        } #Books 24-27

        #Government publication (byte 28/11)
        $bytehash{govtpub} = substr($material_specific_bytes, 10, 1);
        unless ($bytehash{govtpub} =~ /^[acfilmosuz|\s]$/) {
            push @warningstoreturn, ("008: Byte 28 (006/11), Books-Govt publication has bad characters ($bytehash{govtpub}).")
        } #Books 28

        #Conference publication (byte 29/12)
        $bytehash{confpub} = substr($material_specific_bytes, 11, 1);
        unless ($bytehash{confpub} =~ /^[01|]$/) {
            push @warningstoreturn, ("008: Byte 29 (006/12), Books-Conference publication has bad characters ($bytehash{confpub}).")
        } #Books 29

        #Festschrift (byte 30/13)
        $bytehash{fest} = substr($material_specific_bytes, 12, 1);
        unless ($bytehash{fest} =~ /^[01|]$/) {
            push @warningstoreturn, ("008: Byte 30 (006/13), Books-Festschrift has bad characters ($bytehash{fest}).")
        } #Books 30

        #Index (byte 31/14)
        $bytehash{bkindex} = substr($material_specific_bytes, 13, 1);
        unless ($bytehash{bkindex} =~ /^[01|]$/) {
            push @warningstoreturn, ("008: Byte 31 (006/14), Books-Index has bad characters ($bytehash{bkindex}).");
        } #Books 31

        #Undefined (byte 32/15)
        $bytehash{obsoletebyte32} = substr($material_specific_bytes, 14, 1);
        unless ($bytehash{obsoletebyte32} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 32 (006/15), Books-Obsoletebyte32 has bad characters ($bytehash{obsoletebyte32}).");
        } #Books 32

        #Literary form (byte 33/16)
        $bytehash{fict} = substr($material_specific_bytes, 15, 1);
        unless ($bytehash{fict} =~ /^[01defhijmpsu|\s]$/) {
            if ($bytehash{fict} eq 'c') {
                push @warningstoreturn, ("008: Byte 33 (006/16), Books-Literary form code 'c' is now covered by 008/24-27 (006/07-10; Nature of contents) value '6'.");
            } #if comic
            else {
                push @warningstoreturn, ("008: Byte 33 (006/16), Books-Literary form has bad characters ($bytehash{fict}).");
            } #else non-comic
        } #Books 33

        #Biography (byte 34/17)
        $bytehash{biog} = substr($material_specific_bytes, 16, 1);
        unless ($bytehash{biog} =~ /^[abcd|\s]$/) {
            push @warningstoreturn, ("008: Byte 34 (006/17), Books-Biography has bad characters ($bytehash{biog}).");
        } #Books 34

    } ### if Books, mattype 'a' or 't'

    return @warningstoreturn;
    
} # _check_book_bytes

=head2 _check_electronic_resources_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Electronic Resources.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_electronic_resources_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    ### Electronic Resources bytes 18-34 ###
    ########################################
    ########################################
    ########################################

    #electronic resources/computer files
    if ($mattype =~ /^[m]$/) {

        #Undefined (byte 18-21/1-4)
        $bytehash{electresundef18to21} = substr($material_specific_bytes, 0, 4);
        unless ($bytehash{electresundef18to21} =~ /^[|\s]{4}$/) {
            push @warningstoreturn, ("008: Bytes 18-21 (006/01-04), Electronic Resources-Undef18to21 has bad characters ($bytehash{electresundef18to21}).");
        } #Electronic Resources 18-21

        #Target audience (byte 22/5)
        $bytehash{audience} = substr($material_specific_bytes, 4, 1);
        unless ($bytehash{audience} =~ /^[abcdefgj|\s]$/) {
            push @warningstoreturn, ("008: Byte 22 (006/05), Electronic Resources-Audience has bad characters ($bytehash{audience}).");
        } #Electronic Resources 22

        #Target audience (byte 23/6)
        $bytehash{formofitem} = substr($material_specific_bytes, 5, 1);
        unless ($bytehash{formofitem} =~ /^[oq|\s]$/) {
            push @warningstoreturn, ("008: Byte 23 (006/06), Electronic Resources-FormofItem has bad characters ($bytehash{formofitem}).");
        } #Electronic Resources 22

        #Undefined (byte[24/7]-[25/8])
        $bytehash{electresundef24to25} = substr($material_specific_bytes, 6, 2);
        unless ($bytehash{electresundef24to25} =~ /^[|\s]{2}$/) {
            push @warningstoreturn, ("008: Bytes 24-25 (006/07-08), Electronic Resources-Undef24to25 has bad characters ($bytehash{electresundef24to25}).");
        } #Electronic Resources 24-25

        #Type of computer file (byte[26/9])
        $bytehash{typeoffile} = substr($material_specific_bytes, 8, 1);
        unless ($bytehash{typeoffile} =~ /^[abcdefghijmuz|]$/) {
            push @warningstoreturn, ("008: Byte 26 (006/09), Electronic Resources-Type of file has bad characters ($bytehash{typeoffile}).");
        } #Electronic Resources 26

        #Undefined (byte[27/10])
        $bytehash{electresundef27} = substr($material_specific_bytes, 9, 1);
        unless ($bytehash{electresundef27} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 27 (006/10), Electronic Resources-Undef27 has bad characters ($bytehash{electresundef27}).");
        } #Electronic Resources 27

        #Government publication (byte [28/11])
        $bytehash{govtpub} = substr($material_specific_bytes, 10, 1);
        unless ($bytehash{govtpub} =~ /^[acfilmosuz|\s]$/) {
            push @warningstoreturn, ("008: Byte 28 (006/11), Electronic Resources-Govt publication has bad characters ($bytehash{govtpub}).");
        } #Electronic Resources 28

        #Undefined (byte[29/12]-[34/17])
        $bytehash{electresundef29to34} = substr($material_specific_bytes, 11, 6);
        unless ($bytehash{electresundef29to34} =~ /^[|\s]{6}$/) {
            push @warningstoreturn, ("008: Bytes 29-34 (006/12-17), Electronic Resources-Undef29to34 has bad characters ($bytehash{electresundef29to34}).")
        } #Electronic Resources 29-34 

    } # if electronic resources mattype 'm'

    return @warningstoreturn;
    
} # _check_electronic_resources_bytes

=head2 _check_cartographic_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Cartographic Materials.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_cartographic_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    #  Cartographic Materials bytes 18-34  #
    ########################################
    ########################################
    ########################################

    #cartographic materials/maps
    if ($mattype =~ /^[ef]$/) {

        #Relief (byte[18/1]-[21/4])
        $bytehash{relief} = substr($material_specific_bytes, 0, 4);
        unless ($bytehash{relief} =~ /^[abcdefgijkmz|\s]{4}$/) {
            push @warningstoreturn, ("008: Bytes 18-21 (006/01-04), Cartographic-Relief has bad characters ($bytehash{relief}).");
        } #Cartographic 18-21

        #Projection (byte[22/5]-[23/6])
        $bytehash{projection} = substr($material_specific_bytes, 4, 2);
        unless ($bytehash{projection} =~ /^\|\||\s\s|aa|ab|ac|ad|ae|af|ag|am|an|ap|au|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bo|br|bs|bu|bz|ca|cb|cc|ce|cp|cu|cz|da|db|dc|dd|de|df|dg|dh|dl|zz$/) {
            push @warningstoreturn, ("008: Bytes 22-23 (006/05-06), Cartographic-Projection has bad characters ($bytehash{projection}).");
            } #Cartographic 22-23 

        #Undefined (byte[24/7])
        $bytehash{mapundef24} = substr($material_specific_bytes, 6, 1);
        unless ($bytehash{mapundef24} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 24 (006/7), Cartographic-Undef24 has bad characters ($bytehash{mapundef24}).");
        } #Cartographic 24

        #Type of cartographic material (byte[25/8])
        $bytehash{typeofmap} = substr($material_specific_bytes, 7,1);
        unless ($bytehash{typeofmap} =~ /^[abcdefguz|]$/) {
            push @warningstoreturn, ("008: Byte 25 (006/08), Cartographic-Type of map has bad characters ($bytehash{typeofmap}).");
        } #Cartographic 25

        #Undefined (byte[26/9]-[27/10])
        $bytehash{mapundef26to27} = substr($material_specific_bytes, 8, 2);
        unless ($bytehash{mapundef26to27} =~ /^[|\s]{2}$/) {
            push @warningstoreturn, ("008: Bytes 26-27 (006/09-10), Cartographic-Undef26to27 has bad characters ($bytehash{mapundef26to27}).");
        } #Cartographic 26-27 

        #Government publication (byte[28/11])
        $bytehash{govtpub} = substr($material_specific_bytes, 10, 1);
        unless ($bytehash{govtpub} =~ /^[acfilmosuz|\s]$/) {
            push @warningstoreturn, ("008: Byte 28 (006/11), Cartographic-Govt publication has bad characters ($bytehash{govtpub}).");
        } #Cartographic 28

        #Form of item (byte[29/12])
        $bytehash{formofitem} = substr($material_specific_bytes, 11, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 29 (006/12), Cartographic-Form of item has bad characters ($bytehash{formofitem}).");
        } #Cartographic 29

        #Undefined (byte[30/13])
        $bytehash{mapundef30} = substr($material_specific_bytes, 12, 1);
        unless ($bytehash{mapundef30} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 30 (006/13), Cartographic-Undef30 has bad characters ($bytehash{mapundef30}).");
        } #Cartographic 30

        #Index (byte[31/14])
        $bytehash{mapindex} = substr($material_specific_bytes, 13, 1);
        unless ($bytehash{mapindex} =~ /^[01|]$/) {
            push @warningstoreturn, ("008: Byte 31 (006/14), Cartographic-Index has bad characters ($bytehash{mapindex}).");
        } #Cartographic 31

        #Undefined (byte[32/15])
        $bytehash{mapundef32} = substr($material_specific_bytes, 14, 1);
        unless ($bytehash{mapundef32} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 32 (006/15), Cartographic-Undef32 has bad characters ($bytehash{mapundef32}).");
        } #Cartographic 32

        #Special format characteristics (byte[33/16]-[34/17])
        $bytehash{specialfmtchar} = substr($material_specific_bytes, 15, 2);
        unless ($bytehash{specialfmtchar} =~ /^[ejklnoprz|\s]{2}$/) {
            push @warningstoreturn, ("008: Bytes 33-34 (006/16-17), Cartographic-Special format characteristics has bad characters ($bytehash{specialfmtchar}).");
            } #Cartographic 33-34

    } # Cartographic Materials


    return @warningstoreturn;
    
} # _check_cartographic_bytes

=head2 _check_music_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Music and Sound Recordings.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_music_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    #  Music/Sound Recordings bytes 18-34  #
    ########################################
    ########################################
    ########################################

    #music and sound recordings
    if ($mattype =~ /^[cdij]$/) {

        #Form of composition (byte[18/1]-[19/2])
        $bytehash{formofcomp} = substr($material_specific_bytes, 0, 2);
        unless ($bytehash{formofcomp} =~ /^\|\||an|bd|bg|bl|bt|ca|cb|cc|cg|ch|cl|cn|co|cp|cr|cs|ct|cy|cz|df|dv|fg|fl|fm|ft|gm|hy|jz|mc|md|mi|mo|mp|mr|ms|mu|mz|nc|nn|op|or|ov|pg|pm|po|pp|pr|ps|pt|pv|rc|rd|rg|ri|rp|rq|sd|sg|sn|sp|st|su|sy|tc|tl|ts|uu|vi|vr|wz|za|zz$/) {
            push @warningstoreturn, ("008: Bytes 18-19 (006/01-02), Music-Form of composition has bad characters ($bytehash{formofcomp}).");
        } #Music 18-19

        #Format of music (byte[20/3])
        $bytehash{fmtofmusic} = substr($material_specific_bytes, 2, 1);
        unless ($bytehash{fmtofmusic} =~ /^[abcdeghijklmnuz|]$/) {
            push @warningstoreturn, ("008: Byte 20 (006/03), Music-Format of music has bad characters ($bytehash{fmtofmusic}).");
        } #Music 20

        #Music parts (byte[21/4])
        $bytehash{musicparts} = substr($material_specific_bytes, 3, 1);
        unless ($bytehash{musicparts} =~ /^[defnu|\s]$/) {
            push @warningstoreturn, ("008: Byte 21 (006/04), Music-Parts has bad characters ($bytehash{musicparts}).");
        } #Music 21

        #Target audience (byte[22/5])
        $bytehash{audience} = substr($material_specific_bytes, 4, 1);
        unless ($bytehash{audience} =~ /^[abcdefgj|\s]$/) {
            push @warningstoreturn, ("008: Byte 22 (006/05), Music-Audience has bad characters ($bytehash{audience}).");
        } #Music 22

        #Form of item (byte[23/6])
        $bytehash{formofitem} = substr($material_specific_bytes, 5, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 23 (006/06), Music-Form of item has bad characters ($bytehash{formofitem}).");
        } #Music 23

        #Accompanying matter (byte[24/7]-[29/12])
        $bytehash{accompmat} = substr($material_specific_bytes, 6, 6);
        unless ($bytehash{accompmat} =~ /^[abcdefghikrsz|\s]{6}$/) {
            push @warningstoreturn, ("008: Bytes 24-29 (006/07-12), Music-Accompanying material has bad characters ($bytehash{accompmat}).");
        } #Music 24-29 

        #Literary text for sound recordings (byte[30/13]-[31/14])
        $bytehash{textforsdrec} = substr($material_specific_bytes, 12, 2);
        unless ($bytehash{textforsdrec} =~ /^[abcdefghijklmnoprstz|\s]{2}$/) {
            push @warningstoreturn, ("008: Byte 30-31 (006/13-14), Music-Text for sound recordings has bad characters ($bytehash{textforsdrec}).");
        } #Music 30-31

        #Undefined (byte[32/15])
        $bytehash{musicundef32} = substr($material_specific_bytes, 14, 1);
        unless ($bytehash{musicundef32} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 32 (006/15), Music-Undef32 has bad characters ($bytehash{musicundef32}).");
        } #Music 32

        #Transposition and arrangement (byte[33/16])
        $bytehash{transposeandarr} = substr($material_specific_bytes, 15, 1);
        unless ($bytehash{transposeandarr} =~ /^[abcnu|\s]$/) {
            push @warningstoreturn, ("008: Byte 33 (006/16), Music-Transposition and arrangement has bad characters ($bytehash{transposeandarr}).");
        } #Music 33

        #Undefined (byte[34/17])
        $bytehash{musicundef34} = substr($material_specific_bytes, 16, 1);
        unless ($bytehash{musicundef34} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 34 (006/17), Music-Undef34 has bad characters ($bytehash{musicundef34}).");
        } #Music 34

    } # Music and Sound Recordings

    return @warningstoreturn;
    
} # _check_music_bytes

=head2 _check_visual_material_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Visual Materials.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_visual_material_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    ####  Visual Materials bytes 18-34  ####
    ########################################
    ########################################
    ########################################

    #visual materials
    if ($mattype =~ /^[gkor]$/) {

        #Running time for motion pictures and videorecordings (byte[18/1]-[20/3])
        $bytehash{runningtime} = substr($material_specific_bytes, 0, 3);
        unless ($bytehash{runningtime} =~ /^([|\d]{3}|\-{3}|n{3})$/) {
            push @warningstoreturn, ("008: Bytes 18-20 (006/01-03), Visual materials-Runningtime has bad characters ($bytehash{runningtime}).")
        } #Visual materials 18-20

        #Undefined (byte[21/4])
        $bytehash{visualmatundef21} = substr($material_specific_bytes, 3, 1);
        unless ($bytehash{visualmatundef21} =~ /^[|\s]$/) {
            push @warningstoreturn, ("008: Byte 21 (006/04), Visual materials-Undef21 has bad characters ($bytehash{visualmatundef21}).");
        } #Visual materials 21

        #Target audience (byte[22/5])
        $bytehash{audience} = substr($material_specific_bytes, 4, 1);
        unless ($bytehash{audience} =~ /^[abcdefgj|\s]$/) {
            push @warningstoreturn, ("008: Byte 22 (006/05), Visual materials-Audience has bad characters ($bytehash{audience}).");
        } #Visual materials 22

        #Undefined (byte[23/6]-[27/10])
        $bytehash{visualmatundef23to27} = substr($material_specific_bytes, 5, 5);
        unless ($bytehash{visualmatundef23to27} =~ /^[|\s]{5}$/) {
            push @warningstoreturn, ("008: Bytes 23-27 (006/06-10), Visual materials-Undef23to27 has bad characters ($bytehash{visualmatundef23to27}).");
        } #Visual materials 23-27 

        #Government publication (byte[28/11])
        $bytehash{govtpub} = substr($material_specific_bytes, 10, 1);
        unless ($bytehash{govtpub} =~ /^[acfilmosuz|\s]$/) {
            push @warningstoreturn, ("008: Byte 28 (006/11), Visual materials-Govt publication has bad characters ($bytehash{govtpub}).");
        } #Visual materials 28

        #Form of item (byte[29/12])
        $bytehash{formofitem} = substr($material_specific_bytes, 11, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 29 (006/12), Visual materials-Form of item has bad characters ($bytehash{formofitem}).");
        } #Visual materials 29

        #Undefined (byte[30/13]-[32/15])
        $bytehash{visualmatundef30to32} = substr($material_specific_bytes, 12, 3);
        unless ($bytehash{visualmatundef30to32} =~ /^[|\s]{3}$/) {
            push @warningstoreturn, ("008: Bytes 30-32 (006/13-15), Visual materials-Undef30to32 has bad characters ($bytehash{visualmatundef30to32}).");
        } #Visual materials 30-32 

        #Type of visual material (byte[33/16])
        $bytehash{typevisualmaterial} = substr($material_specific_bytes, 15, 1);
        unless ($bytehash{typevisualmaterial} =~ /^[abcdfgiklmnopqrstvwz|]$/) {
            push @warningstoreturn, ("008: Byte 33 (006/16), Visual materials-Type of visual material has bad characters ($bytehash{typevisualmaterial}).");
        }

        #Technique (byte[34/17])
        $bytehash{technique} = substr($material_specific_bytes, 16, 1);
        unless ($bytehash{technique} =~ /^[aclnuz|]$/) { push @warningstoreturn, ("008: Byte 34 (006/17), Visual materials-Technique has bad characters ($bytehash{technique}).");
        } #Visual materials 34

    } #Visual Materials

    return @warningstoreturn;
    
} # _check_visual_material_bytes

=head2 _check_mixed_material_bytes($mattype, $biblvl, $bytes)

 Internal sub to check 008 bytes 18-34 or 006 bytes 01-17 for Mixed Materials.

 Receives material type, bibliographic level, and a 17-byte string to be validated. The bytes should be bytes 18-34 of the 008, or bytes 01-17 of the 006.

=cut

sub _check_mixed_material_bytes {

    my $mattype = shift;
    my $biblvl = shift;
    my $material_specific_bytes = shift;

    my %bytehash = ();
    my @warningstoreturn = ();

    ########################################
    ########################################
    ########################################
    ####  Mixed Materials bytes 18-34   ####
    ########################################
    ########################################
    ########################################

    #mixed materials
    if ($mattype =~ /^[p]$/) {

        #Undefined (byte[18/1]-[22/5])
        $bytehash{mixedundef18to22} = substr($material_specific_bytes, 0, 5);
        unless ($bytehash{mixedundef18to22} =~ /^[|\s]{5}$/) {
            push @warningstoreturn, ("008: Bytes 18-22 (006/01-05), Mixed materials-Undef18to22 has bad characters ($bytehash{mixedundef18to22}).");
        } #Mixed materials 18-22 

        #Form of item (byte[23/6])
        $bytehash{formofitem} = substr($material_specific_bytes, 5, 1);
        unless ($bytehash{formofitem} =~ /^[abcdfoqrs|\s]$/) {
            push @warningstoreturn, ("008: Byte 23 (006/06), Mixed materials-Form of item has bad characters ($bytehash{formofitem}).");
        } #Mixed materials 23

        #Undefined (byte[24/7]-[34/17])
        $bytehash{mixedundef24to34} = substr($material_specific_bytes, 6, 11);
        unless ($bytehash{mixedundef24to34} =~ /^[|\s]{11}$/) {
            push @warningstoreturn, ("008: Bytes 24-34 (006/07-17), Mixed materials-Undef24to34 has bad characters ($bytehash{mixedundef24to34}).");
        } #Mixed materials 24-30 

    } #Mixed Materials


#########################################
#########################################
#########################################
#########################################

    return @warningstoreturn;
    
} # _check_mixed_material_bytes

sub _reword_008 {
    my @warnings = @_;

    foreach (@warnings) {
        $_ =~ s/^(008: Byte[ s] ?[\-0-9]+) \(006\/[\-0-9]+\)/$1/;        
    } #foreach warning

    return @warnings;

} #_reword_008

sub _reword_006 {

    my @warnings = @_;

    foreach (@warnings) {
        $_ =~ s/^(008: Byte[ s] ?[\-0-9]+) \(006\/([\-0-9]+)\)/006: Byte(s) $2/;

    } #foreach warning

    return @warnings;

} #_reword_006

#########################################
#########################################
#########################################
#########################################

=head2 _get_current_date()

Internal sub for use with validate008($field008, $mattype, $biblvl) (actually with parse008date($field008string)). Returns the current year-month-day, in the form yyyymmdd.

Also used by check_010($record).

=cut

sub _get_current_date {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
  
    $year += 1900;
    #add 1 to month to account for 0-base
    $mon++; 

    return sprintf("%0.4d%0.2d%0.2d",$year,$mon,$mday);

} #_get_current_date()

#########################################
#########################################
#########################################
#########################################

#########################################
#########################################
#########################################
#########################################

=head1 CHANGES/VERSION HISTORY

Version 1.18: Updated Oct. 8, 2012 to June 22, 2013. Released , 2013.

 -Updated _check_music_bytes for MARC Update 16 (Sept. 2012), adding 'l' as valid for 008/20.

Version 1.17: Updated Oct. 8, 2012 to June 22, 2013. Released June 23, 2013.

 -Updated check_490vs8xx($record) to look only for 800, 810, 811, 830 rather than any 8XX.
 -Added functionality to deal with RDA records.
 -Updated parse008vs300b($illcodes, $field300subb, $record_is_RDA) to pass 3rd variable, "$record_is_RDA".
 -Updated _check_music_bytes for MARC Update 15 (Sept. 2012), adding 'k' as valid for 008/20.

Version 1.16: Updated May 16-Nov. 14, 2011. Released .

 -Turned off check_fieldlength($record) in check_all_subs()
 -Turned off checking of floating hyphens in 520 fields in findfloatinghyphens($record)
 -Updated validate008 subs (and 006) related to 008/24-27 (Books and Continuing Resources) for MARC Update no. 10, Oct. 2009 and Update no. 11, 2010; no. 12, Oct. 2010; and no. 13, Sept. 2011.
 -Updated %ldrbytes with leader/18 'c' and redefinition of 'i' per MARC Update no. 12, Oct. 2010.

Version 1.15: Updated June 24-August 16, 2009. Released , 2009.

 -Updated checks related to 300 to better account for electronic resources.
 -Revised wording in validate008($field008, $mattype, $biblvl) language code (008/35-37) for '   '/zxx.
 -Updated validate008 subs (and 006) related to 008/24-27 (Books and Continuing Resources) for MARC Update no. 9, Oct. 2008.
 -Updated validate008 sub (and 006) for Books byte 33, Literary form, invalidating code 'c' and referring it to 008/24-27 value 'c' .
 -Updated video007vs300vs538($record) to allow Blu-ray in 538 and 's' in 07/04.

Version 1.14: Updated Oct. 21, 2007, Jan. 21, 2008, May 20, 2008. Released May 25, 2008.

 -Updated %ldrbytes with leader/19 per Update no. 8, Oct. 2007. Check for validity of leader/19 not yet implemented.
 -Updated _check_book_bytes with code '2' ('Offprints') for 008/24-27, per Update no. 8, Oct. 2007.
 -Updated check_245ind1vs1xx($record) with TODO item and comments
 -Updated check_bk008_vs_300($record) to allow "leaves of plates" (as opposed to "leaves", when no p. or v. is present), "leaf", and "column"(s).

Version 1.13: Updated Aug. 26, 2007. Released Oct. 3, 2007.

 -Uncommented valid MARC 21 leader values in %ldrbytes to remove local practice. Libraries wishing to restrict leader values should comment out individual bytes to enable errors when an unwanted value is encountered.
 -Added ldrvalidate.t.pl and ldrvalidate.t tests.
 -Includes version 1.18 of MARC::Lint::CodeData.

Version 1.12: Updated July 5-Nov. 17, 2006. Released Feb. 25, 2007.

 -Updated check_bk008_vs_300($record) to look for extra p. or v. after parenthetical qualifier.
 -Updated check_bk008_vs_300($record) to look for missing period after 'col' in subfield 'b'.
 -Replaced $field-tag() with $tag in error message reporting in check_nonpunctendingfields($record).
 -Turned off 50-field limit check in check_fieldlength($record).
 -Updated parse008vs300b($illcodes, $field300subb) to look for /map[ \,s]/ rather than just 'map' when 008 is coded 'b'.
 -Updated check_bk008_vs_bibrefandindex($record) to look for spacing on each side of parenthetical pagination.
 -Updated check_internal_spaces($record) to report 10 characters on either side of each set of multiple internal spaces.
 -Uncommented level-5 and level-7 leader values as acceptable. Level-3 is still commented out, but could be uncommented for libraries that allow it.
 -Includes version 1.14 of MARC::Lint::CodeData.

Version 1.11: Updated June 5, 2006. Released June 6, 2006.

 -Implemented check_006($record) to validate 006 (currently only does length check).
 --Revised validate008($field008, $mattype, $biblvl) to use internal sub for material specific bytes (18-34)
 -Revised validate008($field008, $mattype, $biblvl) language code (008/35-37) to report new 'zxx' code availability when '   ' is the code in the record.
 -Added 'mgmt.' to %abbexceptions for check_nonpunctendingfields($record).

Version 1.10: Updated Sept. 5-Jan. 2, 2006. Released Jan. 2, 2006.

 -Revised validate008($field008, $mattype, $biblvl) to use internal subs for material specific byte checking.
 --Added: 
 ---_check_cont_res_bytes($mattype, $biblvl, $bytes),
 ---_check_book_bytes($mattype, $biblvl, $bytes),
 ---_check_electronic_resources_bytes($mattype, $biblvl, $bytes),
 ---_check_cartographic_bytes($mattype, $biblvl, $bytes),
 ---_check_music_bytes($mattype, $biblvl, $bytes),
 ---_check_visual_material_bytes($mattype, $biblvl, $bytes),
 ---_check_mixed_material_bytes,
 ---_reword_008(@warnings), and
 ---_reword_006(@warnings).
 --Updated Continuing resources byte 20 from ISSN center to Undefined per MARC 21 update of Oct. 2003.
 -Updated wording in findfloatinghyphens($record) to report 10 chars on either side of floaters and check_floating_punctuation($record) to report some context if the field in question has more than 80 chars.
 -check_bk008_vs_bibrefandindex($record) updated to check for 'p. ' following bibliographical references when pagination is present.
 -check_5xxendingpunctuation($record) reports question mark or exclamation point followed by period as error.
 -check_5xxendingpunctuation($record) now checks 505.
 -Updated check_nonpunctendingfields($record) to account for initialisms with interspersed periods.
 -Added check_floating_punctuation($record) looking for unwanted spaces before periods, commas, and other punctuation marks.
 -Renamed findfloatinghyphens($record) to fix spelling.
 -Revised check_bk008_vs_300($record) to account for textual materials on CD-ROM.
 -Added abstract to name.

Version 1.09: Updated July 18, 2005. Released July 19, 2005 (Aug. 14, 2005 to CPAN).

 -Added check_010.t (and check_010.t.pl) tests for check_010($record).
 -check_010($record) revisions.
 --Turned off validation of 8-digit LCCN years. Code commented-out.
 --Modified parsing of numbers to check spacing for 010a with valid non-digits after valid numbers.
 --Validation of 10-digit LCCN years is based on current year.
 -Fixed bug of uninitialized values for matchpubdates($record) 050 and 260 dates.
 -Corrected comparison for year entered < 1980.
 -Removed AutoLoader (which was a remnant of the initial module creation process)

Version 1.08: Updated Feb. 15-July 11, 2005. Released July 16, 2005.

 -Added 008errorchecks.t (and 008errorchecks.t.txt) tests for 008 validation
 -Added check of current year, month, day vs. 008 creation date, reporting error if creation date appears to be later than local time. Assumes 008 dates of 00mmdd to 70mmdd represent post-2000 dates.
 --This is a change from previous range, which gave dates as 00-06 as 200x, 80-99 as 19xx, and 07-79 as invalid. 
 -Added _get_current_date() internal sub to assist with check of creation date vs. current date.
 -findemptysubfields($record) also reports error if period(s) and/or space(s) are the only data in a subfield.
 -Revised wording of error messages for validate008($field008, $mattype, $biblvl)
 -Revised parse008date($field008string) error message wording and bug fix.
 -Bug fix in video007vs300vs538($record) for gathering multiple 538 fields.
 -added check in check_5xxendingpunctuation($record) for space-semicolon-space-period at the end of 5xx fields.
 -added field count check for more than 50 fields to check_fieldlength($record)
 -added 'webliography' as acceptable 'bibliographical references' term in check_bk008_vs_bibrefandindex($record), even though it is discouraged. Consider adding an error message indicating that the term should be 'bibliographical references'?
 -Code indenting changed from tabs to 4 spaces per tab.
 -Misc. bug fixes including changing '==' to 'eq' for tag numbers, bytes in 008, and indicators.

Version 1.07: Updated Dec. 11-Feb. 2005. Released Feb. 13, 2005.

 -check_double_periods() skips field 856, where multiple punctuation is possible for URIs.
 -added code in check_internal_spaces() to account for spaces between angle brackets in open dates in field 260c.
 -Updated various subs to verify that 008 exists (and quietly return if not. check_008 will report the error).
 -Changed #! line, removed -w, replaced with use warnings.
 -Added error message to check_bk008_vs_bibrefandindex($record) if 008 book
 index byte is not 0 or 1. This will result in duplicate errors if check_008 is
 also called on the record.

Version 1.05 and 1.06: Updated Dec. 6-7. Released Dec. 6-7, 2004.

 -CPAN distribution fix.

Version 1.04: Updated Nov. 4-Dec. 4, 2004. Released Dec. 5, 2004.

 -Updated validate008() to use MARC::Lint::CodeData.
 -Removed DATA section, since this is now in MARC::Lint::CodeData.
 -Updated check_008() to use the new validate008().
 -Revised bib. refs. check to require 'reference' to be followed by optional 's', optional period, and word boundary (to catch things like 'referenced'.


Version 1.03: Updated Aug. 30-Oct. 16, 2004. Released Oct. 17. First CPAN version.

 -Moved subs to MARC::QBIerrorchecks
 --check_003($record)
 --check_CIP_for_stockno($record)
 --check_082count($record)
 -Fixed bug in check_5xxendingpunctuation for first 10 characters.
 -Moved validate008() and parse008date() from MARC::BBMARC (to make MARC::Errorchecks more self-contained).
 -Moved readcodedata() from BBMARC (used by validate008)
 -Moved DATA from MARC::BBMARC for use in readcodedata() 
 -Remove dependency on MARC::BBMARC
 -Added duplicate comma check in check_double_periods($record)
 -Misc. bug fixes
 Planned (future versions):
 -Account for undetermined dates in matchpubdates($record).
 -Cleanup of validate008
 --Standardization of error reporting
 --Material specific byte checking (bytes 18-34) abstracted to allow 006 validation.
  
Version 1.02: Updated Aug. 11-22, 2004. Released Aug. 22, 2004.

 -Implemented VERSION (uncommented)
 -Added check for presence of 040 (check_040present($record)).
 -Added check for presence of 2 082s in full-level, 1 082 in CIP-level records (check_082count($record)).
 -Added temporary (test) check for trailing punctuation in 240, 586, 440, 490, 246 (check_nonpunctendingfields($record))
 --which should not end in punctuation except when the data ends in such.
 -Added check_fieldlength($record) to report fields longer than 1870 bytes.
 --This should be rewritten to use the length in the directory of the raw MARC.
 -Fixed workaround in check_bk008_vs_bibrefandindex($record) (Thanks again to Rich Ackerman).
 
Version 1.01: Updated July 20-Aug. 7, 2004. Released Aug. 8, 2004.

 -Temporary (or not) workaround for check_bk008_vs_bibrefandindex($record) and bibliographies.
 -Removed variables from some error messages and cleanup of messages.
 -Code readability cleanup.
 -Added subroutines:
 --check_240ind1vs1xx($record)
 --check_041vs008lang($record)
 --check_5xxendingpunctuation($record)
 --findfloatinghypens($record)
 --video007vs300vs538($record)
 --ldrvalidate($record)
 --geogsubjvs043($record)
 ---has list of exceptions (e.g. English-speaking countries)
 --findemptysubfields($record)
 -Changed subroutines:
 --check_bk008_vs_300($record): 
 ---added cross-checking for codes a, b, c, g (ill., map(s), port(s)., music)
 ---added checking for 'p. ' or 'v. ' or 'leaves ' in subfield 'a'
 ---added checking for 'cm.', 'mm.', 'in.' in subfield 'c'
 --parse008vs300b
 ---revised check for 'm', phono. (which our catalogers don't currently use)
 --Added check in check_bk008_vs_bibrefandindex($record) for 'Includes index.' (or indexes) in 504
 ---This has a workaround I would like to figure out how to fix
 
Version 1.00 (update to 0.95): First release July 18, 2004.

 -Fixed bugs causing check_003 and check_010 subroutines to fail (Thanks to Rich Ackerman)
 -Added to documentation
 -Misc. cleanup
 -Added skip of 787 fields to check_internal_spaces
 -Added subroutines:
 --check_end_punct_300($record)
 --check_bk008_vs_300($record)
 ---parse008vs300b
 --check_490vs8xx($record)
 --check_245ind1vs1xx($record)
 --matchpubdates($record)
 --check_bk008_vs_bibrefandindex($record)

Version 1 (original version (actually version 0.95)): First release, June 22, 2004

=head1 SEE ALSO

MARC::Record -- Required for this module to work.

MARC::Lint -- In the MARC::Record distribution and basis for this module.

MARC::Lintadditons -- Extension of MARC::Lint for checks involving individual tags.
(vs. cross-field checking covered in this module).
Available at http://home.inwave.com/eija (and may be merged into MARC::Lint).

MARC pages at the Library of Congress (http://www.loc.gov/marc)

Anglo-American Cataloging Rules, 2nd ed., 2002 revision, plus updates.

Library of Congress Rule Interpretations to AACR2.

MARC Report (http://www.marcofquality.com) -- More full-featured commercial program for validating MARC records.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this module is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2003-2013

=cut

1;

__END__