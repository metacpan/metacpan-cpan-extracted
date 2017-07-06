package Finance::QuoteHist::Google;

use strict;
use vars qw(@ISA $VERSION);
use Carp;

$VERSION = "1.24";

use Finance::QuoteHist::Generic;
@ISA = qw(Finance::QuoteHist::Generic);

use Date::Manip;

# Example URL:
#
# http://www.google.com/finance/historical?q=IBM&startdate=Nov%2011%2C%202008&enddate=Feb%27%2C%202009&output=csv
#
# This also works:
#
# http://www.google.com/finance/historical?q=IBM&startdate=2008-11-11&enddate=2009-02-27&output=csv
#
# weekly:
#
# http://www.google.com/finance/historical?cid=99624&startdate=2008-11-11&enddate=2009-02-27&histperiod=weekly&output=csv
#
# Note: regular symbols have csv available, but some such as .DJI do not.

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my %parms = @_;
  my $self = __PACKAGE__->SUPER::new(%parms);
  bless $self, $class;
  $self->parse_mode('csv');
  $self;
}

sub url_base_csv { 'http://www.google.com/finance/historical' }

sub granularities { qw( daily weekly ) }

sub url_maker {
  my($self, %parms) = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  my $grain       = $parms{granularity} || $self->granularity;
  # *always* block unknown target/mode cominations
  return undef unless $target_mode eq 'quote' && $parse_mode eq 'csv';
  my($ticker, $start_date, $end_date) =
    @parms{qw(symbol start_date end_date)};
  $start_date ||= $self->start_date;
  $end_date   ||= $self->end_date;

  my($sy, $sm, $sd) = $self->ymd($start_date);
  my($ey, $em, $ed) = $self->ymd($end_date);
  my @base_parms = (
    "q=$ticker",
    "startdate=$sy-$sm-$sd", "enddate=$ey-$em+$ed",
  );
  push(@base_parms, 'histperiod=weekly') if $grain && $grain =~ /^w/i;
  push(@base_parms, "output=csv");
  my @urls = join('?', $self->url_base_csv, join('&', @base_parms));

  sub { pop @urls };
}

1;

__END__

=head1 NAME

Finance::QuoteHist::Google - Site-specific class for retrieving historical stock quotes.

=head1 SYNOPSIS

  use Finance::QuoteHist::Google;
  $q = Finance::QuoteHist::Google->new
     (
      symbols    => [qw(IBM UPS AMZN)],
      start_date => '01/01/1999',
      end_date   => 'today',
     );

  foreach $row ($q->quotes()) {
    ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;
    ...
  }

=head1 DESCRIPTION

Finance::QuoteHist::Google is a subclass of
Finance::QuoteHist::Generic, specifically tailored to read historical
quotes from the Google web site (I<http://finance.google.com/>).

Google does not currently provide information on dividends or
splits.

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

Finance::QuoteHist::Generic

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

Details for Googles's terms of use can be found here:

  http://www.google.com/accounts/TOS?loc=us

If you still have concerns, then use another site-specific historical
quote instance, or none at all.

Above all, play nice.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2017 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Finance::QuoteHist::Generic(3), Finance::QuoteHist(3), perl(1).

=cut
