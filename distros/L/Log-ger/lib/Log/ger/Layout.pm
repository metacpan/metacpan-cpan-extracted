package Log::ger::Layout;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.016'; # VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a layout plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout - Use a layout plugin

=head1 VERSION

version 0.016

=head1 SYNOPSIS

To set globally:

 use Log::ger::Layout;
 Log::ger::Format->set('Pattern');

or:

 use Log::ger::Layout 'Pattern';

To set for current package only:

 use Log::ger::Layout;
 Log::ger::Layout->set_for_current_package('Pattern');

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Format>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
