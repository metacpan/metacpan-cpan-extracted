#!/usr/bin/perl

# The following example automates a simple but time-consuming task for
# a librarian. Booksellers commonly include a disk containing standard
# bibliographical and catalogging data with their shipments to libraries.
# The data is in MAchine Readable Catalog (MARC) format. The MARC.pm
# module creates, reads, updates, and writes that data. Most library
# databases also import from and export into MARC format. But a library
# often must add to the data provided by the booksellers. We are going to
# add the Wisconsin inter-library loan code for the Clinton Public Library
# and the local call number to each MARC record (each catalog item).

# A record consists of a number of tags (data types) and each tag can have
# one or more subfields (data elements). Tags are designated by 3-digit
# identifiers (000-999) corresponding to specific data types (i.e. the 245
# tag is the Title Statement). In this example, we care about the 852 tag
# (Location) subfield 'h' (Dewey or similar Recommended Call Number) and
# the 900 and 999 tags (reserved for "local" use). We plan to append a 999
# field to each record based in part on the 852 tag subfield 'h'. We will
# also print a text listing of any records missing this subfield so the
# librarian can update those manually. Finally, we will insert the call
# number as a 900 tag.

    use MARC 0.93;
    my $infile = "microlif.001";
    my $outfile = "output.002";
    my $outfile2 = "output2.txt";
    my $outtext = "output.txt";
    unlink $outfile, $outtext, $outfile2;

# Your filenames will vary. You probably want absolute pathnames.
# In Clinton, WI, we have a shortcut to the newbooks.d directory and
# use these:
#   my $infile = "a:\\microlif.001";			# floppy from vendor
#   my $outfile = "d:\\microlif.002";			# file to import 
#   my $outfile2 = "d:\\newbooks.d\\updated.txt";	# ascii to check
#   my $outtext = "d:\\newbooks.d\\missing.txt";	# needs attention

    my $count = 0;
    my $missing = 0;    
    $x = MARC->new;
    $x->openmarc({file=>$infile,'format'=>"usmarc"}) || die;

# You may want a more informative failure routine if run from a GUI

# We process records one at a time for this operation. Multiple 852 fields
# are legal (for multiple copies) - the 'h' subfield should be the same.
# But a few percent of incoming materials do not include this subfield.

    while ($x->nextmarc(1)) {
        my ($callno) = $x->getvalue({record=>'1',field=>'852',subfield=>'h'});
	$callno = "|" unless (defined $callno);

# A single 'fill character' ("|" eq 0x7c) is used for none.
# Some vendors don't like "empty" subfields

        $x->addfield({record=>1, 
                      field=>"999", 
                      ordered=>"n", 
                      i1=>" ", i2=>" ", 
                      value=>[c=>"wL70",d=>"AR Clinton PL",f=>"$callno"]});

# Tag 999 subfield 'f' gets the Call Number. The others are constant in this
# example. Tag 999 is the last legal choice, so a simple append is fine.

        $x->addfield({record=>1, 
                      field=>"900", 
                      ordered=>"y", 
                      i1=>" ", i2=>" ", 
                      value=>[a=>"$callno"]});

# Tag 900 subfield 'a' gets the Call Number. Since some records already
# have 9xx tags (e.g. 935), we want 'ordered' (which is also the default).

        $x->output({file=>">>$outfile",'format'=>"usmarc"});
	if ($callno eq "|") {
            $x->output({file=>">>$outtext",'format'=>"ascii",
		lineterm=>"\r\n"});
	    $missing++;
	}
        $x->output({file=>">>$outfile2",'format'=>"ascii",
		lineterm=>"\r\n"});
        $x->deletemarc(); #empty the object for reading in another
	$count++;
    }

# We write all the records to the output file in MARC format. Even the
# incomplete ones at least have added the fixed data. The ascii output
# in $outtext gives the librarian both a list of records requiring manual
# attention and all the Title, Author, Publication and related data needed
# to assign location based on standard references. This demo also writes
# an ascii version of its output as $outfile2 so the final MARC records
# can be viewed with the changes. Since Clinton runs on NT, we specify
# a Notepad-compatible line termination.

    print "\nprocessed $count records\n";
    print "$missing had missing call numbers\n\n";
    print "press <Enter> to continue\n";
    my $junk = <>;

# Allow results to be seen even when run from a GUI.

