package Ixchel::Actions::github_fetch_release_asset;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use JSON;
use Ixchel::functions::github_fetch_release_asset;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::github_fetch_release_asset - Fetch an release asset from a github repo.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a github_fetch_release_asset B<-o> <owner> B<-r> <repo> B<-f> <asset> B<-P> [B<--pre>] B<-P>

ixchel -a github_fetch_release_asset B<-o> <owner> B<-r> <repo> B<-f> <asset> B<-w> <outfile>
[B<--ppre>] [B<-N>] [B<-A>] [B<-B>] [B<-U>] <umask>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'github_fetch_release_asset',
                                opts=>{o=>'mikefarah', r=>'yq', f=>'checksums' w=>'/tmp/yq-checksums' });

    print Dumper($results);

=head1 FLAGS

Fetch an release asset from a github repo for the latest release.

=head2 -o <owner>

The repo owner.

=head2 -r <repo>

The repo to fetch it from in org/repo format.

=head2 -f <asset>

The name of the asset to fetch for a release.

=head2 --pre

Pre-releases are okay.

=head2 -d

Draft-releases are okay.

=head2 -P

Print it out instead of writing it out.

=head2 -w <output>

Where to write the output to.

=head2 -N

Do not overwrite if the file already exists.

=head2 -A

Write the file out in append mode.

=head2 -B

Write the file in a atomicly if possible.

=head2 -U

Umask to use. If undef will default to what ever sysopen is.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .content :: Fetched content.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	# if neither are defined error and return
	if ( !defined( $self->{opts}{r} ) ) {
		$self->status_add(
			error  => 1,
			status => '-r not specified'
		);
		return undef;
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{o} ) ) {
		$self->status_add(
			error  => 1,
			status => '-o not specified'
		);
		return undef;
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{f} ) ) {
		$self->status_add(
			error  => 1,
			status => '-fs not specified'
		);
		return undef;
	}

	my $content;
	eval {
		$content = github_fetch_release_asset(
			owner  => $self->{opts}{o},
			repo   => $self->{opts}{r},
			asset  => $self->{opts}{f},
			output => $self->{opts}{w},
			pre    => $self->{opts}{p},
			draft  => $self->{opts}{d},
			atomic => $self->{opts}{B},
			append => $self->{opts}{A},
			return => $self->{opts}{P},
		);
	};
	if ($@) {
		$self->status_add(
			error  => 1,
			status => 'Fetching ' . $self->{opts}{o} . '/' . $self->{opts}{r} . ' failed... ' . $@
		);
	}
	$self->{results}{content} = $content;

	if ( $self->{opts}{P} ) {
		print $content;
	}
	return undef;
} ## end sub action_extra

sub short {
	return 'Fetch an release asset from a github repo.';
}

sub opts_data {
	return '
r=s
f=s
pre
d
o=s
w=s
P
N
A
B
U
';
} ## end sub opts_data

1;
