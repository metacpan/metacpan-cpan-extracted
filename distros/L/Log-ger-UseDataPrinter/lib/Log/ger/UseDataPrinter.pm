package Log::ger::UseDataPrinter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Log-ger-UseDataPrinter'; # DIST
our $VERSION = '0.002'; # VERSION

use Data::Printer ();
use Log::ger ();

$Log::ger::_dumper = sub { Data::Printer::np(@_, colored=>1) };

1;
# ABSTRACT: Use Data::Printer to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseDataPrinter - Use Data::Printer to dump data structures

=head1 VERSION

This document describes version 0.002 of Log::ger::UseDataPrinter (from Perl distribution Log-ger-UseDataPrinter), released on 2020-06-04.

=head1 SYNOPSIS

 use Log::ger::UseDataPrinter;

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseDataPrinter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseDataPrinter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseDataPrinter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Data::Printer>

Other modules to set data dumper for Log::ger: L<Log::ger::UseDataDump>,
L<Log::ger::UseDataDumpColor>, L<Log::ger::UseDataDumpObjectAsString>,
L<Log::ger::UseDataDumpOptions>, L<Log::ger::UseDataDumper>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
