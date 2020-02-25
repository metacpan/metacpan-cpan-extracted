package App::annex_to_annex_reinject;
# ABSTRACT: annex-to-annex-reinject
#
# Copyright (C) 2019-2020  Sean Whitton <spwhitton@spwhitton.name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
$App::annex_to_annex_reinject::VERSION = '0.002';
use 5.028;
use strict;
use warnings;

use autodie;
use Git::Annex;
use File::Basename qw(basename dirname);
use File::chmod;
$File::chmod::UMASK = 0;
use File::Path qw(rmtree);
use File::Spec::Functions qw(rel2abs);
use File::Find;
use Try::Tiny;

exit main() unless caller;


sub main {
    shift if $_[0] and ref $_[0] eq ""; # in case main called as a class method
    local @ARGV = @{ $_[0] } if $_[0] and ref $_[0] ne "";

    die "usage: annex-to-annex-reinject SOURCEANNEX DESTANNEX\n"
      unless @ARGV == 2;

    my $source = Git::Annex->new($ARGV[0]);
    my $dest   = Git::Annex->new($ARGV[1]);
    #<<<
    try {
        $source->git->rev_parse({ git_dir => 1 });
    } catch {
        die "$ARGV[0] doesn't look like a git repository ..\n";
    };
    try {
        $dest->git->rev_parse({ git_dir => 1 });
    } catch {
        die "$ARGV[1] doesn't look like a git repository ..\n";
    };
    #>>>

    # `git annex reinject` doesn't work in a bare repo atm
    my $use_worktree
      = ($dest->git->rev_parse({ is_bare_repository => 1 }))[0] eq 'true';
    my ($temp, $worktree);
    if ($use_worktree) {
        $temp = tempdir(CLEANUP => 1, DIR => dirname $ARGV[1]);
        say "bare repo; our git worktree is in $temp";
        $dest->git->worktree("add", { force => 1, detach => 1 },
            rel2abs($temp), "synced/master");
    }

    my ($source_uuid) = $source->git->config('annex.uuid');
    die "couldn't get source annex uuid"
      unless $source_uuid =~ /\A[a-z0-9-]+\z/;
    my $spk = $source->batch("setpresentkey");

    my ($source_objects_dir)
      = $source->git->rev_parse({ git_path => 1 }, "annex/objects");
    $source_objects_dir = rel2abs $source_objects_dir, $ARGV[0];
    my $reinject_from = $use_worktree ? $temp : $ARGV[1];
    say "reinjecting from $source_objects_dir into $reinject_from";
    find({
            wanted => sub {
                -f or return;
                say "\nconsidering $_";
                my $dir = dirname $_;
                chmod "u+w", $dir, $_;
                system "git", "-C", $reinject_from, "annex", "reinject",
                  "--known", $_;
                if (-e $_) {
                    chmod "u-w", $dir, $_;
                } else {
                    my $key = basename $_;
                    say "telling setpresentkey process '$key $source_uuid 0'";
                    say for $spk->say("$key $source_uuid 0");
                    # alt. to setpresentkey:
                    # say "fscking key $key in $ARGV[0]";
                    # system 'git', '-C', $ARGV[0], 'annex', 'fsck',
                    #     '--numcopies=1', '--key', $key;
                    say "cleaning up empty dirs";
                    foreach
                      my $d ($dir, dirname($dir), dirname(dirname($dir))) {
                        last unless _is_empty_dir($d);
                        rmdir $d;
                    }
                }
            },
            no_chdir => 1
        },
        $source_objects_dir
    );
    if ($use_worktree) {
        # we can't use `git worktree remove` because the way git-annex
        # worktree support works breaks that command: git-annex replaces
        # the .git worktree file with a symlink
        rmtree $temp;
        $dest->git->worktree("prune");
    }

    # cause setpresentkey changes to be recorded in git-annex branch
    undef $spk;
    sleep 1;
    $source->annex->merge;

    return 0;
}


sub _is_empty_dir {
    -d $_[0] or return 0;
    opendir(my $dirh, $_[0]);
    my @files = grep { $_ ne '.' && $_ ne '..' } readdir $dirh;
    return @files == 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::annex_to_annex_reinject - annex-to-annex-reinject

=head1 VERSION

version 0.002

=head1 FUNCTIONS

=head2 main

Implementation of annex-to-annex-reinject(1).  Please see
documentation for that command.

Normally takes no arguments and responds to C<@ARGV>.  If you want to
override that you can pass an arrayref of arguments, and those will be
used instead of the contents of C<@ARGV>.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
