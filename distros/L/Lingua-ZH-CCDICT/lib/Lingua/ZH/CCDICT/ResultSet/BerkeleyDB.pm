package Lingua::ZH::CCDICT::ResultSet::BerkeleyDB;

use strict;
use warnings;

use base 'Lingua::ZH::CCDICT::ResultSet';

use Storable qw( thaw );


sub new
{
    my $class = shift;
    my %p = @_;

    return bless { index => 0,
                   keys  => $p{keys},
                   db    => $p{db},
                 }, $class;
}

sub next
{
    my $self = shift;

    my $index = $self->{index};

    unless ( exists $self->{keys}[$index] )
    {
        $self->{index} = 0;

        return;
    }

    my $value = $self->_get_value( $self->{keys}[$index] );

    $self->{index}++;

    return Lingua::ZH::CCDICT::ResultItem->new( thaw($value) );
}

sub all
{
    my $self = shift;

    return
        ( map { Lingua::ZH::CCDICT::ResultItem->new( thaw( $self->_get_value($_) ) ) }
          @{ $self->{keys} }
        );
}

sub _get_value
{
    my $self = shift;
    my $key = shift;

    my $value;
    my $status = $self->{db}->db_get( $key, $value );

    die "Failed to retrieve key ($key): $status" if $status;

    return $value;
}


1;

__END__

=head1 NAME

Lingua::ZH::CCDICT::ResultSet::BerkeleyDB - Iterates over results in a BerkeleyDB database

=head1 SYNOPSIS

  my $results = $dict->match_unicode( chr 0x8830, chr 0x88A4 );

  while ( my $item = $results->next )
  {
      ..
  }

=head1 DESCRIPTION

This module implements the C<Lingua::ZH::CCDICT::ResultSet> API.

It implements this API by fetching results from a BerkeleyDB database
as needed.

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
