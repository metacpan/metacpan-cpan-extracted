#!/usr/bin/perl

  # The following example is an expanded version of "addlocal.pl" that
  # checks and fixes existing records in addition to processing new ones.
  # It first looks for a call number subfield 'h' of the 852 field (#852.h).
  # If missing, it then checks #900.a and #999.f for the data. It puts the
  # call number found into all of these locations including any repeated
  # fields. It will create the locations if necessary.

use MARC 0.95;
my $infile = "specials.001";
my $outfile = "output.003";
my $outtext = "output3.txt";
my $outtext2 = "output4.txt";
unlink $outfile, $outtext, $outtext2;

sub fix_update {
    my $subfield = shift;
    my $value = shift;
    my @f = ();
    my $ff;
    my $altered = 0;
    my $fixed = 0;
    while (@_) {
	last unless defined ($ff = shift);
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
	unless ($subfield eq $ff) {
	    push @f, shift;
	    next;
	}
	last unless defined ($ff = shift);
	push @f, $value;
	$fixed++;
	if ($value ne $ff) { $altered++; }
    }
    return ($altered,@f);
}

my $loc852 = {record=>1, field=>'852', ordered=>'y'};
my $loc900 = {record=>1, field=>'900', ordered=>'y'}; 
my $loc999 = {record=>1, field=>'999', ordered=>'n'}; 

$x = MARC->new;
$x->openmarc({file=>$infile,'format'=>"usmarc"}) || die;

  # We process records one at a time for this operation. Multiple 852 fields
  # are legal (for multiple copies) - the 'h' subfield should be the same.
  # But a few percent of incoming materials do not include this subfield.

while ($x->nextmarc(1)) {
    my $from999 = "";
    my $from900 = "";
    my ($callno) = $x->getvalue($loc852,'subfield','h');
    my $from852 = (1 == scalar $x->getvalue($loc852)) ? $callno : "";
    unless ($callno) {
	    # "" and '0' are not legal call numbers
        $callno = "";
        ($from900) = $x->getvalue($loc900,'subfield','a');
	if ($from900) {
	    $callno = $from900;
	}
	else {
            ($from999) = $x->getvalue($loc999,'subfield','f');
	    if ($from999) {
	        $callno = $from999;
	    }
	}
    }
    my $change = 0;

    my ($found) = $x->searchmarc($loc999);
    if (defined $found) {
        my @m999 = $x->getupdate($loc999);
	my @f999 = fix_update('f', $callno, @m999);
	if (shift @f999) {
	    $change++;
	    $x->updaterecord ($loc999, @f999) || warn "999 update failed\n";
	}
    }
    else {
        $x->addfield($loc999,'i1',' ','i2',' ', 
                     'c','wL70','d','AR Clinton PL','f',"$callno");
	$change++;
    }

    ($found) = $x->searchmarc($loc900);
    if (defined $found) {
        my @m900 = $x->getupdate($loc900);
	my @f900 = fix_update('a', $callno, @m900);
	if (shift @f900) {
	    $change++;
	    $x->updaterecord ($loc900, @f900) || warn "900 update failed\n";
	}
    }
    else {
        $x->addfield($loc900,'i1',' ','i2',' ','a',"$callno");
	$change++;
    }

    if ($callno && not $from852) {
        ($found) = $x->searchmarc($loc852);
        if (defined $found) {
            my @m852 = $x->getupdate($loc852);
	    my @f852 = fix_update('h', $callno, @m852);
	    if (shift @f852) {
	        $change++;
	        $x->updaterecord ($loc852, @f852) || warn "852 update failed\n";
	    }
        }
        else {
            $x->addfield($loc852,'i1','1','i2',' ','h',"$callno");
	    $change++;
        }
    }

    $x->output({file=>">>$outfile",'format'=>"usmarc"});
    $x->output({file=>">>$outtext",'format'=>"ascii"}) unless $callno;
    $x->output({file=>">>$outtext2",'format'=>"ascii"}) if $change;
    $x->deletemarc(); #empty the object for reading in another
}

  # We write all the records to the output file in MARC format. Even the
  # incomplete ones at least have added the fixed data. The ascii output
  # in $outtext gives the librarian both a list of records requiring manual
  # call number assignment and all the Title, Author, Publication and
  # related data needed to assign location based on standard references.
  # For checking, we write all the modified records to $outtext2.

