use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Path;

class Getopt::Pad::Type::File :isa(Getopt::Pad::Type::Path) :strict(params) {
	use constant NAMES => ['file'];
	use File::Basename ();
	use File::Path     ();

	our $VERSION = '0.04';

	method label() { return 'File Path' }

	method kind() { return 'file' }

	method completes() { return 'files' }

	method pathExists($value) { return -f $value }

	# The parent directories are created along with the empty file.
	method createPath($value) {
		File::Path::make_path(File::Basename::dirname($value), { error => \my $errors });
		if ($errors->@*) {
			my ($path, $reason) = $errors->[0]->%*;
			return $reason;
		}
		open my $handle, '>>', $value or return "$!";
		close $handle;
		return undef;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::File - The file option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        input  => { type => 'file', mustExist => 1 },
        output => { type => 'file', createPathIfMissing => 1 },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'file' >>. It
accepts any path and returns it as given; a leading C<~> is not expanded.

=over 4

=item * With C<mustExist>, the path must be an existing file (C<-f>); a
missing path or a directory is rejected with C<file 'PATH' does not
exist>.

=item * With C<createPathIfMissing>, a missing file is created empty,
together with its missing parent directories, for the value that is
finally used. An existing file is not touched.

=back

The help output labels the option C<[File Path]>, and shell completion
completes file names. See L<Getopt::Pad/file> and
L<Getopt::Pad/Type-specific keys>.

=head1 SEE ALSO

L<Getopt::Pad::Type::Dir>, L<Getopt::Pad::Type::Path>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
