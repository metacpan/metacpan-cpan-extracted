# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# Dummy implementation that creates a git repository on the fly
# for every match.

package File::Globstar::ListMatch;

use common::sense;

use File::Temp;
use Git;

sub new {
    my ($class, $input, %options) = @_;

    my $self = {
        __gitignore => $$input,
    };

    $self->{__ignore_case} = delete $options{ignoreCase};

    bless $self, $class;
}

sub match {
    my ($self, $path, $is_directory) = @_;

    $is_directory = 1 if $path =~ s{/$}{};

    $path .= '/' if $is_directory;

    $path =~ s{^/+}{};

    my $dir = File::Temp::newdir;
    my $status = Git::command_oneline(init => $dir);
    my $repo = Git->repository(Directory => $dir);

    open my $fh, '>', "$dir/.gitignore"
        or die "cannot open '$dir/.gitignore': $!";
    $fh->print($self->{__gitignore});

    # git-check-ignore exits with status code 1 if the file does not get
    # ignored, and that throws an exception.  We use that as the indicator
    # instead of the path name returned;
    eval { $repo->command('check-ignore', $path) };
    return if $@;

    return $self;
}

sub matchExclude {
    &match;
}

package main;

require "t/listmatch-xmode.t";
