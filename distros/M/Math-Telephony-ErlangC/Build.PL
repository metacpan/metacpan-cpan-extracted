use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::Telephony::ErlangC',
    license             => 'perl',
    dist_author         => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    dist_version_from   => 'lib/Math/Telephony/ErlangC.pm',
    requires => {
        'Math::Telephony::ErlangB' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Math-Telephony-ErlangC-*' ],
);

$builder->create_build_script();
