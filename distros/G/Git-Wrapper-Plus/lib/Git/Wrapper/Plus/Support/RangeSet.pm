use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::RangeSet;

our $VERSION = '0.004011';

# ABSTRACT: A set of ranges of supported things

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );







has 'items' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_items {
  return [];
}









sub add_range_object {
  my ( $self, $range_object ) = @_;
  push @{ $self->items }, $range_object;
  return $self;
}














sub add_range {
  my ( $self, @args ) = @_;
  my $config;
  if ( 1 == @args ) {
    $config = $args[0];
  }
  else {
    $config = {@args};
  }
  require Git::Wrapper::Plus::Support::Range;
  return $self->add_range_object( Git::Wrapper::Plus::Support::Range->new($config) );
}










sub supports_version {
  my ( $self, $version_object ) = @_;
  for my $item ( @{ $self->items } ) {
    my $cmp = $item->supports_version($version_object);
    return $cmp if defined $cmp;
  }
  return;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::RangeSet - A set of ranges of supported things

=head1 VERSION

version 0.004011

=head1 METHODS

=head2 C<add_range_object>

Appends C<$object> to the C<items> stash.

    $set->add_range_object( $object );

=head2 C<add_range>

    $set->add_range( %params );

This is essentially shorthand for

    require Git::Wrapper::Plus::Support::Range;
    $set->add_range_object( Git::Wrapper::Plus::Support::Range->new( %params ) );

See L<< C<::Support::Range>|Git::Wrapper::Plus::Support::Range >> for details.

=head2 C<supports_version>

    $set->supports_version( $gwp->versions );

Determines if the data based on C<items> indicate that a thing is supported on the C<git>
versions described by the C<Versions> object.

=head1 ATTRIBUTES

=head2 C<items>

The series of L<< C<::Range>|Git::Wrapper::Plus::Support::Range >> objects that comprise the set.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
