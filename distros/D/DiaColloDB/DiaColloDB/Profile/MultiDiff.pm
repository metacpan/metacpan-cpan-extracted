## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Profile::MultiDiff.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, co-frequency profile diffs, by date


package DiaColloDB::Profile::MultiDiff;
use DiaColloDB::Profile::Multi;
use DiaColloDB::Profile::Diff;
use DiaColloDB::Utils qw(:html :list);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Profile::Multi);

##==============================================================================
## Constructors etc.

## $mpd = CLASS_OR_OBJECT->new(%args)
## $mpd = CLASS_OR_OBJECT->new($mp1,$mp2,%args)
## + %args, object structure:
##   (
##    profiles => \@profiles,   ##-- ($profile, ...) : sub-diffs, with {label} key
##    titles   => \@titles,     ##-- item group titles (default:undef: unknown)
##    qinfo    => \%qinfo,      ##-- query info (optional; keys prefixed with 'a' or 'b'): see DiaColloDB::Profile::Multi
##   )
## + additional %args:
##   (
##    populate => $bool,        ##-- auto-populate() if $mp1 and $mp2 are specified? (default=1)
##    diff     => $diffop,      ##-- low-level diff operation (see DiaColloDB::Profile::Diff)
##   )
sub new {
  my $that = shift;
  my $mp1  = UNIVERSAL::isa(ref($_[0]),'DiaColloDB::Profile::Multi') ? shift : undef;
  my $mp2  = UNIVERSAL::isa(ref($_[0]),'DiaColloDB::Profile::Multi') ? shift : undef;
  my %opts = @_;
  my $populate = $opts{populate}//1;
  delete($opts{populate});
  my $mpd  = $that->SUPER::new(%opts);
  return $mpd->populate($mp1,$mp2) if ($populate && $mp1 && $mp2);
  return $mpd;
}


## $mp2 = $mp->clone()
## $mp2 = $mp->clone($keep_compiled)
##  + clones %$mp
##  + if $keep_score is true, compiled data is cloned too
##  + INHERITED from DiaColloDB::Profile::Multi

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: JSON
##  + mostly INHERITED from DiaCollocDB::Persistent

