#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_stacked.t
#
#  DESCRIPTION:  Test combination of run-time options in the "stacked"
#                format, i.e, -f, --foo
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  Sat Aug 15 14:37:57 PDT 2009
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
        = qw(--foo -bar bararg1 bararg2 notanarg --tar=tararg2 --nosubs -- --foobar);
    use Getopt::Auto;
}

our %options;

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

# --nosubs has no associated sub`, so ..
ok( $options{'--nosubs'} == 1, 'Option "--nosubs" processed correcly' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq '--foobar',
    'Unused command line argument "--foobar" remains' );

exit 0;

__END__

=pod

=begin stopwords
Nosub
nosubs 
=end stopwords 

=head2 -bar, --foo - do a foo

This is the help for --foo, or -bar as the occasion demands

=head2 --tar - do a tar

This is the help for --tar

=head2 --foobar - do a foobar

This is the help for --foobar, which won't be executed
because of the '--' in the command line

=head2 --nosubs -- bump a counter

Nosub has -- supprise -- no associated sub

=cut

