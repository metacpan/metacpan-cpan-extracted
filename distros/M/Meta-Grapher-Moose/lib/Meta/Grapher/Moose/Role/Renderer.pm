package Meta::Grapher::Moose::Role::Renderer;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

use Moose::Role;

with 'MooseX::Getopt::Dashes';

requires 'add_edge', 'add_package', 'render';

1;

# ABSTRACT: Base role for all Meta::Grapher::Moose renderers

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Role::Renderer - Base role for all Meta::Grapher::Moose renderers

=head1 VERSION

version 1.03

=head1 REQUIRED METHODS

There are several methods that must be implemented.

=head3 add_package( name => $name, attributes => \@attr, methods => \@meth )

A request that a package is added to the rendered output.  The C<attributes>
and C<methods> contain arrays of attribute and method names which the renderer
may use if it wants.

=head3 add_edge( from => $from_package_name, to => $to_package_name )

A request that the rendered output indicate one package consumes another.

=head3 render()

Actually do the rendering, presumably rendering to an output file or some such

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
