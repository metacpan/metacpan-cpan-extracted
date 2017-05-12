package Geo::WebService::OpenCellID::cell;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Base};
use Geo::WebService::OpenCellID::Response::cell::get;
use Geo::WebService::OpenCellID::Response::cell::getMeasures;
our $VERSION = '0.05';

=head1 NAME

Geo::WebService::OpenCellID::cell - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use Geo::WebService::OpenCellID;
  my $gwo=Geo::WebService::OpenCellID->new(key=>$apikey);
  my $point=$gwo->cell->get(mcc=>$country,
                            mnc=>$network,
                            lac=>$locale,
                            cellid=>$cellid);
  printf "Lat:%s, Lon:%s\n", $point->latlon;

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 get

Returns a response object L<Geo::WebService::OpenCellID::Response::cell::get>.

  my $response=$gwo->cell->get(key=>$myapikey,
                               mnc=>1,
                               mcc=>2,
                               lac=>200,
                               cellid=>234);

Documentation from: http://www.opencellid.org/api

Get the position of a specific cell http://www.opencellid.org/cell/get?key=myapikey&mnc=1&mcc=2&lac=200&cellid=234 

  Where:
    key: The apikey
    mcc: mobile country code (decimal)
    mnc: mobile network code (decimal)
    lac: locale area code (decimal)
    cellid: value of the cell id 

lac can be ommitted.  However, if cellid is not present or if cellid i unkown, a defaut return will be based on lac information, but with a much lower accuracy. In that case, cellid return will be -1.

The postion is returned in xml format by the web service but this package wraps this return in a blessed object.

Example: http://www.opencellid.org/cell/get?mcc=250&mnc=99&cellid=29513&lac=0 

  <?xml version="1.0" encoding="UTF-8" ?> 
  <rsp stat="ok">
    <cell nbSamples="38"
          lat="57.8240013122559"
          lon="28.00119972229"
          range="6000"
          mcc="250"
          mnc="99"
          lac="0"
          cellId="29513" /> 
  </rsp>

Note: nbSamples=0 is very common!

=cut

sub get {
  my $self=shift;
  return $self->parent->call("cell/get",
                             "Geo::WebService::OpenCellID::Response::cell::get",
                             @_);
}

=head2 getMeasures

Returns a response object L<Geo::WebService::OpenCellID::Response::cell::getMeasures>

  my $response=$gwo->cell->getMeasures(key=>$myapikey,
                                       mnc=>1,
                                       mcc=>2,
                                       lac=>200,
                                       cellid=>234);

  <?xml version="1.0" encoding="UTF-8" ?> 
  <rsp stat="ok">
    <cell nbSamples="1"
          lat="38.865953"
          lon="-77.108595"
          mnc="784"
          mcc="608"
          lac="46156"
          cellId="40072">
      <measure lat="38.865953"
               lon="-77.108595"
               takenOn="Sat Feb 28 06:07:12 +0100 2009"
               takenBy="582" /> 
    </cell>
  </rsp>

=cut

sub getMeasures {
  my $self=shift;
  return $self->parent->call("cell/getMeasures",
                             "Geo::WebService::OpenCellID::Response::cell::getMeasures",
                             @_);
}

=head1 BUGS

Submit to RT and email the Author

=head1 SUPPORT

Try the Author or Try 8motions.com

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
