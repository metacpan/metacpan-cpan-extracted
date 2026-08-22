package Math::Histo::PDL;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.2.0';

use Math::Histo 0.1.1;
use Math::Histo::2D;
use PDL 2.000 ();
use Carp qw(croak);
use Exporter 'import';

our @EXPORT_OK = qw(
    hist1d
    hist2d
    fill_pdl
    fill2d_pdl
    to_pdl
    to_pdl2d
    pdl_to_histo
    histo_to_pdl
    counts_pdl
    edges_pdl
    centers_pdl
    errors_pdl
    matrix_pdl
    x_edges_pdl
    y_edges_pdl
    x_centers_pdl
    y_centers_pdl
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

# Internal helper: extract packed byte buffer from a PDL object for zero-copy ingestion
sub _ensure_packed_double {
    my ($pdl) = @_;
    if (!eval { $pdl->isa('PDL') }) {
        if (ref($pdl) eq 'ARRAY') {
            $pdl = PDL::pdl(PDL::double(), $pdl);
        } else {
            croak "Math::Histo::PDL: input must be a PDL piddle or arrayref";
        }
    }
    return ('', 0) if $pdl->isempty || $pdl->nelem == 0;

    my $d = ($pdl->type eq 'double') ? $pdl : $pdl->double;
    $d = $d->flat unless $d->ndims == 1;
    $d = $d->make_physical;
    my $dataref = $d->get_dataref;
    return ($$dataref, $d->nelem);
}

# 1D Ingestion
sub fill_pdl {
    my ($self, $data, $weights) = @_;
    croak "Math::Histo::PDL: first argument must be a Math::Histo object"
        unless eval { $self->isa('Math::Histo') };
    croak "Math::Histo::PDL: data piddle is required" unless defined $data;

    my ($x_bytes, $n_x) = _ensure_packed_double($data);
    return $self if $n_x == 0;

    if (defined $weights) {
        my ($w_bytes, $n_w) = _ensure_packed_double($weights);
        if ($n_w != $n_x) {
            croak "Math::Histo::PDL::fill_pdl: weights length ($n_w) must match data length ($n_x)";
        }
        $self->fill_packed_f64($x_bytes, $w_bytes);
    } else {
        $self->fill_packed_f64($x_bytes);
    }
    return $self;
}

# 2D Ingestion
sub fill2d_pdl {
    my ($self, @args) = @_;
    croak "Math::Histo::PDL: first argument must be a Math::Histo::2D object"
        unless eval { $self->isa('Math::Histo::2D') };

    my ($x_pdl, $y_pdl, $weights);

    if (@args == 1 || (@args == 2 && eval { $args[0]->isa('PDL') } && $args[0]->ndims == 2)) {
        # Single 2D coordinate matrix: (2, N) or (N, 2), plus optional weights
        my $coords = $args[0];
        $weights = $args[1] if @args == 2;

        if ($coords->dim(0) == 2) {
            $x_pdl = $coords->slice('(0),:')->flat;
            $y_pdl = $coords->slice('(1),:')->flat;
        } elsif ($coords->dim(1) == 2) {
            $x_pdl = $coords->slice(',(0)')->flat;
            $y_pdl = $coords->slice(',(1)')->flat;
        } else {
            croak "Math::Histo::PDL::fill2d_pdl: coordinate matrix must have dimension 2 along axis 0 or 1 (got " . join('x', $coords->dims) . ")";
        }
    } elsif (@args == 2 || @args == 3) {
        ($x_pdl, $y_pdl, $weights) = @args;
    } else {
        croak "Math::Histo::PDL::fill2d_pdl: invalid arguments (expected (\$h2d, \$x, \$y, [\$weights]) or (\$h2d, \$coords, [\$weights]))";
    }

    my ($x_bytes, $n_x) = _ensure_packed_double($x_pdl);
    my ($y_bytes, $n_y) = _ensure_packed_double($y_pdl);

    if ($n_x != $n_y) {
        croak "Math::Histo::PDL::fill2d_pdl: X length ($n_x) and Y length ($n_y) must match";
    }
    return $self if $n_x == 0;

    if (defined $weights) {
        my ($w_bytes, $n_w) = _ensure_packed_double($weights);
        if ($n_w != $n_x) {
            croak "Math::Histo::PDL::fill2d_pdl: weights length ($n_w) must match data length ($n_x)";
        }
        $self->fill_packed_f64($x_bytes, $y_bytes, $w_bytes);
    } else {
        $self->fill_packed_f64($x_bytes, $y_bytes);
    }
    return $self;
}

# 1D Export to PDL
sub counts_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo object"
        unless eval { $self->isa('Math::Histo') };
    my $contents = $self->bin_contents;
    my $packed = pack('d*', @$contents);
    my $p = PDL->new_from_specification(PDL::double(), scalar(@$contents));
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub edges_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo object"
        unless eval { $self->isa('Math::Histo') };
    my $edges = $self->bin_edges;
    my $packed = pack('d*', @$edges);
    my $p = PDL->new_from_specification(PDL::double(), scalar(@$edges));
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub centers_pdl {
    my ($self) = @_;
    my $edges = edges_pdl($self);
    return ($edges->slice('0:-2') + $edges->slice('1:-1')) / 2.0;
}

sub errors_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo object"
        unless eval { $self->isa('Math::Histo') };
    my $n = $self->nbins;
    my @errors = map { $self->bin_error($_) // 0.0 } 0 .. $n - 1;
    my $packed = pack('d*', @errors);
    my $p = PDL->new_from_specification(PDL::double(), $n);
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub to_pdl {
    my ($self, %opts) = @_;
    if (wantarray && !%opts) {
        return (counts_pdl($self), edges_pdl($self), errors_pdl($self));
    }
    if ($opts{all}) {
        return {
            counts  => counts_pdl($self),
            edges   => edges_pdl($self),
            centers => centers_pdl($self),
            errors  => errors_pdl($self),
        };
    }
    return counts_pdl($self);
}

# 2D Export to PDL
sub matrix_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo::2D object"
        unless eval { $self->isa('Math::Histo::2D') };
    my $nx = $self->nx;
    my $ny = $self->ny;
    my $packed = '';
    for my $iy (0 .. $ny - 1) {
        for my $ix (0 .. $nx - 1) {
            $packed .= pack('d', $self->bin_content($ix, $iy));
        }
    }
    my $p = PDL->new_from_specification(PDL::double(), $nx, $ny);
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub x_edges_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo::2D object"
        unless eval { $self->isa('Math::Histo::2D') };
    my $nx = $self->nx;
    my @edges;
    for my $ix (0 .. $nx - 1) {
        my ($x0, $x1) = $self->bin_bounds($ix, 0);
        push @edges, $x0;
        push @edges, $x1 if $ix == $nx - 1;
    }
    my $packed = pack('d*', @edges);
    my $p = PDL->new_from_specification(PDL::double(), scalar(@edges));
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub y_edges_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo::2D object"
        unless eval { $self->isa('Math::Histo::2D') };
    my $ny = $self->ny;
    my @edges;
    for my $iy (0 .. $ny - 1) {
        my (undef, undef, $y0, $y1) = $self->bin_bounds(0, $iy);
        push @edges, $y0;
        push @edges, $y1 if $iy == $ny - 1;
    }
    my $packed = pack('d*', @edges);
    my $p = PDL->new_from_specification(PDL::double(), scalar(@edges));
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub x_centers_pdl {
    my ($self) = @_;
    my $edges = x_edges_pdl($self);
    return ($edges->slice('0:-2') + $edges->slice('1:-1')) / 2.0;
}

sub y_centers_pdl {
    my ($self) = @_;
    my $edges = y_edges_pdl($self);
    return ($edges->slice('0:-2') + $edges->slice('1:-1')) / 2.0;
}

sub errors2d_pdl {
    my ($self) = @_;
    croak "Math::Histo::PDL: argument must be a Math::Histo::2D object"
        unless eval { $self->isa('Math::Histo::2D') };
    my $nx = $self->nx;
    my $ny = $self->ny;
    my $packed = '';
    for my $iy (0 .. $ny - 1) {
        for my $ix (0 .. $nx - 1) {
            $packed .= pack('d', $self->bin_error($ix, $iy) // 0.0);
        }
    }
    my $p = PDL->new_from_specification(PDL::double(), $nx, $ny);
    ${$p->get_dataref} = $packed;
    $p->upd_data;
    return $p;
}

sub to_pdl2d {
    my ($self, %opts) = @_;
    if (wantarray && !%opts) {
        return (matrix_pdl($self), x_edges_pdl($self), y_edges_pdl($self));
    }
    if ($opts{all}) {
        return {
            matrix    => matrix_pdl($self),
            x_edges   => x_edges_pdl($self),
            y_edges   => y_edges_pdl($self),
            x_centers => x_centers_pdl($self),
            y_centers => y_centers_pdl($self),
            errors    => errors2d_pdl($self),
        };
    }
    return matrix_pdl($self);
}

# High-level functional builders
sub hist1d {
    my ($data, %opts) = @_;
    my $pdl = eval { $data->isa('PDL') } ? $data : PDL::pdl($data);
    my $weights = delete $opts{weights};

    my $h;
    if (exists $opts{edges}) {
        my $edges = $opts{edges};
        my @edges_arr = eval { $edges->isa('PDL') } ? $edges->list : @$edges;
        delete $opts{edges};
        $h = Math::Histo->new(edges => \@edges_arr, %opts);
    } elsif (exists $opts{rule} || exists $opts{auto}) {
        my $rule = delete $opts{rule} // delete $opts{auto};
        my @samples = $pdl->list;
        my ($nbins, $min, $max) = Math::Histo->estimate_bins(\@samples, $rule);
        if ($min == $max) {
            $min -= 0.5;
            $max += 0.5;
        } else {
            my $margin = ($max - $min) * 1e-6;
            $max += ($margin > 0 ? $margin : 1e-6);
        }
        $h = Math::Histo->new(bins => $nbins, min => $min, max => $max, %opts);
    } else {
        my $nbins = delete $opts{bins} // delete $opts{nbins} // 50;
        my $min = delete $opts{min};
        my $max = delete $opts{max};

        if (!defined $min || !defined $max) {
            if ($pdl->nelem > 0) {
                my ($pmin, $pmax) = $pdl->minmax;
                $min //= $pmin;
                if (!defined $max) {
                    if ($pmin == $pmax) {
                        $min -= 0.5;
                        $max = $pmax + 0.5;
                    } else {
                        my $margin = ($pmax - $pmin) * 1e-6;
                        $max = $pmax + ($margin > 0 ? $margin : 1e-6);
                    }
                }
            } else {
                $min //= 0.0;
                $max //= 1.0;
            }
        }
        $h = Math::Histo->new(bins => $nbins, min => $min, max => $max, %opts);
    }

    fill_pdl($h, $pdl, $weights) if $pdl->nelem > 0;
    return $h;
}

sub hist2d {
    my (@args) = @_;
    my ($x, $y, $coords, %opts);

    if (@args >= 1 && eval { $args[0]->isa('PDL') } && $args[0]->ndims == 2) {
        $coords = shift @args;
        %opts = @args;
        if ($coords->dim(0) == 2) {
            $x = $coords->slice('(0),:')->flat;
            $y = $coords->slice('(1),:')->flat;
        } elsif ($coords->dim(1) == 2) {
            $x = $coords->slice(',(0)')->flat;
            $y = $coords->slice(',(1)')->flat;
        } else {
            croak "Math::Histo::PDL::hist2d: coordinate matrix must have 2 columns or 2 rows (got " . join('x', $coords->dims) . ")";
        }
    } else {
        $x = shift @args;
        $y = shift @args;
        %opts = @args;
        $x = PDL::pdl($x) unless eval { $x->isa('PDL') };
        $y = PDL::pdl($y) unless eval { $y->isa('PDL') };
    }

    my $weights = delete $opts{weights};
    my $h2d;

    if (exists $opts{xedges} && exists $opts{yedges}) {
        my $xe = delete $opts{xedges};
        my $ye = delete $opts{yedges};
        my @x_arr = eval { $xe->isa('PDL') } ? $xe->list : @$xe;
        my @y_arr = eval { $ye->isa('PDL') } ? $ye->list : @$ye;
        $h2d = Math::Histo::2D->new(xedges => \@x_arr, yedges => \@y_arr, %opts);
    } else {
        my ($xbins, $ybins);
        if (exists $opts{bins}) {
            my $b = delete $opts{bins};
            if (ref($b) eq 'ARRAY') {
                ($xbins, $ybins) = @$b;
            } else {
                $xbins = $ybins = $b;
            }
        }
        $xbins //= delete $opts{xbins} // 50;
        $ybins //= delete $opts{ybins} // 50;

        my $xmin = delete $opts{xmin};
        my $xmax = delete $opts{xmax};
        my $ymin = delete $opts{ymin};
        my $ymax = delete $opts{ymax};

        if (!defined $xmin || !defined $xmax) {
            if ($x->nelem > 0) {
                my ($min, $max) = $x->minmax;
                $xmin //= $min;
                if (!defined $xmax) {
                    if ($min == $max) {
                        $xmin -= 0.5;
                        $xmax = $max + 0.5;
                    } else {
                        my $margin = ($max - $min) * 1e-6;
                        $xmax = $max + ($margin > 0 ? $margin : 1e-6);
                    }
                }
            } else {
                $xmin //= 0.0;
                $xmax //= 1.0;
            }
        }

        if (!defined $ymin || !defined $ymax) {
            if ($y->nelem > 0) {
                my ($min, $max) = $y->minmax;
                $ymin //= $min;
                if (!defined $ymax) {
                    if ($min == $max) {
                        $ymin -= 0.5;
                        $ymax = $max + 0.5;
                    } else {
                        my $margin = ($max - $min) * 1e-6;
                        $ymax = $max + ($margin > 0 ? $margin : 1e-6);
                    }
                }
            } else {
                $ymin //= 0.0;
                $ymax //= 1.0;
            }
        }

        $h2d = Math::Histo::2D->new(
            xbins => $xbins, xmin => $xmin, xmax => $xmax,
            ybins => $ybins, ymin => $ymin, ymax => $ymax,
            %opts
        );
    }

    if ($x->nelem > 0) {
        fill2d_pdl($h2d, $x, $y, $weights);
    }
    return $h2d;
}

sub pdl_to_histo {
    my ($pdl, %opts) = @_;
    if (eval { $pdl->isa('PDL') } && $pdl->ndims == 2 && ($pdl->dim(0) == 2 || $pdl->dim(1) == 2)) {
        return hist2d($pdl, %opts);
    }
    return hist1d($pdl, %opts);
}

sub histo_to_pdl {
    my ($h, %opts) = @_;
    if (eval { $h->isa('Math::Histo::2D') }) {
        return to_pdl2d($h, %opts);
    }
    return to_pdl($h, %opts);
}

# Inject OO extension methods into Math::Histo and Math::Histo::2D upon module load
{
    no warnings 'redefine';
    *Math::Histo::fill_pdl    = \&fill_pdl;
    *Math::Histo::to_pdl      = \&to_pdl;
    *Math::Histo::counts_pdl  = \&counts_pdl;
    *Math::Histo::edges_pdl   = \&edges_pdl;
    *Math::Histo::centers_pdl = \&centers_pdl;
    *Math::Histo::errors_pdl  = \&errors_pdl;

    *Math::Histo::2D::fill_pdl    = \&fill2d_pdl;
    *Math::Histo::2D::to_pdl      = \&to_pdl2d;
    *Math::Histo::2D::matrix_pdl  = \&matrix_pdl;
    *Math::Histo::2D::counts_pdl  = \&matrix_pdl;
    *Math::Histo::2D::x_edges_pdl = \&x_edges_pdl;
    *Math::Histo::2D::y_edges_pdl = \&y_edges_pdl;
    *Math::Histo::2D::x_centers_pdl = \&x_centers_pdl;
    *Math::Histo::2D::y_centers_pdl = \&y_centers_pdl;
    *Math::Histo::2D::errors_pdl  = \&errors2d_pdl;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::PDL - High-performance PDL integration and zero-copy ingestion for Math::Histo

=head1 SYNOPSIS

  use PDL;
  use Math::Histo;
  use Math::Histo::PDL qw(:all);

  # 1D Ingestion from PDL (Zero-Copy)
  my $data = grandom(1_000_000);
  my $h = hist1d($data, bins => 100, min => -5, max => 5);

  # Weighted ingestion
  my $weights = random(1_000_000);
  $h->fill_pdl($data, $weights);

  # Export 1D histogram to PDL piddles
  my ($counts, $edges, $errors) = $h->to_pdl;
  my $centers = $h->centers_pdl;

  # 2D Ingestion from PDL
  my $x = grandom(500_000);
  my $y = grandom(500_000);
  my $h2d = hist2d($x, $y, xbins => 50, ybins => 50);

  # 2D Ingestion from Nx2 or 2xN coordinate matrix
  my $coords = grandom(2, 500_000);
  my $h2d_mat = hist2d($coords, bins => 50);

  # Export 2D histogram to PDL matrix and axis vectors
  my ($matrix, $x_edges, $y_edges) = $h2d->to_pdl;
  my $x_centers = $h2d->x_centers_pdl;
  my $y_centers = $h2d->y_centers_pdl;

=head1 DESCRIPTION

C<Math::Histo::PDL> provides seamless, bidirectional integration between L<PDL> (Perl Data Language)
and L<Math::Histo> / L<Math::Histo::2D>.

It is designed for maximum numerical throughput:

=over 4

=item * B<Zero-Copy Ingestion>: For double-precision contiguous piddles, C<Math::Histo::PDL> leverages
C<$pdl->get_dataref> to pass underlying C buffers directly into C<Math::Histo>'s SIMD-accelerated C core
(C<fill_packed_f64>).

=item * B<Transparent Coercion>: Non-double data types (e.g. C<long>, C<float>) or non-contiguous slices
(e.g. strided or transposed piddles) are automatically and cleanly converted to physical double buffers.

=item * B<Idiomatic OO and Functional APIs>: When loaded, C<Math::Histo::PDL> automatically attaches C<to_pdl>,
C<fill_pdl>, and axis export methods directly onto L<Math::Histo> and L<Math::Histo::2D>, alongside
convenience builder functions (C<hist1d>, C<hist2d>, C<pdl_to_histo>, C<histo_to_pdl>).

=back

=head1 FUNCTIONS

=head2 1D Histogramming

=over 4

=item B<hist1d($data, %opts)>

Creates and fills a L<Math::Histo> 1D histogram from a PDL piddle C<$data>.

Options:

=over 8

=item * C<bins> / C<nbins>: Number of bins (default: 50).

=item * C<min>, C<max>: Range minimum and maximum. Defaults to data min/max if omitted.

=item * C<edges>: Arrayref or 1D piddle of custom variable bin edges.

=item * C<rule> / C<auto>: Automatic bin estimation rule (C<'fd'>, C<'scott'>, C<'sturges'>, C<'doane'>, C<'knuth'>, C<'auto'>).

=item * C<weights>: Optional 1D weights piddle of matching length.

=item * C<sumw2> / C<track_sumw2>: Track sum of squared weights for error propagation.

=back

=item B<fill_pdl($h, $data, [$weights])>

Fills an existing L<Math::Histo> histogram with elements from C<$data> and optional C<$weights>.
Returns C<$h> for method chaining.

=item B<counts_pdl($h)>

Returns a 1D double PDL piddle containing the bin contents (size C<< $h->nbins >>).

=item B<edges_pdl($h)>

Returns a 1D double PDL piddle containing all bin edges (size C<< $h->nbins + 1 >>).

=item B<centers_pdl($h)>

Returns a 1D double PDL piddle containing the bin center coordinates (size C<< $h->nbins >>).

=item B<errors_pdl($h)>

Returns a 1D double PDL piddle containing the statistical uncertainties / standard errors per bin.

=item B<to_pdl($h, %opts)>

In list context: returns C<($counts, $edges, $errors)>.
In scalar context: returns C<$counts>.
If C<< all => 1 >> is passed: returns a hashref containing C<counts>, C<edges>, C<centers>, C<errors>.

=back

=head2 2D Histogramming

=over 4

=item B<hist2d($x, $y, %opts)> or B<hist2d($coords, %opts)>

Creates and fills a L<Math::Histo::2D> histogram from coordinate piddles C<($x, $y)> or a 2D coordinate matrix
C<$coords> (having shape C<(2, N)> or C<(N, 2)>).

Options:

=over 8

=item * C<xbins>, C<ybins> (or C<< bins => [$nx, $ny] >> or C<< bins => $n >>): Bin counts per axis.

=item * C<xmin>, C<xmax>, C<ymin>, C<ymax>: Axis bounds. Defaults to data min/max if omitted.

=item * C<xedges>, C<yedges>: Custom variable bin edges per axis.

=item * C<weights>: Optional weights piddle.

=back

=item B<fill2d_pdl($h2d, $x, $y, [$weights])> or B<fill2d_pdl($h2d, $coords, [$weights])>

Fills an existing 2D histogram from coordinate piddles. Returns C<$h2d>.

=item B<matrix_pdl($h2d)> (alias B<counts_pdl>)

Returns a 2D double PDL matrix of shape C<(nx, ny)> containing the 2D bin contents.

=item B<x_edges_pdl($h2d)> / B<y_edges_pdl($h2d)>

Returns 1D double PDL piddles of X and Y bin edges (sizes C<nx + 1> and C<ny + 1>).

=item B<x_centers_pdl($h2d)> / B<y_centers_pdl($h2d)>

Returns 1D double PDL piddles of X and Y bin centers.

=item B<errors2d_pdl($h2d)>

Returns a 2D double PDL matrix of shape C<(nx, ny)> of bin errors.

=item B<to_pdl2d($h2d, %opts)>

In list context: returns C<($matrix, $x_edges, $y_edges)>.
In scalar context: returns C<$matrix>.
If C<< all => 1 >> is passed: returns a hashref containing C<matrix>, C<x_edges>, C<y_edges>, C<x_centers>, C<y_centers>, C<errors>.

=back

=head1 OBJECT-ORIENTED EXTENSIONS

When C<Math::Histo::PDL> is loaded, the following methods are added:

=head2 Methods on L<Math::Histo>

=over 4

=item * C<< $h->fill_pdl($data, [$weights]) >>

=item * C<< $h->to_pdl(%opts) >>

=item * C<< $h->counts_pdl >>

=item * C<< $h->edges_pdl >>

=item * C<< $h->centers_pdl >>

=item * C<< $h->errors_pdl >>

=back

=head2 Methods on L<Math::Histo::2D>

=over 4

=item * C<< $h2d->fill_pdl($x, $y, [$weights]) >> / C<< $h2d->fill_pdl($coords, [$weights]) >>

=item * C<< $h2d->to_pdl(%opts) >>

=item * C<< $h2d->matrix_pdl >> / C<< $h2d->counts_pdl >>

=item * C<< $h2d->x_edges_pdl >> / C<< $h2d->y_edges_pdl >>

=item * C<< $h2d->x_centers_pdl >> / C<< $h2d->y_centers_pdl >>

=item * C<< $h2d->errors_pdl >>

=back

=head1 PERFORMANCE CONSIDERATIONS

To achieve zero-copy filling into C<libhisto>:

=over 4

=item 1. Ensure your input piddle is of type C<double> (e.g. C<< $pdl->double >> or created as C<< zeros(double, ...) >>).

=item 2. Avoid passing deeply sliced non-physical views directly in hot loops if maximum throughput is required; C<Math::Histo::PDL> will automatically call C<make_physical> when needed.

=back

=head1 SEE ALSO

L<Math::Histo>, L<Math::Histo::2D>, L<PDL>

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself (MIT License).

=cut
