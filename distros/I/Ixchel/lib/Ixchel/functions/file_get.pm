package Ixchel::functions::file_get;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(file_get);
use LWP::Simple;

=head1 NAME

Ixchel::functions::file_get - Fetches a file file via URL.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::file_get;

    my $file=file_get(url=>'https://raw.githubusercontent.com/quadrantsec/sagan/main/etc/sagan.yaml');

=head1 Functions

=head2 file_get

Any protocol understood via L<LWP> may be used.

If it failes to fetch it, it will die.

    - url :: The URL to fetch. Required.

    - ftp :: FTP proxy to use. Optional.

    - http :: HTTP proxy to use. Optional.

    - https :: HTTPS proxy to use. Optional.

If the $ENV variables below are set, they will be used for proxy info,
but the ones above will take president over that and set the env vars.

    $ENV{FTP_PROXY}
    $ENV{HTTP_PROXY}
    $ENV{HTTPS_PROXY}

=cut

sub file_get {
	my ( %opts ) = @_;

	if ( !defined( $opts{url} ) ) {
		die('url not specified');
	}

	if ( defined( $opts{ftp} ) ) {
		$ENV{FTP_PROXY} = $opts{ftp};
	}
	if ( defined( $opts{http} ) ) {
		$ENV{HTTP_PROXY} = $opts{http};
	}
	if ( defined( $opts{https} ) ) {
		$ENV{HTTPS_PROXY} = $opts{https};
	}

	my $content = get( $opts{url} );
	if ( !defined($content) ) {
		die( 'Fetching "' . $opts{url} . '" failed' );
	}

	return $content;
} ## end sub file_get

1;
