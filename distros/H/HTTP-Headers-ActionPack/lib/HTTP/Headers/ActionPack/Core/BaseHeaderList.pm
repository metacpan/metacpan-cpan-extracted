package HTTP::Headers::ActionPack::Core::BaseHeaderList;
BEGIN {
  $HTTP::Headers::ActionPack::Core::BaseHeaderList::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::Core::BaseHeaderList::VERSION = '0.09';
}
# ABSTRACT: A Base Header List

use strict;
use warnings;

use Scalar::Util                    qw[ blessed ];
use HTTP::Headers::ActionPack::Util qw[ split_header_words ];

use parent 'HTTP::Headers::ActionPack::Core::Base';

sub new_from_string {
    my ($class, $header_string) = @_;
    my $list = $class->new;
    foreach my $header ( split_header_words( $header_string ) ) {
        $list->add_header_value( $header )
    }
    $list;
}

sub as_string {
    my $self = shift;
    join ', ' => map { blessed $_ ? $_->as_string : $_ } $self->iterable;
}

sub add              { die "Abstract method" }
sub add_header_value { die "Abstract method" }
sub iterable         { die "Abstract method" }

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::Core::BaseHeaderList - A Base Header List

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Core::BaseHeaderList;

=head1 DESCRIPTION

This is a base class for header lists. There are no real
user serviceable parts in here.

=head1 METHODS

=over 4

=item C<new_from_string ( $header_string )>

This accepts a HTTP header string which get parsed
and loaded accordingly.

=item C<as_string>

=back

=head1 ABSTRACT METHODS

=over 4

=item C<add>

=item C<add_header_value>

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
