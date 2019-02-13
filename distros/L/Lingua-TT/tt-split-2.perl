#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);

our $frac1        = undef;
our $n1           = undef;
our $outfile1     = '-';
our $outfile2     = '-';
our $srand        = 0;
our $bytoken      = 0;

our $verbose      = 1;

#our %ioargs = (encoding=>'UTF-8');
our %ioargs = qw();

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- Selection
	   'bytoken|bytok|token|t!' => \$bytoken,
	   'bysentence|bysent|sentence|s!' => sub { $bytoken = !$_[1]; },
	   'frac1|f1|f=f' => \$frac1,
	   'n1|n=i' => \$n1,
	   'srand|seed|r=i' => \$srand,
	   'noseed|random|rand' => sub { undef($srand); },

	   ##-- I/O
	   'output1|o1=s' => \$outfile1,
	   'output2|o2=s' => \$outfile2,
	   'encoding|e=s' => \$ioargs{encoding},
	  );

pod2usage({
	   -msg=>'You must specify either -f or -n!',
	   -exitval=>0,
	   -verbose=>0
	  }) if (!$frac1 && !$n1);
pod2usage({
	   -exitval=>0,
	   -verbose=>0
	  }) if ($help);
pod2usage({
	   -exitval=>0,
	   -verbose=>1
	  }) if ($man);

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

## dumpSentence()
our ($buf,$ntoks,$nsents,$outi,@outfh,$pntoks);
our @ntoks  = (0,0);
our @nsents = (0,0);
sub dumpSentence {
  --$ntoks if (!$bytoken);
  $outi = (rand() <= $frac1 ? 0 : 1);
  $outfh[$outi]->print($buf);
  $ntoks[$outi] += ($ntoks-$pntoks);
  if ($buf =~ /\n\n\z/) {
    ++$nsents[$outi];
    ++$nsents;
  }
  $pntoks = $ntoks;
  $buf = '';
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV, '-') if (!@ARGV);

##-- set random seed
srand($srand) if (defined($srand));

##-- open output file(s)
our $ttout1 = Lingua::TT::IO->toFile($outfile1,%ioargs)
  or die("$0: open failed for '$outfile1': $!");
our $ttout2 = Lingua::TT::IO->toFile($outfile2,%ioargs)
  or die("$0: open failed for '$outfile2': $!");
@outfh  = ($ttout1->{fh},$ttout2->{fh});

##-- read in source file(s)
my ($ttin);
$pntoks = 0;
$ntoks  = 0;
$nsents = 0;
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,%ioargs)
    or die("$0: open failed for file '$infile': $!");
  our $infh = $ttin->{fh};
  $buf = '';
  while (defined($line=<$infh>)) {
    $buf .= $line;
    ++$ntoks;
    dumpSentence if ($line =~ /^$/ || ($bytoken && $line !~ /^(?:%%.*)$/));
  }
  dumpSentence if ($buf);
}

##-- report
print STDERR
  ("$progname: got $ntoks tokens in $nsents sentences total\n",
  );

##-- Summarize
our $nitems = $bytoken ? $ntoks : $nsents;
our ($ntoks1,$ntoks2)   = @ntoks;
our ($nsents1,$nsents2) = @nsents;
$nsents ||= 1;

$flen = length($outfile1) > length($outfile2) ? length($outfile1) : length($outfile2);
$ilen = length($ntoks);

print STDERR
  (sprintf("\t+ %-${flen}s : %${ilen}d sentences (%6.2f %%)   /   %${ilen}d tokens (%6.2f %%)\n",
	   $outfile1,
	   $nsents1, 100.0*$nsents1/$nsents,
	   $ntoks1, 100.0*$ntoks1/$ntoks),
sprintf("\t+ %-${flen}s : %${ilen}d sentences (%6.2f %%)   /   %${ilen}d tokens (%6.2f %%)\n",
	   $outfile2,
	   $nsents2, 100.0*$nsents2/$nsents,
	   $ntoks2, 100.0*$ntoks2/$ntoks),
  );


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-split-2.perl - split up .t, .tt, and .ttt files into two parts

=head1 SYNOPSIS

 tt-split-2.perl OPTIONS [FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Selection Options
   -bytoken , -bysentence  ##-- default: -bysentence
   -frac    FLOAT          ##-- fraction of total items for -output1
   -n       NSENTS         ##-- absolute number of total items for -output1
   -srand   SEED           ##-- default: none (perl default)
   -noseed                 ##--  ... truly random

 I/O Options:
   -output1 OUTFILE1
   -output2 OUTFILE2

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

