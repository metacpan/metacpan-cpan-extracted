## -*- Mode: CPerl -*-
## File: DiaColloDB::Document::TCF.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source document, TCF format (tokens, sentences, postags, lemmas)

package DiaColloDB::Document::TCF;
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
##    #(none)
##    ##
##    ##-- document data
##    date   =>$date,     ##-- year
##    tokens =>\@tokens,  ##-- tokens, including undef for EOS
##    meta   =>\%meta,    ##-- document metadata (e.g. author, title, collection, ...)
##                        ##   + parsed from /D-Spin/MetaData/source[@type] for $type !~ /^meta:ATTR/
##   )
## + namespaces:
##    dspin : http://www.dspin.de/data
##    meta  : http://www.dspin.de/data/metadata
## + each token in @tokens is a HASH-ref {w=>$word,p=>$pos,l=>$lemma,...}
sub new {
  my $that = shift;
  my $doc  = $that->SUPER::new(
			       @_, ##-- user arguments
			      );
  return $doc;
}

##==============================================================================
## API: I/O


## $ext = $doc->extension()
##  + default extension, for Corpus::Compiled
sub extension {
  return '.tcf';
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

  my $xdoc = XML::LibXML->load_xml(location => $file)
    or $doc->logconfess("fromFile(): cannot load file '$file' as XML document: $!");

  my $tokens   = $doc->{tokens};
  @$tokens     = qw();
  my $meta     = $doc->{meta};
  %$meta       = qw();
  my $eos      = undef;

  ##-- parse: basic
  my $xroot = $xdoc->documentElement;

  ##-- parse: metadata
  if (defined(my $xmeta = [$xroot->getChildrenByLocalName("MetaData")]->[0])) {
    ##-- parse: metadata: : /*/MetaData/source[@type="meta:KEY"]
    my ($type);
    foreach (@{$xmeta->getChildrenByLocalName("source")}) {
      $type = $_->getAttribute('type');
      $meta->{$1} = $_->textContent if ($type && $type =~ /^meta:(.*)$/);
    }

    ##-- parse: metadata: CMDI header
    my ($xhdr);
    if (defined($xhdr = $xmeta->findnodes('./*[local-name()="source"]/*[local-name()="CMD"]/*[local-name()="Header"]')->[0])) {
      foreach (grep {UNIVERSAL::isa($_,'XML::LibXML::Element')} @{$xhdr->childNodes}) {
	$type = $_->nodeName;
	$meta->{"$type"} = $_->textContent;
      }
    }

    ##-- parse: metadata: embedded TEI header (DTA-style)
    my ($nod);
    if (defined($xhdr = $xmeta->findnodes('.//*[local-name()="teiHeader"]')->[0])) {
      ##-- tei header: date: teiHeader/fileDesc/sourceDesc/biblFull/publicationStmt/date
      if (defined($nod=$xmeta->findnodes('.//*[local-name()="sourceDesc"]//*[local-name()="date"]')->[0])) {
	$meta->{date} = $nod->textContent;
      }

      ##-- tei header: author
      if (defined($nod=$xmeta->findnodes('.//*[local-name()="author"]')->[0])) {
	$meta->{author} = $nod->textContent;
      }

      ##-- tei header: title
      if (defined($nod=$xmeta->findnodes('.//*[local-name()="title" and level="a" and @type="main"]')->[0])
	  || defined($nod=$xmeta->findnodes('.//*[local-name()="title" and @type="main"]')->[0])
	  || defined($nod=$xmeta->findnodes('.//*[local-name()="title"]')->[0])) {
	$meta->{title} = $nod->textContent;
      }

      ##-- tei header: bibl
      if (defined($nod=$xmeta->findnodes('.//*[local-name()="sourceDesc"]/*[local-name()="bibl"]')->[0])) {
	$meta->{bibl} = $nod->textContent;
      }
    }
  }

  ##-- metadata: trim
  foreach (values %$meta) {
    s/^\s+//;
    s/\s+$//;
    s/\s+/ /g;
  }


  ##-- parse: date
  ($doc->{date} = $meta->{date} // $meta->{date_} // 0) =~ s/^[^0-9]*([0-9]+)[^0-9].*$//;

  ##-- parse: corpus
  my $xcorpus = [$xroot->getChildrenByLocalName('TextCorpus')]->[0]
    or $doc->logconfess("fromFile(): no <TextCorpus> node found in XML document for file '$file'");

  ##-- parse: tokens -> w
  my ($w,@w,%id2w);
  my $xtokens = [$xcorpus->getChildrenByLocalName('tokens')]->[0]
    or $doc->logconfess("fromFile(): no <tokens> node found in XML document for file '$file'");
  foreach ($xtokens->getChildrenByLocalName('token')) {
    push(@w, $w={w=>$_->textContent, id=>$_->getAttribute('ID')});
    $id2w{$w->{id}} = $w if (defined($w->{id}));
  }

  ##-- parse: sentences
  @$tokens = ("#file"); ##-- always include '#file' break
  if (defined(my $xsents = [$xcorpus->getChildrenByLocalName('sentences')]->[0])) {
    foreach ($xsents->getChildrenByLocalName('sentence')) {
      push(@$tokens, "#s", @id2w{split(' ',$_->getAttribute('tokenIDs'))}, undef);
    }
  } else {
    @$tokens = @w;
    push(@$tokens,undef);
  }

  ##-- parse: POStags -> p
  my ($id);
  if (defined(my $xpostags = [$xcorpus->getChildrenByLocalName('POStags')]->[0])) {
    foreach ($xpostags->getChildrenByLocalName('tag')) {
      ($id = $_->getAttribute('tokenIDs')) =~ s/\s.*$//;
      $id2w{$id}{p} = $_->textContent;
    }
  }

  ##-- parse: lemmas -> l
  if (defined(my $xlemmas = [$xcorpus->getChildrenByLocalName('lemmas')]->[0])) {
    foreach ($xlemmas->getChildrenByLocalName('lemma')) {
      ($id = $_->getAttribute('tokenIDs')) =~ s/\s.*$//;
      $id2w{$id}{l} = $_->textContent;
    }
  }

  return $doc;
}

##==============================================================================
## Footer
1;

__END__




