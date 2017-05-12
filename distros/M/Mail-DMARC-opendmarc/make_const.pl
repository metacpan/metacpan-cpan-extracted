# Note from author (SHARI)
# You will only need this if you are modifying the module,
# specifically to upgrade to a newer libopendmarc version
# After you build the lib/Mail/DMARC/opendmarc/Constants/C/Symbols.pm, 
# edit the file and add a $VERSION (align it to the module's version)
# to make sure the CPAN indexer doesn't get confused.
# e.g.      our $VERSION = '0.11';
# Read through the code and adjust as and if needed.

  use C::Scan::Constants;

  # Where the dmarc.h header file is located
  my @hdr_files = (
      "/home/shari/local/include/opendmarc/dmarc.h"
  );

  ## Slurp a list of constant information from C headers
  my @constants = extract_constants_from( @hdr_files );

  ## Version specific workaround - libopendmarc 1.1.1 and possiblity later
  ## the #define OPENDMARC_STATUS_T int in dmarc.h
  ## confuses C::Scan::Constants which will try to create
  ## a constant definition for 'int' and cause C compiler to fail.
  ## Kludgy workaround follows
  my @new_constants;
  foreach $const (@constants) {
      push (@new_constants, $const) unless $const eq 'OPENDMARC_STATUS_T';
  }
  @constants = @new_constants;
  ## Workaround end
  
  ## Create the C, XS, and pure-Perl machinery needed to
  ## provide automagical access to C constants at runtime.
  write_constants_module( "Mail::DMARC::opendmarc", @constants );

