package Dist::Zilla::Role::Stash::Authors 6.014;
# ABSTRACT: a stash that provides a list of author strings

use Moose::Role;
with 'Dist::Zilla::Role::Stash';

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod An Authors stash must provide an C<authors> method that returns an arrayref of
#pod author strings, generally in the form "Name <email>".
#pod
#pod =cut

requires 'authors';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Stash::Authors - a stash that provides a list of author strings

=head1 VERSION

version 6.014

=head1 OVERVIEW

An Authors stash must provide an C<authors> method that returns an arrayref of
author strings, generally in the form "Name <email>".

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
