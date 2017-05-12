package Dist::Zilla::Plugin::PodInherit;
# ABSTRACT: autogenerate inherited POD sections for Dist::Zilla distributions
use strict;
use warnings;
use Moose;
use Pod::Inherit;

our $VERSION = '0.007';

=head1 NAME

Dist::Zilla::Plugin::PodInherit - use L<Pod::Inherit> to provide C<INHERITED METHODS> sections in POD

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Just add [PodInherit] to dist.ini. Currently there's no config options at all.

=head1 DESCRIPTION

Simple wrapper around L<Pod::Inherit> to provide an 'inherited methods' section for
any modules in this distribution. See the documentation for L<Pod::Inherit> for more
details.

=cut

use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileInjector';
with 'Dist::Zilla::Role::FileFinderUser' => {
	default_finders => [ qw( :InstallModules ) ],
};

has generated => is => 'rw', default => 0;

=head1 METHODS

=cut

=head2 gather_files

Called for each matching file (using :InstallModules so we expect
to find all the .pm files), we'll attempt to do pod generation for
the ones which end in .pm (case insensitive, will also match .PM).

=cut

sub gather_files {
	my ($self) = @_;
	foreach my $file (@{ $self->found_files }) {
		$self->process_pod($file) if $file->name =~ /\.pm$/i;
	}
	$self->log("Generated " . $self->generated . " POD files");
}

=head2 process_pod

Calls L<Pod::Inherit> to generate the merged C<.pod> documentation files.

=cut

sub process_pod {
	my ($self, $file) = @_;
	unless(-r $file->name) {
		$self->log_debug("Skipping " . $file->name . " because we can't read it, probably InMemory/FromCode");
		return;
	}

	$self->log_debug("Processing " . $file->name . " for inherited methods");
	local @INC = ('lib/', @INC);
	my $cfg = Pod::Inherit->new({
		input_files => [$file->name],
		skip_underscored => 1,
		method_format => 'L<%m|%c/%m>',
		debug => 0,
	});
	my $content = $cfg->create_pod($file->name) or return;
	(my $output = $file->name) =~ s{\.pm$}{.pod}i;
	$self->add_file(
		my $new = Dist::Zilla::File::InMemory->new({
			name    => $output,
			content => $content,
		})
	);
	$self->log_debug("Generated POD for " . $file->name . " in " . $new->name);
	$self->generated($self->generated + 1);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 BUGS

Some of the path and extension handling may be non-portable, should probably
use L<File::Basename> and L<File::Spec>.

Also, generating an entire .pod output file which is identical apart from the
extra inherited methods section seems suboptimal, other plugins such as
L<Dist::Zilla::Plugin::PodVersion> manage to update the source .pm file
directly so perhaps that would be a better approach.

=head1 SEE ALSO

=over 4

=item * L<Pod::POM>

=item * L<Pod::Inherit>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
