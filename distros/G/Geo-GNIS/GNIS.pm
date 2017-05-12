package Geo::GNIS;

use 5.006;
use strict;
use Carp::Assert;
use base qw(
    Geo::TigerLine::Record::Parser
    Geo::TigerLine::Record::Accessor
    Geo::TigerLine::Record
    Class::Data::Inheritable
);

our $VERSION = '0.01';

# Auto-generated data dictionary.
my @Proto_Dict = (
    fid	=> {
	beg => 1, end => 10, type => "N", description => "Feature ID" },
    state => {
	beg => 11, end => 13, type => "L", description => "State Alpha Code" },
    name => {
	beg => 14, end => 114, type => "L", description => "Feature Name" },
    type => {
	beg => 115, end => 124, type => "L", description => "Feature Type" },
    county => {
	beg => 125, end => 140, type => "L", description => "County" },
    coord => {
	beg => 141, end => 157, type => "L", 
	description => "Geographic Coordinates" },
    cell => {
	beg => 158, end => 182, type => "L", description => "Cell Name" },
    elev => {
	beg => 183, end => 189, type => "N", description => "Elevation" },
    est_pop => {
	beg => 190, end => 197, type => "N", description => "Est. Population" },
    status => {
	beg => 199, end => 207, type => "L",
	description => "Federal Status of Feature Name" },
);

my %Data_Dict = ();
my @Data_Fields = ();
my $fieldnum = 1;

while (my ($field, $args) = splice(@Proto_Dict, 0, 2)) {
    $Data_Dict{$field} = { 
	fieldnum => $fieldnum++, bv => "Yes", field => $field,
	len => $args->{end} - $args->{beg} + 1,
	fmt => ($args->{type} eq "N" ? "R" : "L"),
	%$args
    };
    push @Data_Fields, $field;
}

assert(keys %Data_Dict == @Data_Fields);

# Turn the data dictionary into class data
__PACKAGE__->mk_classdata('Fields');
__PACKAGE__->mk_classdata('Dict');
__PACKAGE__->mk_classdata('Pack_Tmpl');

__PACKAGE__->Dict(\%Data_Dict);
__PACKAGE__->Fields(\@Data_Fields);

# Generate a pack template for parsing and turn it into class data.
my $pack_tmpl = join ' ', map { "A$_" } map { $_->{len} } 
                                          @Data_Dict{@Data_Fields};
__PACKAGE__->Pack_Tmpl($pack_tmpl);

# Generate accessors for each data field
foreach my $def (@Data_Dict{@Data_Fields}) {
    __PACKAGE__->mk_accessor($def);
}

sub lat {
    my $self = shift;
    my ($d, $m, $s, $ns) = $self->coord =~ /(\d\d)(\d\d)(\d\d)([NS])/gos;
    my $lat = $d + $m / 60 + $s / 3600;
    return ($ns eq "N" ? $lat : -$lat);
}

sub lon {
    my $self = shift;
    my ($d, $m, $s, $ew) = $self->coord =~ /(\d\d\d?)(\d\d)(\d\d)([EW])/gos;
    my $lon = $d + $m / 60 + $s / 3600;
    return ($ew eq "W" ? -$lon : $lon);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::GNIS - Perl extension for parsing USGS GNIS gazetteer data

=head1 SYNOPSIS

  use Geo::GNIS;

  @records = Geo::GNIS->parse_file( $filehandle );
  
  Geo::GNIS->parse_file( $filehandle, \&callback );

  $record = Geo::GNIS->new( \%data );

  $record->fid();
  $record->state();
  $record->name();
  $record->type();
  $record->county();
  $record->coord(); # this is raw DMS
  $record->cell();
  $record->elev();
  $record->est_pop();
  $record->status();

  $record->lat(); # decimal degrees
  $record->lon(); # decimal degrees

=head1 DESCRIPTION

Geo::GNIS provides a representation of the US Geological Survey's Geographic
Names Information Service (GNIS) gazetteer format.  Each object is one record.
It also contains methods to parse GNIS Columnar Format data files and turn them
into objects.

This is intended as an intermediate format between pulling the raw
data out of the simplistic GNIS data files into something more
sophisticated (a process you should only have to do once).  As such,
it's not very fast, but it's careful, easy to use, and performs some
verifications on the data being read.

This module subclasses Michael Schwern's very nice Geo::TigerLine modules
to do all the heavy lifting.

=head1 BUGS, CAVEATS, ETC.

This module wasn't automatically generated like the Geo::TigerLine::Record::*
modules were. Probably it should have been, but the GNIS data record layout
changes even less often than the TIGER data. If it ever gets revised, I will
gladly update this module by hand.

Currently, only the population file format is supported.

=head1 SEE ALSO

You can learn all about the Geographic Names Information Service at
L<http://geonames.usgs.gov/>. If you decide to download data for the state or
topical gazetteers from L<http://geonames.usgs.gov/stategaz/>, be sure to
get the so-called B<Columnar Format Files>.

The data dictionary was transcribed from
L<http://geonames.usgs.gov/stategaz/00README.html>.

Geo::TigerLine(3pm), Geo::Fips55(3pm)

=head1 AUTHOR

Schuyler D. Erle <schuyler@nocat.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Schuyler D. Erle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
