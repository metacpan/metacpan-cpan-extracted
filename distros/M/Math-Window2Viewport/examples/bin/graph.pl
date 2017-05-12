#!/usr/bin/env perl 

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;

use POSIX;
use GD::Simple;
use Math::Trig qw( asin );
use Math::Window2Viewport;

GetOptions (
    'wave=s'    => \my $wave,
    'width=i'   => \my $width,
    'height=i'  => \my $height,
    'res=s'     => \my $res,
    help        => \my $help,
    man         => \my $man,
);
pod2usage( -verbose => 0 ) if $help;
pod2usage( -verbose => 2 ) if $man;

$width  ||= 200;
$height ||= 150;
$res    ||= .01;

our %map_args = (
    Wb => 0,        Wt => 1, Wl => 0, Wr => 4,
    Vb => $height,  Vt => 0, Vl => 0, Vr => $width,
);

my %waves = (
    sine        => \&sine,
    square      => \&square,
    fsquare     => \&fsquare,
    sawtooth    => \&sawtooth,
    triangle    => \&triangle,
);

$wave = 'sine' unless exists $waves{$wave || ''};
my $sub = $waves{$wave};

print $sub->( GD::Simple->new( $width, $height ), abs( $res ), $wave );


sub sine {
    my $mapper = Math::Window2Viewport->new( %map_args, Wb => -1, Wr => 3.1459 * 2 );
    return _graph_it( $mapper, sub { sin( $_[0] ) }, @_ );
}

sub sawtooth {
    my $mapper = Math::Window2Viewport->new( %map_args );

    my $sub = sub {
        my $tmp = $_[0] / $mapper->{Wr} * 2 * 1.618;
        return 1 * ( $tmp - floor( $tmp ) );
    };

    return _graph_it( $mapper, $sub, @_ );
}

sub triangle {
    my $mapper = Math::Window2Viewport->new( %map_args, Wb => -1 );

    my $sub = sub {
        return (2 / 3.1459 ) * asin( sin( $_[0] * 3.1459 ) );
    };

    return _graph_it( $mapper, $sub, @_ );
}

sub square {
    my $mapper = Math::Window2Viewport->new( %map_args, Wb => -2, Wt => 2 );

    my $sign = sub { $_[0] >= 0 ? ($_[0] == 0 ? 0 : 1) : -1 };
    my $sub = sub {
        return .9 * $sign->( sin( 2 * 3.1459 * ( $_[0] - .5 ) / $mapper->{Wr} * 2 ) );
    };

    return _graph_it( $mapper, $sub, @_ );
}


sub fsquare {
    my $mapper = Math::Window2Viewport->new( %map_args, Wb => -1, Wr => 2 );

    my $sub = sub { 
        my $y = 0;
        for (my $i = 1; $i < 20; $i += 2) {
            $y += 1 / $i * cos( 2 * 3.1459 * $i * $_[0] + ( -3.1459 / 2 ) );
        }
        $y;
    };

    return _graph_it( $mapper, $sub, @_ );
}


sub _graph_it {
    my ($mapper,$yval,$img,$res,$wave) = @_;

    my (%curr,%prev);
    for (my $x = $mapper->{Wl}; $x <= $mapper->{Wr}; $x += $res) {
        my $y = $yval->( $x );
        %curr = ( dx => $mapper->Dx( $x ), dy => $mapper->Dy( $y ) );
        if (keys %prev) {
            $img->moveTo( @prev{qw(dx dy)} );
            $img->lineTo( @curr{qw(dx dy)} );
        } else {
            $img->moveTo( @curr{qw(dx dy)} );
        }
        %prev = %curr;
    }

    $img->moveTo( $mapper->Dx( $mapper->{Wr} / 3 ), $mapper->Dy( $mapper->{Wb} ) );
    $img->fgcolor('blue');
    $img->string( "$wave wave" );
    return $img->png;
}


# for GD
# sudo apt-get -y install libgd2-xpm-dev build-essential


__END__
=head1 NAME

graph.pl - 

=head1 SYNOPSIS

graph.pl [options]

 Options:
   --wave           sine or sqaure
   --height         height of PNG output
   --width          width of PNG output
   --res            resolution of wave
   --help           list usage
   --man            print man page

=head1 OPTIONS

=over 8

=item B<--wave>

The waveform to draw. Current options are:

  sin
  square

=item B<--height>

The height (in pixels) of the PNG output.

=item B<--width>

The width (in pixels) of the PNG output.

=item B<--res>

The resolution of the waveform. Values between
0 and 1 work best.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will produce a waveform in PNG format
on request.

=cut
