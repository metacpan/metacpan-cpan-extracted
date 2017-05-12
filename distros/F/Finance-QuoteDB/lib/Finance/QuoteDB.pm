package Finance::QuoteDB;

use warnings;
use strict;

use Exporter ();
use vars qw/@EXPORT @EXPORT_OK @EXPORT_TAGS $VERSION/;
use Finance::Quote;

# Bug correction in Finance::QuoteHist
# reported on RT #64365
# This block can safely be removed once Finance::QuoteHist is corrected
BEGIN {
$Date::Manip::Backend = 'DM5';
}

use Finance::QuoteHist;
use LWP::UserAgent;
use HTML::TableExtract;

require Finance::QuoteDB::Geniustrader;

use Log::Log4perl qw(:easy);

=head1 NAME

Finance::QuoteDB - User database tools based on Finance::Quote

=cut

@EXPORT = ();
@EXPORT_OK = qw /createdb updatedb addstock/ ;
@EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $VERSION = '0.18'; # VERSION

=head1 SYNOPSIS

Please take a look at script/fqdb which is the command-line frontend
to Finance::QuoteDB. Type following command at your command prompt for
more information:

    fqdb --help

=head1 METHODS

=head2 new

new({dsn=>$dsn})

=cut

sub new {
  my $self = shift;
  my $class = ref($self) || $self;

  my $this = {} ;
  bless $this, $class;

  my $config = shift ;

  foreach (keys %$config) {
    $this->{$_} = $$config{$_};
  }
  $this->{logger} = Log::Log4perl::get_logger();
  if ($ENV{"FQDBDEBUG"}) { # enable debug logging if FQDBDEBUG is set
    $this->{logger}->level($DEBUG)
  } else {
    $this->{logger}->level($INFO)
  } ;
  if (my $dsn = $this->{dsn}) {
    INFO ("CREATED FQDB object based on $dsn\n");
  } else {
    ERROR ("No dsn specified\n") ;
    die;
  }

  return $this;
}

=head2 createdb

createdb()

=cut

sub createdb {
  my $self = shift;

  my $dsn = $self->{dsn};
  my $dsnuser = $self->{dsnuser};
  my $dsnpasswd = $self->{dsnpasswd};

  INFO ("COMMAND: Create database $dsn with user $dsnuser\n");
  my $schema = Finance::QuoteDB::Schema->connect_and_deploy($dsn,$dsnuser,$dsnpasswd); # creates the database
  return $schema;
}

=head2 updatedb

updatedb()

=cut

sub updatedb {
  my $self = shift ;

  my $dsn = $self->{dsn};
  INFO ("COMMAND: Update database $dsn\n");

  my $schema = $self->schema();
  my @stocks = $schema -> resultset('Symbol')->
    search(undef, { order_by => "fqmarket,fqsymbol",
                    columns => [qw / symbolID fqmarket fqsymbol /] });
  my %symbolIDs ;
  my %fqsymbols ;
  foreach my $stock (@stocks) {
    my $fqmarket = $stock->fqmarket()->name() ;
    my $symbolID = $stock->symbolID() ;
    my $fqsymbol = $stock->fqsymbol() ;
    ${$symbolIDs{$fqmarket}}{ $fqsymbol } = $symbolID ;
    print ("SCANNING : $fqmarket - $fqsymbol -> $symbolID\n");
  };
  foreach my $market (keys %symbolIDs) {
    DEBUG "$market -->" .join( "," , keys(%{$symbolIDs{$market}}) ) ."\n" ;
    $self->updatedbMarketStock ( $market , \%{$symbolIDs{$market}} ) ;
  }
}

=head2 updatedbMarketStock

updatedbMarketStock($market,\%symbolIDs)

=cut

sub updatedbMarketStock {
  my ($self,$market,$stockHash) = @_ ;
  my $schema = $self->schema();
  my @fqsymbols = keys(%{$stockHash}) ;
  DEBUG "UPDATEDBMARKETSTOCK: $market -->" .join(",",@fqsymbols)."\n" ;
  my $q = Finance::Quote->new();
  my %quotes = $q->fetch($market,@fqsymbols);
  foreach my $stock (@fqsymbols) {
    if ($quotes{$stock,"success"}) { # This quote was retrieved
      my $symbolID = ${$stockHash}{$stock} ;
      print ("Updating stock $stock ($symbolID) --> $quotes{$stock,'last'}\n");
      my $quoters = $schema->resultset('Quote')->update_or_create(
        { symbolID => $symbolID,
          date => $quotes{$stock,'isodate'},
          previous_close => $quotes{$stock,'close'},
          day_open => $quotes{$stock,'open'},
          day_high => $quotes{$stock,'high'},
          day_low => $quotes{$stock,'low'},
          day_close => $quotes{$stock,'last'},
          bid => $quotes{$stock,'bid'},
          ask => $quotes{$stock,'ask'},
          volume => $quotes{$stock,'volume'}
        });
    } else {
      print ("Could not retrieve $stock\n");
    }
  }
};

