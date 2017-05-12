package Lingua::ZH::CCDICT::ResultItem;

use strict;
use warnings;

use Params::Validate qw( validate SCALAR UNDEF ARRAYREF );
use Sub::Name qw( subname );

foreach my $item ( qw( unicode radical index stroke_count cangjie four_corner ) )
{
    my $sub = sub { return unless exists $_[0]->{$item};
                    $_[0]->{$item} };

    my $sub_name = __PACKAGE__ . "::$item";

    no strict 'refs';
    *{$sub_name} = subname $sub_name => $sub;
}

foreach my $item ( qw( jyutping pinyin pinjim english ) )
{
    my $sub = sub { return unless exists $_[0]->{$item};
                    wantarray ? @{ $_[0]->{$item} } : $_[0]->{$item}[0] };

    my $sub_name = __PACKAGE__ . "::$item";

    no strict 'refs';
    *{$sub_name} = subname $sub_name => $sub;
}


sub new
{
    my $class = shift;
    my %p = validate( @_,
                      { unicode      => { type => SCALAR },
                        radical      => { type => SCALAR },
                        index        => { type => SCALAR },
                        stroke_count => { type => SCALAR, optional => 1 },
                        cangjie      => { type => SCALAR, optional => 1 },
                        four_corner  => { type => SCALAR, optional => 1 },
                        jyutping     => { type => ARRAYREF, optional => 1 },
                        pinyin       => { type => ARRAYREF, optional => 1 },
                        pinjim       => { type => ARRAYREF, optional => 1 },
                        english      => { type => ARRAYREF, optional => 1 },
                      },
                    );

    return bless \%p, $class;
}


1;

__END__

=head1 NAME

Lingua::ZH::CCDICT::ResultItem - A single result from a dictionary search

=head1 SYNOPSIS

  print $item->unicode();

  print $_->syllable(), "\n" for $item->pinyin();

=head1 DESCRIPTION

Each individual result returned by a C<Lingua::ZH::CCDICT::ResultSet>
returns an object of this class.

=head1 METHODS

This class provides the following methods:

=head2 $item->unicode()

=head2 $item->radical()

=head2 $item->index()

=head2 $item->stroke_count()

=head2 $item->cangjie()

=head2 $item->four_corner()

These methods always return a single item when the requested data is
available or a false value if this item is not available.

=head2 $item->pinjim()

=head2 $item->jyutping()

=head2 $item->pinyin()

=head2 $item->english()

These methods represent data for which there may be multiple values.
In a list context, all values are returned. In a scalar context, only
the first value is returned. When the requested data is not
available, a false value is returned.

Romanizations are returned as C<Lingua::ZH::CCDICT::Romanization>
objects.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
