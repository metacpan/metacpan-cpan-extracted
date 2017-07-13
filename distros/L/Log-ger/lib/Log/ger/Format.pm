package Log::ger::Format;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.016'; # VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a format plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format - Use a format plugin

=head1 VERSION

version 0.016

=head1 SYNOPSIS

To set globally:

 use Log::ger::Format;
 Log::ger::Format->set('Block');

or:

 use Log::ger::Format 'Block';

To set for current package only:

 use Log::ger::Format;
 Log::ger::Format->set_for_current_package('Block');

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Layout>

L<Log::ger::Output>

L<Log::ger::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
