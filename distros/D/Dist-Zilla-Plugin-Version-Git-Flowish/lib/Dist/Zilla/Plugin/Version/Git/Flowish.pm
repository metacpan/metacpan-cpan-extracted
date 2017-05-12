package Dist::Zilla::Plugin::Version::Git::Flowish;
{
  $Dist::Zilla::Plugin::Version::Git::Flowish::VERSION = '0.09';
}
use Moose;
use v5.10;

# ABSTRACT: Get a version number via git and a flow-inspired structure.

with (
    'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::TextTemplate'
);


has master_regexp  => (
    is => 'ro',
    isa=>'Str',
    default => '^master$'
);

has release_regexp  => (
    is => 'ro',
    isa=>'Str',
    default => '^release-(\d+.\d+\.\d+)$'
);

has tag_regexp  => (
    is => 'ro',
    isa=>'Str',
    default => '^(\d.\d+\.\d+)$'
);

sub provide_version {
    my ($self) = @_;

    # Get the current branch, so we can decide how to proceed.
    my ($branch) = `git branch --no-color 2> /dev/null` =~ /^\* (.*)/m;

    $self->log_debug([ 'picked up branch %s', $branch ]);

    my $version = undef;
    my $extra_version = $ENV{'FLOWISH_EXTRA_VERSION'};

    # Let an environment variable override the version.
    if(exists($ENV{'FLOWISH_VERSION'})) {
        $self->log_debug([ 'overriden by environment' ]);
        $version = $ENV{'FLOWISH_VERSION'};
        $self->log_debug("Got version from environment");
    }

    # Verify that we didn't already get a version from the ENV
    if(!defined($version)) {

        my $master_re = $self->master_regexp;
        my $release_re = $self->release_regexp;
        my $tag_re = $self->tag_regexp;

        given($branch) {

            when(/$master_re/) {
                # If the branch is master then we'll get the most recent tag and
                # use it as the version number.
                $self->log_debug([ 'fetching latest tag due to master branch' ]);
                my $tag = `git describe --tags --abbrev=0`;
                $tag =~ /$tag_re/;
                $version = $1;
            }
            when(/$release_re/) {
                $self->log_debug([ 'gleaning version from release branch' ]);
                # If this is a release branch, grab the version number from the
                # branch name.
                $version = $1;
            }
            default {
                $self->log_fatal("Couldn't find a version from master or release. Check regexp?");
            }
        }
    }

    if(defined($extra_version)) {
        $self->log_debug("Adding extra version from env");
        $version .= '_'.$extra_version;
    }

    $self->log_debug([ 'returning version %s', $version ]);
    return $version;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Version::Git::Flowish - Get a version number via git and a flow-inspired structure.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # [Version::Git::Flowish]
    # master_regexp = ^master$
    # release_regexp = ^release-(\d+.\d+\.\d+)$
    # tag_regexp = ^(\d.\d+\.\d+)$

=head1 DESCRIPTION

This plugin consumes the Dist::Zilla VersionProvider role and gleans a version
number from Git using a structure similar to Vincent Driessen's
L<git flow|http://nvie.com/posts/a-successful-git-branching-model/> model.

The idea is to facilitate automated systems, such as continuous integration,
to divine version numbers from the branching and release strategies used in
our repositories.

Note that, by default, the version numbers used as defaults by this plugin
are in the form of C<0.0.0>.  This can be changed by manipulating the options
shown in the Synopsis.

It works like this:

=head2 Environment Variable #1

The environment variable FLOWISH_VERSION is checked and used if set.

=head2 Branch

The current branch is attained via a call to git branch and grepping for
the leading *.

    git branch --no-color 2> /dev/null

=head2 Case: Master Branch

If the current branch is master, then the most recent tag is attained
via:

    git describe --tags --abbrev=0

You can influence how this date is parsed using the C<tag_regexp> option.

=head2 Case: Release Branch

If this isn't the master branch, but it begins with "release-" (configurable
via C<master_regexp>) then the version number after the release- will be used.

=head2 Environment Variable #2

The environment variable FLOWISH_EXTRA_VERSION is checked and appending to the
version with an underscore as a separator.  This lets you create development
versions of whathaveyou.

=head2 And Then?

At this point we just give up and return nothing.

=head1 CONTRIBUTORS

Mike Eldridge

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

