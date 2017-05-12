#!perl -w

=head2 JUNK CODE

 ####################
 ####################
 ###
 ### Add below where it belongs. Also, use
 ### in individual scripts where needed.
 ###
 ### #!/usr/bin/perl -w
 ### # use strict;
 ### # $| = 1;
 ### # use MARC::File;
 ###
 ####################
 ####################

=cut

package MARC::BBMARC;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. @EXPORT = qw();

$VERSION = 1.08;

=head1 NAME

MARC::BBMARC

=head1 SYNOPSIS

Basic list of subs. For individual use, see the descriptions/POD-like info above each sub.

  use MARC::Field;
  use MARC::File;
  use MARC::BBMARC;
  MARC::BBMARC::as_formatted2();
  MARC::BBMARC::recas_formatted();
  MARC::BBMARC::skipget();
  MARC::BBMARC::getthreedigits();
  MARC::BBMARC::getindicators();
  MARC::BBMARC::updated_record_array();
  MARC::BBMARC::read_controlnos();
  MARC::BBMARC::readcodedata();
  MARC::BBMARC::parse008date($field008string);
  MARC::BBMARC::updated_record_hash();
  
=head1 DESCRIPTION

Collection of methods and subroutines, add-ons to MARC::Record, MARC::File, MARC::Field.

Subroutines include: 

C<as_formatted2()>, add-on to MARC::Field, which pretty-prints fields, separating subfields by tabs, rather than line breaks.

C<recas_formatted()>, add-on to MARC::Record, which is the same as as_formatted, but uses as_formatted2() instead.

C<skipget()>, add-on to  MARC::File, which returns the next raw marc record from a file.

C<updated_record_array()>, which creates an array of control numbers (001) from input file. Used with merge marc script. Call to initialize updated record array variable prior to entering loop. Accepts passed file name, or prompts for one.

C<read_controlnos()>, reads file of control number and returns the control numbers (or lines of file) as an array. Accepts passed file name, or prompts for one.

C<getthreedigits()>, prompts (without prompt) for 3 digit number, if not received, asks to try again.

C<getindicators()>, prompts for 1st and 2nd indicator values. Parses for legitimate values. 
Returns 2 array references:
\@indicators, \@indicatortypes
The first contains the values of the indicators.
The second contains the types of those indicators.
The first element in each is 'empty', so numbering
matches indicator 1 and indicator 2.
Indicator types: 'digit', 'blank', or 'any'.

