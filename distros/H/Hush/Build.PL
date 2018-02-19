use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hush',
    license             => 'perl',
    dist_author         => 'Duke Leto <duke@leto.net>',
    dist_abstract       => 'HushList-powered secure messaging',
    dist_version        => '0.03',
    include_dirs        => '',
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
        'perl'                 => '5.008',
	'URL::Encode'          => '0.03',
        'Bitcoin::RPC::Client' => '0.07',
    },
    add_to_cleanup      => [ 'Hush-*' ],
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/leto/hushlist/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have freakin' awesome day!\n";
