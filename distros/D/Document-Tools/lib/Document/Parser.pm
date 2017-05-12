## Base Class for Creating Text Format Parsers
# 
# Document::Parser is a base class that you can use to easily generate a
# parser for text document markups (like Wiki or POD markups).
# 
# See this parser as an example:
# 
#     http://svn.kwiki.org/kwiki/trunk/src/core/Spork/lib/Spork/Parser.pm
# 
# And this module for usage of the parser:
# 
#     http://svn.kwiki.org/kwiki/trunk/src/core/Spork/lib/Spork/Formatter2.pm
#
# Copyright (c) 2007. Ingy döt Net. All rights reserved.
#
# Licensed under the same terms as Perl itself.
##
package Document::Parser;
use strict;
use warnings;

## Synopsis:
#
#     package MyParser;
#     use base 'Document::Parser';
# 
#     sub create_grammar { 
#         return {
#             # ... define a grammar hash here ...
#         };
#     }
##

##------------------------------------------------------------------------------
# Parser object constructor/initializer
##------------------------------------------------------------------------------
sub new {
    my $class = shift;
    return bless { @_ }, ref($class) || $class;
}

##------------------------------------------------------------------------------
# $parsed = $parser->parse($wikitext);
##------------------------------------------------------------------------------
sub parse {
    my $self = shift;
    $self->{input} ||= shift;
    $self->{grammar} ||= $self->set_grammar;
    $self->{receiver} ||= $self->set_receiver;
    $self->{receiver}->init;
    $self->parse_blocks('top');
    return $self->{receiver}->content;
}

##
# Call `set_receiver` to reset the receiver for a new parse.
sub set_receiver {
    my $self = shift;
    $self->{receiver} = shift || $self->create_receiver;
}

sub set_grammar {
    my $self = shift;
    $self->{grammar} = shift || $self->create_grammar;
}

#-------------------------------------------------------------------------------
# Parse input into a series of blocks. With each iteration the parser must
# match a block at position 0 of the text, and remove that block from the
# input reparse it further. This continues until there is no input left.
#-------------------------------------------------------------------------------
sub parse_blocks {
    my $self = shift;
    my $container_type = shift;
    my $types = $self->{grammar}{$container_type}{blocks};
    while (my $length = length $self->{input}) {
        for my $type (@$types) {
            my $matched = $self->find_match(matched_block => $type) or next;
            substr($self->{input}, 0, $matched->{end}, '');
            $self->handle_match($type, $matched);
            last;
        }
        die $self->reduction_error
            unless length($self->{input}) < $length;
    }
    return;
}

#-------------------------------------------------------------------------------
# This code parses a chunk into interleaved pieces of plain text and
# phrases. It repeatedly tries to match every possible phrase and
# then takes the match closest to the start. Everything before a
# match is written as text. Matched phrases are subparsed according
# to their rules. This continues until the input is all eaten.
#-------------------------------------------------------------------------------
sub parse_phrases {
    my $self = shift;
    my $container_type = shift;
    my $types = $self->{grammar}{$container_type}{phrases};
    while (length $self->{input}) {
        my $match;
        for my $type (@$types) {
            my $matched = $self->find_match(matched_phrase => $type) or next;
            if (not defined $match or $matched->{begin} < $match->{begin}) {
                $match = $matched;
                $match->{type} = $type;
                last if $match->{begin} == 0;
            }
        }
        if (! $match) {
            $self->{receiver}->text_node($self->{input});
            last;
        }
        my ($begin, $end, $type) = @{$match}{qw(begin end type)};
        $self->{receiver}->text_node(substr($self->{input}, 0, $begin))
          unless $begin == 0;
        substr($self->{input}, 0, $end, '');
        $type = $match->{type};
        $self->handle_match($type, $match);
    }
    return;
}

sub find_match {
    my ($self, $matched_func, $type) = @_;
    my $matched;
    if (my $regexp = $self->{grammar}{$type}{match}) {
        if (ref($regexp) eq 'ARRAY') {
            for my $re (@$regexp) {
                if ($self->{input} =~ $re) {
                    $matched = $self->$matched_func;
                    last;
                }
            }
            return unless $matched;
        }
        else {
            return unless $self->{input} =~ $regexp;
            $matched = $self->$matched_func;
        }
    }
    else {
        my $func = "match_$type";
        $matched = $self->$func or return;
    }
    return $matched;
}

sub handle_match {
    my ($self, $type, $match) = @_;
    my $func = "handle_$type";
    if ($self->can($func)) {
        $self->$func($match, $type);
    }
    else {
        my $grammar = $self->{grammar}{$type};
        my $parse = $grammar->{blocks}
        ? 'parse_blocks'
        : 'parse_phrases';
        my @filter = $grammar->{filter}
        ? ($grammar->{filter})
        : ();
        $self->subparse($parse, $match, $type, @filter);
    }
}

sub subparse {
    my ($self, $func, $match, $type, $filter) = @_;
    $self->{receiver}->begin_node($type);
    my $parser = $self->new(
        grammar => $self->{grammar},
        receiver => $self->{receiver}->new,
        input => $filter
        ? do { $_ = $match->{text}; &$filter(); $_ }
        : $match->{text},
    );
    $parser->$func($type);
    $self->{receiver}->insert($parser->{receiver});
    $self->{receiver}->end_node($type);
}

#-------------------------------------------------------------------------------
# Helper functions
#
# These are the odds and ends called by the code above.
#-------------------------------------------------------------------------------

sub reduction_error {
    my $self = shift;
    return ref($self) . qq[ reduction error for:\n"$self->{input}"];
}

sub matched_block {
    my $begin = defined $_[2] ? $_[2] : $-[0];
    die "All blocks must match at position 0"
      if "$begin" ne "0";

    return +{
        text => ($_[1] || $1),
        end => ($_[3] || $+[0]),
    };
}

sub matched_phrase {
    return +{
        text => ($_[1] || $1),
        begin => (defined $_[2] ? $_[2] : $-[0]),
        end => ($_[3] || $+[0]),
    };
}

1;

=for perldoc
This POD generated by Perldoc-0.21.
DO NOT EDIT. Your changes will be lost.

=encoding utf8

=head1 NAME

Document::Parser - Base Class for Creating Text Format Parsers

=head1 SYNOPSIS

    package MyParser;
    use base 'Document::Parser';

    sub create_grammar { 
        return {
            # ... define a grammar hash here ...
        };
    }

=head1 DESCRIPTION

Document::Parser is a base class that you can use to easily generate a
parser for text document markups (like Wiki or POD markups).

See this parser as an example:

    http://svn.kwiki.org/kwiki/trunk/src/core/Spork/lib/Spork/Parser.pm

And this module for usage of the parser:

    http://svn.kwiki.org/kwiki/trunk/src/core/Spork/lib/Spork/Formatter2.pm

=head1 AUTHOR

Ingy döt Net

=head1 COPYRIGHT

Copyright (c) 2007. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
