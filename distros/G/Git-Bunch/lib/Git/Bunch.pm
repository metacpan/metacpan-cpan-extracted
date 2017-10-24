package Git::Bunch;

our $DATE = '2017-10-19'; # DATE
our $VERSION = '0.620'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options 'system', 'readpipe', -log=>1, -lang=>'C';
use Cwd ();
use File::chdir;
use File::Path qw(make_path);
use List::Util qw(max);
use POSIX qw(strftime);
use String::ShellQuote;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(check_bunch sync_bunch exec_bunch);

our %SPEC;

$SPEC{":package"} = {
    v => 1.1,
    summary => 'Manage gitbunch directory (directory which contain git repos)',
    description => <<'_',

A _gitbunch_ or _bunch_ directory is just a term I coined to refer to a
directory which contains, well, a bunch of git repositories. It can also contain
other stuffs like files and non-git repositories (but they must be dot-dirs).
Example:

 repos/            -> a gitbunch dir
   proj1/          -> a git repo
   proj2/          -> ditto
   perl-Git-Bunch/ -> ditto
   ...
   .videos/        -> a non-git dir
   README.txt      -> file

If you organize your data as a bunch, you can easily check the status of your
repositories and synchronize your data between two locations, e.g. your
computer's harddisk and an external/USB harddisk.

A little bit of history: after _git_ got popular, in 2008 I started using it for
software projects, replacing Subversion and Bazaar. Soon, I moved everything*)
to git repositories: notes & writings, Emacs .org agenda files, configuration,
even temporary downloads/browser-saved HTML files. I put the repositories inside
_$HOME/repos_ and add symlinks to various places for conveniences. Thus, the
_$HOME/repos_ became the first bunch directory.

*) everything except large media files (e.g. recorded videos) which I put in
dot-dirs inside the bunch.

See also <prog:rsybak>, which I wrote to backup everything else.

_
    links => [
        {
            url => 'prog:rsybak',
        },
        {
            url => 'http://joeyh.name/code/mr/',
            description => <<'_',

You probably want to use this instead. _mr_ supports other control version
software aside from git, doesn't restrict you to put all your repos in one
directory, supports more operations, and has been developed since 2007. Had I
known about _mr_, I probably wouldn't have started gitbunch. On the other hand,
gitbunch is simpler (I think), doesn't require any config file, and can
copy/sync files/directories not under source control. I mainly use gitbunch to
quickly: 1) check whether there are any of my repositories which have
uncommitted changes; 2) synchronize (pull/push) to other locations. I put all my
data in one big gitbunch directory; I find it simpler. gitbunch works for me and
I use it daily.

_
        },
    ],
};

our %common_args = (
    source           => {
        summary      => 'Directory to check',
        schema       => ['str*'],
        req          => 1,
        pos          => 0,
    },
    include_repos    => {
        summary      => 'Specific git repos to sync, if not specified '.
            'all repos in the bunch will be processed',
        schema       => ['array' => {
            of => 'str*',
        }],
        tags => ['filter'],
    },
    repo             => {
        summary      => 'Only process a single repo',
        schema       => 'str*',
        tags => ['filter'],
    },
    # XXX option to only process a single non-git dir?
    # XXX option to only process a single file?
    include_repos_pat=> {
        summary      => 'Specify regex pattern of repos to include',
        schema       => ['str'],
        tags => ['filter'],
    },
    exclude_repos    => {
        summary      => 'Exclude some repos from processing',
        schema       => ['array*' => {of => 'str*'}],
        tags => ['filter'],
    },
    exclude_non_git_dirs => {
        summary      => 'Exclude non-git dirs from processing',
        schema       => ['bool'],
        description  => <<'_',

This only applies to and `sync_bunch` operations. Operations like `check_bunch`
and `exec_bunch` already ignore these and only operate on git repos.

_
        cmdline_aliases => {
            include_non_git_dirs => {
                summary => 'Alias for --no-exclude-non-git-dirs',
                schema  => ['bool*', is=>1],
                code    => sub { $_[0]{exclude_non_git_dirs} = 0 },
            },
        },
        tags => ['filter'],
    },
    exclude_files    => {
        summary      => 'Exclude files from processing',
        schema       => ['bool'],
    description      => <<'_',

This only applies to `sync_bunch` operations. Operations like `check_bunch` and
`exec_bunch` already ignore these and only operate on git repos.

_
        cmdline_aliases => {
            include_files => {
                summary => 'Alias for --no-exclude-files',
                schema  => ['bool*', is=>1],
                code    => sub { $_[0]{exclude_non_git_dirs} = 0 },
            },
        },
        tags => ['filter'],
    },
    exclude_repos_pat=> {
        summary      => 'Specify regex pattern of repos to exclude',
        schema       => ['str'],
        tags => ['filter'],
    },
    min_repo_access_time => {
        summary => 'Limit to repos that are accessed (mtime, committed, status-ed, pushed) recently',
        description => <<'_',

This can significantly reduce the time to process the bunch if you are only
interested in recent repos (which is most of the time unless you are doing a
full check/sync).

_
        schema => ['date*', 'x.perl.coerce_rules' => ['str_alami_en']],
        tags => ['filter'],
    },
);

our %sort_args = (
    sort             => {
        summary      => 'Order entries',
        schema       => ['str' => {
            in      => [qw/name -name
                           mtime -mtime
                           commit_time -commit_time
                           status_time -status_time
                           pull_time   -pull_time
                          /],
        }],
    },
);

our %target_args = (
    target           => {
        summary      => 'Destination bunch',
        schema       => ['str*'],
        req          => 1,
        pos          => 1,
    },
);

