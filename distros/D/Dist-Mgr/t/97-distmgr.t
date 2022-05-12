use warnings;
use strict;

use Capture::Tiny qw(:all);
use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use File::Copy;
use File::Find::Rule;
use File::Path qw(make_path rmtree);
use File::Find;
use JSON;
use Test::More;
use Dist::Mgr qw(:private);
use version;

BEGIN {
    # DIST_MGR_REPO_DIR eg. /home/spek/repos

    if (!$ENV{DIST_MGR_GIT_TEST} || !$ENV{DIST_MGR_REPO_DIR}) {
        plan skip_all => "DIST_MGR_GIT_TEST and DIST_MGR_REPO_DIR env vars must be set";
    }
}

use lib 't/lib';
use Helper qw(:all);

my @phases = qw(create dist cycle install release);

my $repos_dir = $ENV{DIST_MGR_REPO_DIR};
my $repo = 'test-module';
my $repo_dir = "$repos_dir/$repo";

my $cwd = getcwd();

my %cpan_args = (
    dry_run     => 1,
);

# create
{
    before ('create');

    system("rm", "-rf", $repo_dir);

    my @create_cmd_list = (
        'distmgr',
        'create',
        '--destroy',
        '-m Test::Module',
        '-a "Steve Bertrand"',
        '-e steveb@cpan.org',
        '-r test-module',
        '-u stevieb9',
    );

    my $cmd = join ' ', @create_cmd_list;
    my $output = `$cmd`;

    my $tpl_dir = "$cwd/t/data/distmgr/create_test-module";
    copy_second_module($tpl_dir, 'create');

    compare_files($tpl_dir, 'create');

    # NOTE: Do not remove the repo dir... we need it for the release test

    after();
}
# release
{
    before('release');

    my $cmd = 'distmgr release --nowait -d'; # no wait CI, dryrun CPAN
    my $output = `$cmd`;

    my $tpl_dir = "$cwd/t/data/distmgr/release_test-module";
    compare_files($tpl_dir, 'release');

    after();
}

# cycle
{
    before('cycle');

    my $pre_cycle_versions = version_info();

    my $cmd = 'distmgr cycle';
    my $output = `$cmd`;

    my $tpl_dir = "$cwd/t/data/distmgr/cycle_test-module";
    compare_files($tpl_dir, 'cycle');

    after();

    system("rm", "-rf", $repo_dir);
}

# dist
{
    system("rm", "-rf", 't/temp');
    mkdir 't/temp' or die "Can't create t/temp dir: $!";

    before ('dist');

    my @dist_cmd_list = (
        'distmgr',
        'dist',
        '-m Test::Module',
        '-a "Steve Bertrand"',
        '-e steveb@cpan.org',
    );

    my $cmd = join ' ', @dist_cmd_list;
    my $output = `$cmd`;

    chdir 'Test-Module' or die "Can't change into Test-Module/ dir: $!";
    like getcwd(), qr|t/temp/Test-Module$|, "in t/temp/Test-Modules ok";

    my $tpl_dir = "$cwd/t/data/distmgr/dist_test-module";
    copy_second_module($tpl_dir, 'dist');

    compare_files($tpl_dir, 'dist');

    # NOTE: Don't delete the temp dir!

    after();
}

# install
{
    before('install');

    # --ci

    is -e '.github/workflows/github_ci_default.yml', undef, "CI not created yet ok";
    `distmgr install --ci --repo test-module --user stevieb9`;

    file_count(18, "--ci");
    is -e '.github/workflows/github_ci_default.yml', 1, "CI config in place ok";
    check_file(
        '.github/workflows/github_ci_default.yml',
        qr/PL2Bat/,
        "our custom CI config file is in place ok"
    );

    # --gitignore

    is -e '.gitignore', undef, ".gitignore not created yet ok";
    git_ignore();
    is -e '.gitignore', 1, ".gitignore in place ok";
    check_file('.gitignore', qr/BB-Pass/, "our custom .gitignore is in place ok");

    # --badges

    `distmgr install --badges -u stevieb9 -r test-module`;
    check_file('lib/Test/Module.pm', qr/=for html/, "ci_badges() has html for loop ok");
    check_file('lib/Test/Module.pm', qr/coveralls/, "ci_badges() dropped coveralls ok");
    check_file('lib/Test/Module.pm', qr/workflows/, "ci_badges() dropped github actions ok");

    # --bugtracker

    `distmgr install --bugtracker -u stevieb9 -r test-module`;
    check_file('Makefile.PL', qr/META_MERGE/, "bugtrack META_MERGE added ok");
    check_file('Makefile.PL', qr/bugtracker/, "bugtracker added ok");

    # --repository

    `distmgr install --repository -u stevieb9 -r test-module`;
    check_file('Makefile.PL', qr/META_MERGE/, "repo META_MERGE added ok");
    check_file('Makefile.PL', qr/repository/, "repository added ok");

    after();

    system("rm", "-rf", 't/temp');
}

