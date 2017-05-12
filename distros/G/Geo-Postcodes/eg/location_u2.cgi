#! /usr/bin/perl

use strict;

use Geo::Postcodes::U2 0.30;
use HTML::Entities ();

use CGI ();

print CGI::header(),
      CGI::start_html('-');

if (CGI::param())
{
  my $postcode = CGI::param('postcode');

  if (!Geo::Postcodes::U2::legal($postcode))
  {
    print "<em>Illegal postcode</em>";
  }
  elsif (!Geo::Postcodes::U2::valid($postcode))
  {
    print "<em>Postcode not in use</em>";
  }
  else
  {
    print HTML::Entities::encode(Geo::Postcodes::U2::location_of($postcode));
  }
}

print CGI::end_html(), "\n";
