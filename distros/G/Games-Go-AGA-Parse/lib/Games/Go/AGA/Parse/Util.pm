#===============================================================================
#
#         FILE:  Games::Go::AGA::Parse::Util.pm
#
#      PODNAME:  Games::Go::AGA::Parse::Util
#     ABSTRACT:  Utilities to help Parse lines from AGA format files
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  Thu Jan 27 09:22:26 PST 2011
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::Parse::Util;
use parent 'Exporter';

our @EXPORT_OK = qw(
    is_ID
    is_Rank
    is_Rating
    is_Rank_or_Rating
    normalize_ID
    Rank_to_Rating
);

use Scalar::Util qw( looks_like_number );
use Carp;

our $VERSION = '0.042'; # VERSION

sub is_ID {
    my ($token) = @_;

    return (
        defined $token and      # of course
        $token =~ /^\w+$/ and   # only alphanums and underscore
        $token =~ /^\D/         # not digit in first position
    );
}

sub is_Rank {
    my ($token) = @_;

    return (
        defined $token and
        (($token =~ m/^(\d+)[dD]$/ and
           $1 >= 1 and
           $1 < 20)
        or
         ($token =~ m/^(\d+)[kK]$/ and
           $1 >= 1 and
           $1 < 100)
        )
    );
}

sub is_Rating {
    my ($token) = @_;

    return (looks_like_number($token) and
            (($token < 20.0 and
              $token >= 1.0) or
             ($token <= -1.0 and
              $token >  -100.0)));
}

sub is_Rank_or_Rating {
    my ($token) = @_;

    return (
        is_Rating($token) or
        is_Rank($token)
        );
}

sub normalize_ID  {
    my ($id) = @_;

    $id = uc $id;
    $id = "USA$id" if ($id =~ m/^\d/);
    # remove preceding 0 from numeric parts: X0010 => X10
    $id =~ s/([\D])0+(\d)/$1$2/g;
    # shorten remaining sequences of 0: A000B => A0B
    $id =~ s/00+(\D)/0$1/g;
    return $id;
}

sub Rank_to_Rating {
    my ($rank) = @_;

    if (is_Rank($rank) and
        $rank =~ m/(\d+)([dkDK])/) {
        if (lc $2  eq 'k') {
            return -0.5 - $1;
        }
        return 0.5 + $1;
    }
    elsif (is_Rating($rank)) {
        return $rank;
    }
    croak("$rank is not a rank or a rating");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse::Util - Utilities to help Parse lines from AGA format files

=head1 VERSION

version 0.042

=head1 SYNOPSIS

    use Games::Go::Parse::Util qw( is_Rank ... );
    ...
    if (is_Rank($token)) {
        ...
    }

=head1 DESCRIPTION

Utility functions to help parse AGA format files.

Importable functions are:

    is_ID
    is_Rank
    is_Rating
    is_Rank_or_Rating
    normalize_ID
    Rank_to_Rating

=over

=item is_ID($id);

Returns true if $id is a valid AGA ID, otherwise returns false.

=item is_Rank($rank);

Returns true if $rank is a valid AGA rank like '3D' or '10k',
otherwise returns false.

=item is_Rating($rating);

Returns true if $rating is a valid AGA numeric rating, otherwise
returns false.

=item is_Rank_or_Rating($rating);

Returns is_Rank($rating) or is_Rating($rating)

=item $id = normalize_ID($id);

Normalizes IDs.  All lower-case letters are converted to upper case.
If the ID starts with a digit (e.g. directly from a TDList file), it
is pre-pended with 'USA'.  Preceding zeros (defined as any zero
immediately following a non-digit and followed by a digit) are removed
(u01x002 becomes U1X2).  All remaining sequences of zeros are
shortened to a single zero (u003x00 becomes U3X0).

=item $rank = Rank_to_Rating($rank);

Converts a B<$rank> (like 3D or 10k) to a numeric rating.  If B<$rank> is
already a Rating, just returns it unchanged.  Dan range adds 0.5, while kyu
ranges subtract 0.5 (so 3D = 3.5 and 10K = -10.5).  Can throw an exception if
B<$rank> is not recognized as a rank or a rating.

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
