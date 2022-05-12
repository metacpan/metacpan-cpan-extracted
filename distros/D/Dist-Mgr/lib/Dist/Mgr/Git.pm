package Dist::Mgr::Git;

use strict;
use warnings;
use version;

use Capture::Tiny qw(:all);
use Carp qw(croak cluck);
use Cwd qw(getcwd);
use Data::Dumper;
use Digest::SHA;
use Dist::Mgr::FileData qw(:all);
use File::Copy;
use File::Copy::Recursive qw(rmove_glob);
use File::Path qw(make_path rmtree);
use File::Find::Rule;
use Module::Starter;
use PPI;
use Term::ReadKey;
use Tie::File;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    _git_add
    _git_commit
    _git_clone
    _git_push
    _git_pull
    _git_release
    _git_repo
    _git_status_differs
    _git_tag
);
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

our $VERSION = '1.13';

my $spinner_count;

sub _exec {
    my ($cmd, $verbose) = @_;

    croak("_exec() requires cmd parameter sent in") if ! defined $cmd;

    if ($verbose) {
        print `$cmd`;
    }
    else {
        capture_merged {
            `$cmd`;
        };
    }
}
sub _git_add {
    my ($verbose) = @_;

    if (_validate_git()) {
        _exec('git add .', $verbose);
        croak("Git add failed with exit code: $?") if $? != 0;
    }
    else {
        warn "'git' not installed, can't add\n";
    }

    return $?;
}
sub _git_commit {
    my ($msg, $verbose) = @_;

    croak("git_commit() requires a commit message sent in") if ! defined $msg;

    if ( _validate_git()) {
        _exec("git commit -am '$msg'", $verbose);

        if ($? != 0) {
            if ($? == 256) {
                print "\nNothing to commit, proceeding...\n" if $verbose;
            }
            else {
                croak("Git commit failed with exit code: $?") if $? != 0;
            }
        }
    }
    else {
        warn "'git' not installed, can't commit\n";
    }

    return $?;
}
sub _git_clone {
    my ($user, $repo, $verbose) = @_;

    if (! defined $user || ! defined $repo) {
        croak("git_clone() requires a user and repository sent in");
    }

    if ( _validate_git()) {
        _exec("git clone 'git\@github.com:/$user/$repo'", $verbose);

        if ($? != 0) {
            if ($? == 32768) {
                croak(
                    "Git clone failed with exit code: $? DIRECTORY $repo ALREADY EXISTS\n"
                );
            }
            croak("Git clone failed with exit code: $?\n") if $? != 0;
        }
    }
    else {
        warn "'git' not installed, can't clone\n";
    }

    return $?;
}
sub _git_pull {
    my ($verbose) = @_;

    if (_validate_git()) {
        _exec('git pull', $verbose);
        croak("Git pull failed with exit code: $?") if $? != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
    }

    return $?;
}
sub _git_push {
    my ($verbose) = @_;

    if (_validate_git()) {
        _exec('git push', $verbose);
        _exec('git push --tags', $verbose);
        croak("Git push failed with exit code: $?") if $? != 0;
    }
    else {
        warn "'git' not installed, can't push\n";
    }

    return $?;
}
sub _git_release {
    my ($version, $wait_for_ci) = @_;

    croak("git_release() requires a version sent in") if ! defined $version;

    my $git_status_differs = _git_status_differs();
    $wait_for_ci //= 1;
    my $verbose = 0;

    if ($git_status_differs) {
        _git_pull();
        _git_commit($version, $verbose);
        _git_push($verbose);
    }

    if ($wait_for_ci && $git_status_differs) {
        `clear`;

        print "\n\nWaiting for CI tests to complete.\n\n";
        print "Hit ENTER on failure, and CTRL-C to continue on...\n\n";

        local $| = 1;

        my $interrupt = 0;
        $SIG{INT} = sub {$interrupt = 1;};

        my $key = '';

        do {
            _wait_spinner("Waiting: ");
            $key = ReadKey(-1);
        }
            until ($interrupt || defined $key && $key eq "\n");

        if ($interrupt) {
            print "\nTests pass, continuing with release\n";
            return 1;
        }
        else {
            print "\nTests failed, halting progress\n";
            return 0;
        }
    }

    return 1;
}
sub _git_repo {
    my $repo;

    if (_validate_git()) {
        capture_merged {
            $repo = `git rev-parse --show-toplevel`;
        };
    }

    if ($? == 0) {
        $repo =~ s|.*/(.*)|$1|;
        return $repo;
    }
    else {
        return $?;
    }
}
sub _git_status_differs {
    my $status_output;

    if (_validate_git()) {
        $status_output = `git status`;
    }
    else {
        warn "'git' not installed, can't get status\n";
    }

    my @git_output = (
        'On branch',
        'Your branch is up-to-date with',
        'nothing to commit, working directory clean'
    );

    my @status = split /\n/, $status_output;

    for (0..$#status) {
        return 1 if $status[$_] !~ /$git_output[$_]/;
    }

    return 0;
}
sub _git_tag {
    my ($version, $verbose) = @_;

    croak("git_tag() requires a version sent in") if ! defined $version;

    if (_validate_git()) {
        _exec('git tag', $verbose);
        croak("Git tag failed... needs intervention...") if $? != 0;

       # croak("Git tag failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
    }

    return $?;
}
sub _wait_spinner {
    my ($msg) = @_;

    croak("_wait_spinner() needs a message sent in") if ! $msg;

    $spinner_count //= 0;
    my $num = 20 - $spinner_count;
    my $spinner = '.' x $spinner_count . ' ' x $num;
    $spinner_count++;
    $spinner_count = 0 if $spinner_count == 20;
    print STDERR "$msg: $spinner\r";
    select(undef, undef, undef, 0.1);
}
sub _validate_git {
    my $sep = $^O =~ /win32/i ? ';' : ':';
    return grep {-x "$_/git" } split /$sep/, $ENV{PATH};
}
sub __placeholder {}

1;
__END__

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
