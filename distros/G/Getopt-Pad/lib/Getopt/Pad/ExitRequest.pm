use v5.26;
use Object::Pad;

class Getopt::Pad::ExitRequest {
	our $VERSION = '0.02';

	field $output :param :reader;
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::ExitRequest - control-flow exception ending a parse successfully

=head1 DESCRIPTION

Control-flow exception thrown by every trigger (--help, --version,
--create-completions, --create-default-config) once it has done its work. It carries the finished
output, newline included, and GetOptions prints it to STDOUT verbatim and
exits 0 without needing to know which trigger fired.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
