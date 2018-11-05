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
package Graphics::GVG::AST::Polygon;
$Graphics::GVG::AST::Polygon::VERSION = '0.91';
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Graphics::GVG::AST::Command;
use Math::Trig qw{ deg2rad pi };

with 'Graphics::GVG::AST::Command';

has [qw{ cx cy r rotate }] => (
    is => 'ro',
    isa => 'Num',
    default => 0.0,
);
has sides => (
    is => 'ro',
    isa => 'Int',
    default => 3,
);
has color => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);
has coords => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Num]]',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $radius = $args->{r};
    my $sides = $args->{sides};
    my $rotate = $args->{rotate};
    my $cx = $args->{cx};
    my $cy = $args->{cy};

    $args->{coords} = [
        map {[
            $class->_calc_x_coord( $_, $sides, $radius, $rotate, $cx ),
            $class->_calc_y_coord( $_, $sides, $radius, $rotate, $cy ),
        ]} (1 .. $sides)
    ];
    return $args;
}


sub to_string
{
    my ($self) = @_;
    my $str = 'poly( #'
        . sprintf( '%08x', $self->color )
        . ', ' . join( ', ', $self->cx, $self->cy, $self->r, $self->sides,
            $self->rotate )
        . " );\n";
    return $str;
}


sub _calc_x_coord
{
    my ($class, $side, $total_sides, $radius, $rotate, $cx) = @_;
    return $cx
        + $radius * cos( 2 * pi * $side / $total_sides + deg2rad($rotate) );
}

sub _calc_y_coord
{
    my ($class, $side, $total_sides, $radius, $rotate, $cy) = @_;
    return $cy
        + $radius * sin( 2 * pi * $side / $total_sides + deg2rad($rotate) );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

