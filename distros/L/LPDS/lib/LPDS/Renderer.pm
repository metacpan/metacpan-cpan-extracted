package LPDS::Renderer;

use Moose;
use feature qw/say switch/;
use YAML;

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

my @COL_NAMES;
$COL_NAMES[COL_NAME]      = 'name';
$COL_NAMES[COL_CPU_NAME]  = 'cpu_name';
$COL_NAMES[COL_GPU_NAME]  = 'gpu_name';
$COL_NAMES[COL_MEM_SZ]    = 'mem_sz';
$COL_NAMES[COL_MEM_FREQ]  = 'mem_freq';
$COL_NAMES[COL_DISK_SZ]   = 'disk_sz';
$COL_NAMES[COL_DISK_ROT]  = 'disk_rot';
$COL_NAMES[COL_SCREEN_SZ] = 'screen_sz';
$COL_NAMES[COL_PRICE]     = 'price';
$COL_NAMES[COL_COLOR]     = 'color';

my %NAME_COLS = (
    name      => COL_NAME,
    cpu_name  => COL_CPU_NAME,
    gpu_name  => COL_GPU_NAME,
    mem_sz    => COL_MEM_SZ,
    mem_freq  => COL_MEM_FREQ,
    disk_sz   => COL_DISK_SZ,
    disk_rot  => COL_DISK_ROT,
    screen_sz => COL_SCREEN_SZ,
    price     => COL_PRICE,
    color     => COL_COLOR
);

use LPDS::RendererModel;
use LPDS::RendererAxis;

my @MODES_CPU    = qw/score_3dmark06 score_superpi_32m cores threads TDP/;
my @MODES_GPU    = qw/score_3dmark05 score_3dmark06 cores/;
my @MODES_MEM    = qw/size frequency/;
my @MODES_DISK   = qw/size RPM/;
my @MODES_SCREEN = qw/size/;
my @MODES_PRICE  = qw/price/;

use Glib qw/TRUE FALSE/;
use Gtk2;
use Goo::Canvas;

has canvas => (
    is       => 'ro',
    isa      => 'Goo::Canvas',
    required => 1
);

has top_group => (
    is  => 'ro',
    isa => 'Goo::Canvas::Group'
);

has data => (
    is       => 'ro',
    isa      => 'Gtk2::ListStore',
    required => 1
);

has CPU => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1
);

has GPU => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1
);

has axes => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has axes_order => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] }
);

has models => (
    is      => 'ro',
    isa     => 'ArrayRef[LPDS::RendererModel]',
    default => sub { [] }
);

has click_callback => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1
);

sub BUILD {
    my $self = shift;

    # create canvas group object of all children
    my $root      = $self->canvas->get_root_item;
    my $top_group = Goo::Canvas::Group->new($root);
    $top_group->set( x => 50, y => 50 );
    $self->{top_group} = $top_group;

    # connect signal for liststore
    my $data = $self->data;
    $data->signal_connect( 'row-inserted', \&on_data_inserted, $self );
    $data->signal_connect( 'row-deleted',  \&on_data_deleted,  $self );
    $data->signal_connect( 'row-changed',  \&on_data_changed,  $self );

    # axis
    my $base_line =
      Goo::Canvas::Polyline->new_line( $top_group, 0, 300, 800, 300 );
    $base_line->set( 'stroke-color-rgba' => 0x0000007f );

    my @labels = qw/CPU GPU Memory Disk Screen Price/;

    for ( my $i = 0 ; $i < @labels ; $i++ ) {
        my $x = $i * 800 / ( @labels - 1 );

        my @axis_modes;
        given ( $labels[$i] ) {
            when ('CPU') {
                @axis_modes = @MODES_CPU

            }
            when ('GPU') {
                @axis_modes = @MODES_GPU
            }
            when ('Memory') {
                @axis_modes = @MODES_MEM
            }
            when ('Disk') {
                @axis_modes = @MODES_DISK
            }
            when ('Screen') {
                @axis_modes = @MODES_SCREEN;
            }
            when ('Price') {
                @axis_modes = @MODES_PRICE;
            }
        }

        my $axis = LPDS::RendererAxis->new(
            label     => $labels[$i],
            parent    => $self,
            top_group => $top_group,
            x         => $x,
            modes     => \@axis_modes,
        );
        $self->{axes}{ $labels[$i] } = $axis;
        push @{ $self->axes_order }, $labels[$i];
        $axis->render;
    }
}

