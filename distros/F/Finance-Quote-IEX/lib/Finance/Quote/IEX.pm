package Finance::Quote::IEX;

# ABSTRACT: (DEPRECATED) Retrieve stock quotes using the IEX API

use strict;
use warnings;
use DateTime;
use JSON qw(decode_json);
use HTTP::Status qw(status_message);

warnings::warnif( 'deprecated',
    'Finance::Quote::IEX is deprecated and should no longer be used' );

our $VERSION = '0.002000'; # VERSION

sub methods {
    return (
        iex    => \&iex,
        usa    => \&iex,
        nasdaq => \&iex,
        nyse   => \&iex,
    );
}

sub labels {
    my @labels = qw/
        name
        last
        date
        isodate
        time
        net
        p_change
        volume
        close
        open
        year_range
        pe
        cap
        exchange
        method
        price
        currency
        /;
    return (
        iex    => \@labels,
        usa    => \@labels,
        nasdaq => \@labels,
        nyse   => \@labels,
    );
}

sub iex {
    my $quoter = shift;
    my @stocks = @_;

    my $iex_url  = 'https://api.iextrading.com/1.0/stock/%s/quote';
    my $errormsg = 'Error retrieving quote for "%s": GET "%s" resulted in'
        . ' HTTP response %d (%s)';

    my $ua = $quoter->user_agent();
    my %info;

    foreach my $symbol (@stocks) {
        my $url = sprintf( $iex_url, $symbol );
        my $response = $ua->get($url);

        if ( !$response->is_success ) {
            my $code = $response->code;
            my $desc = status_message($code);
            $info{ $symbol, 'success' } = 0;
            $info{ $symbol, 'errormsg' }
                = sprintf( $errormsg, $symbol, $url, $code, $desc );
            next;
        }

        my $data = decode_json( $response->decoded_content );

        if ( !defined $data->{latestPrice} ) {
            my $code = $response->code;
            my $desc = status_message($code);
            $info{ $symbol, 'success' }  = 0;
            $info{ $symbol, 'errormsg' } = sprintf(
                'Error retrieving quote for "%s":'
                    . ' no price found in response data',
                $symbol
            );
            next;
        }

        if ( !defined $data->{latestUpdate} ) {
            my $code = $response->code;
            my $desc = status_message($code);
            $info{ $symbol, 'success' }  = 0;
            $info{ $symbol, 'errormsg' } = sprintf(
                'Error retrieving quote for "%s":'
                    . ' no date found in response data',
                $symbol
            );
            next;
        }

        $info{ $symbol, 'success' }  = 1;
        $info{ $symbol, 'method' }   = 'iex';
        $info{ $symbol, 'source' }   = 'Finance::Quote::IEX';
        $info{ $symbol, 'currency' } = 'USD';
        $info{ $symbol, 'symbol' }   = $data->{symbol};
        $info{ $symbol, 'name' }
            = $symbol . ' (' . $data->{companyName} . ')';
        $info{ $symbol, 'last' }     = $data->{latestPrice};
        $info{ $symbol, 'price' }    = $data->{latestPrice};
        $info{ $symbol, 'net' }      = $data->{change};
        $info{ $symbol, 'p_change' } = $data->{changePercent};
        $info{ $symbol, 'volume' }   = $data->{latestVolume};
        $info{ $symbol, 'close' }    = $data->{close};
        $info{ $symbol, 'open' }     = $data->{open};
        $info{ $symbol, 'year_range' }
            = $data->{week52Low} . ' - ' . $data->{week52High};
        $info{ $symbol, 'pe' }       = $data->{peRatio};
        $info{ $symbol, 'cap' }      = $data->{marketCap};
        $info{ $symbol, 'exchange' } = $data->{exchange};

        # The Finance::Quote documentation indicates that the date shouldn't
        # be parsed, but store_date does not support epoch time.
        my $dt
            = DateTime->from_epoch( epoch => $data->{latestUpdate} / 1000 );
        $info{ $symbol, 'time' }    = $dt->hms;
        $info{ $symbol, 'date' }    = $dt->strftime('%m/%d/%y');
        $info{ $symbol, 'isodate' } = $dt->ymd;
    }

    return wantarray() ? %info : \%info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Quote::IEX - (DEPRECATED) Retrieve stock quotes using the IEX API

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

    use Finance::Quote;
    my $q = Finance::Quote->new('IEX');
    my %info = Finance::Quote->fetch( 'iex', 'AAPL' );

=head1 DESCRIPTION

This module fetches information from the IEX API.

This module is not loaded by default on a Finance::Quote object. It
must be loaded explicitly by placing C<'IEX'> in the argument list to
C<< Finance::Quote->new() >>.

This module provides the C<iex> fetch method.

=head1 DEPRECATED

B<This module is deprecated. Use L<Finance::Quote::IEXCloud> instead.>

B<The IEX API removed all non-IEX data in June 2019.>

=head1 ATTRIBUTION

If you redistribute IEX API data:

=over 4

=item *

Cite IEX using the following text and link: "Data provided for free by
L<IEX|https://iextrading.com/developer>."

=item *

Provide a link to L<https://iextrading.com/api-exhibit-a> in your terms of
service.

=back

Additionally, if you display our TOPS price data, cite
"L<IEX Real-Time Price|https://iextrading.com/developer>" near the price.

=head1 LABELS RETURNED

The following labels may be returned by C<Finance::Quote::IEX>: name, last, date,
time, net, p_change, volume, close, open, year_range, pe, cap, exchange, method
and price.

=head1 SEE ALSO

=over 4

=item * L<Finance::Quote>

=item * L<Finance::Quote::IEXCloud>

=item * L<https://iextrading.com/developer/docs/>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut
