use Module::Build;

my $build = Module::Build->new
   (
     module_name => 'Geo::Postcodes::DK',
     license     => 'perl',
     requires    => {
                     'perl'           => '5.6.1',
                     'Geo::Postcodes' => '0.31'
                    },
   );
$build->create_build_script;
