use strict;
use warnings;
use utf8;
use Test::More;
use File::Zglob;
use Data::Dumper;
use Cwd;

{
    package Cwd::Guard;
    sub new {
        my ($class, $path) = @_;
        my $cwd = Cwd::getcwd();
        chdir($path);
        bless \$cwd, $class;
    }
    sub DESTROY {
        my $self = shift;
        chdir($$self);
    }
}

$File::Zglob::DEBUG = $ENV{DEBUG} ? 1 : 0;

{
    my $guard = Cwd::Guard->new('t/dat/');
    is_deeply2('**/normalfile', ['very/deep/normalfile']);
    is_deeply2('very/**/*', [qw(very/deep very/deep/normalfile)]);
    is_deeply2('very/deep/*', ['very/deep/normalfile']);
    is_deeply2('very/deep/.*', ['very/deep/.dotfile']);
    is_deeply2('**/*.{pm,pl}', [qw(lib/bar.pl lib/foo.pm)]);
    is_deeply2('bug/0', ['bug/0']);
    is_deeply2('./very/**/*', [qw(very/deep very/deep/normalfile)]);
    is_deeply2('./very/deep/*', ['very/deep/normalfile']);
    is_deeply2('./very/deep/.*', ['very/deep/.dotfile']);
    is_deeply2('very/./**/*', [qw(very/deep very/deep/normalfile)]);
}
is_deeply2('*/*.t', [qw(t/00_compile.t   t/02_glob_prepare_pattern.t  t/03_zglob.t t/04_dotdot.t xt/01_podspell.t  xt/02_perlcritic.t  xt/03_pod.t  xt/04_minimum_version.t)]);
is_deeply2('lib/File/Zglob.pm', ['lib/File/Zglob.pm']);
is_deeply2('lib/*/Zglob.pm', ['lib/File/Zglob.pm']);
is_deeply2('lib/File/*.pm', ['lib/File/Zglob.pm']);
is_deeply2('l*/*/*.pm', ['lib/File/Zglob.pm']);
is_samepath('~', [glob('~')]);
if (-f glob('~/.bashrc')) {
    is_samepath('~/.bashrc', [glob('~/.bashrc')]);
}
if (-f '/etc/passwd') {
    is_samepath('/etc/passwd', ['/etc/passwd']);
}
if ($ENV{USER} && $ENV{HOME} eq "/home/$ENV{USER}" && -d "/home/$ENV{USER}/") {
    is_deeply2("~", ["/home/$ENV{USER}"]);
    is_deeply2("~$ENV{USER}", ["/home/$ENV{USER}"]);
}

done_testing;

sub is_deeply2 {
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 0;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($pattern, $expected, $reason) = @_;
    is(Dumper([sort { $a cmp $b } zglob($pattern)]), Dumper([sort @$expected]), $reason || $pattern) or do {
        die "ABORT" if $File::Zglob::DEBUG;
    };
}

sub normalize {
    my $path = shift;
    if ($^O eq 'MSWin32') {
        require Win32;
        Win32::GetLongPathName(Cwd::abs_path($path))
    } else {
        Cwd::abs_path($path)
    }

}
sub is_samepath {
    my ($p, $b) = @_;

    my $a = [zglob($p)];
    return 0 if !defined($a) || !defined($b) || @$a != @$b;
    for (0..$#$a) {
        is(normalize($a->[$_]), normalize($b->[$_]));
    }
}
