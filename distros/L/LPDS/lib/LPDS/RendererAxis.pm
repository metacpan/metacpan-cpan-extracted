package LPDS::RendererAxis;

use Moose;
use feature qw/say switch/;

use Glib qw/TRUE FALSE/;
use Gtk2;
use Goo::Canvas;
use List::MoreUtils qw/any/;
use POSIX qw/ceil/;
use YAML;

has 'label' => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has 'top_group' => (
    is       => 'rw',
    isa      => 'Goo::Canvas::Group',
    required => 1
);

has 'modes' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1
);

has modes_combo => (
    is  => 'ro',
    isa => 'Gtk2::ComboBox'
);

has 'x' => (
    is       => 'rw',
    isa      => 'Num',
    required => 1
);

has 'ticks' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

has 'min' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'parent' => (
    is       => 'rw',
    isa      => 'LPDS::Renderer',
    weak_ref => 1,
    required => 1
);

has 'max' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'need_render' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

sub BUILD {
    my $self = shift;
    my $line =
      Goo::Canvas::Polyline->new_line( $self->top_group, $self->x, 0, $self->x,
        300 );
    $line->set( 'stroke-color-rgba' => 0x0000007f );
    my $text =
      Goo::Canvas::Text->new( $self->top_group, $self->label, $self->x, 300, -1,
        'north' );

    my $combo = Gtk2::ComboBox->new_text;
    $combo->append_text($_) foreach @{ $self->modes };
    $combo->set_active(0);
    $combo->signal_connect( 'changed' => \&_on_axis_mode_changed, $self );
    $self->{modes_combo} = $combo;
    my $combo_container =
      Goo::Canvas::Widget->new( $self->top_group, $combo, $self->x - 10,
        320, -1, -1 );

    foreach ( @{ $self->modes } ) {
        $self->{min}{$_} = undef;
        $self->{max}{$_} = undef;
    }
}

sub render {
    my $self = shift;

    my $mode = $self->get_mode;

    # clear old ticks
    foreach my $pair ( @{ $self->ticks } ) {
        foreach (@$pair) {
            my $i = $self->top_group->find_child($_);
            $self->top_group->remove_child($i);
        }
    }
    $self->ticks( [] );

    # validate range
    return undef if $self->max == $self->min;

    # generate new ticks
    my @list = $self->gen_tick_list;
    
    my $min  = $self->{min}{$mode};
    my $max  = $self->{max}{$mode};

    unshift @list, $min
      if defined $min and $min != $list[0];
    push @list, $max
      if defined $max and $max != $list[-1];

    
    foreach (@list) {
        my $y = $self->calc_y($_);

        my $line_obj =
          Goo::Canvas::Polyline->new_line( $self->top_group, $self->x, $y,
            $self->x - 5, $y );
        $line_obj->set( 'stroke-color-rgba' => 0x0000007f );

        my $text_obj = Goo::Canvas::Text->new( $self->top_group, $_, 0, 0, -1,
            'south-east' );
        $text_obj->set(
            'stroke-color-rgba' => 0x0000007f,
            'fill-color-rgba'   => 0x0000007f,
        );
        $text_obj->translate( $self->x - 5, $y );
        $text_obj->scale( 0.7, 0.7 );

        push @{ $self->ticks }, [ $line_obj, $text_obj ];
    }

    $self->need_render(0);
}

sub render_if_needed {
    my $self = shift;
    $self->render if $self->need_render;
}

sub calc_y {
    my $self  = shift;
    my $input = shift;

    my $mode = $self->get_mode;

    my $min = $self->{min}{$mode};
    my $max = $self->{max}{$mode};
    $min = 0 if !defined $min;
    $max = 0 if !defined $max;

    my $range = $max - $min;

    if ( $range == 0 ) {
        return 300 / 2;
    }
    else {
        return 300 * ( 1 - ( $input - $min ) / $range );
    }
}

sub gen_tick_list {
    my $self = shift;
    my $mode = $self->get_mode;

    my $max = $self->{max}{$mode};
    my $min = $self->{min}{$mode};
    $min = 0 if !defined $min;
    $max = 0 if !defined $max;

    if ( $min == $max ) {
        return $min;
    }
    else {
        my $length = $max - $min;
        my $digits = length $length;
        my $step   = 10**( $digits - 1 );
        $step /= 2 if $length / $step < 5;

        my @result;
        my $start = ceil( $min / $step );
        for ( my $curr = $start ; $curr < $max ; $curr += $step ) {
            push @result, $curr;
        }
        return @result;
    }
}

sub get_mode {
    my $self = shift;
    return $self->modes_combo->get_active_text;
}

sub try_modify_min_max {
    my ( $self, %values ) = @_;
    
    my $axis_mode = $self->get_mode;
    my $changed = 0;
    
    foreach my $mode ( keys %values ) {
        my ($min,$max) = @{$values{$mode}};

        confess "invalid mode: $mode for axis ", $self->label,
          ", valid modes for this axis are: ", join( '|', @{ $self->modes } )
          if !( grep { $_ eq $mode } @{ $self->modes } );
        
        # modify min
        if (defined $min) {
            if (!defined $self->min->{$mode} or $min != $self->min->{$mode}) {
                $changed = 1 if $mode eq $axis_mode;
                $self->min->{$mode} = $min;
            }
        }
        else {
            if (defined $self->min->{$mode}) {
                $changed = 1 if $mode eq $axis_mode;
                $self->min->{$mode} = $min;
            }
        }
        
        # modify max
        if (defined $max) {
            if (!defined $self->max->{$mode} or $max != $self->max->{$mode}) {
                $changed = 1 if $mode eq $axis_mode;
                $self->max->{$mode} = $max;
            }
        }
        else {
            if (defined $self->max->{$mode}) {
                $changed = 1 if $mode eq $axis_mode;
                $self->max->{$mode} = $max;
            }
        }
    }

    if ($changed) {
        $self->need_render(1);
        $self->parent->request_model_render;
    }
}

sub _on_axis_mode_changed {
    my ( $combo, $self ) = @_;
    $self->render;
    $self->parent->request_model_render;
    $self->parent->render_model_if_needed;
}

1;

