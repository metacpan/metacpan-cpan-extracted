## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-10'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.040'; # VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a filter plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Filter - Use a filter plugin

=head1 VERSION

version 0.040

=head1 SYNOPSIS

To set globally:

 use Log::ger::Filter;
 Log::ger::Filter->set('Code', code => sub{ ... });

or:

 use Log::ger::Filter 'Code', (code => sub { ... });

To set for current package only:

 use Log::ger::Filter;
 Log::ger::Filter->set_for_current_package('Code', code => sub { ... });

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Format>

L<Log::ger::Layout>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
