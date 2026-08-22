# Math::Histo::PDL

High-performance PDL (Perl Data Language) integration and zero-copy ingestion for `Math::Histo`.

## Features

- **Zero-Copy Ingestion**: Ingests double-precision contiguous piddles directly using `$pdl->get_dataref` into `Math::Histo` / `Math::Histo::2D`'s SIMD-accelerated C core (`fill_packed_f64`).
- **Encapsulated Coercion**: Handles integer, float, and non-contiguous/transposed slices via safe, clean coercion (`$pdl->double->make_physical`).
- **Full 1D & 2D Support**: Supports 1D vectors, pairs of 1D vectors `($x, $y)`, and 2D coordinate matrices `(2, N)` / `(N, 2)`.
- **Weighted Histogramming**: Ingests unweighted or weighted samples with proper error propagation.
- **Export to PDL**: Converts 1D histograms to counts, bin edges, bin centers, and errors; converts 2D histograms to `(nx, ny)` matrices and coordinate vectors.
- **OO & Functional APIs**: Automatic method injection onto `Math::Histo` and `Math::Histo::2D` (`$h->to_pdl`, `$h->fill_pdl`) plus functional builders (`hist1d`, `hist2d`).

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## Quick Example

```perl
use PDL;
use Math::Histo;
use Math::Histo::PDL qw(:all);

# Create and fill 1D histogram from a piddle
my $data = grandom(1_000_000);
my $h = hist1d($data, bins => 100, min => -5, max => 5);

# Export to PDL
my ($counts, $edges, $errors) = $h->to_pdl;
my $centers = $h->centers_pdl;

# 2D Histogram from coordinate matrix
my $coords = grandom(2, 500_000);
my $h2d = hist2d($coords, bins => 50);
my ($matrix, $x_edges, $y_edges) = $h2d->to_pdl;
```

## License

MIT License. Copyright (c) 2026 Steffen Mueller.
