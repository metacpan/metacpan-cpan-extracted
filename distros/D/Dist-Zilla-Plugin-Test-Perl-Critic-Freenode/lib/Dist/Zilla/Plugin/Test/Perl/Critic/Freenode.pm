use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Perl::Critic::Freenode;
# ABSTRACT: Tests to check your code against policies inspired by #perl on Freenode
$Dist::Zilla::Plugin::Test::Perl::Critic::Freenode::VERSION = '0.002';
use Moose;
use Moose::Util qw( get_all_attribute_values );

use Dist::Zilla::File::InMemory;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use namespace::autoclean;

# and when the time comes, treat them like templates
with qw(
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::TextTemplate
    Dist::Zilla::Role::PrereqSource
);

sub gather_files {
    my ($self) = @_;

    my $data = $self->merged_section_data;
    return unless $data and %$data;

    my $stash = get_all_attribute_values( $self->meta, $self);

    # NB: This code is a bit generalised really, and could be forked into its
    # own plugin.
    for my $name ( keys %$data ){
        my $template = ${$data->{$name}};
        $self->add_file( Dist::Zilla::File::InMemory->new({
            name => $name,
            content => $self->fill_in_string( $template, $stash )
        }));
    }
}

sub register_prereqs {
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Perl::Critic' => 0,
        'Perl::Critic::Freenode' => 0,

        # TODO also extract list of policies used in file $self->critic_config
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Perl::Critic::Freenode - Tests to check your code against policies inspired by #perl on Freenode

=head1 VERSION

version 0.002

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Perl::Critic::Freenode]

=head1 DESCRIPTION

This will provide a F<xt/author/critic-freenode.t> file for use during the
"test" and "release" calls of C<dzil>. To use this, make the changes to
F<dist.ini> above and run one of the following:

    dzil test
    dzil release

During these runs, F<xt/author/critic-freenode.t> will use
L<Test::Perl::Critic> to run L<Perl::Critic> against your code and report its
findings.

This plugin is an extension of L<Dist::Zilla::Plugin::InlineFiles>.

This plugin is a fork of L<Dist::Zilla::Plugin::Test::Perl::Critic>.

=for Pod::Coverage gather_files register_prereqs

=head1 SEE ALSO

You can look for information on this module at:

=for stopwords AnnoCPAN

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode>

=item * See open / report bugs

L<https://github.com/pink-mist/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode/issues>

=item * Git repository

L<https://github.com/pink-mist/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Test-Perl-Critic-Freenode>

=back

=head1 ORIGINAL AUTHOR

Original author of L<Dist::Zilla::Plugin::Test::Perl::Critic> is Jerome Quelin

=head1 AUTHOR

Andreas Guldstrand

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Andreas Guldstrand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/critic-freenode.t ]___
#!perl

use strict;
use warnings;

use Test::Perl::Critic (-theme => 'freenode', severity => 1);
all_critic_ok();
