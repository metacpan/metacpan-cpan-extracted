package Gnuplot::Builder::Util;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(quote_gnuplot_str);

sub quote_gnuplot_str {
    my ($str) = @_;
    return undef if !defined($str);
    $str = "$str";  ## explicit stringification
    $str =~ s/'/''/g;
    return qq{'$str'};
}

1;
