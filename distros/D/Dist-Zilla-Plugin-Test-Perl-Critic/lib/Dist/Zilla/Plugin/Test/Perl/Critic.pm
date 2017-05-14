use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Perl::Critic; # git description: v3.000-10-gfceb71d
# ABSTRACT: Tests to check your code against best practices
our $VERSION = '3.001';
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

has critic_config => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => 'perlcritic.rc',
);

sub gather_files {
    my ($self) = @_;

    my $data = $self->merged_section_data;
    return unless $data and %$data;

    my $stash = get_all_attribute_values( $self->meta, $self);
    $stash->{critic_config} ||= 'perlcritic.rc';

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

        # TODO also extract list of policies used in file $self->critic_config
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
#pod =pod
#pod
#pod =for Pod::Coverage gather_files register_prereqs
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [Test::Perl::Critic]
#pod     critic_config = perlcritic.rc ; default / relative to project root
#pod
#pod =head1 DESCRIPTION
#pod
#pod This will provide a F<t/author/critic.t> file for use during the "test" and
#pod "release" calls of C<dzil>. To use this, make the changes to F<dist.ini>
#pod above and run one of the following:
#pod
#pod     dzil test
#pod     dzil release
#pod
#pod During these runs, F<t/author/critic.t> will use L<Test::Perl::Critic> to run
#pod L<Perl::Critic> against your code and by report findings.
#pod
#pod This plugin accepts the C<critic_config> option, which specifies your own config
#pod file for L<Perl::Critic>. It defaults to C<perlcritic.rc>, relative to the
#pod project root. If the file does not exist, L<Perl::Critic> will use its defaults.
#pod
#pod This plugin is an extension of L<Dist::Zilla::Plugin::InlineFiles>.
#pod
#pod =head1 SEE ALSO
#pod
#pod You can look for information on this module at:
#pod
#pod =for stopwords AnnoCPAN
#pod
#pod =over 4
#pod
#pod =item * Search CPAN
#pod
#pod L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic>
#pod
#pod =item * See open / report bugs
#pod
#pod L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Test-Perl-Critic>
#pod
#pod =item * Mailing-list (same as L<Dist::Zilla>)
#pod
#pod L<http://www.listbox.com/subscribe/?list_id=139292>
#pod
#pod =item * Git repository
#pod
#pod L<http://github.com/jquelin/dist-zilla-plugin-test-perl-critic>
#pod
#pod =item * AnnoCPAN: Annotated CPAN documentation
#pod
#pod L<http://annocpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic>
#pod
#pod =item * CPAN Ratings
#pod
#pod L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Test-Perl-Critic>
#pod
#pod =back
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Perl::Critic - Tests to check your code against best practices

=head1 VERSION

version 3.001

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Perl::Critic]
    critic_config = perlcritic.rc ; default / relative to project root

=head1 DESCRIPTION

This will provide a F<t/author/critic.t> file for use during the "test" and
"release" calls of C<dzil>. To use this, make the changes to F<dist.ini>
above and run one of the following:

    dzil test
    dzil release

During these runs, F<t/author/critic.t> will use L<Test::Perl::Critic> to run
L<Perl::Critic> against your code and by report findings.

This plugin accepts the C<critic_config> option, which specifies your own config
file for L<Perl::Critic>. It defaults to C<perlcritic.rc>, relative to the
project root. If the file does not exist, L<Perl::Critic> will use its defaults.

This plugin is an extension of L<Dist::Zilla::Plugin::InlineFiles>.

=for Pod::Coverage gather_files register_prereqs

=head1 SEE ALSO

You can look for information on this module at:

=for stopwords AnnoCPAN

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Test-Perl-Critic>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-test-perl-critic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Test-Perl-Critic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Test-Perl-Critic>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Perl-Critic>
(or L<bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Jerome Quelin

=head1 CONTRIBUTORS

=for stopwords Jérôme Quelin Karen Etheridge Kent Fredric Olivier Mengué Stephen R. Scaffidi Gryphon Shafer Mike Doherty

=over 4

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Stephen R. Scaffidi <stephen@scaffidi.net>

=item *

Gryphon Shafer <gryphon@goldenguru.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/critic.t ]___
#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "{{ $critic_config }}") x!! -e "{{ $critic_config }}";
all_critic_ok();
