use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Perl::Critic; # git description: v3.001-16-ga4df0a2
# ABSTRACT: Tests to check your code against best practices
our $VERSION = '3.002';
use Moose;

use Moose::Util::TypeConstraints qw(
    role_type
);
use Dist::Zilla::File::InMemory;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use Data::Dumper ();
use namespace::autoclean;

# and when the time comes, treat them like templates
with qw(
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::TextTemplate
    Dist::Zilla::Role::PrereqSource
);

has filename => (
    is => 'ro',
    default => 'xt/author/critic.t',
);

has _file => (
    is => 'ro',
    isa => role_type('Dist::Zilla::Role::File'),
    lazy => 1,
    default => sub {
        my $self = shift;
        return Dist::Zilla::File::InMemory->new(
            name => $self->filename,
            content => ${$self->section_data('test-perl-critic')},
        );
    },
);

sub mvp_aliases { {
    profile => 'critic_config',
} }

has critic_config => (
    is      => 'ro',
    isa     => 'Str',
);

has verbose => (
    is => 'ro',
);

sub gather_files {
    my $self = shift;
    $self->add_file( $self->_file );
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

sub _dumper {
    my ($value) = @_;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Trailingcomma = 1;
    my $dump = Data::Dumper::Dumper($value);
    $dump =~ s{\n\z}{};
    return $dump;
}

sub munge_file {
    my $self = shift;
    my ($file) = @_;

    return
        unless $file == $self->_file;

    my $options = {};
    if (defined(my $verbose = $self->verbose)) {
        $options->{'-verbose'} = $verbose;
    }
    if (my $profile = $self->critic_config) {
        $options->{'-profile'} = $profile;
    }
    elsif (grep $_->name eq 'perlcritic.rc', @{ $self->zilla->files }) {
        $options->{'-profile'} = 'perlcritic.rc';
    }

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist    => \($self->zilla),
                plugin  => \$self,
                dumper  => \\&_dumper,
                options => \$options,
            }
        )
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
#pod =pod
#pod
#pod =for Pod::Coverage gather_files register_prereqs munge_file mvp_aliases
#pod
#pod =for stopwords LICENCE
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
#pod This will provide a F<xt/author/critic.t> file for use during the "test" and
#pod "release" calls of C<dzil>. To use this, make the changes to F<dist.ini>
#pod above and run one of the following:
#pod
#pod     dzil test
#pod     dzil release
#pod
#pod During these runs, F<xt/author/critic.t> will use L<Test::Perl::Critic> to run
#pod L<Perl::Critic> against your code and by report findings.
#pod
#pod =head1 OPTIONS
#pod
#pod =head2 filename
#pod
#pod The file name of the test to generate. Defaults to F<xt/author/critic.t>.
#pod
#pod =head2 critic_config
#pod
#pod This plugin accepts the C<critic_config> option, which s
#pod Specifies your own config file for L<Perl::Critic>. It defaults to
#pod C<perlcritic.rc>, relative to the project root. If the file does not exist,
#pod L<Perl::Critic> will use its defaults.
#pod
#pod The option can also be configured using the C<profile> alias.
#pod
#pod =head2 verbose
#pod
#pod If configured, overrides the C<-verbose> option to L<Perl::Critic>.
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Perl::Critic - Tests to check your code against best practices

=head1 VERSION

version 3.002

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Perl::Critic]
    critic_config = perlcritic.rc ; default / relative to project root

=head1 DESCRIPTION

This will provide a F<xt/author/critic.t> file for use during the "test" and
"release" calls of C<dzil>. To use this, make the changes to F<dist.ini>
above and run one of the following:

    dzil test
    dzil release

During these runs, F<xt/author/critic.t> will use L<Test::Perl::Critic> to run
L<Perl::Critic> against your code and by report findings.

=for Pod::Coverage gather_files register_prereqs munge_file mvp_aliases

=for stopwords LICENCE

=head1 OPTIONS

=head2 filename

The file name of the test to generate. Defaults to F<xt/author/critic.t>.

=head2 critic_config

This plugin accepts the C<critic_config> option, which s
Specifies your own config file for L<Perl::Critic>. It defaults to
C<perlcritic.rc>, relative to the project root. If the file does not exist,
L<Perl::Critic> will use its defaults.

The option can also be configured using the C<profile> alias.

=head2 verbose

If configured, overrides the C<-verbose> option to L<Perl::Critic>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Perl-Critic>
(or L<bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Jerome Quelin

=head1 CONTRIBUTORS

=for stopwords Jérôme Quelin Karen Etheridge Graham Knop Kent Fredric Olivier Mengué Gryphon Shafer Stephen R. Scaffidi Mike Doherty

=over 4

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Gryphon Shafer <gryphon@goldenguru.com>

=item *

Stephen R. Scaffidi <stephen@scaffidi.net>

=item *

Mike Doherty <doherty@cs.dal.ca>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ test-perl-critic ]___
#!perl

use strict;
use warnings;

use Test::Perl::Critic{{ %$options ? ' ' . $dumper->($options) : '' }};
all_critic_ok();
