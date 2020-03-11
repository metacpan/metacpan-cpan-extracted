package App::annex_to_annex;
# ABSTRACT: use hardlinks to migrate files between git annex repos
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
$App::annex_to_annex::VERSION = '0.003';
use 5.028;
use strict;
use warnings;

use autodie;
use subs qw(main exit);
use Digest::MD5::File qw(file_md5);
use File::Basename qw(dirname basename);
use File::Copy;
use File::Find;
use File::Spec::Functions qw(catfile rel2abs abs2rel);
use Try::Tiny;
use Git::Annex;

my $exit_main = 0;

CORE::exit main unless caller;


sub main {
    shift if $_[0] and ref $_[0] eq ""; # in case main called as a class method
    local @ARGV = @{ $_[0] } if $_[0] and ref $_[0] ne "";

    # only support v7 because supporting v5 too would make things quite
    # complex.  require git-annex >=7.20191009 because it will refuse to
    # work in v5 repos, and because it supports `git annex find --unlocked`
    chomp(my %annex_version_fields = map { split ': ' } `git annex version`);
    die "I need git-annex >=7.20191009 and a v7 repository\n"
      unless $annex_version_fields{'git-annex version'} >= 7.20191009;

    die "need at least two arguments\n" unless @ARGV > 1;
    my $dest = rel2abs pop @ARGV;
    die "dest is not a directory\n" unless -d $dest;
    my $dest_device_id = (stat($dest))[0];
    my $dannex         = Git::Annex->new($dest);
    my $do_commit      = 0;
    if ($ARGV[0] eq '--commit') {
        $do_commit = 1;
        shift @ARGV;

        my @git_status = $dannex->git->RUN("status", { porcelain => 1 });
        die "git repo containing $dest is not clean; please commit\n"
          unless @git_status == 0;

        #<<<
        try {
            $dannex->git->symbolic_ref({ quiet => 1 }, "HEAD");
        } catch {
            die "$dest has a detached HEAD; aborting";
        };
        #>>>
    }
    my @sources = map rel2abs($_), @ARGV;

    # process one entry in @sources at a time because we can start up
    # annex batch processes for each of these as all files under each
    # entry in @sources will lie in the same annex
    foreach my $source (@sources) {
        my $dir   = dirname $source;
        my $annex = Git::Annex->new($dir);
        #<<<
        try {
            $annex->annex->status;
        } catch {
            die "$source does not appear to lie within an annex\n";
        };
        #>>>
        die "$source does not exist\n" unless -e $source;

        if ($do_commit) {
            my @git_status = $annex->git->RUN("status", { porcelain => 1 });
            die "git repo containing $source is not clean; please commit\n"
              unless @git_status == 0;

            #<<<
            try {
                $annex->git->symbolic_ref({ quiet => 1 }, "HEAD");
            } catch {
                die "$dest has a detached HEAD; aborting";
            };
            #>>>
        }

        my @missing
          = $annex->annex->find("--not", "--in", "here",
                                abs2rel $source, $annex->toplevel);
        if (@missing) {
            say "Following annexed files are not present in this repo:";
            say for @missing;
            die "cannot continue; please `git-annex get` them\n";
        }

        # start batch processes
        my $lk   = $annex->batch("lookupkey");
        my $cl   = $annex->batch("contentlocation");
        my $find = $annex->batch("find", "--unlocked");

        find({
                wanted => sub {
                    my $rel    = abs2rel $File::Find::name, $dir;
                    my $target = catfile $dest,             $rel;
                    die "$target already exists!\n"
                      if -e $target and !-d $target;

                    my $key = $lk->ask($File::Find::name);
                    if ($key) {    # this is an annexed file
                        my $content = rel2abs $cl->ask($key), $annex->toplevel;
                        my $content_device_id = (stat $content)[0];
                        if ($dest_device_id == $content_device_id) {
                            link $content, $target;
                        } else {
                            _copy_and_md5($content, $target);
                        }
                        # add, and then maybe unlock.  we don't use `-c
                        # annex.addunlocked=true` because we want to
                        # hardlink from .git/annex/objects in the source
                        # to .git/annex/objects in the dest, rather than
                        # having the unlocked copy in dest be hardlinked
                        # to the source, or anything like that
                        system "git", "-C", $dest, "annex", "add",    $rel;
                        system "git", "-C", $dest, "annex", "unlock", $rel
                          if $find->ask(abs2rel $File::Find::name,
                                        $annex->toplevel);

                        # if using the default backend, quick sanity check
                        if ($key =~ /^SHA256E-s[0-9]+--([0-9a-f]+)/) {
                            my $key_sum = $1;
                            chomp(my $dest_key
                                  = `git -C "$dest" annex lookupkey "$rel"`);
                            if ($dest_key =~ /^SHA256E-s[0-9]+--([0-9a-f]+)/) {
                                my $dest_key_sum = $1;
                                die
"git-annex calculated a different checksum for $target"
                                  unless $key_sum eq $dest_key_sum;
                            }
                        }
                    } else {    # this is not an annexed file
                        if (-d $File::Find::name) {
                            mkdir $target unless -d $target;
                        } else {
                            _copy_and_md5($File::Find::name, $target);
                            system "git", "-C", $dest,
                              "-c", "annex.gitaddtoannex=false", "add", $rel;
                        }
                    }
                    $annex->git->rm($File::Find::name)
                      unless -d $File::Find::name;
                },
                no_chdir => 1,
            },
            $source
        );
        $annex->git->commit({ message => "migrated by annex-to-annex" })
          if $do_commit;
    }
    $dannex->git->commit({ message => "add" }) if $do_commit;

  EXIT_MAIN:
    return $exit_main;
}

sub _copy_and_md5 {
    copy($_[0], $_[1]);
    die "md5 checksum failure after copying $_[0] to $_[1]!"
      unless file_md5($_[0]) eq file_md5($_[1]);
}

sub exit { $exit_main = shift // 0; goto EXIT_MAIN }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::annex_to_annex - use hardlinks to migrate files between git annex repos

=head1 VERSION

version 0.003

=head1 FUNCTIONS

=head2 main

Implementation of annex-to-annex(1).  Please see documentation for
that command.

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
