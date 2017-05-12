use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    create_makefile_pl  => 'traditional',
    module_name         => 'Mail::Mailer::smtp_auth',
    license             => 'perl',
    dist_author         => 'Fayland <fayland@gmail.com>',
    dist_version_from   => 'lib/Mail/Mailer/smtp_auth.pm',
    build_requires => {
        'Test::More' => 0,
        'Mail::Mailer'   => 0,
        'Net::SMTP_auth' => 0,
    },
    add_to_cleanup      => [ 'Mail-Mailer-smtp_auth-*' ],
);

$builder->create_build_script();
