use ExtUtils::MakeMaker;
WriteMakefile(
    INSTALLDIRS => 'perl',
    NAME	=> 'Devel::tkdb',
    VERSION_FROM => 'tkdb.pm', # finds $VERSION
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                web => 'https://github.com/vadrer/Perl-Devel-tkdb',
                url => 'https://github.com/vadrer/Perl-Devel-tkdb',
            },
            MailingList => 'mailto:tcltk@perl.org',
        },
	keywords => [qw(Tk Tcl/Tk GUI Debuger)],
    },
    PREREQ_PM => {
	'Tcl::Tk' => 1.03,
        'Tcl::Tk::Tkwidget::treectrl' => 1,
    }
);
