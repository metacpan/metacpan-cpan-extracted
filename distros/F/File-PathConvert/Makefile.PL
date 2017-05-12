use ExtUtils::MakeMaker;

warn <<'TOHERE';

*** THIS MODULE (File::PathConvert) IS DEPRECATED. ****

There are several known bugs, and it is not being actively
maintained since all functionality is now available in
modules (Cwd.pm and File::Spec) bundled in every Perl
distribution of recent vintage.  This version is provided to
fix a few bugs and to get the word out about the
deprecation.

Please use Cwd::abs_path() instead of
File::PathConvert::realpath() and File::Spec methods instead
of all other path manipulation functions in this module.

If you use setfstype, you probably want to access a File::Spec::Foo
module for the appropriate operating system.

There is also a version of File::Spec on CPAN for backwards
compatability.

Thank you,

Barrie Slaymaker <barries@slaysys.com>


TOHERE


WriteMakefile(
    'NAME' => 'File::PathConvert',
    'VERSION_FROM' => 'PathConvert.pm',
    'clean' => {FILES => 'LOG ./test'},
    'dist' => {TARFLAGS => 'cvf', COMPRESS => 'gzip', SUFFIX => 'gz'},
);
