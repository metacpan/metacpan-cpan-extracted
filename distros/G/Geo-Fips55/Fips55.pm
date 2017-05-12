package Geo::Fips55;

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
    state_fips	=> {
	beg => 1, end => 2, len => 2, type => "N", 
	description => "FIPS State Code" },
    place_fips	=> {
	beg => 3, end => 7, len => 5, type => "N", 
	description => "FIPS Place Code" },
    state	=> {
	beg => 8, end => 9, len => 2, type => "A",
	description => "State Alpha Code" },
    num_counties => {
	beg => 10, end => 11, len => 2, type => "N", 
	description => "Total Number of Counties" },
    crsn => {
	beg => 12, end => 13, len => 2, type => "N", 
	description => "County Record Sequence Number" },
    class => {
	beg => 14, end => 15, len => 2, type => "A", 
	description => "Class Code" },
    name => {
	beg => 16, end => 67, len => 52, type => "A", 
	description => "Place Name" },
    county_fips => {
	beg => 68, end => 70, len => 3, type => "N", 
	description => "FIPS County Code" },
    county => {
	beg => 71, end => 92, len => 22, type => "A",
	description => "Name of County" },
    part_of => {
	beg => 93, end => 97, len => 5, type => "N",
	description => "Part of Code" },
    other_name => {
	beg => 98, end => 102, len => 5, type => "N",
	description => "Other Name Code" },
    zip => {
	beg => 103, end => 107, len => 5, type => "N",	
	description => "Zip Code" },
    postal_match => {
	beg => 108, end => 109, len => 2, type => "A",
	description => "Postal Name Match" },
    zip_range => {
	beg => 110, end => 111, len => 2, type => "N",
	description => "Zip Code Range" },
    gsa => {
	beg => 112, end => 115, len => 4, type => "N",
	description => "GSA Code" },
    mrf => {
	beg => 116, end => 119, len => 4, type => "N",
	description => "MRF Code" },
    msa => {
	beg => 120, end => 123, len => 4, type => "N",
	description => "MSA Code" },
    cd1 => {
	beg => 124, end => 125, len => 2, type => "N",
	description => "Congressional District 1" },
    cd2 => {
	beg => 126, end => 127, len => 2, type => "N",
	description => "Congressional District 2" },
    cd3 => {
	beg => 128, end => 129, len => 2, type => "N",
	description => "Congressional District 3" },
    cd4 => {
	beg => 130, end => 131, len => 2, type => "N",
	description => "Congressional District 4" },
    cd5 => {
	beg => 132, end => 133, len => 2, type => "N",
	description => "Congressional District 5" },
    cd6 => {
	beg => 134, end => 135, len => 2, type => "N",
	description => "Congressional District 6" },
    cd7 => {
	beg => 136, end => 137, len => 2, type => "N",
	description => "Congressional District 7" },
    cd8 => {
	beg => 138, end => 139, len => 2, type => "N",
	description => "Congressional District 8" },
    cd9 => {
	beg => 140, end => 141, len => 2, type => "N",
	description => "Congressional District 9" },
    cd10 => {
	beg => 142, end => 143, len => 2, type => "N",
	description => "Congressional District 10" },
    cd11 => {
	beg => 144, end => 145, len => 2, type => "N",
	description => "Congressional District 11" },
    cd12 => {
	beg => 146, end => 147, len => 2, type => "N",
	description => "Congressional District 12" },
    cd13 => {
	beg => 148, end => 149, len => 2, type => "N",
	description => "Congressional District 13" },
    cd14 => {
	beg => 142, end => 143, len => 2, type => "N",
	description => "Congressional District 14" },
);

my %Data_Dict = ();
my @Data_Fields = ();
my $fieldnum = 1;

while (my ($field, $args) = splice(@Proto_Dict, 0, 2)) {
    $Data_Dict{$field} = { 
	fieldnum => $fieldnum++, bv => "Yes", field => $field,
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

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Fips55 - Perl extension for parsing FIPS-55 gazetteer data

=head1 SYNOPSIS

  use Geo::Fips55;

  @records = Geo::Fips55->parse_file( $filehandle );
  
  Geo::Fips55->parse_file( $filehandle, \&callback );

  $record = Geo::Fips55->new( \%data );

  $record->state_fips();
  $record->place_fips();
  $record->state();
  $record->num_counties();
  $record->crsn();
  $record->class();
  $record->name();
  $record->county_fips();
  $record->county();
  $record->part_of();
  $record->other_name();
  $record->zip();
  $record->postal_match();
  $record->zip_range();
  $record->gsa();
  $record->mrf();
  $record->msa();
  $record->cd1(); # and so on up to cd14()

=head1 DESCRIPTION

Geo::Fips55 provides a representation of the US Geological Survey FIPS-55
gazetteer format.  Each object is one record.  It also contains methods
to parse FIPS-55 data files and turn them into objects.

This is intended as an intermediate format between pulling the raw
data out of the simplistic FIPS-55 data files into something more
sophisticated (a process you should only have to do once).  As such,
its not very fast, but its careful, easy to use and performs some
verifications on the data being read.

This module subclasses Michael Schwern's very nice Geo::TigerLine modules
to do all the heavy lifting.

=head1 BUGS, CAVEATS, ETC.

This module wasn't automatically generated like the
Geo::TigerLine::Record::* modules were. Probably it should have been,
but the FIPS data record layout changes even less often than the TIGER
data -- the last revision to the FIPS-55 spec was in 1994. If it ever
gets revised, I will gladly update this module by hand.

=head1 SEE ALSO

You can learn more about the FIPS-55 standard and download the entire
US geographic names database from L<http://geonames.usgs.gov/fips55.html>.

Geo::TigerLine(3pm)

=head1 AUTHOR

Schuyler D. Erle <schuyler@nocat.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Schuyler D. Erle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
