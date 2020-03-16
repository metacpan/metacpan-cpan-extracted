package GraphQL::Client::https;
# ABSTRACT: GraphQL over HTTPS

use warnings;
use strict;

use parent 'GraphQL::Client::http';

our $VERSION = '0.601'; # VERSION

sub new {
    my $class = shift;
    GraphQL::Client::http->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GraphQL::Client::https - GraphQL over HTTPS

=head1 VERSION

version 0.601

=head1 DESCRIPTION

This is the same as L<GraphQL::Client::http>.

=head1 SEE ALSO

L<GraphQL::Client::http>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/graphql-client/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
