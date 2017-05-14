package MARC;

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG $TEST);

$VERSION = '1.07';
$MARC::DEBUG = 0;
$MARC::TEST = 0;

require Exporter;
require 5.004;

@ISA = qw(Exporter);
@EXPORT= qw();
@EXPORT_OK= qw();

#### Not using these yet

#### %EXPORT_TAGS = (USTEXT	=> [qw( marc2ustext )]);
#### Exporter::export_ok_tags('USTEXT');
#### $EXPORT_TAGS{ALL} = \@EXPORT_OK;


# Preloaded methods go here.

sub mycarp { # rec
    Carp::carp (@_) unless $MARC::TEST;
}

####################################################################
# This is the constructor method that creates the MARC object. It  #
# will call the appropriate read using the file and format         #
# parameters that are passed.                                      #
####################################################################
sub new { # rec
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $file = shift;
    my $marc = []; 
    my $totalrecord;
    $marc->[0]{'increment'}=-1; #store the default increment in the object
    my $proto_rec;
#    print STDERR "foo\n";
    { 
	# We are going to look for related classes in Perl's
	# symbol table. This is a little tricky.
	# Shoot me.
	
	no strict 'refs';
	# Next, we set up a symbolic reference.
	my $g = $ {$class.'::Rec::VERSION'}; # space for emacs.
	# That was a sample of Perl reflection. Yup, what Smalltalk
	# does with Class and MetaClass, Perl does with strings.
	# Not much structure, but also not much fuss.

        my $rec_class = $class."::Rec" if $g;
	# Now we will use the related Rec class if it exists.
        $rec_class ||= "MARC::Rec";
    
	$proto_rec = $rec_class->new();
    }

    $marc->[0]{'proto_rec'}=$proto_rec; # Used for future manipulations.
    bless ($marc, $class);
	# bless early so _readxxx can use methods
        #if file isn't defined then just return the empty MARC object
    if ($file) {
        unless (-e $file) {mycarp "File $file doesn't exist"; return}
	    #if the file doesn't exist return an error
        my $format = shift || "usmarc";
	    # $format defaults to USMARC if undefined
	open(*file, $file) or mycarp "Open Error: $file, $!";
	binmode *file;
	$marc->[0]{'handle'}=\*file;
	$proto_rec->{'handle'} = $marc->[0]{'handle'};
	$proto_rec->{'format'} = lc $format;
        if ($format =~ /usmarc$/io) {
	    $marc->[0]{'format'}='usmarc';
	    $totalrecord = _readmarc($marc);
	    close *file or mycarp "Close Error: $file, $!";
        }
        elsif ($format =~ /unimarc$/io) {
	    $marc->[0]{'format'}='unimarc';
	    $totalrecord = _readmarc($marc);
	    close *file or mycarp "Close Error: $file, $!";
        }
        elsif ($format =~ /marcmaker$/io) {
	    $marc->[0]{'lineterm'}="\015\012";	# MS-DOS default for MARCMaker
	    $totalrecord = _readmarcmaker($marc);
	    close *file or mycarp "Close Error: $file, $!";
        }
        elsif ($format =~ /xml/oi) {
	    mycarp "XML formats are now handled by MARC::XML";
	    return;
        }
        else {
	    mycarp "I don't recognize format $format";
	    return;
        }
    }
    print "read in $totalrecord records\n" if $MARC::DEBUG;
    return $marc;
}
####################################################################

# clone returns a new MARC object with copies of the data.
# Admin information remains linked to original.

####################################################################

sub clone {
    my $marc = shift;
    my $class = shift || ref $marc;
    my $ans = $marc->new;
    bless $ans, $class;
    $ans->[0] = $marc->[0];
    foreach my $i (1..$#$marc) {
	my $rec = $marc->[$i];

	my $newrec = $rec->clone();
	bless $newrec, $class."::Rec";
	push @$ans, $newrec;
    }
    return $ans;
}

###################################################################
# _readmarc() reads in a MARC file into the $marc object           #
###################################################################
sub _readmarc { # also rec
    my $marc = shift;
    my $handle = $marc->[0]{'handle'};
    my $proto_rec = $marc->[0]{'proto_rec'};
    my $increment = $marc->[0]{'increment'}; #pick out increment from the object
    my $recordcount = 0;

    while ($increment==-1 || $recordcount<$increment) {
	my ($rec,$status)=$proto_rec->_readmarc();
	last unless $status;
	if ($status == -1) {
	    mycarp "Invalid record, size does not match leader";
	    return unless $recordcount;	# undef if first
	    return -$recordcount;	        # if some are valid		
	}
	if ($status == -2) {
	    mycarp "Invalid record, leader size not numeric";
	    return unless $recordcount;	# undef if first
	    return -$recordcount;	        # if some are valid		
	}
	push @$marc, $rec;
	$recordcount++;
    } #end processing this record
    return $recordcount;
} 

###################################################################
# readmarcmaker() reads a marcmaker file into the MARC object     #
###################################################################
sub _readmarcmaker { # rec
    my $marc = shift;
    my $handle = $marc->[0]{'handle'};
    my $proto_rec = $marc->[0]{'proto_rec'};
    my $increment = $marc->[0]{'increment'}; #pick out increment from the object
    unless (exists $marc->[0]{'makerchar'}) {
        $marc->[0]{'makerchar'} = usmarc_default();	# hash ref
	$proto_rec->{'makerchar'} = $marc->[0]{'makerchar'};
    }
    my $recordcount = 0;

    while ($increment==-1 or $recordcount<$increment) {
	my ($rec,$status) = $proto_rec->_readmarcmaker();
	last unless $status;
	if ($status == -1)  {
	    mycarp 'Invalid record, prefix "=LDR  " not found';
	    return unless $recordcount;	# undef if first
	    return -$recordcount;	# if some are valid		
	}
	push @$marc, $rec;
	$recordcount++;
    } #end reading this record
    return $recordcount;
}

sub _maker2char { # rec
    return MARC::Rec::_maker2char(@_);
}

sub usmarc_default { # rec
    return MARC::Rec::usmarc_default(@_);
}

####################################################################
# marc_count() returns the number of records in a                  #
# particular MARC object                                           #
####################################################################
sub marc_count {
    my $marc=shift;
    return $#$marc;
}

####################################################################
# openmarc() is a method for reading in a MARC file. It takes      #
# several parameters: file (name of the marc file) ; format, ie.   #
# usmarc ; and increment which defines how many records to read in #
####################################################################
sub openmarc {
    my $marc=shift;
    my $params=shift;
    my $file=$params->{'file'};
    if (not(-e $file)) {mycarp "File \"$file\" doesn't exist"; return} 
    $marc->[0]{'format'}=$params->{'format'}; #store format in object
    my $totalrecord;
    $marc->[0]{'increment'}=$params->{'increment'} || 0;
        #store increment in the object, default is 0
    unless ($marc->[0]{'format'}) {$marc->[0]{'format'}="usmarc"}; #default to usmarc
    open(*file, $file) or mycarp "Open Error: $file, $!";
    binmode *file;
    $marc->[0]{'handle'}=\*file; #store filehandle in object
    my $proto_rec = $marc->[0]{'proto_rec'};
    $proto_rec->{'handle'} = $marc->[0]{'handle'};
    $proto_rec->{'format'} = lc $marc->[0]{'format'};
    if ($marc->[0]{'format'} =~ /usmarc/oi) {
	$totalrecord = _readmarc($marc);
    }
    elsif ($marc->[0]{'format'} =~ /marcmaker/oi) {
        if (exists $params->{'charset'}) {
	    $marc->[0]{makerchar} = $params->{'charset'};	# hash ref
	}
	else {
            unless (exists $marc->[0]{'makerchar'}) {
	        $marc->[0]{makerchar} = usmarc_default();	# hash ref
	    }
        }
        $marc->[0]{'lineterm'} = $params->{'lineterm'} || "\015\012";
	$totalrecord = _readmarcmaker($marc);
    }
    else {
	close *file;
        if ($params->{'format'} =~ /xml/oi) {
	    mycarp "XML formats are now handled by MARC::XML";
        }
	else {
	    mycarp "Unrecognized format $marc->[0]{'format'}";
        }
	return;
    }
    print "read in $totalrecord records\n" if $MARC::DEBUG;
    if ($totalrecord==0) {$totalrecord="0 but true"}
    return $totalrecord;    
}

####################################################################
# closemarc() will close a file-handle that was opened with        #
# openmarc()                                                       #
####################################################################
sub closemarc {
    my $marc = shift;
    $marc->[0]{'increment'}=0;
    if (not($marc->[0]{'handle'})) {
	mycarp "There isn't a MARC file to close"; 
	return;
    }
    my $ok = close $marc->[0]{'handle'};
    $marc->[0]{'handle'}=undef;
    return $ok;
}

####################################################################
# nextmarc() will read in more records from a file that has      #
# already been opened with openmarc(). the increment can be        #
# adjusted if necessary by passing a new value as a parameter. the # 
# new records will be APPENDED to the MARC object                  #
####################################################################
sub nextmarc {
    my $marc=shift;
    my $increment=shift;
    my $totalrecord;
    if (not($marc->[0]{'handle'})) {
	mycarp "There isn't a MARC file open"; 
	return;
    }
    if ($increment) {$marc->[0]{'increment'}=$increment}
    if ($marc->[0]{'format'} =~ /usmarc/oi) {
	$totalrecord = _readmarc($marc);
    }
    elsif ($marc->[0]{'format'} =~ /marcmaker/oi) {
	$totalrecord = _readmarcmaker($marc);
    }
    else {return}   
    return $totalrecord;
}

####################################################################

# add_map() takes a recnum and a ref to a field in ($tag,
# $i1,$i2,a=>"bar",...) or ($tag, $field) formats and will append to
# the various indices that we have hanging off that record.  It is
# intended for use in creating records de novo and as a component for
# rebuild_map(). It carefully does not copy subfield values or entire
# fields, maintaining some reference relationships.  What this means
# for indices created with add_map that you can directly edit
# subfield values in $marc->[recnum]{array} and the index will adjust
# automatically. Vice-versa, if you edit subfield values in
# $marc->{recnum}{tag}{subfield_code} the fields in
# $marc->[recnum]{array} will adjust. If you change structural
# information in the array with such an index, you must rebuild the
# part of the index related to the current tag (and possibly the old
# tag if you change the tag).

####################################################################

sub add_map { # rec
    my $marc=shift;
    my $recnum = shift;
    my $rafield = shift;
    $marc->[$recnum]->add_map($rafield);
}

####################################################################

# rebuild_map() takes a recnum and a tag and will synchronize the
# index with all elements in the [recnum]{array} with that tag.

####################################################################
sub rebuild_map { # rec
    my $marc=shift;
    my $recnum = shift;
    my $tag = shift;
    return undef if $tag eq '000'; #currently ldr is different...
    $marc->[$recnum]->rebuild_map($tag);
}

####################################################################

# rebuild_map_all() takes a recnum and will synchronize the
# index with all elements in the [recnum]{array}

####################################################################
sub rebuild_map_all { # rec
    my $marc=shift;
    my $recnum = shift;
    $marc->[$recnum]->rebuild_map_all();
}

