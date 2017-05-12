#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  04-bugs_0.t
#
#  DESCRIPTION:  Regression testing for reported bugs
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  08/18/2009 10:16:12 PM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;    # last test to print

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (RequirePodAtEnd)

BEGIN {
    @ARGV = qw(--foo);
    use Getopt::Auto;
}

# Courtesy of Ian Tegebo: option seen before sub is parsed
# Note: original submission was bad POD (no blank lines)

=head2 --foo - do a foo

Test

=cut

my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

exit 0;

