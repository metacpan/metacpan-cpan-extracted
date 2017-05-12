#
# This file is part of Dist-Zilla-Plugin-Bitbucket
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::Bitbucket::Update;
$Dist::Zilla::Plugin::Bitbucket::Update::VERSION = '0.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Update a Bitbucket repo's info on release

use Moose;
use HTTP::Tiny 0.050;
use MIME::Base64 3.14;
use JSON::MaybeXS 1.002006 qw( encode_json decode_json );

extends 'Dist::Zilla::Plugin::Bitbucket';
with 'Dist::Zilla::Role::AfterRelease';

sub after_release {
	my $self = shift;

	my ($login, $pass)  = $self->_get_credentials(0);
	return if (!$login);

	my $repo_name = $self->_get_repo_name(1);

	# set the repo settings
	my ($params, $headers);
	$params->{'description'} = $self->zilla->abstract;
	$params->{'website'} = $self->zilla->distmeta->{'resources'}{'homepage'};

	# construct the HTTP request!
	my $http = HTTP::Tiny->new;
	$headers->{'authorization'} = "Basic " . MIME::Base64::encode_base64("$login:$pass", '');
	$headers->{'content-type'} = "application/json";

	# We use the v1.0 API to update
	my $url = 'https://bitbucket.org/api/1.0/repositories/' . $repo_name; # TODO encode the repo_name?
	$self->log( "Updating Bitbucket repository info" );
	my $response = $http->request( 'PUT', $url, {
		content => encode_json( $params ),
		headers => $headers
	});

	if ( ! $response->{'success'} ) {
		$self->log( ["Error: HTTP status(%s) when trying to POST => %s", $response->{'status'}, $response->{'reason'} ] );
		return;
	}

	my $r = decode_json( $response->{'content'} );
	if ( ! $r ) {
		$self->log( "ERROR: Malformed response content when trying to POST" );
		return;
	}
	if ( exists $r->{'error'} ) {
		$self->log( [ "Unable to update Bitbucket repository: %s", $r->{'error'} ] );
		return;
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=for Pod::Coverage after_release

=head1 NAME

Dist::Zilla::Plugin::Bitbucket::Update - Update a Bitbucket repo's info on release

=head1 VERSION

  This document describes v0.001 of Dist::Zilla::Plugin::Bitbucket::Update - released November 03, 2014 as part of Dist-Zilla-Plugin-Bitbucket.

=head1 DESCRIPTION

	# in your profile.ini in the MintingProvider's profile
	[Bitbucket::Update]

This L<Dist::Zilla> plugin updates the information of the Bitbucket repository
when C<dzil release> is run. As of now the following values will be updated:

The 'website' field will be set to the value present in the dist meta via "homepage"
(e.g. the one set by other plugins).

The 'description' field will be set to the value present in $zilla->abstract.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::Bitbucket|Dist::Zilla::Plugin::Bitbucket>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
