## -*- Mode: CPerl -*-
## File: Lingua::TT::Token.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: tokens (and comments)


package Lingua::TT::Token;
use strict;

##==============================================================================
## Globals & Constants

##==============================================================================
## Constructors etc.

## $tok = CLASS_OR_OBJECT->new(@vals)
## + $tok: ARRAY-ref:
##    [$val1, $val2, ..., $valN]
sub new {
  my $that = shift;
  return bless([@_], ref($that)||$that);
}

## $tok = CLASS_OR_OBJECT->newFromString($str)
##  + should be equivalent to CLASS_OR_OBJECT->new()->fromString($str)
sub newFromString {
  return bless([split(/[\n\r]*[\t\n\r][\n\r]*/,$_[1])], ref($_[0])||$_[0]);
}

## $tok2 = $tok->copy($deep)
##  + creates a (shallow) copy of $tok
##  + $deep is ignored
sub copy {
  return bless([@{$_[0]}], ref($_[0]));
}

##==============================================================================
## Methods: Access

## $bool = $tok->isEmpty()
##  + true iff $tok has no non-empty fields
sub isEmpty {
  return !grep {$_ ne ''} @{$_[0]};
}

## $bool = $tok->isComment()
##  + true iff $tok is a comment pseudo-token
sub isComment {
  return defined($_[0][0]) && $_[0][0] =~ /^\s*\%\%/;
}

## $bool = $tok->isVanilla()
##  + true if $tok is a "vanilla" (non-empty and non-comment) token
sub isVanilla {
  return !($_[0]->isEmpty || $_[0]->isComment);
}

## $tok = $tok->rmEmptyFields()
##  + removes empty & undefined fields from @$tok
sub rmEmptyFields {
  @{$_[0]} = grep {defined($_) && $_ ne ''} @{$_[0]};
  return $_[0];
}


##==============================================================================
## Methods: I/O

## $str = $tok->toString()
##  + returns string representing $tok, but without terminating newline
sub toString {
  return join("\t", @{$_[0]});
}

## $tok = $tok->fromString($str)
##  + parses token fields from $str, which may (or may not) contain embedded newlines
sub fromString {
  #return $_[0]->newFromString($_[1]) if (!ref($_[0]));
  #my ($tok,$str) = @_;
  @{$_[0]} = split(/[\n\r]*[\t\n\r][\n\r]*/,$_[1]);
  return $_[0];
}

##==============================================================================
## Footer
1;

__END__
