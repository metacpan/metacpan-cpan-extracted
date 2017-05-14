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

package Dist::Zilla::Plugin::Git::CommitBuild;
# ABSTRACT: Check in build results on separate branch

our $VERSION = '2.042';

use Git::Wrapper 0.021 ();      # need -STDIN
use IPC::Open3;
use IPC::System::Simple; # required for Fatalised/autodying system
use File::chdir;
use File::Spec::Functions qw/ rel2abs catfile /;
use File::Temp;
use Moose;
use namespace::autoclean;
use Path::Tiny qw();
use MooseX::Types::Path::Tiny qw( Path );
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str Bool };
use Cwd qw(abs_path);
use Try::Tiny;

use String::Formatter (
	method_stringf => {
		-as   => '_format_branch',
		codes => {
			b => sub { shift->_source_branch },
		},
	},
	method_stringf => {
		-as   => '_format_message',
		codes => {
			b => sub { shift->_source_branch },
			h => sub { (shift->git->rev_parse( '--short',    'HEAD' ))[0] },
			H => sub { (shift->git->rev_parse('HEAD'))[0] },
		    t => sub { shift->zilla->is_trial ? '-TRIAL' : '' },
		    v => sub { shift->zilla->version },
		}
	}
);

# debugging...
#use Smart::Comments '###';

with 'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::AfterRelease',
    'Dist::Zilla::Role::Git::Repo';

# -- attributes

has branch  => ( ro, isa => Str, default => 'build/%b', required => 1 );
has release_branch  => ( ro, isa => Str, required => 0 );
has message => ( ro, isa => Str, default => 'Build results of %h (on %b)', required => 1 );
has release_message => ( ro, isa => Str, lazy => 1, builder => '_build_release_message' );
has build_root => ( rw, coerce => 1, isa => Path );

has _source_branch => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    init_arg=> undef,
    default => sub {
        ($_[0]->git->name_rev( '--name-only', 'HEAD' ))[0];
    },
);

has multiple_inheritance => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# -- attribute builders

sub _build_release_message { return shift->message; }

# -- role implementation

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ }
            qw(branch release_branch message release_message build_root)),
        multiple_inheritance => $self->multiple_inheritance ? 1 : 0,
    };

    return $config;
};

sub after_build {
    my ( $self, $args) = @_;

    # because the build_root mysteriously change at
    # the 'after_release' stage
    $self->build_root( $args->{build_root} );

    $self->_commit_build( $args, $self->branch, $self->message );
}

sub after_release {
    my ( $self, $args) = @_;

    $self->_commit_build( $args, $self->release_branch, $self->release_message );
}

sub _commit_build {
    my ( $self, undef, $branch, $message ) = @_;

    return unless $branch;

    my $dir = Path::Tiny->tempdir( CLEANUP => 1) ;
    my $src = $self->git;

    my $target_branch = _format_branch( $branch, $self );

    for my $file ( @{ $self->zilla->files } ) {
        my ( $name, $content ) = ( $file->name, (Dist::Zilla->VERSION < 5
                                                 ? $file->content
                                                 : $file->encoded_content) );
        my ( $outfile ) = $dir->child( $name );
        $outfile->parent->mkpath();
        $outfile->spew_raw( $content );
        chmod $file->mode, "$outfile" or die "couldn't chmod $outfile: $!";
    }

    # returns the sha1 of the created tree object
    my $tree = $self->_create_tree($src, $dir);

    my ($last_build_tree) = try { $src->rev_parse("$target_branch^{tree}") };
    $last_build_tree ||= 'none';

    ### $last_build_tree
    if ($tree eq $last_build_tree) {

        $self->log("No changes since the last build; not committing");
        return;
    }

    my @parents = (
        ( $self->_source_branch ) x $self->multiple_inheritance,
        grep {
            eval { $src->rev_parse({ 'q' => 1, 'verify'=>1}, $_ ) }
        } $target_branch
    );

    ### @parents

    my $this_message = _format_message( $message, $self );
    my @commit = $src->commit_tree( { -STDIN => $this_message }, $tree, map { ( '-p' => $_) } @parents );

    ### @commit
    $src->update_ref( 'refs/heads/' . $target_branch, $commit[0] );
}

sub _create_tree {
    my ($self, $repo, $fs_obj) = @_;

    ### called with: "$fs_obj"
    if (!$fs_obj->is_dir) {

        my ($sha) = $repo->hash_object({ w => 1 }, "$fs_obj");
        ### hashed: "$sha $fs_obj"
        return $sha;
    }

    my @entries;
    for my $obj ($fs_obj->children) {

        ### working on: "$obj"
        my $sha  = $self->_create_tree($repo, $obj);
        my $mode = sprintf('%o', $obj->stat->mode); # $obj->is_dir ? '040000' : '
        my $type = $obj->is_dir ? 'tree' : 'blob';
        my $name = $obj->basename;

        push @entries, "$mode $type $sha\t$name";
    }

    ### @entries

    my ($sha) = $repo->mktree({ -STDIN => join("\n", @entries, q{}) });

    return $sha;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::CommitBuild - Check in build results on separate branch

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::CommitBuild]
	; these are the defaults
    branch = build/%b
    message = Build results of %h (on %b)
    multiple_inheritance = 0

=head1 DESCRIPTION

Once the build is done, this plugin will commit the results of the
build to a branch that is completely separate from your regular code
branches (i.e. with a different root commit).  This potentially makes
your repository more useful to those who may not have L<Dist::Zilla>
and all of its dependencies installed.

The plugin accepts the following options:

=over 4

=item * branch - L<String::Formatter> string for where to commit the
build contents.

A single formatting code (C<%b>) is defined for this attribute and will be
substituted with the name of the current branch in your git repository.

Defaults to C<build/%b>, but if set explicitly to an empty string
causes no build contents checkin to be made.

=item * release_branch - L<String::Formatter> string for where to commit the
build contents

Same as C<branch>, but commit the build content only after a release. No
default, meaning no release branch.

=item * message - L<String::Formatter> string for what commit message
to use when committing the results of the build.

This option supports five formatting codes:

=over 4

=item * C<%b> - Name of the current branch

=item * C<%H> - Commit hash

=item * C<%h> - Abbreviated commit hash

=item * C<%v> - The release version number

=item * C<%t> - The string "-TRIAL" if this is a trial release

=back

=item * release_message - L<String::Formatter> string for what
commit message to use when committing the results of the release.

Defaults to the same as C<message>.

=item * multiple_inheritance - Indicates whether the commit containing
the build results should have the source commit as a parent.

If false (the default), the build branch will be completely separate
from the regular code branches.  If set to a true value, commits on a
build branch will have two parents: the previous build commit and the
source commit from which the build was generated.

=back

=for Pod::Coverage after_build
    after_release

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
