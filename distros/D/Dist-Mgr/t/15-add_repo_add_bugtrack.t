use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Dist::Mgr qw(:all);

use lib '.';
use lib 't/lib';
use Helper qw(:all);

# Prepare for the tests
unlink_makefile();
copy_makefile();

my $mf_orig = 't/data/orig/Makefile.PL';
my $mf_work = 't/data/work/Makefile.PL';

# bad params (repo)
{
    is eval{add_repository(); 1}, undef, "repo croak if no params ok";
    like $@, qr/Usage: add_repository/, "...and error is sane";

    is eval{add_repository('stevieb9'); 1}, undef, "repo croak if only author param ok";
    like $@, qr/Usage: add_repository/, "...and error is sane";

    is
        eval { Dist::Mgr::_makefile_insert_repository('a', 'r'); 1 },
        undef,
        "_makefile_insert_repository() croaks if no makefile sent in";
}

# bad params (bugtrack)
{
    is eval{add_bugtracker(); 1}, undef, "bugtracker croak if no params ok";
    like $@, qr/Usage: add_bugtracker/, "...and error is sane";

    is eval{add_bugtracker('stevieb9'); 1}, undef, "bugtracker croak if only author param ok";
    like $@, qr/Usage: add_bugtracker/, "...and error is sane";

    is
        eval { Dist::Mgr::_makefile_insert_bugtracker('a', 'r'); 1 },
        undef,
        "_makefile_insert_bugtracker() croaks if no makefile sent in";
}

# add_repository
{
    is
        add_repository('stevieb9', 'add-repo', $mf_work),
        0,
        "add_repository() returns 0 ok";

    open my $fh_orig, '<', $mf_orig or die $!;
    open my $fh_work, '<', $mf_work or die $!;

    my @orig = <$fh_orig>;
    my @work = <$fh_work>;

    close $fh_orig;
    close $fh_work;

    is scalar @orig, 24, "orig makefile line count ok";
    is scalar @work, 34, "repo makefile line count ok";

    my @repo_lines = section_repo();
    my $repo_line_count = scalar @repo_lines;
    my $count = 0;
    my $orig_count = 0;

    for (@work) {
        s/\s+//g;
        if ($_ =~ /META_MERGE/) {
            $repo_lines[$count] =~ s/\s+//g;
            is $repo_lines[$count] eq $_, 1, "repo '$_' line matches ok";
            $count++;
            next;
        }
        if ($count && $count < $repo_line_count) {
            $repo_lines[$count] =~ s/\s+//g;
            is $repo_lines[$count] eq $_, 1, "repo '$_' line matches ok";
            $count++;
            next;
        }
        $orig[$orig_count] =~ s/\s+//g;
        is $orig[$orig_count] eq $_, 1, "Makefile.PL line '$_' matches ok";
        $orig_count++;
    }
}

# Remove and re-copy the Makefile.PL for bugtracker testing
unlink_makefile();
copy_makefile();

# add_bugtracker
{
    is
        add_bugtracker('stevieb9', 'add-repo', $mf_work),
        0,
        "add_bugtracker() returns 0 ok";

    open my $fh_orig, '<', $mf_orig or die $!;
    open my $fh_work, '<', $mf_work or die $!;

    my @orig = <$fh_orig>;
    my @work = <$fh_work>;

    close $fh_orig;
    close $fh_work;

    is scalar @orig, 24, "orig makefile line count ok";
    is scalar @work, 32, "bugttrack makefile line count ok";

    my @bugtrack_lines = section_bugtrack();
    my $bugtrack_line_count = scalar @bugtrack_lines;
    my $orig_count = 0;
    my $count = 0;

    for (@work) {
        s/\s+//g;

        if ($_ =~ /META_MERGE/) {
            $bugtrack_lines[$count] =~ s/\s+//g;
            is $bugtrack_lines[$count] eq $_, 1, "bugtrack '$_' line matches ok";
            $count++;
            next;
        }
        if ($count && $count < $bugtrack_line_count) {
            $bugtrack_lines[$count] =~ s/\s+//g;
            is $bugtrack_lines[$count] eq $_, 1, "bugtrack '$_' line matches ok";
            $count++;
            next;
        }
        $orig[$orig_count] =~ s/\s+//g;
        is $orig[$orig_count] eq $_, 1, "Makefile.PL line '$_' matches ok";
        $orig_count++;
    }
}

# Remove and re-copy the Makefile.PL for repo & bugtrack tests

unlink_makefile();
copy_makefile();

# add_bugtracker & repo
{
    is add_repository('stevieb9', 'add-repo', $mf_work),
        0,
        "add_repository() returns 0 both test ok";

    is
        add_bugtracker('stevieb9', 'add-repo', $mf_work),
        0,
        "add_bugtracker() returns 0 both test ok";

    open my $fh_orig, '<', $mf_orig or die $!;
    open my $fh_work, '<', $mf_work or die $!;

    my @orig = <$fh_orig>;
    my @work = <$fh_work>;

    close $fh_orig;
    close $fh_work;

    is scalar @orig, 24, "orig makefile line count ok";
    is scalar @work, 37, "bugttrack makefile line count ok";

    my @bugtrack_and_repo_lines = section_bugtrack_and_repo();
    my $line_count = scalar @bugtrack_and_repo_lines;
    my $orig_count = 0;
    my $count = 0;

    for (@work) {
        s/\s+//g;

        if ($_ =~ /META_MERGE/) {
            $bugtrack_and_repo_lines[$count] =~ s/\s+//g;
            is $bugtrack_and_repo_lines[$count] eq $_, 1, "bugtrack & repo '$_' line matches ok";
            $count++;
            next;
        }
        if ($count && $count < $line_count) {
            $bugtrack_and_repo_lines[$count] =~ s/\s+//g;
            is $bugtrack_and_repo_lines[$count] eq $_, 1, "bugtrack & repo '$_' line matches ok";
            $count++;
            next;
        }
        $orig[$orig_count] =~ s/\s+//g;
        is $orig[$orig_count] eq $_, 1, "Makefile.PL line '$_' matches ok";
        $orig_count++;
    }
}

unlink_makefile();

done_testing();

sub section_repo {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "            repository => {",
        "                type => 'git',",
        "                url => 'https://github.com/stevieb9/add-repo.git',",
        "                web => 'https://github.com/stevieb9/add-repo',",
        "            },",
        "        },",
        "    },"
    );
}
sub section_bugtrack {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "            bugtracker => {",
        "                web => 'https://github.com/stevieb9/add-repo/issues',",
        "            },",
        "        },",
        "    },"
    );
}
sub section_bugtrack_and_repo {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "            bugtracker => {",
        "                web => 'https://github.com/stevieb9/add-repo/issues',",
        "            },",
        "            repository => {",
        "                type => 'git',",
        "                url => 'https://github.com/stevieb9/add-repo.git',",
        "                web => 'https://github.com/stevieb9/add-repo',",
        "            },",
        "        },",
        "    },"
    );
}