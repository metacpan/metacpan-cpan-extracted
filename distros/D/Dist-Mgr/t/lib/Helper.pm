package Helper;

use warnings;
use strict;

use Carp qw(croak);
use Cwd qw(getcwd);
use Exporter qw(import);
use Digest::SHA;
use Dist::Mgr qw(version_info version_bump);
use File::Copy;
use File::Path qw(rmtree);
use Digest::MD5;
use Test::More;
use Tie::File;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    copy_changes
    copy_makefile
    copy_module_files
    copy_manifest
    copy_git_ignore

    unlink_changes
    unlink_ci_files
    unlink_makefile
    unlink_module_files
    unlink_manifest
    unlink_git_ignore

    mkdir_init

    remove_ci
    remove_init
    remove_unwanted

    file_compare
    file_scalar
    sha1sum
    module_args
    release_version
    trap_warn
    verify_clean
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $orig_dir        = 't/data/orig';
my $work_dir        = 't/data/work';
my $tpl_dir         = 't/data/module_template';
my $unwanted_dir    = 't/data/work/unwanted';
my $init_dir        = 't/data/work/init';
my $ci_dir          = 't/data/work/ci';

sub copy_changes {
    copy "$orig_dir/Changes", $work_dir or die "can't copy $orig_dir/Changes: $!";
    copy "$tpl_dir/Changes", "$work_dir/Changes-prerelease" or die "Can't copy $tpl_dir/Changes-prerelease: $!";
    copy "$orig_dir/Changes-release", $work_dir or die "Can't copy $orig_dir/Changes-release: $!";

    # Set today's date in the -release file. This is the file we'll compare
    # the results to

    my ($d, $m, $y) = (localtime)[3, 4, 5];
    $y+= 1900;
    $m+= 1;

    $d = "0$d" if length $d == 1;
    $m = "0$m" if length $m == 1;

    my $changes_release = "$work_dir/Changes-release";

    my $tie = tie my @changes, 'Tie::File', $changes_release;

    for my $line (@changes) {
        if ($line =~ /XXXX-YY-ZZ/) {
            $line =~ s/XXXX-YY-ZZ/$y-$m-$d/;
            last;
        }
    }

    untie $tie;
}
sub copy_makefile {
    copy "$orig_dir/Makefile.PL", $work_dir or die $!;
}
sub copy_module_files {
    for (find_module_files($orig_dir)) {
        copy $_, $work_dir or die $!;
    }
}
sub copy_manifest {
    copy "$orig_dir/MANIFEST.SKIP", $work_dir or die $!;
    copy "$orig_dir/manifest.t", $work_dir or die $!;
}
sub copy_git_ignore {
    copy "$orig_dir/.gitignore", $work_dir or die $!;
}

sub unlink_changes {
    if (-e "$work_dir/Changes") {
        unlink "$work_dir/Changes" or die $!;
    }
    is -e "$work_dir/Changes", undef, "temp Changes deleted ok";

    if (-e "$work_dir/Changes-release") {
        unlink "$work_dir/Changes-release" or die $!;
    }
    is -e "$work_dir/Changes-release", undef, "temp Changes-release deleted ok";

    if (-e "$work_dir/Changes-prerelease") {
        unlink "$work_dir/Changes-prerelease" or die $!;
    }
    is -e "$work_dir/Changes-prerelease", undef, "temp Changes-prerelease deleted ok";
}
sub unlink_ci_files {
    if (-e "$work_dir/github_ci_default.yml") {
        unlink "$work_dir/github_ci_default.yml" or die $!;
    }
    is -e "$work_dir/github_ci_default.yml", undef, "temp github actions file deleted ok";
}
sub unlink_makefile {
    if (-e "$work_dir/Makefile.PL") {
        unlink "$work_dir/Makefile.PL" or die $!;
    }
    is -e "$work_dir/Makefile.PL", undef, "temp makefile deleted ok";
}
sub unlink_module_files {
    for (find_module_files($work_dir)) {
        if (-e $_) {
            unlink $_ or die $!;
        }
        is -e $_, undef, "unlinked $_ file ok";
    }
}
sub unlink_manifest {
    if (-e "$work_dir/MANIFEST.SKIP") {
        unlink "$work_dir/MANIFEST.SKIP" or die $!;
    }
    is -e "$work_dir/MANIFEST.SKIP", undef, "temp MANIFEST.SKIP deleted ok";

    if (-e "$work_dir/manifest.t") {
        unlink "$work_dir/manifest.t" or die $!;
    }
    is -e "$work_dir/manifest.t", undef, "temp manifest.t deleted ok";
}
sub unlink_git_ignore {
    if (-e "$work_dir/.gitignore") {
        unlink "$work_dir/.gitignore" or die $!;
    }
    is -e "$work_dir/.gitignore", undef, "temp .gitignore deleted ok";
}

