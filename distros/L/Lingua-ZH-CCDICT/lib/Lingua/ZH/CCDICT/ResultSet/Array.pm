package Lingua::ZH::CCDICT::ResultSet::Array;

use strict;
use warnings;

use base 'Lingua::ZH::CCDICT::ResultSet';


sub new
{
    my $class = shift;
    my %p = @_;

    return bless { index => 0,
                   array => $p{array},
                 }, $class;
}

sub next
{
    my $self = shift;

    my $index = $self->{index};

    unless ( exists $self->{array}[$index] )
    {
        $self->{index} = 0;

        return;
    }

    $self->{index}++;

    return $self->{array}[$index];
}

sub all
{
    my $self = shift;

    return @{ $self->{array} };
}


1;

__END__

=head1 NAME

Lingua::ZH::CCDICT::ResultSet::Array - An iterator over an array

=head1 SYNOPSIS

  my $results = $dict->match_unicode( chr 0x8830, chr 0x88A4 );

  while ( my $item = $results->next )
  {
      ..
  }

=head1 DESCRIPTION

This module implements the C<Lingua::ZH::CCDICT::ResultSet> API.

It is implemented as a simple array in memory.

=head1 METHODS

See the C<Lingua::ZH::CCDICT::ResultSet> documentation for details.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
