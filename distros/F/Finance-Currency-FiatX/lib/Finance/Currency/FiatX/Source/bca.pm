package Finance::Currency::FiatX::Source::bca;

our $DATE = '2018-06-19'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Role::Tiny;
with 'Finance::Currency::FiatX::Role::Source';

sub get_all_spot_rates {
    require Finance::Currency::Convert::KlikBCA;
    my $res = Finance::Currency::Convert::KlikBCA::get_currencies();

    return $res unless $res->[0] == 200;

    my @recs;
    for my $to (sort keys %{ $res->[2]{currencies} }) {
        my $h = $res->[2]{currencies}{$to};
        push @recs, (
            {
                pair => "$to/IDR",
                type => "buy",
                rate => $h->{buy_er},
                note => "buy_er",
                mtime => $res->[2]{mtime_er},
            },
            {
                pair => "$to/IDR",
                type => "sell",
                rate => $h->{sell_er},
                note => "sell_er",
                mtime => $res->[2]{mtime_er},
            },
            {
                pair => "IDR/$to",
                type => "buy",
                rate => 1/$h->{sell_er},
                note => "1/sell_er",
                mtime => $res->[2]{mtime_er},
            },
            {
                pair => "IDR/$to",
                type => "sell",
                rate => 1/$h->{buy_er},
                note => "1/buy_er",
                mtime => $res->[2]{mtime_er},
            },
        );
    }

    [200, "OK", \@recs];
}

sub get_spot_rate {
    my ($from, $to, $type) = @_;

    return [501, "This source only provides buy/sell rate types"]
        unless $type =~ /\A(buy|sell)\z/;
    return [501, "This source only provides IDR/* or */IDR spot rates"]
        unless $from eq 'IDR' || $to eq 'IDR';

    require Finance::Currency::Convert::KlikBCA;
    my $res = Finance::Currency::Convert::KlikBCA::get_currencies();
    return $res unless $res->[0] == 200;

    my $h = $res->[2]{currencies}{$to} || $res->[2]{currencies}{$from};
    return [404, "Cannot find rate for $from/$to"] unless $h;

    my $rate = {
        pair => "$from/$to",
        mtime => $res->[2]{mtime_er},
        type => $type,
    };
    ;
    if ($from eq 'IDR') {
        if ($type eq 'buy') {
            $rate->{rate} = 1/$h->{sell_er};
            $rate->{note} = "1/sell_er";
        } elsif ($type eq 'sell') {
            $rate->{rate} = 1/$h->{buy_er};
            $rate->{note} = "1/buy_er";
        }
    } else {
        if ($type eq 'buy') {
            $rate->{rate} = $h->{buy_er};
            $rate->{note} = "buy_er";
        } elsif ($type eq 'sell') {
            $rate->{rate} = $h->{sell_er};
            $rate->{note} = "sell_er";
        }
    }

    [200, "OK", $rate];
}

sub get_historical_rates {
    return [501, "This source does not provide historical rates"];
}

1;
# ABSTRACT: Get currency conversion rates from BCA (Bank Central Asia)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::FiatX::Source::bca - Get currency conversion rates from BCA (Bank Central Asia)

=head1 VERSION

This document describes version 0.005 of Finance::Currency::FiatX::Source::bca (from Perl distribution Finance-Currency-FiatX), released on 2018-06-19.

=head1 DESCRIPTION

Bank Central Asia is one of the largest retail banks in Indonesia.

=for Pod::Coverage ^(.+)$

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<https://bca.co.id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
