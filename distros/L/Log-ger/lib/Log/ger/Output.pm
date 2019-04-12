package Log::ger::Output;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.026'; # VERSION

use parent 'Log::ger::Plugin';

# we only use one output, so set() should replace all hooks from previously set
# plugin package
sub _replace_package_regex { qr/\ALog::ger::Output::/ }

1;
# ABSTRACT: Set logging output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output - Set logging output

=head1 VERSION

version 0.026

=head1 SYNOPSIS

To set globally:

 use Log::ger::Output;
 Log::ger::Output->set(Screen => (
     use_color => 1,
     ...
 );

or:

 use Log::ger::Output 'Screen', (
     use_color=>1,
     ...
 );

To set for current package only:

 use Log::ger::Output;
 Log::ger::Output->set_for_current_package(Screen => (
     use_color => 1,
     ...
 );

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Format>

L<Log::ger::Layout>

L<Log::ger::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
