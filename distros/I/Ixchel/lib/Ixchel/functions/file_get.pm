package Ixchel::functions::file_get;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(file_get);
use LWP::UserAgent ();

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

If the $ENV variables below are set, they will be used for proxy info.

    $ENV{FTP_PROXY}
    $ENV{HTTP_PROXY}
    $ENV{HTTPS_PROXY}

=cut

sub file_get {
	my (%opts) = @_;

	if ( !defined( $opts{url} ) ) {
		die('url not specified');
	}

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

		my $response = $ua->get( $opts{url} );

		if ( $response->is_success ) {
			$content = $response->decoded_content;
		} else {
			die( $response->status_line );
		}
	};
	if ($@) {
		die( 'Fetching "' . $opts{url} . '" failed' ... $@ );
	}

	return $content;
} ## end sub file_get

1;
