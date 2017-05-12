=head1 NAME

MARC::Errorchecks -- Collection of MARC 21/AACR2 error checks

=head1 DESCRIPTION

Module for storing MARC error checking subroutines,
based on MARC21, AACR2, and LCRIs.
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

=head1 SEE ALSO

MARC::Record -- Required for this module to work.

MARC::Lint -- In the MARC::Record distribution and basis for this module.

MARC::Lintadditons -- Extension of MARC::Lint for checks involving individual tags.
(vs. cross-field checking covered in this module).
Available at http://home.inwave.com/eija (and may be merged into MARC::Lint).

MARC pages at the Library of Congress (http://www.loc.gov/marc)

Anglo-American Cataloging Rules, 2nd ed., 2002 revision, plus updates.

Library of Congress Rule Interpretations to AACR2R.

MARC Report (http://www.marcofquality.com) -- More full-featured commercial program for validating MARC records.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this module is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2003-2012

=cut