C<readcodedata()>, subroutine for reading data to build an array of country codes, geographic area codes, and language codes, valid and obsolete, for use in validate008 (in MARC::Errorchecks) and 043 validation (in Lintadditions (which uses its own, similar subroutine).

C<parse008date($field008string)>, preliminary version of code to parse a 6 digit date in the form yymmdd into yyyy\tmm\tdd\t$errors. It is from validate008, and that subroutine might be (or has been?) cleaned by calling parse008date($field008string).

C<counting_print( $number )>, prints out running count ('$number') passed in, based on constant MOD_INTERVAL (if count divides evenly).

C<startstop_time()>, returns current time in h:m:s format. If numbers are 1 digit, then only that digit appears (may be fixed later).

Also includes code to wrap around scripts, integrating startstop_time and counting_print, plus elapsed time.

C<updated_record_hash()>, similar to updated_record_array(), but stores raw USMARC record indexed (keyed) by control number. This has not been fully tested, and will likely eat massive amounts of memory, especially for large files of records.

C<as_array()>, add-on to MARC::Field, breaks field into flat array of subfield code-data pairs. Based on example #U9 of the MARC::Doc::Tutorial. 


=head1 EXPORT

None

=head1 TO DO

Figure out how to "use" and not have to put MARC::BBMARC before subroutine/method calls.

Clean up readability of POD-like documentation.

Test and cleanup updated_record_hash()

(More to do in individual subs).

Evaluate the usefulness of parse008date, which is now duplicated in MARC::Errorchecks.

Verify each of the codes in the data against current lists and lists of changes. Maintain code list data when future changes occur.

=cut

###################################################
# Link methods to MARC modules, for compatibility #
###################################################

*MARC::File::skipget = *MARC::BBMARC::skipget;
*MARC::Field::as_formatted2 = *MARC::BBMARC::as_formatted2;
*MARC::Field::as_array = *MARC::BBMARC::as_array;
*MARC::Record::as_formatted2 = *MARC::BBMARC::recas_formatted;

=head2 as_formatted2()

Returns a pretty string for printing in a MARC dump.
From MARC::Field.

=cut

sub as_formatted2() {

	use MARC::Field;

	my $self = shift;
	### @lines will contain tag number, indicators,
	### and subfield data.
	my @lines = ();

	if ( $self->is_control_field() ) {
		push( @lines, sprintf( "%03s     %s", $self->{_tag}, $self->{_data} ) );
	} 
	else {
		my $hanger = sprintf( "%03s %1.1s%1.1s", $self->{_tag}, $self->{_ind1}, $self->{_ind2} );

		my @subdata = @{$self->{_subfields}};
		while ( @subdata ) {
			my $code = shift @subdata;
			my $text = shift @subdata;

### push onto @lines each subfield, formatting each
### according to the info in the sprintf call
### hanger is already formatted as: %03==3 places,
### pad with zeros; [space], 1 char, 1 char.
### Then line is formatted exactly 6 spaces,
### left justified in field; [space]; underscore for
### subfield code (so can change that); one char; 
### then string of subfield data. (original code:
### "%-6.6s _%1.1s%s")
### changed to at sign for indicator (\@); 
### added tab between tag+indicator+code and subfield data


#changed 4-28-04 in attempt to remove extra spaces between fields
# if $hanger exists, it is first run, and has tag and indicators

			if ($hanger) {
				push( @lines, sprintf( "%-6.6s \@%1.1s\t%s", $hanger, $code, $text ) );
				$hanger = "";
			}

#once $hanger is undef, no need for 6  spaces between subfields
			else {
				push( @lines, sprintf( "%-0.0s\@%1.1s\t%s", $hanger, $code, $text ) ); 
			}
		} # while
	}

	return join( "\t", @lines );

} # as_formatted2()

##########################
##########################
##########################

=head2 recas_formatted()

Prints an entire record in human-readable form, using as_formatted2().
This puts each field on a single line and uses @ (at) as subfield 
delimiter instead of _ (underscore).
Based on MARC::Record::as_formatted().

=cut

sub recas_formatted() {

	use MARC::Record;

	my $self = shift;
	    
	my @lines = ("LDR " . ($self->{_leader} || ""));
	for my $field (@{$self->{_fields}}) {
		push(@lines, $field->as_formatted2());
	}

	return join("\n", @lines);

} # recas_formatted



##########################
##########################
##########################

=head2 skipget()

Returns a raw MARC record string or undef.

=cut

sub skipget {

	use MARC::File;
	my $self = shift;
	$self->{recnum}++;

	my $rec = $self->_next();

	return $rec ? $rec : undef;

}

##########################
##########################
##########################

=head2 updated_record_array()

Note: Creates an array of control numbers (001) from input file.
Use with merge marc script. Call to initialize updated record array variable prior to entering loop.
Prompts for updated record file.
Prints running count of records based on counting_print function. Works only with USMARC input files.

=cut

sub updated_record_array {

	use MARC::File::USMARC;
	my @updatedrecarray;
####################################
# To do: test abstracted input file call ##
####################################
	my $inputfile = shift;
	unless ($inputfile) {
		print ("What is the updated record file?:");
		$inputfile = <>;
		chomp $inputfile;
		#remove double quotes inserted when drag-dropping from Windows
		$inputfile =~ s/^\"(.*)\"$/$1/;
	}
	#initialize $decodedfile as new usmarc file object
	my $decodedfile = MARC::File::USMARC->in( "$inputfile" );
	my $recordno = 0;

	while ( my $record = $decodedfile->next()) { 

		my $controlnumb = $record->field('001')->as_string();

		$updatedrecarray[$recordno] = $controlnumb;
		$recordno++;
		MARC::BBMARC::counting_print ($recordno);

	} #while

	return @updatedrecarray;

} #updated_record_array

##########################
##########################
##########################

=head2 read_controlnos()

Accepts passed filename as arguement.
If nothing is passed, asks for file path/name.
Reads each line of file, and pushes it onto array, @controlnumberarray, which is returned.
Lines in the file should contain only control number.

Since it does not do anything to the line it reads, this subroutine can be used to read lines from a file and store them in an array.

To do: Modify existing scripts to clean control number, replacing spaces with underscores.
Regex-ify control number to be (3 char) - (8 digit) - (space). 

=cut

sub read_controlnos {

	#get passed-in filename
	my $controlinputfile = shift;
	unless ($controlinputfile) {
		print ("Where is the file of control numbers?\n");
		print ("\(enter blank line if none\): ");
		$controlinputfile = <>;
		chomp $controlinputfile;
		#remove double quotes inserted when drag-dropping from Windows
		$controlinputfile =~ s/^\"(.*)\"$/$1/;
	}
	my @controlnumberarray = ();
	#read line from file
	##line should contain only control number
	if ($controlinputfile) {
		open (CONTROLNOFILE, $controlinputfile) or die "Cannot open controlnofile, $!";
		while (my $cnumber = <CONTROLNOFILE>) {
			#get rid of line breaks
			chomp $cnumber;
			push (@controlnumberarray, $cnumber);
		}#while
		close $controlinputfile;
	} #if filename was submitted
	
	return @controlnumberarray;

} # read_controlnos

##########################
##########################
##########################


=head2 getthreedigits()

Looks for three digit input. Returns three digit string.

=cut

sub getthreedigits {

##################################################
### Prompting is done in calling program       ###
### Assures that input is exactly three digits ###
##################################################

	my $threedigits = <>;
	chomp $threedigits;

	#added period as possible digit (4-28-04)

	if ($threedigits =~ /^[\d\.]{3}$/){
			return "$threedigits";
	}
	else { 
		print "Try again\n";
		getthreedigits()
	}

} #sub getthreedigits

##########################
##########################
##########################

=head2 sub getindicators()

Gets 1st and 2nd indicator values.
Parses for legitimate values.
Returns 2 array references:
\@indicators, \@indicatortypes
The first contains the values of the indicators.
The second contains the types of those indicators.
The first element in each is 'empty', so numbering
matches indicator 1 and indicator 2.
Indicator types: 'digit', 'blank', or 'any'.

=head2 Get indicator additional info

 ##################################
 ##################################
 ### Synopsis/Calling procedure ###
 ##################################

 my ($gotindicators, $gotindicatortypes) = getindicators();
 print join ("\n", "indarray", @$gotindicators, "\n");
 print join ("\n", "indtypes", @$gotindicatortypes, "\n");

=cut

######################
### Get indicators ###
######################

sub getindicators {

	my @indicators = [];
	my @indicatortypes=[];
	$indicators[0] = 'empty';
	$indicatortypes[0]= 'empty';
	print ("Enter space for blank, or a single digit, enter \'?\' for any\n");
	print ("Enter indicators: 1st: ");
	$indicators[1]=<>;
	chomp $indicators[1];
	print ("Enter indicators: 2nd: ");
	$indicators[2]=<>;
	chomp $indicators[2];

	for my $i (1..2) {

		if ($indicators[$i] =~ /^\d$/) {
			$indicatortypes[$i]='digit';
		}
		elsif ($indicators[$i]  =~ /^\s$/) {
			$indicatortypes[$i]='blank';
		}
		elsif ($indicators[$i]  =~ /^\?$/) {
			$indicatortypes[$i]='any';
		} 
		else {
			## digit, space, or ? not entered##
			print ("Invalid indicator.\nPlease reenter: ");
			$indicatortypes[$i]='bad';
		}
	} #for
	if ($indicatortypes[1] eq 'bad' || $indicatortypes[2] eq 'bad') {
		print ("You entered bad indicators. Try again\n");
		@indicatortypes = [];
		@indicators =[];
		my ($gotindicators, $gotindicatortypes) = getindicators();
		@indicators = @$gotindicators; 
		@indicatortypes = @$gotindicatortypes;
	}

	return (\@indicators, \@indicatortypes);

} #sub getindicators


=head2 readcodedata()

readcodedata() -- Read Country, Geographic Area Code, Language Data

=head2 DESCRIPTION (readcodedata())

Subroutine for reading data to build an array of country codes, geographic area codes, and language codes, valid and obsolete, for use in validate008 (in MARC::Errorchecks) and 043 validation (in MARC::Lintadditions).

=head2 SYNOPSIS (readcodedata())

 my @dataarray = MARC::BBMARC::readcodedata();
## or 
 #MARC::BBMARC::readcodedata();
 #my @countrycodes = split "\t", $MARC::BBMARC::dataarray[1];
 
 my @countrycodes = split "\t", $dataarray[1];
 my @oldcountrycodes = split "\t", $dataarray[3];
 my @geogareacodes = split "\t", $dataarray[5];
 my @oldgeogareacodes = split "\t", $dataarray[7];
 my @languagecodes = split "\t", $dataarray[9];
 my @oldlanguagecodes = split "\t", $dataarray[11];

=head2 DATA Outline

 Data lines:
 0: __CountryCodes__
 1: countrycodes (tab-delimited)
 2: __ObsoleteCountry__
 3: oldcountrycodes (tab-delimited)
 4: __GeogAreaCodes__
 5: gacodes (tab-delimited)
 6: __ObsoleteGeogAreaCodes__
 7: oldgacodes (tab-delimited)
 8: __LanguageCodes__
 9: languagecodes (tab-delimited)
 10: __LanguageCodes__
 11: oldlanguagecodes (tab-delimited)

=cut


#declare global @dataarray

our @dataarray = ();

sub readcodedata {

	# return @dataarray if it has been filled
	if (@dataarray) {return @dataarray;}
	# otherwise fill @dataarray
	else {
	#get start position so the next call can read the same data again
		my $startdataposition = tell DATA;
		while (my $dataline = <DATA>) {
			chomp $dataline;
			push @dataarray, $dataline;
		}
	#set the pointer back at the starting position
		seek DATA, $startdataposition, 0;
		return @dataarray;
	}
} # readcodedata

##########################
##########################
##########################

=head2 parse008date($field008string)

Subroutine parse008date returns four-digit year, two-digit month, and two-digit day.
It requres an 008 string at least 6 bytes long.


=head2 SYNOPSIS (parse008date($field008string))

 my ($earlyyear, $earlymonth, $earlyday);
 print ("What is the earliest create date desired (008 date, in yymmdd)? ");
 while (my $earlydate = <>) {
 chomp $earlydate;
 my $field008 = $earlydate;
 my $yyyymmdderr = MARC::BBMARC::parse008date($field008);
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

=cut

sub parse008date {

	my $field008 = shift;
	if (length ($field008) < 6) { return "\t\t\t$field008 is too short";}

	my $hasbadchars = "";
	my $dateentered = substr($field008,0,6);
	my $yearentered = substr($dateentered, 0, 2);
	#validate year portion--change dates to reflect local implementation of code 
	#(and for future use--after 2006)
	#year created less than 06 considered 200x
	if ($yearentered <= 6) {$yearentered += 2000;}
	#year created between 80 and 99 considered 19xx
	elsif ((80 <= $yearentered) && ($yearentered <= 99)) {$yearentered += 1900;}
	else {$hasbadchars .= "Year entered is after 2006 or before 1980\t";}

	#validate month portion
	my $monthentered = substr($dateentered, 2, 2);
	if (($monthentered < 1) || ($monthentered > 12)) {$hasbadchars .= "Month entered is greater than 12 or is 00\t";}

	#validate day portion
	my $dayentered = substr($dateentered, 4, 2);

	if (($monthentered =~ /^01$|^03$|^05$|^07$|^08$|^10$|^12$/) && (($dayentered < 1) || ($dayentered > 31))) {$hasbadchars .= "Day entered is greater than 31 or is 00\t";}
	elsif (($monthentered =~ /^04$|^06$|^09$|^11$/) && (($dayentered < 1) || ($dayentered > 30))) {$hasbadchars .= "Day entered is greater than 30 or is 00\t";}
	elsif (($monthentered =~ /^02$/) && (($dayentered < 1) || ($dayentered > 29))) {$hasbadchars .= "Day entered is greater than 29 or is 00\t";}

	return (join "\t", $yearentered, $monthentered, $dayentered, $hasbadchars)

} #parse008date



##########################
##########################
##########################

=head2 counting_print ($modcount)

Prints a running count (when called from a loop) based on MOD_INTERVAL.
Argument is current count
use constant MOD_INTERVAL => ###put number here###;

=cut

######################################
###for counting_print()
use constant MOD_INTERVAL => "1000";
####

sub counting_print {
	my $modcount = shift;
	if ($modcount % MOD_INTERVAL == 0) {
		print "passing $modcount\n";
	} #if
} #counting_print

##########################
##########################
##########################

=head2 startstop_time()

Start stop time is called when a program starts 
or finishes, to see how long it takes to complete.
Returns time in hour:min:second format, 
with seconds<10 being single digit. (to fix later)

=cut

###################################

sub startstop_time {

	my $dayornight;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	if ($hour >12) {$hour-=12; $dayornight="p.m.";}
	elsif ($hour == 12) {$dayornight="p.m.";}
	else {$dayornight="a.m.";}
	if ($min < 10) {$min = "0".$min;}
	if ($sec < 10) {$sec = "0".$sec;}
	return "$hour:$min:$sec $dayornight\n"
}

##########################
##########################
##########################

=head2 updated_record_hash()

Note: Creates an hash of control numbers (001) and associated raw MARC data from input file.
Use with compare records script. Call to initialize updated record array variable prior to entering loop.
Prompts for updated record file if the name (or path) of one is not passed in.
Prints running count of records based on counting_print function. Works only with USMARC input files.

=head1 NOTE WARNING (on updated_record_hash)

This may be very memory intensive as it stores raw MARC for each record in the updated (first) file, with its associated control number.
40000+ records (43815K on disk) take approximately 102,192K+ to read in and then dereference.
YOU HAVE BEEN WARNED!!!

=head2 TO DO (on updated_record_hash)

Reduce memory usage, probably by learning how to tie hash to file instead of storing everything in memory.

=cut

sub updated_record_hash {

	use MARC::Batch;
	my %updatedrechash;

	#retrieve file name if one was passed
	my $inputfile = shift;
	#otherwise get file name
	unless ($inputfile) {
		print ("What is the updated record file?:");
		$inputfile = <>;
		chomp $inputfile;
		#remove double quotes inserted when drag-dropping from Windows
		$inputfile =~ s/^\"(.*)\"$/$1/;
	}

	#initialize $batch as new MARC::Batch object
	my $batch = MARC::Batch->new('USMARC', "$inputfile");
	my $recordno = 0;

	while (my $record = $batch->next()) {

		#get control number for the record
		my $controlnumb = $record->field('001')->as_string();

		#use $controlnumb as hash key to full raw MARC string 
		$updatedrechash{$controlnumb} = $record->as_usmarc();
$recordno++;
		MARC::BBMARC::counting_print ($recordno);

	} #while

###testing ###
	print "$recordno records read\n";
###/testing ###

	return \%updatedrechash;

} #updated_record_hash

##########################
##########################
##########################

=head2 as_array

Add-on method to MARC::Field. Breaks MARC::Field into a flat array of subfield code and subfield data pairs.
Based on example 9 of the MARC::Doc::Tutorial.

head2 Example (as_array)

my $field043 = MARC::Field->new('043', '', '', 'a' => 'n-us---', 'a' => 'e-uk---', 'a' => 'a-th---' );

my $field043_arrayref = $field043->as_array(); 
my @field043_array = @$field043arrayref;

# @field043_array is: ('a', 'n-us---', 'a', 'e-uk---', 'a', 'a-th---')

=head2 TO DO (as_array)

Add ability to optionally pass in regex to find in subfields, returning positions of the matches (in a second array ref).

=cut

sub as_array {

	use MARC::Field;
	my $self = shift;

	my @field_as_array = ();
	my @subfields = $self->subfields();

	# break subfields into code-data array (so the entire field is in one array)
	while (my $subfield = pop(@subfields)) {
		my ($code, $data) = @$subfield;
		unshift (@field_as_array, $code, $data);
	} # while

	return (\@field_as_array)

} # as_array

##########################
##########################
##########################

##########################
##########################
##########################

##########################
##########################
##########################
###End main subroutines###
##########################
##########################
##########################


##########################
##########################
##########################


=head2
 
 ########################
 ### Program template ###
 ########################
 ###########################
 ### Initialize includes ###
 ### and basic needs     ###
 ###########################
 
 ##Time coding to wrap around program to determine how long execution takes:
 
 ##########################
 ## Time coding routines ##
 ## Print start time and ##
 ## set start variable   ##
 ##########################
 
 use Time::HiRes qw(  tv_interval );
 # measure elapsed time 
 # (could also do by subtracting 2 gettimeofday return values)
 my $t0 = [Time::HiRes::time()];
 my $startingtime = MARC::BBMARC::startstop_time();
 # do bunch of stuff here
 #########################
 ### Start main program ##
 #########################
 ############################################
 # Set start time for main calculation loop #
 ############################################
 my $t1 = [Time::HiRes::time()];
 my $runningrecordcount=0;
 #####################################
 ## Place the following within loop ##
 #####################################
 $runningrecordcount++;
 MARC::BBMARC::counting_print ($runningrecordcount);
 ##########################
 ### Main program done.  ##
 ### Report elapsed time.##
 ##########################
 
 my $elapsed = tv_interval ($t0);
 my $calcelapsed = tv_interval ($t1);
 print sprintf ("%.4f %s\n", "$elapsed", "seconds from execution\n");
 print sprintf ("%.4f %s\n", "$calcelapsed", "seconds to calculate\n");
 my $endingtime = MARC::BBMARC::startstop_time();
 print "Started at $startingtime\nEnded at $endingtime";
 
 print "\n\nPress Enter to quit";
 <>;
 #####################
 ### END OF PROGRAM ##
 #####################
 
=cut

1;

=head1 SEE ALSO

MARC::Record -- Required for this module to work.

MARC::Lintadditions -- Extension of MARC::Lint (in the MARC::Record distribution) for checks involving individual tag checking.

MARC::Errorchecks -- Extension of MARC::Lint (in the MARC::Record distribution) for checks involving cross-field checking.

MARC pages at the Library of Congress (http://www.loc.gov/marc)

=head1 CHANGES/HISTORY

Version 1.08: Updated Oct 31, 2004. Released Dec. 5, 2004.

 -New method, as_array, an add-on to MARC::Field which breaks down a MARC::Field object into a flat array, returns a ref to that array.
 -Misc. cleanup.

Version 1.07: Updated Aug. 30-Oct. 16, 2004. Released Oct. 17, 2004.

 -Moved subroutine getcontrolstocknos() to MARC::QBIerrorchecks
 -Moved validate007() to Lintadditions.pm
 -Moved validate008() and related subs to Errorchecks.pm
 --(Left readcodedata() in BBMARC, but it is now duplicated in Errorchecks.pm, along with a modified version in Lintadditions.pm).
 --Also left parse008date, which may have uses outside of error checking.
 -Updated read_controlnos([$filename]) with minor changes. 
 --This subroutine could be rewritten in a more general way, since it simply reads all lines from a file into an array and returns that array.
 
Version 1.06: Updated Aug. 10-22, 2004. Released Aug. 22, 2004.

 -Implemented VERSION (uncommented)
 -Added subroutine getcontrolstocknos()
 -General readability cleanup (added tabs)
 -Bug fix in C<validate008> for date2 check
 
Version 1.05: Updated July 3-17, 2004. Released July 18, 2004

 -Cleaned some documentation
 -Added global variable in hopes of improving efficiency of language/GAC/country code validation
 -Modified C<validate008> and/or C<readcodedata()> to use the new global variable.
 -Moved C<readcodedata()> and C<parse008date> above C<validate008>

Version 1.04: Updated June 16, 2004, released June 20, 2004

 -Updated as_formatted2() to work with MARC::Record 1.38 (is_control_field() instead of is_control_tag()
 -Fixed bug in validate008 for visual materials running time (hypen was not escaped, so it was being interpreted as a range indicator).
 -Added parse008date($) to allow user to enter yymmdd and get yyyy\tmm\tdd\t$error string back (for other uses).
 -Added DATA containing codes from the MARC lists for Countries, Geographic Areas, and Languages, to 2003. Each code set is separated by tabs, and Obsolete codes are given following each set of valid codes, in the same format.
 -Added readcodedata() subroutine for reading in the data and returning the data in an array for use by validation code, such as in validate008()
 -Modified validate008 subroutine to use the DATA to validate language and country codes.

Version 1.03: Updated June 10, not released.

 -Contained many of the changes in 1.04, but 1.04 contains the update to validate008, so I wanted a new version.

Version 1.02: Updated May 27, 2004, released May 31, 2004

 -added updated_record_hash() (not yet tested, highly memory intensive)
 -cleaned some documentation

Version 1.01: Updated Apr. 28, 2004, released May 1, 2004

 -Added validate008()
 -Changed as_formatted2() in attempt to remove extra spaces between subfields
 -Changed getthreedigits() to allow wildcards (.)

Version 1 (original version, lacked version designation): First release, Jan. 5, 2004

=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this module is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2003-2004

 ##methodchecking code:
 ### put this in scripts if adding it to BBMARC fails:
 # else {
 # *MARC::File::skipget = *MARC::BBMARC::skipget;
 # };

 ###########################################
 ### For Windows/DOS, end programs with: ###
 #print "Press Enter to continue"; #########
 #<>; ######################################
 ############################################


=cut


1;

__DATA__
__CountryCodes__
af 	alu	aku	aa 	abc	ae 	as 	an 	ao 	am 	ay 	aq 	ag 	azu	aru	ai 	aw 	at 	au 	aj 	bf 	ba 	bg 	bb 	bw 	be 	bh 	dm 	bm 	bt 	bo 	bn 	bs 	bv 	bl 	bcc	bi 	vb 	bx 	bu 	uv 	br 	bd 	cau	cb 	cm 	xxc	cv 	cj 	cx 	cd 	cl 	cc 	ch 	xa 	xb 	ck 	cou	cq 	cf 	cg 	ctu	cw 	cr 	ci 	cu 	cy 	xr 	iv 	deu	dk 	dcu	ft 	dq 	dr 	em 	ec 	ua 	es 	enk	eg 	ea 	er 	et 	fk 	fa 	fj 	fi 	flu	fr 	fg 	fp 	go 	gm 	gz 	gau	gs 	gw 	gh 	gi 	gr 	gl 	gd 	gp 	gu 	gt 	gv 	pg 	gy 	ht 	hiu	hm 	ho 	hu 	ic 	idu	ilu	ii 	inu	io 	iau	ir 	iq 	iy 	ie 	is 	it 	jm 	ja 	ji 	jo 	ksu	kz 	kyu	ke 	gb 	kn 	ko 	ku 	kg 	ls 	lv 	le 	lo 	lb 	ly 	lh 	li 	lau	lu 	xn 	mg 	meu	mw 	my 	xc 	ml 	mm 	mbc	xe 	mq 	mdu	mau	mu 	mf 	ot 	mx 	miu	fm 	xf 	mnu	msu	mou	mv 	mc 	mp 	mtu	mj 	mr 	mz 	sx 	nu 	nbu	np 	ne 	na 	nvu	nkc	nl 	nhu	nju	nmu	nyu	nz 	nfc	nq 	ng 	nr 	xh 	xx 	nx 	ncu	ndu	nik	nw 	ntc	no 	nsc	nuc	ohu	oku	mk 	onc	oru	pk 	pw 	pn 	pp 	pf 	py 	pau	pe 	ph 	pc 	pl 	po 	pic	pr 	qa 	quc	riu	rm 	ru 	rw 	re 	xj 	xd 	xk 	xl 	xm 	ws 	sm 	sf 	snc	su 	stk	sg 	yu 	se 	sl 	si 	xo 	xv 	bp 	so 	sa 	scu	sdu	xs 	sp 	sh 	xp 	ce 	sj 	sr 	sq 	sw 	sz 	sy 	ta 	tz 	tnu	fs 	txu	th 	tg 	tl 	to 	tr 	ti 	tu 	tk 	tc 	tv 	ug 	un 	ts 	xxk	uik	xxu	uc 	up 	uy 	utu	uz 	nn 	vp 	vc 	ve 	vtu	vm 	vi 	vau	wk 	wlk	wf 	wau	wj 	wvu	ss 	wiu	wyu	ye 	ykc	za 	rh 
__ObsoleteCountry__
ai 	air	ac 	ajr	bwr	cn 	cz 	cp 	ln 	cs 	err	gsr	ge 	gn 	hk 	iw 	iu 	jn 	kzr	kgr	lvr	lir	mh 	mvr	nm 	pt 	rur	ry 	xi 	sk 	xxr	sb 	sv 	tar	tt 	tkr	unr	uk 	ui 	us 	uzr	vn 	vs 	wb 	ys 
__GeogAreaCodes__
a-af---	f------	fc-----	fe-----	fq-----	ff-----	fh-----	fs-----	fb-----	fw-----	n-us-al	n-us-ak	e-aa---	n-cn-ab	f-ae---	ea-----	sa-----	poas---	aa-----	sn-----	e-an---	f-ao---	nwxa---	a-cc-an	t------	nwaq---	nwla---	n-usa--	ma-----	ar-----	au-----	r------	s-ag---	n-us-az	n-us-ar	a-ai---	nwaw---	lsai---	u-ac---	a------	ac-----	as-----	l------	fa-----	u------	u-at---	u-at-ac	e-au---	a-aj---	lnaz---	nwbf---	a-ba---	ed-----	eb-----	a-bg---	nwbb---	a-cc-pe	e-bw---	e-be---	ncbh---	el-----	ab-----	f-dm---	lnbm---	a-bt---	mb-----	a-ccp--	s-bo---	nwbn---	a-bn---	e-bn---	f-bs---	lsbv---	s-bl---	n-cn-bc	i-bi---	nwvb---	a-bx---	e-bu---	f-uv---	a-br---	f-bd---	n-us-ca	a-cb---	f-cm---	n-cn---	nccz---	lnca---	lncv---	cc-----	poci---	ak-----	e-urk--	e-urr--	nwcj---	f-cx---	nc-----	e-urc--	f-cd---	s-cl---	a-cc---	a-cc-cq	i-xa---	i-xb---	q------	s-ck---	n-us-co	b------	i-cq---	f-cf---	f-cg---	fg-----	n-us-ct	pocw---	u-cs---	nccr---	e-ci---	nwcu---	nwco---	a-cy---	e-xr---	e-cs---	f-iv---	eo-----	zd-----	n-us-de	e-dk---	dd-----	d------	f-ft---	nwdq---	nwdr---	x------	n-usr--	ae-----	an-----	a-em---	poea---	xa-----	s-ec---	f-ua---	nces---	e-uk-en	f-eg---	f-ea---	e-er---	f-et---	me-----	e------	ec-----	ee-----	en-----	es-----	ew-----	lsfk---	lnfa---	pofj---	e-fi---	n-us-fl	e-fr---	h------	s-fg---	pofp---	a-cc-fu	f-go---	pogg---	f-gm---	a-cc-ka	awgz---	n-us-ga	a-gs---	e-gx---	e-ge---	e-gw---	f-gh---	e-gi---	e-uk---	e-uk-ui	nl-----	np-----	fr-----	e-gr---	n-gl---	nwgd---	nwgp---	pogu---	a-cc-kn	a-cc-kc	ncgt---	f-gv---	f-pg---	a-cc-kw	s-gy---	a-cc-ha	nwht---	n-us-hi	i-hm---	a-cc-hp	a-cc-he	a-cc-ho	ah-----	nwhi---	ncho---	a-cc-hk	a-cc-hh	n-cnh--	a-cc-hu	e-hu---	e-ic---	n-us-id	n-us-il	a-ii---	i------	n-us-in	ai-----	a-io---	a-cc-im	m------	c------	n-us-ia	a-ir---	a-iq---	e-ie---	a-is---	e-it---	nwjm---	lnjn---	a-ja---	a-cc-ku	a-cc-ki	a-cc-kr	poji---	a-jo---	zju----	n-us-ks	a-kz---	n-us-ky	f-ke---	poki---	pokb---	a-kr---	a-kn---	a-ko---	a-cck--	a-ku---	a-kg---	a-ls---	cl-----	e-lv---	a-le---	nwli---	f-lo---	a-cc-lp	f-lb---	f-ly---	e-lh---	poln---	e-li---	n-us-la	e-lu---	a-cc-mh	e-xn---	f-mg---	lnma---	n-us-me	f-mw---	am-----	a-my---	i-xc---	f-ml---	e-mm---	n-cn-mb	poxd---	n-cnm--	zma----	poxe---	nwmq---	n-us-md	n-us-ma	f-mu---	i-mf---	i-my---	mm-----	ag-----	pome---	zme----	n-mx---	nm-----	n-us-mi	pott---	pomi---	n-usl--	aw-----	n-usc--	poxf---	n-us-mn	n-us-ms	n-usm--	n-us-mo	n-uss--	e-mv---	e-mc---	a-mp---	n-us-mt	nwmj---	zmo----	f-mr---	f-mz---	f-sx---	ponu---	n-us-nb	a-np---	zne----	e-ne---	nwna---	n-us-nv	n-cn-nk	ponl---	n-usn--	a-nw---	n-us-nh	n-us-nj	n-us-nm	u-at-ne	n-us-ny	u-nz---	n-cn-nf	ncnq---	f-ng---	fi-----	f-nr---	fl-----	a-cc-nn	poxh---	n------	ln-----	n-us-nc	n-us-nd	pn-----	n-use--	xb-----	e-uk-ni	u-at-no	n-cn-nt	e-no---	n-cn-ns	n-cn-nu	po-----	n-us-oh	n-uso--	n-us-ok	a-mk---	n-cn-on	n-us-or	zo-----	p------	a-pk---	popl---	ncpn---	a-pp---	aopf---	s-py---	n-us-pa	ap-----	s-pe---	a-ph---	popc---	zpl----	e-pl---	pops---	e-po---	n-cnp--	n-cn-pi	nwpr---	ep-----	a-qa---	a-cc-ts	u-at-qn	n-cn-qu	mr-----	er-----	n-us-ri	sp-----	nr-----	e-rm---	e-ru---	e-ur---	e-urf--	f-rw---	i-re---	nwsd---	fd-----	nweu---	lsxj---	nwxi---	nwxk---	nwst---	n-xl---	nwxm---	pows---	posh---	e-sm---	f-sf---	n-cn-sn	zsa----	a-su---	ev-----	e-uk-st	f-sg---	i-se---	a-cc-ss	a-cc-sp	a-cc-sm	a-cc-sh	e-urs--	e-ure--	e-urw--	a-cc-sz	f-sl---	a-si---	e-xo---	e-xv---	i-xo---	zs-----	pobp---	f-so---	f-sa---	s------	az-----	ls-----	u-at-sa	n-us-sc	ao-----	n-us-sd	lsxs---	ps-----	xc-----	n-usu--	n-ust--	e-urn--	e-sp---	f-sh---	aoxp---	a-ce---	f-sj---	fn-----	fu-----	zsu----	s-sr---	lnsb---	nwsv---	f-sq---	e-sw---	e-sz---	a-sy---	a-ch---	a-ta---	f-tz---	u-at-tm	n-us-tn	i-fs---	n-us-tx	a-th---	af-----	a-cc-tn	a-cc-ti	at-----	f-tg---	potl---	poto---	nwtr---	lstd---	w------	f-ti---	a-tu---	a-tk---	nwtc---	potv---	f-ug---	e-un---	a-ts---	n-us---	nwuc---	poup---	e-uru--	zur----	s-uy---	n-us-ut	a-uz---	ponn---	e-vc---	s-ve---	zve----	n-us-vt	u-at-vi	a-vt---	nwvi---	n-us-va	e-urp--	fv-----	powk---	e-uk-wl	powf---	n-us-dc	n-us-wa	n-usp--	awba---	nw-----	n-us-wv	u-at-we	xd-----	f-ss---	nwwi---	n-us-wi	n-us-wy	a-ccs--	a-cc-su	a-ccg--	a-ccy--	ay-----	a-ye---	e-yu---	n-cn-yk	a-cc-yu	fz-----	f-za---	a-cc-ch	f-rh---
__ObsoleteGeogAreaCodes__
t-ay---	e-ur-ai	e-ur-aj	nwbc---	e-ur-bw	f-by---	pocp---	e-url--	cr-----	v------	e-ur-er	et-----	e-ur-gs	pogn---	nwga---	nwgs---	a-hk---	ei-----	f-if---	awiy---	awiw---	awiu---	e-ur-kz	e-ur-kg	e-ur-lv	e-ur-li	a-mh---	cm-----	e-ur-mv	n-usw--	a-ok---	a-pt---	e-ur-ru	pory---	nwsb---	posc---	a-sk---	posn---	e-uro--	e-ur-ta	e-ur-tk	e-ur-un	e-ur-uz	a-vn---	a-vs---	nwvr---	e-urv--	a-ys---
__LanguageCodes__
abk	ace	ach	ada	ady	aar	afh	afr	afa	aka	akk	alb	ale	alg	tut	amh	apa	ara	arg	arc	arp	arw	arm	art	asm	ath	aus	map	ava	ave	awa	aym	aze	ast	ban	bat	bal	bam	bai	bad	bnt	bas	bak	baq	btk	bej	bel	bem	ben	ber	bho	bih	bik	bis	bos	bra	bre	bug	bul	bua	bur	cad	car	cat	cau	ceb	cel	cai	chg	cmc	cha	che	chr	chy	chb	chi	chn	chp	cho	chu	chv	cop	cor	cos	cre	mus	crp	cpe	cpf	cpp	crh	scr	cus	cze	dak	dan	dar	day	del	din	div	doi	dgr	dra	dua	dut	dum	dyu	dzo	bin	efi	egy	eka	elx	eng	enm	ang	epo	est	gez	ewe	ewo	fan	fat	fao	fij	fin	fiu	fon	fre	frm	fro	fry	fur	ful	glg	lug	gay	gba	geo	ger	gmh	goh	gem	gil	gon	gor	got	grb	grc	gre	grn	guj	gwi	gaa	hai	hat	hau	haw	heb	her	hil	him	hin	hmo	hit	hmn	hun	hup	iba	ice	ido	ibo	ijo	ilo	smn	inc	ine	ind	inh	ina	ile	iku	ipk	ira	gle	mga	sga	iro	ita	jpn	jav	jrb	jpr	kbd	kab	kac	xal	kal	kam	kan	kau	kaa	kar	kas	kaw	kaz	kha	khm	khi	kho	kik	kmb	kin	kom	kon	kok	kor	kpe	kro	kua	kum	kur	kru	kos	kut	kir	lad	lah	lam	lao	lat	lav	ltz	lez	lim	lin	lit	nds	loz	lub	lua	lui	smj	lun	luo	lus	mac	mad	mag	mai	mak	mlg	may	mal	mlt	mnc	mdr	man	mni	mno	glv	mao	arn	mar	chm	mah	mwr	mas	myn	men	mic	min	mis	moh	mol	mkh	lol	mon	mos	mul	mun	nah	nau	nav	nbl	nde	ndo	nap	nep	new	nia	nic	ssa	niu	nog	nai	sme	nso	nor	nob	nno	nub	nym	nya	nyn	nyo	nzi	oci	oji	non	peo	ori	orm	osa	oss	oto	pal	pau	pli	pam	pag	pan	pap	paa	per	phi	phn	pol	pon	por	pra	pro	pus	que	roh	raj	rap	rar	roa	rom	rum	run	rus	sal	sam	smi	smo	sad	sag	san	sat	srd	sas	sco	gla	sel	sem	scc	srr	shn	sna	iii	sid	sgn	bla	snd	sin	sit	sio	sms	den	sla	slo	slv	sog	som	son	snk	wen	sot	sai	sma	spa	suk	sux	sun	sus	swa	ssw	swe	syr	tgl	tah	tai	tgk	tmh	tam	tat	tel	tem	ter	tet	tha	tib	tir	tig	tiv	tli	tpi	tkl	tog	ton	chk	tsi	tso	tsn	tum	tup	tur	ota	tuk	tvl	tyv	twi	udm	uga	uig	ukr	umb	und	urd	uzb	vai	ven	vie	vol	vot	wak	wal	wln	war	was	wel	wol	xho	sah	yao	yap	yid	yor	ypk	znd	zap	zen	zha	zul	zun
__ObsoleteLanguageCodes__
ajm	esk	esp	eth	far	fri	gag	gua	int	iri	cam	kus	mla	max	lan	gal	lap	sao	gae	sho	snh	sso	swz	tag	taj	tar	tru	tsw
__END__