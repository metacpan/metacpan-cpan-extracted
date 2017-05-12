## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Profile.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, (co-)frequency profile
##  + for scoring heuristics, see:
##
##    - Jörg Didakowski; Alexander Geyken, 2013. From DWDS corpora to a German Word Profile – methodological problems and solutions.
##      In: Network Strategies, Access Structures and Automatic Extraction of Lexicographical Information. 2nd Work Report of the
##      Academic Network "Internet Lexicography". Mannheim: Institut für Deutsche Sprache. (OPAL - Online publizierte Arbeiten zur
##      Linguistik X/2012), S. 43-52.
##      URL http://www.dwds.de/static/website/publications/pdf/didakowski_geyken_internetlexikografie_2012_final.pdf
##
##    - Rychlý, P. 2008. `A lexicographer-friendly association score'. In P. Sojka and A. Horák (eds.) Proceedings of Recent
##      Advances in Slavonic Natural Language Processing. RASLAN 2008, 6­9.
##      URL http://www.muni.cz/research/publications/937193 , http://www.fi.muni.cz/usr/sojka/download/raslan2008/13.pdf
##
##    - Kilgarriff, A. and Tugwell, D. 2002. `Sketching words'. In M.-H. Corréard (ed.) Lexicography and Natural
##      Language Processing: A Festschrift in Honour of B. T. S. Atkins. EURALEX, 125-137.
##      URL http://www.kilgarriff.co.uk/Publications/2002-KilgTugwell-AtkinsFest.pdf
##
##    - Evert, Stefan (2008). "Corpora and collocations." In A. Lüdeling and M. Kytö (eds.),
##      Corpus Linguistics. An International Handbook, article 58, pages 1212-1248.
##      Mouton de Gruyter, Berlin.
##      URL (extended manuscript): http://purl.org/stefan.evert/PUB/Evert2007HSK_extended_manuscript.pdf
##

package DiaColloDB::Profile;
use DiaColloDB::Utils qw(:math :html);
use DiaColloDB::Persistent;
use DiaColloDB::Profile::Diff;
use IO::File;
use strict;

#use overload
#  #fallback => 0,
#  bool => sub {defined($_[0])},
#  int => sub {$_[0]{N}},
#  '+' => \&add,
#  '+=' => \&_add,
#  '-' => \&diff,
#  '-=' => \&_diff;


##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent);

##==============================================================================
## Constructors etc.

## $prf = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    label => $label,    ##-- string label (used by Multi; undef for none(default))
##    N   => $N,          ##-- total marginal relation frequency
##    f1  => $f1,         ##-- total marginal frequency of target word(s)
##    f2  => \%f2,        ##-- total marginal frequency of collocates: ($i2=>$f2, ...)
##    f12 => \%f12,       ##-- collocation frequencies, %f12 = ($i2=>$f12, ...)
##    titles => \@titles, ##-- item group titles (default:undef: unknown)
##    #
##    eps => $eps,       ##-- smoothing constant (default=0) #0.5
##    score => $func,    ##-- selected scoring function qw(f fm lf lfm mi1 mi3 milf ld ll)
##    milf => \%milf_12, ##-- score: mutual information * logFreq a la Wortprofil; requires compile_milf()
##    mi1 => \%mi1_12,   ##-- score: mutual information; requires compile_mi1()
##    mi3 => \%mi3_12,   ##-- score: mutual information^3 a la Rychly (2008); requires compile_mi3()
##    ld => \%ld_12,     ##-- score: log-dice a la Wortprofil; requires compile_ld()
##    ll => \%ll_12,     ##-- score: 1-sided log-likelihood a la Evert (2008); requires compile_ll()
##    fm => \%fm_12,     ##-- frequency per million score; requires compile_fm()
##    lf => \%lf_12,     ##-- log-frequency ; requires compile_lf()
##    lfm => \%lfm_12,   ##-- log-frequency per million; requires compile_lfm()
##   )
sub new {
  my $that = shift;
  my $prf  = bless({
		    #label=>undef,
		    N=>1,
		    f1=>0,
		    f2=>{},
		    f12=>{},
		    eps=>0, #0.5,
		    #titles=>undef,
		    #ld=>{},
		    @_
		   }, (ref($that)||$that));
  return $prf;
}

