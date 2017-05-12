use ExtUtils::MakeMaker;
my $module = 'ImageSize.pm';
WriteMakefile(
              NAME         => 'File::Find::Rule::ImageSize',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               'Test::More' => 0,
                               'File::Find::Rule' => 0.07,
                               'Number::Compare' => 0,
                               'Image::Size' => 0,
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
