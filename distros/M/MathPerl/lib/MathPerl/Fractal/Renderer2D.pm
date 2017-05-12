# [[[ HEADER ]]]
package MathPerl::Fractal::Renderer2D;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.006_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);    # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use MathPerl::Fractal::Mandelbrot;
use MathPerl::Fractal::Julia;
use MathPerl::Color::HSV;
use Time::HiRes qw(time);
use POSIX qw(floor);
use SDL;
use SDL::Event;
use SDL::Video;
#use SDL::Mouse;  # NEED REMOVE: not necessary?
use SDLx::App;
use SDLx::Text;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    set            => my integer_arrayref_arrayref $TYPED_set = undef,
    set_name       => my string $TYPED_set_name               = undef,
    set_names      => my string_arrayref $TYPED_set_names     = ['mandelbrot', 'julia', 'mandelbrot_julia' ],  # NEED UPGRADE: remove redundant data via unique_hashref data structure
    set_mode       => my integer $TYPED_set_mode              = undef,
    set_modes      => my integer_hashref $TYPED_set_modes     = { 'mandelbrot' => 0, 'julia' => 1, 'mandelbrot_julia' => 2 },
    set_object     => my MathPerl::Fractal $TYPED_set_object  = undef,
    iterations_max => my integer $TYPED_iterations_max        = undef,
    window_title   => my string $TYPED_window_title           = undef,
    window_width   => my integer $TYPED_window_width          = undef,
    window_height  => my integer $TYPED_window_height         = undef,
    x_pixel_count  => my integer $TYPED_x_pixel_count         = undef,
    y_pixel_count  => my integer $TYPED_y_pixel_count         = undef,
    x_pixel_offset => my integer $TYPED_x_pixel_offset = undef,
    x_min          => my number $TYPED_x_min                  = undef,
    x_max          => my number $TYPED_x_max                  = undef,
    y_min          => my number $TYPED_y_min                  = undef,
    y_max          => my number $TYPED_y_max                  = undef,
    zoom           => my number $TYPED_zoom                   = undef,
    move_factor     => my number $TYPED_move_factor           = 0.1,                  # NEED FIX: remove hard-coded values?
    zoom_factor     => my number $TYPED_zoom_factor           = 0.2,
    iterations_inc  => my integer $TYPED_iterations_inc       = 10,
    iterations_init => my integer $TYPED_iterations_init      = undef,
    automatic       => my boolean $TYPED_automatic            = 0,
    automatic_step  => my integer $TYPED_automatic_step       = undef,
    app             => my SDLx::App $TYPED_app                = undef,
    coloring_name       => my string $TYPED_coloring_name               = undef,
    coloring_names      => my string_arrayref $TYPED_coloring_names     = ['RGB', 'HSV' ],  # NEED UPGRADE: remove redundant data via unique_hashref data structure
    coloring_mode       => my integer $TYPED_coloring_mode              = undef,
    coloring_modes      => my integer_hashref $TYPED_coloring_modes     = { 'RGB' => 0, 'HSV' => 1 },
    color_invert    => my boolean $TYPED_color_invert         = undef,
    color_value      => my integer $TYPED_color_value           = undef,
    color_values     => my integer_arrayref $TYPED_color_values = [ 0, 1, 127, 255 ],
    color_masks     => my integer_arrayref $TYPED_color_masks = undef,
    real_arg => my number $TYPED_real_arg = undef,
    real_arg_inc => my number $TYPED_real_arg_inc = 0.1,
    imaginary_arg => my number $TYPED_imaginary_arg = undef,
    imaginary_arg_inc => my number $TYPED_imaginary_arg_inc = 0.1,
    mouse_clicked => my boolean $TYPED_mouse_clicked = undef,
};

# [[[ OO METHODS & SUBROUTINES ]]]

our void::method $init = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my string $set_name, my integer $x_pixel_count, my integer $y_pixel_count, my integer $iterations_max ) = @_;

    $self->{iterations_init} = $iterations_max;  # save for use on reset
    MathPerl::Fractal::Renderer2D::init_values(@_);

    SDL::init(SDL_INIT_VIDEO);

    $self->{app} = SDLx::App->new(
        title  => $self->{window_title},
        width  => $self->{window_width},
        height => $self->{window_height},
        depth  => 32,                       # 32-bit color
        delay  => 25,                       # don't let SDL overload the CPU
        resizeable => 1                     # dual modes require window resize
    );
};

