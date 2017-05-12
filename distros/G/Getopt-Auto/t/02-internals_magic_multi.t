#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  02-internals_magic_multi.t
#
#  DESCRIPTION:  Test the construction of internal data structures
#                which result from the "magic" mode of Getopt::Auto
#                when running multiple files
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;
use Test::Output;
use Getopt::Auto( { findsub => 1, test => 1 } );
use lib 't';
use Internals_magic_multi;

use 5.006;
our $VERSION = '1.9.8';

## no critic (ProhibitImplicitNewlines)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateVars)
## no critic (RequireCheckedSyscalls))

# What's being tested here is the ability to spread option subroutines
# over multiple files. The sub for --internals_magic_multi_pm is in
# internals_magic_multi, which itself uses Getopt::Auto.

my $output = q{did internals_magic_multi_t
did Internals_magic_multi_pm
};

sub internals_magic_multi_t { print "did internals_magic_multi_t\n"; return; }

@ARGV = qw(--internals_magic_multi_t --internals_magic_multi_pm);
stdout_is( \&Getopt::Auto::_parse_args, $output,
    'Check internals_magic_multi' );

exit 0;

__END__
