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

our $nsplits      = 2;
our $outfmt       = 'split.%d';
our $seed         = undef;
our $shuffle	  = 1;

our %ioargs = (encoding=>'UTF-8');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- Selection
	   'n-splits|ns|n=i' => \$nsplits,
	   'seed|srand|s|r=i' => \$seed,
	   'shuffle|shuf|S|randomize|random|rand|R!' => \$shuffle,

	   ##-- I/O
	   'output-format|outfmt|output|o=s' => \$outfmt,
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
our $ntoks = 0;
my ($docin);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for file '$infile': $!");
  $docin = $ttin->getDocument;
  $ttin->close();
  if (!defined($doc)) { $doc=$docin; }
  else                { push(@$doc,@$docin); }
}

##-- totals
$nsents = $doc->nSentences;
$ntoks  = $doc->nTokens;

##-- report
print STDERR
  ("$progname: got $ntoks tokens in $nsents sentences total\n",
  );

##-- shuffle & split
$doc->shuffle(seed=>$seed) if ($shuffle);
our @odocs = $doc->splitN($nsplits,contiguous=>!$shuffle);

##-- output
$outfmt .= ".%d" if ($outfmt !~ /\%(?:\d*\.?\d*)?d/);
our @ofiles = map {sprintf($outfmt,$_)} (0..$#odocs);
#print STDERR "$0: outfmt='$outfmt', ofiles=(", join(' ', map {"'$_'"} @ofiles), ")\n"; ##-- DEBUG
foreach $oi (0..$#odocs) {
  $ttout = Lingua::TT::IO->toFile($ofiles[$oi],%ioargs)
    or die("$0: open failed for output file '$ofiles[$oi]': $!");
  $ttout->putDocument($odocs[$oi]);
  $ttout->close();
}

##-- Summarize
our @nosents = map {$_->nSentences} (@odocs);
our @notoks  = map {$_->nTokens} (@odocs);
our $flen = length($ofiles[$#ofiles]);
our $ilen = length($ntoks);

print STDERR
  ("$progname Summary:\n",
   map {
    sprintf("\t+ %-${flen}s : %${ilen}d sentences (%5.1f %%)   /   %${ilen}d tokens (%5.1f %%)\n",
	    $ofiles[$_],
	    $nosents[$_], 100.0*$nosents[$_]/$nsents,
	    $notoks[$_],  100.0*$notoks[$_]/$ntoks)
  } (0..$#odocs));


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-split-n.perl - split up .t, .tt, and .ttt files into equally sized chunks

=head1 SYNOPSIS

 tt-split-n.perl OPTIONS [FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Selection Options:
   -n       NSPLITS        # number of output files
   -srand   SEED           # default: none (perl default)
   -shuffle , -noshuffle   # do/don't shuffle before splitting (default=do)

 I/O Options:
   -outfmt   OUTFMT        # %d will be replaced by split index
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

