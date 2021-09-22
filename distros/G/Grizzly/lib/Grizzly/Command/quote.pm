package Grizzly::Command::quote;

# ABSTRACT: Gets a stock quote for the given symbol

use Grizzly -command;
use strict;
use warnings;

use Finance::Quote;
use Grizzly::Progress::Bar;
use Term::ANSIColor;

my $q = Finance::Quote->new("YahooJSON");

sub abstract { "display stock quote" }

sub description { "Display the stock quote information." }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Need a symbol args") unless @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    quote_info(@$args);
}

sub quote_info {
    my ($symbol) = @_;

    my %quote = $q->yahoo_json($symbol);

    Grizzly::Progress::Bar->progressbar();

    my $name       = $quote{ $symbol, "name" };
    my $date       = $quote{ $symbol, "date" };
    my $last_price = $quote{ $symbol, "last" };
    my $open       = $quote{ $symbol, "open" };
    my $high       = $quote{ $symbol, "high" };
    my $low        = $quote{ $symbol, "low" };
    my $close      = $quote{ $symbol, "close" };
    my $div_yield  = $quote{ $symbol, "div_yield" };
    my $pe         = $quote{ $symbol, "pe" };
    my $eps        = $quote{ $symbol, "eps" };

    unless ($name) {
        $name = $symbol;
    }
    unless ($date) {
        $date = 'n/a';
    }
    unless ($last_price) {
        $last_price = 'n/a';
    }
    unless ($open) {
        $open = 'n/a';
    }
    unless ($high) {
        $high = 'n/a';
    }
    unless ($low) {
        $low = 'n/a';
    }
    unless ($close) {
        $close = 'n/a';
    }
    unless ($div_yield) {
        $div_yield = 'n/a';
    }
    unless ($pe) {
        $pe = 'n/a';
    }
    unless ($eps) {
        $eps = 'n/a';
    }

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

Grizzly::Command::quote - Gets a stock quote for the given symbol

=head1 VERSION

version 0.103

=head1 SYNOPSIS

    grizzly quote [stock symbol]

=head1 DESCRIPTION

Grizzly will output the stock quote of the inputted tickers symbol.

=head1 NAME

Grizzly::Command::quote

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Nobunaga.

MIT License

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
