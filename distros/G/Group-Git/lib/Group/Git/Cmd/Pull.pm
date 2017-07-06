package Group::Git::Cmd::Pull;

# Created on: 2013-05-06 21:57:07
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo::Role;
use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use File::chdir;
use Getopt::Alt;

our $VERSION = version->new('0.6.3');

requires 'repos';
requires 'verbose';

my $opt = Getopt::Alt->new(
    { help => __PACKAGE__, },
    [
        'quiet|q!',
        'verbose|v',
        #'recurse-submodules=s![=yes|on-demand|no',
        'recurse-submodules=[yes|on-demand|no]',
        'commit!',
        'edit|e!',
        'ff!',
        'ff-only',
        #'log=d!',
        'log=d',
        'stat|n!',
        'squash!',
        'strategy|s=s',
        'strategy-option|X=s',
        'verify-signatures!',
        'summary!',
        #'rebase|r=s![=false|true|preserve]',
        'rebase|r=[false|true|preserve]',
        'all',
        'append|a',
        'depth=i',
        'unshallow',
        'update-shallow',
        'force|f',
        'keep|k',
        'no-tags',
        'update-head-ok|u',
        'upload-pack=s',
        'progress',
    ]
);

sub update_start { shift->pull_start($_[0], 'update') }
sub pull_start {
    $opt->process;
    return;
}

sub update { shift->pull($_[0], 'update') }
sub pull {
    my ($self, $name, $type) = @_;
    $type ||= 'pull';

    my $repo = $self->repos->{$name};
    my $cmd;
    my $dir;

    if ( -d $name ) {
        {
            local $CWD = $name;

            # check that there is a remote
            my $remotes = `git remote 2> /dev/null`;
            chomp $remotes;

            if ( ! $remotes && ! $self->verbose ) {
                return;
            }
        }

        $dir = $name;
        my @args = map {
                $opt->opt->{$_} eq '0'   ? "--no-$_"
                : $opt->opt->{$_} eq '1' ? "--$_"
                :                          "--$_=" . $opt->opt->{$_};
            }
            keys %{ $opt->opt };
        $cmd = join ' ', 'git', map { $self->shell_quote } $type, @args, @ARGV;
    }
    elsif ( $repo->git ) {
        $cmd = join ' ', 'git', 'clone', map { $self->shell_quote } $repo->git, $name;
    }
    else {
        return;
    }

    local $CWD = $dir if $dir;
    warn "$cmd\n" if $self->verbose > 1;
    return `$cmd 2>&1` if !$opt->opt->quiet;

    my @ans = `$cmd 2>&1`;

    return if @ans == 1 && $ans[0] =~ /^Already \s up-to-date[.]$/xms;

    return wantarray ? @ans : join '', @ans;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Pull - Pull latest versions of all repositories or clone any that are missing

=head1 VERSION

This documentation refers to Group::Git::Cmd::Pull version 0.6.3.

=head1 SYNOPSIS

    group-git pull (options)

  OPTIONS:
    -q --quiet
       --no-quiet
    -v --verbose
       --recurse-submodules=[yes|on-demand|no]
       --commit
       --no-commit
    -e --edit
       --no-edit
       --ff
       --no-ff
       --ff-only
       --log=d
    -n --stat
       --no-stat
       --squash
       --no-squash
    -s --strategy[=]str
    -X --strategy-option[=]str
       --verify-signatures
       --no-verify-signatures
       --summary
       --no-summary
    -r --rebase[=][false|true|preserve]
       --all
    -a --append
       --depth=i
       --unshallow
       --update-shallow
    -f --force
    -k --keep
       --no-tags
    -u --update-head-ok
       --upload-pack=s
       --progress

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<pull ($name[, 'update'])>

Runs git pull on all repositories, if a repository doesn't exist on disk this
will clone that repository.

=item C<update ($name)>

Runs git update on all repositories, if a repository doesn't exist on disk this
will clone that repository.

=item C<pull_start ()>

Pre-process pull options

=item C<update_start ()>

Pre-process update options

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
