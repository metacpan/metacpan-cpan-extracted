use Module::Build;
Module::Build
    ->new(
        dist_author         => 'Mark Stosberg <mark@summersault.com>',
        dist_abstract       => 'Quickly Add Events to ICal with natural language',
        dist_version_from   => 'lib/ICal/QuickAdd.pm',
        add-to-cleanup      => [ 'ICal::QuickAdd-*', 't/evo_injectee.ics' ],
        create_makefile_pl  => 'traditional',
        module_name         => 'ICal::QuickAdd',
        license             => 'perl',
        create_readme       => 1,
        script_files        => [ 'bin/iqa' ],
        requires => {
            'DateTime::Format::Natural' => 0,
            'DateTime::Format::ICal'    => 0,
            'Mail::Audit'               => 0,
            'Data::ICal'                => 0,
            'Email::Date'               => 0,
            'Test::More' => 0,
        },
    )
    ->create_build_script;

# vim: nospell
