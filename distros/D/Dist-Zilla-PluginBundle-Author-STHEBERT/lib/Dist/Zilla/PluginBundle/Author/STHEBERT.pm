package Dist::Zilla::PluginBundle::Author::STHEBERT;

=head1 NAME

Dist::Zilla::PluginBundle::Author::STHEBERT - STHEBERT Dist Zilla plugin bundle

=head1 DESCRIPTION

This is the Dist Zilla plugin bundle that STHEBERT uses.

=cut

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $VERSION = '0.2';

=head1 METHODS

=head2 configure()

=cut

sub configure
{
    my $self = shift;

    $self->add_plugins(
        qw{
            RewriteVersion
            GatherDir
            MetaYAML
            PruneCruft

            MakeMaker
            Manifest

            License

            Readme

            MetaProvides::Package
            }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REPOSITORY

L<https://github.com/sebthebert/Dist-Zilla-PluginBundle-Author-STHEBERT>

=head1 AUTHOR

Sebastien Thebert <stt@onetool.pm>

=cut
