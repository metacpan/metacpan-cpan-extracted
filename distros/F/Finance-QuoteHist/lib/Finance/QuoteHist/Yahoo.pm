package Finance::QuoteHist::Yahoo;

use strict;
use vars qw(@ISA $VERSION);
use Carp;

$VERSION = "1.26";

use Finance::QuoteHist::Generic;
@ISA = qw(Finance::QuoteHist::Generic);

use Date::Manip;
use JSON;

# curl 'https://query2.finance.yahoo.com/v8/finance/chart/TLSA?formatted=true&crumb=l92p7dftYe%2F&lang=en-US&region=US&includeAdjustedClose=true&interval=1d&period1=1455840000&period2=1613692800&events=div%7Csplit&useYfid=true&corsDomain=finance.yahoo.com' \
#  -H 'authority: query2.finance.yahoo.com' \
#  -H 'pragma: no-cache' \
#  -H 'cache-control: no-cache' \
#  -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36' \
#  -H 'dnt: 1' \
#  -H 'accept: */*' \
#  -H 'origin: https://finance.yahoo.com' \
#  -H 'sec-fetch-site: same-site' \
#  -H 'sec-fetch-mode: cors' \
#  -H 'sec-fetch-dest: empty' \
#  -H 'referer: https://finance.yahoo.com/quote/TLSA/history?period1=1455840000&period2=1613692800&interval=1d&filter=history&frequency=1d&includeAdjustedClose=true' \
#  -H 'accept-language: en-US,en;q=0.9' \
#  -H 'cookie: B=a912p61g2vk8r&b=3&s=tt; GUC=AQEBAQFgMSJgOUIaCwP5; A1=d=AQABBBvRL2ACEAlRbREoQmTRqOBpeDBZhKQFEgEBAQEiMWA5YAAAAAAA_SMAAAcIG9EvYDBZhKQ&S=AQAAApHY37COo3qJCJvBwk9D-TA; A3=d=AQABBBvRL2ACEAlRbREoQmTRqOBpeDBZhKQFEgEBAQEiMWA5YAAAAAAA_SMAAAcIG9EvYDBZhKQ&S=AQAAApHY37COo3qJCJvBwk9D-TA; A1S=d=AQABBBvRL2ACEAlRbREoQmTRqOBpeDBZhKQFEgEBAQEiMWA5YAAAAAAA_SMAAAcIG9EvYDBZhKQ&S=AQAAApHY37COo3qJCJvBwk9D-TA&j=US; cmp=t=1613746462&j=0; PRF=t%3DTLSA%252BIBM%252B%255EYHQ' \
#  -H 'sec-gpc: 1' \
#  --compressed


# https://query1.finance.yahoo.com/v7/finance/download/IBM?period1=1495391410&period2=1498069810&interval=1d&events=history&crumb=bB6k340lPXt
# https://query1.finance.yahoo.com/v7/finance/download/IBM?period1=993096000&period2=1498017600&interval=1wk&events=history&crumb=bB6k340lPXt
# https://query1.finance.yahoo.com/v7/finance/download/IBM?period1=993096000&period2=1498017600&interval=1mo&events=history&crumb=bB6k340lPXt
#
# Dividends:
# https://query1.finance.yahoo.com/v7/finance/download/IBM?period1=993096000&period2=1498017600&interval=1d&events=div&crumb=bB6k340lPXt
#
# Splits:
# https://query1.finance.yahoo.com/v7/finance/download/NKE?period1=993096000&period2=1498017600&interval=1d&events=split&crumb=bB6k340lPXt

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my %parms = @_;

  $parms{parse_mode} = 'json';
  $parms{ua_params} ||= {};
  $parms{ua_params}{cookie_jar} ||= {};

  my $self = __PACKAGE__->SUPER::new(%parms);
  bless $self, $class;

  # set initial cookie (the cookie crumbs are hashed out of this)
  # https://finance.yahoo.com/quote/IBM/history
  my $ticker = $parms{symbols};
  $ticker = $ticker->[0] if ref $ticker eq 'ARRAY';
  my $html = $self->fetch("https://finance.yahoo.com/quote/$ticker/history");

  # extract the cookie crumb
  my %crumbs;
  for my $c ($html =~ /"crumb"\s*:\s*"([^"]+)"/g) {
    next if $c =~ /[{}]/;
    $c =~ s/\\u002F/\//;
    ++$crumbs{$c};
  }
  my $crumb = '';
  my $max = 0;
  for my $c (keys %crumbs) {
    if ($crumbs{$c} >= $max) {
      $crumb = $c;
      $max = $crumbs{$c};
    }
  }

  $self->{crumb} = $crumb;

  $self;
}

