#!/usr/bin/perl -T

# examples/list.pl
#  List files in the current directory using `ls'
#
# $Id: list.pl 8217 2009-07-25 22:35:54Z FREQUENCY@cpan.org $
#
# All rights to this example script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Env::Sanctify::Auto;
my $sanctify = Env::Sanctify::Auto->new;

## Try this script with and without $sanctify
## Uncomment to see taint exception:
# undef($sanctify);

print `ls`;