our void::method $init_values = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my string $set_name, my integer $x_pixel_count, my integer $y_pixel_count, my integer $iterations_max, my string $coloring_name ) = @_;
    if ( not exists $self->{set_modes}->{$set_name} ) { die 'Unknown fractal set name ' . $set_name . ', dying' . "\n"; }
    if ($x_pixel_count < 10) { die 'X pixel count ' . $x_pixel_count . ' below minimum of 10, dying' . "\n"; }
    if ($y_pixel_count < 10) { die 'Y pixel count ' . $y_pixel_count . ' below minimum of 10, dying' . "\n"; }
    if ($iterations_max < 10) { die 'Detail maximum iterations ' . $iterations_max . ' below minimum of 10, dying' . "\n"; }
    if ( not exists $self->{coloring_modes}->{$coloring_name} ) { die 'Unknown fractal coloring name ' . $coloring_name . ', dying' . "\n"; }

    $self->{set_name}        = $set_name;
    $self->{set_mode}        = $self->{set_modes}->{$set_name};
    $self->{window_title}    = 'Fractal Generator';
    $self->{iterations_max}  = $iterations_max;
    $self->{x_pixel_count} = $x_pixel_count;
    $self->{y_pixel_count} = $y_pixel_count;
    $self->{x_pixel_offset} = 0;

    if ( $self->{set_name} eq 'mandelbrot' ) {
        $self->{window_width}  = $x_pixel_count;
        $self->{window_height} = $y_pixel_count;
        $self->{set_object}    = MathPerl::Fractal::Mandelbrot->new();
        $self->{real_arg}      = 0;  # unused in Mandelbrot
        $self->{imaginary_arg} = 0;
    }
    elsif ( $self->{set_name} eq 'julia' ) {
        $self->{window_width}  = $x_pixel_count;
        $self->{window_height} = $y_pixel_count;
        $self->{set_object}    = MathPerl::Fractal::Julia->new();
        $self->{real_arg}      = -0.7;
        $self->{imaginary_arg} = 0.270_15;
    }
    elsif ( $self->{set_name} eq 'mandelbrot_julia' ) {
        $self->{window_width}  = $x_pixel_count * 2;
        $self->{window_height} = $y_pixel_count;
        $self->{set_object}    = MathPerl::Fractal::Julia->new();
        $self->{x_pixel_offset} += $self->{x_pixel_count};
        $self->{real_arg}      = -0.7;
        $self->{imaginary_arg} = 0.270_15;
    }

    $self->{x_min} = $self->{set_object}->X_SCALE_MIN();
    $self->{x_max} = $self->{set_object}->X_SCALE_MAX();
    $self->{y_min} = $self->{set_object}->Y_SCALE_MIN();
    $self->{y_max} = $self->{set_object}->Y_SCALE_MAX();
    $self->{zoom}           = 1.0;
    $self->{automatic_step} = 0;

    $self->{coloring_name}        = $coloring_name;
    $self->{coloring_mode}        = $self->{coloring_modes}->{$coloring_name};
    $self->{color_invert}   = 0;

    # only used for RGB coloring mode, not HSV coloring mode
    $self->{color_value}     = 5;     # blue on black
#   $self->{color_invert} = 1;  $self->{color_value} = 3;  # red on white
    $self->{color_masks} = [
        $self->{color_values}->[ $self->{color_value} % 4 ],
        $self->{color_values}->[ floor( ( $self->{color_value} % 16 ) / 4 ) ],
        $self->{color_values}->[ floor( ( $self->{color_value} % 64 ) / 16 ) ]
    ];

    $self->{mouse_clicked} = 0;
};