=head2 backpopulate

backpopulate($start_date, $end_date, $overwrite, $stocks)

=cut

sub backpopulate {
  my ($self, $start_date, $end_date, $overwrite, $stocks) = @_;
  $end_date = $self->today() if (!$end_date);
  if (my @symbolIDs = split(",",$stocks)) {
    print ("Retrieving data...\n");
    my $schema = $self->schema();
    my %symbolID ;
    foreach my $symbolID (@symbolIDs) {
      my $fqsymbol = $schema -> resultset('Symbol')->single({symbolID => $symbolID})->fqsymbol() ;
      $symbolID{$fqsymbol} = $symbolID ;
    }
    my @fqsymbols = keys (%symbolID);

    my $q = Finance::QuoteHist->new( symbols => \@fqsymbols,
                                     start_date => $start_date,
                                     end_date => $end_date );
    my $line = "" ;
    my %symbols ;
    foreach my $row ($q->quotes()) {
      my ($fqsymbol, $date, $open, $high, $low, $close, $volume) = @$row;
      $date =~ tr|/|-|;
      my $tline = substr($date,0,7) ;
      if ($line ne $tline) {
        INFO ("$tline") ;
        %symbols = () ;
      };
      $line = $tline ;
      if (!$symbols{$fqsymbol}) {
        $symbols{$fqsymbol}=1;
        INFO (" -> $fqsymbol") ;
      }
      my %data = ( symbolID => $symbolID{$fqsymbol},
                   date => $date,
                   day_open => $open,
                   day_high => $high,
                   day_low => $low,
                   day_close => $close,
                   volume => $volume
                 ) ;
      if ($overwrite) {
        $schema->resultset('Quote')->update_or_create( \%data ) ;
      } else {
        $schema->resultset('Quote')->find_or_create( \%data ) ;
      }
    }
  }
}

=head2 delstock

delstock($stocks)

=cut

sub delstock {
  my ($self,$stocks) = @_ ;

  if (my @stocks = split(",",$stocks)) {
    my $schema = $self->schema();
    foreach my $stock (@stocks) {
      print ("Deleting stock $stock\n");
      my $rs = $schema -> resultset('Symbol')->
        search({'symbolID' => $stock});
      $rs->delete_all();
    }
  } else {
    print ("No stocks specified\n") ;
  }
};

=head2 addstock

addstock($market,$stocks)

$stocks is in the format FQsymbol[USERsymbol],...
If USERsymbol is ommitted then USERsymbol will be set to FQsymbol

=cut

