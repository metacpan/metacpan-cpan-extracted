package Dist::Zilla::PluginBundle::Classic 6.014;
# ABSTRACT: the classic (old) default configuration for Dist::Zilla

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use namespace::autoclean;

sub configure {
  my ($self) = @_;

  $self->add_plugins(qw(
    GatherDir
    PruneCruft
    ManifestSkip
    MetaYAML
    License
    Readme
    PkgVersion
    PodVersion
    PodCoverageTests
    PodSyntaxTests
    ExtraTests
    ExecDir
    ShareDir

    MakeMaker
    Manifest

    ConfirmRelease
    UploadToCPAN
  ));
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 DESCRIPTION
#pod
#pod This bundle is more or less the original configuration bundled with
#pod Dist::Zilla.  More than likely, you'd rather be using
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic> or a more complex bundle.  This one
#pod will muck around with your code by adding C<$VERSION> declarations and will
#pod mess with you Pod by adding a C<=head1 VERSION> section, but it won't get you a
#pod lot of more useful features like autoversioning, autoprereqs, or Pod::Weaver.
#pod
#pod It includes the following plugins with their default configuration:
#pod
#pod =for :list
#pod * L<Dist::Zilla::Plugin::GatherDir>
#pod * L<Dist::Zilla::Plugin::PruneCruft>
#pod * L<Dist::Zilla::Plugin::ManifestSkip>
#pod * L<Dist::Zilla::Plugin::MetaYAML>
#pod * L<Dist::Zilla::Plugin::License>
#pod * L<Dist::Zilla::Plugin::Readme>
#pod * L<Dist::Zilla::Plugin::PkgVersion>
#pod * L<Dist::Zilla::Plugin::PodVersion>
#pod * L<Dist::Zilla::Plugin::PodCoverageTests>
#pod * L<Dist::Zilla::Plugin::PodSyntaxTests>
#pod * L<Dist::Zilla::Plugin::ExtraTests>
#pod * L<Dist::Zilla::Plugin::ExecDir>
#pod * L<Dist::Zilla::Plugin::ShareDir>
#pod * L<Dist::Zilla::Plugin::MakeMaker>
#pod * L<Dist::Zilla::Plugin::Manifest>
#pod * L<Dist::Zilla::Plugin::ConfirmRelease>
#pod * L<Dist::Zilla::Plugin::UploadToCPAN>
#pod
#pod =head1 SEE ALSO
#pod
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Classic - the classic (old) default configuration for Dist::Zilla

=head1 VERSION

version 6.014

=head1 DESCRIPTION

This bundle is more or less the original configuration bundled with
Dist::Zilla.  More than likely, you'd rather be using
L<@Basic|Dist::Zilla::PluginBundle::Basic> or a more complex bundle.  This one
will muck around with your code by adding C<$VERSION> declarations and will
mess with you Pod by adding a C<=head1 VERSION> section, but it won't get you a
lot of more useful features like autoversioning, autoprereqs, or Pod::Weaver.

It includes the following plugins with their default configuration:

=over 4

=item *

L<Dist::Zilla::Plugin::GatherDir>

=item *

L<Dist::Zilla::Plugin::PruneCruft>

=item *

L<Dist::Zilla::Plugin::ManifestSkip>

=item *

L<Dist::Zilla::Plugin::MetaYAML>

=item *

L<Dist::Zilla::Plugin::License>

=item *

L<Dist::Zilla::Plugin::Readme>

=item *

L<Dist::Zilla::Plugin::PkgVersion>

=item *

L<Dist::Zilla::Plugin::PodVersion>

=item *

L<Dist::Zilla::Plugin::PodCoverageTests>

=item *

L<Dist::Zilla::Plugin::PodSyntaxTests>

=item *

L<Dist::Zilla::Plugin::ExtraTests>

=item *

L<Dist::Zilla::Plugin::ExecDir>

=item *

L<Dist::Zilla::Plugin::ShareDir>

=item *

L<Dist::Zilla::Plugin::MakeMaker>

=item *

L<Dist::Zilla::Plugin::Manifest>

=item *

L<Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN>

=back

=head1 SEE ALSO

L<@Basic|Dist::Zilla::PluginBundle::Basic>

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
