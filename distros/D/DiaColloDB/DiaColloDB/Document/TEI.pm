## -*- Mode: CPerl -*-
## File: DiaColloDB::Document::TEI.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source document, TEI-likie format (w,p,l, #s,#p)

package DiaColloDB::Document::TEI;
use DiaColloDB::Document;
use XML::LibXML; ##-- require v1.70 for load_xml() method
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
##    tei_ns_NS     => $uri,   ##-- namespace URI for user-defined XPaths
##    tei_date      => $xpath, ##-- XPath for parsing document date, relative to document root
##    tei_meta_ATTR => $xpath, ##-- XPath for parsing meta-attribute ATTR, relative to document root
##    tei_word_ATTR => $xpath, ##-- XPath for parsing token-attribute ATTR, relative to //w element
##    tei_break_BRK => $xpath, ##-- XPath for parsing break nodes, relative to document root
##    tei_eos       => $break, ##-- default break-level (default: 's')
##    ##
##    ##-- document data
##    date   =>$date,     ##-- year
##    tokens =>\@tokens,  ##-- tokens, including undef for EOS
##    meta   =>\%meta,    ##-- document metadata (e.g. author, title, collection, ...)
##                        ##   + parsed from /D-Spin/MetaData/source[@type] for $type !~ /^meta:ATTR/
##   )
## + default namespaces:
##   (
##    tei_ns_tei => "http://www.tei-c.org/ns/1.0",
##   )
## + default XPaths:
##   (
##    tei_date        => 'teiHeader/fileDesc/publicationStmt/date'
##    tei_meta_title  => 'teiHeader/fileDesc/titleStmt/title',
##    tei_meta_author => 'teiHeader/fileDesc/titleStmt/author',
##    tei_meta_textClass => 'teiHeader/fileDesc/profileDesc/textClass/classCode',
##    tei_word_w         => 'text()',
##    tei_word_l         => '@lemma',
##    tei_word_p         => '@type',
##    tei_break_s        => '//text//s',
##    tei_break_p        => '//text//p',
##    tei_break_div      => '//text//div',
##    tei_break_page     => '//text//pb',
##   )
sub new {
  my $that = shift;
  my $doc  = $that->SUPER::new(
			       ##-- default xpaths
			       tei_ns_tei      => "http://www.tei-c.org/ns/1.0",
			       tei_date        => '*[local-name()="teiHeader"]/*[local-name()="fileDesc"]/*[local-name()="publicationStmt"]/*[local-name()="date"]',
			       tei_meta_title  => '*[local-name()="teiHeader"]/*[local-name()="fileDesc"]/*[local-name()="titleStmt"]/*[local-name()="title"]',
			       tei_meta_author => '*[local-name()="teiHeader"]/*[local-name()="fileDesc"]/*[local-name()="titleStmt"]/*[local-name()="author"]',
			       tei_meta_textClass => '*[local-name()="teiHeader"]/*[local-name()="fileDesc"]/*[local-name()="profileDesc"]/*[local-name()="textClass"]/*[local-name()="classCode"]',
			       ##
			       tei_word_w => 'text()',
			       tei_word_p => '@type',
			       tei_word_l => '@lemma',
			       ##
			       tei_break_s    => '//*[local-name()="text"]//*[local-name()="s"]',
			       tei_break_p    => '//*[local-name()="text"]//*[local-name()="p"]',
			       tei_break_div  => '//*[local-name()="text"]//*[local-name()="div"]',
			       tei_break_page => '//*[local-name()="text"]//*[local-name()="pb"][1]',
			       ##
			       tei_eos => 's',

			       ##-- user arguments
			       @_,
			      );
  return $doc;
}

