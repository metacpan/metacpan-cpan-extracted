#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment;
use Lingua::TT::Diff;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

use strict;

##----------------------------------------------------------------------
## Globals

##-- verbosity levels
our $vl_silent = $Lingua::TT::Diff::vl_silent;
our $vl_error = $Lingua::TT::Diff::vl_error;
our $vl_warn = $Lingua::TT::Diff::vl_warn;
our $vl_info = $Lingua::TT::Diff::vl_info;
our $vl_trace = $Lingua::TT::Diff::vl_trace;

our $prog         = basename($0);
our $verbose      = $vl_info;
our $VERSION	  = 0.11;

our $outfile      = '-';
our %diffargs     = qw();
our %ioargs       = (encoding=>'UTF-8');
our %saveargs     = (shared=>1, context=>undef, syntax=>1);

our $briefmode    = 0;
our %classify    = (tp=>1,fp=>1,fn=>1);

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
our ($help,$version);
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'brief|b!' => \$briefmode,
	   'output|out|o=s' => \$outfile,
	   'encoding|e=s' => \$ioargs{encoding},
	   'context|c|k=i' => \$saveargs{context},
	   #'shared|s!' => \$saveargs{shared},

	   ##-- Annotation
	   'classify-true-positives|ctp|tp!' => \$classify{tp},
	   'classify-false-positives|cfp|fp!' => \$classify{fp},
	   'classify-false-negatives|cfn|fn!' => \$classify{fn},
	   'classify-errors|errors|ce|E!' => sub {$classify{fp}=$classify{fn}=$_[1]; $classify{tp}=!$_[1];},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'Not enough arguments specified!'}) if (@ARGV < 1);

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

##======================================================================
## precision, recall

## %prf = n2prf($ntp, $nfp, $nfn)
##      = n2prf($n12, $n_2, $n1_)
sub n2prf {
  my ($ntp,$nfp,$nfn) = map {$_||0} @_;
  my $nretr = $ntp+$nfp;
  my $nrel  = $ntp+$nfn;
  my $pr = ($nretr==0 ? 'nan' : ($ntp/$nretr));
  my $rc = ($nrel ==0 ? 'nan' : ($ntp/$nrel));
  my $F  = ($pr+$rc==0) ? 'nan' : (2 * $pr * $rc / ($pr + $rc));
  my $Err = ($ntp+$nfp+$nfn==0 ? 'nan' : ($nfp+$nfn) / ($ntp+$nfp+$nfn));
  return (
	  "tp"=>"$ntp", "fp"=>"$nfp", "fn"=>"$nfn", "ret"=>"$nretr", "rel"=>"$nrel",
	  "pr"=>"$pr",  "rc"=>"$rc","F"=>"$F",
	  "Err"=>"$Err",
	 );
}

## $sum = lsum(@vals)
sub lsum {
  my $sum = 0;
  $sum += $_ foreach (@_);
  return $sum;
}

## $max = lmax(@vals)
sub lmax {
  my $max = -inf;
  foreach (@_) { $max=$_ if ($_>$max); }
  return $max;
}

## $maxlen = maxlen(@strings)
sub maxlen {
  return lmax map {length $_} @_;
}

## @strings = dumptab($line_prefix, \%ev, @prefixes=sort keys %events)
sub dumptab {
  my ($lprefix, $ev,@prefixes) = @_;
  @prefixes  = (sort keys %$ev) if (!@prefixes);
  return if (!@prefixes); ##-- nothing to evaluate!
  my $plen   = maxlen('which',@prefixes);
  my $dlen   = maxlen 'tp', map {int($_)} map {@{$ev->{$_}}{qw(tp fp fn)}} @prefixes;
  my $flen   = 6;
  my $ffmt   = "%${flen}.2f";
  return
    (
     sprintf("%s %-${plen}s  ".join('  ',map {"%${dlen}s"} qw(tp fp fn)).'  '.join('  ',map {"%${flen}s %%"} qw(pr rc F Err))."\n",
	     $lprefix, map {uc($_)} 'label', qw(tp fp fn), qw(pr rc F Err)),
     (map {
       my $prf = $_;
       sprintf("%s %-${plen}s  ".join('  ',map {"%${dlen}d"} qw(tp fp fn)).'  '.join('  ',map {"$ffmt %%"} qw(pr rc F Err))."\n",
	       $lprefix, $_, @{$ev->{$prf}}{qw(tp fp fn)}, (map {100.0*$ev->{$prf}{$_}} qw(pr rc F Err)))
     } @prefixes),
    );
}

