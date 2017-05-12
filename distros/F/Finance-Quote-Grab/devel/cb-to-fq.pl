#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Carp;
use Finance::Quote;

my $cb = 'http://www.cbwiki.net/wiki/index.php/Specification_1.1';
my $dc = 'http://purl.org/dc/elements/1.1/';
my $dcterms = 'http://purl.org/dc/terms/';

use constant::defer XMLRSS_CLASS => sub {
  my @errors;
  require Module::Load;
  my @classes = ('XML::RSS::LibXML',
                 # 'XML::RSS'  # not quite right on nested stuff?
                );
  foreach my $class (@classes) {
    if (eval { Module::Load::load ($class); 1 }) {
      return $class;
    }
    push @errors, $@;
  }
  croak "Cannot load ",join(" or ",@classes),"\n",@errors,"  ";
};

sub quotes_from_cbrss {
  my ($fq, $quotes, $str, %option) = @_;

  my $source = $option{'source'} || (caller)[0];
  my $symbol_list = $option{'symbol_list'};
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'method'}  = $option{'method'};
    $quotes->{$symbol,'source'}  = $source;
    $quotes->{$symbol,'success'} = 0;
  }

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  my $feed = XMLRSS_CLASS()->new;
  if (! eval { $feed->parse($str); 1 }) {
    my $err = $@;
    $err =~ s/^\n+//;  # spurious leading newlines from XML::RSS
    _errormsg ($quotes, $symbol_list, "XML parse error $err");
    return;
  }
  print Data::Dumper->new([$feed],["feed"])
    ->Useqq(1)->Indent(1)->Dump;

  my $copyright_url = $feed->{'channel'}->{$dcterms}{'license'};

  foreach my $item (@{$feed->{'items'}}) {
    my $statistics = $item->{$cb}{'statistics'} || next;
    my $exchangeRate = $statistics->{$cb}{'exchangeRate'} || next;

    my $from = $exchangeRate->{$cb}{'baseCurrency'};
    my $to   = $exchangeRate->{$cb}{'targetCurrency'};
    $to =~ s/_.*//;  # fix RBA "TWI_4pm"
    my $symbol = $from . $to;
    if (! exists $want_symbol{$symbol}) { next; } # unwanted item

    # stringize XML::RSS::LibXML::MagicElement
    # ENHANCE-ME: apply unit_mult ?
    my $value = $exchangeRate->{$cb}{'value'};
    $quotes->{$symbol,'last'} = "$value";

    if (defined (my $rateType = $exchangeRate->{$cb}{'rateType'})) {
      $quotes->{$symbol,'cb_rate_type'} = $rateType;
    }

    # is this any good ?
    if (defined (my $observationPeriod
                 = $exchangeRate->{$cb}{'observationPeriod'})) {
      if (defined (my $frequency = $observationPeriod->{'frequency'})) {
        $quotes->{$symbol,'cb_observation_frequency'} = $frequency;
      }
    }

    if (defined $copyright_url) {
      $quotes->{$symbol,'copyright_url'} = $copyright_url;
    }

    my ($date, $time) = _dc_date_parse ($item->{$dc}{'date'});
    $fq->store_date($quotes, $symbol, {isodate => $date});
    if (defined $time) {
      $quotes->{$symbol,'time'} = $time;
    }

    #     my $desc = $item->{'description'};
    #     if ($desc =~ /(\d+ pm)/) {
    #       $quotes->{$symbol,'time'} = $fq->isoTime($1);
    #     }
    # $quotes->{$symbol}{'name'} = $item->{'description'};
    $quotes->{$symbol}{'success'} = 1;
    $seen_symbol{$symbol} = 1;
  }

  delete @want_symbol{keys %seen_symbol}; # hash slice
  # any not seen
  _errormsg ($quotes, [keys %want_symbol], 'No such symbol');
}

sub _errormsg {
  my ($quotes, $symbol_list, $errormsg) = @_;
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'errormsg'} = $errormsg;
  }
}

# eg. "2006-12-19"
#     "2006-12-19T19:20+01:00"
# return ($date, $time) or ($date, undef), or empty ()
# ENHANCE-ME: should do something with the timezone
#
sub _dc_date_parse {
  my ($str) = @_;
  $str =~ /^(\d{4}-\d{2}-\d{2})(T(\d{2}:\d{2}(:\d{2})?))?/ or return;
  return ($1, $3);
}

#----------

{ local $,=' ';
  print  _dc_date_parse("2006-12-19T19:20+01:00"),"\n";
  print  _dc_date_parse("2006-12-19"),"\n";
}


use File::Spec;
use FindBin;
my $progname = $FindBin::Script;
my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);

require Perl6::Slurp;
my $xml = Perl6::Slurp::slurp
  (File::Spec->catfile ($topdir, 'samples', 'rba',
                        'rss-cb-exchange-rates.xml'));

print XMLRSS_CLASS(), " ", XMLRSS_CLASS()->VERSION,"\n";

require Finance::Quote;
my $fq = do {
  local $ENV{'FQ_LOAD_QUOTELET'} = '';
  Finance::Quote->new;
};

my %quotes;
quotes_from_cbrss ($fq, \%quotes, $xml,
                   method => 'rba',
                   symbol_list => ['AUDUSD']);
require Data::Dumper;
print Data::Dumper->new([\%quotes],['quotes'])->Useqq(1)->Sortkeys(1)->Indent(1)->Dump;
