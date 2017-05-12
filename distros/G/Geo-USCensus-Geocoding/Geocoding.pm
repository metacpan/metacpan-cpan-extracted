package Geo::USCensus::Geocoding;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use Geo::USCensus::Geocoding::Result;
use Text::CSV;

=head1 NAME

Geo::USCensus::Geocoding - The U.S. Census Bureau geocoding service

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $DEBUG = 0;

=head1 SYNOPSIS

    use Geo::USCensus::Geocoding;

    my $request = {
      # required fields
      street  => '123 Main Street',
      city    => 'San Francisco',   # city
      state   => 'CA',              # state
      # optional fields
      zip     => '93102',           # zip code
      benchmark => 'Public_AR_ACS2013', # default is "Public_AR_Current"
      vintage   => 'Census2010_ACS2013', # default is "Current_Current"

      debug => 1,                   # will print the URL and some other info
    };
    my $result = Geo::USCensus::Geocoding->query($request);

    if ($result->is_match) {
      print $result->address,"\n",
            $result->latitude,", ",$result->longitude,"\n",
            $result->censustract,"\n";
    } else {
      print "No match.\n";
    }

=head1 CLASS METHODS

=head2 query HASHREF

Send a request to the web service.  See
L<http://geocoding.geo.census.gov/geocoder> for API documentation. This 
package will always use the batch method (which seems to be more reliable,
as of 2015) and the Geographies return type.

Returns an object of class Geo::USCensus::Geocoding::Result.

=cut

my $ua = LWP::UserAgent->new;
my $url = 'http://geocoding.geo.census.gov/geocoder/geographies/addressbatch';

my $csv = Text::CSV->new({eol => "\n", binary => 1});

# for a current list of benchmark/vintage IDs, download
# http://geocoding.geo.census.gov/geocoder/benchmarks
# http://geocoding.geo.census.gov/geocoder/vintages?benchmark=<id>
# with Accept: application/json

sub query {
  my $class = shift;
  my %opt = (
    returntype => 'geographies',
    benchmark => 4, # "Current"
    vintage   => 4, # "Current"
  );
  if (ref $_[0] eq 'HASH') {
    %opt = (%opt, %{ $_[0] });
  } else {
    %opt = (%opt, @_);
  }

  $DEBUG = $opt{debug} || 0;

  my $result = Geo::USCensus::Geocoding::Result->new;

  my @row = ( 1 ); # first element = row identifier
  # at some point support multiple rows in a single query?
  if (!$opt{street}) {
    $result->error_message("Street address is required.");
    return $result;
  }
  if (!$opt{zip} and (!$opt{city} or !$opt{state})) {
    $result->error_message("Either city/state or zip code is required.");
    return $result;
  }
  foreach (qw(street city state zip)) {
    push @row, $opt{$_} || '';
  }

  $csv->combine(@row);
  warn "Sending:\n".$csv->string."\n" if $DEBUG;

  # they are not picky about content types, Accept headers, etc., but
  # the uploaded file must have a _name_.
  my $resp = $ua->request(POST $url,
    'Content_Type'  => 'form-data',
    'Content'       => [ benchmark     => $opt{benchmark},
                         vintage       => $opt{vintage},
                         returntype    => $opt{returntype},
                         addressFile   => [ undef, 'upload.csv',
                                            Content => $csv->string
                                          ],
                       ],
  );
  if ( $resp->is_success ) {
    $result->content($resp->content);
    my $status = $csv->parse($resp->content);
    my @fields = $csv->fields;
    if (!$status or @fields < 3) {
      $result->error_message("Unable to parse response:\n" . $resp->content);
      return $result;
    }
    if ( $fields[2] eq 'Match' ) {
      $result->is_match(1);
      $result->match_level($fields[3]);
      $result->address($fields[4]);
      my ($long, $lat) = split(',', $fields[5]);
      $result->longitude($long);
      $result->latitude($lat);
      $result->state($fields[8]);
      $result->county($fields[9]);
      $result->tract($fields[10]);
      $result->block($fields[11]);
    } else {
      $result->is_match(0);
    }
  } else {
    $result->error_message( $resp->status_line );
  }

  return $result;
}

=head1 AUTHOR

Mark Wells, C<< <mark at freeside.biz> >>

=head1 SUPPORT

Commercial support for this module is available from Freeside Internet 
Services:

    L<http://www.freeside.biz/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Mark Wells.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
