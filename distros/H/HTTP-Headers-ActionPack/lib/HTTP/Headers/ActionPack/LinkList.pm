package HTTP::Headers::ActionPack::LinkList;
# ABSTRACT: A List of Link objects

use strict;
use warnings;

our $VERSION = '0.10';

use HTTP::Headers::ActionPack::LinkHeader;

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderList';

sub BUILDARGS { shift; +{ items => [ @_ ] } }

sub items { (shift)->{'items'} }

sub add {
    my ($self, $link) = @_;
    push @{ $self->items } => $link;
}

sub add_header_value {
    my ($self, $value) = @_;
    $self->add( HTTP::Headers::ActionPack::LinkHeader->new( @$value ) );
}

sub iterable { @{ (shift)->items } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::LinkList - A List of Link objects

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::LinkList;

=head1 DESCRIPTION

This is a simple list of Links since the Link header
can legally have more then one link in it.

=for Pod::Coverage items

=head1 METHODS

=over 4

=item C<add ( $link )>

=item C<add_header_value ( $header_value )>

=item C<iterable>

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
