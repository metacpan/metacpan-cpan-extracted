package Dist::Zilla::PluginBundle::BioPerl;
$Dist::Zilla::PluginBundle::BioPerl::VERSION = '0.27';
use utf8;

# ABSTRACT: Build your distributions like Bioperl does
# AUTHOR:   Florian Ragwitz <rafl@debian.org>
# AUTHOR:   Sheena Scroggins
# AUTHOR:   Carnë Draug <carandraug+dev@gmail.com>
# AUTHOR:   Chris Fields <cjfields1@gmail.com>
# OWNER:    2010 Florian Ragwitz
# OWNER:    2011 Sheena Scroggins
# OWNER:    2013-2017 Carnë Draug
# LICENSE:  Perl_5

use Moose 1.00;
use MooseX::AttributeShortcuts;
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(ArrayRef Bool Str);
use namespace::autoclean;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::PluginRemover
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);



sub get_value {
    my ($self, $accessor) = @_;
    my %defaults = (
        'homepage'            => 'https://metacpan.org/release/%{dist}',
        'repository.github'   => 'user:bioperl',
        'bugtracker.github'   => 'user:bioperl',
        'bugtracker.mailto'   => 'bioperl-l@bioperl.org',
        'trailing_whitespace' => 1,
        'allow_dirty'         => ['Changes', 'dist.ini'],
    );
    return $self->payload->{$accessor} || $defaults{$accessor};
}

has homepage => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('homepage') }
);

has repository_github => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('repository.github') }
);

has bugtracker_github => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('bugtracker.github') }
);

has bugtracker_mailto => (
    is      => 'lazy',
    isa     => EmailAddress,
    default => sub { shift->get_value('bugtracker.mailto') }
);

has trailing_whitespace => (
    is      => 'lazy',
    isa     => Bool,
    default => sub { shift->get_value('trailing_whitespace') }
);


sub mvp_multivalue_args { qw( allow_dirty ) }
has allow_dirty => (
    is      => 'lazy',
    isa     => ArrayRef,
    default => sub { shift->get_value('allow_dirty') }
);


sub configure {
    my $self = shift;

    $self->add_bundle('@Filter' => {
        '-bundle' => '@Basic',
        '-remove' => ['Readme'],
    });

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
        Test::NoTabs
        Test::Compile
        PodCoverageTests
        MojibakeTests
        AutoPrereqs
    ));

    my @allow_dirty;
    foreach (@{$self->allow_dirty}) {
        push (@allow_dirty, 'allow_dirty', $_);
    }

    $self->add_plugins(
        [AutoMetaResources => [
            'repository.github' => $self->repository_github,
            'homepage'          => $self->homepage,
            'bugtracker.github' => $self->bugtracker_github,
        ]],
        [MetaResources => [
            'bugtracker.mailto' => $self->bugtracker_mailto,
        ]],
        ['Test::EOL' => {
            trailing_whitespace => $self->trailing_whitespace,
        }],
        [Encoding => [
             'encoding' => 'bytes',
             'match' => '^t/data/',
        ]],
        [PodWeaver => {
            config_plugin => '@BioPerl',
        }],
    );

    $self->add_plugins(qw(
        NextRelease
    ));

    $self->add_plugins(
        ['Git::Check' => [
            @allow_dirty,
        ]],
        ['Git::Commit' => [
            @allow_dirty,
        ]],
        ['Git::Tag' => [
            tag_format  => '%N-v%v',
            tag_message => '%N-v%v',
        ]],
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::BioPerl - Build your distributions like Bioperl does

=head1 VERSION

version 0.27

=head1 SYNOPSIS

  # dist.ini
  name = Dist-Zilla-Plugin-BioPerl
  ...

  [@BioPerl]

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration for the BioPerl project. It is roughly
equivalent to:

  [@Filter]
  -bundle = @Basic      ; the basic to maintain and release CPAN distros
  -remove = Readme      ; avoid conflict since we already have a README file

  [MetaConfig]          ; summarize Dist::Zilla configuration on distribution
  [MetaJSON]            ; produce a META.json
  [PkgVersion]          ; add a $version to the modules
  [PodSyntaxTests]      ; create a release test for Pod syntax
  [Test::NoTabs]        ; create a release tests making sure hard tabs aren't used
  [Test::Compile]       ; test syntax of all modules
  [PodCoverageTests]    ; create release test for Pod coverage
  [MojibakeTests]       ; create release test for correct encoding
  [AutoPrereqs]         ; automatically find the dependencies

  [AutoMetaResources]   ; automatically fill resources fields on metadata
  repository.github     = user:bioperl
  bugtracker.github     = user:bioperl
  homepage              = https://metacpan.org/release/${dist}

  [MetaResources]       ; fill resources fields on metadata
  bugtracker.mailto     = bioperl-l@bioperl.org

  [Test::EOL]           ; create release tests for correct line endings
  trailing_whitespace = 1

  ;; While data files for the test units are often text files, they
  ;; need to be treated as bytes.  This has the side effect of having
  ;; them ignored by [Test::NoTabs] and [Test::EOL]
  [Encoding]
  encoding = bytes
  match = ^t/data/

  [PodWeaver]
  config_plugin = @BioPerl

  [NextRelease]         ; update release number on Changes file
  [Git::Check]          ; check working path for any uncommitted stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Commit]         ; commit the dzil-generated stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Tag]            ; tag our new release
  tag_format  = %N-v%v
  tag_message = %N-v%v

