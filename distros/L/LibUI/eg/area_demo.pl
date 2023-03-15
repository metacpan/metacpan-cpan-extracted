use strict;
use warnings;
use lib '../lib';
#
{
    use LibUI ':all';
    use LibUI::Window;
    use LibUI::Area;
    use LibUI::Draw::Brush;
    use LibUI::Draw::Path;
    use LibUI::Draw;
    use LibUI::HBox;
    #
    Init() && die;

    # Helper to quickly set a brush color
    sub buildSolidBrush {
        my ( $color, $alpha ) = @_;
        my $component = ( $color >> 16 ) & 0xff;
        my $R         = $component / 255;
        $component = ( $color >> 8 ) & 0xff;
        my $G = $component / 255;
        $component = $color & 0xff;
        my $B = $component / 255;
        my $A = $alpha;
        #
        return { R => $R, G => $G, B => $B, A => $A, type => LibUI::Draw::BrushType::Solid() };
    }
    my $colorDodgerBlue = 0x1E90FF;
    my $window          = LibUI::Window->new( 'Hi', 640, 480, 1 );
    my $hbox            = LibUI::HBox->new;
    $window->setChild($hbox);
    my $widget = LibUI::Area->new(
        {   draw => sub {
                use Data::Dump;
                ddx \@_;
                my ( $s, $area, $p ) = @_;

                # fill the area with a dodger blue color rectangle
                my $brush = buildSolidBrush( $colorDodgerBlue, 1.0 );
                my $path  = LibUI::Draw::Path->new( LibUI::Draw::FillMode::Winding() );
                $path->addRectangle( 0, 0, $p->{width}, $p->{height} );
                $path->end;
                LibUI::Draw::fill( $p->{context}, $path, $brush );
                $path->free();
            },
            mouseEvent   => sub { },
            mouseCrossed => sub { },
            dragBroken   => sub { },
            keyEvent     => sub { }
        }
    );
    $hbox->append( $widget, 1 );
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();
}
