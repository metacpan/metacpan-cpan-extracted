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
our %ioargs       = (encoding=>'UTF-8');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (!@ARGV);
our $ttout = Lingua::TT::IO->toFile($outfile,%ioargs)
    or die("$0: open failed for '$outfile': $!");

my ($sraw);
foreach my $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for '$infile': $!");
  $doc = $ttin->getDocument;
  $ttin->close();

  $ttout->putLines([grep {$_ !~ /^\s*$/} map {$_->rawString} @$doc]);
}
$ttout->close();

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-sents2raw.perl - heuristically extract raw sentence text from .tt file(s)

=head1 SYNOPSIS

 tt-sents2raw.perl OPTIONS [TT_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)
   -encoding ENCODING   ##-- I/O encoding (default: UTF-8)

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
