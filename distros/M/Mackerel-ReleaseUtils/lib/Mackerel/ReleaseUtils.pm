package Mackerel::ReleaseUtils;

use 5.014;
use warnings;
use utf8;

use Mackerel::ReleaseUtils::Log;

use IPC::Cmd qw/run/;
use Carp qw/croak/;
use ExtUtils::MakeMaker qw/prompt/;
use File::Which qw/which/;
use JSON::PP qw/decode_json/;
use Path::Tiny qw/path/;
use POSIX qw(setlocale LC_TIME);
use Scope::Guard qw/guard/;
use Time::Piece qw/localtime/;
use version; our $VERSION = version->declare("v0.2.5");

use parent 'Exporter';

our @EXPORT = qw/
    command git hub
    replace
    create_release_pull_request/;

sub DEBUG() { $ENV{MC_RELENG_DEBUG} }

sub command {say('+ '. join ' ', @_) if DEBUG; !system(@_) or croak $!}

sub git {
    state $com = which('git') or die "git command is requred\n";
    unshift  @_, $com; goto \&command
}

sub hub {
    state $com = which('hub') or die "hub command is requred\n";
    unshift @_, $com; goto \&command;
}

# file utils
sub replace {
    my ($glob, $code) = @_;
    for my $file (glob $glob) {
        my $content = $code->(path($file)->slurp_utf8, $file);
        $content .= "\n" if $content !~ /\n\z/ms;

        my $f = path($file);
        # for keeping permission
        $f->append_utf8({truncate => 1}, $content);
    }
}

## version utils
sub parse_version {
    my $ver = shift;
    my ($major, $minor, $patch) = $ver =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)$/;
    ($major, $minor, $patch)
}

sub suggest_next_version {
    my $ver = shift;
    my ($major, $minor, $patch) = parse_version($ver);
    join '.', $major, ++$minor, 0;
}

sub is_valid_version {
    my $ver = shift;
    my ($major) = parse_version($ver);
    defined $major;
}

sub decide_next_version {
    my $current_version = shift;
    my $opt_next_version = shift;
    my $next_version = suggest_next_version($current_version);
    if ($opt_next_version) {
        $next_version = $opt_next_version;
    } else {
        $next_version = prompt("input next version:", $next_version);
    }

    if (!is_valid_version($next_version)) {
        die qq{"$next_version" is invalid version string\n};
    }
    if (version->parse($next_version) < version->parse($current_version)) {
        die qq{"$next_version" is smaller than current version "$current_version"\n};
    }
    $next_version;
}

## git utils
sub last_release {
    my @out = `git tag`;

    my ($tag) =
        sort { version->parse($b) <=> version->parse($a) }
        map {/^v([0-9]+(?:\.[0-9]+){2})$/; $1 || ()}
        map {chomp; $_} @out;
    $tag;
}

sub merged_prs {
    my $current_tag = shift;

    my $data = eval { decode_json scalar `ghch -f v$current_tag` };
    if ($! || $@ || $?) {
        die "calling ghch and/or decoding json failed: $@";
    }
    return grep {$_->{title} !~ /\[nitp?\]/i} @{ $data->{pull_requests} };
}

sub build_pull_request_body {
    my ($next_version, @releases) = @_;
    my $body = "Release version $next_version\n\n";
    for my $rel (@releases) {
        $body .= sprintf "- %s #%s\n", $rel->{title}, $rel->{number};
    }
    $body;
}

sub update_versions {
    my ($package_name, $current_version, $next_version) = @_;

    ### update versions
    my $cur_ver_reg = quotemeta $current_version;

    # update rpm spec
    replace sprintf('packaging/rpm/%s*.spec', $package_name) => sub {
        my $content = shift;
        $content =~ s/^(Version:\s+)$cur_ver_reg/$1$next_version/ms;
        $content;
    };
    command qw/gobump set/, $next_version, '-w';
}

sub _detect_debian_revision {
    my ($packagen_name, $content) = @_;
    my $p = quotemeta $packagen_name;
    my ($debian_revision) = $content =~ /^$p \([0-9]+(?:\.[0-9]+){2}-([^)]+)\) stable;/ms;
    $debian_revision;
}