sub granularities { qw( daily weekly monthly ) }

sub url_maker {
  my($self, %parms) = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode = $parms{parse_mode} || $self->parse_mode;

  # *always* block unknown target mode and parse mode combinations for
  # cascade to work properly!
  return undef unless $target_mode eq 'quote' ||
                      $target_mode eq 'split' ||
                      $target_mode eq 'dividend';

  $parse_mode = "json";

  my $granularity = lc($parms{granularity} || $self->granularity);
  my $grain = 'd';
  $granularity =~ /^\s*(\w)/;
  $grain = $1 if $1 eq 'w' || $1 eq 'm';
  my($ticker, $start_date, $end_date) =
    @parms{qw(symbol start_date end_date)};
  $start_date ||= $self->start_date;
  $end_date   ||= $self->end_date;
  if ($start_date && $end_date && $start_date gt $end_date) {
    ($start_date, $end_date) = ($end_date, $start_date);
  }

  #my $host = "query1.finance.yahoo.com";
  #my $base_url = "https://$host/v7/finance/download/$ticker?";
  
  # https://query2.finance.yahoo.com/v8/finance/chart/TLSA?
  #   formatted=true
  #   crumb=l92p7dftYe%2F
  #   lang=en-US
  #   region=US
  #   includeAdjustedClose=true
  #   interval=1d
  #   period1=1455840000
  #   period2=1613692800
  #   events=div%7Csplit
  #   useYfid=true
  #   corsDomain=finance.yahoo.com

  my $host = "query2.finance.yahoo.com";
  my $base_url = "https://$host/v8/finance/chart/$ticker?";
  my @base_parms;
  if ($start_date) {
    my($y, $m, $d) = $self->ymd($start_date);
    my $ts = Date_SecsSince1970($m, $d, $y, 0, 0, 0);
    push(@base_parms, "period1=$ts");
  }
  if ($end_date) {
    my($y, $m, $d) = $self->ymd($end_date);
    my $ts = Date_SecsSince1970($m, $d, $y, 0, 0, 0);
    $ts += 24*60*60;
    push(@base_parms, "period2=$ts");
  }

  my $interval = "1d";
  if ($grain eq 'w') {
    $interval = "1wk";
  }
  elsif ($grain eq 'm') {
    $interval = "1mo";
  }
  push(@base_parms, "interval=$interval");

  if ($target_mode eq "quote") {
    push(@base_parms, "events=history");
    push(@base_parms, "includeAdjustedClose=true")
  }
  elsif ($target_mode eq "dividend") {
    push(@base_parms, "events=div");
  }
  elsif ($target_mode eq "split") {
    push(@base_parms, "events=split");
  }

  push(@base_parms, "crumb=" . $self->{crumb});

  my @urls = $base_url . join('&', @base_parms);
  return sub { pop @urls };
}

sub json_parser {
  my $self = shift;
  my $target_mode = $self->target_mode();
  my $json_quote_parse = sub {
    my $data_result = shift;
    my $data_indicators = $data_result->{indicators} || {};
    my $data_quote      = ($data_indicators->{quote} || [])->[0];
    my @rows = [];
    if ($data_quote) {
      my $data_high       = $data_quote->{high};
      my $data_close      = $data_quote->{close};
      my $data_open       = $data_quote->{open};
      my $data_low        = $data_quote->{low};
      my $data_volume     = $data_quote->{volume};
      my $data_adj_close  = $data_indicators->{adjclose}[0]{adjclose};
      my $data_timestamp  = $data_result->{timestamp};
      for my $i (0 .. $#{$data_timestamp}) {
        push(@rows, [
          $data_timestamp->[$i],
          $data_open->[$i],
          $data_high->[$i],
          $data_low->[$i],
          $data_close->[$i],
          $data_volume->[$i],
        ]);
      }
    }
    \@rows;
  };
  my $json_split_parse = sub {
    my $data_result = shift;
    my $data_events = $data_result->{events} || {};
    my $data_splits = $data_events->{splits} || {};
    my @rows;
    if ($data_splits) {
      for my $rec (sort values %$data_splits) {
        push(@rows, [
          $rec->{date},
          $rec->{numerator},
          $rec->{denominator},
        ]);
      }
    }
    \@rows;
  };
  my $json_div_parse = sub {
    # "date" "amount"
    my $data_result = shift;
    my $data_events = $data_result->{events} || {};
    my $data_dividends = $data_events->{dividends} || {};
    my @rows;
    for my $rec (sort values %$data_dividends) {
      push(@rows, [
        $rec->{date},
        $rec->{amount},
      ]);
    }
    \@rows;
  };
  sub {
    my $data = shift;
    $data = decode_json($data);
    my $data_result = $data->{chart}{result}[0] || {};
    if ($target_mode eq "quote") {
      return $json_quote_parse->($data_result);
    }
    elsif ($target_mode eq "split") {
      return $json_split_parse->($data_result);
    }
    elsif ($target_mode eq "dividend") {
      return $json_div_parse->($data_result);
    }
    else { die "unknown mode: $target_mode" }
  };
}

