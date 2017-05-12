package Finance::YahooProfile;

use strict;
use vars qw($VERSION);

$VERSION = '1.12';

use LWP::UserAgent;
use HTTP::Request::Common;

sub new {
    my $type = shift;
    my $class = ref $type || $type;
    my $self = {};
    bless $self, $class;
    $self->_init(@_) if @_;
    return $self;
}

sub _init {
    my ($self, %params) = @_;
    for (keys %params) {
	$self->{$_} = $params{$_};
	$self->{'dollar_symbol'} = 1 unless defined $params{'dollar_symbol'};
    }
}

sub profile {
    my ($self, %params) = @_;

    my (@res, $ua);

    $ua = LWP::UserAgent->new;
    $ua->timeout($self->{'timeout'}) if defined $self->{'timeout'};
    $ua->env_proxy();

    if (not ref $params{'s'}) { $params{'s'} = [$params{'s'}]; }

    my ($s, $firstletter, $url, $content, $res);
    for $s ( @{$params{'s'}} ) {

	$firstletter = substr($s, 0, 1);
	$url = "http://biz.yahoo.com/p/$firstletter/$s.html";
	$content = $ua->request(GET $url)->content();
	$res = {};  ## to store the results
	$res->{'requested_symbol'} = $s;

	{
	    local $/;
	    $content =~ s/<[^>]*>//gs;
	}

	## Prepare Content for extraction
	$content =~ s/&nbsp;/ /g;                         ## insert spaces
	$content =~ s/.*(Statistics at a Glance -- )//s;  ## remove the beginning
	$content =~ s/(See Profile).*//s;                 ## remove the end
	
	## Check for non-existent data
	if ($content =~ /\nNo Such Data/) {
	    $res->{'success'} = 0;
	    push (@res, $res);
	    next;
	}

	## Market
	$content =~ s/(.+?)://s;
	$res->{'market'} = $1;
	
	## Ticker Symbol
	if ($content =~ s/(.+?)As of //s) {
	    $res->{'symbol'} = $1;
	}
	
	## Last Updated
	if ($content =~ s/(.+?)Price and Volume//s) { 
	    $res->{'last_updated'} = $1; 
	}
	
	## 52-Week Prices
	if ($content =~ s/52-Week Lowon (.+?)\$(.+?) Recent Price(.+?) 52-Week Highon (.+?)\$(.+?)( )?Beta/Beta/s) { 
	    $res->{'52_week_low_date'} = $1;
	    $res->{'52_week_low'} = $2;
	    $res->{'recent_price'} = $3;
	    $res->{'52_week_high_date'} = $4;
	    $res->{'52_week_high'} = $5;
	}

	## Beta, and Volume Data
	if ($content =~ s/Beta(.+?) Daily Volume \(3-month avg\)(.+?)Daily Volume \(10-day avg\)(.+?)Stock/Stock/s) { 
	    $res->{'beta'} = $1;
	    $res->{'daily_volume_3ma'} = $2;
	    $res->{'daily_volume_10da'} = $3;
	}
	
	## 52-Week Price Change
	if ($content =~ s/.+?52-Week Change(.+?)52-Week Changerelative to S&amp;P500(.+?)Share//s) { 
	    $res->{'52_week_change'} = $1;
	    $res->{'52_week_change_sp500'} = $2;
	}
	
	## Share related items
	if ($content =~ s/.+?Market Capitalization(.+?)Shares Outstanding(.+?)Float(.+?)Dividends//s) { 
	    $res->{'market_capitalization'} = $1;
	    $res->{'shares_outstanding'} = $2;
	    $res->{'shares_float'} = $3;
	}
	
	if ($content =~ s/.*?Annual Dividend( \(indicated\))?(.+?)( Dividend Yield(.+?))?Last Split(.+?)Per//s) { 
	    $res->{'dividend'} = $2;
	    $res->{'dividend_yield'} = $4;

	    if ($5 ne 'none') {
		if ($5 =~ m/factor (.+?) on (.+)/) {
		    $res->{'last_split_factor'} = $1;
		    $res->{'last_split_date'} = $2;
		}
	    }
	}

	## Per-Share Data
	if ($content =~ s/.+?Book Value \(mrq\*\)(.+?) Earnings \(ttm\)(.+?) (Earnings \(mrq\)(.+?) )?Sales \(ttm\)(.+?) Cash( \(mrq\*\)?)?(.+?) Valuation//s) { 
	    $res->{'book_value'} = $1;
	    $res->{'earnings_ttm'} = $2;
	    $res->{'earnings_mrq'} = $4;
	    $res->{'sales_ttm'} = $5;
	    $res->{'cash'} = $7;
	}

	## Valuation Ratios
	if ($content =~ s!.+?Price/Book \(mrq\*\)(.+?) Price/Earnings( \(ttm\))?(.+?) Price/Sales \(ttm\)(.+?) Income!!s) { 
	    $res->{'price_book'} = $1;
	    $res->{'price_earnings'} = $3;
	    $res->{'price_sales'} = $4;
	}

	## Income Statements
	if ($content =~ s/.+?Sales \(ttm\)(.+?)EBITDA \(ttm\*\)(.+?)Income available to common \(ttm\)(.+?)Profitability//s) { 
	    $res->{'sales'} = $1;
	    $res->{'ebitda'} = $2;
	    $res->{'income'} = $3;
	}
	
	## Profitability
	if ($content =~ s/.*?Profit Margin \(ttm\)(.+?)Operating Margin \(ttm\)(.+?)Fiscal//s) { 
	    $res->{'profit_margin'} = $1;
	    $res->{'operating_margin'} = $2;
	}
	
	## Fiscal Year
	if ($content =~ s/.*?Fiscal Year Ends(.+?)Most recent quarter(\(fully\nupdated\))?(.+?)(Most recent quarter\(flash earnings\)(.+?))?Management//s) { 
	    $res->{'fiscal_year_ends'} = $1;
	    $res->{'most_recent_quarter'} = $3;
	    $res->{'most_recent_quarter_fe'} = $5;
	    $res->{'fiscal_year_ends'} =~  s/\n|\r/ /s;

	    }

	## Management Effectiveness
	if ($content =~ s/.*?Return on Assets \(ttm\)(.+?)Return on Equity \(ttm\)(.+?)Financial//s) { 
	    $res->{'return_on_assets'} = $1;
	    $res->{'return_on_equity'} = $2;
	}
	
	## Financial Strength
	if ($content =~ s/.*?Current Ratio( \(mrq\*?\))?(.+?) Debt\/Equity( \(mrq\*?\))?(.+?) Total Cash( \(mrq\*?\))?(.+?)Short//s) { 
	    $res->{'current_ratio'} = $2;
	    $res->{'debt_equity'} = $4;
	    $res->{'total_cash'} = $6;
	}
	
	## Short Interest
	if ($content =~ s/.*?InterestAs\nof (.+?)Shares\nShort(.+?)Percent of Float(.+?)Shares Short\(Prior Month\)(.+?)Short Ratio(.+?) Daily Volume([\d\.KMB]+)//s) { 
	    $res->{'short_interest_date'} = $1;
	    $res->{'short_interest'} = $2;
	    $res->{'short_percent'} = $3;
	    $res->{'short_previous_month'} = $4;
	    $res->{'short_ratio'} = $5;
	    $res->{'short_daily_volume'} = $6;
	}
	
	$self->_expand($res) if $self->{'expand_numbers'} || $self->{'expand_percent'} || $self->{'expand'};
	$res->{'success'} = 1;
	
	push(@res, $res);
    }

    return wantarray ? @res : \@res;
    
}

