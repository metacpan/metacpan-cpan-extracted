use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Finance::Bank::SK::SLSP::Notification',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Finance/Bank/SK/SLSP/Notification.pm',
    requires => {
        'Email::MIME'           => 0,
        'File::Temp'            => 0,
        'Path::Class'           => 0,
        'Archive::Extract'      => 0,
        'File::Find::Rule'      => 0,
        'Encode'                => 0,
        'Email::Address'        => 0,
        'Class::Accessor::Fast' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    add_to_cleanup      => [ 'Finance-Bank-SK-SLSP-Notification-*' ],
    create_readme       => 1,
);

$builder->create_build_script();