sub _check_common_args {
    my ($args, $requires_target) = @_;
    my $res;

    $args->{source} or return [400, "Please specify source"];
    $args->{source} =~ s!/+$!!;
    $res = _check_bunch_sanity(\$args->{source}, 'Source');
    return $res unless $res->[0] == 200;

    my $ir = $args->{include_repos};
    return [400, "include_repos must be an array"]
        if defined($ir) && ref($ir) ne 'ARRAY';
    my $irp = $args->{include_repos_pat};
    if (defined $irp) {
        return [400, "Invalid include_repos_pat: must be a string"]
            if ref($irp);
        return [400, "Invalid include_repos_pat: $@"]
            if !(eval q{qr/$irp/});
    }
    my $er = $args->{exclude_repos};
    return [400, "exclude_repos must be an array"]
        if defined($er) && ref($er) ne 'ARRAY';
    my $erp = $args->{exclude_repos_pat};
    if (defined $erp) {
        return [400, "Invalid exclude_repos_pat: must be a string"]
            if ref($erp);
        return [400, "Invalid exclude_repos_pat: must be a string"]
            if !(eval q{qr/$erp/});
    }

    if ($requires_target) {
        $args->{target} or return [400, "Please specify target"];
        $res = _check_bunch_sanity(\$args->{target}, 'Target', 0);
        return $res unless $res->[0] == 200;
    }

    [200];
}

# return 1 if normal git repo, 2 if bare git repo, 0 if not repo
sub _is_repo {
    my $dir = shift;

    return 0 unless (-d $dir);
    return 1 if (-d "$dir/.git");
    return 2 if (-d "$dir/branches") && (-f "$dir/HEAD");
    0;
}

# return true if entry should be skipped
sub _skip_process_entry {
    use experimental 'smartmatch';

    my ($e, $args, $dir, $skip_non_repo) = @_;

    # skip special files
    if ($e->{name} =~ /\A(repos\.db|\.gitbunch-sync-timestamp)\z/) {
        log_debug("Skipped $e->{name} (special files)");
        return 1;
    }

    my $is_repo = $e->{type} eq 'r';

    if (defined $args->{repo}) {
        # avoid logging all the skipped messages if user just wants to process a
        # single repo
        return 1 unless $is_repo;
        return 1 unless $args->{repo} eq $e;
        return 0;
    }

    if ($skip_non_repo && !$is_repo) {
        log_debug("Skipped $e->{name} (not a git repo), ".
                        "please remove it or rename to .$e->{name}");
        return 1;
    }
    if ($is_repo) {
        my $ir = $args->{include_repos};
        if ($ir && !($e->{name} ~~ @$ir)) {
            log_debug("Skipped $e->{name} (not in include_repos)");
            return 1;
        }
        my $irp = $args->{include_repos_pat};
        if (defined($irp) && $e->{name} !~ qr/$irp/) {
            log_debug("Skipped $e->{name} (not matched include_repos_pat)");
            return 1;
        }
        my $er = $args->{exclude_repos};
        if ($er && $e->{name} ~~ @$er) {
            log_debug("Skipped $e->{name} (in exclude_repos)");
            return 1;
        }
        my $erp = $args->{exclude_repos_pat};
        if (defined($erp) && $e->{name} =~ qr/$erp/) {
            log_debug("Skipped $e->{name} (not matched exclude_repos_pat)");
            return 1;
        }
        my $min_rat = $args->{min_repo_access_time};
        if ($min_rat && max(grep {defined} $e->{mtime}, $e->{commit_time}, $e->{status_time}, $e->{pull_time}) < $min_rat) {
            log_debug("Skipped $e->{name} (doesn't pass min_repo_access_time)");
            return 1;
        }
    } elsif ((-f $dir) && $args->{exclude_files}) {
        log_debug("Skipped $e->{name} (exclude_files)");
        return 1;
    } elsif ((-d $dir) && $args->{exclude_non_git_dirs}) {
        log_debug("Skipped $e->{name} (exclude_non_git_dirs)");
        return 1;
    }
    return 0;
}

sub _skip_process_repo {
    my ($repo, $args, $dir) = @_;
    _skip_process_entry($repo, $args, $dir, 1);
}

sub _check_bunch_sanity {
    my ($path_ref, $title, $must_exist) = @_;
    $title //= "Directory";
    $$path_ref =~ s!/+$!!;
    if ($must_exist // 1) {
        (-d $$path_ref) or return [404, "$title doesn't exist"];
    }
    _is_repo($$path_ref) and
        return [400, "$title is probably a git repo, ".
                    "you should specify a dir *containing* ".
                        "git repos instead"];
    [200, "OK"];
}

sub _list {
    my $args = shift;

    my @entries;
    @entries = do {
        opendir my ($dh), "." or die "Can't read dir '$args->{source}': $!";
        map { +{name => $_} } grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    };
    for my $e (@entries) {
        my @st = stat $e->{name};
        $e->{mtime} = $st[9];
        if (-d _) {
            if ($e->{name} =~ /\A\./) {
                $e->{type} = 'd';

                # to save stat() call, we assume any dir that does not start
                # with dot to be a repo

            #} elsif (-d "$e->{name}/.git") {
            #    $e->{type} = 'r';

            } else {
                $e->{type} = 'r';
            }
        } else {
            $e->{type} = 'f';
        }
    }
    {
        #last unless $sort =~ /\A-?(commit_time|status_time|pull_time)/;
        last unless -f "repos.db";
        require DBI;
        my $dbh = DBI->connect("dbi:SQLite:dbname=repos.db", "", "",
                               {RaiseError=>1});
        my $sth = $dbh->prepare("SELECT * FROM repos");
        $sth->execute;
        my %rows;
        while (my $row = $sth->fetchrow_hashref) {
            $rows{$row->{name}} = $row;
        }
        for my $e (@entries) {
            next unless my $row = $rows{$e->{name}};
            for (qw/commit_time status_time pull_time/) {
                $e->{$_} = $row->{$_};
            }
        }
    }
    @entries;
}

