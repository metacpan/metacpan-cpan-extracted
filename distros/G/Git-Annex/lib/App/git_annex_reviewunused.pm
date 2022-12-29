package App::git_annex_reviewunused;
# ABSTRACT: interactively process 'git annex unused' output
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
$App::git_annex_reviewunused::VERSION = '0.008';
use 5.028;
use strict;
use warnings;

use subs qw(main exit);
use Getopt::Long;
use Git::Annex;
use Try::Tiny;
use Term::ReadKey;
use Term::ANSIColor;

my $exit_main = 0;

CORE::exit main unless caller;


sub main {
    shift if $_[0] and ref $_[0] eq ""; # in case main called as a class method
    local @ARGV = @{ $_[0] } if $_[0] and ref $_[0] ne "";

    my $annex = Git::Annex->new;

    my $just_print = 0;
    my ($uuid, $from_arg, $used_refspec_arg, %unused_opts, %dropunused_args);
    GetOptions
      'from=s'         => \$from_arg,
      'used-refspec=s' => \$used_refspec_arg,
      'just-print'     => \$just_print;
    if ($from_arg) {
        $unused_opts{from} = $dropunused_args{from} = $from_arg;
    #<<<
    try {
        ($uuid) = $annex->git->config("remote." . $from_arg . ".annex-uuid");
    } catch {
        die "couldn't determine an annex UUID for $from_arg remote";
    };
    #>>>
    }
    $unused_opts{used_refspec} = $used_refspec_arg if $used_refspec_arg;

    my @to_drop;
    my @unused_files = grep {
        # check the unused file still exists i.e. has not been dropped
        # already (in the case of reviewing unused files at a remote,
        # just check that it's not been dropped according to the local
        # git-annex branch by using readpresentkey rather than
        # checkpresentkey)

        my $ret = $_->{contentlocation}
          = $annex->abs_contentlocation($_->{key});

        if ($from_arg) {
            #<<<
            try {
                $annex->annex->readpresentkey($_->{key}, $uuid);
            } catch {
                $ret = 0;
            };
            #>>>
        }

        $ret;
    } $annex->unused(%unused_opts, log => 1)->@*;
    exit unless @unused_files;
    if ($just_print) {
        _say_spaced_bullet("There are unused files you can drop with"
              . " `git annex dropunused':");
        say "    " . $_->{number} . "     " . $_->{key} for @unused_files;
        print "\n";
    }
    my $i = 0;
  UNUSED: while ($i < @unused_files) {
        my $unused_file     = $unused_files[$i];
        my $contentlocation = $unused_file->{contentlocation};

        system qw(clear -x) unless $just_print;
        _say_bold("unused file #" . $unused_file->{number} . ":");

        if ($unused_file->{bad} or $unused_file->{tmp}) {
            say "  looks like stale tmp or bad file, with key "
              . $unused_file->{key};
        } else {
            my @log_lines = map { s/^/  /r } @{ $unused_file->{log_lines} };
            unless ($just_print) {
                # truncate log output if necessary to ensure user's
                # terminal does not scroll
                my (undef, $height) = GetTerminalSize;
                splice @log_lines, $height - (5 + @log_lines)
                  if 5 + @log_lines > $height;
            }
            print "\n";
            say for @log_lines;
            unless ($just_print) {
                my $response;
              READKEY: while (1) {
                    # before prompting, clear out stdin, to avoid
                    # registered a keypress more than once
                    ReadMode 4;
                    1 while defined ReadKey(-1);

                    my @opts = ('y', 'n');
                    push @opts, 'o' if $contentlocation;
                    push @opts, ('d', 'b') if $i > 0;
                    print "Drop this unused files?  ("
                      . join('/', @opts) . ") ";

                    # Term::ReadKey docs recommend ReadKey(-1) but that
                    # means we need an infinite loop calling ReadKey(-1)
                    # over and over, which ramps up system load
                    my $response = ReadKey(0);
                    ReadMode 0;

                    # respond to C-c
                    exit 0 if ord $response == 3;

                    say $response;
                    $response = lc($response);
                    if ($response eq "y") {
                        push @to_drop, $unused_file->{number};
                        last READKEY;
                    } elsif ($response eq "n") {
                        last READKEY;
                    } elsif ($response eq "o" and defined $contentlocation) {
                        system "xdg-open", $contentlocation;
                    } elsif ($response eq "b" and $i > 0) {
                        $i--;
                        pop @to_drop
                          if @to_drop
                          and $to_drop[$#to_drop] eq
                          $unused_files[$i]->{number};
                        next UNUSED;
                    } elsif ($response eq "d" and $i > 0) {
                        # user wants to drop the list we've accumulated up
                        # until now and get out of this script
                        last UNUSED;
                    } else {
                        say "invalid response";
                    }
                }
            }
        }
        print "\n";
        $i++;
    }

    if (@to_drop) {
        _say_spaced_bullet("Will dropunused with --force:");
        say "@to_drop\n";
        $annex->annex->dropunused(\%dropunused_args, "--force", @to_drop)
          if _prompt_yn("Go ahead with this?");
    }

    # exit value represents whether or not there are any unused files left
    # after this run.  note that in --just-print mode, @to_drop will be
    # empty, so we'll always exit non-zero if there are any unused files
    exit(@to_drop != @unused_files);

  EXIT_MAIN:
    return $exit_main;
}

sub _say_bold { print colored(['bold'], @_), "\n" }

sub _say_bullet { _say_bold(" • ", @_) }

sub _say_spaced_bullet { _say_bold("\n", " • ", @_, "\n") }

sub _prompt_yn {
    my $prompt = shift;
    local $| = 1;
    my $response;
    while (1) {
        print colored(['bold'], "$prompt ");
        chomp(my $response = <STDIN>);
        return 1 if lc($response) eq "y";
        return 0 if lc($response) eq "n";
        say "invalid response";
    }
}

sub exit { $exit_main = shift // 0; goto EXIT_MAIN }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::git_annex_reviewunused - interactively process 'git annex unused' output

=head1 VERSION

version 0.008

=head1 FUNCTIONS

=head2 main

Implementation of git-annex-reviewunused(1).  Please see documentation
for that command.

Normally takes no arguments and responds to C<@ARGV>.  If you want to
override that you can pass an arrayref of arguments, and those will be
used instead of the contents of C<@ARGV>.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2021 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
