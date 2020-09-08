package Math::Matrix::Banded::Rectangular;
use 5.014;

=pod

=head1 NAME

Math::Matrix::Banded::Rectangular - banded non-square matrix

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.004';

use Moo;
use Try::Tiny;


=pod

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Math::Matrix::Banded::Rectangular;

    my $foo = Math::Matrix::Banded::Rectangular->new();
    ...

=head1 DESCRIPTION


=head1 ATTRIBUTES

=head3 data

=cut

has 'M' => (
    is       => 'ro',
    required => 1,
);

has 'N' => (
    is       => 'ro',
    required => 1,
);

has '_data' => (
    is      => 'lazy',
    builder => sub {
        my ($self)  = @_;
        my $M       = $self->M;
        my $data    = [];

        for (my $i=0;$i<$M;$i++) {
            push(@$data, [undef, []]);
        }

        return $data;
    },
);

=pod

=head1 METHODS

=cut

sub element {
    my ($self, $i, $j, @args) = @_;
    my $data                  = $self->_data;

    my ($offset, $row_data) = @{$data->[$i]};
    my $j_eff_max           = $#$row_data;
    my $j_eff               = defined($offset) ? $j - $offset : undef;
    if (@args > 0) {
        if (!defined($j_eff)) {
            $offset = $self->_adjust_offset($i, $j);
            $j_eff  = 0;
        }
        elsif ($j_eff < 0) {
            $offset = $self->_adjust_offset($i, $offset + $j_eff);
            $j_eff  = 0;
        }
        elsif ($j_eff > $j_eff_max) {
            $j_eff_max = $self->_adjust_range($i, $j_eff);
        }
        $row_data->[$j_eff] = $args[0];
    }

    if (($j_eff // -1) < 0 or $j_eff > $j_eff_max) { return 0 }
    else { return($row_data->[$j_eff] // 0) }
}


sub _set_offset {
    my ($self, $i, $new_offset) = @_;
    my $data                    = $self->_data;
    my ($offset, $row_data)     = @{$data->[$i]};

    # should not happen
    return if (defined($offset) and $offset <= $new_offset);

    if (@$row_data) {
        # this implies that $offset is set
        my $k      = $offset - $new_offset;
        my @zeroes = map { 0 } (1..$k);
        unshift(@$row_data, @zeroes);
    }
    $data->[$i]->[0] = $new_offset;
}


sub _set_range {
    my ($self, $i, $new_range) = @_;
    my $data                   = $self->_data;
    my ($offset, $row_data)    = @{$data->[$i]};

    # should not happen
    return if (!defined($offset) or $#$row_data >= $new_range);

    my $k      = $new_range - $#$row_data;
    my @zeroes = map { 0 } (1..$k);
    push(@$row_data, @zeroes);
}


sub _maintain_band_structure {
    my ($self, $i) = @_;
    my $M          = $self->M;
    my $data       = $self->_data;

    # should not happen
    return if (!defined($data->[$i]->[0]));

    my $k = $i;
    while ($k > 0) {
        my $max_offset = $data->[$k]->[0];
        my $cur_offset = $data->[$k-1]->[0];
        if (!defined($cur_offset) or $cur_offset > $max_offset) {
            $self->_set_offset($k - 1, $max_offset);
            $k--;
        }
        else { last }
    }

    while ($k < $M) {
        my $last_row = $k > 0 ? $data->[$k-1] : [0, []];
        my $this_row = $data->[$k];
        last if (!defined($this_row->[0]));

        my $min_range =
            $#{$last_row->[1]} - ($this_row->[0] - $last_row->[0]);
        my $cur_range = $#{$this_row->[1]};
        if ($cur_range < $min_range) {
            $self->_set_range($k, $min_range);
        }
        $k++;
    }
}


sub _adjust_offset {
    my ($self, $i, $new_offset) = @_;
    my $data                    = $self->_data;
    my ($offset, $row_data)     = @{$data->[$i]};

    # offset small enough; nothing to do here nor in rows above
    if (defined($offset) and $offset <= $new_offset) {
        return $offset;
    }

    $self->_set_offset($i, $new_offset);
    $self->_maintain_band_structure($i);

    return $new_offset;
}


sub _adjust_range {
    my ($self, $i, $new_range) = @_;
    my $data                   = $self->_data;
    my ($offset, $row_data)    = @{$data->[$i]};

    return undef       if (!defined($offset));
    return $#$row_data if ($#$row_data >= $new_range);

    $self->_set_range($i, $new_range);
    $self->_maintain_band_structure($i);

    return $new_range;
}


sub row {
    my ($self, $i) = @_;
    my $N          = $self->N;
    my $data       = $self->_data;

    my ($offset, $row_data) = @{$data->[$i]};
    my $j_eff_max           = $#$row_data;
    my $row                 = [];
    for (my $j=0;$j<$N;$j++) {
        my $j_eff = defined($offset) ? $j - $offset : undef;
        push(
            @$row,
            (($j_eff // -1) < 0 || $j_eff > $j_eff_max)
                ? 0 : $row_data->[$j_eff],
        );
    }

    return $row;
}


sub column {
    my ($self, $j) = @_;
    my $M          = $self->M;
    my $N          = $self->N;
    my $data       = $self->_data;

    my $col = [];
    for (my $i=0;$i<$M;$i++) {
        my ($offset, $row_data) = @{$data->[$i]};
        my $j_eff               = defined($offset) ? $j - $offset : undef;
        my $j_eff_max           = $#$row_data;
        push(
            @$col,
            (($j_eff // -1) < 0 || $j_eff > $j_eff_max)
                ? 0 : $row_data->[$j_eff],
        );
    }

    return $col;
}


sub as_string {
    my ($self) = @_;
    my $M      = $self->M;

    return join(
        qq{\n},
        map { join(' ', map { sprintf(q{%7.3f}, $_) } @$_) }
        map { $self->row($_) }
        (0..$M-1),
    );
}


sub transpose {
    my ($self) = @_;
    my $M      = $self->M;
    my $N      = $self->N;
    my $data   = $self->_data;

    my $t = Math::Matrix::Banded::Rectangular->new(
        M => $N,
        N => $M,
    );
    for (my $i=0;$i<$M;$i++) {
        my ($offset, $row_data) = @{$data->[$i]};
        for (my $j_eff=0;$j_eff<@$row_data;$j_eff++) {
            my $j = $offset + $j_eff;
            $t->element($j, $i, $row_data->[$j_eff]);
        }
    }

    return $t;
}


sub multiply_vector {
    my ($self, $v) = @_;
    my $M          = $self->M;
    my $N          = $self->N;
    my $data       = $self->_data;

    my $w = [];
    for (my $i=0;$i<$M;$i++) {
        my ($offset, $row_data) = @{$data->[$i]};
        if (!defined($offset)) {
            $w->[$i] = 0 * $v->[0];
            next;
        }

        my $j_min = $offset;
        my $j_max = $offset + $#$row_data;
        my $w_i   = 0 * $v->[0];
        for (my $j=$j_min;$j<=$j_max;$j++) {
            my $j_eff = $j - $offset;
            $w_i += $row_data->[$j_eff] * $v->[$j];
        }
        $w->[$i] = $w_i;
    }

    return $w;
}


sub AAt {
    my ($self) = @_;
    my $M      = $self->M;
    my $N      = $self->N;
    my $data   = $self->_data;

    my $C = Math::Matrix::Banded::Square->new(
        N         => $M,
        symmetric => 1,
    );
    for (my $i=0;$i<$M;$i++) {
        my ($offset_i, $row_data_i) = @{$data->[$i]};
        last if (!defined($offset_i));

        my $k_max_i = $offset_i + $#$row_data_i;
        for (my $j=$i;$j<$M;$j++) {
            # We multiply the ith row of A with jth column of At,
            # which is the jth row of A.
            my ($offset_j, $row_data_j) = @{$data->[$j]};
            last if (!defined($offset_j));

            my $k_min_j = $offset_j;
            last if ($k_min_j > $k_max_i);

            my $c_ij = 0;
            for (my $k=$k_min_j;$k<=$k_max_i;$k++) {
                my $k_eff_i = $k - $offset_i;
                my $k_eff_j = $k - $offset_j;
                $c_ij +=
                    $row_data_i->[$k_eff_i] * $row_data_j->[$k_eff_j];
            }
            $C->element($i, $j, $c_ij);
        }
    }

    return $C;
}


sub AtA {
    my ($self) = @_;

    return $self->transpose->AAt;
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
