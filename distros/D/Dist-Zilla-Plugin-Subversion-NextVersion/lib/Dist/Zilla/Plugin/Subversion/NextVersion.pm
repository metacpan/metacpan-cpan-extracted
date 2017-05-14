use strict;
use warnings;
package Dist::Zilla::Plugin::Subversion::NextVersion;
# ABSTRACT: provide a version number by bumping the last SVN release tag

use Dist::Zilla 4 ();
use version;
use Version::Next;

use Moose;
use Moose::Util::TypeConstraints;
use SVN::Client;
use Try::Tiny;

with 'Dist::Zilla::Role::VersionProvider';
with 'Dist::Zilla::Role::BeforeRelease';

has 'svn' => (
	is => 'ro',
	isa => 'SVN::Client',
	lazy => 1,
	default => sub {
		my $self = shift;
		SVN::Client->new();
	},
);

use constant _CoercedRegexp => do {
    my $tc = subtype as 'RegexpRef';
    coerce $tc, from 'Str', via { qr/$_/ };
    $tc;
};

has 'tag_folder' => (
	is => 'ro', isa => 'Str',
	default => sub {
		my $self = shift;
		return( '^/'.$self->zilla->name.'/tags/' );
	},
);

has version_regexp  => ( is => 'ro', isa=> _CoercedRegexp, coerce => 1,
                         default => sub { qr/^(.+)$/ } );

has first_version  => ( is => 'ro', isa=>'Str', default => '0.001' );

has 'all_versions' => (
	is => 'ro', isa => 'ArrayRef[version]', lazy => 1,
	default => sub {
		my $self = shift;
		my $regex = $self->version_regexp;
		my $listing = $self->svn->ls($self->tag_folder, 'HEAD', 0);
		my @versions = keys %$listing;
		@versions = sort map { /$regex/ ? try { version->parse("$1") } : () } @versions;
		return( \@versions );
	},
);

has 'max_version' => (
	is => 'ro', isa => 'version', lazy => 1,
	default => sub {
		my $self = shift;
		if( ! @{$self->all_versions} ) {
			die('could not obtain max_version from empty version list!');
		}
		return( $self->all_versions->[-1] );
	},
);

has 'next_version' => (
	is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;
		return( Version::Next::next_version($self->max_version->stringify) );
	},
);

sub provide_version {
	my ($self) = @_;

	# override (or maybe needed to initialize)
	if( exists $ENV{V} ) {
		$self->log("using version ".$ENV{V}.' from environment');
		return $ENV{V};
	}

	my $max_version = $self->max_version;
	my $next_version = $self->next_version;

	$self->log("bumping version from $max_version to $next_version");

	return "$next_version";
}

sub before_release {
	my $self = shift;
	my $version = version->parse( $self->zilla->version );

	if( grep { $_ == $version } @{$self->all_versions} ) {
		$self->log_fatal("version $version has already been tagged")
	}
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Subversion::NextVersion - provide a version number by bumping the last subversion release tag

=head1 VERSION

version 1.000

=head1 SYNOPSIS

In your F<dist.ini>:

    [Subversion::NextVersion]
    tag_folder = '^/<your-dist-name>/tags/' ; this is the default
    first_version = 0.001       ; this is the default
    version_regexp  = ^(.+)$   ; this is the default

=head1 DESCRIPTION

This does the L<VersionProvider|Dist::Zilla::Role::VersionProvider> role.
It finds the last version number from your the C<tag_folder>, increments it
using L<Version::Next>, and uses the result as the C<version> parameter
for your distribution.

In addition, when making a release, it ensures that the version being
released has not already been tagged. 

The plugin accepts the following options:

=over

=item *

C<tag_folder> - this folder is used to search for tagged versions of your project.
It defaults to '^/<your-dist-name>/tags/'.
Must be subversion repository or working directory URL.

=item *

C<first_version> - if the repository has no tags at all, this version
is used as the first version for the distribution.  It defaults to "0.001".

=item *

C<version_regexp> - regular expression that matches a tag containing
a version.  It must capture the version into $1.  Defaults to ^(.+)$

=back

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

=head1 AUTHOR

Markus Benning

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Markus Benning

It is based on Dist::Zilla::Plugin::Git::NextVersion which is
copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
