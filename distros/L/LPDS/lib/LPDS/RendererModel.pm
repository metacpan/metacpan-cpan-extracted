package LPDS::RendererModel;

use Moose;
use feature qw/say switch/;

use Glib qw/TRUE FALSE/;
use Gtk2;
use Goo::Canvas;

use LPDS::Util;

use constant {
    COL_NAME      => 0,
    COL_CPU_NAME  => 1,
    COL_GPU_NAME  => 2,
    COL_MEM_SZ    => 3,
    COL_MEM_FREQ  => 4,
    COL_DISK_SZ   => 5,
    COL_DISK_ROT  => 6,
    COL_SCREEN_SZ => 7,
    COL_PRICE     => 8,
    COL_COLOR     => 9
};

has 'top_group' => (
    is       => 'rw',
    isa      => 'Goo::Canvas::Group',
    required => 1
);

has row => (
    is       => 'ro',
    isa      => 'Gtk2::TreeRowReference',
    required => 1
);

has parent => (
    is       => 'ro',
    isa      => 'LPDS::Renderer',
    weak_ref => 1,
    required => 1
);

has axis_labels => (
    is  => 'ro',
    isa => 'HashRef[Goo::Canvas::Text]'
);

has curve => (
    is  => 'ro',
    isa => 'Goo::Canvas::Path'
);

has need_render => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

has selected => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has handler => (
    is => 'rw',
);

sub BUILD {
    my $self   = shift;
    my $parent = $self->parent;
    
    say "Model created";
    # create labels
    my %labels;

    foreach my $axis_name ( keys %{ $parent->axes } ) {
        my $axis = $parent->axes->{$axis_name};
        my $x    = $axis->x;

        my $text = Goo::Canvas::Text->new( $self->top_group, '', $x, 0, -1,
            'south-west' );
        $labels{$axis_name} = $text;
    }
    $self->{axis_labels} = \%labels;

    # create path
    my $curve = Goo::Canvas::Path->new( $self->top_group, '' );
    $self->{curve} = $curve;

}

sub DESTROY {
    my $self  = shift;
    my $group = $self->top_group;
    
    foreach my $name ( keys %{ $self->axis_labels } ) {
        my $label = $self->axis_labels->{$name};
        my $i     = $group->find_child($label);
        $group->remove_child($i);
    }

    my $curve = $self->curve;
    my $i     = $group->find_child($curve);
    $group->remove_child($i);
}

sub get_name {
    my $self = shift;
    my $data = $self->row->get_model;
    my $path = $self->row->get_path;
    my $iter = $data->get_iter($path);
    my $name = $data->get( $iter, COL_NAME );
    return $name;
}

sub get_color {
    my $self  = shift;
    my $data  = $self->row->get_model;
    my $path  = $self->row->get_path;
    my $iter  = $data->get_iter($path);
    my $color = $data->get( $iter, COL_COLOR );
    return $color;
}

sub get_iter {
    my $self = shift;
    my $data  = $self->row->get_model;
    my $path  = $self->row->get_path;
    return $data->get_iter($path);
}

sub render {
    my $self = shift;

    my $parent = $self->parent;

#    say "render $self";
    my @path_points;

    my $color = $self->get_color;

    foreach my $axis_name ( @{ $parent->axes_order } ) {
        my $axis      = $parent->axes->{$axis_name};
        my $axis_mode = $axis->get_mode;

        my $value = $self->get_data_by_axis( $axis_name, $axis_mode );

        if ( defined $value ) {
            my $x = $axis->x;
            my $y = $axis->calc_y($value);
#            say "\t$axis_name - $axis_mode: $value at $y";

            push @path_points, [ $x, $y ];
            $self->axis_labels->{$axis_name}->set(
                x                   => $x,
                y                   => $y,
                text                => $value,
                'stroke-color-rgba' => $color,
                'fill-color-rgba'   => $color
            );
        }
        else {
            push @path_points, undef;
            $self->axis_labels->{$axis_name}->set( text => '' );
        }
    }

    my @cmd;
    for ( my $i = 1 ; $i < @path_points ; $i++ ) {
        next if !defined $path_points[$i] or !defined $path_points[ $i - 1 ];

        my @curr   = @{ $path_points[$i] };
        my @prev   = @{ $path_points[ $i - 1 ] };
        my $mid_x  = ( $prev[0] + $curr[0] ) / 2;
        my @prev_c = ( $mid_x, $prev[1] );
        my @curr_c = ( $mid_x, $curr[1] );

        push @cmd,
          "M$prev[0],$prev[1]",
          "C$prev_c[0],$prev_c[1] $curr_c[0],$curr_c[1] $curr[0],$curr[1]";

    }
    
    $self->curve->set(
        data                => join( ' ', @cmd ),
        'stroke-color-rgba' => $color
    );
}

sub get_data_by_axis {
    my $self      = shift;
    my $axis_name = shift;
    my $mode      = shift;

    my $data = $self->row->get_model;
    my $path = $self->row->get_path;
    my $iter = $data->get_iter($path);

    my $value;
    given ($axis_name) {
        when ('CPU') {
            my %cpu = %{ $self->parent->CPU };
            my $cpu_name = $data->get( $iter, COL_CPU_NAME );
            if ( defined $cpu_name and defined $cpu{$cpu_name}{$mode} )
            {
                $value = $cpu{$cpu_name}{$mode};
            }
            else {
                $value = undef;
            }
        }
        when ('GPU') {
            my %gpu = %{ $self->parent->GPU };
            my $gpu_name = $data->get( $iter, COL_GPU_NAME );
            if ( defined $gpu_name and defined $gpu{$gpu_name}{$mode} ) {
                $value = $gpu{$gpu_name}{$mode};
            }
            else {
                $value = undef;
            }
        }
        when ('Memory') {
            if ( $mode eq 'size' ) {
                $value = $data->get( $iter, COL_MEM_SZ );
            }
            elsif ( $mode eq 'frequency' ) {
                $value = $data->get( $iter, COL_MEM_FREQ );
            }
            else {
                confess "invalid mem axis: $axis_name - $mode";
            }
        }
        when ('Disk') {
            if ( $mode eq 'size' ) {
                $value = $data->get( $iter, COL_DISK_SZ );
            }
            elsif ( $mode eq 'RPM' ) {
                $value = $data->get( $iter, COL_DISK_ROT );
            }
            else {
                confess "invalid mem axis: $axis_name - $mode";
            }
        }
        when ('Screen') {
            $value = $data->get( $iter, COL_SCREEN_SZ );
        }
        when ('Price') {
            $value = $data->get( $iter, COL_PRICE );
        }
        default {
            confess 'unknown axis name: $axis_name';
        }
    }

    return $value;
}

sub set_selected {
    my $self  = shift;
    my $value = shift;
    
    return undef if $self->selected == $value;
    
    $self->{selected} = $value;

    foreach my $name ( keys %{ $self->axis_labels } ) {
        my $label = $self->axis_labels->{$name};
        if ($value) {
            $label->set( visibility => 'visible' );
        }
        else {
            $label->set( visibility => 'invisible' );
        }
    }

    my $curve = $self->curve;
    my $color = $curve->get('stroke_color_rgba');
    if ($value) {
        $color |= 0x000000ff;
    }
    else {
        $color &= 0xffffff00;
        $color += 0x3f;
    }
    $curve->set( 'stroke_color_rgba' => $color );

}

sub render_if_needed {
    my $self = shift;
    $self->render if $self->need_render;
}

1;
