package Log::Contextual::Role::Router::WithLogger;
use strict;
use warnings;

our $VERSION = '0.009001';

use Moo::Role;

requires 'with_logger';

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt

=head1 NAME

Log::Contextual::Role::Router::WithLogger - Abstract interface between loggers and logging code blocks

=head1 VERSION

version 0.009001

=head1 REQUIRED METHODS

=over

=item with_logger

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Log-Contextual/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
