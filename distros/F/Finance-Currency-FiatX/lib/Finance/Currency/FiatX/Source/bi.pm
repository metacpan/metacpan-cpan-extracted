package Finance::Currency::FiatX::Source::bi;

our $DATE = '2018-06-19'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Role::Tiny;
with 'Finance::Currency::FiatX::Role::Source';

sub get_all_spot_rates {
    require Finance::Currency::Convert::BI;
    my $res = Finance::Currency::Convert::BI::get_currencies();

    return $res unless $res->[0] == 200;

    my @recs;
    for my $to (sort keys %{ $res->[2]{currencies} }) {
        my $h = $res->[2]{currencies}{$to};
        push @recs, (
            {
                pair => "$to/IDR",
                type => "buy",
                rate => $h->{buy},
                mtime => $res->[2]{mtime},
            },
            {
                pair => "$to/IDR",
                type => "sell",
                rate => $h->{sell},
                mtime => $res->[2]{mtime},
            },
            {
                pair => "IDR/$to",
                type => "buy",
                rate => 1/$h->{sell},
                note => "1/sell",
                mtime => $res->[2]{mtime},
            },
            {
                pair => "IDR/$to",
                type => "sell",
                rate => 1/$h->{buy},
                note => "1/buy",
                mtime => $res->[2]{mtime},
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

    require Finance::Currency::Convert::BI;
    my $res = Finance::Currency::Convert::BI::get_currencies();
    return $res unless $res->[0] == 200;

    my $h = $res->[2]{currencies}{$to} || $res->[2]{currencies}{$from};
    return [404, "Cannot find rate for $from/$to"] unless $h;

    my $rate = {
        pair => "$from/$to",
        mtime => $res->[2]{mtime},
        type => $type,
    };
    ;
    if ($from eq 'IDR') {
        if ($type eq 'buy') {
            $rate->{rate} = 1/$h->{sell};
            $rate->{note} = "1/sell";
        } elsif ($type eq 'sell') {
            $rate->{rate} = 1/$h->{buy};
            $rate->{note} = "1/buy";
        }
    } else {
        if ($type eq 'buy') {
            $rate->{rate} = $h->{buy};
            $rate->{note} = "buy";
        } elsif ($type eq 'sell') {
            $rate->{rate} = $h->{sell};
            $rate->{note} = "sell";
        }
    }

    [200, "OK", $rate];
}

sub get_historical_rate {
    return [501, "Getting historical rate not yet supported by this module"];
}

1;
# ABSTRACT: Get currency conversion rates from BI (Bank Indonesia)

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::FiatX::Source::bi - Get currency conversion rates from BI (Bank Indonesia)

=head1 VERSION

This document describes version 0.005 of Finance::Currency::FiatX::Source::bi (from Perl distribution Finance-Currency-FiatX), released on 2018-06-19.

=head1 DESCRIPTION

Bank Indonesia is Indonesia's central bank.

=for Pod::Coverage ^(.+)$

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<https://www.bi.go.id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
