## -*- Mode: CPerl -*-
## File: DiaColloDB::Document::DDCTabs.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source document, DDC tab-dump

package DiaColloDB::Document::DDCTabs;
use DiaColloDB::Document;
use IO::File;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Document);

##==============================================================================
## Constructors etc.

## $doc = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- parsing options
##    eosre => $re,        ##-- EOS regex (empty or undef for file-breaks only; default='^$')
##    utf8  => $bool,      ##-- enable utf8 parsing? (default=1)
##    trimPND    => $bool, ##-- create trimmed "pnd" meta-attribute? (default=1)
##    trimAuthor => $bool, ##-- trim "author" meta-attribute (eliminate DTA PNDs)? (default=1)
##    trimGenre  => $bool, ##-- create trimmed "genre" meta-attribute? (default=1)
##    foreign => $bool,    ##-- alias for trimAuthor=0 trimPND=0 trimGenre=0
##    ##
##    ##-- document data
##    date   =>$date,     ##-- year
##    wf     =>$iw,       ##-- index-field for $word attribute (default=0)
##    pf     =>$ip,       ##-- index-field for $pos attribute (default=1)
##    lf     =>$il,       ##-- index-field for $lemma attribute (default=2)
##    pagef  =>$ipage,    ##-- index-field for $page attribute (default=undef:none)
##    tokens =>\@tokens,  ##-- tokens, including undef for EOS
##    meta   =>\%meta,    ##-- document metadata (e.g. author, title, collection, ...)
##                        ##   + may also generate special $meta->{genre} as 1st component of $meta->{textClass} if available
##   )
## + each token in @tokens is a HASH-ref {w=>$word,p=>$pos,l=>$lemma,...}
## + default attribute positions ($iw,$ip,$il,$ipage) are overridden doc lines '%%$DDC:index[INDEX]=LONGNAME w' etc if present
sub new {
  my $that = shift;
  my $doc  = $that->SUPER::new(
			       utf8=>1,
			       trimPND=>1,
			       trimAuthor=>1,
			       trimGenre=>1,
			       eosre=>qr{^$},
			       wf=>0,
			       pf=>1,
			       lf=>2,
			       pagef=>undef,
			       @_, ##-- user arguments
			      );
  return $doc;
}

##==============================================================================
## API: I/O

## $ext = $doc->extension()
##  + default extension, for Corpus::Compiled
sub extension {
  return '.tabs';
}

##--------------------------------------------------------------
## API: I/O: parse

## $bool = $doc->fromFile($filename_or_fh, %opts)
##  + parse tokens from $filename_or_fh
##  + %opts : clobbers %$doc
sub fromFile {
  my ($doc,$file,%opts) = @_;
  $doc = $doc->new() if (!ref($doc));
  @$doc{keys %opts} = values %opts;
  $doc->{label} = ref($file) ? "$file" : $file;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  $doc->logconfess("fromFile(): cannot open file '$file': $!") if (!ref($fh));
  binmode($fh,':utf8') if ($doc->{utf8});

  my ($wf,$pf,$lf,$pagef) = map {($_//-1)} @$doc{qw(wf pf lf pagef)};
  my $tokens   = $doc->{tokens};
  @$tokens     = qw();
  my $meta     = $doc->{meta};
  %$meta       = qw();
  my $eos      = undef;
  my $eosre    = $doc->{eosre};
  $eosre       = qr{$eosre} if ($eosre && !ref($eosre));
  my $last_was_eos = 1;
  my $is_eos  = 0;
  my $curpage = '';
  my ($w,$p,$l,$page);
  while (defined($_=<$fh>)) {
    chomp;
    if (/^%%/) {
      if (/^%%(?:\$DDC:meta\.date_|\$?date)=([0-9]+)/) {
	$doc->{date} = $1;
      }
      if (/^%%\$DDC:meta\.([^=]+)=(.*)$/) {
	$meta->{$1} = $2;
      }
      elsif (/^%%\$DDC:index\[([0-9]+)\]=Token\b/ || /^%%\$DDC:index\[([0-9]+)\]=\S+ w$/) {
	$wf = $doc->{wf} = $1;
      }
      elsif (/^%%\$DDC:index\[([0-9]+)\]=Pos\b/ || /^%%\$DDC:index\[([0-9]+)\]=\S+ p$/) {
	$pf = $doc->{pf} = $1;
      }
      elsif (/^%%\$DDC:index\[([0-9]+)\]=Lemma\b/ || /^%%\$DDC:index\[([0-9]+)\]=\S+ l$/) {
	$lf = $doc->{lf} = $1;
      }
      elsif (/^%%\$DDC:index\[([0-9]+)\]=Pos\b/ || /^%%\$DDC:index\[([0-9]+)\]=\S+ page$/) {
	$pagef = $doc->{pagef} = $1;
      }
      elsif (/^%%\$DDC:BREAK.([^=\[\]]+)/) {
	push(@$tokens,"#$1");
      }
      elsif (/^%%\$DDC:PAGE=/) {
	push(@$tokens,"#page");
      }
      if ($eosre && $_ =~ $eosre) {
	push(@$tokens,$eos) if (!$last_was_eos);
	$last_was_eos = 1;
      }
      next;
    }
    elsif ($eosre && $_ =~ $eosre) {
      push(@$tokens,$eos) if (!$last_was_eos);
      $last_was_eos = 1;
      next;
    }
    ($w,$p,$l,$page) = (split(/\t/,$_))[$wf,$pf,$lf,$pagef];

    ##-- honor dta-style $page index
    if ($pagef > 0 && $page ne $curpage) {
      push(@$tokens, "#page");
      $curpage = $page;
    }

    ##-- add token
    push(@$tokens, {w=>($w//''), p=>($p//''), l=>($l//'')});
    $last_was_eos = 0;
  }
  push(@$tokens,$eos) if (!$last_was_eos);

  if (!$doc->{foreign}) {
    ##-- hack: compute top-level $meta->{genre} from $meta->{textClass} if requested
    $meta->{genre} //= $meta->{textClass};
    $meta->{genre} =~ s/\:.*$//
      if ($doc->{trimGenre} && defined($meta->{genre}));

    ##-- hack: compute/trim top-level $meta->{pnd} if requested
    $meta->{pnd} //= $meta->{author};
    if ($doc->{trimPND} && defined($meta->{pnd})) {
      $meta->{pnd} = join(' ', ($meta->{pnd} =~ m/\#[0-9a-zA-Z]+/g));
      delete($meta->{pnd}) if (($meta->{pnd}//'') eq '');
    }

    ##-- hack: trim top-level $meta->{author} if requested
    $meta->{author} =~ s/\s*\([^\)]*\)$//
      if ($doc->{trimAuthor} && defined($meta->{author}));
  }

  $fh->close() if (!ref($file));
  return $doc;
}

##==============================================================================
## Footer
1;

__END__




