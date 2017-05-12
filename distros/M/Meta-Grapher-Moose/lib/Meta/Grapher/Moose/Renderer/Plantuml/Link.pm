package Meta::Grapher::Moose::Renderer::Plantuml::Link;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

use Digest::MD5 qw(md5_hex);

use Moose;

has from => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has to => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub to_plantuml {
    my $self = shift;

    return <<"END";
"@{[ md5_hex($self->to) ]}" --> "@{[ md5_hex($self->from) ]}"
END
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Utility class for Meta::Grapher::Moose::Renderer::Plantuml

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Renderer::Plantuml::Link - Utility class for Meta::Grapher::Moose::Renderer::Plantuml

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Internal class. Part of the L<Meta::Grapher::Moose::Renderer::Plantuml>
renderer. Represents a link between two packages to be rendered.

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 from

The id of the package we're linking from.

Required.

=head2 to

The id of the package we're linking to.

Required.

=head1 METHODS

This class provides the following methods:

=head2 to_plantuml

Return source code representing this link as plantuml source.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose>
(or L<bug-meta-grapher-moose@rt.cpan.org|mailto:bug-meta-grapher-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
