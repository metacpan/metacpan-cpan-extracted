package Dist::Zilla::Plugin::CSJEWELL::FTPUploadToOwnSite;

use 5.008003;
use Moose;
use Net::Netrc;
use Net::FTP;
with 'Dist::Zilla::Role::Releaser';

our $VERSION = '0.900';
$VERSION =~ s/_//sm;

has site => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has directory => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has passive_ftp => (
	is      => 'ro',
	isa     => 'Int',
	default => 1,
);

has debug => (
	is      => 'ro',
	isa     => 'Int',
	default => 0,
);

sub release {
	my ( $self, $archive ) = @_;

	my $filename = $archive->stringify();
	my $site     = $self->site();
	my $siteinfo = Net::Netrc->lookup($site);
	if ( not $siteinfo ) {
		$self->log_fatal(
			"Could not get information for $site from .netrc.");
	}
	my ( $user, $password, undef ) = $siteinfo->lpa();

	my $ftp = Net::FTP->new(
		$site,
		Debug   => $self->debug(),
		Passive => $self->passive_ftp(),
	);

	$ftp->login( $user, $password )
	  or $self->log_fatal( 'Could not log in to ' . $site );

	$ftp->binary;

	$ftp->cwd( $self->directory() )
	  or $self->log_fatal(
		'Could not change remote site directory to' . $self->directory() );

	my $remote_file = $ftp->put($filename);

	if ( $remote_file ne $filename ) {
		$self->log_fatal( 'Could not upload file: ' . $ftp->message() );
	}

	my $remote_size = $ftp->size($remote_file);
	$remote_size ||= 0;
	my $local_size = -s $filename;

	if ( $remote_size != $local_size ) {
		$self->log( "Uploaded file is $remote_size bytes, "
			  . "but local file is $local_size bytes" );
	}

	$ftp->quit;

	$self->log( 'File uploaded to ' . $self->site() );

	return 1;
} ## end sub release

__PACKAGE__->meta()->make_immutable();
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::CSJEWELL::FTPUploadToOwnSite - Upload tarball to my own site

=head1 VERSION

This document describes Dist::Zilla::Plugin::CSJEWELL::FTPUploadToOwnSite version 0.900.

=head1 DESCRIPTION

	; in dzil.ini
	[CSJEWELL::FTPUploadToOwnSite]
	site        = ftp.geocities.invalid
	directory   = /Heartland/Meadows/3044
	passive_ftp = 1
	debug       = 0
	
	# in $HOME/.netrc
	machine ftp.geocities.invalid login csjewell password drowssap

=head1 INTERFACE

=head2 dzil.ini file

The dzil.ini file takes 4 parameters, two of which are required.

=head3 site

The FTP site to upload to.

=head3 directory

The directory on the FTP site to upload the tarball to.

=head3 passive_ftp

Whether to use passive FTP or not. Defaults to 1.

=head3 debug

Tells Net::FTP to print out its debug messages.  Defaults to 0.

=head2 .netrc file

The .netrc file is described in L<Net::Netrc|Net::Netrc> and should have an 
entry in it, matching the site given in the dzil.ini file, and specifying 
the username and password.

=for Pod::Coverage release

=head1 AUTHOR

Curtis Jewell <CSJewell@cpan.org>

=head1 SEE ALSO

L<Dist::Zilla::BeLike::CSJEWELL|Dist::Zilla::BeLike::CSJEWELL>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< CSJewell@cpan.org >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

