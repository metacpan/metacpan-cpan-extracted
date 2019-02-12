## -*- Mode: CPerl -*-
## File: Lingua::TT::Unigrams.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT Utils: unigrams


package Lingua::TT::Unigrams;
use Lingua::TT::Persistent;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Persistent);

##==============================================================================
## Constructors etc.

## $ng = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$ng:
##    wf => { $key=>$count, ... }
sub new {
  my $that = shift;
  my $ng = bless({
		    wf=>{},
		    @_
		   }, ref($that)||$that);
  return $ng;
}

## undef = $ng->clear()
sub clear {
  my $ng = shift;
  %{$ng->{wf}} = qw();
  return $ng;
}

##==============================================================================
## Methods: Access and Manipulation

## $ng1 = $ng1->add($ng2)
##  + adds $ng2 counts to $ng
sub add {
  my ($ng1,$ng2) = @_;
  my ($w,$f);
  while (($w,$f)=each(%{$ng2->{wf}})) {
    $ng1->{$w} += $f;
  }
  return $ng1;
}

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: Native

## $bool = $ng->saveNativeFh($fh,%opts)
## + saves to filehandle
## + implicitly sets $fh ':utf8' flag unless $opts{raw} is set
## + %opts: (none yet)
##    sort => $HOW,      ##-- 'freq', 'lex', or 'none'
##    raw => $bool,      ##-- save raw strings, without encoding?
##    noids => $bool,    ##-- suppress printing of ids?
sub saveNativeFh {
  my ($ng,$fh,%opts) = @_;
  my @w = qw();
  my $wf = $ng->{wf};
  my $sort = $opts{sort} || '';
  if ($sort =~ /^f/i) {
    @w = sort {$wf->{$b} <=> $wf->{$a}} keys %$wf;
  } elsif ($sort =~ /^l/i) {
    @w = sort {$a cmp $b} keys %$wf;
  } else {
    @w = keys %$wf;
    warn(ref($ng).": unknown sort mode '$sort'") if ($sort && $sort !~ /^n/i);
  }
  foreach (@w) {
    $fh->print($wf->{$_}, "\t", $_, "\n");
  }
  return $ng;
}

## $bool = $ng->loadNativeFh($fh)
## + loads from handle
## + implicitly sets $fh ':utf8' flag unless $opts{raw} is set
## + %opts: (none yet)
sub loadNativeFh {
  my ($ng,$fh,%opts) = @_;
  $ng = $ng->new() if (!ref($ng));
  my $wf = $ng->{wf};
  my ($line,$f,$w);
  while (defined($line=<$fh>)) {
    chomp($line);
    next if ($line =~ /^\s*$/ || $line =~ /^\%\%/);
    ($f,$w) = split(/\t/,$line,2);
    $wf->{$w} += $f;
  }
  return $ng;
}

##==============================================================================
## Footer
1;

__END__
