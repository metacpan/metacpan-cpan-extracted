package Dist::Zilla::PluginBundle::CSJEWELL;

use 5.008003;
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $VERSION = '0.900';
$VERSION =~ s/_//sm;

has fake_release => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
		exists $_[0]->payload->{fake_release}
		  ? $_[0]->payload->{fake_release}
		  : 1;
	},
);

sub configure {
	my ($self) = @_;

	my @plugins = qw(
	  CSJEWELL::BeforeBuild
	  GatherDir
	  ManifestSkip
	  CSJEWELL::VersionGetter
	  CSJEWELL::AuthorTest

	  TestRelease
	  ConfirmRelease
	);

	push @plugins,
	  ( $self->fake_release() ? 'FakeRelease' : 'UploadToCPAN' );

	$self->add_plugins(@plugins);

	return $self;
} ## end sub configure

__PACKAGE__->meta()->make_immutable();
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::CSJEWELL - CSJEWELL's basic plugins to maintain and release CPAN dists

=head1 VERSION

This document describes Dist::Zilla::PluginBundle::CSJEWELL version 0.900.

=head1 DESCRIPTION

This is meant to be a usable plugin bundle for those of us that want to check 
in everything, and have what is checked in be released, other than what can 
be generated from what IS checked in at 'Build dist' or 'dzil build' time, 
and that both of those generate an identical tarball.

The goal is that no plugin that creates or modifies a .pm, .pod, or .t file 
'on the fly' is in here.

It includes the following plugins with their default configuration:

=over 4

=item *

L<Dist::Zilla::Plugin::CSJEWELL::BeforeBuild|Dist::Zilla::Plugin::CSJEWELL::BeforeBuild>

=item *

L<Dist::Zilla::Plugin::GatherDir|Dist::Zilla::Plugin::GatherDir>

=item *

L<Dist::Zilla::Plugin::ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>

=item *

L<Dist::Zilla::Plugin::CSJEWELL::VersionGetter|Dist::Zilla::Plugin::CSJEWELL::VersionGetter>

=item *

L<Dist::Zilla::Plugin::TestRelease|Dist::Zilla::Plugin::TestRelease>

=item *

L<Dist::Zilla::Plugin::ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> *

=item *

L<Dist::Zilla::Plugin::FakeRelease|Dist::Zilla::Plugin::FakeRelease> *

=back

* Note that the choice of which the last two is given by a "fake_release" 
option to the plugin bundle, which must exist and be 0 to use UploadToCPAN.

=for Pod::Coverage configure

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



