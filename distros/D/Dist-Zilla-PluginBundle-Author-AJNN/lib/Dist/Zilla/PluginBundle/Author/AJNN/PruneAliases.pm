use 5.026;
use warnings;

package Dist::Zilla::PluginBundle::Author::AJNN::PruneAliases;
# ABSTRACT: Prune macOS aliases
$Dist::Zilla::PluginBundle::Author::AJNN::PruneAliases::VERSION = '0.02';

use Dist::Zilla;
use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::FilePruner';


sub prune_files {
	my ($self) = @_;
	
	my @aliases = grep { $self->_is_alias($_) } $self->zilla->files->@*;
	$self->zilla->prune_file($_) for @aliases;
}


sub _is_alias {
	my ($self, $file) = @_;
	
	# Try to read macOS alias magic number
	open my $fh, '<:raw', $file->name or return;
	my $data;
	my $success = read $fh, $data, 16;
	close $fh;
	$success or return;
	return 1 if $data eq "book\0\0\0\0mark\0\0\0\0";
	
	return;
};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::AJNN::PruneAliases - Prune macOS aliases

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This plugin prunes all macOS alias files.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::AJNN>

L<Dist::Zilla::Plugin::PruneCruft>

L<https://en.wikipedia.org/wiki/Alias_(Mac_OS)>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
