use strict;
use warnings;
package Dist::Zilla::Role::RepoFileInjector; # git description: v0.006-2-gaf009ca
# ABSTRACT: Create files outside the build directory
# KEYWORDS: plugin distribution generate create file repository
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.007';

use Moose::Role;

use MooseX::Types qw(enum role_type);
use MooseX::Types::Moose qw(ArrayRef Str Bool);
use Path::Tiny 0.022;
use Cwd ();
use namespace::clean;

has repo_root => (
    is => 'ro', isa => Str,
    predicate => '_has_repo_root',
    lazy => 1,
    default => sub { path(Cwd::getcwd())->stringify },
);

has allow_overwrite => (
    is => 'ro', isa => Bool,
    default => 1,
);

has _repo_files => (
    isa => ArrayRef[role_type('Dist::Zilla::Role::File')],
    lazy => 1,
    default => sub { [] },
    traits => ['Array'],
    handles => {
        __push_repo_file => 'push',
        _repo_files => 'elements',
    },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        version => $VERSION,
        allow_overwrite => ( $self->allow_overwrite ? 1 : 0 ),
        repo_root => ( $self->_has_repo_root ? $self->repo_root : '.' ),
    };
    return $config;
};

sub add_repo_file
{
    my ($self, $file) = @_;

    my ($pkg, undef, $line) = caller;
    if ($file->can('_set_added_by'))
    {
        $file->_set_added_by(sprintf("%s (%s line %s)", $self->plugin_name, $pkg, $line));
    }
    else
    {
        # as done in Dist::Zilla::Role::FileInjector 4.300039
        $file->meta->get_attribute('added_by')->set_value(
            $file,
            sprintf("%s (%s line %s)", $self->plugin_name, $pkg, $line),
        );
    }

    $self->log_debug([ 'adding file %s', $file->name ]);

    $self->__push_repo_file($file);
}

sub write_repo_files
{
    my $self = shift;

    foreach my $file ($self->_repo_files)
    {
        my $filename = path($file->name);
        my $abs_filename = $filename->is_relative
            ? path($self->repo_root)->child($file->name)->stringify
            : $file->name;

        if (-e $abs_filename and $self->allow_overwrite)
        {
            $self->log_debug([ 'removing pre-existing %s', $abs_filename ]);
            unlink $abs_filename ;
        }
        $self->log_fatal([ '%s already exists (allow_overwrite = 0)', $abs_filename ]) if -e $abs_filename;

        $self->log_debug([ 'writing out %s%s', $file->name,
            $filename->is_relative ? ' to ' . $self->repo_root : '' ]);

        Carp::croak("attempted to write $filename multiple times") if -e $filename;
        $filename->touchpath;

        # handle dzil v4 files by assuming no (or latin1) encoding
        my $encoded_content = $file->can('encoded_content') ? $file->encoded_content : $file->content;

        $filename->spew_raw($encoded_content);
        chmod $file->mode, "$filename" or die "couldn't chmod $filename: $!";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::RepoFileInjector - Create files outside the build directory

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your F<dist.ini>:

    [MyPlugin]

And in your plugin:

    package Dist::Zilla::Plugin::MyPlugin;
    use Moose;
    with 'Dist::Zilla::Role::RepoFileInjector';

    sub some_method {
        ...
        $self->add_repo_file(Dist::Zilla::File::InMemory->new(...));
    }

    sub some_other_method {
        ...
        $self->write_repo_files;
    }

=head1 DESCRIPTION

This role is to be consumed by any plugin that plans to create files outside
the distribution.

=head1 ATTRIBUTES

=head2 repo_root

A string indicating the base directory where the file(s) are written, when
relative paths are provided. Defaults to the current working directory.

This attribute is available as an option of your plugin in F<dist.ini>.

=head2 allow_overwrite

A boolean indicating whether it is permissible for the file to already exist
(whereupon it is overwritten).  When false, a fatal exception is thrown when
the file already exists.

Defaults to true.

This attribute is available as an option of your plugin in F<dist.ini>.

=head1 METHODS

=head2 add_repo_file

    $plugin->add_repo_file($dzil_file);

Registers a file object to be written to disk.
If the path is not absolute, it is treated as relative to C<repo_root>.
The file should consume the L<Dist::Zilla::Role::File> role.
Normally the consuming plugin would call this in the C<FileGatherer> phase.

=head2 write_repo_files

    $plugin->write_repo_files;

Writes out all files registered previously with C<add_repo_file>. Your plugin
should normally do this during either the C<AfterBuild> or C<AfterRelease>
phase, e.g.:

    sub after_build
    {
        my $self = shift;
        $self->write_repo_files;
    }

=head2 _repo_files

Returns the list of files added via C<add_repo_file>.
Normally the consuming plugin would call this in the C<FileMunger> phase.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Role::FileInjector>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-RepoFileInjector>
(or L<bug-Dist-Zilla-Role-RepoFileInjector@rt.cpan.org|mailto:bug-Dist-Zilla-Role-RepoFileInjector@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
