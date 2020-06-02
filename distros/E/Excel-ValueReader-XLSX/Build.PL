use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Excel::ValueReader::XLSX',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Excel/ValueReader/XLSX.pm',

    requires => {
      'perl'                      => "5.010001",
      'utf8'                      => 0,
      'Archive::Zip'              => 0,
      'Module::Load'              => 0,
      'Moose'                     => 0,
     },
    recommends => {
      'XML::LibXML::Reader'       => 0,
     },
    test_requires => {
      'Test::More'                => 0,
      'List::Util'                => 0,
      'Module::Load::Conditional' => 0,
    },

    add_to_cleanup      => [ 'Excel-ValueReader-XLSX-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Excel-ValueReader-XLSX',
       }
     },
);

$builder->create_build_script();
