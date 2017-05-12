use strict;
use warnings;
use Module::Build;

eval {
    require threads;
};
die "threads are required for Distributed::Process to work" if $@;

my $builder = Module::Build->new(
    module_name         => 'Distributed::Process',
    license             => '',
    dist_author         => 'Cédric Bouvier <cbouvi@cpan.org>',
    dist_version_from   => 'lib/Distributed/Process.pm',
    requires => {
        'Test::More' => 0,
	'Time::HiRes' => 0,
    },
    add_to_cleanup      => [ 'Distributed-Process-*' ],
);

$builder->create_build_script();
