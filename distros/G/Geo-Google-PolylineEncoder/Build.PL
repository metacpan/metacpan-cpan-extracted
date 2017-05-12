#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for C<Geo::Google::PolylineEncoder> module

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings;
use File::Spec;
use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'Geo::Google::PolylineEncoder',
   dist_version_from  => 'lib/Geo/Google/PolylineEncoder.pm',
   create_makefile_pl => 'passthrough',
   create_readme      => 1,
   license            => 'perl',
   requires           => {
			  'perl'          => '5.6.0',
			  'accessors'     => '0.02',
		         },
   build_requires     => {
			  'Test::More'    => '0.01',
			  'Module::Build' => '0.20',
			  'IO::File'      => '0.01',
		         },
   build_reccomends   => {
			  'Test::Approx'  => '0.03',
			  'Geo::Gpx'      => '0.21',
		         },

  );

$build->create_build_script;


__END__

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=cut

