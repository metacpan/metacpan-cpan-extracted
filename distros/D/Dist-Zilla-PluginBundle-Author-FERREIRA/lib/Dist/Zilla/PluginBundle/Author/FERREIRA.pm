
package Dist::Zilla::PluginBundle::Author::FERREIRA;
$Dist::Zilla::PluginBundle::Author::FERREIRA::VERSION = '0.4.0';
# ABSTRACT: Build a distribution like FERREIRA

use Moose;
use Dist::Zilla 6;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ($self) = @_;

    $self->add_bundle(
        '@Filter',
        {
            '-bundle'  => '@RJBS',
            '-version' => '5.010',
            '-remove'  => [ 'MakeMaker', 'MetaConfig', 'AutoPrereqs' ],
        }
    );

    $self->add_plugins('ModuleBuild');
    $self->add_plugins('MetaProvides::Package');
    $self->add_plugins(
        [ AutoPrereqs => { extra_scanners => [ 'Mojo', 'Jojo', 'Zim' ] } ] );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the L<Dist::Zilla> plugin bundle that FERREIRA uses.
#pod It is equivalent to:
#pod
#pod     [@Filter]
#pod     -bundle = @RJBS
#pod     -version = 5.010
#pod     -remove = MakeMaker
#pod     -remove = MetaConfig
#pod     -remove = AutoPrereqs
#pod
#pod     [ModuleBuild]
#pod     [MetaProvides::Package]
#pod     [AutoPrereqs]
#pod     extra_scanners = Mojo
#pod     extra_scanners = Jojo
#pod     extra_scanners = Zim
#pod
#pod =head1 ACKNOWLEDGMENTS
#pod
#pod RJBS for L<Dist::Zilla> and L<Dist:Zilla::PluginBundle::RJBS>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::FERREIRA - Build a distribution like FERREIRA

=head1 VERSION

version 0.4.0

=head1 DESCRIPTION

This is the L<Dist::Zilla> plugin bundle that FERREIRA uses.
It is equivalent to:

    [@Filter]
    -bundle = @RJBS
    -version = 5.010
    -remove = MakeMaker
    -remove = MetaConfig
    -remove = AutoPrereqs

    [ModuleBuild]
    [MetaProvides::Package]
    [AutoPrereqs]
    extra_scanners = Mojo
    extra_scanners = Jojo
    extra_scanners = Zim

=head1 ACKNOWLEDGMENTS

RJBS for L<Dist::Zilla> and L<Dist:Zilla::PluginBundle::RJBS>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
