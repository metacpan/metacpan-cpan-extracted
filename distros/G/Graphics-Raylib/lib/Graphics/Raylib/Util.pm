use strict;
use warnings;
package Graphics::Raylib::Util;

# ABSTRACT: Utility functions for use With Graphics::Raylib::XS
our $VERSION = '0.015'; # VERSION

use List::Util qw(reduce);
use Graphics::Raylib::XS qw(:all);
use Scalar::Util 'blessed';
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (objects => [qw(vector rectangle camera)]);
Exporter::export_ok_tags(qw(objects));
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Util - Utility functions for use With Graphics::Raylib::XS


=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Graphics::Raylib::Util;

    # returns Graphics::Raylib::XS::{Vector2,Vector3} depending on scalar @coords
    my $vector = Graphics::Raylib::Util::vector(@coords);

=head1 DESCRIPTION

Raylib deals a lot in value-passed structs. This module builds these structs.

=head1 METHODS AND ARGUMENTS

=over 4

=item vector(@coords)

Constructs a C<Graphics::Raylib::XS::Vector2> or C<Graphics::Raylib::XS::Vector3> depending on number of arguments. Croaks otherwise.

    typedef struct Vector2 {
        float x;
        float y;
    } Vector2;

    typedef struct Vector3 {
        float x;
        float y;
        float z;
    } Vector3;

=cut

sub vector {
    my @coords = @_;
    if (@coords == 1) {
        my $obj = $coords[0];
        if (ref($obj) eq 'ARRAY') {
            @coords = @$obj;
        } elsif (blessed($obj)) {
            return $obj if $obj->isa("Graphics::Raylib::XS::Vector2");
            return $obj if $obj->isa("Graphics::Raylib::XS::Vector3");
        }
    }

    my $vector = @coords == 2 ? __vector2(pack("f2", @coords))
               : @coords == 3 ? __vector3(pack("f3", @coords))
               : croak "Only Graphics::Raylib::XS::{Vector2,Vector3} types may be constructed";

    return $vector;
}
sub __vector2 { my $binstr = shift; bless \$binstr, 'Graphics::Raylib::XS::Vector2' }
sub __vector3 { my $binstr = shift; bless \$binstr, 'Graphics::Raylib::XS::Vector3' }

sub vabs { sqrt reduce { $a + $b } map({ $_ ** 2 } $_[0]->components) }

{
    package Graphics::Raylib::XS::Vector2;
    sub x { return unpack(     "f", ${$_[0]}) }
    sub y { return unpack("x[f] f", ${$_[0]}) }
    sub components { return unpack("f2", ${$_[0]}) }
    sub stringify {
        my ($self) = @_;
        return sprintf '(%d, %d)', $self->components;
    }
    sub add {
        my ($self, $other, $swap) = @_;
        return Graphics::Raylib::Util::vector($self->x + $other->x, $self->y + $other->y);
    }
    sub equal {
        my ($self, $other) = @_;
        $$self eq $$other
    }
    use overload fallback => 1, '""' => 'stringify', '+' => 'add', '==' => 'equal', 'abs' => 'Graphics::Raylib::Util::vabs';
    use constant Zero => Graphics::Raylib::Util::vector(0,0);

    package Graphics::Raylib::XS::Vector3;
    sub x { return unpack(     "f", ${$_[0]}) }
    sub y { return unpack("x[f] f", ${$_[0]}) }
    sub z { return unpack("x[ff]f", ${$_[0]}) }
    sub components { return unpack("f3", ${$_[0]}) }
    sub stringify {
        my ($self) = @_;
        return sprintf '(%d, %d, %d)', $self->components;
    }
    sub add {
        my ($self, $other, $swap) = @_;
        return Graphics::Raylib::Util::vector($self->x + $other->x, $self->y + $other->y, $self->z + $other->z);
    }
    sub equal {
        my ($self, $other) = @_;
        $$self eq $$other
    }
    use overload fallback => 1, '""' => 'stringify', '+' => 'add', '==' => 'equal', 'abs' => 'Graphics::Raylib::Util::vabs';
    use constant Zero => Graphics::Raylib::Util::vector(0,0,0);
}


=item rectangle(x => $x, y => $y, width => $width, height => $height) or rectangle(position => $posVector2, size => $sizeVector2)

Constructs a C<Graphics::Raylib::XS::Rectangle>.

=cut

sub rectangle {
    my %p = ( @_ );
    ($p{x}, $p{y}) = ($p{position}->x, $p{position}->y) if defined $p{position};
    ($p{width}, $p{height}) = ($p{size}->x, $p{size}->y) if defined $p{size};

    return bless \pack("i4", $p{x}, $p{y}, $p{width}, $p{height}), 'Graphics::Raylib::XS::Rectangle'
}

{
    package Graphics::Raylib::XS::Rectangle;
    sub x      { return unpack(      "i", ${$_[0]}) }
    sub y      { return unpack("x[i]  i", ${$_[0]}) }
    sub width  { return unpack("x[ii] i", ${$_[0]}) }
    sub height { return unpack("x[iii]i", ${$_[0]}) }
    sub components {
        my ($x,$y,$w,$h) = unpack("i4", ${$_[0]}); return { x=>$x,y=>$y,width=>$w,height=>$h }
    }
    sub stringify {
        my ($p) = $_[0]->components;
        return sprintf '(x: %d, y: %d, width: %d, height: %d)', $p->{x}, $p->{y}, $p->{width}, $p->{height};
    }
    sub collides {
        Graphics::Raylib::XS::CheckCollisionRecs(shift, shift)
    }
    use overload fallback => 1, '""' => 'stringify', 'x' => 'collides';
}

=item camera(position => $pos3d, target => $target3d, up => $up3d, fovy => $fovy)

Constructs a C<Graphics::Raylib::XS::Camera>.

    typedef struct Camera {
        Vector3 position;
        Vector3 target;
        Vector3 up;
        float fovy;
    } Camera;

=cut

sub camera {
    use constant ZERO => Graphics::Raylib::XS::Vector3::Zero;
    my %p = (position => ZERO, target => ZERO, up => ZERO, fovy => 0, @_);
    ($p{position}, $p{target}, $p{up})
        = map { Graphics::Raylib::Util::vector($_) } $p{position}, $p{target}, $p{up};

    my $camera = ${$p{position}}.${$p{target}}.${$p{up}}.pack('f', $p{fovy});
    return bless \$camera, 'Graphics::Raylib::XS::Camera';
}

{
    package Graphics::Raylib::XS::Camera;
    sub position { return Graphics::Raylib::Util::vector(unpack(      "f3", ${$_[0]})) }
    sub target   { return Graphics::Raylib::Util::vector(unpack("x[f3] f3", ${$_[0]})) }
    sub up       { return Graphics::Raylib::Util::vector(unpack("x[f6] f3", ${$_[0]})) }
    sub fovy     { return                                unpack("x[f9] f",  ${$_[0]})  }
    sub components {
        my $self = shift;
        return {position=>$self->position, target=>$self->target, up=>$self->up, fovy=>$self->fovy}
    }
    sub stringify {
        my ($c) = $_[0]->components;
        return sprintf '(position: %s, target: %s, up: %s, fovy: %s)',
                        $c->{position}, $c->{target}, $c->{up}, $c->{fovy};
    }
    use overload fallback => 1, '""' => 'stringify';
}

1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib>  L<Graphics::Raylib::Color>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