sub _sort_entries_by_recent {
    no warnings 'uninitialized';
    sort {
        my $sort_a = max($a->{commit_time}, $a->{pull_time}, $a->{status_time}, $a->{mtime});
        my $sort_b = max($b->{commit_time}, $b->{pull_time}, $b->{status_time}, $b->{mtime});
        $sort_b <=> $sort_a;
    } @_;
}

$SPEC{check_bunch} = {
    v             => 1.1,
    summary       =>
        'Check status of git repositories inside gitbunch directory',
    description   => <<'_',

Will perform a 'git status' for each git repositories inside the bunch and
report which repositories are clean/unclean.

Will die if can't chdir into bunch or git repository.

_
    args          => {
        %common_args,
    },
    deps => {
        all => [
            {prog => 'git'},
        ],
    },
    features => {
        progress => 1,
        dry_run => 1,
    },
};
sub check_bunch {
    use experimental 'smartmatch';

    my %args = @_;
    my $res;

    my $progress = $args{-progress};

    # XXX schema
    $res = _check_common_args(\%args);
    return $res unless $res->[0] == 200;
    my $source = $args{source};

    log_info("Checking bunch $source ...");

    my $has_unclean;
    my %res;
    local $CWD = $source;

    my @entries = _list(\%args);

    my $i = 0;
    $progress->pos(0) if $progress;
    $progress->target(~~@entries) if $progress;
  REPO:
    for my $e (@entries) {
        my $repo = $e->{name};
        next REPO if _skip_process_repo($e, \%args, ".");
        $CWD = $i++ ? "../$repo" : $repo;

        $progress->update(pos => $i,
                          message =>
                              "Checking repo $repo ...")
            if $progress;

        if ($args{-dry_run}) {
            log_info("[DRY-RUN] checking status of repo %s", $repo);
            next REPO;
        }

        my $output = readpipe("git status 2>&1");
        my $exit = $? >> 8;
        if ($exit == 0 && $output =~ /nothing to commit/) {
            log_info("$repo is clean");
            $res{$repo} = [200, "Clean"];
            next;
        }

        $has_unclean++;
        if ($exit == 0 &&
                $output =~ /(
                                Changes \s to \s be \s committed |
                                Changes \s not \s staged \s for \s commit |
                                Changed \s but
                            )/mx) {
            log_warn("$repo needs commit");
            $res{$repo} = [500, "Needs commit"];
        } elsif ($exit == 0 &&
                     $output =~ /(
                                     Untracked \s files
                                 )/x) {
            log_warn("$repo has untracked files");
            $res{$repo} = [500, "Has untracked files"];
        } elsif ($exit == 0 && $output =~ /Unmerged paths:/) {
            log_warn("$repo needs merging");
            $res{$repo} = [500, "Needs merging"];
        } elsif ($exit == 128 && $output =~ /Not a git repository/) {
            log_warn("$repo is not a git repo (2)");
            $res{$repo} = [500, "Not a git repo (2)"];
        } else {
            log_error("Can't figure out result of 'git status' ".
                            "for repo $repo: exit=$exit, output=$output");
            $res{$repo} = [500, "Unknown (exit=$exit, output=$output)"];
        }
    }
    $progress->finish if $progress;
    [200,
     $has_unclean ? "Some repos unclean" : "All repos clean",
     \%res,
     {'cmdline.result'=>'', 'func.res'=>\%res}];
}

$SPEC{list_bunch_contents} = {
    v             => 1.1,
    summary       =>
        'List contents inside gitbunch directory',
    description   => <<'_',

Will list each repo or non-repo dir/file.

_
    args          => {
        %common_args,
        %sort_args,
        detail => {
            summary =>
                'Show detailed record for each entry instead of just its name',
            schema => 'bool',
            cmdline_aliases => {l => {}},
        },
    },
    features => {
    },
};
sub list_bunch_contents {
    use experimental 'smartmatch';

    my %args = @_;

    # XXX schema
    my $res = _check_common_args(\%args);
    return $res unless $res->[0] == 200;
    my $source = $args{source};
    my $sort = $args{sort} // '';

    local $CWD = $source;

    my @entries = _list(\%args);

    if ($sort) {
        no warnings 'uninitialized';
        my $sortsub;
        my ($rev, $field);
        if (($rev, $field) = $sort =~ /\A(-)?(mtime|commit_time|status_time|pull_time)/) {
            $sortsub = sub { ($rev ? -1:1) * ($a->{$field} <=> $b->{$field}) };
        } elsif (($rev, $field) = $sort =~ /\A(-)?(name)/) {
            $sortsub = sub { ($rev ? -1:1) * ($a->{$field} cmp $b->{$field}) };
        }
        @entries = sort $sortsub @entries;
    }
    #log_trace("entries: %s", \@entries);

    my @res;
  ENTRY:
    for my $e (@entries) {
        next ENTRY if _skip_process_entry($e, \%args, ".");
        push @res, $e;
    }

    my %resmeta;
    if ($args{detail}) {
        $resmeta{'table.fields'} =
            [qw/name type mtime commit_time status_time pull_time/];
        $resmeta{'table.field_formats'} =
            [undef, undef, 'iso8601_datetime', 'iso8601_datetime', 'iso8601_datetime', 'iso8601_datetime'];
    } else {
        @res = map { $_->{name} } @res;
    }
    [200, "OK", \@res, \%resmeta];
}

