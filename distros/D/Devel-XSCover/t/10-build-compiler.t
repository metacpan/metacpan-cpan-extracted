use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Build ();

plan skip_all => 'shell scripts stand in for compilers here' if $^O eq 'MSWin32';

my $bin = File::Temp->newdir;
sub fake {
    my ($name, $text) = @_;
    my $path = File::Spec->catfile($bin, $name);
    open my $fh, '>', $path or die "$path: $!";
    print $fh "#!/bin/sh\necho \"$text\"\n";
    close $fh;
    chmod 0755, $path;
    return $path;
}
my $clang = fake('cc-clang', 'Apple clang version 21.0.0 (clang-2100.1.1.101)');
my $gcc   = fake('cc-gcc', 'gcc (GCC) 14.2.1 20240910');
my $debian = fake('cc-debian', 'cc (Debian 12.2.0-14) 12.2.0\nCopyright (C) 2022 Free Software Foundation, Inc.');
my $bare   = fake('cc-bare', 'cc (Alpine 13.2.1_git20240309) 13.2.1 20240309');
my $odd   = fake('cc-odd', 'tcc version 0.9.27');

my $c = Devel::XSCover::Build->new(cc => $clang)->compiler;
is($c->{name}, 'clang', 'clang detected');
is($c->{major}, 21, 'clang major');
$c = Devel::XSCover::Build->new(cc => $gcc)->compiler;
is($c->{name}, 'gcc', 'gcc detected');
is($c->{major}, 14, 'gcc major');
$c = Devel::XSCover::Build->new(cc => $debian)->compiler;
is($c->{name}, 'gcc', 'a cc that is gcc');
is($c->{major}, 12, 'its major');
$c = Devel::XSCover::Build->new(cc => $bare)->compiler;
is($c->{name}, 'gcc', 'a one-line gcc banner in the name (vendor) version shape');
is($c->{major}, 13, 'its major');
$c = Devel::XSCover::Build->new(cc => $odd)->compiler;
is($c->{name}, 'unknown', 'an unknown compiler');

{
    local $ENV{PATH} = "$bin";
    fake('gcov', 'Apple LLVM version 21.0.0');
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        [File::Spec->catfile($bin, 'gcov')], 'clang with an LLVM gcov shim uses it');

    fake('gcov', 'gcov (GCC) 14.2.1');
    fake('llvm-cov', 'LLVM version 21.0.0');
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        [File::Spec->catfile($bin, 'llvm-cov'), 'gcov'], "clang beside gcc's gcov uses llvm-cov gcov");

    fake('llvm-cov-21', 'LLVM version 21.0.0');
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        [File::Spec->catfile($bin, 'llvm-cov-21'), 'gcov'], 'the versioned llvm-cov first');

    is_deeply(Devel::XSCover::Build->new(cc => $gcc)->gcov_command,
        [File::Spec->catfile($bin, 'gcov')], 'gcc 14 without gcov-14 uses gcov');
    fake('gcov-14', 'gcov (GCC) 14.2.1');
    is_deeply(Devel::XSCover::Build->new(cc => $gcc)->gcov_command,
        [File::Spec->catfile($bin, 'gcov-14')], 'gcc 14 with gcov-14 uses it');

    is_deeply(Devel::XSCover::Build->new(cc => $gcc, gcov => '/opt/bin/gcov-13')->gcov_command,
        ['/opt/bin/gcov-13'], 'the override wins');
    is_deeply(Devel::XSCover::Build->new(cc => $gcc, gcov => 'llvm-cov gcov')->gcov_command,
        ['llvm-cov', 'gcov'], 'an override of two words');
}

done_testing;
