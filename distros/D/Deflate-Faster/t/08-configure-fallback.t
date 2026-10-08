use strict;
use warnings;
use Test::More;
use Config qw(%Config);
use FindBin qw($Bin);
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

my @needed = qw(
    Makefile.PL
    Faster.xs
    deflate-faster-perl.c
    typemap
    ppport.h
    lib/Deflate/Faster.pm
    lib/Deflate/Faster.pod
);

my $root = abs_path("$Bin/..");

sub stage_dist {
    my $dir = tempdir(CLEANUP => 1);
    for my $rel (@needed) {
        my $dst = File::Spec->catfile($dir, $rel);
        my ($vol, $dirs, undef) = File::Spec->splitpath($dst);
        make_path(File::Spec->catpath($vol, $dirs, '')) if length $dirs;
        copy(File::Spec->catfile($root, $rel), $dst) or die "copy $rel: $!";
    }
    return $dir;
}

sub run_pl {
    my ($dir, %extra_env) = @_;
    my $cwd = getcwd();
    chdir $dir or die "chdir $dir: $!";
    local %ENV = (%ENV, %extra_env);
    my $rc = system(qq{"$^X" Makefile.PL > pl.log 2>&1});
    my $content;
    if (-f 'Makefile') {
        open my $fh, '<', 'Makefile' or die $!;
        local $/;
        $content = <$fh>;
        close $fh;
    }
    chdir $cwd or die "chdir $cwd: $!";
    return ($rc == 0, $content);
}

sub write_alien_stub {
    my ($dir) = @_;
    my $moddir = File::Spec->catdir($dir, 'Alien');
    make_path($moddir);
    my $pm = File::Spec->catfile($moddir, 'libdeflate.pm');
    open my $fh, '>', $pm or die $!;
    print {$fh} <<'EOF';
package Alien::libdeflate;
sub libs { $ENV{DF_TEST_ALIEN_LIBS} }
sub cflags { $ENV{DF_TEST_ALIEN_CFLAGS} // '' }
1;
EOF
    close $fh or die $!;
    return $dir;
}

# Baseline: plain configure must succeed, or nothing here is testable
my $base_dir = stage_dist();
my ($base_ok, $base_mk) = run_pl($base_dir);
unless ($base_ok) {
    plan skip_all => 'no usable libdeflate for configure fallback tests';
}
pass("plain configure succeeds");

# libdeflate may live outside the default search paths (Homebrew)
my ($found_libs) = ($base_mk // '') =~ /^#\s+LIBS => \[q\[(.*?)\]\]/m;
my ($found_inc) = ($base_mk // '') =~ /^#\s+INC => q\[(.*?)\]/m;
($found_inc //= '') =~ s/^-I\.\s*//;

# A broken Alien must not block the remaining detection paths
{
    my $dir = stage_dist();
    my $stub = write_alien_stub(tempdir(CLEANUP => 1));
    my $sep = $Config{path_sep};
    my %env = (
        PERL5LIB => $stub . ($ENV{PERL5LIB} ? "$sep$ENV{PERL5LIB}" : ''),
        DF_TEST_ALIEN_LIBS => '-L/nonexistent-xyz -lnolibnamedthis',
    );
    my ($ok, $content) = run_pl($dir, %env);
    ok($ok && defined $content, "configure succeeds despite broken Alien");
    unlike($content // '', qr/nonexistent-xyz/, "broken Alien flags not used");
    like($content // '', qr/-ldeflate/, "fallback detection provides libdeflate");
}

# A working Alien is honored
{
    my $dir = stage_dist();
    my $stub = write_alien_stub(tempdir(CLEANUP => 1));
    my $sep = $Config{path_sep};
    my %env = (
        PERL5LIB => $stub . ($ENV{PERL5LIB} ? "$sep$ENV{PERL5LIB}" : ''),
        DF_TEST_ALIEN_LIBS => $found_libs || '-ldeflate',
        DF_TEST_ALIEN_CFLAGS => "-I$stub $found_inc",
    );
    my ($ok, $content) = run_pl($dir, %env);
    ok($ok && defined $content, "configure succeeds with working Alien");
    like($content // '', qr/\Q$stub\E/, "Alien cflags reach the Makefile");
}

done_testing();
