use strict;
use warnings;

use Module::Build qw( );

my $build = Module::Build->new(
   module_name => 'LWP::Protocol::Coro::http',
   dist_author => 'Eric Brine <ikegami@adaelis.com>',
   license     => 'CC0_1_0',
   configure_requires => {
      'Module::Build'              => 0.36_14,
      'Software::License::CC0_1_0' => 0,
   },
   build_requires => {
      'AnyEvent'     => 0,
      'Carp'         => 0,
      'CGI'          => 0,
      'File::Spec'   => 0,
      'File::Temp'   => 0,
      'FindBin'      => 0,
      'Getopt::Long' => 0,
      'HTTP::Daemon' => 0,
      'LWP::Simple'  => 0,
      'Test::More'   => 0,
      'URI'          => 0,
      'URI::URL'     => 0,
   },
   requires => {
      'AnyEvent::HTTP'      => 2.0,
      'Coro::Channel'       => 0,
      'HTTP::Response'      => 0,
      'LWP::Protocol'       => 0,
      'LWP::Protocol::http' => 0,
      'LWP::Simple'         => 5.827, # Not strictly required, but ensures that LWP::Simple will actually use LWP::Protocol.
      'version'             => 0,
   },
   add_to_cleanup => [ 'LWP-Protocol-Coro-http-*' ],
   meta_merge     => {
      resources => {
         repository => "http://github.com/ikegami/perl-LWP-Protocol-Coro-http",
      }
   },
);

$build->create_build_script();
