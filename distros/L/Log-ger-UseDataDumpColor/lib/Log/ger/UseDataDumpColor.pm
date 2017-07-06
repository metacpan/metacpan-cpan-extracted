package Log::ger::UseDataDumpColor;

our $DATE = '2017-06-28'; # DATE
our $VERSION = '0.001'; # VERSION

use Data::Dump::Color ();
use Log::ger ();

$Log::ger::_dumper = \&Data::Dump::Color::dump;


1;
# ABSTRACT: Use Data::Dump::Color to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseDataDumpColor - Use Data::Dump::Color to dump data structures

=head1 VERSION

This document describes version 0.001 of Log::ger::UseDataDumpColor (from Perl distribution Log-ger-UseDataDumpColor), released on 2017-06-28.

=head1 SYNOPSIS

 use Log::ger::UseDataDumpColor;

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseDataDumpColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseDataDumpColor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseDataDumpColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Data::Dump::Color>

L<Log::ger::UseDataDump>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
