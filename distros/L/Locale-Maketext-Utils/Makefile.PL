use ExtUtils::MakeMaker;

# Note to self: cp t/07.phrase_norm.t t/08.cpanel_norm.t && perl -pi -e 's/Norm.pm/cPanel.pm/g;s/::Norm/::cPanel/g' t/08.cpanel_norm.t

WriteMakefile(
    NAME         => 'Locale::Maketext::Utils',
    VERSION_FROM => 'lib/Locale/Maketext/Utils.pm',
    PREREQ_PM    => {
        'Locale::Maketext'      => 1.23,
        'Locales'               => 0.32,
        'DateTime'              => 0,
        'Net::IDN::Encode'      => 2.005,
        'IO::Interactive::Tiny' => 0,
        'Web::Detect'           => 0.04,
        'Module::Want'          => 0,
        'Encode'                => 0,
        'Test::More'            => 0,
        'Test::Carp'            => 0,
        'Test::Warn'            => 0,
        'Test::NoWarnings'      => 0,

        # 'Sub::Todo'             => 0,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Locale/Maketext/Utils.pod',
            AUTHOR        => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>'
          )
        : ()
    ),
);
