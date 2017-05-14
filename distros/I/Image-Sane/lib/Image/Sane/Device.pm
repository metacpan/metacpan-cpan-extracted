package Image::Sane::Device;

use 5.008005;
use strict;
use warnings;
use Exception::Class (
    'Image::Sane::Exception' => { alias => 'throw', fields => 'status' } );
use Readonly;
Readonly my $_8BIT        => 8;
Readonly my $MAXINT_8BIT  => 255;
Readonly my $MAXINT_16BIT => 65_535;

our ( $VERSION, $DEBUG );
my $EMPTY = q{};

sub _throw_error {
    my ($status) = @_;
    if ($status) {
        throw error => Image::Sane::strstatus($status), status => $status;
    }
    return;
}

sub open {    ## no critic (ProhibitBuiltinHomonyms)
    my $class  = shift;
    my $device = shift;

    if ( not Image::Sane->init ) { return }

    if ( not $device ) { $device = $EMPTY }
    my ( $status, $self ) = _open($device);
    _throw_error($status);
    bless \$self, $class;
    return \$self;
}

sub get_option {
    my $self = shift;
    my $n    = shift;

    my ( $status, $option ) = $self->_get_option($n);
    _throw_error($status);
    return $option;
}

sub set_auto {
    my $self = shift;
    my $n    = shift;

    my ( $status, $info ) = $self->_set_auto($n);
    _throw_error($status);
    return $info;
}

sub set_option {
    my $self  = shift;
    my $n     = shift;
    my $value = shift;

    my ( $status, $info ) = $self->_set_option( $n, $value );
    _throw_error($status);
    return $info;
}

sub start {
    my ($self) = @_;
    _throw_error( $self->_start );
    return;
}

sub get_parameters {
    my $self = shift;

    my ( $status, $params ) = $self->_get_parameters;
    _throw_error($status);
    return $params;
}

sub read {    ## no critic (ProhibitBuiltinHomonyms)
    my $self   = shift;
    my $maxlen = shift;

    my ( $status, $string, $len ) = $self->_read($maxlen);
    _throw_error($status);
    return $string, $len;
}

sub set_io_mode {
    my $self         = shift;
    my $non_blocking = shift;

    my $status = $self->_set_io_mode($non_blocking);
    _throw_error($status);
    return;
}

sub get_select_fd {
    my $self = shift;

    my ( $status, $fd ) = $self->_get_select_fd;
    _throw_error($status);
    return $fd;
}

sub write_pnm_header {
    my ( $self, $fh, $param ) = @_;

    if ( not defined $fh ) { $fh = \*STDOUT }
    if ( not defined $param ) {
        $param = $self->get_parameters;
    }
    for (qw(format pixels_per_line lines depth)) {
        if ( not defined $param->{$_} or $param->{$_} < 0 ) {
            _throw_error( Image::Sane::SANE_STATUS_INVAL() );
        }
    }

    # The netpbm-package does not define raw image data with maxval > 255.
    # But writing maxval 65535 for 16bit data gives at least a chance
    # to read the image.

    # For some reason, the #defines need parentheses here, but not normally
    if (   $param->{format} == Image::Sane::SANE_FRAME_RED()
        or $param->{format} == Image::Sane::SANE_FRAME_GREEN()
        or $param->{format} == Image::Sane::SANE_FRAME_BLUE()
        or $param->{format} == Image::Sane::SANE_FRAME_RGB() )
    {
        printf {$fh} "P6\n# SANE data follows\n%d %d\n%d\n",
          $param->{pixels_per_line}, $param->{lines},
          ( $param->{depth} <= $_8BIT ) ? $MAXINT_8BIT : $MAXINT_16BIT;
    }

    # For some reason, the #defines need parentheses here, but not normally
    elsif ( $param->{format} == Image::Sane::SANE_FRAME_GRAY() ) {
        if ( $param->{depth} == 1 ) {
            printf {$fh} "P4\n# SANE data follows\n%d %d\n",
              $param->{pixels_per_line}, $param->{lines};
        }
        else {
            printf {$fh} "P5\n# SANE data follows\n%d %d\n%d\n",
              $param->{pixels_per_line}, $param->{lines},
              ( $param->{depth} <= $_8BIT ) ? $MAXINT_8BIT : $MAXINT_16BIT;
        }
    }
    return;
}

1;
__END__
