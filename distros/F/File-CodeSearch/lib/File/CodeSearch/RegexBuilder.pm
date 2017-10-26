package File::CodeSearch::RegexBuilder;

# Created on: 2009-08-07 18:41:21
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/any/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.7.5');

has regex => (
    is  => 'rw',
);
has re => (
    is  => 'ro',
    isa => 'ArrayRef',
);
has whole => (
    is  => 'ro',
    isa => 'Bool',
);
has all => (
    is  => 'ro',
    isa => 'Bool',
);
has words => (
    is  => 'ro',
    isa => 'Bool',
);
has ignore_case => (
    is  => 'ro',
    isa => 'Bool',
);
has files => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub{{}},
);
has current_file => (
    is  => 'rw',
);
has current_count => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);
has sub_matches => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{[]},
);
has sub_match => (
    is  => 'rw',
    isa => 'Bool',
);
has sub_not_matches => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{[]},
);
has sub_not_match => (
    is  => 'rw',
    isa => 'Bool',
);
has last => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);
has lasts => (
    is  => 'rw',
    isa => 'HashRef[Str]',
    default => sub{{}},
);
has smart => (
    is  => 'rw',
    isa => 'Bool',
);

sub make_regex {
    my ($self) = @_;
    return $self->regex if ref $self->regex eq 'Regexp';

    my $re;
    my $words = $self->re;

    my $start = shift @{ $words };
    return $self->regex(qr//) if !defined $start;

    if (!any {$start eq $_} qw/n b ss/) {
        unshift @{ $words }, $start;
        undef $start;
    }

    if ($self->whole) {
        @{$words} = map { "\\b$_\\b" } @{$words};
    }

    if ($self->all) {
        if (@{ $words } == 2 ) {
            $re = "$words->[0].*$words->[1]|$words->[1].*$words->[0]";
        }
        else {
            $re = join ' ', @$words;
        }
    }
    elsif ( $self->words ) {
        $re = join '.*', @{ $words };
    }
    else {
        $re = join ' ', @{ $words };
    }

    if ($self->ignore_case) {
        $re = "(?i:$re)";
    }

    $re =
          !defined $start ? $re
        : $start eq 'n'   ? "function(?:&?\\s+|\\s+&?\\s*)$re|$re\\s+=\\s+function"
        : $start eq 'b'   ? "sub\\s+$re"
        :                   "class\\s+$re";

    return $self->regex(qr/$re/);
}

sub match {
    my ($self, $line) = @_;
    my $re = $self->make_regex;

    $self->check_sub_matches($line);
    $self->check_lasts($line);

    my ($match) = $line =~ /($re)/;

    if (defined $match) {
        $self->current_count( $self->current_count + 1 );
    }

    return $match;
}

sub check_sub_matches {
    my ($self, $line) = @_;
    my $matches = $self->sub_matches;
    my $match = 0;
    my $not_matches = $self->sub_not_matches;
    my $not_match = 0;

    return if $self->sub_match;
    return if $self->sub_not_match;

    for my $match_re (@$matches) {
        $match = $line =~ /$match_re/;
        last if $match;
    }

    $self->sub_match($match);

    for my $not_match_re (@$not_matches) {
        $not_match = $line =~ /$not_match_re/;
        last if $not_match;
    }

    $self->sub_not_match($not_match);

    return;
}

sub check_lasts {
    my ($self, $line) = @_;

    if ($self->last) {
        for my $last (@{ $self->last }) {
            my ($match) =
                  $last eq 'function' ? $line =~ /function \s+ (?: & \s*)? ([\w-]+)/xms
                : $last eq 'class'    ? $line =~ /class \s+ ([\w-]+)/xms
                : $last eq 'sub'      ? $line =~ /sub \s+ ([\w-]+)/xms
                :                       $line =~ /$last \s+ ([\w-]+)/xms;
            $self->lasts->{$last} = $match if $match;
        }
    }

    return;
}

sub get_last_found {
    my ($self) = @_;
    my $out    = '';

    return '' if ! %{$self->lasts};

    for my $last (sort keys %{$self->lasts} ) {
        $out .= "$last " . $self->lasts->{$last} . "\n";
    }

    return $out;
}

sub reset_file {
    my ($self, $file) = @_;
    if ( $self->current_count() && $self->current_file ) {
        $self->files->{$self->current_file} = $self->current_count;
    }

    $self->sub_match(0);
    $self->sub_not_match(0);
    $self->current_count(0);
    $self->current_file($file);
    $self->lasts({});

    return;
}


1;

__END__

=head1 NAME

File::CodeSearch::RegexBuilder - Takes in various options and builds a regular expression to check lines of a file

=head1 VERSION

This documentation refers to File::CodeSearch::RegexBuilder version 0.7.5.

=head1 SYNOPSIS

   use File::CodeSearch::RegexBuilder;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item C<regex>

The compiled regex

=item C<re (ArrayRef)>

The strings to compile the regular expression from

=item C<whole (Bool)>

Makes sure each element of C<re> is matched as a whole word

=item C<all (Bool)>

Makes sure that the elements of C<re> are matched in any order (currently only two elements supported)

=item C<words (Bool)>

Match each word separated by arbitrary number of characters (default separation is one space)

=item C<ignore_case (Bool)>

Ignore case in the final regex

=item C<files (HashRef)>

Stores a count of matches in each file

=item C<current_file>

Reference to the current file being searched

=item C<current_count (Int)>

The number of matches found in the currently searched file

=item C<sub_matches (ArrayRef[Str])>

Terms to search on that the file should also contain to be considered to have matched

=item C<sub_match (Bool)>

Stores if a sub match has been found

=item C<sub_not_matches (ArrayRef[Str])>

Terms to search on that the file should not contain to be considered to have matched

=item C<sub_not_match (Bool)>

Stores if a not sub match has been found

=item C<last (ArrayRef[Str])>

A list of types to keep track of for context of a match (eg the last function, class or sub)

=item C<lasts (HashRef[Str])>

The current state of requested "last" types

=item C<smart (Bool)>

Create smart regular expression

=back

=head1 SUBROUTINES/METHODS

=head2 C<make_regex ()>

=head2 C<match ($line)>

=head2 C<sub_matches ($line)>

=head2 C<reset_file ( $file )>

Resets file based counters and adds $file as the new file being processed

=head2 C<check_sub_matches ( $line )>

Checks that $line matches any specified sub matches

=head2 C<check_lasts ( $line )>

Checks if the line matches a block start signature eg checks if we are starting
a sub, function or class so that any matches in that block can be identified as
coming from there.

=head2 C<get_last_found ()>

Returns the last match block

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