our void::method $events = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my SDL::Event $event, my SDLx::App $app ) = @_;
    if ( $event->type() == SDL_QUIT ) { $app->stop(); }
    if ( $event->type() == SDL_KEYDOWN ) {
        my string $key_name   = SDL::Events::get_key_name( $event->key_sym );
        my integer $mod_state = SDL::Events::get_mod_state();
        $self->process_keystroke( $app, $key_name, $mod_state );
    }

    if ($event->type() == SDL_MOUSEBUTTONUP && $event->button_button() == SDL_BUTTON_LEFT) {
#        print 'Mouse Button: Up' . "\n";
        $self->{mouse_clicked} = 0;
    }
    if ($event->type() == SDL_MOUSEBUTTONDOWN && $event->button_button() == SDL_BUTTON_LEFT) {
#        print 'Mouse Button: Down' . "\n";
        $self->{mouse_clicked} = 1;
        (my integer $mouse_mask, my integer $mouse_x, my integer $mouse_y) = @{ SDL::Events::get_mouse_state( ) };
        $self->process_mouseclick( $app, $mouse_mask, $mouse_x, $mouse_y );
    }
    if ($event->type() == SDL_MOUSEMOTION) {
#        print 'Mouse Location: ' . $event->motion_x() . ', ' . $event->motion_y() . "\n";
        (my integer $mouse_mask, my integer $mouse_x, my integer $mouse_y) = @{ SDL::Events::get_mouse_state( ) };
        $self->process_mouseclick( $app, $mouse_mask, $mouse_x, $mouse_y );
#        $self->process_mouseclick( $app, $mouse_mask, $event->motion_x(), $event->motion_y() );
    }
};

our void::method $process_mouseclick = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my SDLx::App $app, my integer $mouse_mask, my integer $mouse_x, my integer $mouse_y ) = @_;
#    print 'Mouse Button: Left' . "\n" if ($mouse_mask & SDL_BUTTON_LMASK);
#    print 'Mouse Button: Right' . "\n" if ($mouse_mask & SDL_BUTTON_RMASK);
#    print 'Mouse Button: Middle' . "\n" if ($mouse_mask & SDL_BUTTON_MMASK);
#    print 'Mouse Location: ' . $mouse_x.', '.$mouse_y . "\n";

    # only use clicks in mandelbrot_julia dual mode, don't use clicks from the Julia screen area on the right, check $self->{mouse_clicked} to allow mouse dragging
    if ($self->{mouse_clicked} and ($self->{set_name} eq 'mandelbrot_julia') and ($mouse_x < $self->{x_pixel_count}) and ($mouse_y < $self->{y_pixel_count})) {
        $self->{real_arg} = MathPerl::Fractal::Mandelbrot->new()->X_SCALE_MIN() + 
            ($mouse_x * ((MathPerl::Fractal::Mandelbrot->new()->X_SCALE_MAX() - MathPerl::Fractal::Mandelbrot->new()->X_SCALE_MIN()) / $self->{x_pixel_count}));
        $self->{imaginary_arg} = MathPerl::Fractal::Mandelbrot->new()->Y_SCALE_MIN() + 
            ($mouse_y * ((MathPerl::Fractal::Mandelbrot->new()->Y_SCALE_MAX() - MathPerl::Fractal::Mandelbrot->new()->Y_SCALE_MIN()) / $self->{y_pixel_count}));
        $self->escape_time_render($app);    # only render additional frames when a change occurs
        $app->update();
    }
};

our void::method $process_keystroke = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my SDLx::App $app, my string $key_name, my integer $mod_state ) = @_;

