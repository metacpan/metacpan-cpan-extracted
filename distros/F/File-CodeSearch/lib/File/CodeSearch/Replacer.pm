package File::CodeSearch::Replacer;

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

our $VERSION = version->new('0.7.5');

extends 'File::CodeSearch::Highlighter';

has replace_re => (
    is  => 'rw',
);
has replace => (
    is  => 'rw',
);
has all => (
    is => 'rw',
    isa => 'Int',
);

sub make_replace_re {
    my ($self) = @_;

    return $self->replace_re if $self->replace_re;

    my $re = $self->make_regex;

    # make sure that all brackets are for non capture groups
    $re =~ s/ (?<! \\ | \[ ) [(] (?! [?] ) /(?:/gxms;

    return $self->replace_re($re);
}

sub highlight {
    my ($self, $string) = @_;
    my $re  = $self->make_highlight_re;
    my $replace_re = $self->make_replace_re;
    my $replace = $self->replace;
    my $before = '';
    my $after = '';
    my $changed = '';

    my @parts = split /($re)/, $string;

    for my $i ( 0 .. @parts - 1 ) {
        if ( $i % 2 ) {
            $before .= $self->before_match . $parts[$i] . $self->after_match;
            my $part = $parts[$i];
            $part =~ s/$replace_re/$replace/;
            $after   .= $self->before_match . $part . $self->after_match;
            $changed .= $part;
        }
        else {
            $before  .= $self->before_nomatch . $parts[$i] . $self->after_nomatch;
            $after   .= $self->before_nomatch . $parts[$i] . $self->after_nomatch;
            $changed .= $parts[$i];
        }
    }

    if ($string !~ /\n/xms) {
        $before .= "\\N\n";
        $after  .= "\\N\n";
    }

    return ( '', $before, $after, $changed );
}

1;

__END__

=head1 NAME

File::CodeSearch::Replacer - Sorts out file content that should be changed.

=head1 VERSION

This documentation refers to File::CodeSearch::Replacer version 0.7.5.

=head1 SYNOPSIS

   use File::CodeSearch::Replacer;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item C<replace_re>

The regular expression to replace text with

=item C<replace>

The text to be used for replacement

=item C<all (Int)>

Answer yes to all questions

=back

=head1 SUBROUTINES/METHODS

=head3 C<highlight ( $search, )>

Param: C<$search> - type (detail) - description

Return: File::CodeSearch::Replacer -

Description:

=head3 C<make_replace_re ( )>

Creates the regular expression for replacing the searched for text.

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
