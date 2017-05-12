use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Finance::QuoteTW',
    license             => 'perl',
    dist_author         => 'Alec Chen <alec@cpan.org>',
    dist_version_from   => 'lib/Finance/QuoteTW.pm',
    build_requires => {
        'Test::More'         => 0,
        'Spiffy'             => 0.30,
        'version'            => 0.76,
        'WWW::Mechanize'     => 1.34,
        'HTML::TableExtract' => 2.10,
        'Encode'             => 2.26,
        'Encode::TW'         => 2.02,
        'HTML::Encoding'     => 0.60,
    },
    add_to_cleanup      => [ 'Finance-QuoteTW-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
