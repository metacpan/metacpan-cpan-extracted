# -*- Mode: Perl -*-
# File: t/common.plt
# Description: re-usable test subs for Math::PartialOrder
use Test;
$| = 1;

# @classes -- test these subclasses
@classes = qw(Std Caching LRUCaching CMasked CEnum);


# isok($label,@_) -- prints helpful label
sub isok {
  my $label = shift;
  print "$label:\n";
  ok(@_);
}

# ulistok($label,\@got,\@expect)
# --> ok() for unsorted lists
sub ulistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',sort(@$l1)),join(',',sort(@$l2)));
}

# $hi = testhi($class)
# -> test hierarchy -- structure:
#           c
#          / \
#       aaa   \
#        |     \
#   aa1 aa2     bb
#     \/        |
#      a        b
#       \      /
#         root
sub testhi {
  my $class = shift;
  eval "use $class;";
  my $h = $class->new({root => 'root'});
  foreach ([qw(a root)], [qw(b root)],
	   [qw(aa1 a)], [qw(aa2 a)], [qw(bb b)],
	   [qw(aaa aa2)], [qw(c aaa bb)])
    {
      $h->add(@$_);
    }
  return $h;
}

print "common.plt loaded.\n";

1;