##======================================================================
## guts

## \%events = get_eval_data($diff)
##  + returns \%events = {$eclass => {tp=>$ntp, fp=>$nfp, fn=>$nfn, ...}, ...}
sub get_eval_data {
  my $diff  = shift;
  my $align = $diff->alignment();

  my %events = (s=>{}, w=>{});

  ##-- variables for kiss-trunk error-rate (class "s:ks")
  my $text      = '';
  my $is_dotted = 0;
  my $n_dots    = 0;
  my $n_ks_cand = 0;

  ##-- convert alignment-items to events
  my $nil = [];
  my @seq = @$diff{qw(seq1 seq2)};
  my @aux = @$diff{qw(aux1 aux2)};
  my ($i1,$i2,$hunk);
  my ($ai,$aitem,$srci,$ii,$line, $ekey);
  my (@classes);
  foreach $ai (0..$#$align) {
    ($i1,$i2,$hunk) = @{$aitem = $align->[$ai]};

    ##-- get item data
    $srci  = defined($i1) ? (defined($i2) ? 1 : 0) : 1;
    $ii    = $aitem->[$srci]; ##-- i.e. $i1 or $i2
    $line  = $seq[$srci][$ii];
    $ekey  = (defined($i1) ? (defined($i2) ? 'tp' : 'fn') : 'fp');

    ##-- classify: sentence vs word
    @classes = qw(all);
    if ($line =~ /^$/) {
      ##-- sub-classify: sentence
      push(@classes, 's');
      if ($ii>0) {
	push(@classes, 's:ks') if ($is_dotted);

	if    ($seq[$srci][$ii-1] =~ m/^[\.\!\?\:]\t/)		{ push(@classes, 's:std'); }
	elsif ($seq[$srci][$ii-1] !~ m/^[^\t]*[[:punct:]]\t/)	{ push(@classes, 's:nopunct'); }
	else							{ push(@classes, 's:nonstd'); }
	if    ($seq[$srci][$ii-1] =~ m/^[^\t]*\.\t/)		{ push(@classes, "s:dot"); }
	if    ($seq[$srci][$ii-1] =~ m/^[^\t]*[^[:punct:]\t][^\t]*\.\t/)	   { push(@classes, "s:abbr"); }
	if    ($seq[$srci][$ii-1] =~ m/^([\.\!\?\:\;\/\)\]\}\-]|(?:[\'\"\`]+))\t/) { push(@classes, "s~$1"); }

	if    ($ii<$#{$seq[$srci]} && $seq[$srci][$ii+1] !~ m/^[[:upper:]]/)	   { push(@classes, "s:nocaps"); }
      }
    }
    else {
      ##-- sub-classify: word
      push(@classes, 'w');

      if    ($line =~ m/^[[:alpha:]]+\t/) { push(@classes, 'w~alpha'); }
      elsif ($line =~ m/^[[:digit:]]+\t/) { push(@classes, 'w~digit'); }
      elsif ($line =~ m/^[[:punct:]]+\t/) { push(@classes, 'w~punct'); }
      elsif ($line =~ m/^[[:alpha:][:punct:]]+\t/) { push(@classes, 'w~alpha+punct'); }
      elsif ($line =~ m/^[[:digit:][:punct:]]+\t/) { push(@classes, 'w~digit+punct'); }
      elsif ($line =~ m/^[[:digit:][:punct:]_ ]+\t/) { push(@classes, 'w~digit+punct+sp'); }
      else { push(@classes, 'w~zother'); }

      push(@classes, 'w:dotted')  if ($line =~ m/^[^\t]*[^[:punct:]\t][^\t]*\.\t/);
      push(@classes, 'w:nospace') if ($ii>0 && !grep {m/^%%\$c=\s+$/} @{$aux[$srci]{$ii}||$nil});
      push(@classes, 'w:apos')    if ($line =~ m/\'/);
      push(@classes, 'w:nolex')   if ($line =~ m/\t.*\(NOLEX\)/);

      ##-- kiss-strunk error rate stuff
      if ($srci==1) {
	($text = $line) =~ s/\t.*$//;
	$n_dots   += scalar @{[ $text =~ /[\.]/g ]};
	if (
	    #$text =~ /[\.\?\!]$/ ##-- generous(?) eos-condition; ~ Kiss&Strunk(2006) Sec. 6.2 [1.40% on WSJ]
	    $text =~ /[\.]$/ ##-- not-so generous(?) eos-condition; ~ Kiss&Strunk(2006) footnote 8 [1.25% on WSJ]
	   ) {
	  $is_dotted = 1;
	  ++$n_ks_cand;
	} elsif ($is_dotted && $text =~ /^[\"\'\`”\)\]\}\.]+/) {
	  $is_dotted = 1;
	} else {
	  $is_dotted = 0;
	}
      }
    }

    ##-- count this item
    ++$events{$_}{$ekey} foreach (@classes);
    push(@{$aux[$srci]{$ii}}, "%%\@eval=$ekey ".join(' ',@classes)) if ($classify{$ekey});
    #$seq[$srci][$ii] .= "\t\@eval=$ekey ".join(' ',@classes) if ($classify{$ekey});

    ##-- DEBUG
    #foreach (@{defined($i1) ? ($aux[0]{$i1}||$nil) : $nil}) { $sid = $1 if (/^%% Sentence (.*)$/); }
    #print DEBUG "$sid\n" if ($ekey eq 'tp' && grep {$_ eq 's:dot'} @classes);
  }

  ##-- compute pr,rc,F
  foreach (values %events) {
    %$_ = (%$_, n2prf(@$_{qw(tp fp fn)}));
  }
  $events{"s:ks"}{ncand} = $n_ks_cand;
  $events{"s:ks"}{ndots} = $n_dots;
  $events{"s:ks"}{Err}   = ($events{"s:ks"}{fp}+$events{"s:ks"}{fn}) / $n_ks_cand; ##-- Kiss&Strunk(2006) "error rate" (not-so-generous)
  #$events{"s:ks"}{Err}   = ($events{"s:ks"}{fp}+$events{"s:ks"}{fn}) / $n_dots; ##-- Kiss&Strunk(2006) "error rate" (generous)

  return \%events;
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
our $diff = Lingua::TT::Diff->new(verbose=>$verbose,%diffargs);
our $outfh = IO::File->new(">$outfile")
  or die("$0: open failed for output file '$outfile': $!");

push(@ARGV,'-') if (!@ARGV);
our $dfile = shift @ARGV;
$diff->loadTextFile($dfile)
  or die("$prog: load failed for '$dfile': $!");
$diff->vmsg1($Lingua::TT::Diff::vl_trace, "loaded $dfile");

##-- evaluate & summarize
vmsg1($vl_trace, "evaluating ...");
my $events = get_eval_data($diff);
my @summary =
  ("%%".('-' x 70)."\n",
   "%% $prog summary (manual=$diff->{file1} ; auto=$diff->{file2})\n",
   dumptab("%% ", $events),
  );

##-- dump: ttdiff
if (!$briefmode) {
  open(OUT, ">$outfile") or die("$prog: open failed for '$outfile': $!");
  $diff->saveTextFile(\*OUT,%saveargs,filename=>$outfile)
    or die("$prog: diff->saveTextFile() failed for '$outfile': $!");
  print OUT @summary;
  close OUT;
}

##-- dump summary to stderr
shift @summary;
s/^%% // foreach (@summary);
vmsg($vl_info, @summary);

##-- all done
vmsg1($vl_trace, "done.\n");

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-rttdiff-eval.perl - evaluate tokenizer output diffs

=head1 SYNOPSIS

 tt-rttdiff-eval.perl [OPTIONS] TT_DIFF

 General Options:
   -help
   -version
   -verbose LEVEL

 I/O Options:
   -brief               # only output summary
   -output FILE         # ttdiff output file (default: STDOUT)
   -encoding ENC        # I/O encoding (default: utf8)
   -context K           # number ttdiff context lines for output (default: full)

 Annotation Options:
   -tp , -notp		# do/don't mark true-positive items (default=do)
   -fp , -nofp		# do/don't mark false-positive items (default=do)
   -fn , -nofn		# do/don't mark false-negative items (default=do)
   -errors , -noerrors	# alias for -[no]fp -[no]fn -[!no]tp

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
