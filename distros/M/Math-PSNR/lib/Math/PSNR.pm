package Math::PSNR;

use warnings;
use strict;
use utf8;
use Carp;
use Mouse;

our $VERSION = '0.02';

has bpp => (
    is      => 'rw',
    isa     => 'Int',
    default => '8',
    trigger => sub {
        my $self = shift;
        $self->_set_max_power( $self->_calc_max_power );
    },
);

has x => (
    is       => 'rw',
    isa      => 'ArrayRef|HashRef',
    required => '1',
    trigger  => sub {
        my $self = shift;
        $self->_reset_cache;
    },
);

has y => (
    is       => 'rw',
    isa      => 'ArrayRef|HashRef',
    required => '1',
    trigger  => sub {
        my $self = shift;
        $self->_reset_cache;
    },
);

has max_power => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_max_power',
    init_arg => undef,
    lazy     => '1',
    default  => sub {
        my $self = shift;
        return $self->_calc_max_power;
    },
    trigger  => sub {
        my $self = shift;
        $self->_reset_cache;
    },
);

has mse_cache => (
    is       => 'ro',
    isa      => 'Num|Undef',
    writer   => '_set_mse_cache',
    init_arg => undef,
    default  => undef,
);

has psnr_cache => (
    is       => 'ro',
    isa      => 'Num|Undef',
    writer   => '_set_psnr_cache',
    init_arg => undef,
    default  => undef,
);

no Mouse;

sub _reset_cache {
    my $self = shift;
    $self->_set_mse_cache(undef);
    $self->_set_psnr_cache(undef);
}

sub _sqr {
    my $var = shift;
    return $var * $var;
}

sub _log10 {
    my $var = shift;
    return log($var) / log(10);
}

sub _calc_max_power {
    my $self = shift;
    return 2**$self->bpp - 1;
}

sub _limit {
    my ( $self, $var ) = @_;

    if ( $var < 0 ) {
        return 0;
    }
    elsif ( $var > $self->max_power ) {
        return $self->max_power;
    }
    return $var;
}

sub _square_remainder {
    my ( $self, $x, $y ) = @_;

    $x = $self->_limit($x);
    $y = $self->_limit($y);

    return _sqr( $x - $y );
}

sub _calc_psnr {
    my ( $self, $mse ) = @_;
    return 20 * _log10( $self->max_power / sqrt($mse) );
}

sub _check_exist_key {
    my ( $self, $key ) = @_;

    unless ( exists $self->x->{$key} && exists $self->y->{$key} ) {
        croak "Hash of signal must have key of '$key'.";
    }

    unless ( ref $self->x->{$key} eq 'ARRAY'
        && ref $self->y->{$key} eq 'ARRAY' )
    {
        croak "Value of '$key' must be numerical array reference. ";
    }
}

sub _check_exist_rgb_keys {
    my $self = shift;

    $self->_check_exist_key('r');
    $self->_check_exist_key('g');
    $self->_check_exist_key('b');
}