## $obj = $CLASS_OR_OBJECT->loadJsonData( $data,%opts)
##  + guts for loadJsonString(), loadJsonFile()
sub loadJsonData {
  my $that = shift;
  my $mp   = $that->DiaColloDB::Persistent::loadJsonData(@_);
  foreach (@{$mp->{profiles}//[]}) {
    bless($_,'DiaColloDB::Profile::Diff');
    bless($_->{prf1}, 'DiaColloDB::Profile') if ($_->{prf1});
    bless($_->{prf2}, 'DiaColloDB::Profile') if ($_->{prf2});
  }
  return $mp;
}

##--------------------------------------------------------------
## I/O: Text

## undef = $CLASS_OR_OBJECT->saveTextHeader($fh, hlabel=>$hlabel, titles=>\@titles)
sub saveTextHeader {
  my ($that,$fh,%opts) = @_;
  DiaColloDB::Profile::Diff::saveTextHeader($that,$fh,hlabel=>'label',@_);
}

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh(); INHERITED from DiaCollocDB::Persistent

## $bool = $mp->saveTextFh($fh,%opts)
##  + save text representation to a filehandle (guts)
##  + INHERITED from DiaCollocDB::Profile::Multi

##--------------------------------------------------------------
## I/O: HTML

## $bool = $mp->saveHtmlFile($filename_or_handle, %opts)
##  + %opts:
##    (
##     table  => $bool,     ##-- include <table>..</table> ? (default=1)
##     body   => $bool,     ##-- include <html><body>..</html></body> ? (default=1)
##     verbose => $bool,    ##-- include verbose output? (default=0)
##     qinfo  => $varname,  ##-- include <script> for qinfo data? (default='qinfo')
##     header => $bool,     ##-- include header-row? (default=1)
##     format => $fmt,      ##-- printf score formatting (default="%.4f")
##    )
sub saveHtmlFile {
  my ($mp,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $mp->logconfess("saveHtmlFile(): failed to open '$file': $!") if (!ref($fh));
  $fh->print("<html><body>\n") if ($opts{body}//1);
  $fh->print("<script type=\"text/javascript\">$opts{qinfo}=", DiaColloDB::Utils::saveJsonString($mp->{qinfo}, pretty=>0), ";</script>\n")
    if ($mp->{qinfo} && ($opts{qinfo} //= 'qinfo'));
  $fh->print("<table><tbody>\n") if ($opts{table}//1);
  $fh->print("<tr>",(
		     map {"<th>".htmlesc($_)."</th>"}
		     ($opts{verbose} ? (map {("${_}a","${_}b")} qw(N f1 f2 f12)) : qw()),
		     qw(ascore bscore diff label),
		     @{$mp->{titles}//[qw(item2)]},
		    ),
	     "</tr>\n"
	    ) if ($opts{header}//1);
  my $ps = $mp->{profiles};
  foreach (@$ps) {
    $_->saveHtmlFile($file, %opts,table=>0,body=>0,header=>0)
      or $mp->logconfess("saveHtmlFile() saved for sub-profile with label '", $_->label, "': $!");
  }
  $fh->print("</tbody><table>\n") if ($opts{table}//1);
  $fh->print("</body></html>\n") if ($opts{body}//1);
  $fh->close() if (!ref($file));
  return $mp;
}

##==============================================================================
## Compilation

##  @ppairs = $CLASS_OR_OBJECT->align($mp1,$mp2)
## \@ppairs = $CLASS_OR_OBJECT->align($mp1,$mp2)
##  + aligns subprofile-pairs from $mp1 and $mp2
##  + INHERITED from DiaColloDB::Profile::Multi

## $mpd = $mpd->populate($mp1,$mp2,%opts)
##  + populates multi-diff by subtracting $mp2 sub-profile scores from $mp1
##  + uses $mpd->align() to align sub-profiles
##  + %opts: clobbers %$mpd
sub populate {
  my ($mpd,$mpa,$mpb,%opts) = @_;
  @$mpd{keys %opts} = values %opts;
  @{$mpd->{profiles}} = map {
    DiaColloDB::Profile::Diff->new($_->[0],$_->[1], diff=>$mpd->{diff})
  } @{$mpd->align($mpa,$mpb)};
  if ($mpa->{qinfo} || $mpb->{qinfo}) {
    $mpd->{qinfo} = {
		     (map {("a$_"=>$mpa->{qinfo}{$_})} keys %{$mpa->{qinfo}//{}}),
		     (map {("b$_"=>$mpb->{qinfo}{$_})} keys %{$mpb->{qinfo}//{}}),
		    };
  }
  return $mpd;
}

## $mp_or_undef = $mp->compile($func,%opts)
##  + compile all sub-profiles for score-function $func; default='f'
##  + INHERITED from DiaColloDB::Profile::Multi

## $mp = $mp->uncompile()
##  + un-compiles all scores for $mp
##  + INHERITED from DiaColloDB::Profile::Multi

## $class = $CLASS_OR_OBJECT->pclass()
##  + class for psum()
sub pclass {
  return 'DiaColloDB::Profile::Diff';
}

## $prf = $mp->psum()
## $prf = $CLASS_OR_OBJECT->psum(\@profiles)
##  + sum of sub-profiles, compiled as for $profiles[0]
##  + used for global trimming

## $mp_or_undef = $mp->trim(%opts)
##  + calls $prf->trim(%opts) for each sub-profile $prf
##  + INHERITED from DiaColloDB::Profile::Multi

## $mp_or_undef = $CLASS_OR_OBJECT->trimPairs(\@pairs, %opts)
##  + %opts: as for DiaColloDB::Profile::Multi::trim(), including 'global' and 'diff' options
sub trimPairs {
  my ($that,$ppairs,%opts) = @_;

  ##-- defaults
  $opts{kbest}  //= -1;
  $opts{cutoff} //= '';
  $opts{global} //= 0;
  $opts{diff}   //= 'adiff';

  if ($opts{global}) {
    ##-- (pre-)trim globally
    my $gpa = DiaColloDB::Profile::Multi->sumover(luniq([map {$_->[0]} @$ppairs]), eps=>$opts{eps});
    my $gpb = DiaColloDB::Profile::Multi->sumover(luniq([map {$_->[1]} @$ppairs]), eps=>$opts{eps});
    DiaColloDB::Profile::Diff->pretrim($gpa,$gpb,%opts);

    my $gdiff = DiaColloDB::Profile::Diff->new($gpa,$gpb, diff=>$opts{diff});
    my %keep  = map {($_=>undef)} @{$gdiff->which( DiaColloDB::Profile::Diff->diffkbest($opts{diff})=>$opts{kbest} )};
    $_->trim(keep=>\%keep) foreach (grep {$_} map {@$_} @$ppairs);
  }
  else {
    ##-- (pre-)trim locally
    foreach (@$ppairs) {
      DiaColloDB::Profile::Diff->pretrim(@$_[0,1],%opts);
    }
  }

  return $ppairs;
}

## $mp = $mp->stringify( $obj)
## $mp = $mp->stringify(\@key2str)
## $mp = $mp->stringify(\&key2str)
## $mp = $mp->stringify(\%key2str)
##  + stringifies multi-profile (destructive) via $obj->i2s($key2), $key2str->($i2) or $key2str->{$i2}
##  + INHERITED from DiaColloDB::Profile::Multi

##==============================================================================
## Binary operations

## $mp = $mp->_add($mp2,%opts)
##  + adds $mp2 frequency data to $mp (destructive)
##  + implicitly un-compiles sub-profiles
##  + %opts: passed to Profile::_add()
##  + INHERITED but probably useless

## $mp3 = $mp1->add($mp2,%opts)
##  + returns sum of $mp1 and $mp2 frequency data (destructive)
##  + %opts: passed to Profile::_add()
##  + INHERITED but probably useless

## $diff = $mp1->diff($mp2)
##  + returns score-diff of $mp1 and $mp2 frequency data (destructive)
##  + INHERITED but probably useless

##==============================================================================
## Package DiaColloDB::Profile::Multi::Diff : alias
package DiaColloDB::Profile::Multi::Diff;
our @ISA = qw(DiaColloDB::Profile::MultiDiff);

##==============================================================================
## Package DiaColloDB::Profile::Diff::Multi : alias
package DiaColloDB::Profile::Diff::Multi;
our @ISA = qw(DiaColloDB::Profile::MultiDiff);


##==============================================================================
## Footer
1;

__END__
