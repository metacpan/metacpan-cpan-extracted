#! /usr/bin/perl -w

# Toby Thurston -- 20 Jan 2016 
# Parse a National Grid ref and show it as LL coordinates

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/grid_to_ll/;
use Geo::Coordinates::OSGB::Grid qw/random_grid parse_grid/;
use Browser::Open qw(open_browser);

use Getopt::Long;
use Pod::Usage;

our $VERSION = '2.16';

sub format_grid_streetmap {
    my $e = shift;
    my $n = shift;
    return sprintf 'http://www.streetmap.co.uk/map.srf?x=%06d&y=%06d&z=3', $e, $n;
}

sub format_ll_googlemaps {
    my ($lat, $lon) = @_;
    return sprintf 'http://www.google.com/maps/place/@%f,%f,14z/data=!4m2!3m1!1s0x0:0x0', $lat, $lon;
}


my $options_ok = GetOptions(
    
    'version'     => sub { warn "$0, version: $VERSION\n"; exit 0; }, 
    'usage'       => sub { pod2usage(-verbose => 0, -exitstatus => 0) },                         
    'help'        => sub { pod2usage(-verbose => 1, -exitstatus => 0) },                         
    'man'         => sub { pod2usage(-verbose => 2, -exitstatus => 0) },

) or die pod2usage();

my ($e, $n) = @ARGV ? parse_grid("@ARGV") : random_grid();

my ($lat, $lon) = grid_to_ll($e, $n);

open_browser(format_ll_googlemaps($lat,$lon));
open_browser(format_grid_streetmap($e, $n));

=pod

=head1 NAME

gbguessr.pl -- compare a random spot in the UK on Streetmap and Googlemaps

This programme shows off some features of L<Geo::Coordinates::OSGB>.

=head1 SYNOPSIS

  perl gbguessr.pl [optional grid ref string]

=head1 ARGUMENTS and OPTIONS

If you supply no argument, then a random grid reference is generated.  If you
do supply an argument, it should be a string that represents a grid reference,
like 'TQ 123 456' or '314159 271828'.  No need to use quotes.

=over 4 

=item --usage, --help, --man

Show increasing amounts of help text, and exit.

=item --version

Print version and exit.

=back

=head1 DESCRIPTION

This script picks a random spot in the British Isles and shows you it on Streetmap.co.uk and 
on Google maps;  this lets you compare the OS and the Google maps side by side for the same
area - sometimes you'll end up in the sea, but you'll always be on one of the Landranger or Explorer sheets.
It's surprisingly addictive...

PS the Google maps parameters are the result of experimentation rather than any API documentation
so I've no idea what the data parameter does, but it seems to be necessary.  The "14z" controls the 
level of zoom, and makes it roughly 1:50,000 corresponding to the Streetmap display with "&z=3".

=head1 DEPENDENCIES

You may need to install L<Browser::Open>.

=head1 AUTHOR

Toby Thurston -- 04 Feb 2016 
toby@cpan.org

=cut