1;

__END__

=head1 NAME

Finance::QuoteHist::Yahoo - Site-specific subclass for retrieving historical stock quotes.

=head1 SYNOPSIS

  use Finance::QuoteHist::Yahoo;
  $q = new Finance::QuoteHist::Yahoo
     (
      symbols    => [qw(IBM UPS AMZN)],
      start_date => '01/01/2009',
      end_date   => 'today',
     );

  # Values
  foreach $row ($q->quotes()) {
    ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;
    ...
  }

  # Splits
  foreach $row ($q->splits()) {
     ($symbol, $date, $post, $pre) = @$row;
  }

  # Dividends
  foreach $row ($q->dividends()) {
     ($symbol, $date, $dividend) = @$row;
  }

=head1 DESCRIPTION

Finance::QuoteHist::Yahoo is a subclass of
Finance::QuoteHist::Generic, specifically tailored to read historical
quotes, dividends, and splits from the Yahoo web site
(I<http://table.finance.yahoo.com/>).

For quotes and dividends, Yahoo can return data quickly in CSV format.
Both of these can also be extracted from HTML tables. Splits are
extracted from the HTML of the 'Basic Chart' page for that ticker.

There are no date range restrictions on CSV queries for quotes and
dividends.

For HTML queries, Yahoo takes arbitrary date ranges as arguments, but
breaks results into pages of 66 entries.

Please see L<Finance::QuoteHist::Generic(3)> for more details on usage
and available methods. If you just want to get historical quotes and
are not interested in the details of how it is done, check out
L<Finance::QuoteHist(3)>.

=head1 METHODS

The basic user interface consists of three methods, as seen in the
example above. Those methods are:

=over

=item quotes()

Returns a list of rows (or a reference to an array containing those
rows, if in scalar context). Each row contains the B<Symbol>, B<Date>,
B<Open>, B<High>, B<Low>, B<Close>, and B<Volume> for that date.

=item dividends()

Returns a list of rows (or a reference to an array containing those
rows, if in scalar context). Each row contains the B<Symbol>, B<Date>,
and amount of the B<Dividend>, in that order.

=item splits()

Returns a list of rows (or a reference to an array containing those
rows, if in scalar context). Each row contains the B<Symbol>, B<Date>,
B<Post> split shares, and B<Pre> split shares, in that order.

=back

The following methods override methods provided by the
Finance::QuoteHist::Generic module; more of this was necessary than is
typical for a basic query site due to the variety of query types and
data formats available on Yahoo.

=over

=item url_maker()

Returns a subroutine reference tailored for the current target mode and
parsing mode. The routine is an iterator that will produce all necessary
URLs on repeated invocations necessary to complete a query.

=item extractors()

Returns a hash of subroutine references that attempt to extract embedded
values (dividends or splits) within the results from a larger query.

=item labels()

Includes the 'adj' column.

=back

=head1 REQUIRES

Finance::QuoteHist::Generic

=head1 DISCLAIMER

The data returned from these modules is in no way guaranteed, nor are
the developers responsible in any way for how this data (or lack
thereof) is used. The interface is based on URLs and page layouts that
might change at any time. Even though these modules are designed to be
adaptive under these circumstances, they will at some point probably
be unable to retrieve data unless fixed or provided with new
parameters. Furthermore, the data from these web sites is usually not
even guaranteed by the web sites themselves, and oftentimes is
acquired elsewhere.

If you would like to know more, check out the terms of service from
Yahoo!, which can be found here:

  http://docs.yahoo.com/info/terms/

If you still have concerns, then use another site-specific historical
quote instance, or none at all.

Above all, play nice.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2021 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Finance::QuoteHist::Generic(3), Finance::QuoteHist(3), perl(1).

=cut
