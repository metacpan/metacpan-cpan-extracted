package Dist::Zilla::Role::ReleaseStatusProvider 6.032;
# ABSTRACT: something that provides a release status for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role must provide a C<provide_release_status>
#pod method that will be called when setting the dist's version.
#pod
#pod If C<provides_release_status> returns undef, it will be ignored.
#pod
#pod =cut

requires 'provide_release_status';

1;

#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins implementing this role:
#pod L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ReleaseStatusProvider - something that provides a release status for the dist

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_release_status>
method that will be called when setting the dist's version.

If C<provides_release_status> returns undef, it will be ignored.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
