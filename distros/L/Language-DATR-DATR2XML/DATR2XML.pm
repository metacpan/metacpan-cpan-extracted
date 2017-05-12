package Language::DATR::DATR2XML;
require 5.005_62;
use strict;
use warnings;

# Author:		Lee Goddard <lgoddard@cpan.org>
# Copyright:	Copyright (C) Lee Goddard; GNU GPL: please see end of file.
# Filename:		DATR2XML.pm

our $VERSION	= "0.901";			# Updated dist
our $MOD_NAME	= "DATR2XML.pm ";	# Name of this module


=head1 NAME

DATR2XML.pm - manipulate DATR .dtr, XML, HTML, XML

=head1 SYNOPSIS

	#! perl -w
	use DATR2XML;

	undef $DATR2XML::includeNodePath;
	$datr -> set_stylesheet('D:/DATR/XSLT/datr.xsl');

	$datr_eg1 = new DATR2XML('D:\DATR\perl\eg.dtr');
	$datr_eg2 = new DATR2XML('D:/DATR/perl/eg.dtr', "on");
	$datr_eg3 = new DATR2XML('http://somewhere/doc.dtr', "verbose");

	viewAll $datr_eg1;
	$datr_eg2 -> viewHeader;

	$datr_eg3 -> printHeader;
	printOpening $datr_eg3;
	printNodes $datr_eg3;
	printClosing $datr_eg3;

	printAll $datr_eg3;

	save $datr_eg3;

	DATR2XML::convert('D:\DATR\XSLT\eg_opening.dtr');


=head1 DESCRIPTION

This module parses into a Perl struct a DATR C<.dtr>-formatted
file, as defined in Gerald Gazdar's I<'DATR By Example'> published
on the DATR web-pages at the University of Sussex < http://www.sussex.ac.uk/ >.

Particular respect was paid to I<datanode31.html>, though I
confess the formal definitions found elsewhere on the site
made no sense to me.

=head1 LOGGING

Process logging may be set to "off", "on" or "true", and "verbose".

=head1 REQUIRED MODULES

If internet access is required, the following modules must
be installed and on the B<@INC> path:

	LWP::UserAgent
	HTTP::Request

If no internet access is required, these modules will not be called.


=head1 DIAGNOSTICS

The usual warnings if it can't read or write.

=head1 EXPORTS

The module exports nothing to the calling namespace.

=head1 CAVEATS

The module does not fully support The DATR Standard Library RFC, Version 2.20.
Specifically, it does not support the use of the proposed I<path cut> operator as
a full-stop within a path: all full stops are taken to signify the end of a clause.

=head1 TO DO

	* Support The DATR Standard Library RFC, Version 2.20
	* Change mechanism of _parseOpeningClosing to allow
	  line-spanning of contents.
	* Support interpoloation of directives within body
	  as specified by the style sheet
	* Fully support comment printing as specified by DATR XML DTD.
	  Currently lumps all comments together.



=head1 GLOBAL VARIABLES

These variables can adjust the output of the DTR parser:
when they are undefined (using C<DATR2XML::$var = undef>) they
prevent the DTR parser from outputing any element which
has a default value, as defined in the DATR DTD; when they
are defined with any value, they force XML output in full.

=item $printComments

Set with any value to print comments, C<undef> not to.

=cut

our $printComments = 1;

=item $includeNodePath

The DTD provides the default path as a null path, but this can
adjusted by setting C<$includeSentenceType> to 1.  This can
be reset by calling C<undef> upon the variable.
See also I<include_sentence_type>.

=cut

our $includeNodePath 		= 1;       # Where decimal 1 is true, and undef is false

=item $includeSentenceType

The DATR DTD provides the default type  as C<==>,
and this can be left if this variable is set, which is
its defualt state.  See also I<include_sentence_type>.

=cut

our $includeSentenceType 	= 1;		# Again, where dec 1 is true, undef is false
our $log 					= 1;		# Ditto; minimal logging by default - see Logging

=item $location_xsl

The path to the required XSLT stylesheet.
The default is C<http://www.leegoddard.com/DATR/XSLT/datr.xsl>.
See also the method and procedure I<set_stylesheet>.

=cut

our $location_xsl = 'd:/DATR/XSLT/datr.xsl';

=item $location_dtd

The SYSTEM location of (that is, the path to) the DATR DTD.
The default is C<http://www.leegoddard.com/DATR/DTD/DATR1.0.dtd>.
See also the method and procedure I<set_dtd>.

=cut

our $location_dtd = 'http://www.leegoddard.com/DATR/DTD/DATR1.0.dtd';

=item $datr_root

This is literally the root element as printed, and may contain
a references, such as to XML schema.

	Eg:
	$datr_root = '<DATR xmlns="x-schema:http://www.leegoddard.com/DATR/DTD/DATR1.0.xml">';

The defualt is simply the opening of the C<DATR> element.
See also I<set_schema>.

=cut

# $datr_root = '<DATR xmlns="x-schema:http://www.leegoddard.com/DATR/DTD/DATR1.0.xml">';
our $datr_root = '<DATR>';

# System  varialbes

$|		= 1;		# Autoflush so STDOUT/STDERR output in chronological order





=head1 PUBLIC METHODS

=cut

=head2 Constructor (new)

Creates a new DATR2XML object from file, URI or DATR C<.dtr> source.

Accepts:	DATR source as scalar, array, scalar/array pointer, or path to a DATR file.
		If source is scalar or pointer to a scalar, is assumed to be just a list
		of node definitions, of BODY slot.

		Optionally accepts a second argument to set logging: see the manual entry
		for the logging method for details.

Returns:	reference to object.

