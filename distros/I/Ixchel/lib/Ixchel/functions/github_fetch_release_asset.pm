package Ixchel::functions::github_fetch_release_asset;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(github_fetch_release_asset);
use Ixchel::functions::github_releases;
use LWP::UserAgent ();
use JSON;

=head1 NAME

Ixchel::functions::github_fetch_release_asset - Fetches a release asset from a Github repo.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::github_fetch_release_asset;

    my $releases;
    eval{ $releases=github_fetch_release_asset(owner=>'mikefarah', repo=>'yq'); };
    if ($@) {
        print 'Error: '.$@."\n";
    }

=head1 Functions

=head2 github_fetch_release_asset

The following args are required.

    - owner :: The owner of the repo in question.

    - repo :: Repo to fetch the releases for.

    - asset :: The name of the asset to fetch.

The following are optional.

    - pre :: If prereleases are okay fetch fetch or not.
        Default :: 0

    - draft :: If draft releases are okay.
        Default :: 0

    - output :: Where to write the file to. If undef, will be writen
            to a file named the same as the asset under the current dir.

    - atomic :: If it should attempt to write the file atomically.
        Default :: 0

    - append :: Append the fetched data to the output file if it already exists.
        Default :: 0

    - umask :: The umask to use. Defaults to what ever sysopen uses.

    - return :: Return the fetched item instead of writing it to a file.
        Default :: 0

If the $ENV variables below are set, they will be used for proxy info.

    $ENV{FTP_PROXY}
    $ENV{HTTP_PROXY}
    $ENV{HTTPS_PROXY}

Upon errors, this will die.

=cut

sub github_fetch_release_asset {
	my (%opts) = @_;

	if ( !defined( $opts{owner} ) ) {
		die('owner not specified');
	}

	if ( !defined( $opts{repo} ) ) {
		die('repo not specified');
	}

	if ( !defined( $opts{asset} ) ) {
		die('asset not specified');
	}

	my $releases;
	eval { $releases = github_releases( owner => $opts{owner}, repo => $opts{repo} ); };
	if ($@) {
		die( 'Failed to fetch the release info for ' . $opts{owner} . '/' . $opts{repo} . '... ' . $@ );
	}

	foreach my $release ( @{$releases} ) {
		my $use_release = 1;

		if ( ref($release) ne 'HASH' ) {
			$use_release = 0;
		}

		# if it is a draft, check if fetching of drafts is allowed
		if (   $use_release
			&& defined( $release->{draft} )
			&& $release->{draft} =~ /$[Tt][Rr][Uu][Ee]^/
			&& !$opts{draft} )
		{
			$use_release = 0;
		}

		# if it is a prerelease, check if fetching of prerelease is allowed
		if (   $use_release
			&& defined( $release->{prerelease} )
			&& $release->{prerelease} =~ /$[Tt][Rr][Uu][Ee]^/
			&& !$opts{pre} )
		{
			$use_release = 0;
		}

		if ($use_release) {
			foreach my $asset ( @{ $release->{assets} } ) {
				my $fetch_it = 0;
				if ( defined( $asset->{name} ) && $asset->{name} eq $opts{asset} ) {
					$fetch_it = 1;
				}

				if ($fetch_it) {
					my $asset_url = $asset->{browser_download_url};
					my $content;
					eval {
						my $ua = LWP::UserAgent->new( timeout => 10 );
						if ( defined( $ENV{HTTP_PROXY} ) ) {
							$ua->proxy( ['http'], $ENV{HTTP_PROXY} );
						}
						if ( defined( $ENV{HTTPS_PROXY} ) ) {
							$ua->proxy( ['https'], $ENV{HTTPS_PROXY} );
						}
						if ( defined( $ENV{FTP_PROXY} ) ) {
							$ua->proxy( ['ftp'], $ENV{FTP_PROXY} );
						}

						my $response = $ua->get($asset_url);

						if ( $response->is_success ) {
							$content = $response->decoded_content;
						} else {
							die( $response->status_line );
						}
					};
					if ($@) {
						die( 'Fetching "' . $asset_url . '" failed' ... $@ );
					}

					if ( $opts{return} ) {
						return ($content);
					}

					my $write_to = $asset->{name};
					$write_to =~ s/\//_/g;
					if ( defined( $opts{output} ) ) {
						$write_to = $opts{output};
					}

					eval {
						write_file(
							$write_to,
							{
								append => $opts{append},
								atomic => $opts{atomic},
								perms  => $opts{umask}
							},
							$content
						);
					};
					if ($@) {
						die(      'Failed to write "'
								. $asset->{browser_download_url}
								. '" out to "'
								. $write_to . '"... '
								. $@ );
					}

					return;
				} ## end if ($fetch_it)
			} ## end foreach my $asset ( @{ $release->{assets} } )
		} ## end if ($use_release)
	} ## end foreach my $release ( @{$releases} )

} ## end sub github_fetch_release_asset

1;
