use ExtUtils::MakeMaker::CPANfile;


WriteMakefile(
    ABSTRACT          => 'Installer for LedgerSMB double entry accounting and ERP',
    AUTHOR            => 'Erik Huelsmann <ehuels@gmail.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            bugtracker      => {
                web            => 'https://github.com/ledgersmb/ledgersmb-installer/issues',
            },
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ledgersmb/ledgersmb-installer.git',
                web            => 'https://github.com/ledgersmb/ledgersmb-installer',
            },
        },
    },
    NAME              => 'LedgerSMB::Installer',
    VERSION_FROM      => 'lib/LedgerSMB/Installer.pm',
);

