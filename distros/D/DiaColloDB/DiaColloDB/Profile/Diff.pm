## -*- Mode: CPerl -*-
## File: DiaColloDB::Profile::Diff.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profile diffs


package DiaColloDB::Profile::Diff;
use DiaColloDB::Utils qw(:math :html);
use DiaColloDB::Profile;
use IO::File;
use strict;


##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Profile);

##==============================================================================
## Constructors etc.

## $dprf = CLASS_OR_OBJECT->new(%args)
## $dprf = CLASS_OR_OBJECT->new($prf1,$prf2,%args)
## + %args, object structure:
##   (
##    ##-- DiaColloDB::Profile::Diff
##    prf1 => $prf1,     ##-- 1st operand
##    prf2 => $prf2,     ##-- 2nd operand
##    diff => $diff,     ##-- low-level score-diff binary operation (default='abs-diff'); known values:
##                       ##    abs-diff  # $score=$a-$b ; aliases=qw(absolute-difference abs-difference abs-diff adiff adifference a-) ; select=kbesta ; default
##                       ##    diff      # $score=$a-$b ; aliases=qw(difference diff d minus -)
##                       ##    sum       # $score=$a+$b ; aliases=qw(sum add plus +)
##                       ##    min       # $score=min($a,$b)
##                       ##    max       # $score=max($a,$b)
##                       ##    avg       # $score=avg($a,$b) ; aliases=qw(average avg mean)
##                       ##    havg      # $score=harmonic_avg($a,$b)  ; aliases=qw(harmonic-average harmonic-mean havg hmean ha h)
##                       ##    gavg      # $score=geometric_avg($a,$b) ; aliases=qw(geometric-average geometric-mean gavg gmean ga g)
##                       ##    lavg      # $score=log_avg($a,$b) ; aliases=qw(logarithmic-average logarithmic-mean log-average log-mean lavg lmean la l)
##    ##-- DiaColloDB::Profile keys
##    label => $label,   ##-- string label (used by Multi; undef for none(default))
##    #N   => $N,         ##-- OVERRIDE:unused: total marginal relation frequency
##    #f1  => $f1,        ##-- OVERRIDE:unused: total marginal frequency of target word(s)
##    #f2  => \%f2,       ##-- OVERRIDE:unused: total marginal frequency of collocates: ($i2=>$f2, ...)
##    #f12 => \%f12,      ##-- OVERRIDE:unused: collocation frequencies, %f12 = ($i2=>$f12, ...)
##    #
##    eps => $eps,       ##-- smoothing constant (default=undef: no smoothing)
##    score => $func,    ##-- selected scoring function ('f12', 'mi', or 'ld')
##    mi => \%mi12,      ##-- DIFFERENCE: score: mutual information * logFreq a la Wortprofil; requires compile_mi()
##    ld => \%ld12,      ##-- DIFFERENCE: score: log-dice a la Wortprofil; requires compile_ld()
##    fm => \%fm12,      ##-- DIFFERENCE: score: frequency per million; requires compile_fm()
##   )
sub new {
  my $that = shift;
  my $prf1 = !defined($_[0]) || UNIVERSAL::isa(ref($_[0]),'DiaColloDB::Profile') ? shift : undef;
  my $prf2 = !defined($_[0]) || UNIVERSAL::isa(ref($_[0]),'DiaColloDB::Profile') ? shift : undef;
  my %opts = @_;
  my $dprf = $that->SUPER::new(
			       prf1=>$prf1,
			       prf2=>$prf2,
			       diff=>'adiff',
			       %opts,
			      );
  delete @$dprf{grep {!defined($opts{$_})} qw(N f1 f2 f12)};
  return $dprf->populate() if ($dprf->{prf1} && $dprf->{prf2});
  return $dprf;
}

