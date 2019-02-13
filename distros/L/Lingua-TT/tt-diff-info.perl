#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Diff;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = $Lingua::TT::Diff::vl_error;

our $outfile      = '-';
our %diffargs     = qw();
our $showFixes    = 1;

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
	   'fixes|fix!' => \$showFixes,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= $Lingua::TT::Diff::vl_info) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## subs

sub pct {
  my ($num,$denom) = @_;
  return !defined($denom) || $denom==0 ? 'nan' : 100*$num/$denom;
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
our $diff = Lingua::TT::Diff->new(verbose=>$verbose,%diffargs);

push(@ARGV,'-') if (!@ARGV);
our $outfh = IO::File->new(">$outfile")
  or die("$0: open failed for output file '$outfile': $!");

foreach $dfile (@ARGV) {
  our $dfile = shift(@ARGV);
  $diff->reset;
  $diff->loadTextFile($dfile)
    or die("$0: load failed for '$dfile': $!");
  $diff->vmsg1($Lingua::TT::Diff::vl_trace, "loaded $dfile");

  ##-- vars
  my ($file1,$file2,$seq1,$seq2,$hunks) = @$diff{qw(file1 file2 seq1 seq2 hunks)};

  ##-- counts
  my $nseq1   = scalar(@$seq1);
  my $nseq2   = scalar(@$seq2);
  my $nhunks  = scalar(@$hunks);
  ##
  my $ndel=0;  $ndel+=($_->[2]-$_->[1]+1) foreach (grep {$_->[0] eq 'd'} @$hunks);
  my $nins=0;  $nins+=($_->[4]-$_->[3]+1) foreach (grep {$_->[0] eq 'a'} @$hunks);
  my $nchg1=0; $nchg1+=($_->[2]-$_->[1]+1) foreach (grep {$_->[0] eq 'c'} @$hunks);
  my $nchg2=0; $nchg2+=($_->[4]-$_->[3]+1) foreach (grep {$_->[0] eq 'c'} @$hunks);
  my $nbad1 = $ndel+$nchg1;
  my $nbad2 = $nins+$nchg2;
  my $nok1 = $nseq1-$nbad1;
  my $nok2 = $nseq2-$nbad2;
  ##
  my $nfix1=0; $nfix1+=($_->[2]-$_->[1]+1) foreach (grep {$_->[5] && $_->[0] ne 'a'} @$hunks);
  my $nfix2=0; $nfix2+=($_->[4]-$_->[3]+1) foreach (grep {$_->[5] && $_->[0] ne 'd'} @$hunks);
  my $nnofix1 = $nbad1-$nfix1;
  my $nnofix2 = $nbad2-$nfix2;

  ##-- counts: fixes
  my %fix1=qw();
  my %fix2=qw();
  if ($showFixes) {
    $fix2{$_->[6]} += ($_->[4]-$_->[3]+1) foreach (grep {$_->[5] && defined($_->[6])} @$hunks);
    $fix1{$_->[6]} += ($_->[2]-$_->[1]+1) foreach (grep {$_->[5] && defined($_->[6])} @$hunks);
  }

  ##-- formatting stuff
  my $llen  = 14;
  if ($showFixes) {
    foreach (keys(%fix1)) {
      $llen = length($_) if (length($_) > $llen);
    }
    $llen += 6;
  }
  my $ilen1 = length($nseq1);
  my $ilen2 = length($nseq2);
  my $flen  = 5;
  my $npad  = 5;
  ##
  my $clen1 = length($file1) > ($ilen1+$flen+$npad) ? length($file1) : ($ilen1+$flen+$npad);

  my $clen2 = length($file2) > ($ilen2+$flen+$npad) ? length($file2) : ($ilen2+$flen+$npad);
  ##
  my $lfmt  = '%'.(-$llen).'s';
  my $sfmt1 = "%${clen1}s";
  my $sfmt2 = "%${clen2}s";
  $ilen1    = ($clen1-$flen-$npad);
  $ilen2    = ($clen2-$flen-$npad);
  my $ifmt1 = "%${ilen1}d";
  my $ifmt2 = "%${ilen2}d";
  my $ifmt1a = $ifmt1.(' ' x ($flen+$npad));
  my $ifmt2a = $ifmt2.(' ' x ($flen+$npad));
  my $ffmt  = "(%${flen}.1f %%)";
  my $iffmt  = $ifmt1.' '.$ffmt.' | '.$ifmt2.' '.$ffmt;
  my $iffmt1 = $ifmt1.' '.$ffmt.' | '.sprintf("%${ilen2}s  %${flen}s   ",'-','-');
  my $iffmt2 = sprintf("%${ilen1}s  %${flen}s   ",'-','-').' | '.$ifmt2.' '.$ffmt;

  ##-- report: basic data
  $outfh->print(#"DIFF: $dfile\n",
		sprintf("$lfmt: %s\n", 'Diff', $dfile),
		sprintf("$lfmt: $sfmt1 | $sfmt2\n", ' + Files', $file1, $file2),
		sprintf("$lfmt: $iffmt\n",  ' + Items', $nseq1, 100, $nseq2, 100),
		sprintf("$lfmt: $iffmt\n",  '   - MATCH',  $nok1, pct($nok1,$nseq1), $nok2, pct($nok2,$nseq2)),
		sprintf("$lfmt: $iffmt\n",  '   - NOMATCH', $nbad1, pct($nbad1,$nseq1), $nbad2, pct($nbad2,$nseq2)),
		sprintf("$lfmt: $iffmt1\n", '     ~ DELETE', $ndel, pct($ndel,$nseq1)),
		sprintf("$lfmt: $iffmt2\n", '     ~ INSERT', $nins, pct($nins,$nseq2)),
		sprintf("$lfmt: $iffmt\n",  '     ~ CHANGE', $nchg1, pct($nchg1,$nseq1), $nchg2, pct($nchg2,$nseq2)),
		sprintf("$lfmt: $iffmt\n",  ' + Fixed', $nfix1, pct($nfix1,$nbad1), $nfix2, pct($nfix2,$nbad2)),
		(map {
		  sprintf("$lfmt: $iffmt\n",  ('   - '.$_), $fix1{$_}, pct($fix1{$_},$nbad1), $fix2{$_}, pct($fix2{$_},$nbad2)),
		} sort(keys(%fix1))),
		sprintf("$lfmt: $iffmt\n",  ' + Unfixed', $nnofix1, pct($nnofix1,$nbad1), $nnofix2, pct($nnofix2,$nbad2)),
	       );
}

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-diff-info.perl - get basic info from tt-diff files

=head1 SYNOPSIS

 tt-diff-info.perl OPTIONS [TT_DIFF_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output FILE         ##-- output file (default: STDOUT)

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
