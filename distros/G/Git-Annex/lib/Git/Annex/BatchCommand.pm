package Git::Annex::BatchCommand;
# ABSTRACT: Perl interface to git-annex --batch commands
#
# Copyright (C) 2020  Sean Whitton <spwhitton@spwhitton.name>
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
$Git::Annex::BatchCommand::VERSION = '0.002';

use 5.028;
use strict;
use warnings;

use autodie;
use Carp;
use IPC::Open2;


sub new {
    my (undef, $annex, $cmd, @params) = @_;
    croak "not enough arguments to Git::Annex::BatchCommand constructor"
      unless $annex and $cmd;

    # normalise supplied arguments a little
    unshift @params, "--batch" unless grep /\A--batch\z/, @params;

    my $self = bless { _annex => $annex, _cmd => [$cmd, @params] }
      => "Git::Annex::BatchCommand";
    $self->_spawn;
    return $self;
}


sub say {
    my ($self, @input) = @_;
    my @output;
    for (@input) {
        chomp;
        say { $self->{_in} } $_;
        chomp(my $out = readline $self->{_out});
        push @output, $out;
    }
    return wantarray ? @output : $output[$#output];
}


*ask = \&say;


sub restart {
    my $self = shift;
    $self->_despawn;
    $self->_spawn;
}

sub _spawn {
    my $self = shift;
    my ($out, $in);
    $self->{_pid} = open2 $out, $in, "git",
      "-C", $self->{_annex}->toplevel,
      "annex", @{ $self->{_cmd} };
    ($self->{_out}, $self->{_in}) = ($out, $in);
}

sub _despawn {
    my $self = shift;
    close $self->{_in};
    close $self->{_out};
    # reap the child per IPC::Open2 docs
    waitpid $self->{_pid}, 0;
}

sub DESTROY { local($., $@, $!, $^E, $?); shift->_despawn }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Annex::BatchCommand - Perl interface to git-annex --batch commands

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # you should not instantiate this class yourself; use Git::Annex::batch
  my $annex = Git::Annex->new("/home/spwhitton/annex");
  my $batch = $annex->batch("find", "--not", "--in=here");

  # see git-annex-find(1) -- `git annex find --batch --not --in here`
  # prints an empty string for each file which is not present
  say "foo/bar is not present in this repo" unless $batch->ask("foo/bar");

=head1 DESCRIPTION

This class can be used to run git-annex commands which take the
C<--batch> option.  You can feed the command lines of input and you
will get back git-annex's responses.

The main point of using C<--batch> commands from Perl is to keep
git-annex running rather than repeatedly executing new git-annex
processes to perform queries or request changes.

=head1 METHODS

=head2 new($annex, $cmd, @args)

Initialise a batch process in Git::Annex C<$annex>, running git-annex
subcommand C<$cmd> (e.g. C<setpresentkey>) with arguments C<@args>.

You should use Git::Annex::batch in preference to this method.

=head2 say($input, ...)

Say a line or lines of input to the batch command's standard input.
Trailing line breaks in C<$input> are optional.

In list context, returns a list of git-annex's responses to the items
of input, chomped.  In scalar context, returns the last of git-annex's
responses, chomped.

=head2 ask($input, ...)

Synonym for C<say> method.

=head2 restart

Kill and restart the C<--batch> command.

This is sometimes needed to ensure the C<--batch> command picks up
changes made to the git-annex branch.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
