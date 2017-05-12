use strict;
use warnings;
use Module::Build::Pluggable 'CPANfile';
use rlib '..', '../..';
use FindBin;

my %pm_files = map {
  (my $path = $_) =~ s{^\./}{};
  if ($path !~ m{^(t|_\w+)/}) {
    ($path => "lib/MOP4Import/$path")
  } else {
    ();
  }
} @{Module::Build->rscan_dir('.', qr/\.pm$/)};

my $builder = Module::Build::Pluggable->new
  (module_name         => 'MOP4Import::Declare'
   , dist_name         => 'MOP4Import-Declare'
   , dist_author       => q{KOBAYASHI, Hiroaki <hkoba@cpan.org>},
   , dist_version_from => 'Declare.pm'
   , dist_abstract     => 'Thin Meta-Object Protocol to build extensible exporters'
   , license           => 'perl'
   , pm_files          => \%pm_files
 );

$builder->create_build_script();
