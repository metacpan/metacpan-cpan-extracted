## -*- Mode: CPerl -*-
## File: DiaColloDB::Document.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source document

package DiaColloDB::Document;
use DiaColloDB::Logger;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Logger);

##==============================================================================
## Constructors etc.

## $doc = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    label  => $label,   ##-- document label (e.g. filename; optional)
##    date   =>$date,     ##-- year
##    tokens =>\@tokens,  ##-- tokens, including undef for eos
##    meta   =>\%meta,    ##-- document metadata (e.g. author, title, collection, ...)
##   )
## + each token in @tokens is one of the following:
##   - undef       : EOS (default, for collocation profiling)
##   - a HASH-ref  : normal token: {w=>$word,p=>$pos,l=>$lemma,...}
##   - a string    : block boundary / "break", e.g. "s": sentence-break, "p": paragraph-break, ...
sub new {
  my $that = shift;
  my $doc  = bless({
		    label =>undef,
		    date  =>0,
		    tokens=>[],
		    meta  =>{},
		    @_, ##-- user arguments
		   },
		   ref($that)||$that);
  return $doc;
}

##==============================================================================
## API: I/O

## $bool = $doc->fromFile($filename_or_fh)
##  + parse tokens from $filename_or_fh
sub fromFile {
  my ($doc,$file) = @_;
  $doc->logconfess("fromFile() not implemented for '$file': $!");
}

## $label = $doc->label()
sub label {
  return $_[0]{label} // "$_[0]";
}

## $ext = $doc->extension()
##  + default extension (including dot), for Corpus::Compiled
sub extension {
  return '';
}

##==============================================================================
## Storable hooks

## ($serialized, $ref1, ...) = $obj->STORABLE_freeze($cloning)
sub STORABLE_freeze {
  my ($obj,$cloning) = @_;
  my $ref = {};
  foreach (keys %$obj) {
    $ref->{$_} = (UNIVERSAL::isa($obj->{$_},'Regexp') ? "$obj->{$_}" : $obj->{$_});
  }
  return ('',$ref);
}

## $obj = STORABLE_thaw($obj, $cloning, $serialized, $ref1,...)
sub STORABLE_thaw {
  my ($obj,$cloning,$ser,$ref) = @_;
  @$obj{keys %$ref} = values %$ref;
  return $obj;
}


##==============================================================================
## Footer
1;

__END__




