package Finance::TW::TSEQuote;
use 5.10.1;
use strict;
our $VERSION = '0.28';

use LWP::Simple ();
use Encode 'from_to';
use URI::Escape;
use App::Cache;
use Digest::MD5 qw(md5_hex);

sub resolve {
    my $self = shift;
    $self = bless {}, __PACKAGE__ unless ref($self) eq __PACKAGE__;
    my $name = shift;
    $self->{cache} ||= App::Cache->new({ ttl => 7 * 24 * 60 * 60 });  # a week
    my $cache = $self->{cache};
    my $key   = md5_hex($name);

    unless ($cache->get($key)) {
        my $url = "http://brk.twse.com.tw:8000/isin/C_public.jsp?strMode=2";
        my $content = $cache->get_url($url);

        from_to($content, 'big5', 'utf-8');
        use HTML::TableExtract;
        my $te = HTML::TableExtract->new(
                            headers => [qw(證券代號及名稱 上市日)]);
        $te->parse($content);
        foreach my $ts ($te->tables) {
            foreach my $row ($ts->rows) {
                my ($symbol, $company)
                    = $row->[0] =~ m|(\S+)\s+\xe3\x80\x80(.*?)$|o;
                next unless $symbol;
                my $board_date = $row->[1];
                $cache->set(md5_hex($company),
                            { id => $symbol, date => $board_date });
            }
        }
    }
    my $id = $cache->get($key)->{id};

    die "can't resolve symbol: $name" unless $id;

    @{$self}{qw/id/} = ($id);

    return $id;

}

sub new {
    my ($class, $target) = @_;
    my $self = bless {}, $class;

    $self->resolve($target)
        unless $target =~ /^\d+$/;

    $self->{id} ||= $target;

    return $self;
}

no utf8;
no encoding;

sub get {
    my $self = shift;
    my $stockno = ref $self ? $self->{id} : shift;
    my $content
        = LWP::Simple::get("http://mis.twse.com.tw/data/$stockno.csv");
    from_to($content, 'big5', 'utf-8');

    my $result;
    $content =~ s/["\n\r]//g;
    my @info = split /,/, $content;
    my $cmap = [ undef,        'UpDown',    'time',      'UpPrice',
                 'DownPrice',  'OpenPrice', 'HighPrice', 'LowPrice',
                 'MatchPrice', 'MatchQty',  'DQty' ];
    $result->{ $cmap->[$_] } = $info[$_] foreach (0 .. 10);
    $result->{name} = $info[32];
    $result->{name} =~ s/\s//g;
    $self->{name} ||= $result->{name} if ref $self;

    if ($result->{MatchPrice} == $result->{UpPrice}) {
        $result->{UpDownMark} = '♁';
    } elsif ($result->{MatchPrice} == $result->{DownPrice}) {
        $result->{UpDownMark} = '?';
    } elsif ($result->{UpDown} > 0) {
        $result->{UpDownMark} = '＋';
    } elsif ($result->{UpDown} < 0) {
        $result->{UpDownMark} = '－';
    }

    $result->{Bid}{Buy}[$_]{ $info[ 11 + $_ * 2 ] } = $info[ 12 + $_ * 2 ]
        foreach (0 .. 4);
    $result->{Bid}{Sell}[$_]{ $info[ 21 + $_ * 2 ] } = $info[ 22 + $_ * 2 ]
        foreach (0 .. 4);
    $result->{BuyPrice}  = $info[11];
    $result->{SellPrice} = $info[21];

    $self->{quote} = $result if ref $self;

    return $result;
}

sub fetchMarketFile {
    my $self = shift;
    my ($stock, $year, $month) = @_;
    my @fields = ();
    my ($i, $url, $file, $arg, $outfile);

    $month = "0" . $month if $month < 10;
    $url
        = "http://www.twse.com.tw/ch/trading/exchange/STOCK_DAY/genpage/Report"
        . $year
        . $month . "/";
    $file = $year . $month . "_F3_1_8_" . $stock . ".php?STK_NO=" . $stock;
    $arg  = "&myear=" . $year . "&mmon=" . $month;
    my $content = LWP::Simple::get("$url$file$arg");
    my $result;

    if ($content) {
        if ($content =~ /<tr bgcolor='#F7F0E8'>(.+)/) {
            $content = $1;
            $content =~ s/<table(.)*?>/ /g;
            $content =~ s/<tr(.)*?>/ /g;
            $content =~ s/<td(.)*?>/ /g;
            $content =~ s/<\/tr(.)*?>/ /g;
            $content =~ s/<\/td(.)*?>/ /g;
            $content =~ s/<div(.)*?>/ /g;
            $content =~ s/<\/div(.)*?>/ /g;
            $content =~ s/&nbsp;/ /g;
            $content =~ s/.*µ§¼Æ\s*//;
            $content =~ s/\s+/ /g;
            $content =~ s/,//g;
            @fields = split / /, $content;

            for ($i = 18; $i <= $#fields; $i += 9) {
                my $date = $fields[ $i - 3 ];
                my ($yy, $mm, $dd) = split /\//, $date;
                $fields[ $i - 3 ] = (1911 + $yy) . "-" . $mm . "-" . $dd
                    if $mm;

                $result
                    .= $fields[$i] . "\t"
                    . $fields[ $i + 1 ] . "\t"
                    . $fields[ $i + 2 ] . "\t"
                    . $fields[ $i + 3 ] . "\t"
                    . $fields[ $i + 5 ] . "\t"
                    . $fields[ $i - 3 ] . "\n";

            }
        }
    }
    return $result;
}

1;

=head1 NAME

Finance::TW::TSEQuote - Check stock quotes from Taiwan Security Exchange

=head1 SYNOPSIS

    use Finance::TW::TSEQuote;

    my $quote = Finance::TW::TSEQuote->new('2002');

    while (1) { print $quote->get->{MatchPrice}.$/; sleep 30 }

=head1 DESCRIPTION

This module provides interface to stock information available from
Taiwan Security Exchange. You could resolve company name to stock
symbol, as well as getting the real time quote.

=head1 CLASS METHODS

=over 4

=item new

    Create a stock quote object. Resolve the name to symbol
    if the argument is not a symbol.

=item resolve

    Resolve the company name to stock symbol.

=item fetchMarketFile

    Fetch the Een-Of-Day stock information for specific company
	by year and month.

=item get

    Get the real time stock information.
    Return a hash containing stock information. The keys are:

=over 4

=item Bid

    a hash of array of best 5 matching Sell and Buy bids

=item DQty

    current volume

=item MatchQty

    daily volume

=item MatchPrice

    current price

=item OpenPrice

    opening price

=item HighPrice

    daily high

=item LowPrice

    daily low

=back

=back

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

Cheng-Lung Sung

=head1 COPYRIGHT

Copyright 2003-2012 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

