#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_long.t
#
#  DESCRIPTION:  Test combinations of 'long' ('--') run-time options
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#===============================================================================

use strict;
use warnings;

use Test::More tests => 17;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)

BEGIN {

   # This simulates our being called with various options on the command line.
   # It's here because Getopt::Auto needs to look at it
    @ARGV
        = qw(--foo --bar bararg1 bararg2 notanarg --tar-arr=tararg2 --nosubs --foo-bar -- --foobar);
    use Getopt::Auto{ 'nohelp' => 1 };
}

# Notice that the subroutine-global variables, such as $is_foo_called are
# not initialized. That's because by the time we get here in the normal course
# of execution, the subroutines have already been executed by the processing
# of @ARGV by Getopt::Auto.

our %options;

# Option has no args
my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

my $is_foo_bar_called;
sub foo_bar { $is_foo_bar_called = 1; return; }
ok( $is_foo_bar_called, 'Calling foo_bar()' );

# Option has two args
my $is_bar_called;

sub bar {
    $is_bar_called = ( shift @ARGV ) . ' and ' . shift @ARGV;
    return;
}
ok( defined $is_bar_called, "Calling bar() with $is_bar_called" );

# Option has one arg, tied with '='
my $is_tar_arr_called;
sub tar_arr { $is_tar_arr_called = shift @ARGV; return; }
ok( defined $is_tar_arr_called, "Calling tar_arr() with $is_tar_arr_called" );

# Option occurs after '--', so is not called
# Subroutine is required as otherwise its always ignored
my $is_foobar_called;
sub foobar { $is_foobar_called = 1; return; }
ok( !defined $is_foobar_called, 'Foobar was not called' );

# --nosubs has no associated sub, so ..
ok( defined $options{'--nosubs'}, 'Option "--nosubs" processed correcly' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq '--foobar',
    'Unused command line argument "--foobar" remains' );

# Verify not a registered option
@ARGV = qw{ --abc };
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: --abc is not a registered option\n",
    '--abc correctly not a registered option'
);

my $Eq1_is_called;
sub Eq1 { $Eq1_is_called = shift @ARGV; return; }

@ARGV = qw{ --Eq1=5 --Eq2=99 --Eq3=111 };
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: --Eq2 is not a registered option\n"
        . "Getopt::Auto: To use --Eq3 with \"=\", a subroutine must be provided\n",
    '--Eq2 correctly not registered option, --Eq3 has no sub'
);
ok( $Eq1_is_called == 5, 'Eq1() correct' );
ok( $ARGV[0] eq '--Eq2=99',  '--Eq2 restored to ARGV' );
ok( $ARGV[1] eq '--Eq3=111', '--Eq3 restored to ARGV' );

# Test elimination of POD formatting from option definitions
@ARGV = qw{ --bold --italic --i --b };
Getopt::Auto::_parse_args();
ok( defined $options{'--italic'}, 'Option "--italic" processed correcly' );
ok( defined $options{'--bold'},   'Option "--bold" processed correcly' );
ok( defined $options{'--i'},      'Option "--i" processed correcly' );
ok( defined $options{'--b'},      'Option "--b" processed correcly' );

exit 0;

__END__

=pod

=begin stopwords
Nosub
nosubs 
=end stopwords 

=head2 --foo - do a foo

This is the help for --foo

=head3 --bar - do a bar

This is the help for --bar
Note: "=head3"

=head4 --tar-arr - do a tar-arr

This is the help for --tar-arr.
Which also proves the - => _ feature
Note: "=head4"

=head2 --foobar - do a foobar

This is the help for --foobar, which won't be executed
because of the '--' in the command line

=over 4

=item --nosubs -- bump a counter

Note: "=item"

=back

Nosub has -- surprise -- no associated sub

=head2 --foo-bar - This tests embedded dashes

=item --Eq1 - assignment op

=item --Eq3 - assignment op, no sub

=item I<--italic> - 

=item B<--bold> - 

=item I<--i>, B<--b> - 

=cut
