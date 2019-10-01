use strict;
use warnings;

package Git::Helpers;
our $VERSION = '0.000020';
use Carp qw( croak );
use Capture::Tiny 'capture_stderr';
use File::pushd qw( pushd );
use Git::Sub;
use Sub::Exporter -setup => {
    exports => [
        'checkout_root',
        'current_branch_name',
        'https_remote_url',
        'ignored_files',
        'is_inside_work_tree',
        'remote_url',
        'travis_url',
    ]
};
use Try::Tiny qw( catch try );
use URI ();
use URI::FromHash qw( uri );
use URI::Heuristic qw(uf_uristr);
use URI::git ();

sub checkout_root {
    my $dir = shift;

    my ( $new_dir, $root );
    $new_dir = pushd($dir) if $dir;
    $dir ||= '.';

    # the exception thrown by rev-parse when we're not in a repo is not
    # very helpful (see following), so just ditch it in favor of the error
    # output.
    #   "rev_parse error 128 at /home/maxmind/perl5/lib/perl5/Git/Helpers.pm line 30"

    my $stderr = capture_stderr {
        try { $root = scalar git::rev_parse qw(--show-toplevel) }
    };
    croak "Error in $dir: $stderr"
        if $stderr;

    return $root;
}

# Works as of 1.6.3:1
# http://stackoverflow.com/questions/1417957/show-just-the-current-branch-in-git
sub current_branch_name {
    return git::rev_parse( '--abbrev-ref', 'HEAD' );
}

sub https_remote_url {
    my $remote_url = remote_url(shift);
    return undef unless $remote_url;

    my $branch = shift;

    # remove trailing .git
    $remote_url =~ s{\.git\z}{};

    # remove 'git@' from git@github.com:username/repo.git
    $remote_url =~ s{\w*\@}{};

    # remove : from git@github.com:username/repo.git
    $remote_url =~ s{(\w):(\w)}{$1/$2};

    if ($branch) {
        $remote_url .= '/tree/' . current_branch_name();
    }

    my $uri = URI->new( uf_uristr($remote_url) );
    $uri->scheme('https');
    return $uri;
}

sub is_inside_work_tree {
    my $success;
    capture_stderr {
        try {
            $success = git::rev_parse('--is-inside-work-tree');
        };
    };
    return $success;
}

sub ignored_files {
    my $dir = shift || '.';
    my @success;
    my $stderr = capture_stderr {
        try {
            @success = git::ls_files(
                $dir, '--ignored', '--exclude-standard',
                '--others'
            );
        };
    };

    croak "Cannot find ignored files in dir: $stderr" if $stderr;

    return \@success || [];
}

sub remote_url {
    my $remote = shift || 'origin';
    my $url;
    my $stderr = capture_stderr {
        try {
            $url = git::remote( 'get-url', $remote );
        }

        catch {
            try {
                $url = git::config( '--get', "remote.$remote.url" );
            };
        }
    };

    return $url;
}

sub travis_url {
    my $remote_url = https_remote_url(shift);
    my $url        = URI->new($remote_url);
    return uri(
        scheme => 'https',
        host   => 'travis-ci.org',
        path   => $url->path,
    );
}

1;

#ABSTRACT: Shortcuts for common Git commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Helpers - Shortcuts for common Git commands

=head1 VERSION

version 0.000020

=head1 SYNOPSIS

    use Git::Helpers qw(
        checkout_root
        current_branch_name
        https_remote_url
        is_inside_work_tree
        remote_url
        travis_url
    );

    my $dir              = '/path/to/folder/in/git/checkout';
    my $root             = checkout_root($dir);
    my $current_branch   = current_branch_name();
    my $https_remote_url = https_remote_url();
    my $inside_work_tree = is_inside_work_tree();
    my $remote_url       = remote_url('upstream');
    my $travis_url       = travis_url();

=head2 checkout_root( $dir )

Gives you the root level of the git checkout which you are currently in.
Optionally accepts a directory parameter.  If you provide the directory
parameter, C<checkout_root> will temporarily C<chdir> to this directory and
find the top level of the repository.

This method will throw an exception if it cannot find a git repository at the
directory provided.

=head2 current_branch_name

Returns the name of the current branch.

=head2 https_remote_url( $remote_name, $use_current_branch )

This is a browser-friendly URL for the remote, fixed up in such a way that
GitHub (hopefully) doesn't need to redirect your URL.

Turns git@github.com:oalders/git-helpers.git into https://github.com/oalders/git-helpers

Turns https://github.com/oalders/git-helpers.git into https://github.com/oalders/git-helpers

Defaults to using C<origin> as the remote if none is supplied.

Defaults to master branch, but can also display current branch.

    my $current_branch_url = https_remote_url( 'origin', 1 );

=head2 ignored_files( $dir )

Returns an arrayref of files which exist in your checkout, but are ignored by
Git.  Optionally accepts a directory as an argument.  Defaults to ".".

Throws an exception if there has been an error running the command.

=head2 is_inside_work_tree

Returns C<true> if C<git rev-parse --is-inside-work-tree> returns C<true>.
Otherwise returns C<false>. This differs slightly from the behaviour of
C<--is-inside-work-tree> in real life, since it returns C<fatal> rather than
C<false> if run outside of a git repository.

=head2 remote_url( $remote_name )

Returns a URL for the remote you've requested by name.  Defaults to 'origin'.
Provides you with the exact URL which git returns. Nothing is fixed up for you.

    # defaults to 'origin'
    my $remote_url = remote_url();
    # $remote_url is now possibly something like one of the following:
    # git@github.com:oalders/git-helpers.git
    # https://github.com/oalders/git-helpers.git

    # get URL for upstream remote
    my $upstream_url = remote_url('upstream');

=head2 travis_url( $remote_name )

Returns a L<travis-ci.org> URL for the remote you've requested by name.
Defaults to 'origin'.

    # get Travis URL for remote named "origin"
    my $origin_travis_url = travis_url();

    # get Travis URL for remote named "upstream"
    my $upstream_travis_url = travis_url('upstream');

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2019 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
