use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Excel::PowerPivot::Utils',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Excel/PowerPivot/Utils.pm',

    requires => {
      'perl'                      => "5.020000",
      'utf8'                      => 0,
      'Scalar::Does'              => 0,
      'List::Util'                => 1.33,
      'Log::Dispatch'             => 0,
      'Moose'                     => 0,
      'POSIX'                     => 0,
      'Win32::OLE'                => 0,
     },
    test_requires => {
      'Test::More'                => 0,
      'Excel::ValueWriter::XLSX'  => 0,
      'LWP::UserAgent'            => 0,
      'DBI'                       => 0,
      'Cwd'                       => 0,
    },

    add_to_cleanup      => [ 'Excel-PowerPivot-Utils-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Excel-PowerPivot-Utils',
       }
     },
);

$builder->create_build_script();
