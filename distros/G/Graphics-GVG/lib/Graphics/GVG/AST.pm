# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Graphics::GVG::AST;
$Graphics::GVG::AST::VERSION = '0.92';
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Graphics::GVG::AST::Node;


has 'commands' => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Graphics::GVG::AST::Node]',
    default => sub { [] },
    handles => {
        push_command => 'push',
    },
);

has 'meta_data' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub {{}},
    writer => '_set_meta_data',
);


sub to_string
{
    my ($self) = @_;
    my @commands = @{ $self->commands };
    return join( "", map { $_->to_string } @commands );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Graphics::GVG::AST -- Abstract Syntax Tree for GVG scripts

=head1 DESCRIPTION

GVG scripts are compiled into an Abstract Syntax Tree (AST). Renderers will 
walk the AST and generate the code they need to render the vectors.

Everything is a Moose object.

=head1 Graphics::GVG::AST

This is the root object returned by C<<Graphics::GVG->parse()>>. It has one 
attribute, C<commands>, which returns an arrayref of C<Graphics::GVG::AST::Node>
objects. Each of these nodes correspond to a command or an effect.

Note that variables are filled in statically. They don't appear in the 
generated AST.

=head1 METHODS

=head2 to_string

Returns the string corresponding to the GVG script representation of the 
AST. Note that the output may not be exactly what you input, as certain 
compile time transforms will loose information. The two should be semantically 
identical, however.

=head2 meta_data

Returns the hashref of metadata associated with this AST. This is only set 
on the root element of the AST.

=head1 COMMANDS

These all do the role C<Graphics::GVG::AST::Command>, which in turn does the 
C<Graphics::GVG::AST::Node> role.

All Nodes require a C<to_string()> method, which will output the GVG script 
representation of the object.

The attributes on each object correspond to their function description in the 
language. See L<Graphics::GVG> for details.

=head2 Circle

Attributes:

=over 4

=item * cx -- Num

=item * cy -- Num

=item * r -- Num

=item * color -- Int

=back


=head2 Ellipse

Attributes:

=over 4

=item * cx -- Num

=item * cy -- Num

=item * rx -- Num

=item * ry -- Num

=item * color -- Int

=back


=head2 Line

Attributes:

=over 4

=item * x1 -- Num

=item * y1 -- Num

=item * x2 -- Num

=item * y2 -- Num

=item * color -- Int

=back


=head2 Polygon

Attributes:

=over 4

=item * cx -- Num

=item * cy -- Num

=item * r -- Num

=item * rotate -- Num

=item * sides -- Int

=item * color -- Int

=back

There is also a special attribute, C<coords>, which returns an arrayref of 
arrayrefs of coordinates (numbers). These are the list of x/y coords of the 
calculated polygon.


=head2 Rect

Attributes:

=over 4

=item * x -- Num

=item * y -- Num

=item * width -- Num

=item * height -- Num

=item * color -- Int

=back


=head1 EFFECTS

These all do the role C<Graphics::GVG::AST::Effect>, which in turn does the 
C<Graphics::GVG::AST::Node> role.

The C<Graphics::GVG::AST::Effect> role has the C<commands> attribute. 
This returns an arrayref of C<Graphics::GVG::AST::Node> objects, which are 
all the nodes under this effect. Note that effects can be nested:

    glow {
        glow {
            line( #ff33ff00, 0.0, 0.0, 1.0, 1.1 );
        }
    }

What this means is left to the renderer.

=head2 Glow

=cut
