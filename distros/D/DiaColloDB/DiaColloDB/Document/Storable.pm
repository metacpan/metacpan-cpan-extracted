## -*- Mode: CPerl -*-
## File: DiaColloDB::Document::Storable.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source document, Storable (nstore_fd)

package DiaColloDB::Document::Storable;
use DiaColloDB::Document;
use Storable;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Document);

##==============================================================================
## Constructors etc.

## $doc = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- document data
##    date   =>$date,     ##-- year
##    tokens =>\@tokens,  ##-- tokens, including undef for EOS
##    meta   =>\%meta,    ##-- document metadata (e.g. author, title, collection, ...)
##   )
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
  return '.sto';
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
  my $ref = (ref($file)
             ? Storable::fd_retrieve($file)
             : Storable::retrieve($file));
  $doc->logconfess("fromFile(): failed to load Storable object from '$file'")
    if (!UNIVERSAL::isa($ref,'HASH'));
  @$doc{keys %$ref} = values %$ref;
  return $doc;
}

##==============================================================================
## Footer
1;

__END__




