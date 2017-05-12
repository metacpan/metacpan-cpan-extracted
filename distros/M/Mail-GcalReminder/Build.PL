use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Mail::GcalReminder',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Mail/GcalReminder.pm',
    requires          => {
        'Test::More'  => 0,
        'Test::Deep'  => 0,
        'Net::Detect' => 0,
        'Test::Warn'  => 0,

        'Moo'                 => 0,
        'Role::Multiton::New' => 0,

        'Email::Send::SMTP::Gmail' => 0,
        'iCal::Parser'             => 0,
        'File::Temp'               => 0,
        'HTML::Tiny'               => 0,

        'DateTime'                  => 0,
        'DateTime::TimeZone'        => 0,
        'Carp'                      => 0,
        'DateTime::Format::ISO8601' => 0,
    },
    add_to_cleanup => ['Mail-GcalReminder-*'],
);

$builder->create_build_script();
