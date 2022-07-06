use 5.026;
use warnings;

package Dist::Zilla::Plugin::PruneAliases;
# ABSTRACT: Prune macOS aliases from your dist
$Dist::Zilla::Plugin::PruneAliases::VERSION = '1.00';

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
	read $fh, my $data, 16 or return;
	close $fh;
	return $data eq "book\0\0\0\0mark\0\0\0\0";
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PruneAliases - Prune macOS aliases from your dist

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 [PruneAliases]

=head1 DESCRIPTION

This tiny plugin prunes all macOS data fork alias files.
Works even on non-Mac operating systems.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::PruneCruft>

L<Mac::Alias>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
