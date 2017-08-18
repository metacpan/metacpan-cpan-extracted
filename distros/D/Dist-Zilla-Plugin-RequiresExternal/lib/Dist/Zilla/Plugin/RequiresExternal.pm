package Dist::Zilla::Plugin::RequiresExternal;

# ABSTRACT: make dists require external commands

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '1.007';     # VERSION
use utf8;

#pod =for test_synopsis
#pod BEGIN { die "SKIP: this is ini, not perl\n" }
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [RequiresExternal]
#pod     requires = /path/to/some/executable
#pod     requires = executable_in_path
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Dist::Zilla|Dist::Zilla> plugin creates a test
#pod in your distribution to check for the existence of executable commands
#pod you require.
#pod
#pod =head1 SEE ALSO
#pod
#pod This module was indirectly inspired by
#pod L<Module::Install::External's requires_external_bin|Module::Install::External/requires_external_bin>
#pod command.
#pod
#pod =cut

use Moose;
use MooseX::Types::Moose qw(ArrayRef Bool Maybe Str);
use MooseX::AttributeShortcuts;
use Dist::Zilla::File::InMemory;
use List::MoreUtils 'part';
use Path::Class;
use namespace::autoclean;
with qw(
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::MetaProvider
    Dist::Zilla::Role::TextTemplate
);

#pod =for Pod::Coverage mvp_multivalue_args
#pod
#pod =cut

sub mvp_multivalue_args { return 'requires' }

#pod =attr requires
#pod
#pod Each C<requires> attribute should be either an absolute path to an
#pod executable or the name of a command in the user's C<PATH> environment.
#pod Multiple C<requires> lines are allowed.
#pod
#pod Example from a F<dist.ini> file:
#pod
#pod     [RequiresExternal]
#pod     requires = sqlplus
#pod     requires = /usr/bin/java
#pod
#pod This will require the program C<sqlplus> to be available somewhere in
#pod the user's C<PATH> and the program C<java> specifically in F</usr/bin>.
#pod
#pod =cut

has _requires => (
    is       => 'lazy',
    isa      => Maybe [ ArrayRef [Str] ],
    init_arg => 'requires',
    default => sub { [] },
);

#pod =attr fatal
#pod
#pod Boolean value to determine if a failed test will immediately stop
#pod testing. It also causes the test name to change to
#pod F<t/000-requires_external.t> so that it runs earlier.
#pod Defaults to false.
#pod
#pod =cut

has fatal => ( is => 'ro', required => 1, isa => Maybe [Bool], default => 0 );

#pod =method gather_files
#pod
#pod Adds a F<t/requires_external.t> test script to your distribution that
#pod checks if each L</requires> item is executable.
#pod
#pod =cut

sub gather_files {
    my $self = shift;

    # @{$requires[0]} will contain any non-absolute paths to look for in $PATH
    # @{$requires[1]} will contain any absolute paths
    my @requires = part { file($_)->is_absolute() } @{ $self->_requires };
    my $template = <<'END_TEMPLATE';
#!/usr/bin/env perl

use Test::Most;
plan tests => {{
    $OUT = 0;
    $OUT += @{ $requires[0] } if defined $requires[0];
    $OUT += @{ $requires[1] } if defined $requires[1];
}};
bail_on_fail if {{ $fatal }};
use Env::Path 0.18 'PATH';

{{ "ok(scalar PATH->Whence(\$_), \"\$_ in PATH\") for qw(@{ $requires[0] });"
        if defined $requires[0]; }}
{{ "ok(-x \$_, \"\$_ is executable\") for qw(@{ $requires[1] });"
        if defined $requires[1]; }}
END_TEMPLATE

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name => (
                $self->fatal
                ? 't/000-requires_external.t'
                : 't/requires_external.t',
            ),
            content => $self->fill_in_string(
                $template, { fatal => $self->fatal, requires => \@requires },
            ),
        ),
    );
    return;
}

#pod =method metadata
#pod
#pod Using this plugin will add L<Test::Most|Test::Most>
#pod and L<Env::Path|Env::Path> to your distribution's
#pod testing prerequisites since the generated script uses those modules.
#pod
#pod =cut

sub metadata {
    return {
        prereqs => {
            test => {
                requires => { 'Test::Most' => '0', 'Env::Path' => '0.18' },
            },
        },
    };
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

__END__

=pod

=encoding utf8

=for :stopwords Mark Gardner Joenio Costa GSI Commerce and cpan testmatrix url annocpan
anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan

=head1 NAME

Dist::Zilla::Plugin::RequiresExternal - make dists require external commands

=head1 VERSION

version 1.007

=for test_synopsis BEGIN { die "SKIP: this is ini, not perl\n" }

=head1 SYNOPSIS

In your F<dist.ini>:

    [RequiresExternal]
    requires = /path/to/some/executable
    requires = executable_in_path

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> plugin creates a test
in your distribution to check for the existence of executable commands
you require.

=head1 ATTRIBUTES

=head2 requires

Each C<requires> attribute should be either an absolute path to an
executable or the name of a command in the user's C<PATH> environment.
Multiple C<requires> lines are allowed.

Example from a F<dist.ini> file:

    [RequiresExternal]
    requires = sqlplus
    requires = /usr/bin/java

This will require the program C<sqlplus> to be available somewhere in
the user's C<PATH> and the program C<java> specifically in F</usr/bin>.

=head2 fatal

Boolean value to determine if a failed test will immediately stop
testing. It also causes the test name to change to
F<t/000-requires_external.t> so that it runs earlier.
Defaults to false.

=head1 METHODS

=head2 gather_files

Adds a F<t/requires_external.t> test script to your distribution that
checks if each L</requires> item is executable.

=head2 metadata

Using this plugin will add L<Test::Most|Test::Most>
and L<Env::Path|Env::Path> to your distribution's
testing prerequisites since the generated script uses those modules.

=head1 SEE ALSO

This module was indirectly inspired by
L<Module::Install::External's requires_external_bin|Module::Install::External/requires_external_bin>
command.

=for Pod::Coverage mvp_multivalue_args

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::RequiresExternal

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-RequiresExternal>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::RequiresExternal>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal>

  git clone git://github.com/mjgardner/Dist-Zilla-Plugin-RequiresExternal.git

=head1 AUTHORS

=over 4

=item *

Mark Gardner <mjgardner@cpan.org>

=item *

Joenio Costa <joenio@joenio.me>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by GSI Commerce and Joenio Costa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
