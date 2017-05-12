use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::Telephony::ErlangB',
    license             => 'perl',
    dist_author         => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    dist_version_from   => 'lib/Math/Telephony/ErlangB.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        perl => 5.008000,
    },
    add_to_cleanup      => [ 'Math-Telephony-ErlangB-*' ],
);

$builder->create_build_script();
