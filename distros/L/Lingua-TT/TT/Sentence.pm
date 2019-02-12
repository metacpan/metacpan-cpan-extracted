## -*- Mode: CPerl -*-
## File: Lingua::TT::Sentence.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: sentences


package Lingua::TT::Sentence;
use Lingua::TT::Token;
use strict;

##==============================================================================
## Globals & Constants

##==============================================================================
## Constructors etc.

## $sent = CLASS_OR_OBJECT->new(@tokens)
## + $sent: ARRAY-ref
##   [$tok1, $tok2, ..., $tokN]
sub new {
  my $that = shift;
  return bless([@_], ref($that)||$that);
}

## $sent = CLASS_OR_OBJECT->newFromString($str)
sub newFromString {
  return $_[0]->new()->fromString($_[1]);
}

## $sent2 = $sent->copy($depth)
##  + creates a copy of $sent
##  + if $deep is 0, only a shallow copy is created (tokens are shared)
##  + if $deep is >=1 (or <0), sentences are copied as well (tokens are copied)
sub copy {
  my ($sent,$deep) = @_;
  my $sent2 = bless([],ref($sent));
  @$sent2 = $deep ? (map {bless([@$_],ref($_))} @$sent) : @$sent;
  return $sent2;
}

##==============================================================================
## Methods: Access

## $bool = $sent->isEmpty()
##  + true iff $sent has no non-empty tokens
sub isEmpty {
  return !grep {!$_->isEmpty} @{$_[0]};
}

## $sent = $sent->rmEmptyTokens()
##  + removes empty & undefined tokens from @$sent
sub rmEmptyTokens {
  @{$_[0]} = grep {defined($_) && !$_->isEmpty} @{$_[0]};
  return $_[0];
}

## $sent = $sent->rmComments()
##  + removes comment pseudo-tokens from @$sent
sub rmComments {
  @{$_[0]} = grep {!defined($_) || !$_->isComment} @{$_[0]};
  return $_[0];
}

## $sent = $sent->rmNonVanilla()
##  + removes non-vanilla tokens from @$sent
sub rmNonVanilla {
  @{$_[0]} = grep {defined($_) && $_->isVanilla} @{$_[0]};
  return $_[0];
}


##==============================================================================
## Methods: I/O

## $str = $sent->toString()
##  + returns string representing $sent, but without terminating newline
sub toString {
  return join("\n", map {$_->toString} @{$_[0]})."\n";
}

## $sent = $sent->fromString($str)
##  + parses $sent from string $str
sub fromString {
  #my ($sent,$str) = @_;
  @{$_[0]} = map {Lingua::TT::Token->newFromString($_)} split(/[\r\n]+/,$_[1]);
  return $_[0];
}

##==============================================================================
## Methods: Raw Text (heuristic)

## $str = $sent->rawString()
##  + get raw text for sentence
##  + returns TEXT from first comment-line '%% $stxt=TEXT' or '%% Sentence ID\t=TEXT' if available
##  + otherwise, heuristically generates raw-text string from sentence tokens using $sent->guessRawString()
sub rawString {
  foreach (@{$_[0]}) {
    return $1 if ($_->[0] =~ /^%%(?:\s*\$stxt=| Sentence\b[^\t]*\t=)(.*)/);
  }
  return $_[0]->guessRawString();
}

## $str = $sent->guessdRawString()
##  + guess raw text for sentence
sub guessRawString {
  my $sent = shift;  ##-- ( \@tok1, \@tok2, ..., \@tokN )
  my @spaces = qw(); ##-- ( $space_before_tok1, ..., $space_before_tokN )
  my @toks   = grep {$_->[0] !~ /^\%\%/} @$sent; ##-- remove comments
  my @words  = map {$_->[0]} @toks;

  foreach (@words) {
    $_ =~ s/_/ /g if ($_ =~ /^[0-9]{1,3}(?:_[0-9]{3})+(?:,[0-9]+)?$/); ##-- map underscore to space in separated numerals
  }

  ##-- insert boundary space
  @spaces = map {''} @words;
  my ($i,$w1,$w2);
  foreach $i (1..$#words) {
    ($w1,$w2) = @words[($i-1),$i];
    next if ($w2 =~ /^(?:[\]\)\%\.\,\:\;\!\?]|\'+|\'[[:alpha:]]+)$/);	##-- no token-boundary space BEFORE these text types
    next if ($w1 =~ /^(?:[\[\(]|\`+)$/);					##-- no token-boundary space AFTER  these text types
    $spaces[$i] = ' ';								##-- default: add token-boundary space
  }

  ##-- dump raw text
  return join('', map {($spaces[$_],$words[$_])} (0..$#words));
}

##==============================================================================
## Footer
1;

__END__
