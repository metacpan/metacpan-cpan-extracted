package Dist::Zilla::Plugin::Git::FilePermissions;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
);

has _git => (
    is      => 'ro',
    isa     => 'Git::Wrapper',
    lazy    => 1,
    default => sub { Git::Wrapper->new( path( shift->zilla->root )->absolute->stringify ) },
);

sub mvp_multivalue_args { return (qw( perms )) }

has perms => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

use Git::Wrapper;
use Path::Tiny;
use Safe::Isa;
use Try::Tiny;

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    my @files = $self->_git_ls_files();
    return if !@files;

    my @perms = $self->_permissions;

  FILE:
    for my $file (@files) {

        # default permission
        my $perm = 0644;

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

    my @files;
    try {
        @files = $git->ls_files();
    }
    catch {
        my $fatal = $_;
        if ( $fatal->$_isa('Git::Wrapper::Exception') ) {
            my $err = $git->ERR;
            if ( $err and @{$err} ) {
                $self->log( @{$err} );
            }

            $self->log_fatal( $fatal->error );
        }

        $self->log_fatal($fatal);
    };

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

Version 0.002

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
0644. You can configure different permissions for some files with the
B<perms> argument in the F<dist.ini>.

The plugin runs in the before build phase, which means it will fix the file
permissions before the files are picked up in the file gather phase. The new
permissions are therefore also the ones used in the build.

The plugin should ensure that you always commit your files with the correct
permissions.

=head2 perms

The B<perms> configuration option takes the form of:

  perms = REGEX WHITESPACE PERMS

or

  perms = REGEX WHITESPACE -

The B<perms> configuration options are processed in order for every file. If
a file matches the B<REGEX> the file permissions are changed to the
corresponding B<PERMS> instead of the default permissions of 0644. If the
B<PERMS> are B<-> the file is ignored.

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

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Git::RequireUnixEOL|Dist::Zilla::Plugin::Git::RequireUnixEOL>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
