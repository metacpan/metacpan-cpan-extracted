use v5.26;
use Object::Pad;

class Getopt::Pad::ExitRequest {
	our $VERSION = '0.04';

	field $output :param :reader;
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::ExitRequest - The exception that ends a parse successfully
(internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

Every trigger of an automatic option (C<--help>, C<--version>,
C<--create-completions>, C<--create-default-config>) throws an
ExitRequest once it has done its work. It carries the finished output,
final newline included. C<GetOptions> prints the output to STDOUT as it
is and exits with status 0, without knowing which option asked for it.

=head1 METHODS

=over 4

=item output

The text to print.

=back

=head1 SEE ALSO

L<Getopt::Pad::Spec>, L<Getopt::Pad::Error>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
