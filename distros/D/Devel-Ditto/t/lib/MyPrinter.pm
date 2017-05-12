package MyPrinter;

use strict;
use warnings;

sub new { bless {}, shift }
sub blurt { shift; print @_ }
sub blub  { shift; warn @_ }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
