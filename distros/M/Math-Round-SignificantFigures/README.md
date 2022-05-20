# NAME

Math::Round::SignificantFigures - Perl package for rounding numbers to a specified number of Significant Figures

# SYNOPSIS

    use Math::Round::SignificantFigures qw{roundsigfigs};
    print roundsigfigs(555.555, 3), "\n";

# DESCRIPTION

Math::Round::SignificantFigures supplies functions that will round numbers based on significant figures. 

This package spans the controversy whether people prefer to call significant figures or significant digits.  You may export either or both but, I called the package significant figures since that is the page for Wikipedia.

# FUNCTIONS

The exporter group :figs exports the roundsigfigs, ceilsigfigs, floorsigfigs functions. The exporter group :digs exports the roundsigdigs, ceilsigdigs, floorsigdigs functions.  The exporter group :all exports all six functions

## roundsigfigs, roundsigdigs

Rounds a number given the number and a number of significant figures.

## floorsigfigs, floorsigdigs

Rounds a number toward -inf given the number and a number of significant figures.

## ceilsigfigs, ceilsigdigs

Rounds a number toward +inf given the number and a number of significant figures.

# SEE ALSO

[Math::Round](https://metacpan.org/pod/Math::Round) supplies functions that will round numbers in different ways.

[Math::SigDig](https://metacpan.org/pod/Math::SigDig) allows you to edit numbers to a significant number of digits.

[https://en.wikipedia.org/wiki/Significant\_figures#Rounding\_to\_significant\_figures](https://en.wikipedia.org/wiki/Significant_figures#Rounding_to_significant_figures)

[https://stackoverflow.com/questions/202302/rounding-to-an-arbitrary-number-of-significant-digits](https://stackoverflow.com/questions/202302/rounding-to-an-arbitrary-number-of-significant-digits)

# AUTHOR

Michael R. Davis, MRDVT

# COPYRIGHT AND LICENSE

MIT LICENSE

Copyright (C) 2022 by Michael R. Davis
