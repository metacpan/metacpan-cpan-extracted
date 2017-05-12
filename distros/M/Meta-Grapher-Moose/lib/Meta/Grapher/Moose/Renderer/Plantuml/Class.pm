package Meta::Grapher::Moose::Renderer::Plantuml::Class;

use strict;
use warnings;
use namespace::autoclean;

use Digest::MD5 qw( md5_hex );

use Moose;

our $VERSION = '1.03';

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has label => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->name },
);

# TODO: This should probably be an enum type
has class_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has class_attributes => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has class_methods => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has formatting => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    required => 1,
);

sub to_plantuml {
    my $self = shift;

    my $extra = $self->formatting->{ $self->class_type } // q{};

    my $attributes = join "\n", map {"$_"} sort @{ $self->class_attributes };
    my $methods    = join "\n", map {"$_()"} sort @{ $self->class_methods };

    return <<"END";
class "@{[ $self->label ]}" as @{[ md5_hex($self->id) ]} ${extra}{
$attributes
$methods
}

END
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Utility class for Meta::Grapher::Moose::Renderer::Plantuml

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Renderer::Plantuml::Class - Utility class for Meta::Grapher::Moose::Renderer::Plantuml

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Internal class part of the L<Meta::Grapher::Moose::Renderer::Plantuml>
renderer. Represents a package to be rendered.

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 id

The id of the package (which is the actual true classname of the package,
even if the class is an anonymous class)

Required.

=head2 label

The class name we put on the diagram (which might be the true class name or
the parameterized class name we create an anonymous class from)

=head2 type

The type of the package.

One of the values provided by L<Meta::Grapher::Moose::Constants>: C<_CLASS>,
C<_ROLE>, C<_ANON_ROLE> or C<_P_ROLE>

Required.

=head2 class_attributes

An arrayref of strings, the name of attributes for the class.

Required.

=head2 class_methods

An arrayref of strings, the name of methods for the class.

Required.

=head2 formatting

A copy of the C<formatting> attribute from the controlling
L<Meta::Grapher::Moose::Renderer::Plantuml> instance that created this
instance.

Required.

=head1 METHODS

This class provides the following methods:

=head2 to_plantuml

Return source code representing this class

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
