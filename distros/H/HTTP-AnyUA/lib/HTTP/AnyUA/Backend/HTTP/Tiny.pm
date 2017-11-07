package HTTP::AnyUA::Backend::HTTP::Tiny;
# ABSTRACT: A unified programming interface for HTTP::Tiny


use warnings;
use strict;

our $VERSION = '0.901'; # VERSION

use parent 'HTTP::AnyUA::Backend';


sub request {
    my $self = shift;

    return $self->ua->request(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Backend::HTTP::Tiny - A unified programming interface for HTTP::Tiny

=head1 VERSION

version 0.901

=head1 DESCRIPTION

This module adds support for the HTTP client L<HTTP::Tiny> to be used with the unified programming
interface provided by L<HTTP::AnyUA>.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::AnyUA::Backend>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/HTTP-AnyUA/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
