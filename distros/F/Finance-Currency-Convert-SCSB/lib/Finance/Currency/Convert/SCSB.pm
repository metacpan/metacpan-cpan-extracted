package Finance::Currency::Convert::SCSB;

use strict;
use warnings;

our $VERSION = v0.1.1;

use Exporter 'import';
our @EXPORT_OK = qw(get_currencies convert_currency);

use Mojo::UserAgent;

sub get_currencies {
    my ($error, $result);

    my $dom;
    eval {
        $dom = _fetch_currency_exchange_web_page();
    } or do {
        $error = $@;
    };
    return ($error, undef) if defined $error;

    my @col_names = qw(zh_currency_name en_currency_name buy_at sell_at);
    my @cols = (
        $dom->find("td.txt09 > span")->map('all_text')->to_array(),
        $dom->find("td.txt09 + td > span")->map('all_text')->to_array(),
        $dom->find("td.txt09 + td + td.txt101 > span")->map('all_text')->to_array(),
        $dom->find("td.txt09 + td + td.txt101 + td.txt101 > span")->map('all_text')->to_array(),
    );

    my @rows = ();
    for my $i (0..$#{$cols[0]}) {
        my $currency = $cols[1][$i] =~ s/ CASH//r;
        push @rows, {
            currency         => $currency,
            zh_currency_name => $cols[0][$i],
            en_currency_name => $cols[1][$i],
            buy_at           => $cols[2][$i],
            sell_at          => $cols[3][$i],
        }
    }

    return (undef, \@rows);
}

sub convert_currency {
    my ($amount, $from_currency, $to_currency) = @_;
    return ("The convertion target must be 'TWD'. Cannot proceed with '$to_currency'", undef) unless $to_currency eq 'TWD';

    my $dom;
    my ($error, $result) = get_currencies();
    return ($error, undef) if defined $error;

    my $rate;
    for (@$result) {
        next if $_->{en_currency_name} =~ /CASH/;
        if ($_->{currency} eq $from_currency) {
            $rate = $_;
            last;
        }
    }
    return ("Unknown currency: $from_currency", undef) unless $rate;

    return (undef, $amount * $rate->{buy_at});
}

sub _fetch_currency_exchange_web_page {
    my $ua = Mojo::UserAgent->new;
    my $result = $ua->get('https://ibank.scsb.com.tw/netbank.portal?_nfpb=true&_pageLabel=page_other12&_nfls=false')->result;
    die $result->message if $result->is_error;
    return $result->dom;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::Currency::Convert::SCSB - Query currency exchange rates from SCSB (Shanghai Commercial and Savings Bank)

=head1 VERSION

v0.1.0

=head1 DESCRIPTION

This module crawl and parses currency exchange rates listed on this web: L<https://ibank.scsb.com.tw/netbank.portal?_nfpb=true&_pageLabel=page_other12&_nfls=false> . All prices on this page are in TWD (Taiwan Dollar.) For this reason, it can only convert some non-TWD currency to TWD.

=head1 FUNCTIONS

The following functions are exportable, but not exported by default.

Some annotations with fictional Types are used in the following
documentation just for the purpose of explaination. No Type-validation
are implemented, nor are they defined. Not in this module.

"Num" referrer to a number, "Currency" is a short string such as
'TWD', 'USD'. The notation `Maybe[T]` means that the variable can
contain a value either be of type T, or C<undef>. See:
L<Types::Standard> or L<Moose::Util::TypeConstraints> for more
description of these notations.

=head2 convert_currency

Definition:

    ($error :Maybe[Str], $result :Maybe[Num]) =
        convert_currency(
            $amount :Num
            $from :Currency,
            $to :Currency
        )

When it is successful, C<$error> is C<undef> and C<$result> contained the parsed output.

When error of some kind happens, C<$error> contains the error message
and C<$result> is undef.

Example Usage:

    # Error-checking
    my ($err, $n) = convert_currency(100, 'USD', 'TWD');
    die "Error: $err": if $err;
    say "100 USD is about $n TWD";

    # Ignore error message. Checks the result directly.
    my $n = convert_currency(100, 'USD', 'TWD');
    if ( defined($n) ) {
        say "100 USD is about $n TWD";
    } else {
        say "Failed to convert 100 USD to TWD";
    }

=head2 get_currencies

With this function, the entire exchange rate table are parsed and returned in the special strucutre.

Definition:

    ($error :Maybe[Str], $result :Maybe[ArrayRef[Rate]]) =
        convert_currency(
            $amount :Num,
            $from :Currency,
            $to :Currency
        )

When it is successful, C<$error> is C<undef> and C<$result> contained the parsed output.

When error of some kind happens, C<$error> contains the error message
and C<$result> is undef.

Usage:

    # Error-checking
    my ($err, $o) = get_currencies();
    die "Error: $err": if $err;
    do_something($o);

    # Ignore error message. Checks the result directly.
    my $o = get_currencies();
    if ($o) {
        ...
    } else {
        ...
    }

The "Rate" type is a HashRef with 5 specific key-value pairs that looks like this:

    {
        currency         => "USD",
        zh_currency_name => "美金現金",
        en_currency_name => "USD CASH",
        buy_at           => 33.06,
        sell_at          => 33.56
    }

This structure is just a directly translation of the rate exchange
table shown on the source web page.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

This is free software, licensed under:

  The MIT (X11) License