sub _sync_repo {
    use experimental 'smartmatch';

    my ($src, $dest, $repo, $opts) = @_;
    my $exit;

    my @src_branches;
    my @dest_branches;
    my %src_heads;  # last revisions for each branch
    my %dest_heads; # last revisions for each branch

    local $CWD = "$src/$repo";
    @src_branches = map {(/^[* ] (.+)/, $1)[-1]} readpipe("git branch");
    $exit = $? >> 8;
    if ($exit) {
        log_error("Can't list branches on src repo $src/$repo: $exit");
        return [500, "Can't list source branches"];
    }
    log_debug("Source branches: %s", \@src_branches);

    for my $branch (@src_branches) {
        my $output = readpipe("git log -1 '$branch'");
        $exit = $? >> 8;
        if ($exit) {
            log_error("Can't find out head for branch $branch on src repo ".
                            "$src/$repo: $exit");
            return [500, "Can't find out head for source branch $branch"];
        }
        $output =~ /commit (\S+)/ or do {
            log_error("Can't recognize git log output ".
                            "(searching for commit XXX): $output");
            return [500, "Can't recognize git log output on src: $output"];
        };
        $src_heads{$branch} = $1;
    }
    log_debug("Source branch heads: %s", \%src_heads);

    $CWD = "$dest/$repo";
    my $is_bare = _is_repo(".") == 2;
    @dest_branches = map {(/^[* ] (.+)/, $1)[-1]} readpipe("git branch");
    if ($exit) {
        log_error("Can't list branches on dest repo $repo: $exit");
        return [500, "Can't list branches on dest: $exit"];
    }
    log_debug("Dest branches: %s", \@dest_branches);
    for my $branch (@dest_branches) {
        my $output = readpipe("git log -1 '$branch'");
        $exit = $? >> 8;
        if ($exit) {
            log_error("Can't find out head for branch $branch on dest repo ".
                            "$dest/$repo: $exit");
            return [500, "Can't find out head for dest branch $branch"];
        }
        $output =~ /commit (\S+)/ or do {
            log_error("Can't recognize git log output ".
                            "(searching for commit XXX): $output");
            return [500, "Can't recognize git log output on src: $output"];
        };
        $dest_heads{$branch} = $1;
    }
    log_debug("Dest branch heads: %s", \%dest_heads);

    my $output;
    my $lock_deleted;
    my $changed_branch;
  BRANCH:
    for my $branch (@src_branches) {
        # XXX we should allow fetching tags only even if head is the same, but
        # right now tags are not that important
        if ($src_heads{$branch} && $dest_heads{$branch} &&
                $src_heads{$branch} eq $dest_heads{$branch}) {
            log_debug("Skipping branch $branch because heads are the same");
            next BRANCH;
        }
        $changed_branch++;
        if (0 && !$lock_deleted++) {
            log_debug("Deleting locks first ...");
            unlink "$src/$repo" .($is_bare ? "" : "/.git")."/index.lock";
            unlink "$dest/$repo".($is_bare ? "" : "/.git")."/index.lock";
        }
        log_info("Updating branch $branch of repo $repo ...")
            if @src_branches > 1;
        if ($is_bare) {
            $output = readpipe(
                join("",
                     "cd '$src/$repo'; ",
                     "git push '$dest/$repo' '$branch' 2>&1",
                 ));
        } else {
            $output = readpipe(
                join("",
                     "cd '$dest/$repo'; ",
                     ($branch ~~ @dest_branches ? "":"git branch '$branch'; "),
                     "git checkout '$branch' 2>/dev/null; ",
                     "git pull '$src/$repo' '$branch' 2>&1"
                 ));
        }
        $exit = $? >> 8;
        if ($exit == 0 && $output =~ /Already up-to-date/) {
            log_debug("Branch $branch of repo $repo is up to date");
            next BRANCH;
        } elsif ($output =~ /^error: (.+)/m) {
            log_error("Can't successfully git pull/push branch $branch of ".
                            "repo $repo: $1");
            return [500, "git pull/push branch $branch failed: $1"];
        } elsif ($exit == 0 &&
                     $output =~ /^Updating \s|
                                 ^Merge \s made \s by \s recursive|
                                 ^Merge \s made \s by \s the \s 'recursive'|
                                /mx) {
            log_warn("Branch $branch of repo $repo updated")
                if @src_branches > 1;
            log_warn("Repo $repo updated")
                if @src_branches == 1;
        } else {
            log_error(
                "Can't recognize 'git pull/push' output for branch ".
                    "$branch of repo $repo: exit=$exit, output=$output");
            return [500, "Can't recognize git pull/push output: $output"];
        }
        log_debug("Result of 'git pull/push' for branch $branch of repo ".
                        "$repo: exit=$exit, output=$output");

        $output = readpipe("cd '$dest/$repo'; ".
                               "git fetch --tags '$src/$repo' 2>&1");
        $exit = $? >> 8;
        if ($exit != 0) {
            log_debug("Failed fetching tags: ".
                            "$output (exit=$exit)");
            return [500, "git fetch --tags failed: $1"];
        }
    }

    if ($opts->{delete_branch}) {
        for my $branch (@dest_branches) {
            next if $branch ~~ @src_branches;
            next if $branch eq 'master'; # can't delete master branch
            $changed_branch++;
            log_info("Deleting branch $branch of repo $repo because ".
                           "it no longer exists in src ...");
            system("cd '$dest/$repo' && git checkout master 2>/dev/null && ".
                       "git branch -D '$branch' 2>/dev/null");
            $exit = $? >> 8;
            log_error("Failed deleting branch $branch of repo $repo: $exit")
                if $exit;
        }
    }

    if ($changed_branch) {
        return [200, "OK"];
    } else {
        return [304, "Not modified"];
    }
}