Object Structure: a hash with the following fields:

	LOCATION - the name of the file, if any

	HEADER   - the file header (as defined in datrnode44.html#fileheader)

	OPENING  - opening declarations/directives as defined in datrnode45.html#openingdeclarations

	BODY     - node defintions,itself an array of hashes of the format defined in _parseNodes

	CLOSING  - clsoing declarations/directives as defined in datrnode47.html#closingdeclarations

=cut

sub new{
	my $pkg = shift;	# Get the package/class reference
	my $self = {};		# Define this object
	bless $self,$pkg;	# explicitly within this package/class

	# Reset logging if passed: do now so errors appear after titles
	if ($_[1]){	logging($_[1])	}

	# Dereference constructor arguments if necessary
	if (ref $_[0] =~ /(HASH)/) {			# Is a reference to a HASH
		die "\nInvalid attempt to construct datr object using a hash reference:\nplease supply a literal scalar or reference to such, an array or a .dtr filename.";
	}
	elsif (ref $_[0] eq "SCALAR") {		# Is a reference to a scaler
		@_ = ${$_[0]};						# so dereference
	}
	elsif (ref $_[0] =~ /(ARRAY)/) {		# Is a reference to an array{
		@_ = @$_[0];						# so coerce dereferenced array to string
	}										# Otherwise assume an string or array passed

	# Create object 'slots' / struct
	$self -> {OPENING}	= [];
	$self -> {HEADER}	= {};
	$self -> {BODY}		= [];
	$self -> {CLOSING}	= [];

	# Load from internet if necessary
	if ($_[0] =~ m|^http://|i) {			# Is a URI, possibly ending .dtr
		$self->{LOCATION} = $_[0];
		@_ = $self -> _loadURI;
	}
	# Load from file system if necessary
	elsif ($_[0] =~ /.*\.dtr/i) {			# Is a filepath
		$self->{LOCATION} = $_[0];
		@_ = $self -> _loadFile;
	}

	$self -> _parseHeader	(\@_);			# Set self contents
	$self -> _parseOpening	(\@_);			#  ""        ""
	$self -> _parseNodes	(\@_);			#  ""        ""
	$self -> _parseClosing	(\@_);			#  ""        ""

	return $self;
}	# End sub new






=head2 include_sentence_type

Sets or resets the C<type> attribute of
C<EQUATION> elements.

Calling with an argument value of C<1> includes the
C<type> attribute (I<default>); calling with C<0> forces
the C<type> attribute to be omitted.

=cut

sub include_sentence_type{
	shift if ref $_[0] eq "REF"; # remove (object) ref if called as method
	if ($_[0]==1){
		$includeSentenceType = 1;
		print "Shall now print the type attribute os EQUATION sentence type." if $log;
	}
	elsif ($_[0]==0) {
		undef $includeSentenceType;
		print "Shall not print the type attribute of EQUATION elements." if $log;
	}
	else { die
"You attempted to set the EQUATION element's
type attribute, but did not supply a correct
value. Please use an argument of 1 to include,
0 to ommit.";
	}
}



=head2 print_comments

Call without a value to stop comment printing;
call with a value to restart comment printing.
Default is to print comments.

=cut

sub print_comments{
	shift if ref $_[0] eq "REF"; # Remove (object) reference if called as method
	if ($_[0] eq ("" or undef)){
		undef $printComments;
		print "Comment printing turned off.\n" if $log; # Notify user if logging
	}
	else {
		$printComments= $_[0];
		print "Comment printing turned on.\n" if $log; # Notify user if logging
	}
}




=head2 set_stylesheet

Sets the path to the required XSLT stylesheet.
See also I<location_xsl> in the section I<Global Variables>.

=cut

sub set_stylesheet{
	shift if ref $_[0] eq "REF"; # Remove (object) reference if called as method
	if ($_[0] eq ("" or undef)){ die
'You tried to set the stylesheet location without specifiying a value.
	http://www.leegoddard.com/DATR/XSLT/datr.xsl;
	http://www.leegoddard.com/DATR/XSLT/datrHTML.xsl;
	http://www.leegoddard.com/DATR/XSLT/prolog.xsl;
';
	}
	$location_xsl = $_[0];
	print "Set stylesheet location to$_[0].\n" if $log; # Notify user if logging
}




=head2 set_dtd

Sets the location of the DTD as used in the DOCTYPE SYSTEM declaration.
See also I<location_dtd> in the section I<Global Variables>.

=cut

sub set_dtd{
	shift if ref $_[0] eq "REF"; 	# Remove (object) reference if called as method
	if ($_[0] eq ("" or undef)){
		die
"You tried to set the location of the DATR DTD without specifiying a value.
The default is http://www.leegoddard.com/DATR/DTD/DATR1.0.dtd\n";
	}
	$location_dtd = $_[0];
	print "Set XML DTD location to $_[0].\n" if $log;	# Notify user if logging
}

=cut


=head2 set_schema

Sets the location of the XML Schema as used in the root element.
If called with no arguemnt value, removes all references to an
XML Schema, setting C<$datr_root> to the opening of the DATR
root tag without attributes.

Calling with a value of C<1> sets the Schema to the author's,
located at C<http://www.leegoddard.com/DATR/DTD/DATR1.0.xml>.
See also I<datr_root> in the section I<Global Variables>.

=cut

sub set_schema{
	shift if ref $_[0] eq "REF"; 	# Remove (object) reference if called as method
	if ($_[0] eq ("" or undef)){
		$datr_root = "<DATR>";
		print "Removed reference to an XML Schema" if $log;		# Notify user if logging
	}
	elsif ($_[0] == 1){
		$datr_root = "http://www.leegoddard.com/DATR/DTD/DATR1.0.xml";
		print "Set XML Schema location to $_[0].\n" if $log;	# Notify user if logging
	}
	else {
		$datr_root = $_[0];
		print "Set XML Schema location to $_[0].\n" if $log;	# Notify user if logging
	}
	print "Set XML Schema location to $_[0].\n" if $log;	# Notify user if logging
}

=cut





=head2 logging

Turns logging off or on, verbose or minimal.

	Accepts: 	"true|on|minimal" or "verbose" or "off|none|silent"
	Returns:	None

=cut

sub logging{
	shift if ref $_[0] eq "REF"; # Remove object reference if passed
	if ($_[0] eq "on" or $_[0] eq "true" or $_[0] eq "minimal"){
		$log = "true";
	}
	elsif ($_[0] eq "verbose") {
		$log = "verbose";
	}
	# Undefine the variable for 'silent' mode with no output
	else { 	undef $log }
	# Output program ID if logging of any kind
	if ($log) {
		print "This is $MOD_NAME called by ";
		$0 =~ /.*(\/|\\)+?(.*)$/;
		print "$2.\nCopyright (C) Lee Goddard 2000. All Rights Reserved.\n",
	}
	# Output logging state after program ID.
	if ($log eq "true"){ print "Minimal logging activated.\n";}
	elsif ($log eq "verbose") { print "Verbose logging activated.\n"; }
}







=head2 viewAll

Provides a rough printout of all records

	Accepts:	object ref;
	Returns:	none

=cut

sub viewAll {
	my $self = shift;
	my $t = localtime;
	print "\n==================================\n",
		  "||     DATR DTR DUMP        ||\n",
		  "==================================\n",
		  "Document location:\n\t";
	if ($self->{LOCATION} ne ""){ print $self->{LOCATION} }
	else { print "a direct call." }
	print "\nConversion time: $t.\n",
		  "==================================\n";
	$self -> viewHeader;
	print "==================================\n";
	$self -> viewOpening;
	print "==================================\n";
	$self -> viewNodes;
	print "==================================\n";
	$self -> viewClosing;
	print "=============================[END]\n\n";
}






=head2 viewHeader

Provides a rough printout of all nodes

	Accepts:	object ref;
	Returns:	none

=cut

sub viewHeader {
	my $self = shift;
	print "File header:\n";
	foreach (keys %{ $self->{HEADER} }){
		print "\t$_ : ",
		$self->{HEADER}->{$_},
		"\n";
	}
	print "End of file header.\n";
}








=head2 viewOpening

Provides a rough view of the opening directives/definitions

	Accepts:	object ref;
	Returns:	none

=cut

sub viewOpening {
	my $self = shift;
	if (@{$self->{OPENING}}){
		print "Opening declarations and directives:\n";
		foreach (@{$self->{OPENING}}){ print "\t$_\n"; }
		print "End of opening.\n";
	}
	else {print "Neither opening declarations nor directives present.\n";}
}







=head2 viewClosing

Provides a rough view of the closing directives/definitions

	Accepts:	object ref;
	Returns:	none

=cut

sub viewClosing {
	my $self = shift;
	if (@{$self->{CLOSING}}){
		print "Closing declarations and directives:\n";
		foreach (@{$self->{CLOSING}}){ print "\t$_\n" }
		print "End of closing.\n";
	}
	else {print "Neither closing declaration nor directives present.\n";}
}






=head2 viewNodes

Provides a rough printout of all nodes

	Accepts:	object ref;
	Returns:	none

=cut

sub viewNodes {
	my $self = shift;
	foreach my $hash (@{$self->{BODY}}){
		foreach ( keys %$hash){ print "$_\t$$hash{$_}\n";}
		print "----------------------------------\n";
	}
}


#--  X M L   O U T P U T   R O U T I N E S  ---------------------------------------------




=head2 save

Saves to local filesystem an XML printout of all records

	Accepts:	object ref;
			optional file path to save at
			or, for internal use, typeglob for PERL filehandle.
	Returns:	none
	Notes:		simply calls printAll, passing filehandle if necessary.

=cut

sub save {
	my $self = shift;
	$self -> printAll(shift);
} # End sub printAll






=head2 convert

Convert one or more  DATR files to XML.

	Accepts:	I<Either>:
			a filepath with an extension,
			optionally with an additional destination filepath or directory,
			I<or,>
			for batch operation, a directory location.
	Returns:	nothing, will die on errors
	Notes:		Does not accept URLs and does not process sub-directories.
			Minimizes logging during operation.

=cut

sub convert{
	my @sourceFiles	= shift;	# Re-fill if batch
	my $destination	= "";		# Destination path for converted data
	my $sourceDir	= "";		# Dir of source, possibly first arg
	my $localLog		= "";	# Stores state of globabl $log for duration

	$destination = shift if $_[0];		 		 # Take a second argument if present

	if ($sourceFiles[0] =~ /^http:\/\//){ 		# if URL passed as first argument
		die "\nDATR2XML::convert does not accept URLs.\n";	# quit the script
	}

	if ($log) {					# If package's logging has been set,
		$localLog = $log;		# store for restoration on exiting the sub
		$log = "";				# and replace it to minimize output on this routine
	}

	# If first argument is a directory path, get batch of filenames:
	if (-d $sourceFiles[0]){
		$sourceDir = $sourceFiles[0];			# Store for append later
		opendir DIR, $sourceDir;
		@sourceFiles = grep /\.dtr$/, readdir DIR;
		print "Batch processing...." if $localLog;
		print "\n" if $localLog;
	}

	foreach my $sourcePath (@sourceFiles) {		# Process all
		if ($sourceDir ne ""){ $sourcePath = $sourceDir."/".$sourcePath }
		# Warn if loading a file with an xml extension: I do it all the time in error....
		if ($sourcePath=~/\.xml$/i){
			warn "** Loading a file with an XML extension:\n   $sourcePath.\n";
		}

		my $datr = new DATR2XML($sourcePath);	# Create a DATR-file object, no logging

		# If the destination wasn't specified as the second argument
		if ($destination eq ""){
			# Destination filepath is source filepath stripped of extension
			$sourcePath =~ /(.*)\.(?=[\w()-]*)/;
			$destination = $& . "xml";			# and with xml extension added
		}
		$datr -> printAll($destination);		# Convert and save  to destination path
		print "Saved file $destination\n" if $localLog;
		$destination = undef;					# Nullify for possible next pass
		$datr = undef;
	}
	print "...done.\n" if $localLog;

	# Restore package's loggging
	$log = $localLog;
}	# End0-sub convert







=head2 printAll

Provides an XML printout of all records

	Accepts:	object ref;
			optional file path to save at.
			or, for internal use, typeglob for PERL filehandle
	Returns:	none

=cut

sub printAll {
	my $self = shift;				# Collect object reference
	# Set up the output stream, file or STDOUT
	my $FH 	 = _setupOutput(shift);
	# Print XML declaration and open DATR - may add encoding="ISO-8859-1" or such here.
	print $FH <<"__STOP_PRINTING__";
<?xml version="1.0" standalone="no"?>
<!DOCTYPE DATR SYSTEM "$location_dtd">
<?xml-stylesheet type="text/xsl" href="$location_xsl" ?>

$datr_root
__STOP_PRINTING__
	$self -> printHeader ($FH);		print $FH "\n\n";
	$self -> printOpening ($FH);	print $FH "\n\n";
	$self -> printNodes ($FH);		print $FH "\n\n";
	$self -> printClosing ($FH);	print $FH "\n\n</DATR>\n\n";
	close $FH;
	print "Done.\n" if $log;

} # End sub printAll








=head2 printHeader

	Provides an rough printout of all nodes

	Accepts:	object ref;
			optional file path
			or, for internal use, typeglob for PERL filehandle
	Returns:	none

=cut

sub printHeader {
	my $self = shift;
	my $FH	 = shift || *STDOUT;					# Output FileHandle to arg2 or standard
	# The time, for insertion into the file
	my $t = localtime;
	# Start with this script's META details
	print $FH "<HEADER>\n",
		"\t<META name='Generator' content='$MOD_NAME (C) Lee Goddard 2000, code\@leegoddard.com'/>\n",
		"\t<META name='Generator:Time' content='$t'/>\n";
	print $FH "\t<META name='Generator:Source Path' content='";
	if ($self->{LOCATION} ne ""){ print $FH $self->{LOCATION}; }
	else { print $FH "direct"; }
	print $FH "'/>\n";
	# Continue with DATR file's details
	foreach (keys %{$self->{HEADER}}){
		print $FH "\t<META name='",uc $_,"' content='$self->{HEADER}->{$_}'/>\n";
	}
	print $FH "</HEADER>\n";
}




=head2 printOpening; printClosing

Provides an XML printout of the opening/closing directives/definitions block element.
Without passing a filepath or typeglob for filehandle, outputs to STDOUT.
Just a wrapper for _printOpeningClosing.

	Accepts:	object ref;
			optionally a file path
			or, for internal use, typeglob for PERL filehandle
	Returns:	none

=cut

sub printOpening {
	my $self = shift;				# Collect object reference
	my $FH	 = shift || *STDOUT;	# Output FileHandle to arg2 or standard
	$self -> _printOpeningClosing($FH,"OPENING");
}

sub printClosing {
	my $self = shift;				# Collect object reference
	my $FH	 = shift || *STDOUT;	# Output FileHandle to arg2 or standard
	$self -> _printOpeningClosing($FH,"CLOSING");
}





=head2 printNodes

Provides an XML printout of all nodes.
Basically writes the EQUATION element and calls
C<_parsePath> on each value of the object's C<{BODY}> key.

	Accepts:	object ref
	Returns:	none

=cut

sub printNodes {
	my $self = shift;				# Collect object reference
	my $FH	 = shift || *STDOUT;	# Output FileHandle to arg2 or standard
	my $i = -1;						# Index to comment array
	# See &_parseNodes() for details of comment.
	# Only print comments if flag is set, if they exist as more than whitespace
	if ($printComments and $self->{COMMENT} and $self->{COMMENT}!~/^\s*$/){
		print $FH "<COMMENT>\n";
		print $FH $self->{COMMENT};
		print $FH "\n</COMMENT>\n\n";
	}
	foreach my $sentence (@{$self->{BODY}}){
		# See &_parseNodes() for details of comment.
		# $i++;
		# print "i = $i\n";
		# if ($$sentence{COMMENT}[$i]){
		#	print "commented line $i of ",$#{$$sentence{COMMENT}},"\n";
		#	print $FH "<COMMENT>$$sentence{COMMENT}[$i]</COMMENT>\n";
		# }
		print $FH "<EQUATION node=\"$$sentence{NODE}\" ";
		if ($includeNodePath){ print $FH "path=\"$$sentence{PATH}\" "}
#		if ($includeSentenceType){
#			print $FH "type=\"";
#			if ($node{TYPE} and $node{TYPE} eq "="){ print $FH "EXTEND"}
#			else { print $FH "DEFINE" }
#			print $FH '"';
#		}
		print $FH ">\n", _parsePath( \$$sentence{VALUE},\$$sentence{NODE} );
		print $FH	"\n</EQUATION>\n";
	}
}





###########################################################################################

#


=head1 PRIVATE METHODS

I<All private method subroutine names are prefixed with an underscore.>

=cut



=head2 _loadFile (private method)

Load a dtr file from the local file system.

	Accepts:	object reference
	Returns:	an array of file contents

=cut

sub _loadFile {
	my $self = shift;
	# Check filename present
	if (!$self->{LOCATION}){
		die "\nAttempted to load a file without specifying a filename.\n";
	}
	# Explicitly state if file does not exist
	if (!-e $self->{LOCATION}){
		die "File $self->{LOCATION} does not exist.\n";
	}
	print "Loading $self->{LOCATION}... " if $log;
	open IN,$self->{LOCATION} or die "\nError loading $self->{LOCATION}.\n";
		@_ = <IN>;
	close IN;
	print "okay.\n" if $log;
	return @_;
}







=head2 _loadURI (private method)

Load a dtr document from a URI

	Accepts:	object reference
	Returns:	an array of file contents

=cut

sub _loadURI {
	my $self = shift;
	if (!$self->{LOCATION}){
		die "\nAttempted to load from the net without specifying a URI.\n";
	}
	use LWP::UserAgent;
	use HTTP::Request;
	my  $ua = new LWP::UserAgent;				# Create a new UserAgent
	$ua->agent('Mozilla/25.0 (DATR-Agent');		# Give it a type name
	print "Attempting to access $self->{LOCATION}..." if $log;
	# Format URL request
	my $req = new HTTP::Request('GET', $self->{LOCATION});
	my $res = $ua->request($req);
	if (!$res->is_success()) { die "failed.\n"}
	else { print "okay." if $log }
	return $res->content;						# Return content retrieved
}







=head2 _parseHeader (private method)

Parses a C<.dtr>-format file header into the class record

	Accepts:	object ref;
	Returns:	none
	Struct:		This method fills the hash held in $self->{HEADER}
			with whatever fields the C<.dtr> file header contains that match
			a name/value pair delimited with a colon.

=cut

sub _parseHeader {
	my $self = shift;				# Collect method's object reference
	# Do not de-ref second argument
	print "Parsing header....\n" if $log;
	# Loop file until a line with no comment exists: quick and dirty
	# Could use for/last-if, but this is faster.
	while (@{$_[0]}[0] =~ m/^\s*?%/){
		shift(@{$_[0]}) =~ /		# Match
			\s*						# Maximum number of spaces
			%						# The DATR comment symbol
			\s*						# Maximum number of spaces
			# Group 1 - field name
			([\w\s\.,()-]*?)		# Any number of words, sapces or symbols listed
			:						# before a colon
			\s*						# Maximum number of spaces
			# Group 2 - field value
			([\w\s\.,()-]*?)		# Any number of words, sapces or symbols listed
			\s*						# Maximum number of spaces
			%						# The DATR comment symbol
			\s*?					# Minimum number of spaces
			\n						# A new-line, return or form-feed
		/sgox;						# compile Once
		if ($1 and $2) {
			my $key = uc $1;		# Make hash key uppercase
			my $value = $2;			# $2 will be lost with substitution below
			$key =~ s/\s/_/sg;		# replace whitespace with u/score
			$self->{HEADER}->{$key}= $value;
			print "\t$key:\t$value\n" if $log eq "verbose";
		# Grab any copyright notice and make a hash key
		}
		#elsif ($d[0]=~/(Copyright\s\(C\)|\(C\)\sCopyright)\s*(.*?)[.]+/i) {
		#	print "\tCOPYRIGHT_RESERVED:\t$2\n" if $log eq "verbose";
		#	$self->{HEADER}->{"COPYRIGHT_RESERVED"} = $2;
		#}
	} # WHend
	print "Finished parsing header.\n" if $log;
} # End sub _parseHeader







=head2 _parseOpening (private method)

Extracts opening directives, those occuring B<before> node definitions,
and places them into the self-object's OPENING array.

	Accepts:	object ref, ref to DATR data
	Returns:	none

=cut

sub _parseOpening{
	my $self=shift;					# Collect method's object reference
	# Don't dereference DATR data from 2nd argument
	my $lastMatch;
	print "Extracting opening directives and definitions....\n" if $log;
	LOOP:
	foreach (@{$_[0]}){				# Loop through whole file
		next LOOP if $_ eq "" or /^\s*$/;
		last LOOP if /^\s*\w*\s*:/;	# End if found a node def a line start
		m/							# Match
			^\s*\#\s*				# At start of scalar, whitespace surronding a directive symbol
			(						# And store as GROUP 1
				[\w\s=\$,:"<>-]*	#" any number of characters in this class
			)
			\s*
			'?(\w*\.\w*)*'?			# In group 2 maybe a single-quoted filename
			\s*
			(?!\#)					# Catch directives without full-stop terminator
			\.						# Ending in a comment or linefeed of some kind, inc. DATR
		/ox;						# single compile, ignore whitespace

		if ($1 ne $lastMatch){
			$lastMatch = $1;		# Prevent duplicates/null finds (nonupdated $1)
			if ($2) {$lastMatch .= " $2";}
			push @{$self->{OPENING}}, $lastMatch;	# Store the atomised match
			print "\t$lastMatch\n" if $log eq "verbose";
		}
		# elsif (/^\s*\w*[:<]/) {	# If the line begins with a node-definition
		# 	last LOOP;				# then stop looking in the opening
		# }							# Now in first case: faster, but better?
		elsif (!/^[%\n\r\f]*/) {	# Catch source errors, not comments/blanks
			print "** Ignoring malformed DATR directive in OPENING:  $_\n" if $log;
		}
	}
	print "Finished extracting opening declarations and directives.\n" if $log;
}






=head2 _parseClosing (private method)

Extracts closing directives, those occuring B<before> node definitions

	Accepts:	object ref; reference to array of DATR data
	Returns:	none
	Notes:		reverses @_ then applies same proc as _parseOpening, then reverses output

=cut

sub _parseClosing{
	# This has been a swine to write, because directives such
	# as show can span lines. We now assume that the
	# DATR Stylesheet is implimented: see
	# www.datr.org/datrnode38.html, "Style sheet for DATR dtr files"
	# Specifically, we rely on the RCS Archive ID comment as defined
	# in the stylesheet www.datr.org/datrnode48.html -- at least
	# we rely on a comment line appearing as the last element of a file.

	my $self=shift;					# Collect method's object reference
	# Don't dereference DATR data from 2nd argument
	my $lastMatch;
	print "Extracting closing directives and definitions....\n" if $log;
	LOOP:
	foreach (reverse @{$_[0]}){		# Loop through whole file
		next LOOP if $_ eq "" or /^\s*$/;
		last LOOP if /^\s*\w*\s*:/;	# End if found a node def a line start
		m/							# Match
			^\s*\#\s*				# At start of scalar, whitespace surronding a directive symbol
			(						# And store as GROUP 1
				[\w\s=\$,:"<>-]*	#" any number of characters in this class
			)
			\s*
			('?\w*\.\w*'?)*			# In group 2 maybe a single-quoted filename
			\s*
			(?!\#)					# Catch directives without full-stop terminator
			\.						# Ending in a comment or linefeed of some kind, inc. DATR
		/ox;						# single compile, ignore whitespace

		if ($1 ne $lastMatch){
			$lastMatch = $1;		# Prevent duplicates/null finds (nonupdated $1)
			if ($2) {$lastMatch .= " $2";}
			unshift @{$self->{CLOSING}}, $lastMatch;	# Store the atomised match
			print "\t$lastMatch\n" if $log eq "verbose";
		}
		 elsif (/^\s*\w*[:<]/) {	# If the line begins with a node-definition
		 	last LOOP;				# then stop looking in the opening
		 }							# Now in first case: faster, but better?
		elsif (!/^[%\n\r\f\s]$/) {	# Catch source errors: not comments/blanks
			print "** Ignoring malformed DATR directive in CLOSING: $_\n" if $log;
		}
	}
	print "Finished extracting closing delcarations and directives.\n" if $log;
}	# End-sub _parseClosing







=head2 _parseNodes (private method)

Parse a list of nodes to the class BODY record.

	Accepts:	an obj ref and an reference to an array
			of DATR data
	Returns:	none
	Struct:		This method creates the array of hashes held in $self->{BODY}
			with the following fields:

			NODE	- the name of the current node
			PATH	- the (left-hand) path
			TYPE	- the sentence-type signifier: = or ==
			VALUE	- the (right-hand) value
			COMMENT - an array of comments, index reflecting source line number

=cut

sub _parseNodes {
	my $self = shift;				# Collect method's object reference
	my %node;
	my ($last_line, $last_comment);
	my $i;							# Index to comment array
	print "Parsing nodes....\n" if $log;

	# To support the DATR XML DTD, comments that appear on a line
	# by themselves should be contained in a COMMENT element;
	# blocks of such should be combined in a single COMMENT element.
	# Comments which appear at the end of a line should be included
	# in the comment attribute of the last element  issued.
	# The code below goes part way to this effect, but a rewriting
	# of the parser regex is needed along the lines of
	# an array gained from the matcher: @_ = m/(groups1-5)/
	# with optional groups for the comment at every juncture.
	# There's just not enough time right now.
	# See also &printNodes()

	# From the DATR, separate comments and the data minus line breaks:
	foreach(@{$_[0]}){
		$i++;							  # Increment comment array index
		next if not /%/;				  # Next if no comment: improves speed
		m/^(.*?)%\s*(.*?)$/o;			  # Put DATR in group 1, comments in Group 2
		if ($last_comment ne $2) {        # If group 3 found a NEW comment
			# $node{COMMENT}[$i].="$2 ";  # Add new comment with space for supliment
			$self->{COMMENT}.="$2\n";      # Add new comment with space for supliment
			$last_comment = $2;           # Remember this comment
			if (/^%/){ $_="" }			  # Catch and stop single line comments
		}
        if ($last_line ne $1) {		      # If group 3 found a NEW comment
            $_ = $1;
            $last_line = $1;	  	      # Remember this comment
        }
	}

	# From the DATR, gather node, path, type symbol and path-value.
	$_ = join "",@{$_[0]};
	while (m/					# Match all occurances
		\s*?					# Any number of formatting spaces.
		# GROUP 1 - optional node name group:
		(
			[\w]+?[\w\s]*?		# Begin with a letter, then any number of words or spaces
			(?!<[\w\s]*?>)		# that are not right-angle and
			:					# are before required colon: chop this later (POOR)
		)*?						# The group is optional
		\s*?					# Any number of formatting spaces.
		# GROUP 2 - the left path, may be empty:
		<([\w\s]*?)>			# Optional Words or spaces within required angle brackets
		\s*?					# Any number of formatting spaces.
		# GROUP 3 - relationshiop signifier:
		(={1,2})				# One or two equality signs
		\s*						# Any number of formatting spaces.
		# GROUP 4 - the value, anything at all
		(.*?)
		\s*						# Any number of formatting spaces.
		# TERMINATOR - non-stored group.
		(?=						# Don't match ending
			[.]					# with a point
		|						# or
			(?=					# a path type definition
				<[\w\s]*?>\s*?={1,2}	# as Groups 2 and 3
			)
		)
	/gsxo # Search globably, stating where left off, with extended source formatting
	){
		# Create hash to push to object; only change node name if new node name present
		# Future Expansion: possibly force ucfirst for DATR syntax, depending on switch?
		if ($1) {
			$node{NODE} = $1;
			chop $node{NODE};	# Remove trailing whitespace
		}
		$node{PATH}		= $2;
		$node{TYPE}	= $3;
		# Strip trainling whitespace
		($node{VALUE}=$4) =~ s/\s+$//g;
		# Error messages for malformed DATR
		if ($5) {warn "*** Malformed DATR source: \n\tParse Error (Group 5 showed $5)\n";}
		if ($6) {warn "*** Malformed DATR source: \n\tParse Error (Group 6 showed $6)\n";}
		push @{$self->{BODY}}, {%node};
	} # Whend
	print "Finsished parsing nodes.\n" if $log;
}	# End sub _parseNodes







=head2 _parsePath (private pseudo-method)

Decodes path attributes into an XML structure.

	Accepts:	a string of DATR path (as in $$hash{VALUE});
			optionally a second argument, being the name of a node to
			build-out the sentence (cf. geraldg@cogs.susx.ac.uk, 06/07/00)
	Returns:	a string of XML structure
	Notes:		a bit of a hack, really.

=cut

sub _parsePath{
	my $nodeValue = shift;				# reference to the operand
	$nodeValue = $$nodeValue;			# de-ref
	my $nodeName	 = shift if $_[0];	# name of node if present (as POD above)
	$nodeName = $$nodeValue;			# de-ref
	# Reference ot chars in string, for speed
	my ($next,$last) = "";
	# Stack of currently open elements
	my @open;
	# Buffer to store output during parse passes
	my $out;
	# Character equivelents for first pass substitution
	my $openQuote = "£l£g££11";
	my ($openPath, $closePath) = ("£l£g££12", "£l£g££13");
	my ($openQuotedPath, $closeQuotedPath) = ("£l£g££14", "£l£g££15");
	my ($openNodePath, $closeNodePath) = ("£l£g££16", "£l£g££17");
	my ($openQuotedNodePath, $closeQuotedNodePath) = ("£l£g££18", "£l£g££19");

	# First parse
	for my $i (0 .. length $nodeValue){			# Iterate (through the first argument)
		if ($i>0) {								# Avoid negative indexing on first interation
			$last = substr($nodeValue,$i-1,1);
		}
		else { $last = ""; }

		my $this = substr $nodeValue,$i,1;			# Take the curent character
		if ($i<length $nodeValue){				# Avoid substr out of bounds on final parse
			$next = substr $nodeValue,$i+1,1;
		}
		else { $next = ""; }

		# Cases:

		# query:  full XML element inserted
		if ($this eq "?"){
			$out .= "<QUERY/>";
		}
		# open node-path	N:<0>
		elsif ($this eq "<" and $last eq ":" and $open[$#open] ne $openQuote) {
			# Add code to $out, for final pass substitution
			$out.=$openNodePath;
			push @open, $openNodePath;
		}
		# open quoted node-path	PART 1 -  "N:<0>"
		elsif ($this eq "<" and $last eq ":" and $open[$#open] eq $openQuote) {
			# Add code to $out in place of :<, for final pass substitution
			$out.=$openQuotedNodePath;
			pop @open;	# remove 'openQuote' from stack
			push @open, $openQuotedNodePath;
		}

		# open path			<0>
		elsif ($this eq "<" && $last ne ":" && $last ne '"') {
			if ($nodeName){							# If node name was passed as arg
				$out.= $nodeName.$openNodePath;	# make this a node path
				push @open, $openNodePath;
			}
			else {
				$out.= $openPath;
				push @open, $openPath;
			}
	    }
		# open quoted-path	"<0>"
		elsif ($this eq '"' && $next eq "<") {
			$out.= $openQuotedPath;
			push @open, $openQuotedPath;
		}
		# open quoted node-path	PART 2 - "N:<0>"
		elsif ($this eq '"' and $next=~/\w/) {
			# $out.= $openQuote; # leave for 2nd parse
			push @open, $openQuote;
		}
		# Characters to ignore, as used above
		elsif ($this eq "<"  or $this eq ":") {
			# Already dealt with, so don't add
		}
		# close node-path
		elsif ($this eq ">" && $open[$#open] eq $openNodePath) {
			$out.= $closeNodePath;
			pop @open;
		}
		# close quoted node-path
		elsif ($this eq ">" and $next eq '"' and $open[$#open] eq $openQuotedNodePath) {
			$out.= $closeQuotedNodePath;
			pop @open;
		}
		# close quoted-path	"<0>"
		elsif ($this eq ">" and $next eq '"' and $open[$#open] eq $openQuotedPath) {
			$out.= $closeQuotedPath;
			pop @open;
		}
		# path-closure unless no path is open
		elsif ($this eq ">" && $open[$#open] eq $openPath) {
			$out.= $closePath;
			pop @open;
		}
		# Just a plain old character
		else { $out.= $this }
	} # next character

	# Second parse: substitute my symbols with DATR symbols including angle-brackets
	# Quoted node path:
	$out =~ s/([\w]*)$openQuotedNodePath/<QUOTEDNODEPATH name="$1">\n/sg;
	$out =~ s|$closeQuotedNodePath"|</QUOTEDNODEPATH>\n|sig;			#"

	# Node path:
	$out =~ s/([\w]*)$openNodePath/<NODEPATH name="$1">\n/sg;
	$out =~ s/$closeNodePath/<\/NODEPATH>\n/sg;

	# Quoted path:
	$out =~ s/$openQuotedPath/<QUOTEDPATH>/sg;
	$out =~ s|$closeQuotedPath"|</QUOTEDPATH>\n|sig;					#"

	# Quoted atoms:
	# Find words ending in double-quote not followed by a right angle-bracket or oblique
	$out =~ s|(\w+)"(?![>/])|<QUOTEDATOM value="$1"/>\n|sg;			#"
	# Paths:
	$out =~ s/$openPath/<PATH>/sg;
	$out =~ s|$closePath|</PATH>\n|sg;

	# Replace linefeeds at the begining of attribute values:
	$out =~ s/"(\n|\r|\f)/"/g;

	# Atoms within all bar <EQUATION>(atoms)</EQUATION>:
	$out =~ s|(<[^>]*>)([^<]+)|							# Group, & grab after element > upto <
				sprintf(								# Format on each parse by regex engine
				   "%s<ATOM value=\"%s\"/>",			# Mix the atom element with ¬
				   $1,									# match group 1 ¬
				   join('"/><ATOM value="',split(/\s/,$2) ) # and with worked-on group 2 ¬
				)										# split at whitespace
			|xeg;										# NB: eXtended and Evaluated Globally

	# Much the same as the previous ATOM regex.
	$out =~ s|^([^<]+)|
			sprintf("<ATOM value=\"%s\"/>",
				join('"/><ATOM value="',split(/\s/,$1)))
			|xeg;

	# Remove all null-atoms: quicker than checking whether to create in first place
	$out =~ s|<ATOM value=""/>||g;

	return $out;
}	# end sub _parsePath







=head2 _preFormatNodes (private method)

Formats nodes for processing by removing comments/directives/linefeeds

	Accepts:	strings or array of DATR node/path/value sentences
	Returns:	one string of DATR node/path/value sentences, without linebreaks

=cut


sub _preFormatNodes { $_ = shift;		# Collect method's object reference
	my (@d) = (@_);
	my ($comment, $last_comment) = ("", ""); # See below
	print "Formatting ... \n" if $log;		 # Be extra polite if asked to
	foreach (@d) {          			# Loop through whole, stripping line feeds
        tr/\n\r\f//d;					# Drop line breaks
        next if not /%/;				# Only proceed if a comment symbol present
        m/^(.*)%\s*(.*?)$/o;			# DATR in group 1, comments in Group 2
        $_ = $1;						# Remove comments
        if ($last_comment ne $2) {      # If group 3 found a NEW comment
            $comment .= "$2 ";   	    # Save new comment with space for next
            $last_comment = $2;    	    # Remember this comment
        }
	}									# Next in array
	print "...done.\n" if $log;
	# Return the array coerced to scalar
	print ">$comment\n";
	return join ("", @d), $comment;

}






=head2 _setupOutput (private method)

Sets up a filehandle for output, whether STDOUT or not

	Accepts:	string of a filepath, or a filehandle, or a (ref to a) typeglob, or undef
	Returns:	a reference to a typeglob that is the filehandle
	See also:	"Passing Filehandles" in perlfaq7 Perl documentation
	Note:		Would it be better not to default to STDOUT but
			to default to a filename specified at object construction time?

=cut

sub _setupOutput{
	my $FH = shift || *STDOUT;
	# Presence of a second arg to this sub forces a check for a filename as first arg
	if (ref \$FH eq "GLOB" && shift){
		die "\nTried to set-up output to file without a filepath having been specified.\n";
	}
	# If typeglob not passed or created, assume a filepath was passed
	if (ref \$FH ne "GLOB"){ # Check for FileHandle not being a typeglob like STDOUT
		my $filepath = $FH;
		print "Attempting to save XML as $filepath....\n" if $log;
		print "..overwriting existing file....\n" if (-e $filepath) and $log eq "verbose";
		open $FH,">$filepath" or die "failed. Did you include a filename?(Perl said: '$!')\n";
		print "\tOpened $filepath for writing....\n" if $log;
	}
	return $FH;
}







=head2 _printOpeningClosing (private pseudo-method)

Prints as XML contents of opening/clsoing, as requested.

=cut

sub _printOpeningClosing {
	my $self = shift;								# Collect object reference
	my $FH	 = shift;                               # Output FileHandle
	my $method	=	shift;							# Key for $self hash: OPENING/CLOSING
	if (@{ $self->{$method} }){						# Only if object slot is defined
		print $FH "<$method>\n";
		foreach (@{$self->{$method}}){				# Do every entry in $method
			my ($key, $values) = split/\s/,$_,2;	# Split into two at first whitesapce
			if ($_ eq ""){next}						# Skip null strings
			elsif (/^vars/i){								# If a dollar-sign is found ¬
				my ($name,$range) = split/:\s*/,$values,2;	# get element attribs,lose whitespace
				print $FH "\t<VARS name=\"$name\" range=\"$range\"/>\n";	# NB: printing dollar
			}
			elsif (/^load/i){
				/load\s*(.*)$/i;						# Get filename by matching stack
				print $FH "\t<LOAD filename=\"$1\"/>\n";
			}
			elsif (/^reset/i or /^delete/i){				# Faster than (x|y): see Programming_Perl
				/($&)\s*(.*)$/i;						# Match element name found above & get attribute
				print $FH "\t<",uc $1;					# Open element in upper case
				if ($2) {print $FH " value=\"$2\""}		# Print value attribute if present
				print $FH "/>\n";
			}
			else {									# If no dollar-sign is found ¬
				print $FH "\t",&_parsePath(\$values),"\n";
			}										# End-if dollar-sign found
			#else {									# If no dollar-sign is found ¬
			#	print $FH uc "<$key>\n\t",			# print the directive as an element ¬
			#			  &_parsePath(\$values),	# wrapping directive's value ¬
			#			  uc "\n</$key>\n";			# and close the element.
			#}										# End-if dollar-sign found
		}
		print $FH "</$method>\n";
	}
	else { print $FH "<$method/>\n";}
}







1;# Exit the module

__END__;

=head1 AUTHOR and COPYRIGHT

Author:		Lee Goddard code@leegoddard.com, leego@cogs.susx.ac.uk

Copyright:	© Lee Goddard, 09/06/00 and as above. All Rights Reserved.
License:	The GNU General Public License applies: copies available from www.gnu.org/.
You are free to distribute and modify this module under the same terms
as those of Perl itself.

=cut
