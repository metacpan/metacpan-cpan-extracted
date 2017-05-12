package Dist::Zilla::Plugin::UploadToSFTP;

use 5.008;
use strict;
use warnings;
use utf8;

our $VERSION = '0.002';    # VERSION
use English '-no_match_vars';
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Bool Str);
use Net::Netrc;
use Net::SFTP::Foreign;
use Try::Tiny;
use namespace::autoclean;
with 'Dist::Zilla::Role::Releaser';

has [qw(site directory)] => ( ro, required, isa => Str );

has debug => ( ro, isa => Bool, default => 0 );

has _sftp => ( ro, lazy_build, isa => 'Net::SFTP::Foreign' );

sub _build__sftp {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    my %sftp_args = (
        host     => $self->site,
        user     => $self->login,
        password => $self->password,
        autodie  => 1,
    );
    if ( $self->debug ) { $sftp_args{more} = '-v' }

    my $sftp;
    try { $sftp = Net::SFTP::Foreign->new(%sftp_args) }
    catch { $self->log_fatal($ARG) };
    return $sftp;
}

has _netrc => ( ro, lazy_build,
    isa     => 'Net::Netrc',
    handles => [qw(login password)],
);

sub _build__netrc {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self  = shift;
    my $site  = $self->site;
    my $netrc = Net::Netrc->lookup($site)
        or
        $self->log_fatal("Could not get information for $site from .netrc.");
    return $netrc;
}

sub release {
    my ( $self, $archive ) = @ARG;
    my $sftp = $self->_sftp;

    try { $sftp->setcwd( $self->directory ) }
    catch { $self->log_fatal($ARG) };

    try { $sftp->put( ("$archive") x 2 ) } catch { $self->log_fatal($ARG) };

    my $remote_size = $sftp->stat("$archive")->size || 0;
    my $local_size = $archive->stat->size;
    if ( $remote_size != $local_size ) {
        $self->log( "Uploaded file is $remote_size bytes, "
                . "but local file is $local_size bytes" );
    }
    $self->log( "$archive uploaded to " . $self->site );

    return;
}

__PACKAGE__->meta->make_immutable();
1;

# ABSTRACT: Upload tarball to my own site

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders

=head1 NAME

Dist::Zilla::Plugin::UploadToSFTP - Upload tarball to my own site

=head1 VERSION

version 0.002

=head1 DESCRIPTION

    ; in dzil.ini
    [UploadToSFTP]
    site        = sftp.geocities.invalid
    directory   = /Heartland/Meadows/3044
    debug       = 0

    # in $HOME/.netrc
    machine sftp.geocities.invalid login mjgardner password drowssap

This is a L<Dist::Zilla::Role::Releaser|Dist::Zilla::Role::Releaser> plugin that
uploads a distribution tarball to an SFTP site.  It can be used in addition to
L<Dist::Zilla::Plugin::UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>
or in its place. In fact I wrote it for the latter case so that I could release
proprietary distributions inhouse.

=head2 F<.netrc> file

The F<.netrc> file is described in L<Net::Netrc|Net::Netrc> and should have an
entry in it matching the site given in the F<dzil.ini> file and specifying
the username and password.

=head1 ATTRIBUTES

=head2 site

The SFTP site to upload to.

=head2 directory

The directory on the SFTP site to upload the tarball to.

=head2 debug

Tells C<ssh> to run in verbose mode.  Defaults to C<0>.

=head1 METHODS

=head2 release

Uploads the tarball to the specified site and directory.

=head1 SEE ALSO

=over

=item L<Dist::Zilla|Dist::Zilla>

=item L<Dist::Zilla::Plugin::CSJEWELL::FTPUploadToOwnSite|Dist::Zilla::Plugin::CSJEWELL::FTPUploadToOwnSite>

The original inspiration for this module.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::UploadToSFTP

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-UploadToSFTP>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-UploadToSFTP>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-UploadToSFTP>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Dist-Zilla-Plugin-UploadToSFTP>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-UploadToSFTP>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-UploadToSFTP>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::UploadToSFTP>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Dist-Zilla-Plugin-UploadToSFTP/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Dist-Zilla-Plugin-UploadToSFTP>

  git clone git://github.com/mjgardner/Dist-Zilla-Plugin-UploadToSFTP.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