sub has_model {
    my $self = shift;
    my $name = shift;

    my $store = $self->data;
    for (
        my $iter = $store->get_iter_first ;
        defined $iter ;
        $iter = $store->iter_next($iter)
      )
    {
        my $curr_name = $store->get( $iter, COL_NAME );
        return 1 if $name eq $curr_name;
    }

    return 0;
}

sub get_model {
    my $self = shift;
    my $name = shift;

    foreach my $model ( @{ $self->models } ) {
        return $model if $model->get_name eq $name;
    }

    return undef;
}

sub select_model {
    my $self = shift;
    my $iter = shift;
    
    return undef if !defined $iter;
    
    my $path = $self->data->get_path($iter);

    foreach my $model (@{$self->models}) {
        my $curr_path = $model->row->get_path;
        if ($path->compare($curr_path)==0) {
            $model->set_selected(1);
        }
        else {
            $model->set_selected(0);
        }
    }
}

sub add_model {
    my $self = shift;
    my $iter = shift;

    my $data = $self->data;
    my $name = $data->get( $iter, COL_NAME );

    # create model object
    my $path = $self->data->get_path($iter);
    my $row = Gtk2::TreeRowReference->new( $self->data, $path );

    my $model = LPDS::RendererModel->new(
        top_group => $self->top_group,
        row       => $row,
        parent    => $self,
    );
    my $h = $model->curve->signal_connect( 'button-release-event', $self->click_callback, $model );
    $model->handler($h);
    push @{ $self->models }, $model;

}

sub delete_model {
    my $self = shift;
    my $i    = shift;
    
    my $model = $self->models->[$i];
    $model->curve->signal_handler_disconnect($model->handler);
    
    splice @{ $self->models }, $i, 1;
    
    say "after deletion: ";
    foreach my $model (@{$self->models}) {
        my $name = $self->data->get($model->get_iter,COL_NAME);
        say "\t$name";
    }

    # update axis ticks
    $self->update_all_axis;
}

sub update_axis {
    my $self = shift;
    my $name = shift;
    confess "no axis named $name" if !exists $self->axes->{$name};
    my $axis = $self->axes->{$name};

    my %extreme;    # mode => [min,max]
    
    foreach my $mode ( @{ $axis->modes } ) {
        my @values;
        foreach my $model ( @{ $self->models } ) {
            my $value = $model->get_data_by_axis( $name, $mode );
            push @values, $value if defined $value;
        }
        
        @values = sort { $a <=> $b } @values;

        if ( @values > 1 ) {
            my ( $min, $max ) = @values[ 0, -1 ];
            $extreme{$mode} = [ $min, $max ];
        }
        elsif ( @values == 1 ) {
            $extreme{$mode} = [ $values[0], $values[0] ];
        }
        else {
            $extreme{$mode} = [ undef, undef ];
        }
    }
    
    $axis->try_modify_min_max(%extreme);
}

sub update_all_axis {
    my $self = shift;
    $self->update_axis($_) foreach keys %{ $self->axes };
}

sub request_model_render {
    my $self = shift;
    foreach my $model ( @{ $self->models } ) {
        $model->need_render(1);
    }
}

sub render_model_if_needed {
    my $self = shift;
    foreach my $model ( @{ $self->models } ) {
        $model->render_if_needed;
    }
}

sub render_axis_if_needed {
    my $self = shift;
    foreach my $name ( keys %{ $self->axes } ) {
        $self->axes->{$name}->render_if_needed;
    }
}

sub on_data_inserted {
    say "# on_data_inserted #";
    my ( $data, $path, $iter, $self ) = @_;
    $self->add_model($iter);
    $self->update_all_axis;
}

sub on_data_deleted {
    say "# on_data_deleted #";
    my ( $data, $path, $self ) = @_;
    my $i = ( split /:/, $path->to_string )[0];

    # do deletion
    $self->delete_model($i);

    $self->update_all_axis;
    $self->render_axis_if_needed;
    $self->render_model_if_needed;
}

sub on_data_changed {
    say "# on_data_changed #";
    my ( $data, $path, $iter, $self ) = @_;

    foreach my $model ( @{ $self->models } ) {
        my $curr_path = $model->row->get_path;
        $model->need_render(1) if $curr_path->compare($path) == 0;
    }

    $self->update_all_axis;
    $self->render_axis_if_needed;
    $self->render_model_if_needed;
}
1;
