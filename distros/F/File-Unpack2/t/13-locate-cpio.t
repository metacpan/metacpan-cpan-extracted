#!perl
#
# The located cpio command is cached per instance, a cached lookup must return the same command as the first one
# (it used to return an array reference, breaking cpio for every helper after the first one that needed it).

use strict;
use warnings;
use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;

plan skip_all => 'cpio is not installed' unless -x '/usr/bin/cpio';

my $u     = File::Unpack2->new(logfile => '/dev/null', verbose => 0);
my @first = File::Unpack2::_locate_cpio_i($u);
is $first[0], '/usr/bin/cpio', 'cpio located';
is_deeply [File::Unpack2::_locate_cpio_i($u)], \@first, 'cached lookup returns the same command';

done_testing;