#    print $key_name . ' ';

    if ( $key_name eq 'q' ) {    # QUIT
        $app->stop();
        return;
    }
    elsif ( $key_name eq 'up' ) {    # MOVE UP
        my number $y_move = ( $self->{y_max} - $self->{y_min} ) * $self->{move_factor};
        $self->{y_min} -= $y_move;
        $self->{y_max} -= $y_move;
    }
    elsif ( $key_name eq 'down' ) {    # MOVE DOWN
        my number $y_move = ( $self->{y_max} - $self->{y_min} ) * $self->{move_factor};
        $self->{y_min} += $y_move;
        $self->{y_max} += $y_move;
    }
    elsif ( $key_name eq 'left' ) {    # MOVE LEFT
        my number $x_move = ( $self->{x_max} - $self->{x_min} ) * $self->{move_factor};
        $self->{x_min} -= $x_move;
        $self->{x_max} -= $x_move;
    }
    elsif ( $key_name eq 'right' ) {    # MOVE RIGHT
        my number $x_move = ( $self->{x_max} - $self->{x_min} ) * $self->{move_factor};
        $self->{x_min} += $x_move;
        $self->{x_max} += $x_move;
    }
    elsif ( $key_name eq 'i' ) {        # ZOOM IN
        my number $zoom_change = $self->{zoom} * $self->{zoom_factor};
        $self->{zoom} = $self->{zoom} + $zoom_change;
        my number $x_zoom_tmp = ( $self->{set_object}->X_SCALE_MAX() - $self->{set_object}->X_SCALE_MIN() ) * ( 1 / $self->{zoom} );
        my number $x_zoom = ( ( $self->{x_max} - $self->{x_min} ) - $x_zoom_tmp ) / 2;
        my number $y_zoom_tmp = ( $self->{set_object}->Y_SCALE_MAX() - $self->{set_object}->Y_SCALE_MIN() ) * ( 1 / $self->{zoom} );
        my number $y_zoom = ( ( $self->{y_max} - $self->{y_min} ) - $y_zoom_tmp ) / 2;

        #        my number $x_zoom = (( $self->{x_max} - $self->{x_min} ) * $zoom_change ) / 2;  # BAD: floating-point rounding error?
        #        my number $y_zoom = (( $self->{y_max} - $self->{y_min} ) * $zoom_change ) / 2;
        $self->{x_min} += $x_zoom;
        $self->{x_max} -= $x_zoom;
        $self->{y_min} += $y_zoom;
        $self->{y_max} -= $y_zoom;
    }
    elsif ( $key_name eq 'o' ) {    # ZOOM OUT
        my number $zoom_change = $self->{zoom} * ( 1 - ( 1 / ( 1 + $self->{zoom_factor} ) ) );
        $self->{zoom} = $self->{zoom} - $zoom_change;
        my number $x_zoom_tmp
            = ( $self->{set_object}->X_SCALE_MAX() - $self->{set_object}->X_SCALE_MIN() ) * ( 1 / $self->{zoom} );
        my number $x_zoom = ( $x_zoom_tmp - ( $self->{x_max} - $self->{x_min} ) ) / 2;
        my number $y_zoom_tmp
            = ( $self->{set_object}->Y_SCALE_MAX() - $self->{set_object}->Y_SCALE_MIN() ) * ( 1 / $self->{zoom} );
        my number $y_zoom = ( $y_zoom_tmp - ( $self->{y_max} - $self->{y_min} ) ) / 2;
        $self->{x_min} -= $x_zoom;
        $self->{x_max} += $x_zoom;
        $self->{y_min} -= $y_zoom;
        $self->{y_max} += $y_zoom;
    }
    elsif ( ( ( $key_name eq '=' ) and ( $mod_state & KMOD_SHIFT ) ) or ( $key_name eq '+' ) ) {    # INCREASE ITERATIONS
        $self->{iterations_max} += $self->{iterations_inc};
    }
    elsif ( ( $key_name eq '-' ) and not( $mod_state & KMOD_SHIFT ) ) {                             # DECREASE ITERATIONS
        if ( $self->{iterations_max} > $self->{iterations_inc} ) {
            $self->{iterations_max} -= $self->{iterations_inc};
        }
    }
    elsif ( $key_name eq 'r' ) {                                                                    # RESET
        $self->init_values( $self->{set_name}, $self->{x_pixel_count}, $self->{y_pixel_count}, $self->{iterations_init}, $self->{coloring_name} );
    }
    elsif ( $key_name eq 'a' ) {                                                                    # AUTOMATIC ON
        $self->{automatic} = 1;
        return;
    }
    elsif ( $key_name eq 'space' ) {                                                                # AUTOMATIC OFF
        $self->{automatic} = 0;
        return;
    }
    elsif ( ( $key_name eq 'c' ) and ( $mod_state & KMOD_CTRL ) ) {    # COLOR MODE
        if   ( $self->{coloring_mode} < (( scalar @{$self->{coloring_names}} ) - 1 ) ) { $self->{coloring_mode}++; $self->{coloring_name} = $self->{coloring_names}->[$self->{coloring_mode}]; }
        else                                                                 { $self->{coloring_mode} = 0; $self->{coloring_name} = $self->{coloring_names}->[$self->{coloring_mode}]; }
    }
    elsif ( ( ( $key_name eq 'c' ) and ( $mod_state & KMOD_SHIFT ) ) or ( $key_name eq 'C' ) ) {    # COLOR VALUE INVERT
        $self->{color_invert} = not $self->{color_invert};
    }
    elsif ( $key_name eq 'c' ) {                                                                    # COLOR VALUE CYCLE
        while (1) {
            if   ( $self->{color_value} < 63 ) { $self->{color_value}++; }
            else                              { $self->{color_value} = 1; }
            $self->{color_masks} = [
                $self->{color_values}->[ $self->{color_value} % 4 ],
                $self->{color_values}->[ floor( ( $self->{color_value} % 16 ) / 4 ) ],
                $self->{color_values}->[ floor( ( $self->{color_value} % 64 ) / 16 ) ]
            ];

            # require at least one color mask is 0, enabling pixel data
            if ( ( $self->{color_masks}->[0] == 0 ) or ( $self->{color_masks}->[1] == 0 ) or ( $self->{color_masks}->[2] == 0 ) ) { last; }
        }
    }
    elsif ( $key_name eq 's' ) {    # SET CYCLE
        if   ( $self->{set_mode} < (( scalar @{$self->{set_names}} ) - 1 ) ) { $self->{set_mode}++; $self->{set_name} = $self->{set_names}->[$self->{set_mode}]; }
        else                                                                 { $self->{set_mode} = 0; $self->{set_name} = $self->{set_names}->[$self->{set_mode}]; }
        $self->init_values( $self->{set_name}, $self->{x_pixel_count}, $self->{y_pixel_count}, $self->{iterations_max}, $self->{coloring_name} );
        $self->{app}->resize($self->{window_width}, $self->{window_height});
        $self->escape_time_render_pre();  # possibly pre-render zeroth frame
    }
    elsif ( ( ( $key_name eq '[' ) and ( $mod_state & KMOD_SHIFT ) ) or ( $key_name eq '{' ) ) {    # JULIA CONSTANT IMAGINARY DECREASE
        if ($self->{set_name} eq 'julia') {
            $self->{imaginary_arg} -= $self->{imaginary_arg_inc};
        }
    }
    elsif ( ( ( $key_name eq ']' ) and ( $mod_state & KMOD_SHIFT ) ) or ( $key_name eq '}' ) ) {    # JULIA CONSTANT IMAGINARY INCREASE
        if ($self->{set_name} eq 'julia') {
            $self->{imaginary_arg} += $self->{imaginary_arg_inc};
        }
    }
    elsif ( $key_name eq '[' ) {    # JULIA CONSTANT REAL DECREASE
        if ($self->{set_name} eq 'julia') {
            $self->{real_arg} -= $self->{real_arg_inc};
        }
    }
    elsif ( $key_name eq ']' ) {    # JULIA CONSTANT REAL INCREASE
        if ($self->{set_name} eq 'julia') {
            $self->{real_arg} += $self->{real_arg_inc};
        }
    }
    else { return; }    # UNUSED KEYSTROKE

    $self->escape_time_render($app);    # only render additional frames when a change occurs
    $app->update();
};

