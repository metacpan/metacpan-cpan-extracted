use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Excel::ValueWriter::XLSX',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Excel/ValueWriter/XLSX.pm',

    requires => {
      'perl'                      => "5.014001",
      'utf8'                      => 0,
      'Archive::Zip'              => 0,
      'Scalar::Util'              => 0,
      'List::Util'                => 0,
      'Params::Validate'          => 0,
      'POSIX'                     => 0,
      'Date::Calc'                => 0,
      'Carp'                      => 0,
     },
    test_requires => {
      'Test::More'                => 0,
    },

    add_to_cleanup      => [ 'Excel-ValueWriter-XLSX-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Excel-ValueWriter-XLSX',
       }
     },
);

$builder->create_build_script();