## $dprf2 = $dprf->clone()
## $dprf2 = $dprf->clone($keep_compiled)
##  + clones %$dprf
##  + if $keep_score is true, compiled data is cloned too
sub clone {
  my ($dprf,$force) = @_;
  return bless({
		label=>$dprf->{label},
		diff=>$dprf->{diff},
		(defined($dprf->{prf1}) ? $dprf->{prf1}->clone($force) : qw()),
		(defined($dprf->{prf2}) ? $dprf->{prf2}->clone($force) : qw()),
	       }, ref($dprf));
}

##==============================================================================
## Basic Access

## ($prf1,$prf2) = $dprf->operands();
sub operands {
  return @{$_[0]}{qw(prf1 prf2)};
}

## $bool = $dprf->empty()
##  + returns true iff both operands are empty
sub empty {
  my $dp = shift;
  return (!$dp->{prf1} || $dp->{prf1}->empty) && (!$dp->{prf2} || $dp->{prf2}->empty);
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: JSON
##  + mostly INHERITED from DiaCollocDB::Persistent

## $obj = $CLASS_OR_OBJECT->loadJsonData( $data,%opts)
##  + guts for loadJsonString(), loadJsonFile()
sub loadJsonData {
  my $that = shift;
  my $dprf = $that->DiaColloDB::Persistent::loadJsonData(@_);
  bless($_,'DiaColloDB::Profile') foreach (grep {defined($_)} @$dprf{qw(prf1 prf2)});
  return $dprf;
}

##--------------------------------------------------------------
## I/O: Text

## undef = $CLASS_OR_OBJECT->saveTextHeader($fh, hlabel=>$hlabel, titles=>\@titles)
sub saveTextHeader {
  my ($that,$fh,%opts) = @_;
  my @fields = (
		(map {("${_}a","${_}b")} qw(N f1 f2 f12 score)),
		qw(diff),
		(defined($opts{hlabel}) ? $opts{hlabel} : qw()),
		@{$opts{titles} // (ref($that) ? $that->{titles} : undef) // [qw(item2)]},
	       );
  $fh->print(join("\t", map {"#".($_+1).":$fields[$_]"} (0..$#fields)), "\n");
}

## $bool = $prf->saveTextFh($fh, %opts)
##  + %opts:
##    (
##     label => $label,   ##-- override $prf->{label} (used by Profile::Multi), no tab-separators required
##     format => $fmt,      ##-- printf score formatting (default="%.4f")
##     header => $bool,   ##-- include header-row? (default=1)
##     hlabel => $hlabel, ##-- prefix header item-cells with $hlabel (used by Profile::Multi)
##    )
##  + format (flat, TAB-separated): Na Nb F1a F1b F2a F2b F12a F12b SCOREa SCOREb SCOREdiff LABEL ITEM2
sub saveTextFh {
  my ($dprf,$fh,%opts) = @_;
  binmode($fh,':utf8');

  my ($pa,$pb,$fscore) = @$dprf{qw(prf1 prf2 score)};
  $fscore //= 'f12';
  my ($Na,$f1a,$f2a,$f12a,$scorea) = @$pa{qw(N f1 f2 f12),$fscore};
  my ($Nb,$f1b,$f2b,$f12b,$scoreb) = @$pb{qw(N f1 f2 f12),$fscore};
  my $scored = $dprf->{$fscore};
  my $label = exists($opts{label}) ? $opts{label} : $dprf->{label};
  my $fmt   = $opts{fmt} || '%f';
  $dprf->saveTextHeader($fh,%opts) if ($opts{header}//1);

  foreach (sort {$scored->{$b} <=> $scored->{$a}} keys %$scored) {
    $fh->print(join("\t",
		    map {$_//0}
		    $Na, $Nb,
		    $f1a,$f1b,
		    $f2a->{$_}, $f2b->{$_},
		    $f12a->{$_}, $f2b->{$_},
		    sprintf($fmt,$scorea->{$_}//'nan'),
		    sprintf($fmt,$scoreb->{$_}//'nan'),
		    sprintf($fmt,$scored->{$_}//'nan'),
		    (defined($label) ? $label : qw()),
		    $_),
	       "\n");
  }
  return $dprf;
}

##--------------------------------------------------------------
## I/O: HTML

## $bool = $prf->saveHtmlFile($filename_or_handle, %opts)
##  + %opts:
##    (
##     table  => $bool,     ##-- include <table>..</table> ? (default=1)
##     body   => $bool,     ##-- include <html><body>..</html></body> ? (default=1)
##     header => $bool,     ##-- include header-row? (default=1)
##     verbose => $bool,    ##-- include verbose output? (default=0)
##     hlabel => $hlabel,   ##-- prefix header item-cells with $hlabel (used by Profile::Multi), no '<th>..</th>' required
##     label => $label,     ##-- prefix item-cells with $label (used by Profile::Multi), no '<td>..</td>' required
##     format => $fmt,      ##-- printf score formatting (default="%.4f")
##    )
##  + saves rows of the format "SCOREa SCOREb DIFF PREFIX? ITEM2"
sub saveHtmlFile {
  my ($dprf,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $dprf->logconfess("saveHtmlFile(): failed to open '$file': $!") if (!ref($fh));
  binmode($fh,':utf8');

  $fh->print("<html><body>\n") if ($opts{body}//1);
  $fh->print("<table><tbody>\n") if ($opts{table}//1);
  $fh->print("<tr>",(
		     map {"<th>".htmlesc($_)."</th>"}
		     ($opts{verbose} ? (map {("${_}a","${_}b")} qw(N f1 f2 f12)) : qw()),
		     qw(ascore bscore diff),
		     (defined($opts{hlabel}) ? $opts{hlabel} : qw()),
		     @{$dprf->{titles}//[qw(item2)]},
		    ),
	     "</tr>\n"
	    ) if ($opts{header}//1);

  my ($pa,$pb,$fscore) = @$dprf{qw(prf1 prf2 score)};
  $fscore //= 'f12';
  my $scorea = $pa->{$fscore};
  my $scoreb = $pb->{$fscore};
  my $scored = $dprf->{$fscore};
  my $fmt    = $opts{format} || "%.4f";
  my $label  = exists($opts{label}) ? $opts{label} : $dprf->{label};
  foreach (sort {$scored->{$b} <=> $scored->{$a}} keys %$scored) {
    $fh->print("<tr>", (map {"<td>".htmlesc($_)."</td>"}
			($opts{verbose}
			 ? (map {($_//0)}
			    $pa->{N}, $pb->{N},
			    $pa->{f1}, $pb->{f1},
			    $pa->{f2}{$_}, $pb->{f2}{$_},
			    $pa->{f12}{$_}, $pb->{f12}{$_},
			   )
			 : qw()),
			sprintf($fmt,$scorea->{$_}//'nan'),
			sprintf($fmt,$scoreb->{$_}//'nan'),
			sprintf($fmt,$scored->{$_}//'nan'),
			(defined($label) ? $label : qw()),
			split(/\t/,$_)),
	       "</tr>\n");
  }
  $fh->print("</tbody><table>\n") if ($opts{table}//1);
  $fh->print("</body></html>\n") if ($opts{body}//1);
  $fh->close() if (!ref($file));
  return $dprf;
}


##==============================================================================
## Compilation

##----------------------------------------------------------------------
## Compilation: diff-ops

## %DIFFOPS : ($opAlias => $opName, ...) : canonical diff-operation names
our %DIFFOPS =
  (
   (map {($_=>'diff')} qw(difference diff d minus -)),
   (map {($_=>'adiff')} qw(absolute-difference abs-difference abs-diff adiff adifference a- DEFAULT)),
   (map {($_=>'sum')} qw(add plus sum +)),
   (map {($_=>'min')} qw(minimum min)),
   (map {($_=>'max')} qw(maximum max)),
   (map {($_=>'avg')} qw(average avg mean)),
   (map {($_=>'havg')} qw(harmonic-average harmonic-avg harmonic harm haverage havg ha h)),
   (map {($_=>'gavg')} qw(geometric-average geometric-mean geometric geom geo gavg gmean ga g)),
   (map {($_=>'lavg')} qw(logarithmic-average logarithmic-mean logarithmic log-average log-mean log lavg lmean la l)),
  );

## $opname = $dprf->diffop()
## $opname = $CLASS_OR_OBJECT->diffop($opNameOrAlias)
##  + returns canonical diff operation-name for $opNameOrAlias
sub diffop {
  my ($that,$op) = @_;
  $op //= $that->{diff} if (ref($that));
  return (defined($op) ? $DIFFOPS{$op} : undef) // $op // $DIFFOPS{DEFAULT};
}

## \&FUNC = $dprf->diffsub()
## \&FUNC = $CLASS_OR_OBJECT->diffsub($opNameOrAlias)
##  + gets low-level binary diff operation for diff-operation $opNameOrAlias (default=$dprf->{diff})
sub diffsub {
  my ($that,$opname) = @_;
  return $opname if (UNIVERSAL::isa($opname,'CODE')); ##-- code-ref
  my $op  = $that->diffop($opname);
  my $sub = $that->can("diffop_$op");
  return $sub if (defined($sub));
  $that->logwarn("unknown low-level diff operation '$op' defaults to '$DIFFOPS{DEFAULT}'");
  return \&diffop_diff;
}

## $how = $dprf->diffpretrim()
## $how = $CLASS_OR_OBJECT->diffpretrim($opNameOrAlias)
##  + returns if and how diff should pre-trim operand profiles: one of:
##    0          : don't pre-trim
##    'restrict' : intersect defined collocates
##    'kbest'    : union of k-best collocates
sub diffpretrim {
  my ($that,$op) = @_;
  $op = $that->diffop($op);
  if ($op =~ /^min|avg/) {
    return 'restrict';
  }
  elsif ($op =~ m/^a?diff|max/) {
    return 'kbest';
  }
  return 0;
}

## $selector = $dprf->diffkbest()
## $selector = $CLASS_OR_OBJECT->diffkbest($opNameOrAlias)
##  + returns 'kbest' selector appropriate for which() or trim() methods
sub diffkbest {
  my ($that,$op) = @_;
  return $that->diffop($op) eq 'adiff' ? 'kbesta' : 'kbest';
}


BEGIN { *diffop_adiff = \&diffop_diff; }
sub diffop_diff  { return $_[0]-$_[1]; }
sub diffop_sum   { return $_[0]+$_[1]; }
sub diffop_min   { return $_[0]<$_[1] ? $_[0] : $_[1]; }
sub diffop_max   { return $_[0]>$_[1] ? $_[0] : $_[1]; }
sub diffop_avg   { return ($_[0]+$_[1])/2.0; }

#sub diffop_havg  { return $_[0]<=0 || $_[1]<=0 ? 0 : 2.0/(1.0/$_[0] + 1.0/$_[1]); }
##--
#our $havg_eps = 0.1;
#sub diffop_havg  { return 2.0/(1.0/($_[0]+$havg_eps) + 1.0/($_[1]+$havg_eps)) - $havg_eps; }
##--
sub diffop_havg0  { return $_[0]<=0 || $_[1]<=0 ? 0 : (2*$_[0]*$_[1])/($_[0]+$_[1]); }
sub diffop_havg   { return diffop_avg(diffop_havg0(@_),diffop_avg(@_)); }

sub nthRoot { return ($_[0]<0 ? -1 : 1) * abs($_[0])**(1/$_[1]); }
#sub diffop_gavg   { return nthRoot($_[0]*$_[1], 2); }
##--
sub diffop_gavg0 { return nthRoot($_[0]*$_[1], 2); }
sub diffop_gavg  { return diffop_avg(diffop_gavg0(@_),diffop_avg(@_)); }


sub diffop_lavg {
  my ($x,$y) = $_[0]<$_[1] ? @_[0,1] : @_[1,0];
  my $delta  = $x<=1 ? (1-$x) : 0;
  return exp( log(($x+$delta)*($y+$delta))/2.0 ) - $delta;
}


##----------------------------------------------------------------------
## Compilation: guts

## $dprf = $dprf->populate()
## $dprf = $dprf->populate($prf1,$prf2)
##  + populates diff-profile by applying the selected diff-operation on aligned operand scores
sub populate {
  my ($dprf,$pa,$pb) = @_;
  $pa //= $dprf->{prf1};
  $pb //= $dprf->{prf2};
  $pa   = $pb->shadow(1) if (!$pa &&  $pb);
  $pb   = $pa->shadow(1) if ( $pa && !$pb);
  @$dprf{qw(prf1 prf2)} = ($pa,$pb);
  $dprf->{label} //= $pa->label() ."-" . $pb->label();

  my $scoref = $dprf->{score} = $dprf->{score} // $pa->{score} // $pb->{score} // 'f12';
  my ($af2,$af12,$ascore) = @$pa{qw(f2 f12),$scoref};
  my ($bf2,$bf12,$bscore) = @$pb{qw(f2 f12),$scoref};
  my $dscore  = $dprf->{$scoref} = ($dprf->{$scoref} // {});
  my $diffsub = $dprf->diffsub();
  $dprf->logconfess("populate(): no {$scoref} key for \$pa") if (!$ascore);
  $dprf->logconfess("populate(): no {$scoref} key for \$pb") if (!$bscore);
  foreach (keys %$bscore) {
    $af2->{$_}    //= 0;
    $af12->{$_}   //= 0;
    $ascore->{$_} //= 0;
    $dscore->{$_} = $diffsub->(($ascore->{$_}//0), ($bscore->{$_}//0));
  }
  return $dprf;
}


## $dprf = $dprf->compile($func,%opts)
##  + compile for score-function $func, one of qw(f fm mi ld); default='f'
sub compile {
  my ($dprf,$func) = (shift,shift);
  $dprf->logconfess("compile(): cannot compile without operand profiles")
    if (!$dprf->{prf1} || !$dprf->{prf2});
  $dprf->{prf1}->compile($func,@_) or return undef;
  $dprf->{prf2}->compile($func,@_) or return undef;
  $dprf->{score} = $dprf->{prf1}{score};
  return $dprf->populate();
}

## $dprf = $dprf->uncompile()
##  + un-compiles all scores for $dprd
sub uncompile {
  my $dprf = shift;
  $dprf->{prf1}->uncompile() if ($dprf->{prf1});
  $dprf->{prf2}->uncompile() if ($dprf->{prf2});
  return $dprf->SUPER::uncompile();
}

##==============================================================================
## Trimming

## \@keys = $prf->which(%opts)
##  + returns 'good' keys for trimming options %opts:
##    (
##     cutoff => $cutoff,  ##-- retain only items with $prf->{$prf->{score}}{$item} >= $cutoff
##     kbest  => $kbest,   ##-- retain only $kbest items
##     kbesta => $kbesta,  ##-- retain only $kbest items (absolute value)
##     return => $which,   ##-- either 'good' (default) or 'bad'
##     as     => $as,      ##-- 'hash' or 'array'; default='array'
##    )
##  + INHERITED from DiaColloDB::Profile

## $dprf = $dprf->trim(%opts)
##  + %opts:
##    (
##     kbest => $kbest,    ##-- retain only $kbest items (by score value)
##     kbesta => $kbesta,  ##-- retain only $kbest items (by score absolute value)
##     cutoff => $cutoff,  ##-- retain only items with $prf->{$prf->{score}}{$item} >= $cutoff
##     keep => $keep,      ##-- retain keys @$keep (ARRAY) or keys(%$keep) (HASH)
##     drop => $drop,      ##-- drop keys @$drop (ARRAY) or keys(%$drop) (HASH)
##    )
sub trim {
  my ($dprf,%opts) = @_;
  my ($pa,$pb) = @$dprf{qw(prf1 prf2)};

  if ($opts{keep} || $opts{drop}) {
    ##-- explicit keep request
    $dprf->populate() if (!$dprf->{score});
    $dprf->SUPER::trim(%opts) or return undef;
  }
  else {
    ##-- heuristic (pre-)trimming
    $dprf->pretrim($pa,$pb,%opts);
    $dprf->populate();
    $dprf->SUPER::trim(%opts);
  }

  ##-- trim operand profiles
  my $keep = $dprf->{$dprf->{score}//'f12'};
  $pa->trim(keep=>$keep) or return undef if ($pa);
  $pb->trim(keep=>$keep) or return undef if ($pb);

  return $dprf;
}

## ($pa,$pb) = $CLASS_OR_OBJECT->pretrim($pa,$pb,%opts)
##   + perform pre-trimming on aligned profile pair ($pa,$pb)
sub pretrim {
  my ($that,$pa,$pb,%opts) = @_;
  my $pretrim = $that->diffpretrim($opts{diff});

  if ($pretrim eq 'kbest') {
    ##-- pre-trim: union of k-best collocates
    my %keep = map {($_=>undef)} (($pa ? @{$pa->which(%opts)} : qw()), ($pb ? @{$pb->which(%opts)} : qw()));
    $pa->trim(keep=>\%keep) if ($pa);
    $pb->trim(keep=>\%keep) if ($pb);
  }
  elsif ($pretrim eq 'restrict' && $pa && $pb) {
    my @drop = (
		(grep {!exists $pa->{f12}{$_}} keys %{$pb->{f12}}),
		(grep {!exists $pb->{f12}{$_}} keys %{$pa->{f12}}),
	       );
    $pa->trim(drop=>\@drop);
    $pb->trim(drop=>\@drop);
  }
  return ($pa,$pb);
}

##==============================================================================
## Stringification

## $dprf = $dprf->stringify( $obj)
## $dprf = $dprf->stringify(\@key2str)
## $dprf = $dprf->stringify(\&key2str)
## $dprf = $dprf->stringify(\%key2str)
##  + stringifies profile (destructive) via $obj->i2s($key2), $key2str->($i2) or $key2str->{$i2}
sub stringify {
  my ($dprf,$i2s) = @_;
  $i2s = $dprf->stringify_map($i2s);
  $_->stringify($i2s) or return undef foreach (grep {defined($_)} $dprf->operands);
  return $dprf->SUPER::stringify($i2s);
}

##==============================================================================
## Binary operations

## $dprf = $dprf->_add($dprf2,%opts)
##  + adds $dprf2 operand frequency data to $dprf operands (destructive)
##  + implicitly un-compiles $dprf
##  + %opts:
##     N  => $bool, ##-- whether to add N values (default:true)
##     f1 => $bool, ##-- whether to add f1 values (default:true)
sub _add {
  my ($dpa,$dpb,%opts) = @_;
  $dpa->{prf1}->_add($dpb->{prf1}) if ($dpa->{prf1} && $dpb->{prf1});
  $dpa->{prf2}->_add($dpb->{prf2}) if ($dpa->{prf2} && $dpb->{prf2});
  return $dpa->uncompile();
}

## $dprf3 = $dprf1->add($dprf2,%opts)
##  + returns sum of $dprf1 and $dprf2 operatnd frequency data (destructive)
##  + see _add() method for %opts
##  + INHERITED from DiaColloDB::Profile

## $diff = $prf1->diff($prf2,%opts)
##  + returns score-diff of $prf1 and $prf2 frequency data (destructive)
##  + %opts: see _diff() method
##  + INHERITED but probably useless


##==============================================================================
## Footer
1;

__END__
