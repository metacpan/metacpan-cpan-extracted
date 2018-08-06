package Finance::Currency::FiatX::Source::mandiri;

our $DATE = '2018-08-01'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Role::Tiny;
with 'Finance::Currency::FiatX::Role::Source';

sub get_all_spot_rates {
    require Finance::Currency::Convert::Mandiri;
    my $res = Finance::Currency::Convert::Mandiri::get_currencies();

    return $res unless $res->[0] == 200;

    my @recs;
    for my $to (sort keys %{ $res->[2]{currencies} }) {
        my $h = $res->[2]{currencies}{$to};
        for (qw/buy sell/) {
            push @recs, (
                {
                    pair => "$to/IDR",
                    type => "${_}_sr",
                    rate => $h->{"${_}_sr"},
                    note => "$_ special rate",
                    mtime => $res->[2]{mtime_sr},
                },
                {
                    pair => "$to/IDR",
                    type => "${_}_ttc",
                    rate => $h->{"${_}_ttc"},
                    note => "$_ TTC (through-the-counter) rate",
                    mtime => $res->[2]{mtime_ttc},
                },
                {
                    pair => "$to/IDR",
                    type => "${_}_bn",
                    rate => $h->{"${_}_bn"},
                    note => "$_ bank notes rate",
                    mtime => $res->[2]{mtime_bn},
                },
            );
        }
        push @recs, (
            {
                pair => "$to/IDR",
                type => "buy",
                rate => $h->{buy_sr},
                note => "=buy_sr",
                mtime => $res->[2]{mtime_sr},
            },
            {
                pair => "$to/IDR",
                type => "sell",
                rate => $h->{sell_sr},
                note => "=sell_sr",
                mtime => $res->[2]{mtime_sr},
            },
            {
                pair => "IDR/$to",
                type => "buy",
                rate => $h->{sell_sr} ? 1/$h->{sell_sr} : 0,
                note => "=1/sell_sr",
                mtime => $res->[2]{mtime_sr},
            },
            {
                pair => "IDR/$to",
                type => "sell",
                rate => $h->{buy_sr} ? 1/$h->{buy_sr} : 0,
                note => "=1/buy_sr",
                mtime => $res->[2]{mtime_sr},
            },
        );
    }

    [200, "OK", \@recs];
}

sub get_spot_rate {
    my %args = @_;

    my $from = $args{from} or return [400, "Please specify from"];
    my $to   = $args{to} or return [400, "Please specify to"];
    my $type = $args{type} or return [400, "Please specify type"];

    return [501, "This source only provides buy/sell rate types"]
        unless $type =~ /\A(buy|sell)\z/;
    return [501, "This source only provides IDR/* or */IDR spot rates"]
        unless $from eq 'IDR' || $to eq 'IDR';

    require Finance::Currency::Convert::Mandiri;
    my $res = Finance::Currency::Convert::Mandiri::get_currencies();
    return $res unless $res->[0] == 200;

    my $h = $res->[2]{currencies}{$to} || $res->[2]{currencies}{$from};
    return [404, "Cannot find rate for $from/$to"] unless $h;

    my $rate = {
        pair => "$from/$to",
        mtime => $res->[2]{mtime_sr},
        type => $type,
    };
    ;
    if ($from eq 'IDR') {
        if ($type eq 'buy') {
            $rate->{rate} = 1/$h->{sell_sr};
            $rate->{note} = "1/sell_sr";
        } elsif ($type eq 'sell') {
            $rate->{rate} = 1/$h->{buy_sr};
            $rate->{note} = "1/buy_sr";
        }
    } else {
        if ($type eq 'buy') {
            $rate->{rate} = $h->{buy_sr};
            $rate->{note} = "buy_sr";
        } elsif ($type eq 'sell') {
            $rate->{rate} = $h->{sell_sr};
            $rate->{note} = "sell_sr";
        }
    }

    [200, "OK", $rate];
}

sub get_historical_rates {
    return [501, "This source does not provide historical rates"];
}

1;
# ABSTRACT: Get currency conversion rates from Bank Mandiri

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::FiatX::Source::mandiri - Get currency conversion rates from Bank Mandiri

=head1 VERSION

This document describes version 0.010 of Finance::Currency::FiatX::Source::mandiri (from Perl distribution Finance-Currency-FiatX), released on 2018-08-01.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<https://www.bankmandiri.co.id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
