#!/usr/bin/env perl

use Test2::V0;
use lib 'lib';

use Dev::Util::Syntax;
use Dev::Util::Query qw(:all);
use IO::Interactive  qw(is_interactive);

plan tests => 4;

#======================================#
#                banner                #
#======================================#

my $expected = <<'EOW';
################################################################################
#                                                                              #
#                                 Hello World                                  #
#                                                                              #
################################################################################

EOW

banner("Hello World");

my $output;
open( my $outputFH, '>', \$output ) or croak;
banner( "Hello World", $outputFH );
close $outputFH;

is( $output, $expected, 'Banner Test' );

#======================================#
#             display_menu             #
#======================================#
SKIP: {
    skip "Non-interactive test enviornment", 1 if ( !is_interactive() );
    my $message = 'Pick a choice from the list:';
    my @items   = qw{ apple pear peach banana };
    my $choice  = display_menu( $message, \@items );
    is( $choice, 0, 'display_menu -> apple' );
}

#======================================#
#            yes_no_prompt             #
#======================================#
SKIP: {
    skip "Non-interactive test enviornment", 1 if ( !is_interactive() );
    my $choice = yes_no_prompt(
                                { text    => "Rename Files?",
                                  default => 1,
                                  prepend => '>' x 3,
                                  append  => ': '
                                }
                              );
    is( $choice, 'y', 'yes_no_prompt -> y' );
}

#======================================#
#                prompt                #
#======================================#
SKIP: {
    skip "Non-interactive test enviornment", 1 if ( !is_interactive() );
    my $choice = prompt(
                         { text    => "Move Files Daily or Monthly",
                           valid   => [ 'daily', 'monthly' ],
                           default => 'daily',
                           prepend => '> ' x 3,
                           append  => ': ',
                           noecho  => 0
                         }
                       );
    is( $choice, 'daily', 'prompt -> daily' );
}

done_testing;
