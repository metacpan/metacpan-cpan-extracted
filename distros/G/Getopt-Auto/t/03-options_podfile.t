#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_podfile.t
#
#  DESCRIPTION:  Test run-time options determined by the POD
#                This is the behavior of version 1.0 of Getopt::Auto
#                This tests the 'podfile' option. POD is in 03.options_podfile.pod,
#                otherwise, the test is the same as 03.options_pod.t
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Mon Aug 10 15:14:54 PDT 2009
#===============================================================================

use strict;
use warnings;

use Test::More tests => 7;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)

BEGIN {

   # This simulates our being called with various options on the command line.
   # It's here because Getopt::Auto needs to look at it
    @ARGV
        = qw(-foo -bar bararg1 bararg2 notanarg -tar=tararg2 -nosub - -foobar);
    use Getopt::Auto;
}

our %options;

my %ex_options = ( '-nosub' => 1, );

# Option has no args
my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

# Option has two args
my $is_bar_called;

sub bar {
    $is_bar_called = ( shift @ARGV ) . ' and ' . shift @ARGV;
    return;
}
ok( defined $is_bar_called, "Calling bar() with $is_bar_called" );

# Option has one arg, tied with '='
my $is_tar_called;
sub tar { $is_tar_called = shift @ARGV; return; }
ok( defined $is_tar_called, "Calling tar() with $is_tar_called" );

# Option occurs after '--', so is not called
# Subroutine is required as otherwise its always ignored
my $is_foobar_called;
sub foobar { $is_foobar_called = 1; return; }
ok( !defined $is_foobar_called, 'Foobar was not called' );

# This establishes that -nosub was noticed. It's registered, so no letter split-out
is_deeply( \%options, \%ex_options, 'Option hash constructed correctly' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq '-foobar', 'Unused command line argument "-foobar" remains' );

exit 0;

__END__

