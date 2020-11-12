package Log::ger::UseDataDump;

our $DATE = '2020-06-06'; # DATE
our $VERSION = '0.004'; # VERSION

use Data::Dump ();
use Log::ger ();

$Log::ger::_dumper = \&Data::Dump::dump;


1;
# ABSTRACT: Use Data::Dump to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseDataDump - Use Data::Dump to dump data structures

=head1 VERSION

This document describes version 0.004 of Log::ger::UseDataDump (from Perl distribution Log-ger-UseDataDump), released on 2020-06-06.

=head1 SYNOPSIS

 use Log::ger::UseDataDump;

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseDataDump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseDataDump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseDataDump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Data::Dump>

Other modules to set data dumper for Log::ger:

=over

=item * L<Log::ger::UseDataBahe>

=item * L<Log::ger::UseDataDumpColor>

=item * L<Log::ger::UseDataDumpObjectAsString>

=item * L<Log::ger::UseDataDumpOptions>

=item * L<Log::ger::UseDataDumper>

=item * L<Log::ger::UseDataDumperCompact>

=item * L<Log::ger::UseDataPrinter>

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
