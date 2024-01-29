package Ixchel::functions::github_releases;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(github_releases);
use LWP::UserAgent ();
use JSON;

=head1 NAME

Ixchel::functions::github_releases - Fetches release information for the specified Github repo

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::github_releases;

    my $releases;
    eval{ $releases=github_releases(owner=>'mikefarah', repo=>'yq'); };
    if ($@) {
        print 'Error: '.$@."\n";
    }

=head1 Functions

=head2 github_releases

The following args are required.

    - owner :: The owner of the repo in question.

    - repo :: Repo to fetch the releases for.

The following are optional.

    - raw :: Return the raw JSON and don't decode it.
        Default :: 0

If the $ENV variables below are set, they will be used for proxy info,
but the ones above will take president over that and set the env vars.

    $ENV{FTP_PROXY}
    $ENV{HTTP_PROXY}
    $ENV{HTTPS_PROXY}

Upon errors, this will die.

=cut

sub github_releases {
	my (%opts) = @_;

	if ( !defined( $opts{owner} ) ) {
		die('owner not specified');
	}

	if ( !defined( $opts{repo} ) ) {
		die('repo not specified');
	}

	my $url     = 'https://api.github.com/repos/' . $opts{owner} . '/' . $opts{repo} . '/releases';
	my $content;
	eval{
		my $ua = LWP::UserAgent->new(timeout => 10);
		if (defined($ENV{HTTP_PROXY})) {
			$ua->proxy(['http'], $ENV{HTTP_PROXY});
		}
		if (defined($ENV{HTTPS_PROXY})) {
			$ua->proxy(['https'], $ENV{HTTPS_PROXY});
		}
		if (defined($ENV{FTP_PROXY})) {
			$ua->proxy(['ftp'], $ENV{FTP_PROXY});
		}

		my $response = $ua->get($url);

		if ($response->is_success) {
			$content=$response->decoded_content;
		}else {
			die($response->status_line);
		}
	};
	if ($@) {
		die( 'Fetching "' . $url . '" failed'... $@ );
	}

	if ( $opts{raw} ) {
		return $content;
	}

	my $json;
	eval { $json = decode_json($content); };
	if ($@) {
		die( 'Decoding JSON from "' . $url . '" failed... ' . $@ );
	}

	return $json;
} ## end sub github_releases

1;
