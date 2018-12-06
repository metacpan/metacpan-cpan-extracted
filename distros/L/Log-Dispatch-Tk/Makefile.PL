use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
    'NAME'	=> 'Log-Dispatch-Tk',
    'VERSION_FROM' => 'lib/Log/Dispatch/ToTk.pm',
    'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
    'PREREQ_PM' => {
        'Tk' => 0,
        'Log::Dispatch' => '2.68',
    },
    LICENSE => 'perl_5',
    META_MERGE => {
        resources => {
            homepage => 'https://metacpan.org/pod/Log::Dispatch::ToTk',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log::Dispatch::ToTk',
            repository  => 'https://github.com/dod38fr/log-dispatch-tk',
        }
    },
    ABSTRACT   => 'Tk text widget for Log::Dispatch messages',
    AUTHOR     => 'Dominique Dumont (ddumont@cpan.org)'
);
