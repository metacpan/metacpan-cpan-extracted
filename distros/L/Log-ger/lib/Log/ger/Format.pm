## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Format;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-10'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.040'; # VERSION

use parent qw(Log::ger::Plugin);

sub _import_sets_for_current_package { 1 }

1;
# ABSTRACT: Use a format plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format - Use a format plugin

=head1 VERSION

version 0.040

=head1 SYNOPSIS

To set for current package only:

 use Log::ger::Format 'Block';

or:

 use Log::ger::Format;
 Log::ger::Format->set_for_current_package('Block');

To set globally:

 use Log::ger::Format;
 Log::ger::Format->set('Block');

=head1 DESCRIPTION

Note: Since format plugins affect log-producing code, the import syntax defaults
to setting for current package instead of globally.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Layout>

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Filter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
