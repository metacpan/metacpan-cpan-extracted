package Finance::QuoteHist::DailyFinance;

use strict;
use vars qw(@ISA $VERSION);
use Carp;

$VERSION = "1.00";

use constant DEBUG => 0;

use Finance::QuoteHist::Generic;
@ISA = qw(Finance::QuoteHist::Generic);

# Example URL:
#
# http://www.motleyfool.idmanagedsolutions.com/stocks/historical_quotes.idms?START_DATE=2011-06-01&END_DATE=2012-11-01&CODE_MARKET=US,@US&SYMBOL_US=IBM&BLOCKSIZE=100&OFFSET=1
# http://www.motleyfool.idmanagedsolutions.com/stocks/historical_quotes.idms?START_DATE=2011-06-01&END_DATE=2012-11-01&CODE_MARKET=US,@US&SYMBOL_US=IBM&BLOCKSIZE=100&OFFSET=2

sub url_maker {
  my($self, %parms) = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;

  # *always* block uknown target mode and parse mode combinations in
  # order for cascade to work!
  return undef unless
    ($target_mode eq 'quote') && $parse_mode eq 'html';

  my($ticker, $start_date, $end_date) =
    @parms{qw(symbol start_date end_date)};
  $start_date ||= $self->start_date;
  $end_date   ||= $self->end_date;

  my($sy, $sm, $sd) = $self->ymd($start_date);
  my($ey, $em, $ed) = $self->ymd($end_date);


  my $host = 'www.motleyfool.idmanagedsolutions.com';
  my $path = 'stocks/historical_quotes.idms';

  my %query = (
    START_DATE  => "$sy-$sm-$sd",
    END_DATE    => "$ey-$em-$ed",
    SYMBOL_US   => $ticker,
    CODE_MARKET => 'US,@US',
    BLOCK_SIZE  => 100,
  );

  my $offset=0;

  sub {
    $query{OFFSET} = $offset;
    my $url = "http://$host/$path?" .
              join('&', map { "$_=$query{$_}" } sort keys %query);
    print STDERR "URL: $url\n" if DEBUG;
    ++$offset;
    return $url;
  };
}

1;

__END__

=head1 NAME

Finance::QuoteHist::DailyFinance - Site-specific class for retrieving historical stock quotes.

=head1 SYNOPSIS

  use Finance::QuoteHist::DailyFinance;
  $q = Finance::QuoteHist::DailyFinance->new
     (
      symbols    => [qw(IBM UPS AMZN)],
      start_date => '01/01/2005',
      end_date   => 'today',
     );

  foreach $row ($q->quotes()) {
    ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;
    ...
  }

=head1 DESCRIPTION

Finance::QuoteHist::DailyFinance is a subclass of
Finance::QuoteHist::Generic, specifically tailored to read historical
quotes from the Daily Finance web site
(I<http://www.dailyfinance.com/>).

DailyFinance offers only daily granularity for quotes.

DailyFinance does not currently provide information on dividends or splits.

Please see L<Finance::QuoteHist::Generic(3)> for more details on usage
and available methods. If you just want to get historical quotes and are
not interested in the details of how it is done, check out
L<Finance::QuoteHist(3)>.

=head1 METHODS

The basic user interface consists of a single method, as shown in the
example above. That method is:

=over

=item quotes()

Returns a list of rows (or a reference to an array containing those
rows, if in scalar context). Each row contains the B<Symbol>, B<Date>,
B<Open>, B<High>, B<Low>, B<Close>, and B<Volume> for that date. Quote
values are pre-adjusted for this site.

=back

=head1 REQUIRES

Finance::QuoteHist::Generic(3)

=head1 DISCLAIMER

The data returned from these modules is in no way guaranteed, nor are
the developers responsible in any way for how this data (or lack
thereof) is used. The interface is based on URLs and page layouts that
might change at any time. Even though these modules are designed to be
adaptive under these circumstances, they will at some point probably be
unable to retrieve data unless fixed or provided with new parameters.
Furthermore, the data from these web sites is usually not even
guaranteed by the web sites themselves, and oftentimes is acquired
elsewhere.

Details for DailyFinance's terms of use can be found here:
I<http://legal.aol.com/TOS/>

If you still have concerns, then use another site-specific historical
quote instance, or none at all.

Above all, play nice.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Finance::QuoteHist::Generic(3), Finance::QuoteHist(3), perl(1).

=cut
