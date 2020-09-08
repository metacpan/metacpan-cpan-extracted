package Math::Matrix::Banded::Square;
use 5.014;

=pod

=head1 NAME

Math::Matrix::Banded::Square - banded square matrix

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.004';

use Moo;
use List::Util (
    'min',
    'max',
);
use Try::Tiny;


=pod

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Math::Matrix::Banded;

    my $foo = Math::Matrix::Banded->new();
    ...

=head1 DESCRIPTION


=head1 ATTRIBUTES

=head3 data

=cut

has 'N' => (
    is       => 'ro',
    required => 1,
);

has 'm_below' => (
    is      => 'rwp',
    lazy    => 1,
    default => 0,
);

has 'm_above' => (
    is      => 'rwp',
    lazy    => 1,
    default => 0,
);

has 'symmetric' => (
    is      => 'lazy',
    default => 0,
);

has '_data' => (
    is      => 'lazy',
    builder => sub {
        my ($self)  = @_;
        my $N       = $self->N;
        my $m       = $self->m_below + 1 + $self->m_above;
        my $data    = [];

        for (my $i=0;$i<$N;$i++) {
            push(@$data, [map { 0 } (1..$m)]);
        }

        return $data;
    },
);

has '_LU_raw' => (
    is        => 'rwp',
    lazy      => 1,
    builder   => '_decompose_LU_without_pivoting',
    clearer   => 1,
    predicate => 1,
    trigger   => sub {
        my ($self) = @_;

        $self->clear_L;
        $self->clear_U;
        $self->clear_permutation;
    },
);

has 'L' => (
    is        => 'lazy',
    builder   => sub {
        my ($self) = @_;

        return $self->_LU_raw->[0];
    },
    clearer   => 1,
    predicate => 1,
);

has 'U' => (
    is        => 'lazy',
    builder   => sub {
        my ($self) = @_;

        return $self->_LU_raw->[1];
    },
    clearer   => 1,
    predicate => 1,
);

has 'permutation' => (
    is        => 'lazy',
    builder   => sub {
        my ($self) = @_;

        return $self->_LU_raw->[2];
    },
    clearer   => 1,
    predicate => 1,
);

=pod

=head1 METHODS

=cut

