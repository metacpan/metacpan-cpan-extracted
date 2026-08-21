# Math::Histo

Fast, memory-safe C histogramming and statistical computing XS library for Perl, wrapping `libhisto`.

## Installation

```bash
cpanm Alien::libhisto
cpanm Math::Histo
```

## Features

- **1D & 2D Histograms**: Uniform and arbitrary variable-width binning.
- **Ingestion Methods**: Scalar, arrayref batch (`fill_n`), and packed binary `double` buffer fills.
- **Analytics**: Mean, variance, skewness, kurtosis, quantiles, mode/FWHM, IQR, MAD, trimmed/winsorized mean.
- **Statistical Testing**: Two-sample $\chi^2$, Kolmogorov-Smirnov, Wasserstein distance, KL divergence, Bhattacharyya distance.
- **Non-Linear Curve Fitting**: Levenberg-Marquardt optimizer for Gaussian, exponential, polynomial, Breit-Wigner, and power-law models.
- **Streaming Quantile Sketches**: DDSketch online dynamic logarithmic binning with relative-error guarantees.
- **Zero-Loss Serialization**: Endian-independent binary wire format and JSON.
