package Finance::Quote::Sberbank;

use 5.008008;
use strict;
use warnings;
use encoding 'utf8';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.04';

our $SBERBANK_URL = "http://sbrf.ru/ru/valkprev/archive_1/";

use LWP::UserAgent;
use HTTP::Request::Common;
use Spreadsheet::ParseExcel;

sub methods { return ( sberbank => \&sberbank ); }

{
    my @labels = qw/name last bid ask date isodate currency/;

    sub labels { return ( sberbank => \@labels ); }
}

sub sberbank {
    my $quoter = shift;
    my @stocks = @_;
    my %info;
    my $ua       = $quoter->user_agent;
    my $url      = "http://sbrf.ru/ru/valkprev/archive_1/";
    my $response = $ua->request( GET $url);

    unless ( $response->is_success ) {
        foreach my $stock (@stocks) {
            $info{ $stock, "success" }  = 0;
            $info{ $stock, "errormsg" } = "HTTP failure";
        }
        return wantarray() ? %info : \%info;
    }
    my $link    = "";
    my $content = $response->content;
    $link = $1
      if $content =~
/<li class="xls"><a href="(.*\/(\d{4})\/(\d{2})\/dm(\d{2})(\d{2})(?:\_\d+)?\.xls)"[^\(]*\(.+(\d{2}).+(\d{2})/g;
    if ($link) {
        $link = "http://sbrf.ru" . $link if ( $link =~ /^\// );
        $response = $ua->request( GET $link);
        unless ( $response->is_success ) {
            foreach my $stock (@stocks) {
                $info{ $stock, "success" }  = 0;
                $info{ $stock, "errormsg" } = "HTTP failure";
            }
            return wantarray() ? %info : \%info;
        }
        $content = $response->content;
        my $xls   = Spreadsheet::ParseExcel::Workbook->Parse( \$content );
        my $sheet = $xls->{Worksheet}[0];

        my ( $row_min, $row_max ) = $sheet->row_range();
        my ( $col_min, $col_max ) = $sheet->col_range();
        my $start    = $row_min;
        my $startcol = $col_min;
        while ($start < $row_max
            && $startcol < $col_max
            && !$sheet->get_cell( $start, $startcol ) )
        {
            $startcol++;
            $start++, $startcol = $col_min
              if $startcol == $col_max;
        }
        while ( $sheet->get_cell( $start, $startcol )->Value !~
/\d+\. Котировки продажи и покупки драгоценных металлов в обезличенном виде/
            && $start < $row_max )
        {
            $start++;
        }
        if ( $start != $row_max ) {
            my %map = (
                'Золото'     => 'SBRF.AU',
                'Палладий' => 'SBRF.PD',
                'Серебро'   => 'SBRF.AG',
                'Платина'   => 'SBRF.PT',
            );
            while ( $sheet->get_cell( $start, $startcol ) && $start < $row_max )
            {
                $start++;
                my $name = $sheet->get_cell( $start, $startcol );
                if ($name) {
                    my $stock = $map{ $name->Value };
                    next unless ($stock);
                    $info{ $stock, "symbol" }   = $stock;
                    $info{ $stock, "name" }     = $name;
                    $info{ $stock, "currency" } = "RUB";
                    $info{ $stock, "method" }   = "sberbank";
                    $info{ $stock, "bid" } =
                      $sheet->get_cell( $start, $startcol + 4 )->{Val};
                    $info{ $stock, "ask" } =
                      $sheet->get_cell( $start, $startcol + 2 )->{Val};
                    $info{ $stock, "last" } = $info{ $stock, "bid" };
                    $quoter->store_date( \%info, $stock, { today => 1 } );
                    $info{ $stock, "success" } = 1;
                }
            }
        }
        return wantarray() ? %info : \%info;
    }
}

1;
__END__

=head1 NAME

Finance::Quote::Sberbank - Obtain quotes from Sberbank (Savings Bank of
 the Russian Federation)

=head1 SYNOPSIS

	use Finance::Quote;

	my $quoter = Finance::Quote->new("Sberbank");
	my %info = $quoter->fetch("sberbank", "SBRF.PD"); # Palladium
	print "$info{'SBRF.PD','date'} $info{'SBRF.PD','last'}\n";

=head1 DESCRIPTION

This module fetches metal quotes information from the Sberbank (Savings
 Bank of the Russian Federation) http://sbrf.ru. It fetches quotes for 
 next metals: Gold (SBRF.AU), Silver (SBRF.AG), Platinum (SBRF.PT),
 Palladium (SBRF.PD).

It's not loaded as default Finance::Quote module, so you need create it
 by Finance::Quote->new("Sberbank"). If you want it to load by default,
 make changes to Finance::Quote default module loader, or use 
 FQ_LOAD_QUOTELET environment variable. Gnucash example:
	FQ_LOAD_QUOTELET="-defaults Sberbank" gnucash

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::Sberbank :

name last bid ask date isodate currency
 
=head1 SEE ALSO

Sberbank (Savings Bank of the Russian Federation), http://sbrf.ru .

=head1 AUTHOR

Alexander Korolyoff, E<lt>kilork@yandex.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alexander Korolyoff. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
