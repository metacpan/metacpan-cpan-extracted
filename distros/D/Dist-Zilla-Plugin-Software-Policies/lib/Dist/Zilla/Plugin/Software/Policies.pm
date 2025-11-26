## no critic (ControlStructures::ProhibitPostfixControls)
package Dist::Zilla::Plugin::Software::Policies;

use strict;
use warnings;
use 5.010;
use feature qw( say );

# ABSTRACT: Create project policy files

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::Plugin';
use Dist::Zilla::Pragmas;
use namespace::autoclean;

has class => (
    is  => 'ro',
    isa => 'Str',
);

has version => (
    is  => 'ro',
    isa => 'Str',
);

has format => (
    is  => 'ro',
    isa => 'Str',
);

has policy_attribute => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has dir => (
    is  => 'ro',
    isa => 'Str',
);

has filename => (
    is  => 'ro',
    isa => 'Str',
);

sub mvp_multivalue_args { return qw( policy_attribute ) }

sub register_prereqs {
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Dist::Zilla::App::Command::policies' => 0,
    );

    return $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Software::Policies' => 0,
    );
}

# If there is no / Policy definition in [Software::Policies]
# Leave plugin_name Software::Policies

around BUILDARGS => sub {
    my ( $orig, $class, @arg ) = @_;
    my $args  = $class->$orig(@arg);
    my %copy  = %{$args};
    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};
    my %other;
    my %attributes = map { split qr/\s*=\s*/msx, $_, 2 } @{ delete $copy{policy_attribute} // [] };

    # $other{'class'} = delete $copy{class} if $copy{class};
    # $other{'version'} = delete $copy{version} if $copy{version};
    # $other{'format'} = delete $copy{format} if $copy{format};
    # $other{'dir'} = delete $copy{dir} if $copy{dir};
    # $other{'filename'} = delete $copy{filename} if $copy{filename};
    for my $key (qw( class version format dir filename )) {
        $other{$key} = delete $copy{$key} if $copy{$key};
    }
    $other{'policy_attribute'} = \%attributes;
    $zilla->log_debug( [ 'Policy %s. Collected attributes: %s', $name, \%attributes ] );
    if (%copy) {
        $zilla->log_fatal(
            [ 'Unknown configuration option(s) in %s: %s', ( __PACKAGE__ . q{ / } . $name ), ( join q{,}, keys %copy ) ] );
    }
    return {
        zilla       => $zilla,
        plugin_name => $name,

        # _prereq     => \%copy,
        %other,
    };
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Software::Policies - Create project policy files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=for Pod::Coverage mvp_multivalue_args register_prereqs

=for stopwords Dist

=head1 STATUS

Dist-Zilla-Plugin-Software-Policies is currently being developed so changes in the API are possible,
though not likely.

=for test_synopsis BEGIN { die "SKIP: skip this pod!\n"; }

    [Software::Policies / Contributing]
    class = PerlDistZilla

    [Software::Policies / CodeOfConduct]
    class = ContributorCovenant
    version = 2.1

    [Test::Software::Policies]
    include_policy = Contributing
    include_policy = CodeOfConduct
    include_policy = License
    include_policy = Security

=for stopwords GitLab

Dist-Zilla-Plugin-Software-Policies is a L<Dist::Zilla> command, plugin and test plugin
for creating different policy and related files
which are commonly present in repositories. Many of these are practically boilerplate
but it is good to have them present in the repository, especially if the repository
is public.

Examples are F<CONTRIBUTING.md>, F<CODE_OF_CONDUCT.md>, F<SECURITY.md>,
F<FUNDING.md>, F<SUPPORT.md> and F<LICENSE>.

The trouble with boilerplate files is that they are easy to forget.
You either forget to place them in the repository in the first place, or you forget to update them
when distribution changes.

One way to handle that problem is to create the files during the build and only
include them in the distribution archive. But that means they would not be present in the
repository itself which is more important nowadays because the repo is public.
In GitHub, GitLab and similar hosting services, the repository becomes the public
frontend of the project, not just a place of work and a heap of source code
from which a release is created.

Some public hosting sites, such as GitHub, place extra weight on these files, and having
them is seen as an indicator of project health and of being welcoming community engagement.
GitHub allows searching for projects with different parameters and it provides a special
interface for files which contain license, code of conduct, contribution guidelines
and support contact information. To increase the visibility of the project,
and make it easier for others to find it,
it is important to have these files present - even when they provide little benefit
for the actual users or developers of the repository.

With this package, creating and maintaining the files is quick and easy.

=head1 USAGE

To use Dist-Zilla-Plugin-Software-Policies, first add a test to your F<dist.ini>
file to ensure the wanted files are present and up-to-date when you run
C<dzil test> or C<dzil release>.

    [Test::Software::Policies]
    include_policy = Contributing
    include_policy = CodeOfConduct
    include_policy = License
    include_policy = Security

Use B<include_policy> configuration item as many times as you need to specify
the wanted policy files, or leave it out completely to test for all
available (installed) policies.

The package L<Software::Policies> is a framework which is easy to expand
to accommodate for future policy files.

The policy files are created from the distribution metadata present
in F<dist.ini> file. If you need to change the default values
for things like distribution name, contact information or supported Perl versions,
you need to set individual configuration for that policy:

    [Software::Policies / Contributing]
    class = PerlDistZilla

    [Software::Policies / CodeOfConduct]
    class = ContributorCovenant
    version = 2.1

    [Software::Policies / License]
    use_double_license_for_perl5 = false
    format = text

    [Software::Policies / Security]
    policy_attribute = maintainer=Policies Team <policies.team@example.com
    policy_attribute = report_url=https://github.com/mikkoi/software-policies/security/advisories

The plugin L<Dist::Zilla::Plugin::Software::Policies> does not actually do anything,
except verify the configuration is correct.
The configuration is used by L<Dist::Zilla::Plugin::Test::Software::Policies>
when creating the test files during the I<build> phase.
By default the tests are placed in F<xt/author>
directory, e.g. F<xt/author/policy_Contributing.t>

The configuration is also used by the command C<dzil policies>.
Run the command when you need to create or update the policy files, for example,
if the tests have failed.

    # usage: dzil policies [<policy>] [--class] [--class-version] [--format]
    dzil policies Contributing
    # or, to create all policies
    dzil policies

During the I<build> phase, when L<Dist::Zilla::Plugin::Test::Software::Policies>
prepares the test files, it runs the policy generation in L<Software::Policies>
and embeds the result into the equivalent test file. During I<test> phase
this is compared with the existing file.

=head1 ATTRIBUTES

=head2 class

Same policy can take many forms. These are called classes.

=head2 version

Internal version of the class.

=head2 format

The format of the document when it is generated.
Mostly markdown but in some cases, for example licenses, is text.

=head2 policy_attribute

Attributes that are policy or class specific.

=for stopwords dir

=head2 dir

The directory name for the resulting file(s).
Default: project root.

Usually policy files are at the root of the repository
but lately GitHub has allowed other location where they are
detected automatically, F<.github> and F<docs> directories.

Please see L<Creating a default community health file|https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file>.

=head2 filename

=for stopwords GPL

The file name of the resulting file.
This is only useful when the policy is written as only one file.
This is usually the case but there are exceptions, for example
when license is written as two different license files
(e.g. Perl_5 license is actually two alternative licenses: GPL and Artistic).

Policies have individual default filenames, see L<Software::Policies>.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
