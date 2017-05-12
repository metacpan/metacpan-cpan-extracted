#
# This file is part of Dist-Zilla-Plugin-Test-Perl-Critic
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Perl::Critic;
# ABSTRACT: Tests to check your code against best practices
$Dist::Zilla::Plugin::Test::Perl::Critic::VERSION = '3.000';
use Moose;
use Moose::Util qw( get_all_attribute_values );

use Dist::Zilla::File::InMemory;
use Data::Section 0.004 -setup;

# and when the time comes, treat them like templates
with qw(
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::TextTemplate
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Perl::Critic - Tests to check your code against best practices

=head1 VERSION

version 3.000

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

=for Pod::Coverage gather_files

=head1 SEE ALSO

You can look for information on this module at:

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

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/critic.t ]___
#!perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

eval "use Test::Perl::Critic";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
Test::Perl::Critic->import( -profile => "{{ $critic_config }}" ) if -e "{{ $critic_config }}";
all_critic_ok();