# config
{
    my $file = config_file();

    remove_config($file);
    is -e $file, undef, 'no config file present ok';

    `distmgr config`;

    is -e $file, 1, 'config file present ok';

    my $data = get_config($file);

    is ref $data, 'HASH', "config file data is a href ok";

    is $data->{cpan_id}, '', "cpan_id empty string ok";
    is $data->{cpan_pw}, '', "cpan_pw empty string ok";

    remove_config($file);
    is -e $file, undef, 'no config file present ok';
}

cpan_restore();

done_testing;

sub before {
    my ($phase) = @_;
    if (! defined $phase || ! grep /$phase/, @phases) {
        croak( "before() needs a phase sent in");
    }

    if ($phase eq 'create') {
        chdir $repos_dir or die "Can't chdir to $repos_dir";
        like getcwd(), qr/$repos_dir$/, "in $repos_dir directory ok";
        die "Not in $repos_dir!" if getcwd() !~ /$repos_dir$/;
    }
    elsif ($phase eq 'dist') {
        chdir 't/temp' or die "Can't chdir to t/temp";
        like getcwd(), qr/t\/temp$/, "in t/temp directory ok";
        die "Not in t/temp!" if getcwd() !~ /t\/temp$/;
    }
    elsif ($phase eq 'install') {
        chdir 't/temp/Test-Module' or die "Can't chdir to t/temp/Test-Module";
        like getcwd(), qr/t\/temp\/Test-Module$/, "in t/temp/Test-Module directory ok";
        die "Not in t/temp/Test-Module!" if getcwd() !~ /t\/temp\/Test-Module$/;
    }
    elsif ($phase eq 'release' || $phase eq 'cycle') {
        chdir $repo_dir or die "Can't chdir to $repo_dir";
        like getcwd(), qr/$repo_dir$/, "in $repo_dir directory ok";
        die "Not in $repo_dir: $!" if getcwd() !~ /$repo_dir$/;
    }
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), _dist_dir_re(), "back in root directory $cwd ok";
}
sub file_count {
    my ($expected_count, $msg) = @_;
    die "need \$msg in file_count()" if ! defined $msg;
    my $fs_entry_count;
    find (sub {$fs_entry_count++;}, '.');
    is $fs_entry_count, $expected_count, "num files: $expected_count,  $msg";
}
sub check_file {
    my ($file, $regex, $msg) = @_;
    open my $fh, '<', $file or die $!;
    my @contents = <$fh>;
    close $fh;
    is grep(/$regex/, @contents) >= 1, 1, $msg;
}
sub copy_second_module {
    my ($src, $phase) = @_;

    croak("copy_second_module needs src dir sent in") if ! defined $src;

    if (! defined $phase || ! grep /$phase/, @phases) {
        croak( "copy_second_module() needs a phase sent in. You sent $phase");
    }

    my $dir;
    $dir = $repo_dir if $phase eq 'create';
    $dir = $repo_dir if $phase eq 'release';
    $dir = "$cwd/t/temp/Test-Module" if $phase eq 'dist';

    make_path "$dir/lib/Test/Module" or die "Can't create 'lib/Test/Module' dir in $dir";
    copy
        "$src/lib/Test/Module/Second.pm",
        "$dir/lib/Test/Module/Second.pm"
    or die "Can't copy Second.pm: $!";

    is -e "$dir/lib/Test/Module/Second.pm", 1, "Second.pm copied ok to $dir/lib/Test/Module";

}
sub compare_files {
    if (@_ != 2) {
        die "compare_files() needs \$tpl dir, and 'phase' sent in\n";
    }

    my ($tpl, $phase) = @_;
    my $dir;
    $dir = $repo_dir if $phase eq 'create';
    $dir = $repo_dir if $phase eq 'cycle';
    $dir = $repo_dir if $phase eq 'release';
    $dir = "$cwd/t/temp/Test-Module" if $phase eq 'dist';

    chdir $dir or die "Can't go into $dir: $!\n";
    like getcwd(), qr/$dir$/, "in $dir directory ok";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($tpl);
    my $file_count = 0;

    if (1) {
        my @files;
        for my $tf (@template_files) {
            (my $nf = $tf) =~ s/$tpl\///;
            # nf == new file
            # tf == template file
            if (-f $nf) {
                next if $nf =~ m|^\.git/|;

                push @files, $nf;
                open my $tfh, '<', $tf or die $!;
                open my $nfh, '<', $nf or die $!;

                my @tf = <$tfh>;
                my @nf = <$nfh>;

                close $tfh;
                close $nfh;

                for (0 .. $#tf) {
                    if ($nf eq 'Changes') {
                        if ($_ == 2) {
                            # create
                            if ($phase =~ /^create$/) {
                                # UNREL/Date line
                                like $nf[$_], qr/0\.01 UNREL/, "Changes line 2 phase '$phase' contains UNREL ok";
                                next;
                            }
                            # release
                            if ($phase =~ /^release$/) {
                                # UNREL/Date line
                                like $nf[$_], qr/0\.01    \d{4}-\d{2}-\d{2}/, "Changes line 2 phase '$phase' has date ok";
                                unlike $nf[$_], qr/UNREL/, "Changes line 2 phase '$phase' no UNREL ok";
                                next;
                            }
                            # cycle
                            if ($phase =~ /^cycle$/) {
                                # UNREL/Date line
                                like $nf[$_], qr/0\.02 UNREL/, "Changes line 2 phase '$phase' contains UNREL ok";
                                next;
                            }
                        }
                        if ($_ == 5 && $phase eq 'cycle') {
                            like $nf[$_], qr/0\.01    \d{4}-\d{2}-\d{2}/, "Changes line 2 phase '$phase' has date ok";
                            next;
                        }
                        if ($nf[$_] =~ /^\s{4}-\s+$/) {
                            like $nf[$_], qr/^\s{4}-\s+$/, "line with only a dash ok";
                            next;
                        }
                    }
                    # Modules
                    if ($nf =~ m|lib/Test/.*\.pm|) {
                        if ($nf[$_] =~ /\$VERSION/) {
                            # VERSION
                            like $nf[$_], qr/\$VERSION = '\d+\.\d+'/, "Module has ver ok";
                            next;
                        }
                        if ($nf[$_] =~ /Copyright/) {
                            # Copyright
                            like $nf[$_], qr/Copyright.*\d{4}/, "Module has copyright ok";
                            next;
                        }
                    }
                    is $nf[$_], $tf[$_], "$dir/$nf file matches the template $tf line $_ ok";
                }
                $file_count++;
            }
        }
        my $base_count = scalar @template_files;
        is scalar $file_count, $base_count, "file count matches number of files in module template";
    }
    else {
        warn "SKIPPING $phase FILE COMPARE CHECKS!";
    }

    chdir $cwd or die "Can't go into $cwd: $!\n";
    like getcwd(), qr/$cwd$/, "in $cwd directory ok";
}
sub done {
    done_testing;
    exit;
}
sub get_config {
    my ($conf_file) = @_;
    {
        local $/;
        open my $fh, '<', $conf_file or die "can't open $conf_file: $!";
        my $json = <$fh>;
        my $perl = decode_json($json);
        return $perl;
    }
}
sub remove_config {
    my ($conf_file) = @_;

    if (-e $conf_file) {
        unlink $conf_file or die "Can't remove config file $conf_file: $!";
        is -e $conf_file, undef, "Removed config file $conf_file ok";
    }

    is -e $conf_file, undef, "(unlink) config file $conf_file doesn't exist ok";
}


