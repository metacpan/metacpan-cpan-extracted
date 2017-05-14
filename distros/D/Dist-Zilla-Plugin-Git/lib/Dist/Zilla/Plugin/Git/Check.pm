#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Check;
# ABSTRACT: Check your git repository before releasing

our $VERSION = '2.042';

use Moose;
use namespace::autoclean 0.09;
use Moose::Util::TypeConstraints qw(enum);
use MooseX::Types::Moose qw(Bool);

with 'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::Git::Repo';
with 'Dist::Zilla::Role::Git::DirtyFiles',
    'Dist::Zilla::Role::GitConfig';

has build_warnings => ( is=>'ro', isa => Bool, default => 0 );

has untracked_files => ( is=>'ro', isa => enum([qw(die warn ignore)]), default => 'die' );

sub _git_config_mapping { +{
   changelog => '%{changelog}s',
} }

# -- public methods

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        # build_warnings does not affect the build outcome; do not need to track it
        untracked_files => $self->untracked_files,
    };

    return $config;
};

sub _perform_checks {
    my ($self, $log_method) = @_;

    my @issues;
    my $git = $self->git;
    my @output;

    # fetch current branch
    my ($branch) =
        map { /^\*\s+(.+)/ ? $1 : () }
        $git->branch;

    # check if some changes are staged for commit
    @output = $git->diff( { cached=>1, 'name-status'=>1 } );
    if ( @output ) {
        push @issues, @output . " staged change" . (@output == 1 ? '' : 's');

        my $errmsg =
            "branch $branch has some changes staged for commit:\n" .
            join "\n", map { "\t$_" } @output;
        $self->$log_method($errmsg);
    }

    # everything but files listed in allow_dirty should be in a
    # clean state
    @output = $self->list_dirty_files($git);
    if ( @output ) {
        push @issues, @output . " uncommitted file" . (@output == 1 ? '' : 's');

        my $errmsg =
            "branch $branch has some uncommitted files:\n" .
            join "\n", map { "\t$_" } @output;
        $self->$log_method($errmsg);
    }

    # no files should be untracked
    @output = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
    if ( @output ) {
      push @issues, @output . " untracked file" . (@output == 1 ? '' : 's');

      my $untracked = $self->untracked_files;
      if ($untracked ne 'ignore') {
        # If $log_method is log_fatal, switch to log unless
        # untracked files are fatal.  If $log_method is already log,
        # this is a no-op.
        $log_method = 'log' unless $untracked eq 'die';

        my $errmsg =
            "branch $branch has some untracked files:\n" .
                join "\n", map { "\t$_" } @output;
        $self->$log_method($errmsg);
      }
    }

    if (@issues) {
      $self->log( "branch $branch has " . join(', ', @issues));
    } else {
      $self->log( "branch $branch is in a clean state" );
    }
} # end _perform_checks

sub after_build {
    my $self = shift;

    $self->_perform_checks('log') if $self->build_warnings;
}

sub before_release {
    my $self = shift;

    $self->_perform_checks('log_fatal');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Check - Check your git repository before releasing

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = README
    changelog = Changes      ; this is the default
    build_warnings = 0       ; this is the default
    untracked_files = die    ; default value (can also be "warn" or "ignore")

=head1 DESCRIPTION

This plugin checks that your Git repo is in a clean state before releasing.
The following checks are performed before releasing:

=over 4

=item * there should be no files in the index (staged copy)

=item * there should be no untracked files in the working copy

=item * the working copy should be clean. The files listed in
C<allow_dirty> can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release
will thus be aborted. This lets you fix the problems before continuing.

The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. defaults to F<Changes>.

=item * allow_dirty - a file that is allowed to have local
modifications.  This option may appear multiple times.  The default
list is F<dist.ini> and the changelog file given by C<changelog>.  You
can use C<allow_dirty => to prohibit all local modifications.

=item * allow_dirty_match - works the same as allow_dirty, but
matching as a regular expression instead of an exact filename.

=item * build_warnings - if 1, perform the same checks after every build,
but as warnings, not errors.  Defaults to 0.

=item * untracked_files - indicates what to do if there are untracked
files.  Must be either C<die> (the default), C<warn>, or C<ignore>.
C<warn> lists the untracked files, while C<ignore> only prints the
total number of untracked files.

=back

=for Pod::Coverage after_build
    before_release

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
