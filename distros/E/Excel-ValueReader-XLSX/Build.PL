use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Excel::ValueReader::XLSX',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Excel/ValueReader/XLSX.pm',

    requires => {
      'perl'                      => "5.012001",
      'utf8'                      => 0,
      'Carp'                      => 0,
      'Archive::Zip'              => "1.61",
      'Module::Load'              => 0,
      'Moose'                     => 0,
      'MooseX::StrictConstructor' => 0,
      'Date::Calc'                => 0,
      'POSIX'                     => 0,
      'Scalar::Util'              => 0,
      'Iterator::Simple'          => 0,
     },
    recommends => {
      'XML::LibXML::Reader'       => 0,
     },
    test_requires => {
      'Test::More'                => "1.302195",
      'List::Util'                => 0,
      'List::MoreUtils'           => 0,
      'Module::Load::Conditional' => "0.66",
      'Clone'                     => 0,
    },

    add_to_cleanup      => [ 'Excel-ValueReader-XLSX-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Excel-ValueReader-XLSX',
       }
     },
);

$builder->create_build_script();
