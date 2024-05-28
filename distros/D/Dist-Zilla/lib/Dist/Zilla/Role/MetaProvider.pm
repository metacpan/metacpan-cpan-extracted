package Dist::Zilla::Role::MetaProvider 6.032;
# ABSTRACT: something that provides metadata (for META.yml/json)

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role provides data to merge into the distribution metadata.
#pod
#pod =method metadata
#pod
#pod This method (which must be provided by classes implementing this role)
#pod returns a hashref of data to be (deeply) merged together with pre-existing
#pod metadata.
#pod
#pod =cut

requires 'metadata';

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::MetaProvider - something that provides metadata (for META.yml/json)

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This role provides data to merge into the distribution metadata.

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

=head1 METHODS

=head2 metadata

This method (which must be provided by classes implementing this role)
returns a hashref of data to be (deeply) merged together with pre-existing
metadata.

=head1 SEE ALSO

Core Dist::Zilla plugins implementing this role:
L<ConfigMeta|Dist::Zilla::Plugin::ConfigMeta>.
L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>.

Dist::Zilla plugins on the CPAN:
L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>...

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins implementing this role:
#pod L<ConfigMeta|Dist::Zilla::Plugin::ConfigMeta>.
#pod L<MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>.
#pod
#pod Dist::Zilla plugins on the CPAN:
#pod L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>...
#pod
#pod =cut