our void::method $escape_time_render = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my SDLx::App $app ) = @_;
#    SDL::Video::fill_rect( $app, SDL::Rect->new( 0, 0, $app->w(), $app->h() ), 0 );    # avoid window resize on exit, blanks out Mandelbrot in mandelbrot_julia dual mode

    my boolean $color_invert_adjusted = $self->{color_invert};
    if ($self->{coloring_name} eq 'HSV') { $color_invert_adjusted = not $color_invert_adjusted; }

    $self->{set} = $self->{set_object}->escape_time(
        $self->{real_arg}, $self->{imaginary_arg}, $self->{x_pixel_count}, $self->{y_pixel_count}, $self->{iterations_max},
        $self->{x_min},    $self->{x_max},         $self->{y_min},        $self->{y_max},      $color_invert_adjusted   
    );

    my integer $x = $self->{x_pixel_offset};
    my integer $y = 0;
    my integer $color_or_mask_red;
    my integer $color_or_mask_green;
    my integer $color_or_mask_blue;
 
    if ($self->{coloring_name} eq 'RGB') {
        # pre-fetch color masks to speed up loop below
        $color_or_mask_red   = $self->{color_masks}->[0];
        $color_or_mask_green = $self->{color_masks}->[1];
        $color_or_mask_blue  = $self->{color_masks}->[2];
    }

