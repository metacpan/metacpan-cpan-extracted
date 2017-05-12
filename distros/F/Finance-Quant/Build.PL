#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
    module_name       => 'Finance::Quant',
    license           => 'perl',
    dist_version_from => 'lib/Finance/Quant.pm',
    dist_author       => 'Hagen Geissler <santex@cpan.org>',
    dist_abstract     =>  'lib/Finance/Quant.pm',
    requires          => {
    'GD'                  => 0,
    'Test::More'       => 0,
    'Carp'=>0,
    'Text::Reform'    =>0,
    'Data::Dumper'			=>0,
    'File::Spec::Functions'		=>0,
    'File::Path'			=>0,
    'Time::Local'			=>0,
    'File::Fetch'			=>0,
    'File::Copy'			=>0,
    'File::Find'			=>0,
    'Finance::Optical::StrongBuy'	=>0,
    'Finance::Quant::Symbols' =>0,
    'Finance::Google::Sector::Mean'	=>0,
    'Finance::NASDAQ::Markets'	=>0,
    'HTML::TreeBuilder'		=>0,
    'Text::Buffer'			=>0,
    'WWW::Mechanize'=>0,
    'GraphViz'=>0,
    'List::Util'=>0,
    'MIME::Base64'=>0,
    'GD::Graph::lines'=>0,
    'Statistics::Basic'=>0,
    'Thread::Queue'=>0,
    'Cache::Memcached'=>0,
    'LWP::UserAgent'=>0,
    'threads'=>0,

    },
    recommends        => {
    },


 script_files => [
                        'scripts/financequant',
                        'scripts/FINANCE_QUANT_HTTP_SERVER',
                        'scripts/FINANCE_QUANT_CREATE_DB',
                        'scripts/FINANCE_QUANT_R_CMD',
                        'scripts/FINANCE_QUANT_RECOMMENDED',
                        'scripts/FINANCE_QUANT_RESTORE',
                        'scripts/FINANCE_QUANT_SORT_MARKETS',
                        'scripts/FINANCE_QUANT_TEST_INSTALL',
                        'scripts/FINANCE_QUANT_VGREP',
                        'scripts/FINANCE_QUANT_TRAY',
                        'scripts/FINANCE_QUANT_XML_RESULTS',
                        'scripts/FINANCE_QUANT_CACHE',
                        'scripts/FINANCE_QUANT_RUN_ALL',
                        'scripts/longtrend-001.r',
                        'scripts/longtrend-002.r',
                        'scripts/longtrend-003.r',


    ],

 
       example_files => [
			'libdoc/'
    ],
    create_makefile_pl => 'passthrough',
    build_class        => 'Module::Build',
    );
$build->create_build_script;
exit 0;
