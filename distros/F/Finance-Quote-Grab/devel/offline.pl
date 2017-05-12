#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2014, 2015 Kevin Ryde

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
use File::Spec;

use FindBin;
my $progname = $FindBin::Script;


{
  require HTTP::Request;
  require HTTP::Response;
  require Perl6::Slurp;
  my $symbol = 'AUDPHP';

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
  my $content = Perl6::Slurp::slurp
    (File::Spec->catfile ($topdir, 'samples', 'rba',
                          'exchange-rates.html.5'));
  $resp->content($content);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  require Finance::Quote;
  my $fq = Finance::Quote->new ('RBA');
  my %quotes;
  Finance::Quote::RBA::_parse ($fq, $resp, \%quotes, [$symbol]);

  require Data::Dumper;
  print Data::Dumper->new([\%quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}

{
  require HTTP::Request;
  require HTTP::Response;
  require Perl6::Slurp;
  my $symbol = 'Property Securities Fund,MasterKey Superannuation (Gold Star)';

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
  my $content = Perl6::Slurp::slurp
    (File::Spec->catfile ($topdir, 'samples', 'mlc',
                          'mlc.data'
                          # 'quote.html'
                         ));
  $resp->content($content);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  require Finance::Quote;
  my $fq = Finance::Quote->new ('MLC');
  my %quotes;
  Finance::Quote::MLC::resp_to_quotes ($fq, $resp, \%quotes, $symbol);

  require Data::Dumper;
  print Data::Dumper->new([\%quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}

{
  require HTTP::Request;
  require HTTP::Response;
  require Perl6::Slurp;
  # my @symbol_list = ('MWZ9'); my $filename = 'wquotes_js.js.1';
  my @symbol_list = ('IHZ9'); my $filename = 'aquotes.htx.3';

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
  my $content = Perl6::Slurp::slurp
    (File::Spec->catfile ($topdir, 'samples', 'mgex', $filename));
  $resp->content($content);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  my %quotes;
  require Finance::Quote;
  my $fq = Finance::Quote->new ('MGEX');
  Finance::Quote::MGEX::resp_to_quotes ($fq, $resp, \%quotes, \@symbol_list);

  require Data::Dumper;
  print Data::Dumper->new([\%quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}




{
  require HTTP::Request;
  require HTTP::Response;
  require Perl6::Slurp;
  my $symbol = 'MNG';

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
  my $content = Perl6::Slurp::slurp
    (File::Spec->catfile ($topdir, 'samples', 'casab',
                          'Donnes_valeurs.asp-MNG.html'));
  $resp->content($content);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  my %quotes;
  require Finance::Quote;
  my $fq = Finance::Quote->new ('Casablanca');
  Finance::Quote::Casablanca::resp_to_quotes ($fq, $symbol, $resp, \%quotes);

  require Data::Dumper;
  print Data::Dumper->new([\%quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}