##==============================================================================
## API: I/O

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

  ##-- setup xpaths
  my (%xp_meta,%xp_word,%xp_break);
  my $xpc   = XML::LibXML::XPathContext->new;
  foreach (keys %$doc) {
    if (/^tei_meta_(.*)$/) {
      $xp_meta{$1} = $doc->{$_};
    }
    elsif (/^tei_word_(.*)$/) {
      $xp_word{$1} = $doc->{$_};
    }
    elsif (/^tei_break_(.*)$/) {
      $xp_break{$1} = $doc->{$_};
    }
    elsif (/^tei_ns_(.*)$/) {
      $xpc->registerNs($1, $doc->{$_}) if ($doc->{$_});
    }
  }
  delete @xp_meta{grep {!$xp_meta{$_}} keys %xp_meta};
  delete @xp_word{grep {!$xp_word{$_}} keys %xp_word};
  delete @xp_break{grep {!$xp_break{$_}} keys %xp_break};

  ##-- parse xml document
  my $xdoc = XML::LibXML->load_xml(location => $file)
    or $doc->logconfess("fromFile(): cannot load file '$file' as XML document: $!");

  my $tokens   = $doc->{tokens};
  @$tokens     = qw();
  my $meta     = $doc->{meta};
  %$meta       = qw();

  ##-- parse: basic
  my $xroot = $xdoc->documentElement;

  ##-- parse: metadata
  my ($akey,$xp,$nods);
  while (($akey,$xp) = each %xp_meta) {
    next if (!defined($nods = $xpc->findnodes($xp, $xroot)));
    $meta->{$akey} = join(':', map {nodval($_)} @$nods) if (@$nods);
  }
  ##-- parse: date (integer values only)
  $doc->{date}  = nodval($xpc->findnodes($doc->{tei_date}, $xroot));
  ($doc->{date} //= $meta->{date} // $meta->{date_} // 0) =~ s/^[^0-9]*([0-9]+)[^0-9].*$//;

  ##-- parse: tokens
  my %key2w = qw(); ## $key => \%w ; additional keys "n_"=>$w_pos
  my ($wnod,$anod,$w);
  my $nw = 0;
  foreach $wnod ($xpc->findnodes('//*[local-name()="text"]//*[local-name()="w"]',$xroot)) {
    $w    = $key2w{$wnod->unique_key} = { n_=>$nw++ };
    while (($akey,$xp) = each %xp_word) {
      next if (!defined($nods = $xpc->findnodes($xp, $wnod)));
      $w->{$akey} = join(':', map {nodval($_)} @$nods) if (@$nods);
    }
  }

  ##-- parse: breaks; setup $w->{break_before_} = {$brk=>undef,...};  %break_final = ($brk=>undef,...)
  my ($bkey,$bnod);
  my (%break_final);
  while (($bkey,$xp) = each %xp_break) {
    foreach $bnod ($xpc->findnodes($xp,$xroot)) {
      if (defined($wnod = $xpc->findnodes('descendant::*[local-name()="w"][1]',$bnod)->[0])) {
	$w->{break_before_}{$bkey} = undef if (defined($w=$key2w{$wnod->unique_key}));
      }
      if (defined($wnod = $xpc->findnodes('following::*[local-name()="w"][1]',$bnod)->[0])) {
	$w->{break_before_}{$bkey} = undef if (defined($w=$key2w{$wnod->unique_key}));
      } else {
	$break_final{$bkey} = undef;
      }
    }
  }

  ##-- construct: tokens
  my $eos = $doc->{tei_eos};
  push(@$tokens,'#file'); ##-- always include 'file' break
  foreach $w (sort {$a->{n_} <=> $b->{n_}} values %key2w) {
    if ($w->{break_before_}) {
      push(@$tokens,
	   ($eos && exists($w->{break_before_}{$eos}) ? undef : qw()),
	   (map {"#$_"} sort keys %{$w->{break_before_}}),
	  );
    }
    delete @$w{qw(break_before_ n_)};
    push(@$tokens,$w);
  }
  push(@$tokens,
       (map {"#$_"} sort keys %break_final),
       undef,  ##-- always push final eos
      );

  return $doc;
}

##==============================================================================
## XPath utilities

## $val = nodval($nod)
sub nodval {
  return undef if (!defined($_[0]));
  return UNIVERSAL::isa($_[0],'XML::LibXML::Attribute') ? $_[0]->nodeValue : $_[0]->textContent;
}

##==============================================================================
## Footer
1;

__END__




