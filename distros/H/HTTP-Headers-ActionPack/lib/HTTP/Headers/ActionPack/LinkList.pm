package HTTP::Headers::ActionPack::LinkList;
BEGIN {
  $HTTP::Headers::ActionPack::LinkList::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::LinkList::VERSION = '0.09';
}
# ABSTRACT: A List of Link objects

use strict;
use warnings;

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

=head1 NAME

HTTP::Headers::ActionPack::LinkList - A List of Link objects

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::LinkList;

=head1 DESCRIPTION

This is a simple list of Links since the Link header
can legally have more then one link in it.

=head1 METHODS

=over 4

=item C<add ( $link )>

=item C<add_header_value ( $header_value )>

=item C<iterable>

=back

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
