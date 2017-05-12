package Dist::Zilla::Plugin::CSJEWELL::SubversionDist;

use 5.008003;
use Moose;
with 'Dist::Zilla::Role::Releaser';

our $VERSION = '0.900';
$VERSION =~ s/_//sm;

has directory => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'DZ::Plugin::CSJEWELL::SubversionDist',
);

has debug => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0,
);

sub release {
	my ( $self, $archive ) = @_;

	my $filename    = $archive->stringify();
	my $remote_file = $self->directory() . $filename;
	my $bot_name    = $self->name();
	my ( $release, $version ) =
	  $filename =~ m/([\w-]+)-([\d_.]+)(?:-TRIAL)?.tar.gz/msx;
	$release    =~ s/-/::/gms;
	my $message = "[$bot_name] Importing upload file for $release $version";

	my $command = qq(svn import $filename $remote_file -m "$message" 2>&1);
	if ( $self->debug() ) {
		$self->log($command);
	} else {
		my $i = system $command;
	}

	$self->log('Release file committed to SVN.');

	return 1;
} ## end sub release

__PACKAGE__->meta()->make_immutable();
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::CSJEWELL::SubversionDist - Upload tarball to a Subversion repository

=head1 VERSION

This document describes Dist::Zilla::Plugin::CSJEWELL::SubversionDist version 0.900.

=head1 DESCRIPTION

	; in dzil.ini
	[CSJEWELL::SubversionDist]
	directory    = http://svn.ali.as/cpan/release/
	fake_release = 0
	name         = DZ

=head1 INTERFACE

=head2 dzil.ini file

The dzil.ini file takes 3 parameters, one of which is required.

=head3 directory

The location in the Subversion repository to upload to.

=head3 directory

The directory on the FTP site to upload the tarball to.

=head3 name

The name appended to the commit message. Defaults to C<DZ::Plugin::CSJEWELL::SubversionDist>.

=head3 debug

Whether to just log the command line rather than executing it.  Defaults to 0.

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

