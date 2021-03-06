# =========================================================================
# THIS FILE IS AUTOMATICALLY GENERATED BY MINILLA.
# DO NOT EDIT DIRECTLY.
# =========================================================================

use 5.006;
use strict;

use ExtUtils::MakeMaker 6.64;


my %WriteMakefileArgs = (
    NAME     => 'Markdown::TOC',
    DISTNAME => 'Markdown-TOC',
    VERSION  => '0.01',
    EXE_FILES => [glob('script/*'), glob('bin/*')],
    CONFIGURE_REQUIRES => {
  "ExtUtils::MakeMaker" => "6.64"
}
,
    BUILD_REQUIRES     => {}
,
    TEST_REQUIRES      => {
  "Test::More" => "0.98"
}
,
    PREREQ_PM          => {
  "perl" => "5.008001"
}
,
);

WriteMakefile(%WriteMakefileArgs);
