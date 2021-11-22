#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.13";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $seed         = undef;

our %ioargs = (encoding=>'UTF-8');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- Behavior
	   'seed|srand|s|r=i' => \$seed,

	   ##-- I/O
	   'output-file|outfile|output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## Subs: messages
##----------------------------------------------------------------------

# undef = vmsg($level,@msg)
#  + print @msg to STDERR if $verbose >= $level
sub vmsg {
  my $level = shift;
  print STDERR (@_) if ($verbose >= $level);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV, '-') if (!@ARGV);

##-- read in source file
my ($ttin);
our $doc = undef;
my ($docin);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for file '$infile': $!");
  $docin = $ttin->getDocument;
  $ttin->close();
  if (!defined($doc)) { $doc=$docin; }
  else                { push(@$doc,@$docin); }
}

##-- shuffle sentences
$doc->shuffle(seed=>$seed);

##-- output
$ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
  or die("$0: open failed for output file '$outfile': $!");
$ttout->putDocument($doc);
$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-shuffle.perl - shuffle sentences in .tt file(s)

=head1 SYNOPSIS

 tt-shuffle.perl OPTIONS [FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Randomization Options:
   -srand   SEED           # default: none (perl default)

 I/O Options:
   -outfile  OUTFILE       # default: stdout
   -encoding ENCODING      # set I/O encoding (default=UTF-8)

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

