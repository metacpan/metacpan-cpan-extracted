package Exobrain::Component;
use Moose::Role;

# ABSTRACT: Role used for component definitions.
our $VERSION = '1.08'; # VERSION

requires qw(component services);

1;

__END__

=pod

=head1 NAME

Exobrain::Component - Role used for component definitions.

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
