use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'EBook::Tools',
     license  => 'gpl2',
     requires => {
         'perl'              => '5.10.1',
         'Archive::Zip'      => 1.16,
         'Bit::Vector'	     => 6.4,
         'Compress::Zlib'    => 1,
         'Config::IniFiles'  => 2,
         'Data::UUID'        => 1,
         'Date::Manip'       => 5.44,
         'DBI'               => '1.614',
         'Encode::Detect'    => 1,
         'File::MimeInfo'    => 0.13,
         'File::Slurp'	     => 9999,
         'File::Which'       => 0,
	 'HTML::Entities'    => 1,
         'HTML::TextToHTML'  => 2.44,
         'HTML::TreeBuilder' => 3.19,
         'Image::Size'       => 3.1,
         'Lingua::EN::NameParse' => 1,
         'List::MoreUtils'   => 0.21,
         'LWP::Protocol::https' => 0,
         'Mojo::DOM'         => 0,	# Actually needs Mojolicious 4 or above
         'Palm::PDB'         => 1,
         'Palm::Raw'         => 1,
         'String::CRC32'     => 1,
         'Tie::IxHash'       => 1.21,
         'Time::Local'       => 1.18,
         'URI::Escape'	     => 1,
         'version'           => 0.74,
         'XML::Twig'         => 3.32,
     },
     test_requires => {
         'DBD::SQLite'          => '1.20',
     },
     PL_files => { 'Bin.PL' => 'bin/ebook' },
     create_makefile_pl => 'small',
    );
$build->create_build_script;
