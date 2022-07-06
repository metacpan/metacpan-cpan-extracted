package Grizzly::Data::Finance;

# ABSTRACT: Displays Finance::Quote data

use v5.36;
use feature qw(multidimensional);
use parent  qw(Exporter);

use Grizzly::Progress::Bar;
use Grizzly::Data::StockInfo;
use Term::ANSIColor;

require Exporter;
our @ISA         = ("Exporter");
our @EXPORT_OK   = qw(quote_info);
our %EXPORT_TAGS = ( all => [qw(quote_info)], );

sub quote_info {
    my ($symbol) = @_;

    my %quote = stock_info($symbol);

    progressbar();

    my $name       = $quote{ $symbol, "name" }      || 'n/a';
    my $date       = $quote{ $symbol, "date" }      || 'n/a';
    my $last_price = $quote{ $symbol, "last" }      || 'n/a';
    my $open       = $quote{ $symbol, "open" }      || 'n/a';
    my $high       = $quote{ $symbol, "high" }      || 'n/a';
    my $low        = $quote{ $symbol, "low" }       || 'n/a';
    my $close      = $quote{ $symbol, "close" }     || 'n/a';
    my $div_yield  = $quote{ $symbol, "div_yield" } || 'n/a';
    my $pe         = $quote{ $symbol, "pe" }        || 'n/a';
    my $eps        = $quote{ $symbol, "eps" }       || 'n/a';

    my $title = colored( "Grizzly - Stock Quote Analysis", "blue" );

    print <<EOF,;

$title

Company: ========== $name
Date: ============= $date
Latest Price: ===== $last_price
Open: ============= $open
High: ============= $high
Low: ============== $low
Previous Close: === $close
Dividend Yield: === $div_yield
P/E Ratio: ======== $pe
EPS: ============== $eps

EOF
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Grizzly::Data::Finance - Displays Finance::Quote data

=head1 VERSION

version 0.111

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
