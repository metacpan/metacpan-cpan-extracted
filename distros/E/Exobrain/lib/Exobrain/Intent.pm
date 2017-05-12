package Exobrain::Intent;

use Moose::Role;

with 'Exobrain::Message';

# ABSTRACT: Role for Exobrain intent packets
our $VERSION = '1.08'; # VERSION


1;

__END__

=pod

=head1 NAME

Exobrain::Intent - Role for Exobrain intent packets

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Currently this is a very thin wrapper over L<Exobrain::Message>, but
may contain more functionality in the future.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
