package File::CodeSearch::Highlighter;

# Created on: 2009-08-07 18:42:16
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Term::ANSIColor qw/:constants/;
use Term::Size::Any;

our $VERSION = version->new('0.7.5');

extends 'File::CodeSearch::RegexBuilder';

has highlight_re => (
    is  => 'rw',
);
has before_match => (
    is      => 'rw',
    isa     => 'Str',
    default => BOLD . RED,
);
has after_match => (
    is      => 'rw',
    isa     => 'Str',
    default => RESET,
);
has before_nomatch => (
    is      => 'rw',
    isa     => 'Str',
    default => CYAN,
);
has after_nomatch => (
    is      => 'rw',
    isa     => 'Str',
    default => RESET,
);
has before_snip => (
    is      => 'rw',
    isa     => 'Str',
    default => RESET . RED . ON_BLACK,
);
has after_snip => (
    is      => 'rw',
    isa     => 'Str',
    default => RESET,
);
has limit => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        my ($cols, $rows) = Term::Size::Any::chars;
        return $cols || 212;
    }
);
has snip => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

sub make_highlight_re {
    my ($self) = @_;

    return $self->highlight_re if $self->highlight_re;

    my $re = $self->make_regex;

    # make sure that all brackets are for non capture groups
    $re =~ s/ (?<! \\ | \[ ) [(] (?! [?] ) /(?:/gxms;

    return $self->highlight_re($re);
}

sub highlight {
    my ($self, $string) = @_;
    my $re  = $self->make_highlight_re;
    my $out = '';

    my @parts = split /($re)/, $string;

    my $match_length = 0;
    for my $i ( 0 .. @parts - 1 ) {
        if ( $i % 2 ) {
            $match_length += length $parts[$i];
        }
    }

    # 5 is the magic number of characters used to show the line number
    my $limit = $self->limit - $match_length - 5;
    my $joins = @parts - ( @parts - 1 ) / 2;
    my $chars = ( $limit / $joins ) / 2 - 2;
    my $chars_front = int $chars;
    my $chars_back  = int $chars;
    my $total = $joins * ( $chars_front + $chars_back + 3 ) + 1;
    if (length $parts[-1] < $chars * 2) {
        $total -= $chars_front + $chars_back - length $parts[-1];
    }

    my $inc = $limit - $total > $joins * 2 ? 1 : 0;
    $chars += $inc;
    $chars_front = int $chars;
    $chars_back  = int $chars;
    $total = $joins * ( $chars_front + $chars_back + 3 ) + 1;
    if (length $parts[-1] < $chars * 2) {
        $total -= $chars_front + $chars_back - length $parts[-1];
    }
    #warn "match = $match_length\nchars = $chars\nlimit = $limit ($total)\nparts = " . (scalar @parts) . "\njoins = $joins\n";

    for my $i ( 0 .. @parts - 1 ) {
        if ( $i % 2 ) {
            $out .= $self->before_match . $parts[$i] . $self->after_match;
        }
        else {
            my $part = $parts[$i];
            if ($self->snip && length $string > $self->limit) {
                my $chars_front_tmp = $chars_front;
                my $chars_back_tmp = $chars_back;
                if ($total < $limit) {
                    $chars_front_tmp++;
                    $total++;
                }
                if ($total < $limit) {
                    $chars_back_tmp++;
                    $total++;
                }

                # Check if
                if ($chars_front_tmp + $chars_back_tmp < length $parts[$i]) {
                    my ($front) = $chars_front_tmp > 0 ? $parts[$i] =~ /\A(.{$chars_front_tmp})/xms : ('');
                    my ($back)  = $chars_back_tmp  > 0 ? $parts[$i] =~ /(.{$chars_back_tmp})\Z/xms  : ('');
                    $part = (defined $front ? $front : '')
                        . $self->before_snip  . '...'
                        . $self->after_snip
                        . $self->before_nomatch
                        . (defined $back ? $back : '');
                }
            }
            $out .= $self->before_nomatch . $part . $self->after_nomatch;
        }
    }

    $out .= RESET;
    $out .= "\\N" if $string !~ /\n/xms;
    $out .= "\n" if $out !~ /\n/xms;

    return $out;
}

1;

__END__

=head1 NAME

File::CodeSearch::Highlighter - Highlights matched parts of a line.

=head1 VERSION

This documentation refers to File::CodeSearch::Highlighter version 0.7.5.


=head1 SYNOPSIS

   use File::CodeSearch::Highlighter;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item C<highlight_re>

The regular expression used to find what to highlight

=item C<before_match (Str, BOLD RED)>

A string put before a match

=item C<after_match (Str RESET)>

A string put after a match

=item C<before_nomatch (Str, CYAN)>

A string for before text that doesn't match

=item C<after_nomatch (Str, RESET)>

A string for after text that doesn't match

=item C<before_snip (Str, RESET . RED . ON_BLACK)>

A string for before snipped out text.

=item C<after_snip (Str, RESET)>

A string for after snipped out text.

=item C<limit (Int, columns in terminal)>

The size of the limit for line length of text that is extremely long.

=item C<snip (Bool, 1)>

Cut out non-matching text so that one line of text matches on line of output

=back

=head1 SUBROUTINES/METHODS

=head3 C<highlight ( $search, )>

Param: C<$search> - type (detail) - description

Return: File::CodeSearch::Highlighter -

Description:

=head3 C<make_highlight_re ( $search, )>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
