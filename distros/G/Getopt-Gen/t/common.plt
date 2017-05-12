# -*- Mode: Perl -*-
# File: t/common.plt
# Description: re-usable test subs for DWDS::MetaParser
use Test;
$| = 1;

sub safestr {
  return defined($_[0]) ? "'$_[0]'" : 'undef';
}


# isok($label,@_) -- prints helpful label
sub isok {
  my $label = shift;
  print "$label:\n";
  ok(@_);
}

# ulistok($label,\@got,\@expect)
# --> ok() for unsorted lists (no ',' allowed in elements!)
sub ulistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',sort(@$l1)),join(',',sort(@$l2)));
}

# slistok($label,\@got,\@expect)
# --> ok() for sorted lists (no ',' allowed in elements!)
sub slistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',@$l1),join(',',@$l2));
}


# hashok($label,\%got,\%expect)
# --> ok() for hashrefs (no ',' or '=>' allowed in elements!)
sub hashok {
  my ($label,$h1,$h2) = @_;
  isok($label,
       join(',',
	    (map { "$_=>$h1->{$_}" } keys(%$h1)),
	    (map { "$_=>$h2->{$_}" } keys(%$h2))));
}


print "common.plt loaded.\n";

1;

