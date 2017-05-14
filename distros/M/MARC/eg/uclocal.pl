#!/usr/bin/perl -w

  # The following example is an expanded version of "addlocal.pl" that
  # checks and fixes existing records in addition to processing new ones.
  # It looks for a call number subfield 'h' of each 852 field (#852.h).
  # It also checks #900.a and #999.f for the data. It then converts the
  # call number fields to upper case and confirms they are all identical.
  # For mismatches and missing 852 data, the records are not modified,
  # but an ascii version is written so the librarian can determine what
  # is correct. Missing 900 and 999 data is created. An ascii version of
  # the altered records is written for checking. This is a somewhat
  # contrived example. But it shows what can be done with manipulating
  # field data and using option templates.

use MARC 0.98;
use strict;

my $infile = "specials.001";
my $outfile = "output.004";	# results in usmarc format
my $outtext = "output5.txt";	# original input in ascii for ok callno.
my $outtext2 = "output6.txt";	# changed records in ascii
my $outtext3 = "output7.txt";	# invalid or mismatched records in ascii
my $outtext4 = "output8.txt";	# ascii for all ok callno (change or not)
unlink $outfile, $outtext, $outtext2, $outtext3, $outtext4;

  # This subroutine takes an array of all the call numbers found. It
  # returns an upper-cased version if all compare or '' if not

sub check_callno {
    my $num1 = uc(shift);
    foreach (@_) {
	return '' unless ($num1 eq uc($_));
    }
    return $num1;
}

  # This subroutine does most of the dirty work. There are four required
  # parameters: $marc, $template, $subfield, and $value. It will return
  # "undef" unless all four are specified. Zero (0 or "0") is a possible
  # $subfield or $value. Blank ('') can be used for the $value.

sub fix_subfield {
    my $marc = shift || return;
    my $template = shift || return;
    my $subfield = shift;
    my $value = shift;
    return unless (defined $subfield and defined $value);
    my $altered = 0;

  # If the $subfield already exists, get the data in a format suitable
  # for making updates. Note the use of $template.

    my ($found) = $marc->searchmarc($template);
    if (defined $found) {
        my @u = $marc->getupdate($template);
        my @f = ();
        my $ff;
        my $fixed = 0;

  # $fixed accounts for the situation when the call number may be present
  # in some of the 852 fields, but not all of them. $fixed gets set when
  # the $subfield is found within a single field. If processing reaches
  # the end of the field (the "\036" delimiter) without $fixed, then the
  # $subfield and $value are appended to that field.

        while (@u) {
	    last unless defined ($ff = shift @u);
	    if ($ff eq "\036") {
	        unless ($fixed) {
	            push @f, $subfield, $value;
	            $altered++;
	        }
	        push @f, $ff;
    	        $fixed = 0;
	        next;
	    }
	    push @f, $ff;

  # All subfields that don't match out target just get copied.

	    unless ($subfield eq $ff) {
	        push @f, shift @u;
	        next;
	    }
	    last unless defined ($ff = shift @u);

  # Fix the target if necessary and set $altered if anything changed.

	    if ($value eq $ff) {
	        push @f, $ff;
	    }
	    else {
	        $altered++;
	        push @f, $value;
	    }
	    $fixed++;
        }

  # Actually fix the record if required. Again note the use of $template.

	if ($altered) {
	    $marc->updaterecord ($template, @f)
		|| warn "update failed: $template->{field}, $subfield\n";
	}
    }

  # This next part is tricky. If fix_subfield is called with just the
  # four required parameters, you bypass the next step. The preceeding
  # part is run if searchmarc() finds the field specified in the
  # $template. But if the field does not exist, and there are optional
  # parameters in the call to fix_subfield, those parameters are used
  # as a series of subfields for an addfield(). In plain language, you
  # can tell fix_subfield what to add if the field doesn't exist.

    elsif (@_) {
        $marc->addfield($template, @_)
		|| warn "addfield failed: $template->{field}, $subfield\n";
	$altered++;
    }
    return $altered;
}

  # The $template hashes for this example:

my $loc852 = {record=>1, field=>'852', ordered=>'y'};
my $loc900 = {record=>1, field=>'900', ordered=>'y'}; 
my $loc999 = {record=>1, field=>'999', ordered=>'n'};

  # The create_if_not_found field specifications:
 
my @default900 = ('i1',' ','i2',' ','a');
my @default999 = ('i1',' ','i2',' ','c','wL70','d','AR Clinton PL','f');

my $invalid = 0;
my $updated = 0;
my $totalcount = 0;
my $x = MARC->new;
$x->openmarc({file=>$infile,'format'=>"usmarc"}) || die;

  # We process records one at a time for this operation. Multiple 852 fields
  # are legal (for multiple copies).

while ($x->nextmarc(1)) {
    my $change = 0;
    my @callno = $x->getvalue($loc852,'subfield','h');

  # But multiple 900 and 999 fields are not permitted. So we force a
  # miscompare if we discover one.

    my ($from900, $dup900) = $x->getvalue($loc900,'subfield','a');
    if (defined $from900) { push @callno, $from900; }
    if (defined $dup900) { push @callno, ''; }
    my ($from999, $dup999) = $x->getvalue($loc999,'subfield','f');
    if (defined $from999) { push @callno, $from999; }
    if (defined $dup999) { push @callno, ''; }
    
  # We now have an array of all the call numbers found. The subroutine
  # returns an upper-cased version if all compare or '' if not.

    my $callno = check_callno(@callno);

  # Write a "good" result back to everywhere that it should be. Keep track
  # of which records were modified. And notice that a $template conveys
  # a lot of repeated information.

    if ($callno) {
        $x->output({file=>">>$outtext",'format'=>"ascii"});

  # $outtext is a "before" ascii file to compare changes with the "after"
  # ascii file $outtext4.

        if (fix_subfield($x,$loc852,'h',"$callno")) {
	    $change++;
        }

  # The 852 subfield passes just the four required parameters. Hence
  # nothing is added if the 852 field is missing.

        if (fix_subfield($x,$loc900,'a',"$callno",@default900,"$callno")) {
	    $change++;
        }

  # The 900 and 999 fields are created with default values if they
  # do not already exist.

        if (fix_subfield($x,$loc999,'f',"$callno",@default999,"$callno")) {
	    $change++;
        }
        $x->output({file=>">>$outfile",'format'=>"usmarc"});
        $x->output({file=>">>$outtext2",'format'=>"ascii"}) if $change;
        $x->output({file=>">>$outtext4",'format'=>"ascii"});
	$updated++ if $change;
    }

  # Write the records with invalid or mismatched call numbers. In this
  # example, they go into the same usmarc format file $outfile.

    else {
        $x->output({file=>">>$outfile",'format'=>"usmarc"});
        $x->output({file=>">>$outtext3",'format'=>"ascii"});
	$invalid++;
    }
    $x->deletemarc(); #empty the object for reading in another
    $totalcount++;
}

  # We write all the records to the output file in MARC format. The ascii
  # output in $outtext3 gives the librarian both a list of records
  # requiring manual call number assignment/resolution and all the Title,
  # Author, Publication and related data needed to assign location based
  # on standard references. For checking, we write all the modified
  # records to $outtext2.

    print "\nprocessed $totalcount records\n";
    print "$updated had call numbers which were changed\n";
    print "$invalid had missing or invalid call numbers\n";

