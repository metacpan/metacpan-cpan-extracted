package Grizzly::Data::StockInfo;

# ABSTRACT: Gets and returns stock quote

use v5.36;
use parent qw(Exporter);

use Finance::Quote;

require Exporter;
our @ISA    = ("Exporter");
our @EXPORT = qw(stock_info);

my $q = Finance::Quote->new("YahooJSON");

sub stock_info {
    my ($symbol) = @_;

    return $q->yahoo_json($symbol);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Grizzly::Data::StockInfo - Gets and returns stock quote

=head1 VERSION

version 0.111

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
