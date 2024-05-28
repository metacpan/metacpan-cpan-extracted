package Dist::Zilla::PluginBundle::Basic 6.032;
# ABSTRACT: the basic plugins to maintain and release CPAN dists

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::Pragmas;

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
    ExtraTests
    ExecDir
    ShareDir

    MakeMaker
    Manifest

    TestRelease
    ConfirmRelease
    UploadToCPAN
  ));
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 DESCRIPTION
#pod
#pod This plugin is meant to be a basic "first step" bundle for using Dist::Zilla.
#pod It won't munge any of your code, but will generate a F<Makefile.PL> and allows
#pod easy, reliable releasing of distributions.
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
#pod * L<Dist::Zilla::Plugin::ExtraTests>
#pod * L<Dist::Zilla::Plugin::ExecDir>
#pod * L<Dist::Zilla::Plugin::ShareDir>
#pod * L<Dist::Zilla::Plugin::MakeMaker>
#pod * L<Dist::Zilla::Plugin::Manifest>
#pod * L<Dist::Zilla::Plugin::TestRelease>
#pod * L<Dist::Zilla::Plugin::ConfirmRelease>
#pod * L<Dist::Zilla::Plugin::UploadToCPAN>
#pod
#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins: L<@Filter|Dist::Zilla::PluginBundle::Filter>.
#pod
#pod Dist::Zilla roles:
#pod L<PluginBundle|Dist::Zilla::Role::PluginBundle>,
#pod L<PluginBundle::Easy|Dist::Zilla::Role::PluginBundle::Easy>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Basic - the basic plugins to maintain and release CPAN dists

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin is meant to be a basic "first step" bundle for using Dist::Zilla.
It won't munge any of your code, but will generate a F<Makefile.PL> and allows
easy, reliable releasing of distributions.

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

L<Dist::Zilla::Plugin::TestRelease>

=item *

L<Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN>

=back

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

Core Dist::Zilla plugins: L<@Filter|Dist::Zilla::PluginBundle::Filter>.

Dist::Zilla roles:
L<PluginBundle|Dist::Zilla::Role::PluginBundle>,
L<PluginBundle::Easy|Dist::Zilla::Role::PluginBundle::Easy>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
