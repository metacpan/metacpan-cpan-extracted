use ExtUtils::MakeMaker;
my $module = 'MMagic.pm';
WriteMakefile(
              NAME         => 'File::Find::Rule::MMagic',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               'Test::More' => 0,
                               'Text::Glob' => 0,
                               'File::Find::Rule' => 0.07,
                               'File::MMagic' => 0,
                              },
              AUTHOR       => 'Richard Clamp <richardc@unixbeard.net>',
             );

sub MY::postamble {
    return <<EOF
README: $module
\tpod2text $module > README

cover:
\trm -rf cover_db
\tPERL5OPT=-MDevel::Cover \$(MAKE) test || true
\tcover cover_db
EOF
}
