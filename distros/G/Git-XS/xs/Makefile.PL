use ExtUtils::MakeMaker;
use strict;
use Config;
use Cwd;

# TODO Use File::Spec for portability
my $start_dir = Cwd::cwd;
my $libgit2_repo = 'git://github.com/ingydotnet/libgit2.git';
my $libgit2_path = Cwd::cwd . '/libgit2';
my $libgit2_inc = "$libgit2_path/include";
my $libgit2_build = "$libgit2_path/build";
my $libgit2_so = "$libgit2_build/libgit2.so";

# TODO Check for system copy of libgit2
if (not(-e $libgit2_path)) {
    system("git clone $libgit2_repo $libgit2_path") == 0
        or die "Can't git clone $libgit2_repo";
}

if (not(-f $libgit2_so)) {
    mkdir $libgit2_build
        or die "Can't mkdir $libgit2_build";
    chdir $libgit2_build
        or die "Can't chdir $libgit2_build";

    system("cmake ..") == 0
      or die "Can't cmake libgit2. Maybe you need to install cmake.";

    system("cmake --build .") == 0
      or die "Can't cmake --build libgit2.";

    chdir $start_dir
        or die "Can't chdir to $start_dir";
}

my $obj_files = join ' ', map {
    my $c = $_;
    $c =~ s/\.c$/$Config::Config{_o}/;
    $c;
}
glob("*.c"),
'XS.c';

WriteMakefile(
    NAME => 'Git::XS',
    # CCFLAGS => '-ansi -pedantic -Wall',
    # CCFLAGS => '-ansi -Wall',
    PREREQ_PM => {},
    LIBS => ["-L$libgit2_build -lgit2"],
    INC => "-I. -I$libgit2_inc",
    OBJECT => $obj_files,
    ABSTRACT => 'Perl XS binding to libgit2',
    AUTHOR => 'Ingy döt Net <ingy@cpan.org>',
);
