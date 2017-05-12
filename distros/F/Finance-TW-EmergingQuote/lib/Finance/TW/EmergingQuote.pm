package Finance::TW::EmergingQuote;
our $VERSION = '0.26';

use strict;
use LWP::Simple ();
use Encode 'from_to';

sub resolve {
    die "not implemented";
}

sub new {
    my ($class, $target) = @_;
    my $self = bless {}, $class;

    $self->resolve($target)
	unless $target =~ /^\d+$/;

    $self->{id} ||= $target;

    return $self;
}

sub get {
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    shift if $_[0] eq __PACKAGE__;
    my $stockno = $self ? $self->{id} : shift;
    my $content = LWP::Simple::get("http://nweb.otc.org.tw/main.htm");
    from_to($content, 'big5', 'utf-8');
    my $result;

    my ($time) = $content =~ m/製表時間 :.*?,([\d:]+)/;

    undef $self->{quote} if $self;

#<tr bgcolor='#F5EBEB'><td  align='center'><FONT class=AS22 size=2>&nbsp;<A HREF='javascript:winopen("ns01stk","3480")'>3480</A></td><td  align='left'><FONT class=AS22 size=2>&nbsp;®õ¦w¬ì</td><td  align='right'><FONT class=AS22 size=2>&nbsp;70.56</td><td  align='right'><FONT class=AS22 size=2>&nbsp;<A HREF='javascript:winopen1("nsquote_bs","3480","1")'>68.0</a></td><td  align='right'><FONT class=AS22 size=2>&nbsp;     1,000</td><td  align='right'><FONT class=AS22 size=2>&nbsp;<A HREF='javascript:winopen1("nsquote_bs","3480","2")'>72.0</a></td><td  align='right'><FONT class=AS22 size=2>&nbsp;     1,000</td><td  align='right'><FONT class=AS22 size=2>&nbsp;71.0</td><td  align='right'><FONT class=AS22 size=2>&nbsp;69.0</td><td  align='right'><FONT class=AS22 size=2>&nbsp;70.47</td><td  align='right'><FONT class=AS22 size=2>&nbsp;71.0</td><td  align='right'><FONT class=AS22 size=2>&nbsp;     25,039</td><td  align='right'><FONT class=AS22 size=2>&nbsp;95/04/03</td><td  align='left'><FONT class=AS22 size=2>&nbsp;°e¥ó¥Ó½Ð¤W¥«</td></tr>

    while ($content =~ s{<tr bgcolor=(.*?)</tr>}{}) {
	my $entrybuf = $1;
	my ($stock_no) = $entrybuf =~ m{"(\d+)"};
	next unless $stock_no == $self->{id};

	@{$result}{qw(id name PAvg BidBuy BidBuyVol BidSell BidSellVol HighPrice LowPrice Avg MatchPrice DQty)} =
	    map {s/,//g; $_} grep { $_ ne '&nbsp;' } $entrybuf =~ m/>(?:&nbsp;\s*)?([^<>]+)</g;
	$result->{DQty} /= 1000;
	$result->{time} = $time;
    }

    $self->{quote} = $result if $self;

    return $result;
}


1;

=head1 NAME

Finance::TW::EmergingQuote - Check stock quotes from Taiwan Emerging Stock

=head1 SYNOPSIS

    use Finance::TW::EmergingQuote;

    my $quote = Finance::TW::EmergingQuote->new('3481');

    while (1) { print $quote->get->{MatchPrice}.$/; sleep 30 }

=head1 DESCRIPTION

This module provides interface to Emerging Stock price information
available from Taiwan's OTC(over-the-counter market). You could get
the real time quote.

=head1 CLASS METHODS

=over 4

=item new

    Create a stock quote object. Resolve the name to symbol
    if the argument is not a symbol.

=item resolve

    Resolve the company name to stock symbol.

=item get

    Get the real time stock information.
    Return a hash containing stock information. The keys are:

=over 4

=item DQty

    current volume

=item MatchPrice

    current price

=item HighPrice

    daily high

=item LowPrice

    daily low

=back

=back

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

