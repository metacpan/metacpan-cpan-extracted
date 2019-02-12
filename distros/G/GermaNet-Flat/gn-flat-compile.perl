#!/usr/bin/perl -w

use lib qw(.);
use GermaNet::Flat;
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

##==============================================================================
## Globals
our $prog = basename($0);
our $outfile = "-";   ##-- default: stdout

##-- constants: verbosity levels
our $vl_silent   = $GermaNet::Flat::vl_silent;
our $vl_erro     = $GermaNet::Flat::vl_error;
our $vl_warn     = $GermaNet::Flat::vl_warn;
our $vl_info     = $GermaNet::Flat::vl_info;
our $vl_progress = $GermaNet::Flat::vl_progress;
our $vl_debug    = $GermaNet::Flat::vl_debug;
our $verbose     = $vl_progress;

##-- output sub
our $outsub = 'saveText';

##==============================================================================
## Command-line
our ($help);
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=i' => \$verbose,
	   'quiet|q' => sub { $verbose=$GermaNet::Flat::vl_silent; },

	   ##-- I/O
	   'output|out|o=s' => \$outfile,
	   'text|t' => sub {$outsub='saveText'},
	   'binary|bin|b' => sub {$outsub='saveBin'},
	   'bdb|db' => sub {$outsub='saveDB'},
	   'cdb' => sub {$outsub='saveCDB'},
	  );

pod2usage({-exitval=>0,-verbose=>0,}) if ($help);
pod2usage({-exitval=>1,-verbose=>0,-msg=>'No input file(s) specified!'}) if (!@ARGV);

##==============================================================================
## MAIN

my $gn = GermaNet::Flat->new(verbose=>$verbose);
if (@ARGV > 1) {
  $gn->loadXml(@ARGV)
    or die("$prog: failed to load XML file(s): $!");
} else {
  $gn->load($ARGV[0])
    or die("$prog: failed to data from '$ARGV[0]': $!");
}

my $outcode = $gn->can($outsub)
  or die("$prog: unknown output subroutine '$outsub'");

$gn->vmsg($vl_progress, "saving to '$outfile' using method '$outsub' ...");
$outcode->($gn,$outfile)
  or die("$prog: failed to write '$outfile' using output subroutine '$outsub': $!");

$gn->vmsg($vl_progress, 'done.');

__END__

=pod

=head1 NAME

gn-flat-compile.perl - compile GermaNet XML files to flat relational data

=head1 SYNOPSIS

 gn-flat-compile.perl [OPTIONS] GERMANET_DIR_OR_FILE(s)...

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (0<=LEVEL<=1)
  -quiet                 # be silent

 I/O Options:
  -output FILE           # specify output file (default='-' (STDOUT))
  -text                  # select flat text (tt-dict) output mode (default)
  -bin                   # select binary output mode via Storable module
  -bdb                   # select Berkeley DB output mode
  -cdb                   # select CDB output mode (UTF-8 buggy!)

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

Convert GermaNet XML files to flat relational data files.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>jurish@bbaw.deE<gt>

=cut
