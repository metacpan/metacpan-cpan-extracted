package Dist::Zilla::Role::LicenseProvider 6.012;
# ABSTRACT: something that provides a license for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role must provide a C<provide_license> method that
#pod will be called when setting the dist's license.
#pod
#pod If a LicenseProvider offers a license but one has already been set, an
#pod exception will be raised.  If C<provides_license> returns undef, it will be
#pod ignored.
#pod
#pod =head1 REQUIRED METHODS
#pod
#pod =head2 C<< provide_license({ copyright_holder => $holder, copyright_year => $year }) >>
#pod
#pod Generate license object. Returned object should be an instance of
#pod L<Software::License>.
#pod
#pod Plugins are responsible for injecting C<$copyright_holder> and
#pod C<$copyright_year> arguments into the license if these arguments are defined.
#pod
#pod =cut

requires 'provide_license';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::LicenseProvider - something that provides a license for the dist

=head1 VERSION

version 6.012

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_license> method that
will be called when setting the dist's license.

If a LicenseProvider offers a license but one has already been set, an
exception will be raised.  If C<provides_license> returns undef, it will be
ignored.

=head1 REQUIRED METHODS

=head2 C<< provide_license({ copyright_holder => $holder, copyright_year => $year }) >>

Generate license object. Returned object should be an instance of
L<Software::License>.

Plugins are responsible for injecting C<$copyright_holder> and
C<$copyright_year> arguments into the license if these arguments are defined.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
