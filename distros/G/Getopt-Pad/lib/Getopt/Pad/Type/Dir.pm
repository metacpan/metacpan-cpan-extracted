use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Path;

class Getopt::Pad::Type::Dir :isa(Getopt::Pad::Type::Path) :strict(params) {
	use constant NAMES => ['dir', 'directory'];
	use File::Path ();

	our $VERSION = '0.05';

	method label() { return 'Path' }

	method kind() { return 'directory' }

	method completes() { return 'dirs' }

	method pathExists($value) { return -d $value }

	method createPath($value) {
		File::Path::make_path($value, { error => \my $errors });
		return undef if !$errors->@*;
		my ($path, $reason) = $errors->[0]->%*;
		return $reason;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Dir - The dir option type

=head1 SYNOPSIS

=for highlighter language=perl

    options => {
        'work-dir'  => { type => 'dir', mustExist => 1 },
        'cache-dir' => { type => 'dir', createPathIfMissing => 1 },
    },

=head1 DESCRIPTION

The type of options and args declared with C<< type => 'dir' >> or
C<'directory'>. It accepts any path and returns it as given; a leading C<~>
is not expanded.

=over 4

=item * With C<mustExist>, the path must be an existing directory
(C<-d>); anything else is rejected with C<directory 'PATH' does not
exist>.

=item * With C<createPathIfMissing>, a missing directory is created with
all missing parent directories, for the value that is finally used.

=back

The help output labels the option C<[Path]>, and shell completion
completes directory names. See L<Getopt::Pad/dir> and
L<Getopt::Pad/Type-specific keys>.

=head1 SEE ALSO

L<Getopt::Pad::Type::File>, L<Getopt::Pad::Type::Path>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
