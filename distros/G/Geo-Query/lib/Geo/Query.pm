package Geo::Query;

use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Geo::Query ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.04';

#####  FORWARD
sub Debug($);

#####  GLOBAL
my $package = __PACKAGE__;

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {};

	$self->{'debug' } = $params{'debug'} || 0; # 0, 1, 2

	Debug "$package V$VERSION" if $self->{'debug'};

	bless $self, $type;
}

sub distance() {
	my $self = shift;
	my %args = @_;
	$args{'lat1'} ||= 0;
	$args{'lat2'} ||= 0;
	$args{'lng1'} ||= 0;
	$args{'lng2'} ||= 0;

	use Math::Trig;

	my %hash = ();

	my $R = 6371; # -- km
	my $dLat = deg2rad(abs($args{'lat2'} - $args{'lat1'}));
	my $dLon = deg2rad(abs($args{'lng2'} - $args{'lng1'}));

	my $lat1 = deg2rad($args{'lat1'});
	my $lat2 = deg2rad($args{'lat2'});

	my $a = sin($dLat / 2) * sin($dLat / 2) + cos($lat1) * cos($lat2) * sin($dLon / 2) * sin($dLon / 2);

	my $c = 2 * atan2(sqrt(abs($a)), sqrt(1 - $a));

	my $d = $R * $c;

	$hash{'d'} = $c; # -- multiply with your own radius
	$hash{'km'} = sprintf('%.2f', $d);

	\%hash;
}

sub info() {
	my $self = shift;
	my %args = @_;

	my %info = ();
	   $info{'version'} = $VERSION;

	use LWP::Simple;
	my $module_list = get 'http://meta.pg'.
				'ate.net/wiki-reto/index.php?title=Perl_modules_geo-query&printable=yes';

	my @lines = split /\n/, $module_list;
	my $i = 0;
	foreach (@lines) { $i++; last if /BEGIN SECTION 101/; }

	for ($i = $i + 1; $i < $#lines + 1; $i++) {
		chomp $lines[$i];
		last if $lines[$i] =~ /END SECTION 101/;
		$info{'modules'} .= $lines[$i] . "\n" if $lines[$i];
	}

	\%info;
}

sub Debug ($)  { print "[ $package ] $_[0]\n"; }

1;

__END__

=head1 NAME

Geo::Query - Perl extension for querying geo related data from different sources.

=head1 SYNOPSIS

  use Geo::Query;

Library. This will be the container for future Geo::Query::Any modules.

=head2 Calculating distance

  $geo = Geo::Query->new();
  $d = $geo->distance(
  	lat1 => 47.463173, lng1 => 9.0005,
  	lat2 => 47.499879, lng2 => 8.72616
  );
  print "Distance is ", $d->{'km'}, " kilometers\n";

This returns a rough estimation of the distance between two points. For more possibilities in calculating distances please take a look on Geo::Distance - Calculate Distances and Closest Locations.

=head1 Related Modules

B<Geo::Query::LatLong>

  http://search.cpan.org/dist/Geo-Query-LatLong/lib/Geo/Query/LatLong.pm

=head1 DESCRIPTION

Calculates distances. Installs related Geo-Quey modules. Returns information about the Geo-Query modules.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Geo::Query::LatLong

http://www.xn--schrsoft-2za.ch

http://meta.pgate.net/perl-modules/

http://www.movable-type.co.uk/scripts/latlong.html

http://search.cpan.org/dist/Geo-Distance/Distance.pm


=head1 AUTHOR

Reto Schaer, E<lt>reto@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2010 by reto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.x or,
at your option, any later version of Perl 5 you may have available.

=cut