$SPEC{sync_bunch} = {
    v             => 1.1,
    summary       =>
        'Synchronize bunch to another bunch',
    description   => <<'_',

For each git repository in the bunch, will perform a 'git pull/push' for each
branch. If repository in destination doesn't exist, it will be rsync-ed first
from source. When 'git pull' fails, will exit to let you fix the problem
manually.

For all other non-repo file/directory, will simply synchronize by one-way rsync.
But, for added safety, will first check the newest mtime (mtime of the newest
file or subdirectory) between source and target is checked first. If target
contains the newer newest mtime, rsync-ing for that non-repo file/dir will be
aborted. Note: you can use `--skip-mtime-check` option to skip this check.

_
    args          => {
        %common_args,
        %target_args,
        delete_branch    => {
            summary      => 'Whether to delete branches in dest repos '.
                'not existing in source repos',
            schema       => ['bool' => default => 0],
        },
        rsync_opt_maintain_ownership => {
            summary      => 'Whether or not, when rsync-ing from source, '.
                'we use -a (= -rlptgoD) or -rlptD (-a minus -go)',
            schema       => ['bool' => default => 0],
            description  => <<'_',

Sometimes using -a results in failure to preserve permission modes on
sshfs-mounted filesystem, while -rlptD succeeds, so by default we don't maintain
ownership. If you need to maintain ownership (e.g. you run as root and the repos
are not owned by root), turn this option on.

_
        },
        rsync_del => {
            summary => 'Whether to use --del rsync option',
            schema => 'bool',
            description => <<'_',

When rsync-ing non-repos, by default `--del` option is not used for more safety
because rsync is a one-way action. To add rsync `--del` option, enable this

_
        },
        skip_mtime_check => {
            summary => 'Whether or not, when rsync-ing non-repos, '.
                'we check mtime first',
            schema => ['bool'],
            description => <<'_',

By default when we rsync a non-repo file/dir from source to target and both
exist, to protect wrong direction of sync-ing we find the newest mtime in source
or dir (if dir, then the dir is recursively traversed to find the file/subdir
with the newest mtime). If target contains the newer mtime, the sync for that
non-repo file/dir is aborted. If you want to force the rsync anyway, use this
option.

_
        },
        create_bare_target => {
            summary      => 'Whether to create bare git repo '.
                'when target does not exist',
            schema       => ['bool'],
            description  => <<'_',

When target repo does not exist, gitbunch can either copy the source repo using
`rsync` (the default, if this setting is undefined), or it can create target
repo with `git init --bare` (if this setting is set to 1), or it can create
target repo with `git init` (if this setting is set to 0).

Bare git repositories contain only contents of the .git folder inside the
directory and no working copies of your source files.

Creating bare repos are apt for backup purposes since they are more
space-efficient.

Non-repos will still be copied/rsync-ed.

_
            cmdline_aliases => {
                # old name, deprecated since v0.29, remove in later releases
                use_bare => {},
            },
        },
        backup => {
            summary     => 'Whether doing backup to target',
            schema      => ['bool'],
            description => <<'_',

This setting lets you express that you want to perform synchronizing to a backup
target, and that you do not do work on the target. Thus, you do not care about
uncommitted or untracked files/dirs in the target repos (might happen if you
also do periodic copying of repos to backup using cp/rsync). When this setting
is turned on, the function will first do a `git clean -f -d` (to delete
untracked files/dirs) and then `git checkout .` (to discard all uncommitted
changes). This setting will also implicitly turn on `create_bare` setting
(unless that setting has been explicitly enabled/disabled).

_
        },
    },
    deps => {
        all => [
            {prog => 'git'},
            {prog => 'rsync'},
            {prog => 'rsync-new2old'},
            {prog => 'touch'},
        ],
    },
    features => {
        progress => 1,
        dry_run => 1,
    },
};
sub sync_bunch {
    use experimental 'smartmatch';
    require Capture::Tiny;
    require UUID::Random;
    require App::reposdb;

    my %args = @_;
    my $res;

    my $progress = $args{-progress};

    # XXX schema
    $res = _check_common_args(\%args, 1);
    return $res unless $res->[0] == 200;
    my $delete_branch = $args{delete_branch} // 0;
    my $source = $args{source};
    my $target = $args{target};
    my $create_bare = $args{create_bare_target};
    my $backup = $args{backup};
    my $exit;

    $create_bare //= 1 if $backup;

    my $cmd;

    unless ((-d $target) || $args{-dry_run}) {
        log_debug("Creating target directory %s ...", $target);
        make_path($target)
            or return [500, "Can't create target directory $target: $!"];
    }
    $target = Cwd::abs_path($target);

    my $dbh_target;
    $dbh_target = App::reposdb::_connect_db({
        reposdb_path => "$target/repos.db",
    }) unless $args{-dry_run};

    my $_a = $args{rsync_opt_maintain_ownership} ? "aH" : "rlptDH";

    $source = Cwd::abs_path($source);

    local $CWD = $source;
    my @entries = _list(\%args);
    @entries = _sort_entries_by_recent(@entries) if $args{min_repo_access_time};
    #log_trace("entries: %s", \@entries);

    $CWD = $target;

    my %res;
    my $i = 0;
    $progress->pos(0) if $progress;
    $progress->target(~~@entries) if $progress;
  ENTRY:
    for my $e (@entries) {
        ++$i;
        next ENTRY if _skip_process_entry($e, \%args, "$source/$e->{name}");
        my $is_repo = _is_repo("$source/$e->{name}");
        if (!$is_repo) {
            my $file_or_dir = $e->{name};
            $progress->update(pos => $i,
                              message =>
                                  "Sync-ing non-git file/directory $file_or_dir ...")
                 if $progress;

            my $prog;
            my @extra_opts;
            if ($args{skip_mtime_check} || $args{-dry_run}) {
                $prog = "rsync";
            } else {
                $prog = "rsync-new2old";
                push @extra_opts, "--create-target-if-not-exists";
            }

            # just some random unique string so we can detect whether any
            # file/dir is modified/added to target. to check files deleted in
            # target, we use /^deleting /x
            my $uuid = UUID::Random::generate();
            my $_v = log_is_debug() ? "-v" : "";
            my $del = $args{rsync_del} ? "--del" : "";
            push @extra_opts, "--log-format=$uuid" unless $args{-dry_run};
            $cmd = join(
                "",
                $prog,
                $args{-dry_run} ? " --dry-run" : "",
                @extra_opts ? " " . join(" ", @extra_opts) : "",
                " -${_a}z $_v $del",
                " --force",
                " " . shell_quote("$source/$file_or_dir"),
                " .",
            );
            my ($stdout, @result) = log_is_debug() ?
                Capture::Tiny::tee_stdout    (sub { system($cmd) }) :
                Capture::Tiny::capture_stdout(sub { system($cmd) });
            if ($args{-dry_run}) {
                $res{$file_or_dir} = [304, "dry-run"];
                next ENTRY;
            } elsif ($result[0]) {
                log_warn("Rsync failed, please check: $result[0]");
                $res{$file_or_dir} = [500, "rsync failed: $result[0]"];
            } else {
                if ($stdout =~ /^(deleting |\Q$uuid\E)/m) {
                    log_warn("Non-git file/dir '$file_or_dir' updated");
                }
                $res{$file_or_dir} = [200, "rsync-ed"];
            }
            next ENTRY;
        }

        my $repo = $e->{name};
        my $created;
        if (!(-e $repo)) {
            if ($args{-dry_run}) {
                log_warn("[DRY RUN] Copying repo '%s'", $repo);
                next ENTRY;
            }
            if ($create_bare) {
                log_info("Initializing target repo $repo (bare) ...");
                $cmd = "mkdir ".shell_quote($repo)." && cd ".shell_quote($repo).
                    " && git init --bare";
                system($cmd);
                $exit = $? >> 8;
                if ($exit) {
                    log_warn("Git init failed, please check: $exit");
                    $res{$repo} = [500, "git init --bare failed: $exit"];
                    next ENTRY;
                }
                $created++;
                # continue to sync-ing
            } elsif (defined $create_bare) {
                log_info("Initializing target repo $repo (non-bare) ...");
                $cmd = "mkdir ".shell_quote($repo)." && cd ".shell_quote($repo).
                    " && git init";
                system($cmd);
                $exit = $? >> 8;
                if ($exit) {
                    log_warn("Git init failed, please check: $exit");
                    $res{$repo} = [500, "git init failed: $exit"];
                    next ENTRY;
                }
                $created++;
                # continue to sync-ing
            } else {
                $progress->update(pos => $i,
                                  message =>
                                      "Copying repo $repo ...")
                     if $progress;
                $cmd = "rsync -${_a}z ".shell_quote("$source/$repo")." .";
                system($cmd);
                $exit = $? >> 8;
                if ($exit) {
                    log_warn("Rsync failed, please check: $exit");
                    $res{$repo} = [500, "rsync failed: $exit"];
                } else {
                    $res{$repo} = [200, "rsync-ed"];
                }
                log_warn("Repo $repo copied");
                # touch pull time
                $dbh_target->do("INSERT OR IGNORE INTO repos (name) VALUES (?)",
                                {}, $repo);
                $dbh_target->do("UPDATE repos SET pull_time=? WHERE name=?",
                                {}, time(), $repo);
                next ENTRY;
            }
        }

        $progress->update(pos => $i, message => "Sync-ing repo $repo ...")
            if $progress;

        if ($args{-dry_run}) {
            log_warn("[DRY RUN] Sync-ing repo '%s'", $repo);
            next ENTRY;
        }

        if ($backup && !$created) {
            log_debug("Discarding changes in target repo $repo ...");
            local $CWD = $repo;
            system "git clean -f -d && git checkout .";
            # ignore error for now, let's go ahead and sync anyway
        }

        my $res = _sync_repo(
            $source, $target, $repo,
            {delete_branch => $delete_branch},
        );
        # touch pull time
        if ($res->[0] == 200) {
            $dbh_target->do("INSERT OR IGNORE INTO repos (name) VALUES (?)",
                            {}, $repo);
            $dbh_target->do("UPDATE repos SET pull_time=? WHERE name=?",
                            {}, time(), $repo);
        }
        $res{$repo} = $res;
    }
    system "touch", "$target/.gitbunch-sync-timestamp";

    $progress->finish if $progress;

    [200,
     "OK",
     \%res,
     {"cmdline.result" => ''}];
}

