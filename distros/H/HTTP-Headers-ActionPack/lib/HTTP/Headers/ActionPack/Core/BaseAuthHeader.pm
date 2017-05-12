package HTTP::Headers::ActionPack::Core::BaseAuthHeader;
BEGIN {
  $HTTP::Headers::ActionPack::Core::BaseAuthHeader::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::Core::BaseAuthHeader::VERSION = '0.09';
}
# ABSTRACT: The base Auth Header

use strict;
use warnings;

use Carp                            qw[ confess ];
use HTTP::Headers::ActionPack::Util qw[
    join_header_params
];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderWithParams';

sub BUILDARGS {
    my $class = shift;
    my ($type, @params) = @_;

    confess "You must specify an auth-type" unless $type;

    return +{
        auth_type => $type,
        %{ $class->_prepare_params( @params ) }
    };
}

sub new_from_string {
    my ($class, $header_string) = @_;

    my @parts = HTTP::Headers::Util::_split_header_words( $header_string );
    splice @{ $parts[0] }, 1, 1;

    $class->new( map { @$_ } @parts );
}

sub auth_type { (shift)->{'auth_type'} }

sub as_string {
    my $self = shift;
    $self->auth_type . ' ' . join_header_params( ', ' => $self->params_in_order );
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::Core::BaseAuthHeader - The base Auth Header

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Core::BaseAuthHeader;

=head1 DESCRIPTION

This is a base class for Auth-style headers; it inherits
from L<HTTP::Headers::ActionPack::Core::BaseHeaderWithParams>.

=head1 METHODS

=over 4

=item C<new ( %params )>

=item C<new_from_string ( $header_string )>

=item C<auth_type>

=item C<as_string>

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
