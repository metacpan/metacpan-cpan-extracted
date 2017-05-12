package Image::Simple::Gradient;

use Moose;
use GD;
use GD::Simple;
use Moose::Util::TypeConstraints;


subtype 'Email'
   => as 'Str'
   => where { Email::Valid->address($_) }
   => message { "$_ is not a valid email address" };

subtype 'Rgbhex'
   => as 'Str'
   => where { $_ =~ m/^((\d|\w){6})$/  }
   => message { "$_ is not a valid RBG Hex. ie. FFFFFF" };

subtype 'Direction'
   => as 'Str'
   => where { $_ =~ m/^(up|down|left|right)$/i }
   => message { "$_ is not a valid direction. Use up, down, left or right" };

has [qw( width height )] => ( is => 'ro', isa => 'Int', required => 1, );
has [qw( color_begin color_end )] => ( is => 'ro', isa => 'Rgbhex', required => 1, );
has direction => (
    is => 'ro',
    isa => 'Direction',
    required => 1,
    );

sub BUILD {
    my ( $self, $params ) = @_;
}

sub mkramp
{
    my ( $self, $im, $steps, $r0, $g0, $b0, $r1, $g1, $b1 ) = @_;
    my $dr   = ( $r1 - $r0 ) / $steps;
    my $dg   = ( $g1 - $g0 ) / $steps;
    my $db   = ( $b1 - $b0 ) / $steps;
    my @ramp = ();

    my $r = $r0;
    my $g = $g0;
    my $b = $b0;
    for ( my $i = 0 ; $i < $steps ; $i++ ) {
        @ramp = ( @ramp, $im->colorAllocate( $r, $g, $b ) );
        $r += $dr;
        $g += $dg;
        $b += $db;
    }
    return @ramp;
}

sub render_gradient  {
    my ( $self ) = @_;
    my $width = $self->width;
    my $height = $self->height;

        my $from = $self->color_begin;
        my $to   = $self->color_end;
        my $dir  = $self->direction;

        $from =~ s/(..)(..)(..)/$1\|$2\|$3/;
        my ( $from_r, $from_g, $from_b ) = split( /\|/, $from );

        $to =~ s/(..)(..)(..)/$1\|$2\|$3/;
        my ( $to_r, $to_g, $to_b ) = split( /\|/, $to );

        $from_r = hex($from_r);
        $from_g = hex($from_g);
        $from_b = hex($from_b);
        $to_r   = hex($to_r);
        $to_g   = hex($to_g);
        $to_b   = hex($to_b);

        my $steps = 1;
        if ( $dir =~ m/down/i )  { $steps = $height; }
        if ( $dir =~ m/up/i )    { $steps = $height; }
        if ( $dir =~ m/left/i )  { $steps = $width; }
        if ( $dir =~ m/right/i ) { $steps = $width; }

        # create a new image
        GD::Image->trueColor(1);
        my $im = new GD::Image( $width, $height );

        my @ramp =
          $self->mkramp( $im, $steps, $from_r, $from_g, $from_b, $to_r, $to_g,
            $to_b );

        if ( $dir eq "down" ) {
            for ( my $i = 0 ; $i < $height ; $i++ ) {
                $im->line( 0, $i, $width, $i, $ramp[$i] );
            }
        }
        elsif ( $dir eq "up" ) {
            for ( my $i = 0 ; $i < $height ; $i++ ) {
                $im->line( 0, $i, $width, $i, $ramp[ $height - $i - 1 ] );
            }
        }
        elsif ( $dir eq "left" ) {
            for ( my $i = 0 ; $i < $width ; $i++ ) {
                $im->line( $i, 0, $i, $height, $ramp[$i] );
            }
        }
        elsif ( $dir eq "right" ) {
            for ( my $i = 0 ; $i < $width ; $i++ ) {
                $im->line( $i, 0, $i, $height, $ramp[ $width - $i - 1 ] );
            }
        }

        return $im->jpeg(100);
}


=head1 NAME

Image::Simple::Gradient create simple gradients for your perl web / software application.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Create simple gradient images with this module.
If you are looking for a way to render a gradient image going from one color to another color, this is the module for it.
Its useful when your designer needs an easy simple way to generate gradient colors for a webpage or application software.

direction can be: up, down, left, right.
height and width: in pixels.
color_begin and color_end are rgb hex values  with 6 digits. ex: FF0000

    use Image::Simple::Gradient;

    my $im = Image::Simple::Gradient->new({
        color_begin => 'FF0000',
        color_end => '0000FF',
        direction => 'up',
        height => 100,
        width => 200,
        });
    my $im = $image->render_gradient();

    if (open FH, "> my_gradient.jpg") {
      binmode FH;
      my $IO = fileno(FH);
      print FH $im, $filename;
      }



=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS


=over

=item new( HASH_REF );

A hash reference must be passed on construction.

Follow the example:

    my $image = Image::Simple::Gradient->new({
        color_begin => 'FF0000',
        color_end => '0000FF',
        direction => 'up',
        height => 100,
        width => 200,
        });


=item render_gradient();

Renders the image and returns a jpg. ie:

    my $im = $image->render_gradient();

=head1 MODULE AUTHOR

Hernan Lopes, C<< <hernanlopes at gmail.com> >>

=head1 ORIGINAL AUTHOR

Michal Guerquin, C<< <michalg at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-simple-gradient at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-Simple-Gradient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::Simple::Gradient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-Simple-Gradient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-Simple-Gradient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-Simple-Gradient>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-Simple-Gradient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hernan Lopes.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
__PACKAGE__->meta->make_immutable;

1; # End of Image::Simple::Gradient
