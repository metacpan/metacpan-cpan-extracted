package Dist::Zilla::Role::BuildRunner 6.009;
# ABSTRACT: something used as a delegating agent during 'dzil run'

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<build> method called during
#pod C<dzil run>.  It's passed the root directory of the build test dir.
#pod
#pod =head1 REQUIRED METHODS
#pod
#pod =head2 build
#pod
#pod This method will throw an exception on failure.
#pod
#pod =cut

requires 'build';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::BuildRunner - something used as a delegating agent during 'dzil run'

=head1 VERSION

version 6.009

=head1 DESCRIPTION

Plugins implementing this role have their C<build> method called during
C<dzil run>.  It's passed the root directory of the build test dir.

=head1 REQUIRED METHODS

=head2 build

This method will throw an exception on failure.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
