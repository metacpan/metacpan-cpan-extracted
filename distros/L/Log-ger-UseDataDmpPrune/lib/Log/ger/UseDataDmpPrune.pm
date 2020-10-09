package Log::ger::UseDataDmpPrune;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-04'; # DATE
our $DIST = 'Log-ger-UseDataDmpPrune'; # DIST
our $VERSION = '0.001'; # VERSION

use Data::Dmp::Prune ();
use Log::ger ();

$Log::ger::_dumper = \&Data::Dmp::Prune::dmp;


1;
# ABSTRACT: Use Data::Dmp::Prune to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseDataDmpPrune - Use Data::Dmp::Prune to dump data structures

=head1 VERSION

This document describes version 0.001 of Log::ger::UseDataDmpPrune (from Perl distribution Log-ger-UseDataDmpPrune), released on 2020-10-04.

=head1 SYNOPSIS

 use Log::ger::UseDataDmpPrune;

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseDataDmpPrune>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseDataDmpPrune>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseDataDmpPrune>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Data::Dmp::Prune>

Other modules to set data dumper for Log::ger, e.g. L<Log::ger::UseDataDump>,
etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