sub _check_signal_length_each {
    my $self = shift;

    my $signal_length_x = $#{ $self->x->{'r'} };
    unless ( $signal_length_x == $#{ $self->x->{'g'} }
        && $signal_length_x == $#{ $self->x->{'b'} } )
    {
        croak
"Each elements of signal must be the same length. Please check out the length of 'r', 'g', and 'b' of signal x.";
    }

    my $signal_length_y = $#{ $self->y->{'r'} };
    unless ( $signal_length_y == $#{ $self->y->{'g'} }
        && $signal_length_y == $#{ $self->y->{'b'} } )
    {
        croak
"Each elements of signal must be the same length. Please check out the length of 'r', 'g', and 'b' of signal y.";
    }

    unless ( $signal_length_x == $signal_length_y ) {
        croak "Signal length are different between 'Signal x' and 'Signal y'.";
    }
}

sub mse {
    my $self = shift;

    return $self->mse_cache if defined( $self->mse_cache );    # Enable Cache

    unless ( ref $self->x eq 'ARRAY' && ref $self->y eq 'ARRAY' ) {
        croak 'Signals must be array reference.';
    }

    my $signal_length = scalar @{ $self->x };
    unless ( $signal_length == scalar @{ $self->y } ) {
        croak 'Signals must be the same length.';
    }

    my ( $x, $y ) = ( $self->x, $self->y );
    my $sum = 0;
    for my $i ( 0 .. $signal_length - 1 ) {
        $sum += $self->_square_remainder( $x->[$i], $y->[$i] );
    }

    my $mse = $sum / $signal_length;

    $self->_set_mse_cache($mse);
    return $mse;
}

sub psnr {
    my $self = shift;

    return $self->psnr_cache if defined( $self->psnr_cache );    # Enable Cache

    my $mse = defined( $self->mse_cache ) ? $self->mse_cache : $self->mse;
    if ( $mse == 0 ) {
        carp 'Given signals are the same.';
        return 'same';
    }

    my $psnr = $self->_calc_psnr($mse);

    $self->_set_psnr_cache($psnr);
    return $psnr;
}

sub mse_rgb {
    my $self = shift;

    return $self->mse_cache if defined( $self->mse_cache );    # Enable Cache

    unless ( ref $self->x eq 'HASH' && ref $self->y eq 'HASH' ) {
        croak 'Signals must be hash reference.';
    }

    $self->_check_exist_rgb_keys;
    $self->_check_signal_length_each;

    my $signal_length = scalar @{ $self->x->{'r'} };

    my ( $x, $y ) = ( $self->x, $self->y );
    my $sum = 0;
    for my $i ( 0 .. $signal_length - 1 ) {
        $sum +=
          $self->_square_remainder( $x->{'r'}->[$i], $y->{'r'}->[$i] ) +
          $self->_square_remainder( $x->{'g'}->[$i], $y->{'g'}->[$i] ) +
          $self->_square_remainder( $x->{'b'}->[$i], $y->{'b'}->[$i] );
    }

    my $mse = $sum / ( 3 * $signal_length );

    $self->_set_mse_cache($mse);
    return $mse;
}

sub psnr_rgb {
    my $self = shift;

    return $self->psnr_cache if defined( $self->psnr_cache );    # Enable Cache

    my $mse = defined( $self->mse_cache ) ? $self->mse_cache : $self->mse_rgb;
    if ( $mse == 0 ) {
        carp 'Given signals are the same.';
        return 'same';
    }

    my $psnr = $self->_calc_psnr($mse);

    $self->_set_psnr_cache($psnr);
    return $psnr;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::PSNR - Calculate PSNR (Peak Signal-to-Noise Ratio) and MSE (Mean Square Error).


=head1 VERSION

This document describes Math::PSNR version 0.02


=head1 SYNOPSIS

    use Math::PSNR;

    my $psnr = Math::PSNR->new(
        {
            bpp => 8,
            x   => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            y   => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        }
    );

    # Calculate MSE
    $psnr->mse;

    # Calculate PSNR
    $psnr->psnr;

    # Access to member variable of x
    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );

    # Access to member variable of y
    $psnr->y(
        {
            r => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            g => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            b => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        }
    );

    # Calculate MSE of three components signal (e.g. RGB image)
    $psnr->msr_rgb;

    # Calculate PSNR of three components signal (e.g. RGB image)
    $psnr->psnr_rgb;


=head1 DESCRIPTION

This module calculates PSNR (Peak Signal-to-Noise Ration) and MSE (Mean Square Error).

PSNR and MSE are the index of measuring quality between different signals.
They are commonly used to evaluate quality of images.

This module can deal with single component signals (e.g. monochrome image) and
three components signals (e.g. color (RGB) image).

More examples are in my GitHub repository. L<< https://github.com/moznion/p5-Math--PSNR >>


=head1 INTERFACES

=head2 C<< Math::PSNR->new( bpp => $bpp, x => $x, y => $y ) >>

Creates an instance. Attributes are as follows:

=head3 C<< bpp >>

Specify the bpp (bit per pixel). It sets B<2^(bpp) - 1> to maximum power ("maximum power" means maximum allowable value of signal).

=over

=item C<< is : rw >>

This attribute is rewritable. Default accessor to this attribute is provided.

=item C<< isa : Int >>

Please specify value of this attribute as integer.

=item C<< default : 8 >>

This attribute has default value. If I<bpp> is not specified, it will be set 8 (bit).

=item C<< required : 0 >>

You do not have to set value of this attribute at constructor.

=back

=head3 C<< x >>

One side of signal for calculate PSNR and MSE.

=over

=item C<< is : rw >>

This attribute is rewritable. Default accessor to this attribute is provided.

=item C<< isa : ArrayRef|HashRef >>

Please specify value of this attribute as numerical array reference or hash reference.

=item C<< required : 1 >>

You must set value of this attribute at constructor.

=back

=head3 C<< y >>

Another signal for calculate PSNR or MSE.

=over

=item C<< is : rw >>

This attribute is rewritable. Default accessor to this attribute is provided.

=item C<< isa : ArrayRef|HashRef >>

Please specify value of this attribute as numerical array reference or hash reference.

=item C<< required : 1 >>

You must set value of this attribute at constructor.

=back


=head1 METHODS

=over

=item C<< mse >>

This function calculates and returns MSE of single component signal. This function requires values of attribute I<x> and I<y> that is numerical array reference.
Signal (array) length of I<x> and I<y> must be the same.

This function can use cache. If instance is immutable, this function returns previous calculated result.

=item C<< psnr >>

This function calculates and returns PSNR of single component signal. This function requires values of attribute I<x> and I<y> that is numerical array reference.
Signal (array) length of I<x> and I<y> must be the same.

This function can use cache. If instance is immutable, this function returns previous calculated result.
And this function uses cache of MSE if it is available.

=item C<< mse_rgb >>

This function calculates and returns MSE of three components (RGB) signal. This function requires values of attribute I<x> and I<y> that is hash reference. Those hash references must have three components (keys of hash are 'r', 'g', and 'b').
Signal length of each components (keys) of I<x> and I<y> must be the same.

This function can use cache like above-functions.

=item C<< psnr_rgb >>

This function calculates and returns PSNR of three components signal. This function requires values of attribute I<x> and I<y> that is hash reference. Those hash references must have three components (keys of hash are 'r', 'g', and 'b').
Signal length of each components (keys) of I<x> and I<y> must be the same.

This function can use cache like above-functions.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Math::PSNR requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item Mouse (version 1.02 or later)

=item Test::Exception (version 0.31 or later)

=item Test::Warn (version 0.24 or later)

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-math-psnr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