# START HERE: correct HSV color, minibrot auto, julia auto, tests, compiled darker color
# START HERE: correct HSV color, minibrot auto, julia auto, tests, compiled darker color
# START HERE: correct HSV color, minibrot auto, julia auto, tests, compiled darker color

    foreach my integer_arrayref $row ( @{ $self->{set} } ) {
        foreach my integer $pixel ( @{$row} ) {
            if ($self->{coloring_name} eq 'RGB') {
                $app->[$x][$y] = [ undef, $color_or_mask_red || $pixel, $color_or_mask_green || $pixel, $color_or_mask_blue || $pixel ];
            }
            else {  # HSV
#                print 'in escape_time_render(), loop (' . $x . ', ' . $y . '), have ($pixel % 256) = ' . ($pixel % 256) . "\n";
                print 'in escape_time_render(), loop (' . $x . ', ' . $y . '), have $pixel = ' . $pixel . "\n";
                ($color_or_mask_red, $color_or_mask_green, $color_or_mask_blue) = 
#                    @{ MathPerl::Color::HSV::hsv_raw_to_rgb_raw([$pixel % 256, 255, 255 * ($pixel < $self->{iterations_max})]) };
                    @{ MathPerl::Color::HSV::hsv_raw_to_rgb_raw([($pixel * 30) % 256, 255, 255 * ($pixel < $self->{iterations_max})]) };
#                    @{ MathPerl::Color::HSV::hsv_raw_to_rgb_raw([0.95 + ($pixel * 10), 255, 255 * ($pixel < $self->{iterations_max})]) };
#                    @{ MathPerl::Color::HSV::hsv_raw_to_rgb_raw([$pixel, 255, 255 * ($pixel < $self->{iterations_max})]) };
                $app->[$x][$y] = [ undef, $color_or_mask_red, $color_or_mask_green, $color_or_mask_blue ];
            }
            $x++;
        }
        $x = $self->{x_pixel_offset};
        $y++;
    }

    my string $status = q{};
    my string $status_tmp;

    # DEV NOTE: both methods of displaying "Zoom" below are correct
    #    $status_tmp = ::number_to_string(($self->{set_object}->X_SCALE_MAX() - $self->{set_object}->X_SCALE_MIN()) / ($self->{x_max} - $self->{x_min}));
    #    if ($status_tmp !~ m/[.]/xms) { $status_tmp .= '.00'; }  # add 2 significant digits after decimal, if missing
    #    $status_tmp =~ s/([.]..).*/$1/xms;  # limit to exactly 2 significant digits after decimal
    #    $status .= 'ZoomCalc:   ' . $status_tmp . 'x' . "\n";
    $status_tmp = pop [split /_/, $self->{set_name}];  # if set name contains underscore(s), select characters after final underscore
    $status .= 'Set:    ' . (ucfirst $status_tmp) . "\n";
    $status_tmp = ::number_to_string( $self->{zoom} );
    if ( $status_tmp !~ m/[.]/xms ) { $status_tmp .= '.00'; }    # add 2 significant digits after decimal, if missing
    $status_tmp =~ s/([.]..).*/$1/xms;                           # limit to exactly 2 significant digits after decimal
    $status .= 'Zoom:   ' . $status_tmp . 'x' . "\n";
    $status .= 'Detail: ' . ::integer_to_string( $self->{iterations_max} ) . "\n";
    $status .= 'Color:  ' . $self->{coloring_name};
    if ($self->{color_invert}) { $status .= ' Inverted'; }
    $status .= "\n";
