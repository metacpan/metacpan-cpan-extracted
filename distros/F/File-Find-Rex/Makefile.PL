use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::MY;

sub MY::libscan {
  my( $mm, $file ) = @_;
  return if $file =~ /\.DS_Store/;
  return $file;
}

WriteMakefile(
    NAME             => 'File::Find::Rex',
    AUTHOR           => q{Roland Ayala <rolanday@cpan.org>},
    VERSION_FROM     => 'lib/File/Find/Rex.pm',
    ABSTRACT_FROM    => 'lib/File/Find/Rex.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        "Carp" => '1.29',
        "Cwd"  => '3.40',
        'File::Basename' => '2.84',
        'File::Find'     => '0',
        'File::Spec'     => '3.40',
        ($^O eq 'MSWin32' ? ('Win32::File' => '0') : ()),
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-Find-Rex-*' },
);
