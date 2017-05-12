#!/usr/bin/perl -w

use lib qw(. lib dclib);
use DiaColloDB;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use strict;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

##-- program vars
our $prog       = basename($0);
our ($help,$version);

our $dbdir      = undef;
our $outdir     = undef;
our %coldb      = (flags=>'r');
our %export     = (export_sdat=>1, export_cof=>1, export_tdf=>1);
our $dotime     = 1; ##-- report timing?

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'timing|times|time|t!' => \$dotime,
	   'export-sdat|sdat|strings|s!' => \$export{export_sdat},
	   'export-raw|raw!' => sub { $export{export_sdat}=!$_[1]; },
	   'export-cof|cof|c!' => \$export{export_cof},
	   'export-tdf|tdf!' => \$export{export_tdf},
	   'output-directory|outdir|odir|od|o=s' => \$outdir
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>1,-verbose=>0,-msg=>"$prog: ERROR: no DBDIR specified!"}) if (!@ARGV);

if ($version) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog();

##-- open colloc-db
$dbdir = shift(@ARGV);
$dbdir =~ s{/$}{};
my $coldb = DiaColloDB->new(%coldb)
  or die("$prog: failed to create new DiaColloDB object: $!");
$coldb->open($dbdir)
  or die("$prog: DiaColloDB::open() failed for '$dbdir': $!");

##-- export
my $timer = DiaColloDB::Timer->start;
$outdir //= "$dbdir.export";
$coldb->dbexport($outdir,%export)
  or die("$prog: DiaColloDB::export() failed to '$outdir': $!");

##-- cleanup
$coldb->close();

##-- timing
$coldb->info("operation completed in ", $timer->timestr) if ($dotime);

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

dcdb-export.perl - export a text representation of a DiaColloDB diachronic collocation database

=head1 SYNOPSIS

 dcdb-export.perl [OPTIONS] DBDIR

 General Options:
   -help
   -version
   -[no]time            ##-- do/don't report timing information (default=do)

 Export Options:
   -[no]raw             ##-- inverse of -[no]sdat
   -[no]sdat            ##-- do/don't export stringified tuples (*.sdat; default=do)
   -[no]cof             ##-- do/don't export co-frequency files (cof.*; default=do)
   -[no]tdf             ##-- do/don't export term-document files (tdf.*; default=do)
   -output DIR          ##-- dump directory (default=DBDIR.export)

=cut


###############################################################
## DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

dcdb-export.perl
exports the L<DiaColloDB|DiaColloDB> database directory specified
in the L<DBDIR|/DBDIR> argument as text to the
output directory specified by the
L<-output|/-output DIR> option.
Mainly useful for debugging.

=cut


###############################################################
## OPTIONS AND ARGUMENTS
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

###############################################################
# Arguments
###############################################################
=pod

=head2 Arguments

=over 4

=item DBDIR

L<DiaColloDB|DiaColloDB> database directory to be exported.

=back

=cut


###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=back

=cut

###############################################################
# Export Options
###############################################################
=pod

=head2 Export Options

=over 4

=item -raw

=item -noraw

Don't/do export stringified tuples (inverse of -[no]sdat; default=do):

=item -sdat

=item -sdat

Do/don't export stringified tuples (*.sdat; default=do).

=item -[no]cof

Do/don't export co-frequency files (cof.*; default=do).

=item -[no]tdf

Do/don't export term-document files (tdf.*; default=do).

=item -output DIR

Export to directory I<DIR> (default=L<DBDIR|/DBDIR>.export)

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

L<DiaColloDB(3pm)|DiaColloDB>,
L<dcdb-create.perl(1)|dcdb-create.perl>,
L<dcdb-info.perl(1)|dcdb-info.perl>,
L<dcdb-query.perl(1)|dcdb-query.perl>,
perl(1).

=cut
