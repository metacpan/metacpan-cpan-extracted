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
our $verbose    = 1;
our ($help,$version);


our %log   = (level=>'TRACE', rootLevel=>'FATAL');
our $file  = undef;
our $class = undef;
our %opts  = qw();

our $outfile = '-';

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O options
	   'class|c=s' => \$class,
	   'option|opt|O=s' => \%opts,
	   'output|out|o=s' => \$outfile,

	   ##-- general
	   'log-level|level|ll=s' => sub { $log{level} = uc($_[1]); },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>"No input file(s) specified"}) if (!@ARGV);

if ($version || $verbose >= 2) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog();

##-- input file
my $infile = shift(@ARGV);
if (!$class && -f "$infile.hdr") {
  ##-- no class specified; try to read header
  my $hdr = DiaColloDB::Utils::loadJsonFile("$infile.hdr");
  $class = $hdr->{class};
}
die("$0: no -class specified and not found in header") if (!$class);

##-- sanitize class
$class = "DiaColloDB::$class" if ($class !~ /^DiaColloDB::/ && !UNIVERSAL::can($class,'new'));
die("$0: no 'new' method for class '$class'") if (!UNIVERSAL::can($class,'new'));

##-- load object
my $obj = $class->new(%opts)
  or die("$0: could not create object of class '$class' for '$infile': $!");
$obj->open($infile)
  or die("$0: could not open '$infile' via object of class '$class': $!");

##-- dump
$obj->info("saving object to '$outfile'");
$obj->saveTextFile($outfile)
  or die("$0: saveTextFile() failed for object of class '$class' from '$infile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

dcdb-dump.perl - dump a text representation of a DiaColloDB sub-index

=head1 SYNOPSIS

 dcdb-dump.perl [OPTIONS] OBJFILE

 General Options:
   -help
   -version
   -verbose LEVEL

 Dump Options:
   -log-level LEVEL     ##-- set log-level (default=TRACE)
   -class CLASS         ##-- specify object class (default=guess from header)
   -option OPT=VALUE    ##-- set object option
   -output OUTFILE      ##-- specify output file (default=STDOUT)

=cut

###############################################################
## OPTIONS
###############################################################
=pod

=head1 OPTIONS

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

=item -verbose LEVEL

Set verbosity level to LEVEL.  Default=1.

=back

=cut


###############################################################
# Other Options
###############################################################
=pod

=head2 Other Options

=over 4

=item -someoptions ARG

Example option.

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

perl(1).

=cut