## $prf2 = $prf->clone()
## $prf2 = $prf->clone($keep_compiled)
##  + clones %$mp
##  + if $keep_score is true, compiled data is cloned too
sub clone {
  my ($prf,$force) = @_;
  return bless({
		(map {defined($prf->{$_}) ? ($_=>$prf->{$_}) : qw()} qw(label N f1 eps)),
		(map {defined($prf->{$_}) ? ($_=>[@{$prf->{$_}}]) : qw()} qw(titles)),
		(map {defined($prf->{$_}) ? ($_=>{%{$prf->{$_}}}) : qw()} qw(f2 f12)),
		($force
		 ? (
		    ($prf->{score} ? (score=>$prf->{score}) : qw()),
		    (map {$prf->{$_} ? ($_=>{%{$prf->{$_}}}) : qw()} $prf->scoreKeys),
		   )
		 : qw()),
	       }, ref($prf));
}

## $prf2 = $prf->shadow()
## $prf2 = $prf->shadow($keep_compiled)
##  + shadows %$mp
##  + if $keep_score is true, compiled data is shadowed too (all zeroes)
sub shadow {
  my $prf = $_[0]->clone($_[1]);
  $prf->{f1} = $prf->{N} = 0;
  foreach my $key (grep {defined($prf->{$_})} (qw(f2 f12),$prf->scoreKeys)) {
    $_ = 0 foreach (%{$prf->{$key}});
  }
  return $prf;
}



##==============================================================================
## Basic Access


## $label = $prf->label()
##  + get label
sub label {
  return $_[0]{label} // '';
}

## \@titles_or_undef = $prf->titles()
##  + get item titles
sub titles {
  return $_[0]{titles};
}

## @keys = $prf->scoreKeys()
##  + returns known score function keys
sub scoreKeys {
  return qw(mi1 mi3 milf ld ll fm lf lfm);
}

## $bool = $prf->empty()
##  + returns true iff profile is empty
sub empty {
  my $p = shift;
  #return 0 if ($p->{f1}); ##-- do we want to keep nonzero $f1 even if there are no collocates? i think not... moocow 2015-11-02
  return 1 if (!$p->{f1});
  return !$p->size;
}

