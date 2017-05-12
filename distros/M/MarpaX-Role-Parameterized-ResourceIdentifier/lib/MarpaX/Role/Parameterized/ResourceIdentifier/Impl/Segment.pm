use strict;
use warnings FATAL => 'all';

package MarpaX::Role::Parameterized::ResourceIdentifier::Impl::Segment;

# ABSTRACT: Resource Identifier: segment implementation

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

#
# For backward compatility with URI's path_segment
#
use overload '""' => sub { $_[0]->[0] }, fallback => 1;

#
# In contrary to original URI's _segment.pm:
# we create internal the object by sending all segments properly escaped/unescaped
#
sub new {
    my $class = shift;
    bless \@_, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Role::Parameterized::ResourceIdentifier::Impl::Segment - Resource Identifier: segment implementation

=head1 VERSION

version 0.003

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
