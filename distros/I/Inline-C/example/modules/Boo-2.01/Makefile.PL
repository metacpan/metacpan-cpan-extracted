use Inline::MakeMaker;

WriteMakefile(
    NAME             => 'Boo',
    VERSION_FROM     => 'lib/Boo.pm',

    PREREQ_PM        => { Inline::C => 0.57 },
    clean => { FILES => '_Inline *.inl' },
);
