use strict;
use warnings;
package Graphics::Raylib::Util;

# ABSTRACT: Utility functions for use with Graphics::Raylib::XS
our $VERSION = '0.020'; # VERSION

use List::Util qw(reduce);
use Graphics::Raylib::XS qw(:all);
use Scalar::Util 'blessed';
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (objects => [qw(vector rectangle camera3d image)]);
Exporter::export_ok_tags(qw(objects));
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
use Config;

our $PTR_PACK_FMT = $Config{ptrsize} == $Config{longsize}     ? 'L!'
                  : $Config{ptrsize} == $Config{intsize}      ? 'I!'
                  : $Config{ptrsize} == $Config{longlongsize} ? 'Q!'
                  : croak "Strange pointer size of $Config{ptrsize} not supported (yet!). ".
                  __PACKAGE__."'s author would be curious to learn about the weird system you got there.";

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Util - Utility functions for use With Graphics::Raylib::XS


=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Graphics::Raylib::Util;

    # returns Graphics::Raylib::XS::{Vector2,Vector3, Vector4} depending on scalar @coords
    my $vector = Graphics::Raylib::Util::vector(@coords);

=head1 DESCRIPTION

Raylib deals a lot in value-passed structs. This module builds these structs.

=head1 METHODS AND ARGUMENTS

=over 4

=item vector(@coords)

Constructs a C<Graphics::Raylib::XS::Vector2>, C<Graphics::Raylib::XS::Vector3> or C<Graphics::Raylib::XS::Vector4> depending on number of arguments. Croaks otherwise.

    typedef struct Vector2 {
        float x;
        float y;
    } Vector2;

    typedef struct Vector3 {
        float x;
        float y;
        float z;
    } Vector3;

    typedef struct Vector4 {
        float x;
        float y;
        float z;
        float w;
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
            return $obj if $obj->isa("Graphics::Raylib::XS::Vector4");
        }
    }

    my $vector = @coords == 2 ? __vector2(pack("f2", @coords))
               : @coords == 3 ? __vector3(pack("f3", @coords))
               : @coords == 4 ? __vector4(pack("f4", @coords))
               : croak "Only Graphics::Raylib::XS::Vector{2,3,4} types may be constructed";

    return $vector;
}
sub __vector2 { my $binstr = shift; bless \$binstr, 'Graphics::Raylib::XS::Vector2' }
sub __vector3 { my $binstr = shift; bless \$binstr, 'Graphics::Raylib::XS::Vector3' }
sub __vector4 { my $binstr = shift; bless \$binstr, 'Graphics::Raylib::XS::Vector4' }

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

    package Graphics::Raylib::XS::Vector4;
    sub x { return unpack(      "f", ${$_[0]}) }
    sub y { return unpack("x[f]  f", ${$_[0]}) }
    sub z { return unpack("x[ff] f", ${$_[0]}) }
    sub w { return unpack("x[fff]f", ${$_[0]}) }
    sub components { return unpack("f4", ${$_[0]}) }
    sub stringify {
        my ($self) = @_;
        return sprintf '(%d, %d, %d, %d)', $self->components;
    }
    sub add {
        my ($self, $other, $swap) = @_;
        return Graphics::Raylib::Util::vector($self->x + $other->x, $self->y + $other->y, $self->z + $other->z, $self->w + $other->w);
    }
    sub equal {
        my ($self, $other) = @_;
        $$self eq $$other
    }
    use overload fallback => 1, '""' => 'stringify', '+' => 'add', '==' => 'equal', 'abs' => 'Graphics::Raylib::Util::vabs';
    use constant Zero => Graphics::Raylib::Util::vector(0,0,0,0);
}


=item rectangle(x => $x, y => $y, width => $width, height => $height) or rectangle(position => $posVector2, size => $sizeVector2)

Constructs a C<Graphics::Raylib::XS::Rectangle>.

=cut

sub rectangle {
    my %p = ( @_ );
    ($p{x}, $p{y}) = ($p{position}->x, $p{position}->y) if defined $p{position};
    ($p{width}, $p{height}) = ($p{size}->x, $p{size}->y) if defined $p{size};

    return bless \pack("f4", $p{x}, $p{y}, $p{width}, $p{height}), 'Graphics::Raylib::XS::Rectangle'
}

{
    package Graphics::Raylib::XS::Rectangle;
    sub x      { return unpack(      "f", ${$_[0]}) }
    sub y      { return unpack("x[f]  f", ${$_[0]}) }
    sub width  { return unpack("x[ff] f", ${$_[0]}) }
    sub height { return unpack("x[fff]f", ${$_[0]}) }
    sub components {
        my ($x,$y,$w,$h) = unpack("f4", ${$_[0]}); return { x=>$x,y=>$y,width=>$w,height=>$h }
    }
    sub stringify {
        my ($p) = $_[0]->components;
        return sprintf '(x: %f, y: %f, width: %f, height: %f)', $p->{x}, $p->{y}, $p->{width}, $p->{height};
    }
    sub collides {
        Graphics::Raylib::XS::CheckCollisionRecs(shift, shift)
    }
    use overload fallback => 1, '""' => 'stringify', 'x' => 'collides';
}

=item camera3d(position => $pos3d, target => $target3d, up => $up3d, fovy => $fovy)

Constructs a C<Graphics::Raylib::XS::Camera3D>.

    typedef struct Camera3D {
        Vector3 position;
        Vector3 target;
        Vector3 up;
        float fovy;
        int type;
    } Camera3D;

=cut

sub camera3d {
    use constant ZERO => Graphics::Raylib::XS::Vector3::Zero;
    my %p = (position => ZERO, target => ZERO, up => ZERO, fovy => 0, type => 0, @_);
    ($p{position}, $p{target}, $p{up})
        = map { Graphics::Raylib::Util::vector($_) } $p{position}, $p{target}, $p{up};

    my $camera = ${$p{position}}.${$p{target}}.${$p{up}}.pack('f2', $p{fovy}, $p{type});
    return bless \$camera, 'Graphics::Raylib::XS::Camera3D';
}

{
    package Graphics::Raylib::XS::Camera3D;
    sub position { return Graphics::Raylib::Util::vector(unpack(       "f3", ${$_[0]})) }
    sub target   { return Graphics::Raylib::Util::vector(unpack("x[f3]  f3", ${$_[0]})) }
    sub up       { return Graphics::Raylib::Util::vector(unpack("x[f6]  f3", ${$_[0]})) }
    sub fovy     { return                                unpack("x[f9]  f",  ${$_[0]})  }
    sub type     { return                                unpack("x[f10] f",  ${$_[0]})  }
    sub components {
        my $self = shift;
        return {position=>$self->position, target=>$self->target, up=>$self->up, fovy=>$self->fovy, type=>$self->type}
    }
    sub stringify {
        my ($c) = $_[0]->components;
        return sprintf '(position: %s, target: %s, up: %s, fovy: %s, type: %s)',
                        $c->{position}, $c->{target}, $c->{up}, $c->{fovy}, $c->{type};
    }
    use overload fallback => 1, '""' => 'stringify';
}

=item image(data => $str, size => [$width, $height], [ mipmaps => 1, format => UNCOMPRESSED_R8G8B8A8 ])

Constructs a C<Graphics::Raylib::XS::Image>.

    typedef struct Image {
        void *data;             // Image raw data
        int width;              // Image base width
        int height;             // Image base height
        int mipmaps;            // Mipmap levels, 1 by default
        int format;             // Data format (PixelFormat type)
    } Image;

=cut

sub image {
    my %i = (mipmaps => 1, format => Graphics::Raylib::XS::UNCOMPRESSED_R8G8B8A8, @_);

    defined $i{data} && defined $i{width} && defined $i{height} or croak '(data, height, width) may not be undef';

    my $image = pack('Pi4', $i{data}, $i{width}, $i{height}, $i{mipmaps}, $i{format});
    return bless \$image, 'Graphics::Raylib::XS::Image';
}

{
    package Graphics::Raylib::XS::Image;
    #sub bytes   { goto &data }
    sub data    {
        my ($self, $len) = @_;
        return unpack(defined $len ? "P$len" : $PTR_PACK_FMT, $$self)
    }
    sub width   { return  unpack("x[Pi0]i", ${$_[0]})  }
    sub height  { return  unpack("x[Pi1]i", ${$_[0]})  }
    sub size    { return [unpack("x[P]ii",  ${$_[0]})] }
    sub mipmaps { return  unpack("x[Pi2]i", ${$_[0]})  }
    sub format  { return  unpack("x[Pi3]i", ${$_[0]})  }
    sub stringify {
        return sprintf '(Image: %x [%dx%d], mipmaps: %d, format: %d)',
                        $_[0]->data, $_[0]->width, $_[0]->height, $_[0]->mipmaps, $_[0]->format
    }
    use overload fallback => 1, '""' => 'stringify';
}

=begin comment

Constructs a C<Graphics::Raylib::XS::Image>.

    typedef struct Texture2D {
        unsigned int id;        // OpenGL texture id
        int width;              // Texture base width
        int height;             // Texture base height
        int mipmaps;            // Mipmap levels, 1 by default
        int format;             // Data format (PixelFormat type)
    } Texture2D;

=end comment

=cut

{
    package Graphics::Raylib::XS::Texture2D;
    sub id      { return  unpack("      I", ${$_[0]})  }
    sub width   { return  unpack("x[I]  i", ${$_[0]})  }
    sub height  { return  unpack("x[Ii] i", ${$_[0]})  }
    sub size    { return [unpack("x[I] ii",  ${$_[0]})] }
    sub mipmaps { return  unpack("x[Ii2]i", ${$_[0]})  }
    sub format  { return  unpack("x[Ii3]i", ${$_[0]})  }
    sub stringify {
        return sprintf '(Texture2D id:%d [%dx%d], mipmaps: %d, format: %d)',
                        $_[0]->id, $_[0]->width, $_[0]->height, $_[0]->mipmaps, $_[0]->format
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