$SPEC{exec_bunch} = {
    v             => 1.1,
    summary       =>
        'Execute a command for each repo in the bunch',
    description   => <<'_',

For each git repository in the bunch, will chdir to it and execute specified
command.

_
    args          => {
        %common_args,
        command   => {
            summary  => 'Command to execute',
            schema   => ['str*'],
            req      => 1,
            pos      => 1,
            greedy   => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub exec_bunch {
    my %args = @_;
    my $res;
    my $exit;

    # XXX schema
    $res = _check_common_args(\%args);
    return $res unless $res->[0] == 200;
    my $source  = $args{source};
    my $command = $args{command};
    defined($command) or return [400, "Please specify command"];

    local $CWD = $source;
    my %res;
    my $i = 0;
    my @entries = _list(\%args);
    @entries = _sort_entries_by_recent(@entries) if $args{min_repo_access_time};
    #log_trace("entries: %s", \@entries);
  REPO:
    for my $e (@entries) {
        next REPO if _skip_process_repo($e, \%args, ".");
        my $repo = $e->{name};
        $CWD = $i++ ? "../$repo" : $repo;
        if ($args{-dry_run}) {
            log_info("[DRY-RUN] Executing command on $repo ...");
            next REPO;
        }
        log_info("Executing command on $repo ...");
        system($command);
        $exit = $? >> 8;
        if ($exit) {
            log_warn("Command failed: $exit");
            $res{$repo} = [500, "Command failed: $exit"];
        } else {
            $res{$repo} = [200, "Command successful"];
        }
        next REPO;
    }

    [200,
     "OK",
     \%res,
     {"cmdline.result" => ''}];
}

1;
# ABSTRACT: Manage gitbunch directory (directory which contain git repos)

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Bunch - Manage gitbunch directory (directory which contain git repos)

=head1 VERSION

This document describes version 0.620 of Git::Bunch (from Perl distribution Git-Bunch), released on 2017-10-19.

=head1 SYNOPSIS

See the included L<gitbunch> script.

=head1 DESCRIPTION


A I<gitbunch> or I<bunch> directory is just a term I coined to refer to a
directory which contains, well, a bunch of git repositories. It can also contain
other stuffs like files and non-git repositories (but they must be dot-dirs).
Example:

 repos/            -> a gitbunch dir
   proj1/          -> a git repo
   proj2/          -> ditto
   perl-Git-Bunch/ -> ditto
   ...
   .videos/        -> a non-git dir
   README.txt      -> file

If you organize your data as a bunch, you can easily check the status of your
repositories and synchronize your data between two locations, e.g. your
computer's harddisk and an external/USB harddisk.

A little bit of history: after I<git> got popular, in 2008 I started using it for
software projects, replacing Subversion and Bazaar. Soon, I moved everything*)
to git repositories: notes & writings, Emacs .org agenda files, configuration,
even temporary downloads/browser-saved HTML files. I put the repositories inside
I<$HOME/repos> and add symlinks to various places for conveniences. Thus, the
I<$HOME/repos> became the first bunch directory.

*) everything except large media files (e.g. recorded videos) which I put in
dot-dirs inside the bunch.

See also L<rsybak>, which I wrote to backup everything else.

=head1 FUNCTIONS


=head2 check_bunch

Usage:

 check_bunch(%args) -> [status, msg, result, meta]

Check status of git repositories inside gitbunch directory.

Will perform a 'git status' for each git repositories inside the bunch and
report which repositories are clean/unclean.

Will die if can't chdir into bunch or git repository.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_files> => I<bool>

Exclude files from processing.

This only applies to C<sync_bunch> operations. Operations like C<check_bunch> and
C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_non_git_dirs> => I<bool>

Exclude non-git dirs from processing.

This only applies to and C<sync_bunch> operations. Operations like C<check_bunch>
and C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_repos> => I<array[str]>

Exclude some repos from processing.

=item * B<exclude_repos_pat> => I<str>

Specify regex pattern of repos to exclude.

=item * B<include_repos> => I<array[str]>

Specific git repos to sync, if not specified all repos in the bunch will be processed.

=item * B<include_repos_pat> => I<str>

Specify regex pattern of repos to include.

=item * B<min_repo_access_time> => I<date>

Limit to repos that are accessed (mtime, committed, status-ed, pushed) recently.

This can significantly reduce the time to process the bunch if you are only
interested in recent repos (which is most of the time unless you are doing a
full check/sync).

=item * B<repo> => I<str>

Only process a single repo.

=item * B<source>* => I<str>

Directory to check.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 exec_bunch

Usage:

 exec_bunch(%args) -> [status, msg, result, meta]

Execute a command for each repo in the bunch.

For each git repository in the bunch, will chdir to it and execute specified
command.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<str>

Command to execute.

=item * B<exclude_files> => I<bool>

Exclude files from processing.

This only applies to C<sync_bunch> operations. Operations like C<check_bunch> and
C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_non_git_dirs> => I<bool>

Exclude non-git dirs from processing.

This only applies to and C<sync_bunch> operations. Operations like C<check_bunch>
and C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_repos> => I<array[str]>

Exclude some repos from processing.

=item * B<exclude_repos_pat> => I<str>

Specify regex pattern of repos to exclude.

=item * B<include_repos> => I<array[str]>

Specific git repos to sync, if not specified all repos in the bunch will be processed.

=item * B<include_repos_pat> => I<str>

Specify regex pattern of repos to include.

=item * B<min_repo_access_time> => I<date>

Limit to repos that are accessed (mtime, committed, status-ed, pushed) recently.

This can significantly reduce the time to process the bunch if you are only
interested in recent repos (which is most of the time unless you are doing a
full check/sync).

=item * B<repo> => I<str>

Only process a single repo.

=item * B<source>* => I<str>

Directory to check.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_bunch_contents

Usage:

 list_bunch_contents(%args) -> [status, msg, result, meta]

List contents inside gitbunch directory.

Will list each repo or non-repo dir/file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Show detailed record for each entry instead of just its name.

=item * B<exclude_files> => I<bool>

Exclude files from processing.

This only applies to C<sync_bunch> operations. Operations like C<check_bunch> and
C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_non_git_dirs> => I<bool>

Exclude non-git dirs from processing.

This only applies to and C<sync_bunch> operations. Operations like C<check_bunch>
and C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_repos> => I<array[str]>

Exclude some repos from processing.

=item * B<exclude_repos_pat> => I<str>

Specify regex pattern of repos to exclude.

=item * B<include_repos> => I<array[str]>

Specific git repos to sync, if not specified all repos in the bunch will be processed.

=item * B<include_repos_pat> => I<str>

Specify regex pattern of repos to include.

=item * B<min_repo_access_time> => I<date>

Limit to repos that are accessed (mtime, committed, status-ed, pushed) recently.

This can significantly reduce the time to process the bunch if you are only
interested in recent repos (which is most of the time unless you are doing a
full check/sync).

=item * B<repo> => I<str>

Only process a single repo.

=item * B<sort> => I<str>

Order entries.

=item * B<source>* => I<str>

Directory to check.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 sync_bunch

Usage:

 sync_bunch(%args) -> [status, msg, result, meta]

Synchronize bunch to another bunch.

For each git repository in the bunch, will perform a 'git pull/push' for each
branch. If repository in destination doesn't exist, it will be rsync-ed first
from source. When 'git pull' fails, will exit to let you fix the problem
manually.

For all other non-repo file/directory, will simply synchronize by one-way rsync.
But, for added safety, will first check the newest mtime (mtime of the newest
file or subdirectory) between source and target is checked first. If target
contains the newer newest mtime, rsync-ing for that non-repo file/dir will be
aborted. Note: you can use C<--skip-mtime-check> option to skip this check.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool>

Whether doing backup to target.

This setting lets you express that you want to perform synchronizing to a backup
target, and that you do not do work on the target. Thus, you do not care about
uncommitted or untracked files/dirs in the target repos (might happen if you
also do periodic copying of repos to backup using cp/rsync). When this setting
is turned on, the function will first do a C<git clean -f -d> (to delete
untracked files/dirs) and then C<git checkout .> (to discard all uncommitted
changes). This setting will also implicitly turn on C<create_bare> setting
(unless that setting has been explicitly enabled/disabled).

=item * B<create_bare_target> => I<bool>

Whether to create bare git repo when target does not exist.

When target repo does not exist, gitbunch can either copy the source repo using
C<rsync> (the default, if this setting is undefined), or it can create target
repo with C<git init --bare> (if this setting is set to 1), or it can create
target repo with C<git init> (if this setting is set to 0).

Bare git repositories contain only contents of the .git folder inside the
directory and no working copies of your source files.

Creating bare repos are apt for backup purposes since they are more
space-efficient.

Non-repos will still be copied/rsync-ed.

=item * B<delete_branch> => I<bool> (default: 0)

Whether to delete branches in dest repos not existing in source repos.

=item * B<exclude_files> => I<bool>

Exclude files from processing.

This only applies to C<sync_bunch> operations. Operations like C<check_bunch> and
C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_non_git_dirs> => I<bool>

Exclude non-git dirs from processing.

This only applies to and C<sync_bunch> operations. Operations like C<check_bunch>
and C<exec_bunch> already ignore these and only operate on git repos.

=item * B<exclude_repos> => I<array[str]>

Exclude some repos from processing.

=item * B<exclude_repos_pat> => I<str>

Specify regex pattern of repos to exclude.

=item * B<include_repos> => I<array[str]>

Specific git repos to sync, if not specified all repos in the bunch will be processed.

=item * B<include_repos_pat> => I<str>

Specify regex pattern of repos to include.

=item * B<min_repo_access_time> => I<date>

Limit to repos that are accessed (mtime, committed, status-ed, pushed) recently.

This can significantly reduce the time to process the bunch if you are only
interested in recent repos (which is most of the time unless you are doing a
full check/sync).

=item * B<repo> => I<str>

Only process a single repo.

=item * B<rsync_del> => I<bool>

Whether to use --del rsync option.

When rsync-ing non-repos, by default C<--del> option is not used for more safety
because rsync is a one-way action. To add rsync C<--del> option, enable this

=item * B<rsync_opt_maintain_ownership> => I<bool> (default: 0)

Whether or not, when rsync-ing from source, we use -a (= -rlptgoD) or -rlptD (-a minus -go).

Sometimes using -a results in failure to preserve permission modes on
sshfs-mounted filesystem, while -rlptD succeeds, so by default we don't maintain
ownership. If you need to maintain ownership (e.g. you run as root and the repos
are not owned by root), turn this option on.

=item * B<skip_mtime_check> => I<bool>

Whether or not, when rsync-ing non-repos, we check mtime first.

By default when we rsync a non-repo file/dir from source to target and both
exist, to protect wrong direction of sync-ing we find the newest mtime in source
or dir (if dir, then the dir is recursively traversed to find the file/subdir
with the newest mtime). If target contains the newer mtime, the sync for that
non-repo file/dir is aborted. If you want to force the rsync anyway, use this
option.

=item * B<source>* => I<str>

Directory to check.

=item * B<target>* => I<str>

Destination bunch.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Git-Bunch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Git-Bunch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Git-Bunch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<rsybak>.

L<http://joeyh.name/code/mr/>. You probably want to use this instead. I<mr> supports other control version
software aside from git, doesn't restrict you to put all your repos in one
directory, supports more operations, and has been developed since 2007. Had I
known about I<mr>, I probably wouldn't have started gitbunch. On the other hand,
gitbunch is simpler (I think), doesn't require any config file, and can
copy/sync files/directories not under source control. I mainly use gitbunch to
quickly: 1) check whether there are any of my repositories which have
uncommitted changes; 2) synchronize (pull/push) to other locations. I put all my
data in one big gitbunch directory; I find it simpler. gitbunch works for me and
I use it daily.

L<File::RsyBak>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
