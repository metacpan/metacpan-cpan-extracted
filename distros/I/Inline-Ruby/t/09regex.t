#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

use Inline Ruby => 'DATA', REGEX => qr/^pl_/;

my $x = eval { pl_entry_point() };
is ($x, 0, "pl_entry_point was imported.");

my $b = eval { other_func() };
ok ($@, "Exception was thrown.");

__END__
__Ruby__

def pl_entry_point
  return 0
end

def other_func
  return 0
end
