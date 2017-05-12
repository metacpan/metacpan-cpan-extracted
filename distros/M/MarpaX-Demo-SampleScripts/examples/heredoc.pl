#!perl
# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Example of Perl-style here-document parsing by Jeffrey Kegler
# Based on code by Peter Stuifzand
# With bugfix by mauke

use 5.010;
use strict;
use warnings;
use Test::More tests => 2;

use Marpa::R2 3.000000;

my $p = Demo::Heredoc::Parser->new;

my $v = $p->parse(<<"INPUT");
say <<ENDA, <<ENDB, <<ENDC; say <<ENDD;
a
ENDA
b
ENDB
c
ENDC
d
ENDD

INPUT

my $expected =
  [ [ [ 'say', [ "a\n", "b\n", "c\n", ], ], ], [ [ 'say', [ "d\n", ], ], ] ];

is_deeply( $v, $expected );

$v = $p->parse(<<'INPUT');
<<A, <<B, <<A;
a1
A
b
B
a2
A
<<WHEN;
when
WHEN
INPUT

$expected = [ [ "a1\n", "b\n", "a2\n" ], ["when\n"], ];

is_deeply( $v, $expected );

exit;

package Demo::Heredoc::Parser;

sub new {
    my $class = shift;

    my $grammar = Marpa::R2::Scanless::G->new(
        {
            default_action => '::array',

            source => \<<'GRAMMAR',

:start        ::= statements

statements    ::= statement+

# Statement should handle their own semicolons

statement     ::= expressions semicolon  action => ::first

expressions   ::= expression+ separator => comma

expression    ::= <heredoc declaration>  action => ::first
                | 'say' expressions

# The heredoc rule is different from how the source code actually looks The
# pause adverb allows to send only the parts the are useful

<heredoc declaration>       ::= (<heredoc op>) <heredoc>       action => ::first

# Pause at <heredoc>
:lexeme         ~ <heredoc>    pause => before event => 'heredoc declaration'

<heredoc op>    ~ '<<'
semicolon      ~ ';'
comma           ~ ','

# The syntax here is actually for the heredoc's terminator.
# The actual value of the <heredoc> lexeme will
# the heredoc, which will be provided by the external heredoc scanner.
<heredoc>         ~ [\w]+

:discard        ~ ws
ws              ~ [ \t\n]+

GRAMMAR
        }
    );

    my $self = { grammar => $grammar, };

    return bless $self, $class;
} ## end sub new

sub parse {
    my ( $self, $input ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $self->{grammar} } );

    # Start the parse
    my $pos = $recce->read( \$input );
    die "error" if $pos < 0;

    my $last_heredoc_end;

    # In this grammar, reading can stop or pause for one of three
    # reasons:
    #
    # 1.) An event, which is always a heredoc declaration
    #
    # 2.) Reaching the end of physical input
    #
    # 3.) Reaching the end of a line which declares heredocs

    # The loop condition detects the end of physical input
  PARSE_SEGMENT: while ( $pos < length $input ) {

        # We do not need to loop through events, although in a more
        # complicated parser we would.  In this parser, there is only
        # one kind of event.
        my $events = $recce->events();

        # We handle the non-event case here.  Since we are not
        # at end of physical input, and there has been no event,
        # we are at the end of a line which declared heredocs.
        # We resume reading from the end of the last heredoc
        if ( not @{$events} ) {
            $pos              = $recce->resume($last_heredoc_end);
            $last_heredoc_end = undef;
            next PARSE_SEGMENT;
        }

        # If we are here, we paused before a heredoc terminator.

        # The start and length of pause lexeme
        # indicate the start and length of the heredoc terminator.
        my ( $start_of_heredoc_terminator, $length_of_heredoc_terminator ) =
          $recce->pause_span();
        my $end_of_heredoc_terminator =
          $start_of_heredoc_terminator + $length_of_heredoc_terminator;

        # Using the pause lexeme's start and length, find the terminator
        my $terminator =
          $recce->literal( $start_of_heredoc_terminator,
            $length_of_heredoc_terminator );

        # We are in a line declaring heredoc's.  We need to know its EOL.
        my $eol_at_start_of_heredocs = index( $input, "\n", $pos ) + 1;

        # The next heredoc starts after the previous one or,
        # if this is the first heredoc in a line declaring them,
        # after this heredoc declaring line's EOL.
        my $heredoc_start = $last_heredoc_end // $eol_at_start_of_heredocs;

        # We've found the start of the current heredoc.
        pos($input) = $heredoc_start;

        # The heredoc ends after a terminator on a line by itself.
        $input =~ m/^\Q$terminator\E\n/gms
          or die "Heredoc terminator $terminator not found before end of input";

        # Slurp the heredoc into a variable.
        my $heredoc_body = substr $input, $heredoc_start,
          $-[0] - $heredoc_start;

        # Pass the heredoc body to the parser as the value of <heredoc>
        $recce->lexeme_read( 'heredoc', $heredoc_start,
            length($heredoc_body), $heredoc_body ) // die $recce->show_progress;

        # If this line declares another heredoc, it will start after
        # the last one, so we save the location.
        $last_heredoc_end = pos $input;

        # Resume parsing the line declaring heredocs.
        # It runs from the end of this heredoc's terminator, to the next EOL.
        $pos =
          $recce->resume( $end_of_heredoc_terminator,
            $eol_at_start_of_heredocs - $end_of_heredoc_terminator );

    } ## end PARSE_SEGMENT: while ( $pos < length $input )

    my $v = $recce->value;
    return $$v;
} ## end sub parse

# vim: expandtab shiftwidth=4:
