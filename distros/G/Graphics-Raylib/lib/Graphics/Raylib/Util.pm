use strict;
use warnings;
package Graphics::Raylib::Util;

# ABSTRACT: Utility functions for use With Graphics::Raylib:XS
our $VERSION = '0.008'; # VERSION

use List::Util qw(min max);
use Graphics::Raylib::XS qw(:all);
use Carp;

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Util - Utility functions for use With Graphics::Raylib:XS


=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Graphics::Raylib::Util;

    # returns Vector2 or Vector3 depending on scalar @coords
    my $vector = Graphics::Raylib::Util::vector(@coords);

=head1 DESCRIPTION

Raylib deals a lot in value-passed structs. This module builds these structs.

=head1 METHODS AND ARGUMENTS

=over 4

=item vector(@coords)

Constructs a C<Vector2> or C<Vector3> depending on number of arguments. Croaks otherwise.

=cut

sub vector {
    my $vector = @_ == 2 ? bless \pack("f2", @_), 'Vector2'
               : @_ == 3 ? bless \pack("f3", @_), 'Vector3'
               : croak "Only Vector2 and Vector 3 types may be constructed";

    return $vector;
}

{
    package Vector2;
    sub x { return unpack(     "f", ${$_[0]}) }
    sub y { return unpack("x[f] f", ${$_[0]}) }
    sub components { return unpack("f2", ${$_[0]}) }
    sub stringify {
        my ($self) = @_;
        return sprintf '(%d, %d)', $self->components;
    }
    use overload fallback => 1, '""' => 'stringify';

    package Vector3;
    sub x { return unpack(     "f", ${$_[0]}) }
    sub y { return unpack("x[f] f", ${$_[0]}) }
    sub z { return unpack("x[ff]f", ${$_[0]}) }
    sub components { return unpack("f3", ${$_[0]}) }
    sub stringify {
        my ($self) = @_;
        return sprintf '(%d, %d, %d)', $self->components;
    }
    use overload fallback => 1, '""' => 'stringify';

}

=item rectangle(x => $x, y => $y, width => $width, height => $height)

Constructs a C<Rectangle>.

=cut

sub rectangle {
    my %p = ( x => 0, y => 0, height => 1, width => 1, @_ );
    return bless \pack("i4", $p{x}, $p{y}, $p{width}, $p{height}), 'Rectangle'
}

{
    package Rectangle;
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
