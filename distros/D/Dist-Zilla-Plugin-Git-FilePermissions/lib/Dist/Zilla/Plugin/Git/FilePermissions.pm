# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2017-2022 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::FilePermissions;

our $VERSION = '1.002';

use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

use Git::Background 0.003;
use Path::Tiny;

use namespace::autoclean;

sub mvp_multivalue_args { return (qw( perms )) }

has _git => (
    is      => 'ro',
    isa     => 'Git::Background',
    lazy    => 1,
    default => sub { Git::Background->new( path( shift->zilla->root )->absolute ) },
);

has default => (
    is      => 'ro',
    isa     => 'Str',
    default => '0644',
);

has perms => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

sub before_build {
    my ($self) = @_;

    my @files = $self->_git_ls_files();
    return if !@files;

    my @perms = $self->_permissions;

  FILE:
    for my $file (@files) {

        # Git reports submodules as a file although they are a directory on
        # the file system. We skip them because the default permissions of
        # 0644 are suboptimal for directories.
        next FILE if !-f $file;

        # default permission
        my $perm = oct( $self->default );

      PERMS:
        for my $perm_ref (@perms) {
            my ( $regex, $p ) = @{$perm_ref};

            next PERMS if $file !~ m{$regex};

            $perm = $p;
            last PERMS;
        }

        if ( $perm eq q{-} ) {
            $self->log_debug("Ignoring permissions of file $file");
            next FILE;
        }

        my $current_perm = ( stat $file )[2] & 07777;

        if ( $current_perm != $perm ) {
            $self->log( sprintf "Setting permission of $file to %o", $perm );

            my $rc = chmod $perm, $file;
            if ( $rc != 1 ) {
                $self->log_fatal( sprintf "Unable to change permissions of file $file to %o", $perm );
            }
        }
    }

    return;
}

sub _git_ls_files {
    my ($self) = @_;

    my $git = $self->_git;

    my $files_f = $git->run('ls-files')->await;

    $self->log_fatal( scalar $files_f->failure ) if $files_f->is_failed;

    my @files = $files_f->stdout;
    return @files;
}

sub _permissions {
    my ($self) = @_;

    my @perms;

  LINE:
    for my $line ( @{ $self->perms } ) {
        my ( $regex, $perm ) = $line =~ m{ ( .+ ) \s+ ((?: 0[0-9]+ | - )) \s* $ }xsm;

        if ( !defined $perm ) {
            $self->log_fatal("Unable to parse permissions line: $line");
        }

        push @perms, [
            $regex,
            $perm eq q{-} ? q{-} : oct($perm),
        ];
    }

    return @perms;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::FilePermissions - fix the file permissions in your Git repository with Dist::Zilla

=head1 VERSION

Version 1.002

=head1 SYNOPSIS

  # in dist.ini:
  [Git::FilePermissions]
  perms = ^bin/         0755
  perms = ^scripts/     0755

=head1 DESCRIPTION

This plugin fixes the file permissions of all the files in the Git repository
where your project is saved. Files not in the Git index, and directories, are
ignored.

Without configuration, every file is changed to the default permission of
0644. The default permissions can be changed with the C<default> option
and you can configure different permissions for some files with the
C<perms> option in the F<dist.ini>.

The plugin runs in the before build phase, which means it will fix the file
permissions before the files are picked up in the file gather phase. The new
permissions are therefore also the ones used in the build.

The plugin should ensure that you always commit your files with the correct
permissions.

=head2 perms

The C<perms> configuration option takes the form of:

  perms = REGEX WHITESPACE PERMS

or

  perms = REGEX WHITESPACE -

The C<perms> configuration options are processed in order for every file. If
a file matches the C<REGEX> the file permissions are changed to the
corresponding C<PERMS> instead of the default permissions of 0644. If the
C<PERMS> are C<-> the file is ignored.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-FilePermissions/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-FilePermissions>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Git-FilePermissions.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Git::RequireUnixEOL|Dist::Zilla::Plugin::Git::RequireUnixEOL>

=cut
