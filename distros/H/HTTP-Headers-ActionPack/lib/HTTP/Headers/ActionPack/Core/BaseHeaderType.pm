package HTTP::Headers::ActionPack::Core::BaseHeaderType;
BEGIN {
  $HTTP::Headers::ActionPack::Core::BaseHeaderType::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::Core::BaseHeaderType::VERSION = '0.09';
}
# ABSTRACT: A Base header type

use strict;
use warnings;

use Carp qw[ confess ];

use HTTP::Headers::ActionPack::Util qw[
    split_header_words
    join_header_words
];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderWithParams';

sub BUILDARGS {
    my $class = shift;
    my ($subject, @params) = @_;

    confess "You must specify a subject" unless $subject;

    return +{
        subject => $subject,
        %{ $class->_prepare_params( @params ) }
    };
}

sub subject { (shift)->{'subject'} }

sub new_from_string {
    my ($class, $header_string) = @_;
    $class->new( @{ (split_header_words( $header_string ))[0] } );
}

sub as_string {
    my $self = shift;
    join_header_words( $self->subject, $self->params_in_order );
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::Core::BaseHeaderType - A Base header type

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Core::BaseHeaderType;

=head1 DESCRIPTION

This is a base class for header values which also contain
a parameter list. There are no real user serviceable parts
in here.

=head1 METHODS

=over 4

=item C<new( $subject, @params )>

=item C<subject>

=item C<new_from_string ( $header_string )>

This will take an HTTP header string
and parse it into and object.

=item C<as_string>

This stringifies the link
respecting the parameter order.

NOTE: This will canonicalize the header such
that it will add a space between each semicolon
and quotes and unquotes all headers appropriately.

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