sub _expand {
    my ($self, $res) = @_;
    my (%factors, $key, $dollar, $factor, @number_keys, @percent_keys);
    
    %factors = ( 'K' => 1_000,
		 'M' => 1_000_000,
		 'B' => 1_000_000_000,
		 'T' => 1_000_000_000_000       ## for when we have the first trillion dollar company.
	       );

    @number_keys = qw(
		      daily_volume_10da
		      daily_volume_3ma
		      ebitda
		      income
		      market_capitalization
		      sales
		      shares_float
		      shares_outstanding
		      short_interest
		      short_daily_volume
		      short_previous_month
		      total_cash
		     );

    @percent_keys = qw(
		       52_week_change
		       52_week_change_sp500
		       dividend_yield
		       operating_margin
		       profit_margin
		       return_on_assets
		       return_on_equity
		       short_percent
		       );

    if ($self->{'expand_numbers'} || $self->{'expand'}) {
	for $key (@number_keys) {
	    $dollar = (($res->{$key} =~ s/^\$//) ? '$' : '');  ## save dollar sign'

	    if ($res->{$key} =~ s/(K|M|B|T)$//) { 
		$res->{$key} *= $factors{$1};
	    }
	    
	    if ($self->{'dollar_symbol'}) {
		$res->{$key} = $dollar . $res->{$key};
	    }
	}
    }

    if ($self->{'expand_percent'} || $self->{'expand'}) {
	for $key (@percent_keys) {
	    if ($res->{$key} =~ s/^([\+\-\d\.]+)%$/$1/) { 
		$res->{$key} /= 100;
	    }
	}
    }
}


1;

__END__

=head1 NAME

Finance::YahooProfile - Get a stock profiles from Yahoo!

=head1 SYNOPSIS

  use Finance::YahooProfile;
  my $fyp = new Finance::YahooProfile ( timeout => $timeout );
  my $profile  = $fyp->profile( s => 'intc' );               ## for single stock
  my @profiles = $fyp->profile( s => ['intc', 'ibm'] );      ## for many stocks
  my $bookvalue = $res->{'book_value'};

=head1 DESCRIPTION

WARNING:  This module has not been fully tested all sorts of stocks so 
it may NOT always parse the page correctly and return any useful information.
Any version number ending in a letter (as in v.0.12b, 0.12c) is a beta versions 
and have barely been tested. These versions are simply the previous version
with a slight bug fix of some sort.

This module accesses the company profile from Yahoo! Finance and extracts
the numbers from there so that they can be easily used in Perl programs.
The following keys are available in the results hash:

  52_week_change            52-Week percent change
  52_week_change_sp500      52-Week percent change relative to the S&P 500
  52_week_high              52-Week high
  52_week_high_date         Date on which 52-Week high was reached
  52_week_low               52-Week low
  52_week_low_date          Date on which 52-Week high was reached
  beta                      Beta relative to S&P 500
  current_ratio             Current ratio (Current Assets / Current Liabilities)
  daily_volume_10da         Average of the last 10 days' trading volume
  daily_volume_3ma          Average of the last 3 months trading volume
  debt_equity               Debt / Equity
  dividend                  Amount of the last dividend paid
  dividend_yield            Yield of the last dividend
  fiscal_year_ends          End of fiscal year
  last_split_date           Date of the last split
  last_split_factor         Factor of the last split (e.g. 2 for 1)
  last_updated              Date when profile was last updated
  market                    Market on which the stock is traded
  market_capitalization     Market capitalization (Stock Price x Shares Outstanding)
  most_recent_quarter
  most_recent_quarter_fe    Most recent quarter - flash earnings (if available)
  operating_margin          Operating Margin (Earnings / Operating Expenses)
  profit_margin             Profit Margin (Earnings / Total Expenses)
  recent_price              Price at which the stock was last traded
  return_on_assets          Return on assets (Earnings / Total Assets)
  return_on_equity          Return on equity (Earnings / Shareholder's Equity)
  sales                     Sales from the income statement part (usually ttm)
  shares_float              Number of shares freely trading in the markets
  shares_outstanding        Total number of shares issued
  short_daily_volume        
  short_interest            Number of shares sold short
  short_interest_date
  short_percent             Short Interest / Floating Shares
  short_previous_month      Short Interest previous month
  short_ratio               
  success                   Whether the parsing was a success
  symbol
  total_cash                Total current assets in the balance sheet


=head1 Methods
=over 2

=item new(%parameters)

Creates a new Finance::YahooProfile object.  Currently there are two
options you can pass to it:

  $fyp = new Finance::YahooProfile( expand => 0|1,
                                    dollar_symbol => 0|1
                                  );

  expand_number => If this option is set, number such as 3.14M will be
                converted to 3140000 before being passed back.
  expand_percent=> Something like 5.56% will be converted to 0.056
  expand => sets both expand_number and expand_percent

  dollar_symbol => If you set expand to true, then this flag will
            determine whether the dollar symbol is kept in numbers
            such as $3.14M => $3140000.

=head1 FAQ

None.

=head1 VERSION HISTORY

0.1    -          -  Initial Release.
0.11   -          -  Slight Changes
0.11b  - 02/08/02 -  Stopped parsing if the ticker symbol did not return valid
                     a profile page.  Added the 'success' and 'requested_symbol'
                     keys to $res.
                     Changed regex match for short_daily_volume from (.+)
                     to ([\d\.KMB]) since the old regex did not work for
                     ADRs like BF.
0.12   - 05/01/02 -  Added conversion of percents to decimals in _expand()  (5.82% => 0.0582)
                     The options are now 'expand_number' for numerical expansion (K,M,B) and 
                     'expand_percent' for decimal conversion or simply 'expand' for both.
                  

=head1 COPYRIGHT

Copyright 2002, Sidharth Malhotra

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

The information that you obtain with this library may be copyrighted
by Yahoo! Inc., and is governed by their usage license.  See
http://www.yahoo.com/docs/info/gen_disclaimer.html for more
information.

=head1 AUTHOR

Sidharth Malhotra (C<smalhotra@redeyetg.com>), Redeye Technology Group.
Thanks to Ivo Welch for finding bugs and suggesting several improvements.

=head1 SEE ALSO

The Finance::YahooProfile home page will eventually be up at:
http://www.redeyetg.com/projects/YahooProfile/

The Finance::YahooQuote home page can be found at
http://www.padz.net/~djpadz/YahooQuote/
I used a lot from Finance::YahooQuote to build this module.  LWP code,
pod etc.

=cut
