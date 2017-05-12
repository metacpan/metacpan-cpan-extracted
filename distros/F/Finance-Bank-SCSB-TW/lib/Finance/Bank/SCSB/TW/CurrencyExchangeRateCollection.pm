package Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection;
use strict;
use warnings;

sub for_currency {
    my $self = shift;
    my $currency_name = shift;

    my @ret = ();
    for my $c (@$self) {
        if ($c->{en_currency_name} =~ /\Q${currency_name}\E/i) {
            push @ret, $c;
        }
    }

    return \@ret;
}


1;

__END__

=head1 NAME

Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection

=head1 SYNOPSIS

    my $rates = Finance::Bank::SCSB::TW::currency_exchange_rate;

    my $usd_rates = $rates->for_currency('usd');

=head1 METHODS

=over 4

=item for_currency($name)

Given a currency C<$name>, return a sub-set (as an arrayref) of the
original exchange rate table.

For a list of currency names, see the table in this page:
L<https://ibank.scsb.com.tw/netbank.portal?_nfpb=true&_pageLabel=page_other12&_nfls=fals>

=back

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

Based on B<Finance::Bank::LloydTSB> by Simon Cozens C<simon@cpan.org>,
and B<Finance::Bank::Fubon::TW> by Autrijus Tang C<autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2003,2004,2005,2006,2007,2008,2009 by Kang-min Liu E<lt>gugod@gugod.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