sub update_changelog {
    my ($package_name, $next_version, @releases) = @_;

    my $email = 'mackerel-developers@hatena.ne.jp';
    my $name  = 'mackerel';

    my $old_locale = setlocale(LC_TIME);
    setlocale(LC_TIME, "C");
    my $g = guard {
        setlocale(LC_TIME, $old_locale);
    };

    my $now = localtime;

    replace 'packaging/deb*/debian/changelog' => sub {
        my $content = shift;

        my $debian_revision = _detect_debian_revision($package_name, $content);

        my $update = sprintf "%s (%s-%s) stable; urgency=low\n\n",
            $package_name, $next_version, $debian_revision;
        for my $rel (@releases) {
            $update .= sprintf "  * %s (by %s)\n    <%s>\n", $rel->{title}, $rel->{user}{login}, $rel->{html_url};
        }
        $update .= sprintf "\n -- %s <%s>  %s\n\n", $name, $email, $now->strftime("%a, %d %b %Y %H:%M:%S %z");
        $update . $content;
    };

    replace sprintf('packaging/rpm/%s*.spec', $package_name) => sub {
        my $content = shift;

        my $update = sprintf "* %s <%s> - %s\n", $now->strftime('%a %b %d %Y'), $email, $next_version;
        for my $rel (@releases) {
            $update .= sprintf "- %s (by %s)\n", $rel->{title}, $rel->{user}{login};
        }
        $content =~ s/%changelog/%changelog\n$update/;
        $content;
    };

    replace 'CHANGELOG.md' => sub {
        my $content = shift;

        my $update = sprintf "\n\n## %s (%s)\n\n", $next_version, $now->strftime('%Y-%m-%d');
        for my $rel (@releases) {
            $update .= sprintf "* %s #%d (%s)\n", $rel->{title}, $rel->{number}, $rel->{user}{login};
        }
        $content =~ s/\A# Changelog/# Changelog$update/;
        $content;
    };
}

sub update_makefile {
    my $next_version = shift;
    replace 'Makefile' => sub {
        my $content = shift;
        $content =~ s/^VERSION( *:*= *).*?\n/VERSION$1$next_version\n/ms;
        $content;
    };
}

sub create_release_pull_request {
    my ($package_name, $code, $opt_next_version) = @_;
    if (DEBUG) {
        $Mackerel::ReleaseUtils::Log::LogLevel = Mackerel::ReleaseUtils::Log::LOG_DEBUG;
    }

    # exit if workspace is dirty
    if (`git status --porcelain`) {
        die "git workspace is dirty. Make it clean to continue\n";
    }

    chomp(my $current_branch = `git symbolic-ref --short HEAD`);
    my $branch_name;
    my $cleanup = sub {
        infof "cleanup\n";
        git qw/checkout --force/, $current_branch;
        git qw/branch -D/, $branch_name if $branch_name;
        exit 1;
    };
    $SIG{INT} = $cleanup;

    git qw/checkout master/;
    git qw/pull/;

    my $current_version = last_release;
    infof "current version: %s\n", $current_version;
    my $next_version = decide_next_version($current_version, $opt_next_version);

    $branch_name = "bump-version-$next_version";
    infof "checkout new releasing branch [$branch_name]\n";
    git qw/checkout -b/, $branch_name;

    my @releases = merged_prs $current_version;
    infof "bump versions and update documents\n";
    update_versions $package_name, $current_version, $next_version;
    update_changelog $package_name, $next_version, @releases;
    update_makefile $next_version;
    # main process
    $code->($current_version, $next_version, [@releases]) if $code;
    git qw/add ./;
    git qw/commit -m/, "ready for next release and update changelogs. version: $next_version";

    git qw/diff/, qw/--word-diff/, "origin/master..$branch_name";
    my $pr_body = build_pull_request_body($next_version, @releases);
    say '

-------------
Release Note
-------------';
    say $pr_body;

    if (prompt('push changes?', 'y') !~ /^y(?:es)?$/i ) {
        warnf "releng is aborted.\n";
        $cleanup->(); # exit internally
    }
    $SIG{INT} = 'DEFAULT';

    infof "push changes\n";
    git qw/push --set-upstream origin/, $branch_name;
    hub qw/pull-request -m/, $pr_body;

    infof "Releasing pull request is created. Review and merge it. You can update changelogs and commit more in this branch before merging.\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Mackerel::ReleaseUtils - release utilities for Mackerel (https://mackerel.io)

=head1 SYNOPSIS

    use Mackerel::ReleaseUtils;

=head1 DESCRIPTION

Mackerel::ReleaseUtils provides DSLs for writing release scripts.

=head1 LICENSE

Copyright (C) Mackerel developers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mackerel Developers E<lt>mackerel-developers@hatena.ne.jpE<gt>

=cut
