package Dist::Zilla::Role::ReleaseStatusProvider 6.009;
# ABSTRACT: something that provides a release status for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

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

version 6.009

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_release_status>
method that will be called when setting the dist's version.

If C<provides_release_status> returns undef, it will be ignored.

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