sub element {
    my ($self, $i, $j, @args) = @_;
    my $m_below               = $self->m_below;
    my $m_above               = $self->m_above;
    my $data                  = $self->_data;

    my $j_eff_max = $m_below + $m_above;
    my $j_eff     = $j + $m_below - $i;
    if (@args > 0) {
        if ($j_eff < 0) {
            $self->_increase_m_below(-$j_eff);
            $j_eff_max -= $j_eff;
            $j_eff      = 0;
        }
        elsif ($j_eff > $j_eff_max) {
            $self->_increase_m_above($j_eff - $j_eff_max);
            $j_eff_max = $j_eff;
        }
        $data->[$i]->[$j_eff] = $args[0];

        if (!$args[1] and $self->symmetric and $i != $j) {
            $self->element($j, $i, $args[0], 1);
        }
    }

    if ($j_eff < 0 or $j_eff > $j_eff_max) { return 0 }
    else { return($data->[$i]->[$j_eff] // 0) }
}


sub _increase_m_below {
    my ($self, $k) = @_;
    my $data       = $self->_data;

    my @zeroes = map { 0 } (1..$k);
    foreach my $row (@$data) {
        unshift(@$row, @zeroes);
    }
    $self->_set_m_below($self->m_below + $k);
}


sub _increase_m_above {
    my ($self, $k) = @_;
    my $data       = $self->_data;

    my @zeroes = map { 0 } (1..$k);
    foreach my $row (@$data) {
        push(@$row, @zeroes);
    }
    $self->_set_m_above($self->m_above + $k);
}


sub row {
    my ($self, $i) = @_;
    my $N          = $self->N;
    my $m_below    = $self->m_below;
    my $m_above    = $self->m_above;
    my $data       = $self->_data;

    my $stored_row = $data->[$i];
    my $j_eff_max  = $m_below + $m_above;
    my $row        = [];
    for (my $j=0;$j<$N;$j++) {
        my $j_eff = $j + $m_below - $i;
        push(
            @$row,
            ($j_eff < 0 || $j_eff > $j_eff_max)
                ? 0 : $stored_row->[$j_eff],
        );
    }

    return $row;
}


sub column {
    my ($self, $j) = @_;
    my $N          = $self->N;
    my $m_below    = $self->m_below;
    my $m_above    = $self->m_above;
    my $data       = $self->_data;

    my $j_eff_max  = $m_below + $m_above;
    my $col        = [];
    for (my $i=0;$i<$N;$i++) {
        my $stored_row = $data->[$i];
        my $j_eff      = $j + $m_below - $i;
        push(
            @$col,
            ($j_eff < 0 || $j_eff > $j_eff_max)
                ? 0 : $stored_row->[$j_eff],
        );
    }

    return $col;
}


sub as_string {
    my ($self) = @_;
    my $N      = $self->N;

    return join(
        qq{\n},
        map { join(' ', map { sprintf(q{%7.3f}, $_) } @$_) }
        map { $self->row($_) }
        (0..$N-1),
    );
}


sub fill_random {
    my ($self, $min, $max) = @_;
    my $N                  = $self->N;
    my $m_below            = $self->m_below;
    my $m_above            = $self->m_above;
    my $data               = $self->_data;

    $min //= -1;
    $max //= 1;
    my $range = $max - $min;

    for (my $i=0;$i<$N;$i++) {
        my $j_min = max(0, $i - $m_below);
        my $j_max = min($N - 1, $i + $m_above);
        for (my $j=$j_min;$j<=$j_max;$j++) {
            $self->element($i, $j, rand($range) + $min);
        }
    }
}


sub multiply_vector {
    my ($self, $v) = @_;
    my $N          = $self->N;
    my $m_below    = $self->m_below;
    my $m_above    = $self->m_above;
    my $data       = $self->_data;

    my $w = [];
    for (my $i=0;$i<$N;$i++) {
        my $row   = $data->[$i];
        my $j_min = max(0, $i - $m_below);
        my $j_max = min($N - 1, $i + $m_above);
        my $w_i   = 0 * $v->[0];
        for (my $j=$j_min;$j<=$j_max;$j++) {
            my $j_eff = $j + $m_below - $i;
            $w_i += $row->[$j_eff] * $v->[$j];
        }
        $w->[$i] = $w_i;
    }

    return $w;
}


sub multiply_matrix {
    my ($self, $B) = @_;
    my $N          = $self->N;
    my $m_below_A  = $self->m_below;
    my $m_above_A  = $self->m_above;
    my $data_A     = $self->_data;
    my $m_below_B  = $B->m_below;
    my $m_above_B  = $B->m_above;
    my $data_B     = $B->_data;

    die "Size mismatch" if ($B->N != $N);

    my $m_below = $m_below_A + $m_below_B;
    my $m_above = $m_above_A + $m_above_B;
    my $C       = Math::Matrix::Banded::Square->new(
        N       => $N,
        m_below => $m_below,
        m_above => $m_above,
    );

    for (my $i=0;$i<$N;$i++) {
        my $row_A = $data_A->[$i];
        my $j_min = max(0, $i - $m_below);
        my $j_max = min($N - 1, $i + $m_above);
        for (my $j=$j_min;$j<=$j_max;$j++) {
            my $j_min_A = max(0, $i - $m_below_A);
            my $j_max_A = min($N - 1, $i + $m_above_A);
            my $c_ij = 0;
            for (my $k=$j_min_A;$k<=$j_max_A;$k++) {
                my $row_B = $data_B->[$k];
                my $j_A   = $k + $m_below_A - $i;
                my $j_B   = $j + $m_below_B - $k;
                next if ($j_B < 0 or $j_B > $#$row_B);

                $c_ij += $row_A->[$j_A] * $row_B->[$j_B];
            }
            $C->element($i, $j, $c_ij);
        }
    }

    return $C;
}


sub _decompose_LU_without_pivoting {
    my ($self)  = @_;
    my $N       = $self->N;
    my $m_below = $self->m_below;
    my $m_above = $self->m_above;
    my $data    = $self->_data;

    return try {
        my $L = Math::Matrix::Banded::Square->new(
            N       => $N,
            m_below => $m_below,
            m_above => 0,
        );
        my $U = Math::Matrix::Banded::Square->new(
            N       => $N,
            m_below => 0,
            m_above => $m_above,
        );

        my $data_L = $L->_data;
        my $data_U = $U->_data;
        for (my $i=0;$i<$N;$i++) {
            $L->element($i, $i, 1);
        }
        for (my $j=0;$j<$N;$j++) {
            # NR 2.3.12
            my $i_min = max(0, $j - $m_above);
            for (my $i=$i_min;$i<=$j;$i++) {
                my $j_L0   = $j + $m_below;  # this is also j_A
                my $j_U0   = $j;             # m_below is 0 for U
                my $k_min = max(0, $i - $m_below, $j - $m_above);
                my $value = $data->[$i]->[$j_L0-$i];
                for (my $k=$k_min;$k<$i;$k++) {
                    my $k_L0 = $k + $m_below;
                    $value -=
                        $data_L->[$i]->[$k_L0-$i] * $data_U->[$k]->[$j_U0-$k];
                }
                $U->element($i, $j, $value);
            }

            # NR 2.3.13
            my $i_max = min($N - 1, $j + $m_below);
            for (my $i=$j+1;$i<=$i_max;$i++) {
                my $j_L0   = $j + $m_below;  # this is also j_A
                my $j_U0   = $j;             # m_below is 0 for U
                my $k_min = max(0, $i - $m_below, $j - $m_above);
                my $value = $data->[$i]->[$j_L0-$i];
                for (my $k=$k_min;$k<$j;$k++) {
                    my $k_L0 = $k + $m_below;
                    $value -=
                        $data_L->[$i]->[$k_L0-$i] * $data_U->[$k]->[$j_U0-$k];
                }
                $L->element($i, $j, $value / $data_U->[$j]->[0]);
            }
        }

        return [$L, $U, [0..$N-1]];
    }
    catch {
        return [undef, undef, undef];
    };
}

sub decompose_LU {
    my ($self) = @_;

    my $result = $self->_decompose_LU_without_pivoting;
    $self->_set__LU_raw($result);
    return(defined($result->[0]) ? 1 : undef);
}


sub solve_LU {
    my ($self, $b) = @_;
    my $N          = $self->N;
    my $L          = $self->L;
    my $U          = $self->U;

    return undef if (!defined($L));

    my $m_below_L  = $L->m_below;
    my $m_above_L  = $L->m_above;
    my $data_L     = $L->_data;
    my $m_below_U  = $U->m_below;
    my $m_above_U  = $U->m_above;
    my $data_U     = $U->_data;

    # forward
    my $y       = [];
    my $b_start = 0;  # take advantage of leading zeroes in $b
    for (my $i=0;$i<$N;$i++) {
        my $y_i = $b->[$i];
        if ($b_start > 0) {
            my $j_min = max(0, $i - $m_below_L, $b_start - 1);
            for (my $j=$j_min;$j<$i;$j++) {
                my $j_L = $j + $m_below_L - $i;
                $y_i -= $data_L->[$i]->[$j_L] * $y->[$j];
            }
        }
        elsif ($y_i != 0) {
            $b_start = $i + 1;
        }
        $y->[$i] = $y_i;
    }

    # backward
    my $x = [];
    for (my $i=$N-1;$i>=0;$i--) {
        my $x_i   = $y->[$i];
        my $j_max = min($N - 1, $i + $m_above_U);
        for (my $j=$i+1;$j<=$j_max;$j++) {
            my $j_U = $j - $i;
            $x_i -= $data_U->[$i]->[$j_U] * $x->[$j];
        }
        $x->[$i] = $x_i / $data_U->[$i]->[0];
    }

    return $x;
}


1;

__END__

=pod

=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-matrix-banded at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Matrix-Banded>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Lutz Gehlen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