sub addstock {
  my ($self,$market,$stocks) = @_ ;

  if (!$market) {
    print ("No market specified\n") ;
    return
  } else {
    print ("Getting stocks from $market\n") ;
  }
  if (my @stocks = split(",",$stocks)) {
    my %symbolIDs ;
    foreach my $stockItem (@stocks) {
      if ( $stockItem =~ m/([^\[]+)(\[(.+)\])?/ ) {
        my ($fqsymbol,$symbolID) = ($1,$3) ;
        $symbolID = $fqsymbol if (!$symbolID) ;
        INFO (" Stock $fqsymbol <- $symbolID") ;
        $symbolIDs{$fqsymbol}=$symbolID ;
      }
    }
    my @fqsymbols = keys %symbolIDs ;
    my $q = Finance::Quote->new();
    my %quotes = $q->fetch($market,@fqsymbols);
    foreach my $stock (@fqsymbols) {
      print ("Checking stock $stock\n");
      if ($quotes{$stock,"success"}) { # This quote was retrieved
        print (" --> $quotes{$stock,'name'}\n") ;
        my $schema = $self->schema();
        my $marketID = $schema->resultset('FQMarket')->find_or_create({name=>$market})->marketID();
        $schema->populate('Symbol',
                          [[qw /symbolID name fqmarket fqsymbol isin currency/],
                           [$symbolIDs{$stock}, $quotes{$stock,'name'}, $marketID, $stock, '', $quotes{$stock,'currency'} ]]);
      } else {
        print ("Could not retrieve $stock\n");
      }
    }
  } else {
    print ("No stocks specified\n") ;
  }
};

=head2 getquotes

getquotes( $USERsymbols, $date_start [,$date_end] )

This function returns quotes between $date_start and $date_end for the specified
user symbols (comma separated list).  Range will be one day if $date_end is
omitted.

=cut

sub getquotes {
  my ($self,$USERsymbol,$date_start,$date_end) = @_ ;
  $date_end = $date_start if !($date_end) ;
  my $schema = $self->schema();

  my @q = $schema->resultset('Quote')
    ->search( { symbolID=>$USERsymbol,
                date=>{'BETWEEN',[$date_start, $date_end]} },
              { columns=> [qw/ date day_open day_high day_low day_close volume /],
                order_by=> [qw/ date /] });
  @q ? return \@q : 0 ;
}

=head2 dumpquotes

dumpquotes ( $USERsymbols, $date_start [,$date_end] )

This function dumps quotes between $date_start and $date_end for the specified
user symbols (comma separated list).  Range will be one day if $date_end is
omitted.

=cut

sub dumpquotes {
  my ($self,$USERsymbols,$date_start,$date_end) = @_ ;
  $date_end = $date_start if !($date_end) ;
  my $schema = $self->schema();

  if (my @stocks = split(",",$USERsymbols)) {
    foreach my $USERsymbol (@stocks) {
      if ( my $quotesArray = $self->getquotes ( $USERsymbol, $date_start, $date_end ) ) {
        print "STOCK : $USERsymbol\n";
        print "DATE           OPEN     HIGH      LOW    CLOSE       VOLUME\n" ;
        foreach my $q (@$quotesArray) {
          printf "%10s %8.2f %8.2f %8.2f %8.2f %12d\n",
            $q->date(), $q->day_open(), $q->day_high(), $q->day_low(), $q->day_close(), $q->volume() ;
        }
      } else {
        print "NO DATA for stock $USERsymbol\n";
      }
    }
  }
}

=head2 dumpstocks

dumpstocks ()

This function dumps the symbols of the stocks in the database.

=cut

sub dumpstocks {
  my $self = shift ;

  my $dsn = $self->{dsn};
  INFO ("COMMAND: Dump stocks in database $dsn\n");

  my $schema = $self->schema();
  my @stocks = $schema -> resultset('Symbol')->
    search(undef, { order_by => "symbolID,fqmarket,fqsymbol",
                    columns => [qw / symbolID fqmarket fqsymbol /] });
  print "     USERSYMBOL       FQMARKET         FQSYMBOL\n";
  foreach my $stock (@stocks) {
    my $fqmarket = $stock->fqmarket()->name() ;
    my $symbolID = $stock->symbolID() ;
    my $fqsymbol = $stock->fqsymbol() ;
    printf "%15s %15s %15s\n",$symbolID,$fqmarket,$fqsymbol;
  };
}

=head2 add_yahoo_stocks

add_yahoo_stocks( $exchanges , [ $refsearchlist ] )

retrieves yahoo tickers for specified exchanges and stores them in your database
NOTE: $exchanges being the ID as coming from yahoo.
      NYQ for Nyse, PAR for Paris
$refsearchlist is an optional reference to a list of search patterns. defaults to [**AA .. **ZZ]

=cut

sub add_yahoo_stocks {
  # http://uk.biz.yahoo.com/p/uk/cpi/index.html -> list of european stocks
  my ($self,$exchanges,$refsearchlist) = @_ ;
  my $popquantity = 30 ; # number of stocks to add in 1 call of addstock

  if (!defined($exchanges)) {
    ERROR ("No exchanges specified");
  } else {
    my %exchanges ;
    foreach (split(',',$exchanges)) {
      $exchanges{$_}=1 ;
    }  ;

    no strict 'subs' ;
    if (!@$refsearchlist) {
      $refsearchlist = [AA .. ZZ] ;
      $$refsearchlist[$_] = "**".$$refsearchlist[$_] foreach (0 .. $#{@$refsearchlist}) ; # add ** in front of each list item
    }
    DEBUG ("$_") foreach (@$refsearchlist);

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    INFO("Adding symbols from $exchanges.") ;

    my %symbols ;

    foreach my $letter (@$refsearchlist) {
      my $yahoo_url = "http://finance.yahoo.com/lookup?s=$letter&t=S" ; # t=S means ONLY stocks

      my $b = 0 ; # counter in url
      my $cont ;
      do {
        $cont = 1; # continue increasing b
        my $url = $yahoo_url."&b=".$b ;
        DEBUG("URL: $url");
        my $req = HTTP::Request->new(GET => $url);
        my $reply = $ua->request($req);
        if ($reply->is_success) {
          my ($from,$to,$total)=(0,0,0) ;
          if ($reply->content=~ m|Showing\s+(\d)+ - (\d+) of\s+(\d+)|) { # check if this is last page for this market
            ($from,$to,$total)=($1,$2,$3);
            INFO ("For $letter: ".int($to*100/$total)." % completed");
            $b=$to; # next page should start at this symbol. actually starts at symbol+1
            $cont = ($to < $total);
          }
          # scrape the symbols from this page
          my $te = HTML::TableExtract->new( headers=>[qw /Symbol Exchange/ ] );
          $te->parse($reply->content);
          foreach my $ts ($te->tables) {
            my $countrows = 0;
            foreach my $tr ($ts->rows) {
              $countrows++;
              my $trsymb = @$tr[0] ;
              $trsymb =~ s/ //g ;
              my $exchsym = @$tr[1] ;
              $exchsym =~ s/ //g ;
              if (defined($exchanges{$exchsym})) {
                INFO (" Symbol: $trsymb - Exchange $exchsym");
                $symbols{$trsymb}+=1 ;                           # add the symbol as a key in the hash removes duplicates automatically
              }
            }
            DEBUG ("--> $countrows rows");
            if ($countrows && ($total==0)) {                  # there are rows on this page and we are on the last page (no total)
              INFO ("For $letter: 100 % completed");
              $cont=0 ;
            }
          }
        }
        if ($cont) {
          my $sleeptime = int(15+rand(5)) ;
          INFO("Sleeping $sleeptime");
          sleep $sleeptime;                                      # needed otherwise we might overload yahoo server
        }
      } while ($cont);
    }

    my @symbols = sort keys %symbols ;
    while ($#symbols>0) {                                      # still elements in the array
      my $sleeptime = int(10+rand(10)) ;
      INFO("Sleeping $sleeptime");
      sleep $sleeptime;                                        # needed otherwise we might overload yahoo server
      my $stocks = join (",",splice(@symbols,0,$popquantity)); # take $popquantity number of elements out
      # my $stocks = join (",",@symbols[0..$popquantity-1]);
      # @symbols = @symbols[$popquantity+1..$#symbols-1];
      INFO (" Adding stocks: $stocks");
      $self->addstock('yahoo',$stocks);                        # add stocks in database
    }
  }
  INFO("Finished adding stocks from yahoo");
}

=head2 schema

schema()

If necessary, creates a DBIx::Class::Schema and returns a reference to that DBIx::Class::Schema.

=cut

sub schema {
  my $self = shift ;
  my $dsn = $self->{dsn};
  my $dsnuser = $self->{dsnuser};
  my $dsnpasswd = $self->{dsnpasswd};
  if (!$self->{schema}) {
    if (my $schema = Finance::QuoteDB::Schema->connect($dsn,$dsnuser,$dsnpasswd)) {
      INFO ("Connected to database $dsn\n");
      $self->{schema} = $schema ;
    } else {
      ERROR ("Could not connect to database $dsn\n") ;
      die ;
    }
  }
  return $self->{schema}
}

=head2 today

today()

returns current date in isodate format

=cut

sub today {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  return ($year+1900)."-".sprintf('%02d',$mon+1)."-".sprintf('%02d',$mday) ;
}

=head1 AUTHOR

Erik Colson, C<< <eco at ecocode.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-quotedb at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-QuoteDB>.  I will be
notified, and you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::QuoteDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-QuoteDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-QuoteDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-QuoteDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-QuoteDB>

=item * Mailing list

You can subscribe to the mailing list by sending an email to
fqdb@lists.tuxfamily.org with subject : subscribe

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 Erik Colson, all rights reserved.

This file is part of Finance::QuoteDB.

Finance::QuoteDB is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Finance::QuoteDB is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with Finance::QuoteDB.  If not, see
<http://www.gnu.org/licenses/>.

=cut

1; # End of Finance::QuoteDB
