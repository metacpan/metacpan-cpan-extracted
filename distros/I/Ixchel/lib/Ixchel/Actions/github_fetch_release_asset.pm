package Ixchel::Actions::github_fetch_release_asset;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use LWP::Simple;
use JSON;
use Ixchel::functions::github_fetch_release_asset;

=head1 NAME

Ixchel::Actions::github_fetch_release_asset :: Fetch an release asset from a github repo.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

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

=head2 -p

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

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
	};
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	if ( defined( $opts{t} ) ) {
		$self->{t} = $opts{t};
	} else {
		die('$opts{t} is undef');
	}

	if ( defined( $opts{share_dir} ) ) {
		$self->{share_dir} = $opts{share_dir};
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	if ( defined( $opts{argv} ) ) {
		$self->{argv} = $opts{argv};
	}

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	# if neither are defined error and return
	if ( !defined( $self->{opts}{r} ) ) {
		my $error = '-r not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{o} ) ) {
		my $error = '-o not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{f} ) ) {
		my $error = '-fs not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
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
		die( 'Fetching ' . $self->{opts}{o} . '/' . $self->{opts}{r} . ' failed... ' . $@ );
	}

	if ( $self->{opts}{P} ) {
		print $content;
	}
} ## end sub action

sub help {
	return 'Fetch an release asset from a github repo for the latest release.

-o <owner>   The repo owner.

-r <repo>    The repo to fetch it from in org/repo format.

-f <asset>   The name of the asset to fetch for a release.

-p           Pre-releases are okay.

-d           Draft-releases are okay.

-P           Print it out instead of writing it out.

-w <output>  Where to write the output to.

-A           Write the file out in append mode.

-B           Write the file in a atomicly if possible.

-U           umask to use. If undef will default to what ever sysopen is.
';
} ## end sub help

sub short {
	return 'Fetch an release asset from a github repo.';
}

sub opts_data {
	return '
r=s
f=s
p
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
