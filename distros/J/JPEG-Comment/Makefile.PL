use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'JPEG::Comment',
    'VERSION_FROM' => 'Comment.pm',
    'PREREQ_PM' => {},
    ($] >= 5.005 ?
        (AUTHOR => 'Ivan Frolcov <ifrol\@cpan.org>') : ()),
);