#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals

##-- verbosity levels
our $vl_silent = 0;
our $vl_error = 1;
our $vl_warn = 2;
our $vl_info = 3;
our $vl_trace = 4;

our $prog         = basename($0);
our $verbose      = $vl_info;
our $VERSION	  = 0.12;

our $outfile      = '-';
our $txtfile	  = undef;
our %ioargs       = (encoding=>'UTF-8', sentence_text=>0);

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'tt-output|tto|tt|o=s' => \$outfile,
	   'no-tt-output|no-tto|no-tt|nott-output|notto|nott' => sub { undef $outfile },
	   'tt-sentence-text|sentence-text|sentences|stxt|s!' => \$ioargs{sentence_text},
	   ##
	   'text-output|text|txt-output|txt|txo|t=s' => \$txtfile,
	   'no-text-output|no-text|no-txt-output|no-txt|no-txo|no-t|notext-output|notext|notxt-output|notxt|notxo|not' => sub { undef $txtfile },
	   ##
	   'encoding|e=s' => \$ioargs{encoding},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= $vl_trace) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}


##----------------------------------------------------------------------
## messages
sub vmsg {
  my $level = shift;
  print STDERR @_ if ($verbose >= $level);
}
sub vmsg1 {
  my $level = shift;
  vmsg($level, "$prog: ", @_, "\n");
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
our $rttfile = shift // '-';
our $ta = Lingua::TT::TextAlignment->new();

##-- load rtt
vmsg1($vl_trace, "loading RTT file from $rttfile ...");
$ta->loadRttFile($rttfile,%ioargs)
  or die("$prog: load failed for $rttfile: $!");

##-- dump text
if ($txtfile) {
  vmsg1($vl_trace, "dumping text buffer to $txtfile ...");
  $ta->saveTextFile($txtfile,%ioargs)
    or die("$prog: save text failed to $txtfile: $!");
}

if ($outfile) {
  vmsg1($vl_trace, "dumping TT data to $outfile ...");
  $ta->saveTTFile($outfile,%ioargs)
    or die("$prog: save TT failed to $outfile: $!");
}

vmsg1($vl_trace, "done.\n");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-txt-split.perl - split RTT-format raw-text from tokenized data

=head1 SYNOPSIS

 tt-txt-split.perl [OPTIONS] RTT_FILE

 General Options:
   -help
   -version
   -verbose LEVEL

 I/O Options:
   -tt-output FILE      # TT-output file (default: STDOUT)
   -txt-output FILE     # text-output file (default: none)
   -no-tt		# suppress TT-output
   -no-txt		# suppress text-output
   -encoding ENC        # I/O encoding (default: utf8)

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
