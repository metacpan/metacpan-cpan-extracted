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

package Dist::Zilla::Plugin::Git::Commit;
# ABSTRACT: Commit dirty files

our $VERSION = '2.042';

use namespace::autoclean;
use File::Temp           qw{ tempfile };
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use MooseX::Types::Path::Tiny 0.010 qw{ Paths };
use Path::Tiny 0.048 qw(); # subsumes
use Cwd;

with 'Dist::Zilla::Role::AfterRelease',
    'Dist::Zilla::Role::Git::Repo';
with 'Dist::Zilla::Role::Git::DirtyFiles';
with 'Dist::Zilla::Role::Git::StringFormatter';
with 'Dist::Zilla::Role::GitConfig';

sub _git_config_mapping { +{
   changelog => '%{changelog}s',
} }

# -- attributes

has commit_msg => ( ro, isa=>Str, default => 'v%v%n%n%c' );
has add_files_in  => ( ro, isa=> Paths, coerce => 1, default => sub { [] });


# -- public methods

sub mvp_multivalue_args { qw( add_files_in ) }

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        commit_msg => $self->commit_msg,
        add_files_in => [ sort @{ $self->add_files_in } ],
    };

    return $config;
};

sub after_release {
    my $self = shift;

    my $git  = $self->git;
    my @output;

    # check if there are dirty files that need to be committed.
    # at this time, we know that only those 2 files may remain modified,
    # otherwise before_release would have failed, ending the release
    # process.
    @output = sort { lc $a cmp lc $b } $self->list_dirty_files($git, 1);

    # add any other untracked files to the commit list
    if ( @{ $self->add_files_in } ) {
        my @untracked_files = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
        foreach my $f ( @untracked_files ) {
            foreach my $path ( @{ $self->add_files_in } ) {
                if ( Path::Tiny::path( $path )->subsumes( $f ) ) {
                    push( @output, $f );
                    last;
                }
            }
        }
    }

    # if nothing to commit, we're done!
    return unless @output;

    # write commit message in a temp file
    my ($fh, $filename) = tempfile( getcwd . '/DZP-git.XXXX', UNLINK => 1 );
    binmode $fh, ':utf8' unless Dist::Zilla->VERSION < 5;
    print $fh $self->get_commit_message;
    close $fh;

    # commit the files in git
    $git->add( @output );
    $self->log_debug($_) for $git->commit( { file=>$filename } );
    $self->log("Committed @output");
}


#pod =method get_commit_message
#pod
#pod This method returns the commit message.  The default implementation
#pod reads the Changes file to get the list of changes in the just-released version.
#pod
#pod =cut

sub get_commit_message {
    my $self = shift;

    return $self->_format_string($self->commit_msg);
} # end get_commit_message

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Commit - Commit dirty files

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Commit]
    changelog = Changes      ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
committing changelog and F<dist.ini>. The commit message will be taken
from the changelog for this release.  It will include lines between
the current version and timestamp and the next non-indented line,
except that blank lines at the beginning or end are removed.

B<Warning:> If you are using Git::Commit in conjunction with the
L<NextRelease|Dist::Zilla::Plugin::NextRelease> plugin,
C<[NextRelease]> must come before C<[Git::Commit]> (or C<[@Git]>) in
your F<dist.ini> or plugin bundle.  Otherwise, Git::Commit will commit
the F<Changes> file before NextRelease has updated it.

The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. Defaults to F<Changes>.

=item * allow_dirty - a file that will be checked in if it is locally
modified.  This option may appear multiple times.  The default
list is F<dist.ini> and the changelog file given by C<changelog>.

=item * allow_dirty_match - works the same as allow_dirty, but
matching as a regular expression instead of an exact filename.

=item * add_files_in - a path that will have its new files checked in.
This option may appear multiple times. This is used to add files
generated during build-time to the repository, for example. The default
list is empty.

Note: The files have to be generated between the phases BeforeRelease
E<lt>-E<gt> AfterRelease, and after Git::Check + before Git::Commit.

=item * commit_msg - the commit message to use. Defaults to
C<v%v%n%n%c>, meaning the version number and the list of changes.
The L<formatting codes|Dist::Zilla::Role::Git::StringFormatter/DESCRIPTION>
are documented under L<Dist::Zilla::Role::Git::StringFormatter>.

=item * time_zone - the time zone to use with C<%d>.  Can be any
time zone name accepted by DateTime.  Defaults to C<local>.

=back

=head1 METHODS

=head2 get_commit_message

This method returns the commit message.  The default implementation
reads the Changes file to get the list of changes in the just-released version.

=for Pod::Coverage after_release mvp_multivalue_args

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