## $size = $prf->size()
##  + returns total number of collocates defined in profile
sub size {
  my $p = shift;
  my $f = (grep {defined($p->{$_})} qw(f2 f12),$p->scoreKeys)[0];
  return $f ? scalar(keys %{$p->{$f}}) : 0;
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: JSON
##  #+ INHERITED from DiaCollocDB::Persistent
BEGIN {
#  *TO_JSON = \&TO_JSON__table;
}

sub TO_JSON__table {
  my $p = shift;
  my @fnames = (grep {defined($p->{$_})} qw(f2 f12),$p->scoreKeys);
  my @funcs  = @$p{@fnames};
  my @keys   = @funcs ? (keys %{$funcs[0]}) : qw();
  my ($key,$func);
  return {
	  (map {exists($p->{$_}) ? ($_=>$p->{$_}) : qw()} qw(label N f1 eps score)),
	  cols => [@fnames,@{$p->titles//[]}],
	  data => [
		   (map {$key=$_; [(map {$_->{$key}} @funcs), split(/\t/,$key)]} @keys),
		  ],
	 };
}

sub TO_JSON__flat {
  my $p = shift;
  my $keyf = (grep {defined($p->{$_})} qw(f2 f12),$p->scoreKeys)[0];
  my @keys = $keyf ? (keys %{$p->{$keyf}}) : qw();
  return {
	  (map {exists($p->{$_}) ? ($_=>$p->{$_}) : qw()} qw(label N f1 eps)),
	  (keys => [map {[split(' ',$_)]} @keys]),
	  (map {defined($p->{$_}) ? ($_ => [@{$p->{$_}}{@keys}]) : qw()} (qw(f2 f12),$p->scoreKeys)),
	 };
}

##--------------------------------------------------------------
## I/O: Text

## undef = $CLASS_OR_OBJECT->saveTextHeader($fh, hlabel=>$hlabel, titles=>\@titles)
sub saveTextHeader {
  my ($that,$fh,%opts) = @_;
  my @fields = (
		qw(N f1 f2 f12 score),
		(defined($opts{hlabel}) ? $opts{hlabel} : qw()),
		@{$opts{titles} // (ref($that) ? $that->{titles} : undef) // [qw(item2)]},
	       );
  $fh->print(join("\t", map {"#".($_+1).":$fields[$_]"} (0..$#fields)), "\n");
}

## $bool = $prf->saveTextFh($fh, %opts)
##  + %opts:
##    (
##     label => $label,   ##-- override $prf->{label} (used by Profile::Multi), no tab-separators required
##     format => $fmt,    ##-- printf format for scores (default="%f")
##     header => $bool,   ##-- include header-row? (default=1)
##     hlabel => $hlabel, ##-- prefix header item-cells with $hlabel (used by Profile::Multi)
##    )
##  + format (flat, TAB-separated): N F1 F2 F12 SCORE LABEL ITEM2
sub saveTextFh {
  my ($prf,$fh,%opts) = @_;
  my $label = (exists($opts{label}) ? $opts{label} : $prf->{label});
  my ($N,$f1,$f2,$f12) = @$prf{qw(N f1 f2 f12)};
  my $fscore = $prf->{$prf->{score}//'f12'};
  my $fmt    = $opts{format} || '%f';
  binmode($fh,':utf8');
  $prf->saveTextHeader($fh,%opts) if ($opts{header}//1);
  foreach (sort {$fscore->{$b} <=> $fscore->{$a}} keys %$fscore) {
    $fh->print(join("\t",
		    map {$_//0}
		    $N,
		    $f1,
		    $f2->{$_},
		    $f12->{$_},
		    sprintf($fmt,$fscore->{$_}//'nan'),
		    (defined($label) ? $label : qw()),
		    $_),
	       "\n");
  }
  return $prf;
}

##--------------------------------------------------------------
## I/O: HTML

## $bool = $prf->saveHtmlFile($filename_or_handle, %opts)
##  + %opts:
##    (
##     table  => $bool,     ##-- include <table>..</table> ? (default=1)
##     body   => $bool,     ##-- include <html><body>..</html></body> ? (default=1)
##     header => $bool,     ##-- include header-row? (default=1)
##     hlabel => $hlabel,   ##-- prefix header item-cells with $hlabel (used by Profile::Multi), no '<th>..</th>' required
##     label => $label,     ##-- prefix item-cells with $label (used by Profile::Multi), no '<td>..</td>' required
##     format => $fmt,      ##-- printf score formatting (default="%.4f")
##    )
##  + saves rows of the format "N F1 F2 F12 SCORE PREFIX? ITEM2"
sub saveHtmlFile {
  my ($prf,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $prf->logconfess("saveHtmlFile(): failed to open '$file': $!") if (!ref($fh));
  binmode($fh,':utf8');

  $fh->print("<html><body>\n") if ($opts{body}//1);
  $fh->print("<table><tbody>\n") if ($opts{table}//1);
  $fh->print("<tr>",(
		     map {"<th>".htmlesc($_)."</th>"}
		     qw(N f1 f2 f12 score),
		     (defined($opts{hlabel}) ? $opts{hlabel} : qw()),
		     @{$prf->titles//[qw(item2)]},
		    ),
	     "</tr>\n"
	    ) if ($opts{header}//1);

  my ($N,$f1,$f2,$f12) = @$prf{qw(N f1 f2 f12)};
  my $label = (exists($opts{label}) ? $opts{label} : $prf->{label});
  my $fscore = $prf->{$prf->{score}//'f12'};
  my $fmt   = $opts{format} || "%.4f";
  foreach (sort {$fscore->{$b} <=> $fscore->{$a}} keys %$fscore) {
    $fh->print("<tr>", (map {"<td>".htmlesc($_//0)."</td>"}
			$N,
			$f1,
			$f2->{$_},
			$f12->{$_},
			sprintf($fmt, $fscore->{$_}//'nan'),
			(defined($label) ? $label : qw()),
			split(/\t/,$_),
		       ),
	       "</tr>\n");
  }
  $fh->print("</tbody><table>\n") if ($opts{table}//1);
  $fh->print("</body></html>\n") if ($opts{body}//1);
  $fh->close() if (!ref($file));
  return $prf;
}


##==============================================================================
## Compilation

## $prf = $prf->compile($func,%opts)
##  + compile for score-function $func, one of qw(f fm lf lfm mi1 mi3 milf ld ll); default='f'
sub compile {
  my $prf = shift;
  my $func = shift;
  return $prf->compile_f(@_)    if (!$func || $func =~ m{^(?:f(?:req(?:uency)?)?(?:12)?)$}i);
  return $prf->compile_fm(@_)   if ($func =~ m{^(?:f(?:req(?:uency)?)?(?:-?p(?:er)?)?(?:-?m(?:(?:ill)?ion)?)(?:12)?)$}i);
  return $prf->compile_lf(@_)   if ($func =~ m{^(?:l(?:og)?-?f(?:req(?:uency)?)?(?:12)?)$}i);
  return $prf->compile_lfm(@_)  if ($func =~ m{^(?:l(?:og)?-?f(?:req(?:uency)?)?(?:-?p(?:er)?)?(?:-?m(?:(?:ill)?ion)?)(?:12)?)$}i);
  return $prf->compile_ld(@_)   if ($func =~ m{^(?:ld|log-?dice)}i);
  return $prf->compile_ll(@_)   if ($func =~ m{^(?:ll|log-?l(?:ikelihood)?)}i);
  return $prf->compile_milf(@_) if ($func =~ m{^(?:(?:lf)?mi(?:-?lf)?|mutual-?information-?(?:l(?:og)?)?-?f(?:req(?:uency)?)?)?$}i);
  return $prf->compile_mi1(@_)  if ($func =~ m{^(?:mi1|mutual-?information-?1|pmi1?)$}i);
  return $prf->compile_mi3(@_)  if ($func =~ m{^(?:mi3|mutual-?information-?3)$}i);
  $prf->logwarn("compile(): unknown score function '$func'");
  return $prf->compile_f(@_);
}

## $prf = $prf->uncompile()
##  + un-compiles all scores for $prf
sub uncompile {
  delete @{$_[0]}{$_[0]->scoreKeys,'score'};
  return $_[0];
}

## $prf = $prf->compile_clean(%opts)
##  + bashes non-finite compiled score values to undef
sub compile_clean {
  my $prf = shift;
  return $prf if (!$prf->{score} || !$prf->{$prf->{score}});
  foreach (values %{$prf->{$prf->{score}}}) {
    $_ = undef if (isInf($_));
  }
  return $prf;
}

## $prf = $prf->compile_f()
##  + just sets $prf->{score} = 'f12'
sub compile_f {
  $_[0]{score} = 'f12';
  return $_[0];
}

## $prf = $prf->compile_fm()
##  + computes frequency-per-million in $prf->{fm}
##  + sets $prf->{score}='fm'
sub compile_fm {
  my $prf = shift;
  my $pf12 = $prf->{f12};
  my $M    = $prf->{N} / 1000000;
  my $fm   = $prf->{fm} = {};
  my ($i2,$f12);
  while (($i2,$f12)=each(%$pf12)) {
    $fm->{$i2} = $f12 / $M;
  }
  $prf->{score} = 'fm';
  return $prf;
}

## $prf = $prf->compile_lf(%opts)
##  + computes log-frequency profile in $prf->{lf}
##  + sets $prf->{score}='lf'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_lf {
  my ($prf,%opts) = @_;
  my $pf12 = $prf->{f12};
  my $lf   = $prf->{lf} = {};
  my $eps  = $opts{eps} // $prf->{eps} // 0.5; #0
  my ($i2,$f12);
  while (($i2,$f12)=each(%$pf12)) {
    $lf->{$i2} = log2($f12+$eps);
  }
  $prf->{score} = 'lf';
  return $prf->compile_clean();
}

## $prf = $prf->compile_lfm(%opts)
##  + computes log-öfrequency-per-million in $prf->{lfm}
##  + sets $prf->{score}='lfm'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_lfm {
  my ($prf,%opts) = @_;
  my $pf12 = $prf->{f12};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5;
  my $logM = log2($prf->{N}+$eps) - log2(1000000+$eps);
  my $lfm  = $prf->{lfm} = {};
  my ($i2,$f12);
  while (($i2,$f12)=each(%$pf12)) {
    $lfm->{$i2} = log2($f12+$eps) - $logM;
  }
  $prf->{score} = 'lfm';
  return $prf->compile_clean();
}

## $prf = $prf->compile_milf(%opts)
##  + computes MI*logF-profile in $prf->{milf} a la Rychly (2008)
##  + sets $prf->{score}='milf'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
BEGIN {
  *compile_mi = \&compile_milf; ##-- backwards-compatible alias
}
sub compile_milf {
  my ($prf,%opts) = @_;
  my ($N,$f1,$pf2,$pf12) = @$prf{qw(N f1 f2 f12)};
  my $mi = $prf->{milf} = {};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5
  my ($i2,$f2,$f12,$denom);
  while (($i2,$f2)=each(%$pf2)) {
    $f12   = ($pf12->{$i2} // 0) + $eps;
    $denom = (($f1+$eps)*($f2+$eps));
    $mi->{$i2} = (
		  ($f12 >= 0 ? log2($f12) : 0)
		  *
		  ($denom
		   ? log2( (($f12+$eps)*($N+$eps)) / $denom )
		   : 0)
		 );
  }
  $prf->{score} = 'milf';
  return $prf->compile_clean();
}

## $prf = $prf->compile_mi1(%opts)
##  + computes raw poinwise-MI profile in $prf->{mi1}
##  + sets $prf->{score}='mi1'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_mi1 {
  my ($prf,%opts) = @_;
  my ($N,$f1,$pf2,$pf12) = @$prf{qw(N f1 f2 f12)};
  my $mi = $prf->{mi1} = {};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5;
  my ($i2,$f2,$f12,$denom);
  while (($i2,$f2)=each(%$pf2)) {
    $f12 = $pf12->{$i2} // 0;
    $denom = (($f1+$eps)*($f2+$eps));
    $mi->{$i2} = ($denom > 0
		  ? log2( (($f12+$eps)*($N+$eps)) / $denom )
		  : undef
		 );
  }
  $prf->{score} = 'mi1';
  return $prf->compile_clean();
}


## $prf = $prf->compile_mi3(%opts)
##  + computes MI^3 profile in $prf->{mi} a la Rychly (2008)
##  + sets $prf->{score}='mi3'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_mi3 {
  my ($prf,%opts) = @_;
  my ($N,$f1,$pf2,$pf12) = @$prf{qw(N f1 f2 f12)};
  my $mi3 = $prf->{mi3} = {};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5
  my ($i2,$f2,$f12,$denom);
  while (($i2,$f2)=each(%$pf2)) {
    $f12   = $pf12->{$i2} // 0;
    $denom = (($f1+$eps)*($f2+$eps));
    $mi3->{$i2} = ($denom
		   ? log2( (($f12+$eps)**3 * ($N+$eps)) / $denom )
		   : undef
		  );
  }
  $prf->{score} = 'mi3';
  return $prf->compile_clean();
}

## $prf = $prf->compile_ld(%opts)
##  + computes log-dice profile in $prf->{ld} a la Rychly (2008)
##  + sets $pf->{score}='ld'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_ld {
  my ($prf,%opts) = @_;
  my ($N,$f1,$pf2,$pf12) = @$prf{qw(N f1 f2 f12)};
  my $ld = $prf->{ld} = {};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5;
  my ($i2,$f2,$f12,$denom);
  while (($i2,$f2)=each(%$pf2)) {
    $f12   = $pf12->{$i2} // 0;
    $denom = ($f1+$eps) + ($f2+$eps);
    $ld->{$i2} = ($denom
		  ? (14 + log2( (2 * ($f12+$eps)) / $denom ))
		  : undef);
  }
  $prf->{score} = 'ld';
  return $prf->compile_clean();
}

## log0($x) : like log($x) but returns 0 for $x==0
sub log0 {
  no warnings 'uninitialized';
  return $_[0]>0 ? log($_[0]) : 0;
}

## log0d($num,$denom) : like log0($num/$denom), but returns 0 for $num==0 or $denom==0
sub log0d {
  no warnings 'uninitialized';
  return $_[1]==0 ? 0 : log0($_[0]/$_[1]);
}

## $prf = $prf->compile_ll(%opts)
##  + computes 1-sided log-log-likelihood ratio in $prf->{ll} a la Evert (2008)
##  + sets $pf->{score}='ll'
##  + %opts:
##     eps => $eps  #-- clobber $prf->{eps}
sub compile_ll {
  my ($prf,%opts) = @_;
  my $ll = $prf->{ll} = {};
  my $eps = $opts{eps} // $prf->{eps} // 0; #0.5; ##-- IGNORED here
  my ($N,$f1,$pf2,$pf12) = @$prf{qw(N f1 f2 f12)};
  $N  += 2*$eps;
  $f1 += $eps;
  my ($i2,$f2,$f12,$logl);
  my $llmin = 0;
  while (($i2,$f2)=each(%$pf2)) {
    $f12  = ($pf12->{$i2} // 0) + $eps;
    $logl = (##-- raw log-lambda
	     $N<=0 ? 0
	     : ($f12*log0d($f12, ($f1*$f2/$N))
		+($f1-$f12)*log0d(($f1-$f12), (($f1*($N-$f2)/$N)))
		+($f2-$f12)*log0d(($f2-$f12), (($N-$f1)*$f2/$N))
		+($N-$f1-$f2+$f12)*log0d(($N-$f1-$f2+$f12), (($N-$f1)*($N-$f2)/$N))
	       )
	    );
    $ll->{$i2} = (($N && $f12 < ($f1*$f2/$N) ? -1 : 1) ##-- one-sided log-likelihood a la Evert (2008): negative for dis-associations
		  #* $logl			 ##-- raw log-lambda values over-emphasize strong collocates
		  * log0(1+$logl) 		 ##-- extra log() is better for scaling
		  #* sqrt($logl)                 ##-- extra sqrt() for scaling
		  #* ($logl**(1/3))              ##-- extra cube-root for scaling
		 );
  }

  $prf->{score} = 'll';
  return $prf->compile_clean();
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
sub which {
  my ($prf,%opts) = @_;

  ##-- trim: scoring function
  my $score = $prf->{$prf->{score}//'f12'}
    or $prf->logconfess("trim(): no profile scores for '$prf->{score}'");
  my $bad = {};

  ##-- which: by user-specified cutoff
  if ((my $cutoff=$opts{cutoff}//'') ne '') {
    my ($key,$val);
    while (($key,$val) = each %$score) {
      $bad->{$key} = undef if ($val < $cutoff);
    }
  }

  ##-- which: k-best
  my $kbest;
  if (defined($kbest = $opts{kbest}) && $kbest > 0) {
    my @keys = sort {$score->{$b} <=> $score->{$a}} grep {!exists($bad->{$_})} keys %$score;
    if (@keys > $kbest) {
      splice(@keys, 0, $kbest);
      @$bad{@keys} = qw();
    }
  }

  ##-- which: abs k-best
  my $kbesta;
  if (defined($kbesta = $opts{kbesta}) && $kbesta > 0) {
    my @keys = sort {abs($score->{$b}) <=> abs($score->{$a})} grep {!exists($bad->{$_})} keys %$score;
    if (@keys > $kbesta) {
      splice(@keys, 0, $kbesta);
      @$bad{@keys} = qw();
    }
  }

  ##-- which: return
  if (($opts{return}//'') eq 'bad') {
    return lc($opts{as}//'array') eq 'hash' ?  $bad : [keys %$bad];
  }
  return lc($opts{as}//'array') eq 'hash' ? {map {exists($bad->{$_}) ? qw() : ($_=>undef)} keys %$score } : [grep {!exists($bad->{$_})} keys %$score];
}


## $prf = $prf->trim(%opts)
##  + %opts:
##    (
##     kbest => $kbest,    ##-- retain only $kbest items (by score value)
##     kbesta => $kbesta,  ##-- retain only $kbest items (by score absolute value)
##     cutoff => $cutoff,  ##-- retain only items with $prf->{$prf->{score}}{$item} >= $cutoff
##     keep => $keep,      ##-- retain keys @$keep (ARRAY) or keys(%$keep) (HASH)
##     drop => $drop,      ##-- drop keys @$drop (ARRAY) or keys(%$drop) (HASH)
##    )
##  + this COULD be factored out into s.t. like $prf->trim($prf->which(%opts)), but it's about 15% faster inline
sub trim {
  my ($prf,%opts) = @_;

  ##-- trim: scoring function
  my $score = $prf->{$prf->{score}//'f12'}
    or $prf->logconfess("trim(): no profile scores for '$prf->{score}'");

  ##-- trim: by user request: keep
  if (defined($opts{keep})) {
    my $keep = (UNIVERSAL::isa($opts{keep},'ARRAY') ? {map {($_=>undef)} @{$opts{keep}}} : $opts{keep});
    my @trim = grep {!exists($keep->{$_})} keys %$score;
    foreach (grep {defined($prf->{$_})} qw(f2 f12),$prf->scoreKeys) {
      delete @{$prf->{$_}}{@trim};
      $_ //= 0 foreach (@{$prf->{$_}}{keys %$keep});
    }
  }

  ##-- trim: by user request: drop
  if (defined($opts{drop})) {
    my $drop = (UNIVERSAL::isa($opts{drop},'ARRAY') ? $opts{drop} : [keys %{$opts{drop}}]);
    delete @{$prf->{$_}}{@$drop} foreach (grep {defined($prf->{$_})} qw(f2 f12),$prf->scoreKeys);
  }

  ##-- trim: by user-specified cutoff
  if ((my $cutoff=$opts{cutoff}//'') ne '') {
    my @trim = qw();
    my ($key,$val);
    while (($key,$val) = each %$score) {
      push(@trim,$key) if ($val < $cutoff);
    }
    delete @{$prf->{$_}}{@trim} foreach (grep {defined($prf->{$_})} qw(f2 f12),$prf->scoreKeys);
  }

  ##-- trim: k-best
  my $kbest;
  if (defined($kbest = $opts{kbest}) && $kbest > 0) {
    my @trim = sort {$score->{$b} <=> $score->{$a}} keys %$score;
    if (@trim > $kbest) {
      splice(@trim, 0, $kbest);
      delete @{$prf->{$_}}{@trim} foreach (grep {defined($prf->{$_})} qw(f2 f12),$prf->scoreKeys);
    }
  }

  ##-- trim: abs k-best
  my $kbesta;
  if (defined($kbesta = $opts{kbesta}) && $kbesta > 0) {
    my @trim = sort {abs($score->{$b}) <=> abs($score->{$a})} keys %$score;
    if (@trim > $kbesta) {
      splice(@trim, 0, $kbesta);
      delete @{$prf->{$_}}{@trim} foreach (grep {defined($prf->{$_})} qw(f2 f12),$prf->scoreKeys);
    }
  }

  return $prf;
}

##==============================================================================
## Stringification

## $i2s = $prf->stringify_map( $obj)
## $i2s = $prf->stringify_map(\@key2str)
## $i2s = $prf->stringify_map(\&key2str)
## $i2s = $prf->stringify_map(\%key2str)
##  + guts for stringify: get a map for stringification
sub stringify_map {
  my ($prf,$i2s) = @_;
  no warnings 'numeric';
  if (UNIVERSAL::can($i2s,'i2s')) {
    $i2s = { map {($_=>$i2s->i2s($_))} sort {$a<=>$b} keys %{$prf->{$prf->{score}//'f12'}} };
  }
  elsif (UNIVERSAL::isa($i2s,'CODE')) {
    $i2s = { map {($_=>$i2s->($_))} sort {$a<=>$b} keys %{$prf->{$prf->{score}//'f12'}} };
  }
  return $i2s;
}


## $prf = $prf->stringify( $obj)
## $prf = $prf->stringify(\@key2str)
## $prf = $prf->stringify(\&key2str)
## $prf = $prf->stringify(\%key2str)
##  + stringifies profile (destructive) via $obj->i2s($key2), $key2str->($i2) or $key2str->{$i2}
sub stringify {
  my ($prf,$i2s) = @_;
  $i2s = $prf->stringify_map($i2s);
  if (UNIVERSAL::isa($i2s,'HASH')) {
    foreach (grep {defined $prf->{$_}} qw(f2 f12),$prf->scoreKeys) {
      my $sh = {};
      @$sh{@$i2s{keys %{$prf->{$_}}}} = values %{$prf->{$_}};
      $prf->{$_} = $sh;
    }
    return $prf;
  }
  elsif (UNIVERSAL::isa($i2s,'ARRAY')) {
    foreach (grep {defined $prf->{$_}} qw(f2 f12),$prf->scoreKeys) {
      my $sh = {};
      @$sh{@$i2s[keys %{$prf->{$_}}]} = values %{$prf->{$_}};
      $prf->{$_} = $sh;
    }
    return $prf;
  }

  $prf->logconfess("stringify(): don't know how to stringify via '", ($i2s//'undef'). "'");
}

##==============================================================================
## Algebraic operations

## $prf = $prf->_add($prf2,%opts)
##  + adds $prf2 frequency data to $prf (destructive)
##  + implicitly un-compiles $prf
##  + %opts:
##     N  => $bool, ##-- whether to add N values (default:true)
##     f1 => $bool, ##-- whether to add f1 values (default:true)
sub _add {
  my ($pa,$pb,%opts) = @_;
  $pa->{N}  += $pb->{N}  if (!exists($opts{N}) || $opts{N});
  $pa->{f1} += $pb->{f1} if (!exists($opts{f1}) || $opts{f1});
  my ($af2,$af12) = @$pa{qw(f2 f12)};
  my ($bf2,$bf12) = @$pb{qw(f2 f12)};
  foreach (keys %$bf12) {
    $af2->{$_}  += ($bf2->{$_} // 0);
    $af12->{$_} += ($bf12->{$_} // 0);
  }
  return $pa->uncompile();
}

## $prf3 = $prf1->add($prf2,%opts)
##  + returns sum of $prf1 and $prf2 frequency data (destructive)
##  + see _add() method for %opts
sub add {
  return $_[0]->clone->_add(@_[1..$#_]);
}

## $psum = $CLASS_OR_OBJECT->_sum(\@profiles,%opts)
##  + returns a profile representing sum of \@profiles, passing %opts to _add()
##  + if called as a class method and \@profiles contains only 1 element, that element is returned
##  + otherwise, \@profiles are added to the (new) object
sub _sum {
  my ($that,$profiles,%opts) = @_;
  return $profiles->[0] if (!ref($that) && @$profiles==1);
  my $psum = ref($that) ? $that : $that->new();
  $psum->_add($_,%opts) foreach (@$profiles);
  return $psum;
}

## $psum = $CLASS_OR_OBJECT->sum(\@profiles,%opts)
##  + returns a new profile representing sum of \@profiles
sub sum {
  my $that = shift;
  return (ref($that)||$that)->new->_sum(@_);
}

## $diff = $prf1->diff($prf2,%opts)
##  + wraps DiaColloDB::Profile::Diff->new($prf1,$prf2,%opts)
##  + %opts:
##     N  => $bool, ##-- whether to subtract N values (default:true)
##     f1 => $bool, ##-- whether to subtract f1 values (default:true)
##     f2 => $bool, ##-- whether to subtract f2 values (default:true)
##     f12 => $bool, ##-- whether to subtract f12 values (default:true)
##     score => $bool, ##-- whether to subtract score values (default:true)
sub diff {
  return DiaColloDB::Profile::Diff->new(@_);
}


##==============================================================================
## Footer
1;

__END__