In addition, this also has two roles, L<Dist::Zilla::PluginBundle::PluginRemover> and
Dist::Zilla::PluginBundle::Config::Slice, so one could do something like this for
problematic distributions:

  [@BioPerl]
  -remove = MojibakeTests
  -remove = PodSyntaxTests

=head1 Pushing releases

With this PluginBundle, there's a lot of things happening
automatically. It might not be clear what actually needs to be done
and what will be done automatically unless you are already familiar
with all the plugins being used.  Assuming that F<Changes> is up
to date (you should be updating F<Changes> as the changes are made
and not when preparing a release.  If you need to add notes to that
file, then do it do it at the same time you bump the version number in
F<dist.ini>), the following steps will make a release:

=over 4

=item 1

Make sure the working directory is clean with `git status'.

=item 2

Run `dzil test --all'

=item 3

Edit dist.ini to bump the version number only.

=item 4

Run `dzil release'

=item 5

Run `git push --follow-tags'

=back

These steps will automatically do the following:

=over 4

=item *

Modify F<Changes> with the version number and time of release.

=item *

Make a git commit with the changes to F<Changes> and F<dist.ini> using a standard commit message.

=item *

Add a lightweight git tag for the release.

=item *

Run the tests (including a series of new tests for maintainers only) and push release to CPAN.

=back

=head1 CONFIGURATION

Use the L<Dist::Zilla::PluginBundle::Filter> to filter any undesired plugin
that is part of the default set. This also allows to change those plugins
default values. However, the BioPerl bundle already recognizes some of the
plugins options and will pass it to the corresponding plugin. If any is missing,
please consider patching this bundle.

In some cases, this bundle will also perform some sanity checks before passing
the value to the original plugin.

=over 4

=item *

homepage

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

repository.github

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

bugtracker.github

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

bugtracker.mailto

Same option used by the L<Dist::Zilla::Plugin::MetaResources>

=item *

trailing_whitespace

Same option used by the L<Dist::Zilla::Plugin::EOLTests>

=item *

allow_dirty

Same option used by the L<Dist::Zilla::Plugin::Git::Commit> and
L<Dist::Zilla::Plugin::Git::Check>

=back

=for Pod::Coverage get_value

=for Pod::Coverage mvp_multivalue_args

=for Pod::Coverage configure

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org               - General discussion
  https://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>
rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/dist-zilla-pluginbundle-bioperl/issues

=head1 AUTHORS

Florian Ragwitz <rafl@debian.org>

Sheena Scroggins

Carnë Draug <carandraug+dev@gmail.com>

Chris Fields <cjfields1@gmail.com>

=head1 COPYRIGHT

This software is copyright (c) 2010 by Florian Ragwitz, 2011 by Sheena Scroggins, and 2013-2017 by Carnë Draug.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
