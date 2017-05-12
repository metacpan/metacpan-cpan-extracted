package Exobrain::Agent::Beeminder;
use Moose::Role;

our $VERSION = '1.06'; # VERSION
# ABSTRACT: Provide common functions for Beeminder agents.

with 'Exobrain::Agent';

sub component_name { "Beeminder" };

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Beeminder - Provide common functions for Beeminder agents.

=head1 VERSION

version 1.06

=for Pod::Coverage component_name

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