sub file_compare {
    my ($new, $orig) = @_;

    if (! defined $new || ! defined $orig) {
        croak("file_compare() requires 'new' and 'orig' file name params");
    }

    open my $new_fh, '<', $new or croak("Can't open $new: $!");
    open my $orig_fh, '<', $orig or croak("Can't open $new: $!"); # 'original' custom

    my @new = <$new_fh>;
    my @orig = <$orig_fh>;

    close $new_fh or die $!;
    close $orig_fh or die $!;

    for (0..$#new) {
        is $new[$_], $orig[$_], "Updated Changes file line $_ matches template custom ok";
    }
}
sub file_scalar {
    my ($fname) = @_;
    my $contents;

    {
        local $/;
        open my $fh, '<', $fname or die $!;
        $contents = <$fh>;
    }
    return $contents;
}
sub find_module_files {
    my ($dir) = @_;

    croak("find_module_files() needs \$dir param") if ! defined $dir;

    return File::Find::Rule->file()
        ->name('*.pm')
        ->in($dir);
}
sub sha1sum {
    my ($file) = @_;

    croak("shasum needs file param") if ! defined $file;

    my $sha1 = Digest::SHA->new;

    $sha1->addfile($file, 'U');

    return $sha1->hexdigest;
}
sub trap_warn {
    # enable/disable sinking our own internal warnings to prevent
    # cluttered test output

    my ($bool) = shift;

    croak("trap() needs a bool param") if ! defined $bool;

    if ($bool) {
        $SIG{__WARN__} = sub {
            my $w = shift;

            if ($w =~ /valid version/ || $w =~ /VERSION definition/) {
                return;
            }
            else {
                warn $w;
            }
        }
    }
    else {
        $SIG{__WARN__} = sub { warn shift; }
    }
}

sub module_args {
    my %module_args = (
        author  => 'Test Author',
        email   => 'test@example.com',
        modules => [qw(Acme-STEVEB)],
        license => 'artistic2',
        builder => 'ExtUtils::MakeMaker',
    );

    return %module_args;
}

sub mkdir_init {
    if (! -e $init_dir) {
        mkdir $init_dir or die $!;
    }
}

sub remove_ci {
    if (-e $ci_dir) {
        is rmtree("$work_dir/ci") >= 1, 1, "removed ci dir structure ok";
    }
    is -e $ci_dir, undef, "ci dir removed ok";
}
sub remove_init {
    if (-e $init_dir) {
        is rmtree("$work_dir/init") >= 1, 1, "removed init dir structure ok";
    }
    is -e $init_dir, undef, "init dir removed ok";
}
sub remove_unwanted {
    if (-e $unwanted_dir) {
        is rmtree("$work_dir/unwanted") >= 1, 1, "removed unwanted dir structure ok";
    }
    is -e $unwanted_dir, undef, "unwanted dir removed ok";
}

sub release_version {
    my ($v) = @_;
    die "release_version() needs version param" if ! defined $v;
    my $file = "$ENV{DIST_MGR_REPO_DIR}/acme-steveb/lib/Acme/STEVEB.pm";
    $v = sprintf("%.2f", $v + '0.01');
    version_bump($v, $file);
}
sub verify_clean {
    is(scalar(find_module_files($work_dir)), 0, "all work module files unlinked ok");
}

1;