#    if ($self->{set_name} eq 'julia') {
    if ($self->{set_name} =~ m/julia/xms) {
        if ((abs $self->{real_arg}) < 0.0001) { $status_tmp = '0.00'; }  # fix rounding error when close to 0
        else { $status_tmp = ::number_to_string( $self->{real_arg} ); }
        if ( $status_tmp !~ m/[.]/xms ) { $status_tmp .= '.00'; }    # add 2 significant digits after decimal, if missing
        $status_tmp =~ s/([.]..).*/$1/xms;                           # limit to exactly 2 significant digits after decimal
        $status .= 'Real:   ' . $status_tmp . "\n";
        if ((abs $self->{imaginary_arg}) < 0.0001) { $status_tmp = '0.00'; }  # fix rounding error when close to 0
        else { $status_tmp = ::number_to_string( $self->{imaginary_arg} ); }
        if ( $status_tmp !~ m/[.]/xms ) { $status_tmp .= '.00'; }    # add 2 significant digits after decimal, if missing
        $status_tmp =~ s/([.]..).*/$1/xms;                           # limit to exactly 2 significant digits after decimal
        $status .= 'Imag:   ' . $status_tmp . "\n";
    }

    # scale font within limits
    my integer $font_size = floor $self->{window_height} / 12;
    if    ( $font_size < 10 ) { $font_size = 10; }
    elsif ( $font_size > 20 ) { $font_size = 20; }
    my integer_arrayref $font_color;
    if   ( $self->{color_invert} ) { $font_color = [ 0,   0,   0 ]; }      # black text
    else                           { $font_color = [ 255, 255, 255 ]; }    # white text

    # NEED FIX: remove hard-coded font path
    SDLx::Text->new(
        font  => 'fonts/VeraMono.ttf',
        size  => $font_size,
        color => $font_color,
        text  => $status,
        x     => 10 + $self->{x_pixel_offset},
        y     => 10,
    )->write_to($app);

};

our void::method $move = sub {
    ( my MathPerl::Fractal::Renderer2D $self, my number $dt, my SDLx::App $app, my number $t ) = @_;

    #    print 'in move(), received $dt = ' . $dt . ', $t = ' . $t . "\n";
    #    print 'in move(), have $self->{automatic_step} = ' . $self->{automatic_step} . "\n";

    my string_arrayref $auto_moves
        = [
        qw(r up up right right i i i right up i i i i i up i i i i i i right up i i i i i i i i + + i i i i i i i + i + i i i i + right i i i i i + i i i i i i i i i + i i i i i i + i i + i i i i i i i i i i i + i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i)
        ];

    if ( $self->{automatic} ) {

        # check for SPACE keystroke both in events() and here in move(), double keystroke checking is standard practice
        SDL::Events::pump_events();
        my $keys_ref = SDL::Events::get_key_state();
        if ( $keys_ref->[SDLK_SPACE] ) { $self->{automatic} = 0; }

        # simply stop when end of $auto_moves is reached
        if ( $self->{automatic_step} >= ( scalar @{$auto_moves} ) ) {
            $self->{automatic}      = 0;
            $self->{automatic_step} = 0;
        }
        else {
            $self->process_keystroke( $app, $auto_moves->[ $self->{automatic_step} ], 0 );
            $self->{automatic_step}++;
        }

        $self->escape_time_render($app);    # only render additional frames when a change occurs
        $app->update();
    }
};

our void::method $render2d_video = sub {
    ( my MathPerl::Fractal::Renderer2D $self ) = @_;

    $self->escape_time_render_pre();  # possibly pre-render zeroth frame
    $self->escape_time_render( $self->{app} );    # render first frame
    $self->{app}->update();

    $self->{app}->add_event_handler( sub { $self->events(@_) } );
    $self->{app}->add_move_handler( sub  { $self->move(@_) } );

    #    $self->{app}->add_show_handler( sub { $self->{app}->update() } );

    #    $self->{app}->fullscreen();
    $self->{app}->run();
};

our void::method $escape_time_render_pre = sub {
    ( my MathPerl::Fractal::Renderer2D $self ) = @_;

    # render Mandelbrot only once in mandelbrot_julia dual mode
    if ( $self->{set_name} eq 'mandelbrot_julia' ) {
        $self->init_values('mandelbrot', $self->{x_pixel_count}, $self->{y_pixel_count}, $self->{iterations_max}, $self->{coloring_name});
        $self->escape_time_render($self->{app});
        $self->{app}->update();
        $self->init_values('mandelbrot_julia', $self->{x_pixel_count}, $self->{y_pixel_count}, $self->{iterations_max}, $self->{coloring_name});
    }
};

1;    # end of class