####################################################################
# deletemarc() will delete entire records, specific fields, as     #
# well as specific subfields depending on what parameters are      #
# passed to it                                                     #
####################################################################
sub deletemarc {
    my $marc=shift;
    my $template=shift;

    my $params = _params($template,@_);

    my @delrecords= _records($marc,$params);
    my %delrecords= map {$_=>1} @delrecords;
       #if records parameter not passed set to all records in MARC object
    my $field=$params->{field};
    my $subfield=$params->{subfield};

    my $deletecount=0;
    my @keepers = grep {!$delrecords{$_}} (0..$#$marc);

    #delete entire records
    if (not($field) and not($subfield)) {
	my $class = ref $marc;
	my @newmarc = @$marc[@keepers]; # array slice, look it up.
	@$marc=@newmarc;
	bless $marc,$class;
	return @delrecords;
    }

    #delete fields and/or subfields. deletefirst takes care of the details.
    # This may be slow. If so write a loop using deletesubfield, etc.

    foreach my $i (1..$#$marc) {
	next unless $delrecords{$i};
	my $rec=$marc->[$i];
	my @newfields =();
	while (1) {
	    my $has_subfield = $rec->deletefirst($template);
	    last unless $has_subfield;
	    $deletecount++;
	}
	$rec->rebuild_map($field);
    }
    return $deletecount;
}

####################################################################
# selectmarc() performs the opposite function of deletemarc(). It  #
# will select specified elements of a MARC object and return them  #
# as a MARC object. So if you wanted to select records 1-10 and 15 #
# of a MARC object you could say $x=$x->selectmarc(["1-10","15"]); #
####################################################################
sub selectmarc {
    my $marc=shift;
    my $selarray=shift;

    my @keepers=(0); # so we have admin information.
    foreach my $selelement (@$selarray) {
	if ($selelement=~/(\d+)-(\d+)/) {
	    push @keepers,($1..$2);
	} else {
	    push @keepers, $selelement;
	}
    }
    if (not($selarray)) {@{$selarray}= (1..$#$marc)} 
    my $class = ref $marc;
    my @newmarc = @$marc[@keepers]; # array slice, look it up.
    @$marc=@newmarc;
    bless $marc,$class;
    return scalar(@keepers) -1; # minus off the $marc->[0] 
}

####################################################################
# searchmarc() is method for searching a MARC object for specific  #
# values. It will return an array which contains the record        #
# numbers that matched.                                            #
####################################################################
sub searchmarc {
    my $marc=shift;
    my $template=shift;
    return unless (ref($template) eq "HASH");
    my $params = _params($template,@_);

    my $field=$params->{field} || return;
    my $subfield=$params->{subfield};
    my $regex=$params->{regex};
    my $notregex=$params->{notregex};
    my @results;
    my $searchtype;

       #determine the type of search 
    if ($field and not($subfield) and not($regex) and not($notregex)) {
	$searchtype="fieldpresence"}
    elsif ($field and $subfield and not($regex) and not($notregex)) {
	$searchtype="subfieldpresence"}
    elsif ($field and not($subfield) and $regex) {
	$searchtype="fieldvalue"}
    elsif ($field and $subfield and $regex) {
	$searchtype="subfieldvalue"}
    elsif ($field and not($subfield) and $notregex) {
	$searchtype="fieldnotvalue"}
    elsif ($field and $subfield and $notregex) {
	$searchtype="subfieldnotvalue"}

       #do the search by cycling through each record
    for (my $i=1; $i<=$#$marc; $i++) {

	my $flag=0;
	if ($searchtype eq "fieldpresence") {
	    next unless exists $marc->[$i]{$field};
	    push(@results,$i);
	}
	elsif ($searchtype eq "subfieldpresence") {
	    next unless exists $marc->[$i]{$field};
	    next unless exists $marc->[$i]{$field}{$subfield};
	    push(@results,$i);
	}
	elsif ($searchtype eq "fieldvalue") {
	    next unless exists $marc->[$i]{$field};
	    next unless exists $marc->[$i]{$field}{field};
	    my $x=$marc->[$i]{$field}{field};
	    foreach my $y (@$x) {
		my $z=_joinfield($y,$field);
		if (eval qq("$z" =~ $regex)) {$flag=1}
	    }
	    if ($flag) {push (@results,$i)}
	}
	elsif ($searchtype eq "subfieldvalue") {
	    next unless exists $marc->[$i]{$field};
	    next unless exists $marc->[$i]{$field}{$subfield};
	    my $x=$marc->[$i]{$field}{$subfield};
	    foreach my $y (@$x) {
		if (eval qq("$$y" =~ $regex)) {$flag=1}
	    }
	    if ($flag) {push (@results,$i)}
	}
	elsif ($searchtype eq "fieldnotvalue" ) {
	    next unless exists $marc->[$i]{$field};
	    next unless exists $marc->[$i]{$field}{field};
	    my $x=$marc->[$i]{$field}{field};
	    if (not($x)) {push(@results,$i); next}
	    foreach my $y (@$x) {
		my $z=_joinfield($y,$field);
		if (eval qq("$z" =~ $notregex)) {$flag=1}
	    }
	    if (not($flag)) {push (@results,$i)}
	}
	elsif ($searchtype eq "subfieldnotvalue") {
	    next unless exists $marc->[$i]{$field};
	    next unless exists $marc->[$i]{$field}{$subfield};
	    my $x=$marc->[$i]{$field}{$subfield};
	    if (not($x)) {push (@results,$i); next}
	    foreach my $y (@$x) {
		if (eval qq("$$y" =~ $notregex)) {$flag=1}
	    }
	    if (not($flag)) {push (@results,$i)}
	}
    }
    return @results;
}

####################################################################

# getfirstvalue() will return the first value of a field or subfield
# or indicator or i12 in a particular record found in the MARC
# object. It does not depend on the index being up to date.

####################################################################
sub getfirstvalue { # rec
    my $marc= shift;
    my $template=shift;
    return unless (ref($template) eq "HASH");
    my $record = $template->{record};
    if (not($record)) {mycarp "You must specify a record"; return}
    if ($record > $#{$marc}) {mycarp "Invalid record specified"; return}
    my $marcrec = $marc->[$record];
    return $marcrec->getfirstvalue($template);

}

####################################################################
# getvalue() will return the value of a field or subfield in a     #
# particular record found in the MARC object                       #
####################################################################
sub getvalue { # rec
    my $marc = shift;
    my $template=shift;
    return unless (ref($template) eq "HASH");
    my $params = _params($template,@_);
    my $record = $params->{record};
    if (not($record)) {mycarp "You must specify a record"; return}
    if ($record > $#{$marc}) {mycarp "Invalid record specified"; return}
    
    return $marc->[$record]->getvalue($params);
}

####################################################################
#Returns LDR at $record.                                           #
####################################################################
sub ldr { # rec
    my ($self,$record)=@_;
    return $self->[$record]->ldr();
}


####################################################################
#Takes a record number and returns a hash of fields.               #
#Needed to determine the format (BOOK, VIS, etc) of                #
#the record.                                                       #
#Folk also like to know what Ctrl, Desc etc are.                   #
####################################################################
sub unpack_ldr { # rec
    my ($self,$record) = @_;
    return $self->[$record]->unpack_ldr();
}

    
sub _unpack_ldr { # rec
    my ($self,$ldr)=@_;
    return $self->[0]{proto_rec}->unpack_ldr($ldr);
}


####################################################################
#Takes a record number.                                            #
#Returns the unpacked ldr as a ref to hash from the ref in $self.  #
#Does not overwrite hash from ldr.                                 #
####################################################################
sub get_hash_ldr { # rec
    my ($self,$record)=@_;
    return $self->[$record]->get_hash_ldr();
}

####################################################################
# Takes a record number and updates the corresponding ldr if there
# is a hashed form. Returns undef unless there is a hash. Else
# returns $ldr.
####################################################################
sub pack_ldr { # rec
    my ($self,$record)=@_;
    return $self->[$record]->pack_ldr();
}

####################################################################
#Takes a ref to hash version of the LDR and returns a string       #
# version                                                          #
####################################################################
sub _pack_ldr { # rec
    my ($self,$rhldr) = @_;
    return $self->[0]{proto_rec}->_pack_ldr($rhldr);
}

####################################################################
#Takes a string record number.                                     #
#Returns a the format necessary to pack/unpack 008 fields correctly#
####################################################################
sub bib_format { # rec
    my ($self,$record)=@_;
    return $self->[$record]->bib_format();
}

sub _bib_format { # rec
    my ($self,$ldr)=@_;
    return $self->[0]{proto_rec}->_bib_format($ldr);
}

####################################################################
#Takes a record number.                                            #
#Returns the unpacked 008 as a ref to hash. Installs ref in $self. #
####################################################################
sub unpack_008 { # rec
    my ($self,$record) = @_;
    return $self->[$record]->unpack_008();
}

sub _unpack_008 { # rec
    my ($self,$ff_string,$bib_format) = @_;
    return $self->[0]{proto_rec}->_unpack_008($ff_string,$bib_format);
}

####################################################################
#Takes a record number.                                            #
#Returns the unpacked 008 as a ref to hash from the ref in $self.  #
#Does not overwrite hash from 008 field.                           #
####################################################################
sub get_hash_008 { # rec
    my ($self,$record)=@_;
    return $self->[$record]->get_hash_008();
}

####################################################################
#Takes a record number. Flushes hashes to 008 and ldr.             #
#Updates the 008 field from an installed fixed field hash.    
#Returns undef unless there is a hash, else returns the 008 field  #
####################################################################
sub pack_008 { # rec
    my ($self,$record) = @_;
    return $self->[$record]->pack_008();
}

####################################################################
#Takes LDR and ref to hash of unpacked 008                         #
#Returns string version of 008 *without* newlines.                 #
####################################################################
sub _pack_008 { # rec
    my ($self,$ldr,$rhff) = @_;
    return $self->[0]{proto_rec}->_pack_008($ldr,$rhff);
}

####################################################################
# _joinfield() is an internal subroutine for creating a string out #
# of an array of subfields. It takes an optional delimiter         #
# parameter which will print out subfields if defined              #
####################################################################
sub _joinfield { # rec
    return MARC::Rec->_joinfield(@_);
}

####################################################################

# _make_005 is a function: it returns the time formatted for the 005
# field.

####################################################################
sub _make_005 {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    # 1. Official specs for 005 are at 
    #     lcweb.loc.gov/marc/bibliographic/ecbdcntr.html
    # They refer to X3.30 ansi; a copy of that would be of interest.
    # 2. Checked out some examples for existing practice.
    $year += 1900;
    $mon++; #$mon is counted from 1 when talking to humans.
    return  "19960221075055.7" if $MARC::TEST;
    return sprintf("%0.4d%0.2d%0.2d%0.2d%0.2d%0.2d.0",$year,$mon,$mday,$hour,$min,$sec);
}

####################################################################

# add_005s takes a template and adds current 005s to the elements of
# $marc mentioned in $template->{records}

####################################################################
sub add_005s {
    my $marc=shift;
    my $args = shift;
    my @records;
    @records= (1..$#$marc);
    if ($args &&  $args->{'records'} ) {
	@records =@{$args->{'records'}};
    }

    my $time = MARC::_make_005() ;
    foreach my $i (@records) {
	$marc->[$i]->add_005($time);
    }
}
    
####################################################################
# output() will call the appropriate output method using the marc  #
# object and desired format parameters.                            # 
####################################################################
sub output {
    my $marc=shift;
    my $args=shift;
    my $output = "";
    my $newline = $args->{'lineterm'} || "\n";

     $marc->add_005s($args) if ($args->{'file'} or $args->{'add_005s'});

    unless (exists $args->{'format'}) {
	    # everything to string
        $args->{'format'} = "marc";
        $args->{'lineterm'} = $newline;
    }
    if ($args->{'format'} =~ /marc$/oi) {
	$output = _writemarc($marc,$args);
    }
    elsif ($args->{'format'} =~ /marcmaker$/oi) {
	$output = _marcmaker($marc,$args);
    }
    elsif ($args->{'format'} =~ /ascii$/oi) {
	$output = _marc2ascii($marc,$args);
    }
    elsif ($args->{'format'} =~ /html$/oi) {
        $output .= "<html><body>";
	$output .= _marc2html($marc,$args);
        $output .="$newline</body></html>$newline";
    }
    elsif ($args->{'format'} =~ /html_header$/oi) {
	$output = "Content-type: text/html\015\012\015\012";
    }
    elsif ($args->{'format'} =~ /html_start$/oi) {
	if ($args->{'title'}) {
            $output = "<html><head><title>$args->{'title'}</title></head>";
	    $output .= "$newline<body>";
	}
	else {
	    $output = "<html><body>";
	}
    }
    elsif ($args->{'format'} =~ /html_body$/oi) {
        $output =_marc2html($marc,$args);
    }
    elsif ($args->{'format'} =~ /html_footer$/oi) {
	$output = "$newline</body></html>$newline";
    }
    elsif ($args->{'format'} =~ /urls$/oi) {
	my $title = $args->{'title'} || "Untitled URLs";
        $output .= "<html><head><title>$title</title></head>$newline<body>$newline";
	$output .= _urls($marc,$args);
        $output .="</body></html>";
    }
    elsif ($args->{'format'} =~ /isbd$/oi) {
	$output = _isbd($marc,$args);
    }
    elsif ($args->{'format'} =~ /xml/oi) {
	mycarp "XML formats are now handled by MARC::XML" if ($^W);
	return;
    }
    if ($args->{'file'}) {
	if ($args->{'file'} !~ /^>/) {
	    mycarp "Don't forget to use > or >> with output file name";
	    return;
	}
	open (OUT, "$args->{file}") || mycarp "Couldn't open file: $!";
	#above quote is bad if {file} is tainted. Is probably unecessary.dgl.
        binmode OUT;
	print OUT $output;
	close OUT || mycarp "Couldn't close file: $!";
	return 1;
    }
      #if no filename was specified return the output so it can be grabbed
    else {
	return $output;
    }
}

####################################################################
# _records unpacks it hashref arg or defaults to the entire list
####################################################################
sub _records {
    my ($marc,$args)=@_;
    my $trecs =[];
    my @records = ();
    $trecs= [$args->{record}] if exists($args->{record});
    $trecs= $args->{records} if $args->{records};

    @records = @$trecs     if      @$trecs;
    @records = (1..$#$marc) unless @$trecs;

     return @records;
}

####################################################################

# params takes a hashref and does a one level deep copy of it.
# It uses the rest of the args to override elements of the hashref.
# Returns a hashref so that caller does'nt have to worry about
# crypto-context.

####################################################################

sub _params {
    return MARC::Rec::_params(@_);
}

####################################################################
# _writemarc() takes a MARC object as its input and returns the    #
# the USMARC equivalent of the object as a string                  #
####################################################################
sub _writemarc { #rec
    my $marc=shift;
    my $args=shift;
    #Read in each individual MARC record in the file
    my @records = _records($marc,$args);

    my $marcrecord="";
    foreach my $i (@records) {
	my $record = $marc->[$i];
	$marcrecord .= $record->_writemarc($args);
    }
    return $marcrecord;
}


####################################################################
# _marc2ascii() takes a MARC object as its input and returns the   #
# ASCII equivalent of the object (field names, indicators, field   #
# values and line-breaks)                                          #
####################################################################
sub _marc2ascii { # rec
    my $marc=shift;
    my $args=shift;
    my @records = _records($marc,$args);
    $args->{'lineterm'} ||= "\n";
    my $output = "";
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	$output .= $record->_marc2ascii($args);
    }
    return $output;
}

####################################################################
# _marcmaker() takes a MARC object as its input and converts it    #
# into MARCMaker format, which is returned as a string             #
####################################################################
sub _marcmaker { # rec
    my @output = ();
    my $marc=shift;
    my $args=shift;
    $args->{'proto_rec'} = $marc->[0]{'proto_rec'};
    my @records = _records($marc,$args);

    local $^W = 0;	# no warnings
    my $breaker = "";
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	$breaker .= $record->_marcmaker($args);
    }
    return $breaker;
}

sub _char2maker { # rec
    return MARC::Rec::_char2maker(@_);
}

sub ustext_default { # rec
    return MARC::Rec::ustext_default(@_);
}

####################################################################
# _marc2html takes a MARC object as its input and converts it into #
# HTML. It is possible to specify which field you want to output   #
# as well as field labels to be used instead of the MARC codes.    #
# The HTML is returned as a string                                 #
####################################################################
sub _marc2html {
    my $marc = shift;
    my $args = shift;
    my $newline = $args->{'lineterm'} || "\n";

    my @records = _records($marc,$args);
    my $output = "";
    foreach my $i (@records) {
	my $marcrec=$marc->[$i];
	$output.= $marcrec->_marc2html($args);
    }
    return $output;
}


####################################################################
# _urls() takes a MARC object as its input, and then extracts the  #
# control# (MARC 001) and URLs (MARC 856) and outputs them as      #
# hypertext links in an HTML page. This could then be used with a  #
# link checker to determine what URLs are broken.                  #
####################################################################
sub _urls { # rec
    my $marc = shift;
    my $args = shift;

    my $output = "";
    my @records = _records($marc,$args);

    local $^W = 0;	# no warnings
    foreach my $i (@records) {
	my $marcrec=$marc->[$i];
	$output .= $marcrec->_urls($args);
    }
    return $output;
}

####################################################################
# isbd() attempts to create a quasi ISBD output format             #
####################################################################
sub _isbd { # rec
    my $marc=shift;
    my $args=shift;
    my $newline = $args->{'lineterm'} || "\n";
    my @records = _records($marc,$args);
    my $output ="";
    for my $i (@records) { #cycle through each record
	my $record=$marc->[$i];
	$output .= $record->_isbd($args);
    }
    return $output;
}

####################################################################
# createrecord() appends a new record to the MARC object           #
# and initializes the '000' field                                  #
####################################################################
sub createrecord { # rec
    my $marc=shift;
    local $^W = 0;	# no warnings
    my $params=shift;
    my $leader=$params->{'leader'} || "00000nam  2200000 a 4500";
       #default leader see MARC documentation http://lcweb.loc.gov/marc
    my $number=$#$marc + 1;
    my $marcrec = $marc->[0]{'proto_rec'}->createrecord($leader);
    push @$marc, $marcrec;
    return $number;
}

####################################################################
# addfield() appends/inserts a new field into an existing record   #
####################################################################

sub addfield {
    my $marc=shift;
    my $params=shift;
    local $^W = 0;	# no warnings
    my $record=$params->{'record'};
    unless ($record) {mycarp "You must specify a record"; return}
    if ($record > $#{$marc}) {mycarp "Invalid record specified"; return}
    my $field = $params->{'field'};
    unless ($field) {mycarp "You must specify a field"; return}
    unless ($field =~ /^\d{3}$/) {mycarp "Invalid field specified"; return}

    my $i1=$params->{'i1'};
    $i1 = ' ' unless (defined $i1);
    my $i2=$params->{'i2'};
    $i2 = ' ' unless (defined $i2);
    my @value=$params->{'value'} || @_;
    if (ref($params->{'value'}) eq "ARRAY") { @value = @{$params->{'value'}}; }
    unless (defined $value[0]) {mycarp "No value specified"; return}

    if ($field >= 10) {
        if ($value[0] eq 'i1') {
	    shift @value;
	    $i1 = shift @value;
        }
        unless (1 == length($i1)) {
	    mycarp "invalid \'i1\' specified";
	    return;
	}
        if ($value[0] eq 'i2') {
	    shift @value;
	    $i2 = shift @value;
        }
        unless (1 == length($i2)) {
	    mycarp "invalid \'i2\' specified";
	    return;
	}
    }

    my $ordered=$params->{'ordered'} || "y";
    my $insertorder = $#{$marc->[$record]{array}} + 1;
       #if necessary figure out the insert order to preserve tag order
    if ($ordered=~/y/i) {
	for (my $i=0; $i<=$#{$marc->[$record]{array}}; $i++) {
	    if ($marc->[$record]{array}[$i][0] > $field) {
		$insertorder=$i;
		last;
	    }
	    if ($insertorder==0) {$insertorder=1}
	}
    }
    my @field;
    if ($field<10) {
	push (@field, $field, $value[0]);
	if ($ordered=~/y/i) {
	    splice @{$marc->[$record]{array}},$insertorder,0,\@field; 
	}
	else {
	    push (@{$marc->[$record]{array}},\@field);
	}
    }
    else {
	push (@field, $field, $i1, $i2);
	my ($sub_id, $subfield);
	while ($sub_id = shift @value) {
	    last if ($sub_id eq "\036");
	    $subfield = shift @value;
	    push (@field, $sub_id, $subfield);
	}
	if ($ordered=~/y/i) {
	    splice @{$marc->[$record]{array}},$insertorder,0,\@field;
	}
	else {
	    push (@{$marc->[$record]{array}},\@field);
	}
    }
    $marc->add_map($record,\@field);
}

####################################################################

# getfields() takes a template and returns an array of fieldrefs from
# $marc->[$recnum]{'array'} including all with the appropriate tag
# and having the property that they are a contiguous group. (So may
# include fields with other tags.)

####################################################################
sub getfields { # rec
    my $marc=shift;
    my $params=shift;
    my $record=$params->{'record'};
    unless ($record) {mycarp "You must specify a record"; return}
    if ($record > $#{$marc}) {mycarp "Invalid record specified"; return}
    return $marc->[$record]->getfields($params);

}

####################################################################
# getupdate() returns an array of key,value pairs formatted to     #
# pass to addfield(). For repeated tags, a "\036" element is used  #
# to delimit data for separate addfield() commands                 #
####################################################################
sub getupdate {
    my @output;
    my $marc=shift;
    my $params=shift;
    my $record=$params->{'record'};
    unless ($record) {mycarp "You must specify a record"; return}
    if ($record > $#{$marc}) {mycarp "Invalid record specified"; return}
    my $field = $params->{'field'};
    unless ($field) {mycarp "You must specify a field"; return}
    unless ($field =~ /^\d{3}$/) {mycarp "Invalid field specified"; return}

    foreach my $fields (@{$marc->[$record]{array}}) { #cycle each field 
	next unless ($field eq $fields->[0]);
	if ($field<10) {
	    push @output,$fields->[1];
	}
	else {
	    push @output,'i1',$fields->[1],'i2',$fields->[2];
	    my @subfields = @{$fields}[3..$#{$fields}];		
	    while (@subfields) { #cycle through subfields incl. refs
		my $subfield = shift @subfields;
		last unless defined $subfield;
		if (ref($subfield) eq "ARRAY") {
		    foreach my $subsub (@{$subfield}) {
		        push @output, $subsub;
		    }
		}
		else {
		    push @output, $subfield;
		}
	    } #finish cycling through subfields
	} #finish tag test < 10
	push @output,"\036";		
    }
    return @output;
}
#################################################################### 

# deletefirst() takes a template and a boolean $do_rebuild_map to
# rebuild the map. It deletes the field data for a first match, using
# the template and leaves the rest alone. If the template has a
# subfield element it deletes based on the subfield information in the
# template. If the last subfield of a field is deleted, deletefirst()
# also deletes the field.  It complains about attempts to delete
# indicators.  If there is no match, it does nothing. Deletefirst also
# rebuilds the map if $do_rebuild_map. Deletefirst returns the number
# of matches deleted (that would be 0 or 1), or undef if it feels
# grumpy (i.e. carps).

####################################################################

sub deletefirst { # rec
    my $marc = shift || return;
    my $template = shift;
    my $recnum = $template->{'record'};
    if (!$recnum) {mycarp "Need a record to confine my destructive tendencies"; return undef}
    return $marc->[$recnum]->deletefirst($template);
}

#################################################################### 

# field_is_empty takes a ref to an array formatted like
# an element of $marc->[$recnum]{array}. It returns 1 if there are
# no "significant" elements of the array (e.g. nothing but indicators
# if $tag>10), else 0. Override this if you want to delete fields
# that have "insignificant" subfields inside deletefirst.

####################################################################
sub field_is_empty { # rec
    my ($marc,$rfield) = @_;
    return $marc->[0]{proto_rec}->field_is_empty($rfield);
}

#################################################################### 

# field_updatehook takes a ref to an array formatted like
# $marc->[$recnum]{'array'}. It is there so that
# subclasses can override it to do something before calling
# addfield(), e.g.  store field-specific information in the affected
# field or log information in an external file/database. One notes that
# since this is a method, it can ignore its arguments and log global
# information about $marc, e.g. order information in $marc->[$rnum]{'array'}

####################################################################

sub field_updatehook { # rec
    my ($marc,$rfield)=@_;
    $marc->[0]{'proto_rec'}->field_updatehook($rfield);
}

#################################################################### 

# updatefirst() takes a template, a request to rebuild the index, and
# an array from $marc->[recnum]{array}. It replaces/creates the field
# data for a first match, using the template, and leaves the rest
# alone. If the template has a subfield element, (this includes
# indicators) it ignores all other information in the array and only
# updates/creates based on the subfield information in the array. If
# the template has no subfield information then indicators are left
# untouched unless a new field needs to be created, in which case they
# are left blank.

####################################################################

sub updatefirst { # rec
    my $marc = shift || return;
    my $template = shift;
    return unless (ref($template) eq "HASH");
    return unless (@_);
    return if (defined $template->{'value'});

    my $recnum = $template->{'record'};
    if (!$recnum) {mycarp "Need a record to confine my changing needs."; return undef}
    return $marc->[$recnum]->updatefirst($template,@_);
}

####################################################################

# updatefields() takes a template which specifies recnum, a
# $do_rebuild_map and a field (needs the field in case $rafields->[0]
# is empty). It also takes a ref to an array of fieldrefs formatted
# like the output of getfields(), and replaces/creates the field
# data. It assumes that it should remove the fields with the first tag
# in the fieldrefs. It calls rebuild_map() if $do_rebuild_map.

####################################################################
sub updatefields { # rec
    my $marc = shift || return;
    my $template = shift;

    my $rafieldrefs = shift;
    my $recnum = $template->{'record'};
    return $marc->[$recnum]->updatefields($template,$rafieldrefs);
}

####################################################################

# getmatch() takes a subfield code (can be an indicator) and a fieldref
# Returns 0 or a ref to the value to be updated.

####################################################################
sub getmatch { # rec
    my $marc = shift || return;
    return $marc->[0]{proto_rec}->getmatch(@_);
}

####################################################################

# deletesubfield() takes a subfield code (can not be an indicator) and a
# fieldref. Deletes the subfield code and its value in the fieldref at
# the first match on subfield code.  Assumes there is an exact
# subfield match in $fieldref.

####################################################################
sub deletesubfield { # rec
    my $marc = shift || return;
    return $marc->[0]{proto_rec}->deletesubfield(@_);
}

####################################################################

# insertpos() takes a subfield code (can not be an indicator), a
# value, and a fieldref. Updates the fieldref with the first
# place that the fieldref can match. Assumes there is no exact
# subfield match in $fieldref.

####################################################################
sub insertpos { # rec
    my $marc = shift || return;
    return $marc->[0]{proto_rec}->insertpos(@_);
}
    

####################################################################
# updaterecord() takes an array of key/value pairs, formatted like #
# the output of getupdate(), and replaces/creates the field data.  #
# For repeated tags, a "\036" element is used to delimit data into #
# separate addfield() commands.                                    #
####################################################################
sub updaterecord {
    my $marc = shift || return;
    my $template = shift;
    return unless (ref($template) eq "HASH");
    return unless (@_);
    return if (defined $template->{'value'});
    my $count = 0;
    my @records = ();
    unless ($marc->deletemarc($template)) {mycarp "not deleted\n"; return;}
    foreach my $y1 (@_) {
        unless ($y1 eq "\036") {
    	    push @records, $y1;
	    next;
        }
        unless ($marc->addfield($template, @records)) {
	    mycarp "not added\n";
	    return;
	}
        @records = ();
	$count++;
    }
    return $count;
}

####################################################################
# _offset is an internal subroutine used by writemarc to offset    #
# number ie. making "34" into "00034".                             #
#################################################################### 
sub _offset{
    return MARC::Rec::_offset(@_);
}

####################################################################

# MARC::Rec is responsible for the methods and representation of
# a single MARC record. Its protocol is very close to that of MARC:
# in fact, most MARC methods have been moved here without the record
# number and re-implemented in standard form by delegation.

####################################################################

package MARC::Rec;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
	    @LDR_FIELDS $LDR_TEMPLATE %FF_FIELDS %FF_TEMPLATE
	    );

$VERSION = $MARC::VERSION;

@ISA = qw(Exporter);
@EXPORT= qw();
@EXPORT_OK= qw();

#### Not using these yet

#### %EXPORT_TAGS = (USTEXT	=> [qw( marc2ustext )]);
#### Exporter::export_ok_tags('USTEXT');
#### $EXPORT_TAGS{ALL} = \@EXPORT_OK;

# gotta know where to find leader information....

@LDR_FIELDS = qw(rec_len RecStat Type BLvl Ctrl Undefldr base_addr
		 ELvl Desc ln_rec len_len_field len_start_char len_impl Undef2ldr);

$LDR_TEMPLATE = "a5aaaaa3a5aaaaaaa";

#...And the 008 field has a special place in Librarians' hearts.
%FF_FIELDS = (
	      BOOKS =>
	      [qw(Entered DtSt Date1 Date2 Ctry Ills Audn Form Cont
		  GPub Conf Fest Indx Undef1 Fict Biog Lang MRec Srce)],
	      COMPUTER_FILES => 
	      [qw(Entered DtSt Date1 Date2 Ctry Undef1 Audn Undef2 
		  File Undef3 GPub Undef4 Lang MRec Srce)],
	      MAPS =>
	      [qw(Entered DtSt Date1 Date2 Ctry Relf Proj Prme CrTp
		  Undef1 GPub Undef2 Indx Undef3 SpFm Lang MRec Srce)],
	      MUSIC =>        
	      [qw(Entered DtSt Date1 Date2 Ctry Comp FMus Undef1 Audn
		  Form AccM LTxt Undef2 Lang MRec Srce)],
	      SERIALS =>	
	      [qw(Entered DtSt Date1 Date2 Ctry Freq Regl ISSN SrTp
		  Orig Form EntW Cont GPub Conf Undef1 Alph S_L Lang MRec Srce)],
	      VIS =>
	      [qw(Entered DtSt Date1 Date2 Ctry Time Undef1 
		  Audn AccM GPub Undef2 TMat Tech Lang MRec Srce)],
	      MIX =>
	      [qw(Entered DtSt Date1 Date2 
		  Ctry Undef1 Form Undef2 Lang MRec Srce)]
	      );

%FF_TEMPLATE = (
		BOOKS          =>   "a6a1a4a4a3a4a1a1a4a1a1a1a1a1a1a1a3a1a1",
		COMPUTER_FILES =>   "a6a1a4a4a3a4a1a3a1a1a1a6a3a1a1",
		MAPS           =>   "a6a1a4a4a3a4a2a1a1a2a1a2a1a1a2a3a1a1",
		MUSIC          =>   "a6a1a4a4a3a2a1a1a1a1a6a2a3a3a1a1",
		SERIALS        =>   "a6a1a4a4a3a1a1a1a1a1a1a1a3a1a1a3a1a1a3a1a1",
		VIS            =>   "a6a1a4a4a3a3a1a1a5a1a4a1a1a3a1a1",
		MIX            =>   "a6a1a4a4a3a5a1a11a3a1a1"
		);

# Preloaded methods go here.
####################################################################
# _offset is an internal subroutine used by writemarc to offset    #
# number ie. making "34" into "00034".                             #
#################################################################### 
sub _offset{
    my $value=shift;
    my $digits=shift;
    print "DEBUG: _offset value = $value, digits = $digits\n" if $MARC::DEBUG;
    my $x=length($value);
    $x=$digits-$x;
    $x="0"x$x."$value";
}

sub mycarp { # rec
    Carp::carp (@_) unless $MARC::TEST;
}

####################################################################

# This is the constructor method that creates the MARC::Rec object. It
# sets up references and gets out. Any file it knows about will be an
# already opened filehandle: do error checking and binmode on the file
# outside MARC::Rec.

####################################################################
sub new { # rec
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $filehandle = shift;
    my $marcrec = {}; 
    bless ($marcrec, $class);
    my $format = shift || "usmarc";

    $marcrec->{'handle'} ||= \*filehandle;
    $marcrec->{'format'}=$format;
    $marcrec->{'lineterm'}="\015\012" if $format eq 'marcmaker';
    # MS-DOS default for MARCMaker
    return $marcrec;
}

####################################################################

# Copy_struct returns a copy of the marcrec ($proto) without
# {array} and map information. The copy shares references to
# {handle} by design.

####################################################################
sub copy_struct {
    my $proto = shift;
    my $class = ref($proto);
    my $newrec;
    for (keys %$proto) {
	$newrec->{$_} = $proto->{$_} if /^(handle|format|proto_rec)$/;
    }
    return bless $newrec,$class;
}

####################################################################

# clone returns a new MARC::Rec object with copies of the data.
# Admin information remains linked to original.

####################################################################
sub clone {
    my $marcrec=shift;
    my $ldr = $marcrec->ldr();
    my $ans = $marcrec->createrecord($ldr);
    for (@{$marcrec->{array}}) {
	next if $_->[0] eq '000';
	my @field = @$_;
	my $rfield = \@field;
	push @{$ans->{array}}, $rfield;
	$ans->add_map($rfield);
    }
    return $ans;
}

#################################################################### 

# field_is_empty takes a ref to an array formatted like
# an element of $marc->[$recnum]{array}. It returns 1 if there are
# no "significant" elements of the array (e.g. nothing but indicators
# if $tag>10), else 0. Override this if you want to delete fields
# that have "insignificant" subfields inside deletefirst.

####################################################################
sub field_is_empty { # rec
    my ($marcrec,$rfield) = @_;

    my $tag = $rfield->[0];
    my @field = @$rfield;
    return 1 if ($tag > 10 and !defined($field[3]));
    return 1 if ($tag < 10 and !defined($field[1]) );
    return 0;
}

####################################################################

# field_updatehook echos the version in MARC without the recordnum.

####################################################################
sub field_updatehook { # rec
# nothing. Subclass may want to handle this.
}


####################################################################

# getfields() takes a template and returns an array of fieldrefs from
# $marc->[$recnum]{'array'} including all with the appropriate tag
# and having the property that they are a contiguous group. (So may
# include fields with other tags.)

####################################################################
sub getfields { # rec

    my $marcrec=shift;
    my $params=shift;

    my $field = $params->{'field'};
    unless ($field) {mycarp "You must specify a field"; return}
    unless ($field =~ /^\d{3}$/) {mycarp "Invalid field specified"; return}

    my @ans=();
    my $first = undef;
    my $last = $first; 
    my $pos = 0;
    for (@{$marcrec->{'array'}}) {
	$first = $pos if ($_->[0] eq $field && !defined($first)) ;
	$last = $pos if $_->[0] eq $field;
	$pos++;
    }
    return () unless defined($first);
    return @{$marcrec->{'array'}}[$first..$last]; # array slice. Look it up.
}

#################################################################### 

# deletefirst() takes a template and a boolean $do_rebuild_map to
# rebuild the map. It deletes the field data for a first match, using
# the template and leaves the rest alone. If the template has a
# subfield element it deletes based on the subfield information in the
# template. If the last subfield of a field is deleted, deletefirst()
# also deletes the field.  It complains about attempts to delete
# indicators.  If there is no match, it does nothing. Deletefirst also
# rebuilds the map if $do_rebuild_map. Deletefirst returns the number
# of matches deleted (that would be 0 or 1), or undef if it feels
# grumpy (i.e. carps).

####################################################################

sub deletefirst { # rec
    my $marcrec = shift || return;
    my $template = shift;
    return unless (ref($template) eq "HASH");
    return if (defined $template->{'value'});

    my $field = $template->{'field'};

    my $subfield = $template->{'subfield'};
    my $do_rebuild_map = $template->{'rebuild_map'};
    if (defined($subfield) and $subfield =~/^i[12]$/) {mycarp "Cannot delete indicators"; return undef}
#I know that $marc->{$field}{field} is this information
#But I don't want to depend on the map being up-to-date allways.

    my @fieldrefs = $marcrec->getfields($template); #helps with cjk.

    return 0 unless scalar(@fieldrefs);
    
    if ($field and not($subfield)) {
	shift @fieldrefs;
	$marcrec->updatefields($template,\@fieldrefs);
	$marcrec->rebuild_map($field) if $do_rebuild_map;
	return 1;
    }


    #Linear search for the field where deletion happens and the position 
    #in that field.
    my $rvictim=0;
    my $fieldnum = 0;
    foreach my $fieldref (@fieldrefs) {
	if ($marcrec->getmatch($subfield,$fieldref)){
	    $rvictim=$fieldref;
	    last;
	}
	$fieldnum++;
    }
    if (!$rvictim) {
	$marcrec->rebuild_map($field) if $do_rebuild_map;
	return 0;
    }

    #Now we know that we have a field and subfield with a match.
    #Find the first one and kill it. Kill the enclosing field 
    #if it is the last one.
    $marcrec->deletesubfield($subfield,$rvictim);
    $marcrec->field_updatehook($rvictim);
    if ($marcrec->field_is_empty($rvictim)) {
	splice @fieldrefs,$fieldnum,1;
	$marcrec->updatefields($template,\@fieldrefs);
    }
    #here we don't need to directly touch $marc->{array}
    # since we are not changing its structure.
    $marcrec->rebuild_map($field) if $do_rebuild_map;
    return 1;
}

sub _params {
    my $template =shift;
    return {} unless ref $template eq 'HASH';
    my %params = %$template;
    %params = (%params,@_);
    return \%params;
}

####################################################################
# _writemarc() takes a MARC object as its input and returns the    #
# the USMARC equivalent of the object as a string                  #
####################################################################
sub _writemarc { # rec
    my $marcrec=shift;
    my $args=shift;
    my (@record, $fieldbase, $fielddata, $fieldlength, $fieldposition, 
	$marcrecord, $recordlength);
    
    my $record = $marcrec;
    #Reset variables
    my $position=0; my $directory=""; my $fieldstream=""; 
    my $leader=$record->{'000'}[1];
    foreach my $field (@{$record->{'array'}}) {
	my $tag = $field->[0];
	if ($tag eq '000') {next}; #don't output the directory!
	my $fielddata="";
	if ($tag < 10) {
	    $fielddata=$field->[1]; 
	}
	else {
	    $fielddata.=$field->[1].$field->[2]; #add on indicators
	    my @subfields=@{$field}[3..$#{$field}];
	    while (@subfields) {
		$fielddata.="\037".shift(@subfields); #shift off subfield delimiter
		$fielddata.=shift(@subfields); #shift off subfield value
	    }
	}
	$fielddata.="\036";
	$fieldlength=_offset(length($fielddata),4);
	$fieldposition=_offset($position,5);
	$directory.=$tag.$fieldlength.$fieldposition;
	$position+=$fieldlength;
	$fieldstream.=$fielddata;
    }
    $directory.="\036";
    $fieldstream.="\035";
    $fieldbase=24+length($directory);
    $fieldbase=_offset($fieldbase,5);
    $recordlength=24+length($directory)+length($fieldstream);
    $recordlength=_offset($recordlength,5);
    $leader=~s/^.{5}(.{7}).{5}(.{7})/$recordlength$1$fieldbase$2/;

    $marcrecord ="$leader$directory$fieldstream";

    $record->{'000'}[1] = $leader;	# save recomputed version
    return $marcrecord;
}
    
####################################################################
# _marc2ascii() takes a MARC object as its input and returns the   #
# ASCII equivalent of the object (field names, indicators, field   #
# values and line-breaks)                                          #
####################################################################
sub _marc2ascii {

    my $marcrec=shift;
    my $args=shift;
    my $newline = $args->{'lineterm'} || "\n";
    my $output = "";
    my $record=$marcrec;
    foreach my $fields (@{$record->{'array'}}) { #cycle each field 
	my $tag=$fields->[0];
	print "ASCII: tag = $tag\n" if $MARC::DEBUG;
	if ($tag<10) {
	    $output.="$fields->[0]  $fields->[1]";
	}
	else {
	    $output.="$tag  $fields->[1]$fields->[2]  ";
	    my @subfields = @{$fields}[3..$#{$fields}];		
	    while (@subfields) { #cycle through subfields
		$output .= "\$".shift(@subfields).shift(@subfields);
	    } #finish cycling through subfields
	} #finish tag test < 10
	$output .= $newline; #put a newline at the end of the field
    }
    $output.=$newline; #put an extra newline to separate records
    return $output;
}

####################################################################
# _marcmaker() takes a MARC object as its input and converts it    #
# into MARCMaker format, which is returned as a string             #
####################################################################
sub _marcmaker { # rec
    my @output = ();
    my $marcrec=shift;
    my $args=shift;
    my $proto_rec=$args->{'proto_rec'};
    unless (exists $args->{'charset'}) {
        unless (exists $proto_rec->{'brkrchar'}) {
	    $proto_rec->{'brkrchar'} = ustext_default();	# hash ref
	}
	$args->{'charset'} = $proto_rec->{'brkrchar'};
	$proto_rec->{'charset'}  = $proto_rec->{'brkrchar'};
    }
    local $^W = 0;	# no warnings

    my $record=$marcrec;
    foreach my $fields (@{$record->{'array'}}) { #cycle each field 
	my $tag=$fields->[0];
	print "OUT: tag = $tag\n" if $MARC::DEBUG;
	if ($tag eq '000') {
	    my $value=$fields->[1];
	    $value=~s/ /\\/go;
	    push @output, "=LDR  $value";
	}
	elsif ($tag<10) {
	    my $value = _char2maker($fields->[1], $args->{'charset'});
	    $value=~s/ /\\/go;
	    push @output, "=$tag  $value";
	}
	else {
	    my $indicator1=$fields->[1];
	    $indicator1=~s/ /\\/;
	    my $indicator2=$fields->[2];
	    $indicator2=~s/ /\\/;
	    my $output="=$tag  $indicator1$indicator2";
	    my @subfields = @{$fields}[3..$#{$fields}];		
	    while (@subfields) { #cycle through subfields
		my $subfield_id = shift(@subfields);
		my $subfield = _char2maker( shift(@subfields),
					    $args->{'charset'} );
		$output .= "\$$subfield_id$subfield";
	    } #finish cycling through subfields
	    push @output, $output;
	} #finish tag test < 10
    }
    push @output,""; #put an extra blank line to separate records
    
    my $newline = $args->{'lineterm'} || "\015\012";
    if ($args->{'nolinebreak'}) {
	my $breaker1 = join ($newline, @output) . $newline;
	return $breaker1;
    }
# linebreak on by default
    my @output2 = ();
    foreach my $outline (@output) {
	if (length($outline) < 66) {
	    push @output2, $outline;
	    next;
	}
	else {
	    my @words = split (/\s{1,1}/, $outline);
	    my $outline2 = shift @words;
	    foreach my $word (@words) {
		if (length($outline2) + length($word) < 66) {
		    $outline2 .= " $word";
		}
		else {
		    push @output2, $outline2;
		    $outline2 = " $word";
		}
	    }
	    push @output2, $outline2;
	}
    }
    my $breaker = join ($newline, @output2);
    return $breaker;
}

sub _char2maker {
    my @marc_string = split (//, shift);
    my $charmap = shift;
    my $maker_string = join ('', map { ${$charmap}{$_} } @marc_string);
    while ($maker_string =~ s/(&)([^ ]{1,7}?)(;)/{$2}/o) {}
    return $maker_string;
}

sub ustext_default {
    my @hexchar = (0x00..0x1a,0x1c,0x7f..0x8c,0x8f..0xa0,0xaf,0xbb,
		   0xbe,0xbf,0xc7..0xdf,0xfc,0xfd,0xff);
    my %outchar = map {chr($_), sprintf ("{%2.2X}",int $_)} @hexchar;

    my @ascchar = map {chr($_)} (0x20..0x23,0x25..0x7a,0x7c,0x7e);
    foreach my $asc (@ascchar) { $outchar{$asc} = $asc; }

    $outchar{chr(0x1b)} = '{esc}';	# escape
    $outchar{chr(0x24)} = '{dollar}';	# dollar sign
    $outchar{chr(0x5c)} = '{bsol}';	# back slash (reverse solidus)
    $outchar{chr(0x7b)} = '{lcub}';	# opening curly brace
    $outchar{chr(0x7d)} = '{rcub}';	# closing curly brace
    $outchar{chr(0x8d)} = '{joiner}';	# zero width joiner
    $outchar{chr(0x8e)} = '{nonjoin}';	# zero width non-joiner
    $outchar{chr(0xa1)} = '{Lstrok}';	# latin capital letter l with stroke
    $outchar{chr(0xa2)} = '{Ostrok}';	# latin capital letter o with stroke
    $outchar{chr(0xa3)} = '{Dstrok}';	# latin capital letter d with stroke
    $outchar{chr(0xa4)} = '{THORN}';	# latin capital letter thorn (icelandic)
    $outchar{chr(0xa5)} = '{AElig}';	# latin capital letter AE
    $outchar{chr(0xa6)} = '{OElig}';	# latin capital letter OE
    $outchar{chr(0xa7)} = '{softsign}';	# modifier letter soft sign
    $outchar{chr(0xa8)} = '{middot}';	# middle dot
    $outchar{chr(0xa9)} = '{flat}';	# musical flat sign
    $outchar{chr(0xaa)} = '{reg}';	# registered sign
    $outchar{chr(0xab)} = '{plusmn}';	# plus-minus sign
    $outchar{chr(0xac)} = '{Ohorn}';	# latin capital letter o with horn
    $outchar{chr(0xad)} = '{Uhorn}';	# latin capital letter u with horn
    $outchar{chr(0xae)} = '{mlrhring}';	# modifier letter right half ring (alif)
    $outchar{chr(0xb0)} = '{mllhring}';	# modifier letter left half ring (ayn)
    $outchar{chr(0xb1)} = '{lstrok}';	# latin small letter l with stroke
    $outchar{chr(0xb2)} = '{ostrok}';	# latin small letter o with stroke
    $outchar{chr(0xb3)} = '{dstrok}';	# latin small letter d with stroke
    $outchar{chr(0xb4)} = '{thorn}';	# latin small letter thorn (icelandic)
    $outchar{chr(0xb5)} = '{aelig}';	# latin small letter ae
    $outchar{chr(0xb6)} = '{oelig}';	# latin small letter oe
    $outchar{chr(0xb7)} = '{hardsign}';	# modifier letter hard sign
    $outchar{chr(0xb8)} = '{inodot}';	# latin small letter dotless i
    $outchar{chr(0xb9)} = '{pound}';	# pound sign
    $outchar{chr(0xba)} = '{eth}';	# latin small letter eth
    $outchar{chr(0xbc)} = '{ohorn}';	# latin small letter o with horn
    $outchar{chr(0xbd)} = '{uhorn}';	# latin small letter u with horn
    $outchar{chr(0xc0)} = '{deg}';	# degree sign
    $outchar{chr(0xc1)} = '{scriptl}';	# latin small letter script l
    $outchar{chr(0xc2)} = '{phono}';	# sound recording copyright
    $outchar{chr(0xc3)} = '{copy}';	# copyright sign
    $outchar{chr(0xc4)} = '{sharp}';	# sharp
    $outchar{chr(0xc5)} = '{iquest}';	# inverted question mark
    $outchar{chr(0xc6)} = '{iexcl}';	# inverted exclamation mark
    $outchar{chr(0xe0)} = '{hooka}';	# combining hook above
    $outchar{chr(0xe1)} = '{grave}';	# combining grave
    $outchar{chr(0xe2)} = '{acute}';	# combining acute
    $outchar{chr(0xe3)} = '{circ}';	# combining circumflex
    $outchar{chr(0xe4)} = '{tilde}';	# combining tilde
    $outchar{chr(0xe5)} = '{macr}';	# combining macron
    $outchar{chr(0xe6)} = '{breve}';	# combining breve
    $outchar{chr(0xe7)} = '{dot}';	# combining dot above
    $outchar{chr(0xe8)} = '{uml}';	# combining diaeresis (umlaut)
    $outchar{chr(0xe9)} = '{caron}';	# combining hacek
    $outchar{chr(0xea)} = '{ring}';	# combining ring above
    $outchar{chr(0xeb)} = '{llig}';	# combining ligature left half
    $outchar{chr(0xec)} = '{rlig}';	# combining ligature right half
    $outchar{chr(0xed)} = '{rcommaa}';	# combining comma above right
    $outchar{chr(0xee)} = '{dblac}';	# combining double acute
    $outchar{chr(0xef)} = '{candra}';	# combining candrabindu
    $outchar{chr(0xf0)} = '{cedil}';	# combining cedilla
    $outchar{chr(0xf1)} = '{ogon}';	# combining ogonek
    $outchar{chr(0xf2)} = '{dotb}';	# combining dot below
    $outchar{chr(0xf3)} = '{dbldotb}';	# combining double dot below
    $outchar{chr(0xf4)} = '{ringb}';	# combining ring below
    $outchar{chr(0xf5)} = '{dblunder}';	# combining double underscore
    $outchar{chr(0xf6)} = '{under}';	# combining underscore
    $outchar{chr(0xf7)} = '{commab}';	# combining comma below
    $outchar{chr(0xf8)} = '{rcedil}';	# combining right cedilla
    $outchar{chr(0xf9)} = '{breveb}';	# combining breve below
    $outchar{chr(0xfa)} = '{ldbltil}';	# combining double tilde left half
    $outchar{chr(0xfb)} = '{rdbltil}';	# combining double tilde right half
    $outchar{chr(0xfe)} = '{commaa}';	# combining comma above
    if ($MARC::DEBUG) {
        foreach my $num (sort keys %outchar) {
            printf "%x = %s\n", ord($num), $outchar{$num};
        }
    }
    return \%outchar;
}

####################################################################
# _marc2html takes a MARC object as its input and converts it into #
# HTML. It is possible to specify which field you want to output   #
# as well as field labels to be used instead of the MARC codes.    #
# The HTML is returned as a string                                 #
####################################################################
sub _marc2html { # rec
    my $marcrec = shift;
    my $args = shift;
    my $newline = $args->{'lineterm'} || "\n";
    my $output = "";
    my $outputall = 1;

    my @tags =();
    @tags = grep /^[0-9]/, sort(keys(%{$args}));

    $outputall = 0 if (scalar(@tags));
    if (defined $args->{'fields'}) {
        if ($args->{'fields'} =~ /all$/oi) {$outputall=1} ## still needed ?????
    }


    my %tags =();

    %tags = map {$_=>1} @tags;
    %tags = map {$_->[0]=>1} @{$marcrec->{'array'}} if $outputall;
      #if 'all' fields are specified then set $outputall flag to yes
    local $^W = 0;	# no warnings

    my $j=$marcrec;
    $output.= $newline."<p>";
    
    foreach my $rfield (@{$j->{'array'}}) {
	$output.= $rfield->[0]." ".$j->_joinfield($rfield,$rfield->[0])."<br>".$newline
	    if $tags{$rfield->[0]};
    }
    $output.="</p>";
    return $output;
}


####################################################################
# _urls() takes a MARC object as its input, and then extracts the  #
# control# (MARC 001) and URLs (MARC 856) and outputs them as      #
# hypertext links in an HTML page. This could then be used with a  #
# link checker to determine what URLs are broken.                  #
####################################################################
sub _urls {
    my $marcrec = shift;
    my $args = shift;
    my $newline = $args->{'lineterm'} || "\n";
    my $output = "";
    
    my $controlnum=undef;
    foreach my $rfield (@{$marcrec->{'array'}}) {
	if ($rfield->[0] eq "001") {
	    $controlnum= $rfield->[1];
	}
	elsif ($rfield->[0] eq "856") {
	    for (my $k=3; $k< $#$rfield; $k++) {
		if ($rfield->[$k] eq "u") {
		    $output.=qq{<a href="$rfield->[$k+1]">$controlnum :}.
			qq{$rfield->[$k+1]</a><br>$newline};
		}
	    }
	}
    }
    return $output;
}

####################################################################
# isbd() attempts to create a quasi ISBD output format             #
####################################################################
sub _isbd { # rec
    my $marcrec=shift;
    my $args=shift;

    my $output = "";
    my $newline = $args->{'lineterm'} || "\n";

    my @reporting_fields = grep {$_->[0] =~/020|245|250|260|300|440|490|5../}
                               @{$marcrec->{'array'}}; # optimization.
    my %tagfields = (); # This will allow random access to fields based on tags
    foreach my $rfield (@reporting_fields) {
	push @{$tagfields{$rfield->[0]}},$rfield;
    }
    $output .= $marcrec->_joinfield($tagfields{245}[0],"245");
    for (qw/250 260 300/) {
	$output .= " -- ". $marcrec->_joinfield($tagfields{$_}[0],$_) if $tagfields{$_};
    }
    if ($tagfields{'440'}) {
	$output .= " -- ";
	foreach my $rfield (@{$tagfields{'440'}}) {
	    $output .= "(".$marcrec->_joinfield($rfield,"440").") ";
	}
    }
    if ($tagfields{'490'}) {
	$output .= " -- " unless $tagfields{'440'};
	foreach my $rfield (@{$tagfields{'490'}}) {
	    $output .= "(".$marcrec->_joinfield($rfield,"490").") ";
	}
    }
    my @f500s = grep {$_->[0] =~/5../} @reporting_fields;
    foreach my $rfield (@f500s) {
	$output .= $newline.$marcrec->_joinfield($rfield,$rfield->[0]);
    }
    if ($tagfields{'020'}) {
	$output .= $newline.$marcrec->_joinfield($tagfields{'020'}[0]);
    }
    $output .= $newline.$newline;		
    return $output;
}

####################################################################

# createrecord takes a string leader and returns a new record with
# leader information at the appropriate place.

####################################################################
sub createrecord { # rec
    my $marcrec = shift;
    local $^W = 0;	# no warnings
    my $leader=shift || "00000nam  2200000 a 4500";
    my $newrec = $marcrec->copy_struct();
       #default leader see MARC documentation http://lcweb.loc.gov/marc
    my @ldrfield = ('000',$leader);
    $newrec->field_updatehook(\@ldrfield);
    push (@{$newrec->{'000'}},@ldrfield); #create map
    push(@{$newrec->{'array'}},$newrec->{'000'});
    return $newrec;
}

####################################################################
# nextrec() will read in a record from a filehandle
# already been opened with openmarc(). the increment can be        #
# adjusted if necessary by passing a new value as a parameter. the # 
# new records will be APPENDED to the MARC object                  #
####################################################################
sub nextrec {
    my $marcrec=shift;
    if (not($marcrec->{'handle'})) {
	mycarp "There isn't a MARC file open"; 
	return;
    }
    if ($marcrec->{'format'} =~ /usmarc/oi) {
	return  _readmarc($marcrec);
    }
    elsif ($marcrec->{'format'} =~ /marcmaker/oi) {
	return _readmarcmaker($marcrec);
    }
    else {return (undef,-3)}   
}

####################################################################

# Add_map is the rec equivalent of MARC::add_map (as usual, without
# the record number).

####################################################################
sub add_map { # rec
    my $marcrec=shift;
    my $rafield = shift;
    my $tag = $rafield->[0];
    return undef if $tag eq '000'; #currently handle ldr yourself...
    my @tmp = @$rafield;
    my $field_len = $#tmp;
    my $record = $marcrec;
    if ($tag > 10 ) {
	my $i1 = $rafield->[1];
	my $i2 = $rafield->[2];
	my $i12 = $i1.$i2;

	for(my $i=3;$i<$field_len;$i+=2) {
	    my $subf_code = $rafield->[$i];
	    push(@{$record->{$tag}{$subf_code}}, \$rafield->[$i+1]);
	}
	push(@{$record->{$tag}{'i1'}{$i1}},$rafield);
	push(@{$record->{$tag}{'i2'}{$i2}},$rafield);
	push(@{$record->{$tag}{'i12'}{$i12}},$rafield);
    }
    push(@{$record->{$tag}{field}},$rafield);
}

####################################################################

# rebuild_map() is the ::Rec version of MARC::rebuild_map().

####################################################################
sub rebuild_map { # rec
    my $marcrec=shift;
    my $tag = shift;
    return undef if $tag eq '000'; #currently ldr is different...
    my @tagrefs = grep {$_->[0] eq $tag} @{$marcrec->{'array'}};
    delete $marcrec->{$tag};
    for (@tagrefs) {$marcrec->add_map($_)};
}

####################################################################

# rebuild_map_all() is the ::Rec version of MARC::rebuild_map_all()

####################################################################
sub rebuild_map_all { # rec
    my $marcrec=shift;
    my %tags=();
    map {$tags{$_->[0]}++} @{$marcrec->{'array'}};
    foreach my $tag (keys %tags) {$marcrec->rebuild_map($tag)};
}



####################################################################

# Reads the next record out of the handle. Returns a pair (new
# record,status). Status is 1 in the generic case. Status is -1 if
# lengths do not match -2 if leader size is not numeric, undef if at
# the last record. New record is undef if there is an error or at the
# last record.

####################################################################
sub _readmarc { # rec
    my $marcrec = shift;
    my $handle = $marcrec->{'handle'};
    my $string = shift;
    local $/ = "\035";	# cf. TPJ #14
    local $^W = 0;	# no warnings
    my $line;
    $line = $string if $string;
    $line = <$handle> if $handle and !defined($string);
    my $recordlength = substr($line,0,5);
    my $octets = length ($line);
    $line=~s/[\n\r\cZ]//og;
    return (undef,undef) unless $line;
    if ($recordlength =~ /\d{5}/o) {
	print "recordlength = $recordlength, length = $octets\n"
		if $MARC::DEBUG;
	return  (undef,-1) unless $recordlength == $octets;
    } else {
	return  (undef,-2);
    }
    my @d = ();
    $line=~/^(.{24})([^\036]*)\036(.*)/o;
    my $leader=$1; my $dir=$2; my $data=$3;
    my $record = $marcrec->createrecord($leader);

    @d=$dir=~/(.{12})/go;
	for my $d(@d) {
	    my @field=();
	    my $tag=substr($d,0,3);
	    chop(my $field=substr($data,substr($d,7,5),substr($d,3,4)));
	    if ($tag<10) {
		@field=($tag,$field);
	    }
	    else {
		my ($indi1, $indi2, $field_data) = unpack ("a1a1a*", $field);
		
		push (@field, $tag, $indi1, $indi2);
		
		my @subfields = split(/\037/,$field_data);
		foreach (@subfields) {
		    my $delim = substr($_,0,1);
		    next unless $delim;
		    my $subfield_data = substr($_,1);
		    push(@field, $delim, $subfield_data);
		    
		} #end parsing subfields
	    } #end testing tag number
	    push(@{$record->{'array'}},\@field);
	    $record-> add_map(\@field);
	} #end processing this field
    return ($record,1);
}

###################################################################
# readmarcmaker() reads a marcmaker file into the MARC object     #
###################################################################
sub _readmarcmaker { # rec
    my $marcrec = shift;
    my $handle = $marcrec->{'handle'};
    my $string = shift;
    my $record;

    unless (exists $marcrec->{'makerchar'}) {
        $marcrec->{'makerchar'} = usmarc_default();	# hash ref
    }
    my $charset = $marcrec->{makerchar};
    my $lineterm = $marcrec->{'lineterm'} || "\015\012";
	# MS-DOS file default for MARCMaker

      #Set the file input separator to "\r\n\r\n", which is the same as 
      #a blank line. A single blank line separates individual MARC records
      #in the MARCMakr format.
    local $/ = "$lineterm$lineterm";	# cf. TPJ #14
    local $^W = 0;	# no warnings
    $record = $string if $string;
    $record = <$handle> if $handle and !defined($string);

    return (undef,undef) unless $record;
    #Split each record on the "\n=" into the @fields array
    my @lines=split "$lineterm=",$record;
    my $leader = shift @lines;
    unless ($leader =~ /^=LDR  /o) {
	return (undef, -1);
    }
    
    $leader=~s/^=LDR  //o;	#Remove "=LDR  "
    $leader=~s/[\n\r]//og;
    $leader=~s/\\/ /go;	# substitute " " for \
    my $rec = $marcrec->createrecord($leader);
    foreach my $line (@lines) {
	#Remove newlines from @fields ; and also substitute " " for \
	$line=~s/[\n\r]//og;
	$line=~s/\\/ /go;
	#get the tag name
	my $tag = substr($line,0,3);
	my @field=(); #this will be added to $marcrec and the map updated.
	#if the tag is less than 010 (has no indicators or subfields)
	#then push the data into @$field
	if ($tag < 10) {
	    my $value = _maker2char (substr($line,5), $charset);
	    @field=($tag,$value);
	}
	else {
	    #elseif the tag is greater than 010 (has indicators and 
	    #subfields then add the data to the $marc object
	    my $field_data=substr($line,7);
	    my $i1=substr($line,5,1);
	    my $i2=substr($line,6,1);
	    @field = ($tag,$i1,$i2);
	    
	    my @subfields=split /\$/, $field_data; #get the subfields
	    foreach my $subfield (@subfields) {
		my $delim=substr($subfield,0,1); #extract subfield delimiter
		next unless $delim;
		my $subfield_data= MARC::_maker2char (substr($subfield,1),
						      $charset);
		#extract subfield value
		push (@field, $delim, $subfield_data);
	    } #end parsing subfields
	} #end tag>10
	print "DEBUG: tag = $tag\n" if $MARC::DEBUG;
	push @{$rec->{'array'}},\@field;
	$rec -> add_map(\@field);
    } #end reading this line
    return ($rec,1);
} #end reading this record

sub _maker2char { # rec
    my $marc_string = shift;
    my $charmap = shift;
    while ($marc_string =~ /{(\w{1,8}?)}/o) {
	if (exists ${$charmap}{$1}) {
	    $marc_string = join ('', $`, ${$charmap}{$1}, $');
	}
	else {
	    $marc_string = join ('', $`, '&', $1, ';', $');
	}
    }
       # closing curly brace - part 2, permits {lcub}text{rcub} in input
    $marc_string =~ s/\&rcub;/\x7d/go;
    return $marc_string;
}

sub usmarc_default { # rec
    my @hexchar = (0x00..0x1a,0x1c,0x7f..0x8c,0x8f..0xa0,0xaf,0xbb,
		   0xbe,0xbf,0xc7..0xdf,0xfc,0xfd,0xff);
    my %inchar = map {sprintf ("%2.2X",int $_), chr($_)} @hexchar;

    $inchar{esc} = chr(0x1b);		# escape
    $inchar{dollar} = chr(0x24);	# dollar sign
    $inchar{curren} = chr(0x24);	# dollar sign - alternate
    $inchar{24} = chr(0x24);		# dollar sign - alternate
    $inchar{bsol} = chr(0x5c);		# back slash (reverse solidus)
    $inchar{lcub} = chr(0x7b);		# opening curly brace
    $inchar{rcub} = "&rcub;";		# closing curly brace - part 1
    $inchar{joiner} = chr(0x8d);	# zero width joiner
    $inchar{nonjoin} = chr(0x8e);	# zero width non-joiner
    $inchar{Lstrok} = chr(0xa1);	# latin capital letter l with stroke
    $inchar{Ostrok} = chr(0xa2);	# latin capital letter o with stroke
    $inchar{Dstrok} = chr(0xa3);	# latin capital letter d with stroke
    $inchar{THORN} = chr(0xa4);		# latin capital letter thorn (icelandic)
    $inchar{AElig} = chr(0xa5);		# latin capital letter AE
    $inchar{OElig} = chr(0xa6);		# latin capital letter OE
    $inchar{softsign} = chr(0xa7);	# modifier letter soft sign
    $inchar{middot} = chr(0xa8);	# middle dot
    $inchar{flat} = chr(0xa9);		# musical flat sign
    $inchar{reg} = chr(0xaa);		# registered sign
    $inchar{plusmn} = chr(0xab);	# plus-minus sign
    $inchar{Ohorn} = chr(0xac);		# latin capital letter o with horn
    $inchar{Uhorn} = chr(0xad);		# latin capital letter u with horn
    $inchar{mlrhring} = chr(0xae);	# modifier letter right half ring (alif)
    $inchar{mllhring} = chr(0xb0);	# modifier letter left half ring (ayn)
    $inchar{lstrok} = chr(0xb1);	# latin small letter l with stroke
    $inchar{ostrok} = chr(0xb2);	# latin small letter o with stroke
    $inchar{dstrok} = chr(0xb3);	# latin small letter d with stroke
    $inchar{thorn} = chr(0xb4);		# latin small letter thorn (icelandic)
    $inchar{aelig} = chr(0xb5);		# latin small letter ae
    $inchar{oelig} = chr(0xb6);		# latin small letter oe
    $inchar{hardsign} = chr(0xb7);	# modifier letter hard sign
    $inchar{inodot} = chr(0xb8);	# latin small letter dotless i
    $inchar{pound} = chr(0xb9);		# pound sign
    $inchar{eth} = chr(0xba);		# latin small letter eth
    $inchar{ohorn} = chr(0xbc);		# latin small letter o with horn
    $inchar{uhorn} = chr(0xbd);		# latin small letter u with horn
    $inchar{deg} = chr(0xc0);		# degree sign
    $inchar{scriptl} = chr(0xc1);	# latin small letter script l
    $inchar{phono} = chr(0xc2);		# sound recording copyright
    $inchar{copy} = chr(0xc3);		# copyright sign
    $inchar{sharp} = chr(0xc4);		# sharp
    $inchar{iquest} = chr(0xc5);	# inverted question mark
    $inchar{iexcl} = chr(0xc6);		# inverted exclamation mark
    $inchar{hooka} = chr(0xe0);		# combining hook above
    $inchar{grave} = chr(0xe1);		# combining grave
    $inchar{acute} = chr(0xe2);		# combining acute
    $inchar{circ} = chr(0xe3);		# combining circumflex
    $inchar{tilde} = chr(0xe4);		# combining tilde
    $inchar{macr} = chr(0xe5);		# combining macron
    $inchar{breve} = chr(0xe6);		# combining breve
    $inchar{dot} = chr(0xe7);		# combining dot above
    $inchar{diaer} = chr(0xe8);		# combining diaeresis
    $inchar{uml} = chr(0xe8);		# combining umlaut
    $inchar{caron} = chr(0xe9);		# combining hacek
    $inchar{ring} = chr(0xea);		# combining ring above
    $inchar{llig} = chr(0xeb);		# combining ligature left half
    $inchar{rlig} = chr(0xec);		# combining ligature right half
    $inchar{rcommaa} = chr(0xed);	# combining comma above right
    $inchar{dblac} = chr(0xee);		# combining double acute
    $inchar{candra} = chr(0xef);	# combining candrabindu
    $inchar{cedil} = chr(0xf0);		# combining cedilla
    $inchar{ogon} = chr(0xf1);		# combining ogonek
    $inchar{dotb} = chr(0xf2);		# combining dot below
    $inchar{dbldotb} = chr(0xf3);	# combining double dot below
    $inchar{ringb} = chr(0xf4);		# combining ring below
    $inchar{dblunder} = chr(0xf5);	# combining double underscore
    $inchar{under} = chr(0xf6);		# combining underscore
    $inchar{commab} = chr(0xf7);	# combining comma below
    $inchar{rcedil} = chr(0xf8);	# combining right cedilla
    $inchar{breveb} = chr(0xf9);	# combining breve below
    $inchar{ldbltil} = chr(0xfa);	# combining double tilde left half
    $inchar{rdbltil} = chr(0xfb);	# combining double tilde right half
    $inchar{commaa} = chr(0xfe);	# combining comma above
    if ($MARC::DEBUG) {
        foreach my $str (sort keys %inchar) {
            printf "%s = %x\n", $str, ord($inchar{$str});
        }
    }
    return \%inchar;
}

#################################################################### 

# updatefirst() takes a template, a request to rebuild the index, and
# an array from $marc->[recnum]{array}. It replaces/creates the field
# data for a first match, using the template, and leaves the rest
# alone. If the template has a subfield element, (this includes
# indicators) it ignores all other information in the array and only
# updates/creates based on the subfield information in the array. If
# the template has no subfield information then indicators are left
# untouched unless a new field needs to be created, in which case they
# are left blank.

####################################################################

sub updatefirst { # rec
    my $marcrec = shift || return;
    my $template = shift;
    return unless (ref($template) eq "HASH");
    return unless (@_);
    return if (defined $template->{'value'});


    my @ufield = @_;
    my $field = $template->{'field'};
    my $subfield = $template->{'subfield'};
    my $do_rebuild_map = $template->{'rebuild_map'};

    $ufield[0]= $field;
    my $ufield_lt_10_value = $ufield[1];
    my $ftemplate = {field=>$field};
    if (!$field) {mycarp "Need a field to configure my changing needs."; return undef}

    my @fieldrefs = $marcrec->getfields($template);

# An invariant is that at most one element of @fieldrefs is affected.
    if ($field and not($subfield)) {
	#save the indicators! Yes! Yes!
	my ($i1,$i2) = (" "," ");
	if (defined($fieldrefs[0])) {
	    $i1 = $fieldrefs[0][1];
	    $i2 = $fieldrefs[0][2];
	}
	$ufield[1]=$i1; 
	$ufield[2]=$i2;
	if ($field <10) {@ufield = ($field,$ufield_lt_10_value)}
	my $rafieldrefs = \@fieldrefs;
	$marcrec->field_updatehook(\@ufield);
	$rafieldrefs->[0] = \@ufield;
	if (!scalar(@fieldrefs)) {
	    $marcrec->updatefields($template,$rafieldrefs);		
	    return;
	}
	$fieldrefs[0]=\@ufield;
#There is no issue with $fieldrefs being taken over by the splice in updatefields.
# in current testing. Perl may change its behavior later...
	$marcrec->updatefields($template,\@fieldrefs);
	return;
    } #end field.
# The case of adding first subfields is hard.  (Not too bad with
# indicators since every non-control field has them.)
# OK, we have  field, and subfield. 
	if ($field and $subfield) {
	    if ($field <10) {croak "Cannot update subfields of control fields"; return undef}

	    my $rvictim=0;
	    my $fieldnum = 0;
	    my $rval = 0;
	    foreach my $fieldref (@fieldrefs) {
		$rval = $marcrec->getmatch($subfield,$fieldref);
		if ($rval){
		    $rvictim=$fieldref;
		    last;
		}
		$fieldnum++;
	    }
# At this stage we have the number of the field $fieldnum, 
# whether there is a match, $rvictim,
# and what to update if there is, $rval.

	    if (!$rvictim and $subfield =~/^i[12]$/) {
		mycarp "Field $field does not exist. Can only add indicator $subfield to existing fields.";
		return undef;
	    }
	    #Now we need to find first match in @ufield.
	    my $usub = undef;
	    $usub=$ufield[1] if $subfield eq 'i1';
	    $usub=$ufield[2] if $subfield eq 'i2';

	    for(my  $i=3;$i<@ufield;$i = $i+2) {
		my $sub = $ufield[$i]; 
		if ($sub eq $subfield) {
		    $usub = $ufield[$i+1];
		    last;
		}
	    }
	    mycarp(
		 "Did not find $subfield in spec (".
		 join " ",@ufield . ")" 
		 ) if !defined($usub);

	    if (!scalar(@fieldrefs)) {
		my @newfield = ($field, ' ',' ', $subfield =>$usub);
		my $rafields;
		$marcrec->field_updatehook(\@newfield);
		$rafields->[0] = \@newfield;
		return $marcrec->updatefields($template,$rafields);
	    }
	    #The general insert case.
	    if (!$rvictim and scalar(@fieldrefs)) {
		$rvictim = $fieldrefs[0];
		$marcrec->insertpos($subfield,$usub,$rvictim);
		$marcrec->field_updatehook($rvictim);
		$marcrec->rebuild_map($field) if $do_rebuild_map;
		return 1; # $rvictim is now defined, so can't depend on future
		          # control logic. 
	    }
	    #The general replace case.
	    if ($rvictim) {
		$$rval = $usub;
		$marcrec->field_updatehook($rvictim);

		# The following line is unecessary for this class:
		# everything updates due to hard-coded ref
		# relationships in the index.  Left so that subclasses
		# can do their thing with less over-ruling.

		$marcrec->rebuild_map($field) if $do_rebuild_map; 
		return 1;
		}
	} #end $field and $subfield
}

####################################################################

# updatefields() takes a template which specifies a
# $do_rebuild_map and a field (needs the field in case $rafields->[0]
# is empty). It also takes a ref to an array of fieldrefs formatted
# like the output of getfields(), and replaces/creates the field
# data. It assumes that it should remove the fields with the first tag
# in the fieldrefs. It calls rebuild_map() if $do_rebuild_map.

####################################################################
sub updatefields { # rec
    my $marcrec = shift || return;
    my $template = shift;

    my $do_rebuild_map = $template->{'rebuild_map'};
    my $tag = $template->{'field'};
    my $rafieldrefs = shift;
    my @fieldrefs = @$rafieldrefs;


    my $pos = 0;
    my $first=undef;
    my $last = $first; # Should be "Let the first be last". Misbegotten Perl syntax.
    my $firstpast = undef;
    my $len = 0;
    my @mfields = @{$marcrec->{'array'}};
    my $insertpos = undef;
    for (@mfields) {
	$first = $pos if ($_->[0] eq $tag and !defined($first)) ;
	$last = $pos if $_->[0] eq $tag;
	$firstpast  = $pos if ($_->[0] >= $tag and   !defined($firstpast)) ;
	$pos++;
    }
    $len = $last - $first +1 if defined($first);
    $insertpos = scalar(@mfields) if !defined($firstpast);
    $insertpos = $first if (defined($first));
    $insertpos = $firstpast unless $insertpos;
    splice @{$marcrec->{'array'}},$insertpos,$len,@fieldrefs;
    $marcrec->rebuild_map($tag) if $do_rebuild_map;
}

####################################################################
# output() will call the appropriate output method using the marc  #
# object and desired format parameters.                            # 
####################################################################
sub output {
    my $marcrec=shift;
    my $args=shift;
    my $output = "";
    my $newline = $args->{'lineterm'} || "\n";

    $marcrec->add_005($args) if ($args->{'file'} or $args->{'add_005s'});

    unless (exists $args->{'format'}) {
	    # everything to string
        $args->{'format'} = "usmarc";
        $args->{'lineterm'} = $newline;
    }
    if ($args->{'format'} =~ /marc$/oi) {
	$output = _writemarc($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /marcmaker$/oi) {
	$output = _marcmaker($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /ascii$/oi) {
	$output = _marc2ascii($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /html$/oi) {
	$output .= _marc2html($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /html_header$/oi) {
	$output = "Content-type: text/html\015\012\015\012";
    }
    elsif ($args->{'format'} =~ /html_start$/oi) {
	if ($args->{'title'}) {
            $output = "<html><head><title>$args->{'title'}</title></head>";
	    $output .= "$newline<body>";
	}
	else {
	    $output = "<html><body>";
	}
    }
    elsif ($args->{'format'} =~ /html_body$/oi) {
        $output =_marc2html($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /html_footer$/oi) {
	$output = "$newline</body></html>$newline";
    }
    elsif ($args->{'format'} =~ /urls$/oi) {
	$output .= _urls($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /isbd$/oi) {
	$output = _isbd($marcrec,$args);
    }
    elsif ($args->{'format'} =~ /xml/oi) {
	mycarp "XML formats are now handled by MARC::XML" if ($^W);
	return;
    }
    if ($args->{'file'}) {
	if ($args->{'file'} !~ /^>/) {
	    mycarp "Don't forget to use > or >> with output file name";
	    return;
	}
	open (OUT, $args->{file}) || mycarp "Couldn't open file: $!";
	#above quote is bad if {file} is tainted. Is probably unecessary.dgl.
        binmode OUT;
	print OUT $output;
	close OUT || mycarp "Couldn't close file: $!";
	return 1;
    }
      #if no filename was specified return the output so it can be grabbed
    else {
	return $output;
    }
}

####################################################################

# add_005s takes a template and adds current 005s to the elements of
# $marc mentioned in $template->{records}

####################################################################
sub add_005 {
    my $marcrec=shift;
    my $time = shift;
    my @m005 = ('005', $time );
    $marcrec->updatefirst({field=>'005'},@m005);
}

##############################################################
sub _joinfield { # rec
    my $marcrec=shift;
    my ($rfield,$field,$delim)=@_;
    my $result;
    return $rfield->[1] if $field<10;

    if ($delim) {
	foreach (my $i=3; $i<$#$rfield; $i+=2) {
	    $result.=$delim.$rfield->[$i].$rfield->[$i+1];
	}
	return $result;
    }

    for (my $i=4; $i<=$#$rfield; $i=$i+2) {
	$result.=$rfield->[$i];
	$result.=" " unless $result=~/ $/;
    }
    return $result;
}

####################################################################

# getmatch() takes a subfield code (can be an indicator) and a fieldref
# Returns 0 or a ref to the value to be updated.

####################################################################
sub getmatch { # rec
    my $marcrec = shift || return;
    my $subf = shift;
    my $rfield = shift;
    my $tag = $rfield->[0];
    if ($tag < 10) {mycarp "can't find subfields or indicators for control fields"; return undef}
    return \$rfield->[1] if $subf eq 'i1';
    return \$rfield->[2] if $subf eq 'i2';

    for (my $i=3;$i<@$rfield;$i+=2) {
	return \$rfield->[$i+1] if $rfield->[$i] eq $subf;
    }
    return 0;
}

####################################################################

# deletesubfield() takes a subfield code (can not be an indicator) and a
# fieldref. Deletes the subfield code and its value in the fieldref at
# the first match on subfield code.  Assumes there is an exact
# subfield match in $fieldref.

####################################################################
sub deletesubfield { # rec
    my $marcrec = shift || return;
    my $subf = shift;
    my $rfield = shift;
    my $tag = $rfield->[0];
    if ($tag < 10) {mycarp "Can't use subfields or indicators for control fields"; return undef}

    if ($subf =~/i[12]/) {mycarp "Can't delete an indicator."; return undef}
    my $i=3;
    for ($i=3;$i<@$rfield;$i+=2) {
	last if $rfield->[$i] eq $subf;
    }
    splice @$rfield,$i,2; 
    
}

####################################################################

# insertpos() takes a subfield code (can not be an indicator), a
# value, and a fieldref. Updates the fieldref with the first
# place that the fieldref can match. Assumes there is no exact
# subfield match in $fieldref.

####################################################################
sub insertpos { # rec
    my $marcrec = shift || return;
    my $subf = shift;
    my $value = shift;
    my $rfield = shift;
    my $tag = $rfield->[0];
    if ($tag < 10) {mycarp "Can't use subfields or indicators for control fields"; return undef}

    if ($subf =~/i[12]/) {mycarp "Can't insert past an indicator."; return undef}
    my $i=3;
    for ($i=3;$i<@$rfield;$i+=2) {
	last if $rfield->[$i] gt $subf;
    }
    splice @$rfield,$i,0,$subf,$value;
}

####################################################################

# getfirstvalue() will return the first value of a field or subfield
# or indicator or i12 in a particular record found in the MARC
# object. It does not depend on the index being up to date.

####################################################################
sub getfirstvalue { # rec
    my $marcrec= shift;
    my $template=shift;
    return unless (ref($template) eq "HASH");
    my $field  = $template->{'field'};
    my $delim  = $template->{'delimiter'};
    my $subfield;
    $subfield = $template->{'subfield'} if $template->{'subfield'};
    
    if (not($field)) {mycarp "You must specify a field"; return}
    unless ($field =~ /^\d{3}$/) {mycarp "Invalid field specified"; return}
    my @fieldrefs = grep {$_->[0] eq $field} @{$marcrec->{'array'}};
    return unless @fieldrefs;
    if ($field and not $subfield) {
	return $marcrec->_joinfield($fieldrefs[0],$field,$delim);
    } elsif ($field and $subfield) {
	if ($field <10) {mycarp "There are no subfields or indicators for control fields";return}
	return $fieldrefs[0][1].$fieldrefs[0][2] if $subfield eq 'i12';
	my $rsubf = undef;
	foreach my $fieldref (@fieldrefs) {
	    $rsubf =$marcrec->getmatch($subfield,$fieldref);
	    return $$rsubf if $rsubf;
	}
	return undef unless $rsubf;
    }
}
####################################################################
# getvalue() will return the value of a field or subfield in a     #
# particular record found in the MARC object                       #
####################################################################
sub getvalue { # rec
    my $marcrec = shift;
    my $template=shift;
    return unless (ref($template) eq "HASH");
    my $params = _params($template,@_);

    my $field = $params->{field};
    if (not($field)) {mycarp "You must specify a field"; return}
    unless ($field =~ /^\d{3}$/) {mycarp "Invalid field specified"; return}
    my $subfield = $params->{subfield};
    my $delim = $params->{delimiter};
    my @values;
    if ($field and not($subfield)) {
	return unless exists $marcrec->{$field};
	if ($field eq '000') { return $marcrec->{'000'}[1] };
	foreach my $rfield (@{$marcrec->{$field}{field}}) {
	    push @values, 
	    $marcrec->_joinfield($rfield,$field,$delim);
	}
	return @values;
    }
    elsif ($field and $subfield) {
	return unless exists $marcrec->{$field};
	return unless exists $marcrec->{$field}{$subfield};
	if ($subfield eq "i1" || $subfield eq "i2" || $subfield eq "i12") {
	    my @shortone = @{$marcrec->{$field}{field}};
	    foreach my $rfield (@shortone) {
		if ($subfield eq 'i1') {
	            push @values, $rfield->[1];
		}
		elsif ($subfield eq 'i2') {
	            push @values, $rfield->[2];
		}
		else {
	            push @values, $rfield->[1].$rfield->[2];
		}
	    }
	    return @values;
	}
	foreach my $rval (@{$marcrec->{$field}{$subfield}}) {
	    push @values, $$rval;
	}
	return @values;
    }
}

####################################################################
#Returns LDR at $record.                                           #
####################################################################
sub ldr { # rec
    my $marcrec = shift;
    return $marcrec->{array}[0][1];
}


####################################################################
#Takes a record number and returns a hash of fields.               #
#Needed to determine the format (BOOK, VIS, etc) of                #
#the record.                                                       #
#Folk also like to know what Ctrl, Desc etc are.                   #
####################################################################
sub unpack_ldr { # rec
    my $marcrec = shift;

    my $ldr = $marcrec->ldr();
    my $rhldr = $marcrec->_unpack_ldr($ldr);
    $marcrec->{unp_ldr}=$rhldr;
    return $rhldr;
}

    
sub _unpack_ldr { # rec
    my ($marcrec,$ldr) = @_;

    my %ans=();

    my @fields=unpack($LDR_TEMPLATE,$ldr);
    for (@LDR_FIELDS) {
	$ans{$_}=shift @fields;
    }
    return \%ans;
}


####################################################################
#Takes a record number.                                            #
#Returns the unpacked ldr as a ref to hash from the ref in $self.  #
#Does not overwrite hash from ldr.                                 #
####################################################################
sub get_hash_ldr { # rec
    my $marcrec = shift;
    return undef unless exists($marcrec->{unp_ldr});
    return $marcrec->{unp_ldr};
}

####################################################################
# Takes a record number and updates the corresponding ldr if there
# is a hashed form. Returns undef unless there is a hash. Else
# returns $ldr.
####################################################################
sub pack_ldr { # rec
    my $marcrec = shift;
    return undef unless exists($marcrec->{unp_ldr});
    my $rhldr = $marcrec->{unp_ldr};
    my $ldr = $marcrec -> _pack_ldr($rhldr);
    $marcrec->{array}[0][1] = $ldr;
    return $ldr;
}

####################################################################
#Takes a ref to hash version of the LDR and returns a string       #
# version                                                          #
####################################################################
sub _pack_ldr { # rec

    my ($marcrec,$rhldr) = @_;
    my @fields=();

    for (@LDR_FIELDS) {
	push @fields,$rhldr->{$_};
    }
    my $ans = pack($LDR_TEMPLATE,@fields);
    return $ans;
}

####################################################################
#Takes a string record number.                                     #
#Returns a the format necessary to pack/unpack 008 fields correctly#
####################################################################
sub bib_format { # rec
    my ($marcrec)=@_;
    $marcrec->pack_ldr();
    my $ldr = $marcrec->ldr();
    return $marcrec->_bib_format($ldr);
}

sub _bib_format { # rec
    my ($marcrec,$ldr)=@_;
    my $rldr=$marcrec->_unpack_ldr($ldr);
    my ($type,$bib_lvl) = ($rldr->{'Type'},$rldr->{'BLvl'});
    return "UNKNOWN (Type $type Bib_Lvl $bib_lvl)" unless ($type=~/[abcdefgijkmprot]/ &&
							   (($bib_lvl eq "") or 
							    $bib_lvl=~/[abcdms]/)
							   );

    return "BOOKS" if (
		       (
			($type eq "a") && !($bib_lvl =~/[bs]/)
			)
		       or $type eq "t" or $type eq "b"
		       ); #$type b is obsolete, 'tho.
    return "SERIALS" if (
			 ($type eq "a") && 
			 ($bib_lvl =~/[bs]/)
			 );
    return "COMPUTER_FILES" if ($type =~/m/);
    return "MAPS" if ($type =~/[ef]/);
    return "MUSIC" if ($type =~/[cdij]/);
    return "VIS" if ($type =~/[gkro]/);
    return "MIX" if ($type =~/p/);
    return "UNKNOWN (Type $type Bib_Lvl $bib_lvl) ??"; # Shouldn't happen
}

####################################################################
#Takes a record number.                                            #
#Returns the unpacked 008 as a ref to hash. Installs ref in $self. #
####################################################################
sub unpack_008 { # rec
    my ($marcrec) = @_;
    my ($ff_string) = $marcrec->getfirstvalue({field=>'008'});
    my $bib_format = $marcrec->bib_format();
    my $rh008= $marcrec->_unpack_008($ff_string,$bib_format);
    $marcrec->{unp_008}=$rh008;
    return $rh008;
}

sub _unpack_008 { # rec
    my ($marcrec,$ff_string,$bib_format) = @_;
    my %ans=();

    my $ff_templ=$FF_TEMPLATE{$bib_format};
    my $raff_fields=$FF_FIELDS{$bib_format};
    if ($bib_format =~/UNKNOWN/) {
        mycarp "Format is $bib_format";
	return;
    }
    my @fields=unpack($ff_templ,$ff_string);
    for (@{$raff_fields}) {
      $ans{$_}=shift @fields;
    }
    return \%ans;
}

####################################################################
#Takes a record number.                                            #
#Returns the unpacked 008 as a ref to hash from the ref in $self.  #
#Does not overwrite hash from 008 field.                           #
####################################################################
sub get_hash_008 { # rec
    my ($marcrec)=@_;
    return undef unless exists($marcrec->{unp_008});
    return $marcrec->{unp_008};
}

####################################################################
#Takes a record number. Flushes hashes to 008 and ldr.             #
#Updates the 008 field from an installed fixed field hash.    
#Returns undef unless there is a hash, else returns the 008 field  #
####################################################################
sub pack_008 { # rec
    my ($marcrec) = @_;
    $marcrec->pack_ldr();
    my $ldr = $marcrec->ldr();
    my $rhff = $marcrec->get_hash_008();
    return undef unless $rhff;
    my $ff_string = $marcrec->_pack_008($ldr,$rhff);
    $marcrec->updatefirst({field=>'008'},$ff_string);
    return $ff_string;
}

####################################################################
#Takes LDR and ref to hash of unpacked 008                         #
#Returns string version of 008 *without* newlines.                 #
####################################################################
sub _pack_008 { # rec
    my ($marcrec,$ldr,$rhff) = @_;
    my $bib_format = $marcrec->_bib_format($ldr);
    my $ans  = "";
    my @fields = ();
    for (@{$FF_FIELDS{$bib_format}}) {
	push @fields, $rhff->{$_};
    }
    $ans = pack($FF_TEMPLATE{$bib_format},@fields);
    return $ans;
}

####################################################################

# as_string returns a newline-\c^ separated version of the record.
# Subclasses may need to override this. If so, to make Tie happy,
# they should override from_string. 000 is ldr.

####################################################################

sub as_string {
    my $marcrec=shift;
    my $SEP = "\cJ"; #unix newline
    my $ans = "";
    for (@{$marcrec->{'array'}}) {
	my $tag = $_->[0];
	if ($tag < 10) {
	    $ans .= "$tag $_->[1]$SEP";
	    next;
	}
	$ans .= "$tag $_->[1]$_->[2] ";
	foreach (my $i=3; $i<$#$_; $i+=2) {
	    $ans .="\c_$_->[$i]$_->[$i+1]";
	}
	$ans .=$SEP;
    }
    return $ans;
}

####################################################################

# from_string takes a newline-\c^ separated version of the record
# and replaces the {array} information from that information.
# Subclasses may need to override this. If so, to make Tie happy,
# they should override as_string. 000 is ldr.

####################################################################
sub from_string {
    my $marcrec=shift;
    my $string = shift;
    my $do_rebuild_map = shift;
    my $SEP = "\cJ"; #unix newline
    my @lines = split /$SEP/,$string;
    @{$marcrec->{'array'}}=();
    for (@lines) {
	next if /^\s*$/;
	my $tag = substr($_,0,3);
	if ($tag < 10) {
	    my $contents = substr($_,4);
	    push @{$marcrec->{'array'}}, [$tag, $contents];
	    next;
	}
	my ($i1,$i2,$sub_string) = (substr($_,4,1),substr($_,5,1),substr($_,7));
	my @field = ($tag,$i1,$i2);
	my @subfields = split /\c_(.)/,$sub_string;
	shift @subfields if $subfields[0] eq ''; # feature of split.
	push @field,@subfields;
	push @{$marcrec->{'array'}}, [@field];
    }
    $marcrec->rebuild_map_all() if $do_rebuild_map;
}

1;  # so the require or use succeeds

__END__


####################################################################
#                  D O C U M E N T A T I O N                       #
####################################################################

=pod

=head1 NAME

MARC.pm - Perl extension to manipulate MAchine Readable Cataloging records.

=head1 SYNOPSIS

  use MARC;

	# constructors
  $x=MARC->new();
  $x=MARC->new("filename","fileformat");
  $x->openmarc({file=>"makrbrkr.mrc",'format'=>"marcmaker",
		increment=>"5", lineterm=>"\n",
		charset=>\%char_hash});
  $record_num=$x->createrecord({leader=>"00000nmm  2200000 a 4500"});

	# input/output operations
  $y=$x->nextmarc(10);			# increment
  $x->closemarc();
  print $x->marc_count();
  $x->deletemarc({record=>'2',field=>'110'});
  $y=$x->selectmarc(['4','21-50','60']);

	# character translation
  my %inc = %{$x->usmarc_default()};	# MARCMaker input charset
  my %outc = %{$x->ustext_default()};	# MARCBreaker output charset

	# data queries
  @records = $x->searchmarc({field=>"245"});
  @records = $x->searchmarc({field=>"260",subfield=>"c",
			     regex=>"/19../"});
  @records = $x->searchmarc({field=>"245",notregex=>"/huckleberry/i"});
  @results = $x->getvalue({record=>'12',field=>'856',subfield=>'u'});

	# header and control field operations
  $rldr = $x->unpack_ldr($record);
  print "Desc is $rldr->{Desc}";
  next if ($x->bib_format($record) eq 'SERIALS');
  $rff = $x->unpack_008($record);
  last if ($rff->{'Date1'}=~/00/ or $rff->{'Date2'}=~/00/);

	# data modifications
  $x->addfield({record=>"2", field=>"245",
		i1=>"1", i2=>"4", ordered=>'y', value=>
		[a=>"The adventures of Huckleberry Finn /",
                 c=>"Mark Twain ; illustrated by E.W. Kemble."]});

  my $update245 = {field=>'245',record=>2,ordered=>'y'};
  my @u245 = $x->getupdate($update245);
  $x->deletemarc($update245);
  $x->addfield($update245, @u245_modified);
 
	# outputs
  $y = $x->output({'format'=>"marcmaker", charset=>\%outc});
  $x->output({file=>">>my_text.txt",'format'=>"ascii",record=>2});
  $x->output({file=>">my_marcmaker.mkr",'format'=>"marcmaker",
	      nolinebreak=>'y',lineterm=>'\n'});
  $x->output({file=>">titles.html",'format'=>"html", 245=>"Title: "});    

        # manipulation of individual marc records.
  @recs = $x[1..$#$x];
  grep {$_->unpack_ldr() && 0} @recs;
  @LCs = grep {$_->unp_ldr{Desc} eq 'a' &&
	       $_->getvalue({field=>'040'}) =~/DLC\c_.DLC/} @recs;
  foreach my $rec (@LCs) {
	  print $rec->output({format=>'usmarc'});
  }
  
        # manipulation as strings.
  foreach my $rec (@LCs) {
	  my $stringvar = $rec->as_string();
	  $stringvar=~s[^(
			  100\s # main entries of this stripe..
			  ..\s # (don't care about indicators)
			  \c_.\s*
			  )(\S) # take the first letter..
			] [
			${1}uc($2) # and upcase it. All authors have 
				   # upcase first letters in my library.
			]xm; # x means 'ignore whitespace and allow
			     # embedded comments'. 
	 $rec->from_string($stringvar);
	 my ($i2,$article) = $stringvar =~/245 .(.) \c_.(.{0,9})/;	
	 $article = substr($article,0,$i2) if $i2=~/\d/;
	 print "article $article is not common" unless $COMMON_ARTS{$article};
  }
	 
  

=head1 DESCRIPTION

MARC.pm is a Perl 5 module for reading in, manipulating, and outputting bibliographic records in the I<USMARC> format. You will need to have Perl 5.004 or greater for MARC.pm to work properly. Since it is a Perl module you use MARC.pm from one of your own Perl scripts. To see what sorts of conversions are possible you can try out a web interface to MARC.pm which will allow you to upload MARC files and retrieve the results (for details see the section below entitled "Web Interface"). 

However, to get the full functionality you will probably want to install MARC.pm on your server or PC. MARC.pm can handle both single and batches of MARC  records. The limit on the number of records in a batch is determined by the memory capacity of the machine you are running. If memory is an issue for you MARC.pm will allow you to read in records from a batch gradually. MARC.pm also includes a variety of tools for searching, removing, and even creating records from scratch.

=head2 Types of Conversions:

=over 4

=item *

MARC -> ASCII : separates the MARC fields out into separate lines

=item *

MARC <-> MARCMaker : The MARCMaker format is a format that was developed by the
I<Library of Congress> for use with their DOS based I<MARCMaker> and
I<MARCBreaker> utilities. This format is particularly useful for making 
global changes (ie. with a text editor's search and replace) and then converting back to MARC (MARC.pm will read properly formatted MARCMaker records). For more information about the MARCMaker format see http://lcweb.loc.gov/marc/marcsoft.html

=item *

MARC -> HTML : The MARC to HTML conversion creates an HTML file
from the fields and field labels that you supply. You could possibly use
this to create HTML bibliographies from a batch of MARC records. 

=item *

MARC E<lt>-E<gt> XML : XML support is handled by MARC::XML which is a subclass of MARC.pm and is 
also available for download from the CPAN.

=item *

MARC -> URLS : This conversion will extract URLs from a batch of MARC records. The URLs are found in the 856 field, subfield u. The HTML page that is generated can then be used with link-checking software to determine which URLs need to be repaired. Hopefully library system vendors will soon support this activity soon and make this conversion unecessary!

=back

=head2 Downloading and Installing

=over 4

=item Download

The module is provided in standard CPAN distribution format. It will
extract into a directory MARC-version with any necessary subdirectories.
Change into the MARC top directory. Download the latest version from 
http://www.cpan.org/modules/by-module/MARC/

=item Unix

    perl Makefile.PL
    make
    make test
    make install

=item Win9x/WinNT/Win2000

    perl Makefile.PL
    perl test.pl
    perl install.pl

=item Test

Once you have installed, you can check if Perl can find it. Change to some
other directory and execute from the command line:

    perl -e "use MARC"

If you do not get any response that means everything is OK! If you get an
error like I<Can't locate method "use" via package MARC>.
then Perl is not able to find MARC.pm--double check that the file copied
it into the right place during the install.

=back

=head2 Todo

=over 4

=item *

Support for other MARC formats (UKMARC, FINMARC, etc).

=item *

Create a map and instructions for using and extending the MARC.pm data
structure.

=item *

Develop better error catching mechanisms.

=item *

Support for MARC E<lt>-E<gt> Unicode character conversions.

=item *

MARC E<lt>-E<gt> EAD (Encoded Archival Description) conversion?

=item *

MARC E<lt>-E<gt> DC/RDF (Dublin Core Metadata encoded in the Resource Description Framework)?

=back

=head2 Web Interface

A web interface to MARC.pm is available at
http://libstaff.lib.odu.edu/cgi-bin/marc.cgi where you can upload records and
observe the results. If you'd like to check out the cgi script take a look at
http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm/marc-cgi.txt However, to get the full functionality you will want to install MARC.pm on your server or PC.

=head2 Option Templates

A MARC record is a complex structure. Hence, most of the methods have a number
of options. Since a series of operations frequently uses many the same options
for each method, you can create a single variable that forms a "template" for
the desired options. The variable points to a hash - and the hash keys have
been selected so the same hash works for all of the related methods.

    my $loc852 = {record=>1, field=>'852', ordered=>'y'};
    my ($found) = $x->searchmarc($loc852);
    if (defined $found) {
        my @m852 = $x->getupdate($loc852);
        $x->deletemarc($loc852);
            # change @m852 as desired
        $x->updaterecord($loc852, @m852fix);
    }
    else {
        $x->addfield($loc852, @m852new);
    }

The following methods are specifically designed to work together using
I<Option Templates>. The B<required> options are shown as B<bold>. Any
C<(default)> options are shown in parentheses. Although B<deletemarc()>
permits an array for the I<record> option, a single I<record> should be
used in a Template. The I<subfield> option must not be used in a
Template that uses both B<deletemarc> and one of the methods that
acts on a complete I<field> like B<addfield()>. The I<value> option
must not be used with B<updaterecord()>.
 

=over 4

deletemarc() - field (all), record (all), subfield [supplemental]

searchmarc() - B<field>, regex, notregex, subfield [supplemental]

getvalue() - B<record>, B<field>, subfield, delimiter [supplemental]

getupdate() - B<record>, B<field>

addfield() - B<record>, B<field>, i1 (' '), i2 (' '), value, ordered ('y')

updaterecord() - B<record>, B<field>, i1 (' '), i2 (' '), ordered ('y')

=back

The methods that accept a I<subfield> option also accept specifying it as a
supplemental parameter. Supplemental parameters append/overwrite the hash
values specified in the template.

    $x->deletemarc($loc852, 'subfield','k');

    my $f260 = {field=>"260",regex=>"/19../"};
    my @records=$x->searchmarc($f260,'subfield','c');
    foreach $found (@records) {
        $value = $x->getvalue($f260,'record',"$found",'field',"245");
        print "TITLE: $value\n";
    }

=head1 METHODS


Here is a list of the methods in MARC.pm that are available to you for reading in, manipulating and outputting MARC data.

=head2 new()

Creates a new MARC object. 

    $x = MARC->new();

You can also use the optional I<file> and I<format> parameters to create and populate the object with data from a file. If a file is specified it will read in the entire file. If you wish to read in only portions of the file see openmarc(), nextmarc(), and closemarc() below. The I<format> defaults to C<'usmarc'> if not specified. It is only used when a I<file> is given.

    $x = MARC->new("mymarc.dat","usmarc");
    $x = MARC->new("mymarcmaker.mkr","marcmaker");

Creates a new MARC::Rec object.

    $rec=MARC::Rec->new();
    $rec=MARC::Rec->new($filehandle,"usmarc");

MARC::Rec objects are typically created by reading from a filehandle using nextrec()
and a proto MARC::Rec object or by directly stuffing the @{$rec->{'array'}} array.
    


=head2 openmarc()

Opens a specified file for reading data into a MARC object. If no format is specified openmarc() will default to USMARC. The I<increment> parameter defines how many records you would like to read from the file. If no I<increment> is defined then the file will just be opened, and no records will be read in. If I<increment> is set to -1 then the entire file will be read in.

    $x = new MARC;
    $x->openmarc({file=>"mymarc.dat",'format'=>"usmarc",
		  increment=>"1"});
    $x->openmarc({file=>"mymarcmaker.mkr",'format'=>"marcmaker",
		  increment=>"5"});

note: openmarc() will return the number of records read in. If the file opens
successfully, but no records are read, it returns C<"0 but true">. For example:

    $y=$x->openmarc({file=>"mymarc.dat",'format'=>"usmarc",
		     increment=>"5"});
    print "Read in $y records!";

When the I<MARCMaker> format is specified, the I<lineterm> parameter can be
used to override the CRLF line-ending default (the format was originally
released for MS-DOS). A I<charset> parameter accepts a hash-reference to a
user supplied character translation table. The "usmarc.txt" table supplied
with the LoC. MARCMaker utility is used internally as the default. You can
use the B<usmarc_default> method to get a hash-reference to it if you only
want to modify a couple of characters. See example below.

    $x->openmarc({file=>"makrbrkr.mrc",'format'=>"marcmaker",
		  increment=>"5",lineterm=>"\n",
		  charset=>\%char_hash});

=head2 nextmarc()

Once a file is open nextmarc() can be used to read in the next group of records. The increment can be passed to change the number of records read in if necessary. An increment of -1 will read in the rest of the file. Specifying the increment will change the value set with openmarc(). Otherwise, that value is the default.

    $x->nextmarc();
    $x->nextmarc(10);
    $x->nextmarc(-1);

note: Similar to openmarc(), nextmarc() will return the number of records read in. 

    $y=$x->nextmarc();
    print "$y more records read in!";

=head2 nextrec()

MARC:Rec instances can read from a filehandle and produce a new MARC::Rec instance.
If nextrec is passed a string, it will read from that instead. The string should be
formatted according to the {format} field of the instance.

Cases where a new instance cannot be created are classified by a status value:

    my ($newrec,$status) = $rec->nextrec();

$status is undefined if we are at the end of the filehandle. If the
data read from the filehandle cannot be made into a marc record,
$status will be negative.  For example, $status is -1 if there is a
distinction between recsize and leader definition of recsize, and -2
if the leader is not numeric.

An idiom for reading records incrementally with MARC::Recs is:

    my $proto=MARC::Rec->new($filehandle,$format);
    while (1) {
	  my ($rec,$status)=$proto->nextrec();
	  last unless $status;
	  die "Bad record, bad, bad record: error $status"
	      if $status <0;
	  print $rec->output({$format=>'ascii'});
	  # or replace print and output with your own functions/methods.
    }
    close $filehandle or die "File $filehandle is not happy on close\n";

If you are getting records from an external source as strings, the idiom is:

    my $proto=MARC::Rec->new($filehandle,$format);
    while (1) {
          my $string = get_external_marc();
          last unless $string;
          my ($rec,$status)=$proto->nextrec($string);
          last unless $status;
          die "Bad record, bad, bad record: error $status"
              if $status <0;
          print $rec->output({$format=>'ascii'});
          # or replace print and output with your own functions/methods.
    }


=head2 closemarc()

If you are finished reading in records from a file you should close it immediately.

    $x->closemarc();

=head2 add_map()

add_map() takes a recnum and a ref to a field in ($tag,
$i1,$i2,a=>"bar",...) or ($tag, $field) formats and will append to the
various indices that we have hanging off that record.  It is intended
for use in creating records de novo and as a component for
rebuild_map(). It carefully does not copy subfield values or entire
fields, maintaining some reference relationships.  What this means for
indices created with add_map that you can directly edit subfield
values in $marc->[recnum]{array} and the index will adjust
automatically. Vice-versa, if you edit subfield values in
$marc->{recnum}{tag}{subfield_code} the fields in
$marc->[recnum]{array} will adjust. If you change structural
information in the array with such an index, you must rebuild the part
of the index related to the current tag (and possibly the old tag if
you change the tag).

   use MARC 1.02;
   while (<>) {
        chomp;
        my ($author,$title) = split(/\t/);
        my $rnum = $x->createrecord({leader=>
			    	       "00000nmm  2200000 a 4500"});

        my @auth = (100, ' ', ' ', a=>$author);
        my @title = (245, ' ', ' ', a=>$title);
        push @{$x->[$rnum]{array}}, \@auth;
        $x->add_map($rnum,\@auth);
        push @{$x->[$rnum]{array}}, \@title;
        $x->add_map($rnum,\@title);
   }

MARC::Rec::add_map($rfield) does not need the record specification and has the same
effect as add_map.

=head2 rebuild_map

rebuild_map takes a recnum and a tag and will synchronise the index with
the array elements of the marc record at the recnum with that tag.

      #Gonna change all 099's to 092's since this is a music collection.
      grep {$->[0] =~s/099/092} @{$x->[$recnum]{array}};
      
      #Oops, now the index is out of date on the 099's...
      $x->rebuild_map($recnum,099);
      #... and the 092's since we now have new ones.
      $x->rebuild_map($recnum,092);
      #All fixed.

MARC::Rec::rebuild_map($tag) does not need the record number and has the same effect
as rebuild_map.

=head2 rebuild_map_all

rebuild_map takes a recnum and will synchronise the index with
the array elements of the marc record at the recnum.

MARC::Rec::rebuild_map_all() does not need the record number and has the same effect
as rebuild_map_all.

=head2 getfields

getfields takes a template and returns an array of fieldrefs from the
record number implied by that template. The fields referred are 
fields from the $marc->[$recnum]{array} group. The fields are all
fields from the first one with the tag from the template to the last
with that tag. Some marc records (e.g. cjk) may have fields with other
tags mixed in. Consecutive calls to updatefields with a different
tag and the same record are probably a bad idea unless you have assurance
that fields with the same tag are always together.

MARC::Rec::getfields is identical to getfields, but ignores any record
specification in the template.

=head2 marc_count()

Returns the total number of records in a MARC object. This method was
previously named B<length()>, but that conflicts with the Perl built-in
of the same name. Use the new name, the old one is deprecated and will
disappear shortly.

    $length=$x->marc_count();

=head2 getfirstvalue()

getfirstvalue will return the first value of a field or subfield or
indicator or i12 in a particular record found in the MARC object. It
does not depend on the index being up to date.

MARC::Rec::getfirstvalue is identical to getfields, but ignores any record
specification in the template.

=head2 getvalue()

This method will retrieve MARC field data from a specific record in the MARC object. getvalue() takes four parameters: I<record>, I<field>, I<subfield>, and I<delimiter>. Since a single MARC record could contain several of the fields or subfields the results are returned to you as an array. If you only pass I<record> and I<field> you will be returned the entire field without subfield delimiters. Optionally you can use I<delimiter> to specify what character to use for the delimiter, and you will also get the subfield delimiters. If you also specify I<subfield> your results will be limited to just the contents of that subfield. Repeated subfield occurances will end up in separate array elements in the order in which they were read in. The I<subfield> designations C<'i1', 'i2' and 'i12'> can be used to get indicator(s).

        #get the 650 field(s)
    @results = $x->getvalue({record=>'1',field=>'650'}); 

	#get the 650 field(s) with subfield delimiters (ie. |x |v etc)
    @results = $x->getvalue({record=>'1',field=>'650',delimiter=>'|'});

        #get all of the subfield u's from the 856 field
    @results = $x->getvalue({record=>'12',field=>'856',subfield=>'u'});

MARC::Rec::getvalue($template) is identical to getvalue, but ignores any record specification.

=head2 unpack_ldr($record)

Returns a ref to a hash version of the record'th LDR.
Installs the ref in $marc as $marc->[$record]{unp_ldr}

    my $rldr = $x->unpack_ldr(1);
    print "Desc is $rldr{Desc}";
    my ($m040) = $x->getvalues({record=>'1',field=>'040'});
    print "First record is LC, let's leave it alone" 
          if $rldr->{'Desc'} eq 'a' && $m040=~/DLC\s*\c_c\s*DLC/; 

The hash version contains the following information:

	Key		000-Pos	length	Function [standard value]
	---     	-------	------	--------
	rec_len		00-04	   5	Logical Record Length
	RecStat		05	   1	Record Status
	Type		06	   1	Type of Record
	BLvl		07	   1	Bibliographic Level
	Ctrl		08	   1
	Undefldr	09-11	   3	[x22]
	base_addr	12-16	   5	Base Address of Data
	ELvl		17	   1	Encoding Level
	Desc		18	   1	Descriptive Cataloging Form
	ln_rec		19	   1	Linked-Record Code
	len_len_field	20	   1	Length "length of field" [4]
	len_start_char	21	   1	Length "start char pos" [5]
	len_impl	22	   1	Length "implementation dep" [0]
	Undef2ldr	23	   1	[0]

MARC::Rec::unpack_ldr() is identical to unpack_ldr, but does not need the record number.

=head2 get_hash_ldr($record)

Takes a record number. Returns a ref to the cached version of the hash ldr if it exists.
Does this *without* overwriting the hash ldr. Allows external code to safely manipulate
hash versions of the ldr.

     my $rhldr = $marc->get_hash_ldr($record);
     return undef unless $rhldr;
     $rhldr->{'Desc'} =~ s/a/b/;
     $ldr = $x->pack_ldr($record);

MARC::Rec::get_hash_ldr() is identical to get_hash_ldr, but does not need the record number.

=head2 pack_ldr($record)

Takes a record number. Updates the appropriate ldr. 

     $marc->[$record]{'unp_ldr'}{'Desc'} =~ s/a/b/;
     my $ldr = $x->pack_ldr($record);
     return undef unless $ldr;

MARC::Rec::pack_ldr() is identical to pack_ldr, but does not need the record number.

=head2 bib_format($record)

Takes a record number. Returns the "format" used in determining the meanings of the fixed fields in 008. Will force update of the ldr based on any existing hash version.

      foreach $record (1..$#$x) {
	    next if $x->bib_format($record) eq 'SERIALS';
		# serials are hard
	    do_something($x->[record]);
      }

MARC::Rec::bib_format() is identical to bib_format, but does not need the record number.

=head2 unpack_008($record)

Returns a ref to hash version of the 008 field, based on the field's value.
Installs the ref as $marc->[$record]{unp_008}

      foreach $record (1..$#$x) {
	    my $rff = $x->unpack_008($record);
	    print "Record $record: Y2K problem possible"
		if ($rff->{'Date1'}=~/00/ or $rff->{'Date2'}=~/00/);
      }

MARC::Rec::unpack_008() is identical to unpack_008, but does not need the record number.

=head2 get_hash_008($record)

Takes a record number. Returns a ref to the cached version of the hash 008 if it exists.
Does this *without* overwriting the hash 008. Allows external code to safely manipulate
hash versions of the 008.

     my $rh008 = $marc->get_hash_008($record);
     return undef unless $rh008;
     $rh008->{'Date1'} =~ s/00/01/;
     my $m008 = $x->pack_008($record);
     return undef unless $m008;

MARC::Rec::get_hash_008() is identical to get_hash_008, but does not need the record number.

=head2 pack_008($record)

Takes a record number and updates the appropriate 008. Will force update of the
ldr based on any existing hash version.

      foreach $record (1..$#$x) {
	    my $rff = $x->unpack_008($record);
	    $rff->{'Date1'}='2000';
	    print "Record:$record Y2K problem created";
	    $x->pack_008($record);
	    # New value is in the 008 field of $record'th marc
      }

MARC::Rec::pack_008() is identical to pack_008, but does not need the record number.

=head2 deletefirst()

deletefirst() takes a template. It deletes the field data for a first
match, using the template and leaves the rest alone. If the template
has a subfield element it deletes based on the subfield information in
the template. If the last subfield of a field is deleted,
deletefirst() also deletes the field.  It complains about attempts to
delete indicators.  If there is no match, it does nothing. Deletefirst
also rebuilds the map if the template asks for that
$do_rebuild_map. Deletefirst returns the number of matches deleted
(that would be 0 or 1), or undef if it feels grumpy (i.e. carps).

MARC::Rec::deletefirst($template) is identical to deletefirst, but ignores any record number
specified by $template.

Most use of deletefirst is expected to be by MARC::Tie.


=head2 deletemarc()

This method will allow you to remove a specific record, fields or subfields from a MARC object. Accepted parameters include: I<record>, I<field> and I<subfield>. Note: you can use the .. operator to delete a range of records. deletemarc() will return the number of items deleted (be they records, fields or subfields). The I<record> parameter is optional. It defaults to all user records [1..$#marc] if not specified.

        #delete all the records in the object
    $x->deletemarc();

        #delete records 1-5 and 7 
    $x->deletemarc({record=>[1..5,7]});

        #delete all of the 650 fields from all of the records
    $x->deletemarc({field=>'650'});

        #delete the 110 field in record 2
    $x->deletemarc({record=>'2',field=>'110'});

        #delete all of the subfield h's in the 245 fields
    $x->deletemarc({field=>'245',subfield=>'h'});

=head2 updatefirst()

updatefirst() takes a template, and an array from
$marc->[recnum]{array}. It replaces/creates the field data for a first
match, using the template and the array, and leaves the rest alone. If
the template has a subfield element, (this includes indicators) it
ignores all other information in the array and only updates/creates
based on the subfield information in the array. If the template has no
subfield information then indicators are left untouched unless a new
field needs to be created, in which case they are left blank.

MARC::Rec::updatefirst($template) is identical to deletefirst, but ignores any record number
specified by $template.

Most use of updatefirst() is expected to be from MARC::Tie.
It does not currently provide a useful return value.

=head2 updatefields()

updatefields() takes a template which specifies recnum, a
$do_rebuild_map and a field (needs the field in case $rafields->[0] is
empty). It also takes a ref to an array of fieldrefs formatted like
the output of getfields(), and replaces/creates the field data. It
assumes that it should replace the fields with the first tag in the
fieldrefs. It calls rebuild_map() if $do_rebuild_map.

    #Let's kill the *last* 500 field.
    my $loc500 = {record=>1,field=>500,rebuild_map=>1};
    my @rfields = $x->getfields($loc500);
    pop @rfields;
    $x->updatefields($loc500,\@rfields);

=head2 getmatch()

getmatch() takes a subfield code (can be an indicator) and a fieldref.
Returns 0 or a ref to the value to be updated.
    
    #Let's update the value of i2 for the *last* 500
    my $loc500 = {record=>1,field=>500,rebuild_map=>1};
    my @rfields = $x->getfields($loc500);
    my $rvictim = pop @rfields;
    my $rval = getmatch('i2',$rvictim);
    $$rval = "4" if $rval;

MARC::Rec::getmatch($subf,$rfield) is identical to getmatch;

=head2 insertpos()

insertpos() takes a subfield code (can not be an indicator), a value,
and a fieldref. Updates the fieldref with the first place that the
fieldref can match. Assumes there is no exact subfield match in
$fieldref.

    #Let's update the value of subfield 'a' for the *last* 500
    my $value = "new info";
    my $loc500 = {record=>1,field=>500,rebuild_map=>1};
    my @rfields = $x->getfields($loc500);
    my $rvictim = pop @rfields;
    my $rval = getmatch('a',$rvictim);
    if ($rval) {
        $$rval = $value ;
    } else {
	$x->insertpos('a',$value,$rvictim);
    }

MARC::Rec::insertpos($subf,$value,$rfield) is identical to insertpos;

=head2 selectmarc()

This method will select specific records from a MARC object and delete the rest. You can specify both individual records and ranges of records in the same way as deletemarc(). selectmarc() will also return the number of records deleted. 

    $x->selectmarc(['3']);
    $y=$x->selectmarc(['4','21-50','60']);
    print "$y records selected!";

=head2 searchmarc()

This method will allow you to search through a MARC object, and retrieve record numbers for records that matched your criteria. You can search for: 1) records that contain a particular field, or field and subfield ; 2) records that have fields or subfields that match a regular expression ; 3) and records that have fields or subfields that B<do not> match a regular expression. The record numbers are returned to you in an array which you can then use with deletemarc(), selectmarc() and output() if you want.

=over 4

=item *

1) Field/Subfield Presence:

    @records=$x->searchmarc({field=>"245"});
    @records=$x->searchmarc({field=>"245",subfield=>"a"});

=item *

2) Field/Subfield Match:

    @records=$x->searchmarc({field=>"245",
			     regex=>"/huckleberry/i"});
    @records=$x->searchmarc({field=>"260",subfield=>"c",
			     regex=>"/19../"});

=item *

3) Field/Subfield NotMatch:

    @records=$x->searchmarc({field=>"245",
			     notregex=>"/huckleberry/i"});
    @records=$x->searchmarc({field=>"260",
			     subfield=>"c",notregex=>"/19../"});

=back

=head2 createrecord()

You can use this method to initialize a new record. It only takes one optional parameter, I<leader> which sets the 24 characters in the record leader: see http://lcweb.loc.gov/marc/bibliographic/ecbdhome.html for more details on the leader. Note: you do not need to pass character positions 00-04 or 12-16 since these are calculated by MARC.pm if outputting to MARC you can assign 0 to each position. If no leader is passed a default USMARC leader will be created of "00000nam  2200000 a 4500". createrecord() will return the record number for the record that was created, which you will need to use later when adding fields with addfield(). Createrecord now makes the new record an instance of an appropriate MARC::Rec subclass. 

    use MARC;
    my $x = new MARC;
    $record_number = $x->createrecord();
    $record_number = $x->createrecord({leader=>
			    	       "00000nmm  2200000 a 4500"});

MARC::Rec::createrecord($leader) returns an instance of a suitable subclass of MARC::Rec.

=head2 getupdate()

The B<getupdate()> method returns an array that contains the contents of a fieldin a defined order that permits restoring the field after deleting it. This permits changing only individual subfields while keeping other data intact. If a field is repeated in the record, the resulting array separates the field infomation with an element containing "\036" - the internal field separator which can never occur in real MARC data parameters. A non-existing field returns C<undef>. An example will make the structure clearer. The next two MARC fields (shown in ASCII) will be described in the following array:

		246  30  $aPhoto archive
		246  3   $aAssociated Press photo archive

    my $update246 = {field=>'246',record=>2,ordered=>'y'};
	# next two statements are equivalent
    my @u246 = $x->getupdate($update246);
	# or
    my @u246 = ('i1','3','i2','0',
		'a','Photo archive',"\036",
                'i1','3','i2',' ',
		'a','Associated Press photo archive',"\036");
	
After making any desired modifications to the data, the existing field can be replaced using the following sequence (for non-repeating fields):

    $x->deletemarc($update246));
    my @records = ();
    foreach my $y1 (@u246) {
        last if ($y1 eq "\036");
    	push @records, $y1;
    }
    $x->addfield($update246, @records);

=head2 updaterecord()

The updaterecord() method is a more complete version of the preceeding sequence with error checking and the ability to split the update array into multiple addfield() commands when given repeating fields. It takes an array of key/value pairs, formatted like the output of getupdate(), and replaces/creates the field data. For repeated tags, a "\036" element is used to delimit data into separate addfield() commands. It returns the number of successful addfield() commands or C<undef> on failure.

    $repeats = $x->updaterecord($update246, @u246);	# same as above

=head2 addfield()

This method will allow you to addfields to a specified record. The syntax may look confusing at first, but once you understand it you will be able to add fields to records that you have read in, or to records that you have created with createrecord(). addfield() takes six parameters: I<record> which indicates the record number to add the field to, I<field> which indicates the field you wish to create (ie. 245), I<i1> which holds one character for the first indicator, I<i2> which holds one character for the second indicator, and I<value> which holds the subfield data that you wish to add to the field. addfield() will automatically try to insert your new field in tag order (ie. a 500 field before a 520 field), however you can turn this off if you set I<ordered> to "no" which will add the field to the end. Here are some examples:

    $y = $x->createrecord(); # $y will store the record number created

    $x->addfield({record=>"$y", field=>"100", i1=>"1", i2=>"0",
		  value=> [a=>"Twain, Mark, ", d=>"1835-1910."]});

    $x->addfield({record=>"$y", field=>"245",
		  i1=>"1", i2=>"4", value=>
                 [a=>"The adventures of Huckleberry Finn /",
                  c=>"Mark Twain ; illustrated by E.W. Kemble."]});

This example intitalized a new record, and added a 100 field and a 245 field. For some more creative uses of the addfield() function take a look at the I<EXAMPLES> section. The I<value> parameters, including I<i1> and I<i2>, can be specified using a separate array. This permits restoring field(s) from the array returned by the B<getupdate()> method - either as-is or with modifications. The I<i1> and I<i2> key/value pairs must be first and in that order if included.

	# same as "100" example above
    my @v100 = 'i1','1','i2',"0",'a',"Twain, Mark, ",
	       'd',"1835-1910.";
    $x->addfield({record=>"$y", field=>"100"}, @v100);

=head2 add_005s()

Add_005s takes a specification of records (defaults to everything) and 
updates the indicated records with updated 005 fields (date of last transaction).

=head2 output()

Output is a multifunctional method for creating formatted output from a MARC object. There are three parameters I<file>, I<format>, I<records>. If I<file> is specified the output will be directed to that file. It is important to specify with E<gt> and E<gt>E<gt> whether you want to create or append the file! If no I<file> is specified then the results of the output will be returned to a variable (both variations are listed below). 

The MARC standard includes a control field (005) that records the date of last automatic processing. This is implemented as a side-effect of output() to a file or if explicitly requested via a add_005s field of the template. The current time is stamped on the records indicated by the template.

Valid I<format> values currently include usmarc, marcmaker, ascii, html, urls, and isbd. The optional I<records> parameter allows you to pass an array of record numbers which you wish to output. You must pass the array as a reference, hence the forward-slash in \@records below. If you do not include I<records> the output will default to all the records in the object. 

The I<lineterm> parameter can be used to override the line-ending default
for any of the formats. I<MARCMaker> defaults to CRLF (the format was
originally released for MS-DOS). The others use '\n' as the default.

With the I<MARCMaker> format, a I<charset> parameter accepts a hash-reference
to a user supplied character translation table. The "ustext.txt" table supplied
with the LoC. MARCBreaker utility is used internally as the default. You can
use the B<ustext_default> method to get a hash-reference to it if you only
want to modify a couple of characters. See example below.

The I<MARCMaker> Specification requires that long lines be split to less
than 80 columns. While that behavior is the default, the I<nolinebreak>
parameter can override it and the resulting output will be much like the
I<ascii> format.

MARC::Rec::output($template) is the same as output except that ignores
record number(s) and only outputs its caller. (E.g., with $format
eq 'urls' it does not output html header and footer information.)

=over 4

=item *

MARC

    $x->output({file=>">mymarc.dat",'format'=>"usmarc"});
    $x->output({file=>">mymarc.dat",'format'=>"usmarc",
		records=>\@records});
    $y=$x->output({'format'=>"usmarc"}); #put the output into $y

=item *

MARCMaker

    $x->output({file=>">mymarcmaker.mkr",'format'=>"marcmaker"});
    $x->output({file=>">mymarcmaker.mkr",'format'=>"marcmaker",
		records=>\@records});
    $y=$x->output({'format'=>"marcmaker"}); #put the output into $y

    $x->output({file=>"brkrtest.mkr",'format'=>"marcmaker",
		nolinebreak=>"1", lineterm=>"\n",
		charset=>\%char_hash});


=item *

ASCII

    $x->output({file=>">myascii.txt",'format'=>"ascii"});
    $x->output({file=>">myascii.txt",'format'=>"ascii",
		records=>\@records});
    $y=$x->output({'format'=>"ascii"}); #put the output into $y

=item *

HTML

The HTML output method has some additional parameters. I<fields> which if set to "all" will output all of the fields. Or you can pass the tag number and a label that you want to use for that tag. This will result in HTML output that only contains the specified tags, and will use the label in place of the MARC code.

    $x->output({file=>">myhtml.html",'format'=>"html",
		fields=>"all"});

        #this will only output the 100 and 245 fields, with the 
	#labels "Title: " and "Author: "
    $x->output({file=>">myhtml.html",'format'=>"html",
                245=>"Title: ",100=>"Author: "});    

    $y=$x->output({'format'=>"html"});

If you want to build the HTML file in stages, there are four other I<format> values available to you: 1) "html_header", 2) "html_start", 3) "html_body", and 4) "html_footer". Be careful to use the >> append when adding to a file though!

    $x->output({file=>">myhtml.html",
		'format'=>"html_header"}); # Content-type
    $x->output({file=>">>myhtml.html",
		'format'=>"html_start"});  # <BODY>
    $x->output({file=>">>myhtml.html",
		'format'=>"html_body",fields=>"all"});
    $x->output({file=>">>myhtml.html",
		'format'=>"html_footer"});

=item *

URLS

    $x->output({file=>"urls.html",'format'=>"urls"});
    $y=$x->output({'format'=>"urls"});

=item *

ISBD

An experimental output format that attempts to mimic the ISBD.

    $x->output({file=>"isbd.txt",'format'=>"isbd"});
    $y=$x->output({'format'=>"isbd"});

=item *

XML

Roundtrip conversion between MARC and XML is handled by the subclass 
MARC::XML. MARC::XML is available for download from the CPAN.


=back

=head2 usmarc_default()

This method returns a hash reference to a translation table between mnemonics
delimited by curly braces and single-byte character codes in the MARC record.
Multi-byte characters are not currently supported. The hash has keys of the
form '{esc}' and values of the form chr(0x1b). It is used during MARCMaker
input.

    my %inc = %{$x->usmarc_default()};
    printf "dollar = %s\n", $inc{'dollar'};	# prints '$'
    $inc{'yen'} = 'Y';
    $x->openmarc({file=>"makrbrkr.mrc",'format'=>"marcmaker",
		  charset=>\%inc});

MARC::Rec::usmarc_default is identical to usmarc_default;

=head2 ustext_default()

This method returns a hash reference to a translation table between single-byte
character codes and mnemonics delimited by curly braces. Multi-byte characters
are not currently supported. The hash has keys of the form chr(0x1b) and
values of the form '{esc}'. It is used during MARCMaker output.

    my %outc = %{$x->ustext_default()};
    printf "dollar = %s\n", $outc{'$'};	# prints '{dollar}'
    $outc{'$'} = '{uscash}';
    printf "dollar = %s\n", $outc{'$'};	# prints '{uscash}'
    $y = $x->output({'format'=>"marcmaker", charset=>\%outc});

MARC::Rec::ustext_default is identical to ustext_default;

=head2 as_string()

As_string() takes no paramaters and returns a (Unix) newline separated version of the record.

  Format is: $tag<SPACE>$i1$i2<SPACE>$subfields
  where $subfields are separated by "\c_" binary subfield indicators.
  Tag 000 is ldr.

Subclasses may need to override this format. If so, 
they should override from_string.

=head2 from_string()

From_string() takes a string paramater and updates the calling record's {array} information.
It assumes the string is formatted like the output of as_string(). 

=head1 EXAMPLES

Here are a few examples to fire your imagination.

=over 4

=item * 

This example will read in the complete contents of a MARC file called "mymarc.dat" and then output it as a MARCMaker file called "mymkr.mkr".

    #!/usr/bin/perl
    use MARC;
    $x = MARC->new("mymarc.dat","marcmaker");
    $x->output({file=>"mymkr.mkr",'format'=>"marcmaker");

=item *

The MARC object occupies a fair number of working memory, and you may want to do conversions on very large files. In this case you will want to use the openmarc(), nextmarc(), deletemarc(), and closemarc() methods to read in portions of the MARC file, do something with the record(s), remove them from the object, and then read in the next record(s). This example will read in one record at a time from a MARC file called "mymarc.dat" and convert it to a MARC Maker file called "myfile.mkr".

    #!/usr/bin/perl
    use MARC;
    $x = new MARC;
    $x->openmarc({file=>"mymarc.dat",'format'=>"usmarc"});
    while ($x->nextmarc(1)) {
	$x->output({file=>">>myfile.mkr",'format'=>"marcmaker"});
	$x->deletemarc(); #empty the object for reading in another
    }        

=item *

Perhaps you have a tab delimited text file of data for online journals you have access to from Dow Jones Interactive, and you would like to create a batch of MARC records to load into your catalog. In this case you can use createrecord(), addfield() and output() to create records as you read in your delimited file. When you are done, you then output to a file in USMARC.

    #!/usr/bin/perl
    use MARC;
    $x = new MARC;
    open (INPUT_FILE, "delimited_file");
    while ($line=<INPUT_FILE>) {
        ($journaltitle,$issn) = split /\t/,$line;
        $num=$x->createrecord();
        $x->addfield({record=>$num, 
                      field=>"022", 
                      i1=>" ", i2=>" ", 
                      value=>$issn});
        $x->addfield({record=>$num, 
                      field=>"245", 
                      i1=>"0", i2=>" ", 
                      value=>[a=>$journaltitle]});
        $x->addfield({record=>$num, 
                      field=>"260", 
                      i1=>" ", i2=>" ", 
                      value=>[a=>"New York (N.Y.) :",
			      b=>"Dow Jones & Company"]});
	$x->addfield({record=>$num,
		      field=>"710",
		      i1=>"2", i2=>" ",
		      value=>[a=>"Dow Jones Interactive."]});
	$x->addfield({record=>$num,
		      field=>"856",
		      i1=>"4", i2=>" ",
		      value=>[u=>"http://www.djnr.com",
			      z=>"Connect"]});
    }
    close INPUT_FILE;
    $x->output({file=>">dowjones.mrc",'format'=>"usmarc"})

=item * 

Perhaps you have periodicals coming in that you want to order by 
location and then title. MARC::Rec's get you out of some array indexing.

#!/usr/bin//perl
use MARC 1.03;

my @newmarcs=@$marc[1..$#$marc]; # array slice.
my @sortmarcs = sort by_loc_oclc @newmarcs;
@marc[1..$#$marc] = @sortmarcs;

sub by_loc_title {
    my ($aloc,$atitle) = loc_title($a);
    my ($bloc,$btitle) = loc_title($b);
    return  $aloc cmp $bloc 
	          ||
	  $atitle cmp $btitle;
}

sub loc_title {
    my ($rec)=@_;
    my $n049 = $rec->getfirstvalue({field=>040});
    my ($loc) = $n049=~/(ND\S+)/; # Or the first two letters of your OCLC
                                  # location.

    my $title = $rec->getfirstvalue({field=>100,delimiter=>" "});

    return ($loc,$title);
}

=back

=head1 NOTES

Please let us know if you run into any difficulties using MARC.pm--we'd be
happy to try to help. Also, please contact us if you notice any bugs, or
if you would like to suggest an improvement/enhancement. Email addresses 
are listed at the bottom of this page.

Development of MARC.pm and other library oriented Perl utilities is conducted
on the Perl4Lib listserv. Perl4Lib is an open list and is an ideal place to
ask questions about MARC.pm. Subscription information is available at
http://www.vims.edu/perl4lib

Two global boolean variables are reserved for test and debugging. Both are
"0" (off) by default. The C<$TEST> variable disables internal error messages
generated using I<Carp>. It also overrides the date_stamp in the "005" field
with a constant "19960221075055.7". It should only be used in the automatic
test suite. The C<$DEBUG> variable adds verbose diagnostic messages. Since
both variables are used only in testing, I<MARC::Rec> uses C<$MARC::TEST>
and C<$MARC::DEBUG> rather than define a second pair.

=head1 AUTHORS

Chuck Bearden cbearden@rice.edu

Bill Birthisel wcbirthisel@alum.mit.edu

Derek Lane dereklane@pobox.com

Charles McFadden chuck@vims.edu

Ed Summers ed@cheetahmail.com

=head1 SEE ALSO

perl(1), http://lcweb.loc.gov/marc

=head1 COPYRIGHT

Copyright (C) 1999,2000, Bearden, Birthisel, Lane, McFadden, and Summers.
All rights reserved. This module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself. 23 April 2000.
Portions Copyright (C) 1999,2000, Duke University, Lane.

=cut
