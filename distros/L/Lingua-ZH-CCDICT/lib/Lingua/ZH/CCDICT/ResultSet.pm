package Lingua::ZH::CCDICT::ResultSet;

use strict;
use warnings;


sub count
{
    my $self = shift;

    return $self->{index};
}

sub reset
{
    my $self = shift;

    $self->{index} = 0;
}


1;

__END__

=pod

=head1 NAME

Lingua::ZH::CCDICT::ResultSet - Documentation for result set objects

=head1 SYNOPSIS

  my $results = $dict->match_unicode( chr 0x8830, chr 0x88A4 );

  while ( my $item = $results->next )
  {
      ..
  }

=head1 DESCRIPTION

All dictionary searches return an iterator object of results. This
class is the base class for all result set subclasses.

=head1 METHODS

All result set classes provide these methods:

=head2 $set->next()

Return the next item in the result set. If there are no items left
then a false value is returned. A subsequent call will start back at
the first result.

=head2 $set->all()

Returns all of the items in the result set.

=head2 $set->reset()

Resets the index so that the next call to I<next> returns the first
item in the set.

=head2 $set->count()

Returns a number indicating how many items have been returned so far.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
