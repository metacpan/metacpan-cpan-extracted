use strict;
use warnings;
package Dist::Zilla::Plugin::OptionalFeature; # git description: v0.022-4-gd500bf9
# ABSTRACT: Specify prerequisites for optional features in your distribution
# KEYWORDS: plugin metadata prerequisites optional recommended prompt install
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.023';

use Moose;
with
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PrereqSource';

use MooseX::Types::Moose qw(HashRef Bool);
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use Carp 'confess';
use Module::Runtime 'use_module';
use namespace::autoclean;

has name => (
    is => 'ro', isa => NonEmptySimpleStr,
    required => 1,
);
has description => (
    is => 'ro', isa => NonEmptySimpleStr,
    required => 1,
);

has always_recommend => (
    is => 'ro', isa => Bool,
    default => 0,
);

has always_suggest => (
    is => 'ro', isa => Bool,
    lazy => 1,
    default => sub { shift->always_recommend ? 0 : 1 },
);

has require_develop => (
    is => 'ro', isa => Bool,
    default => 1,
);

has prompt => (
    is => 'ro', isa => Bool,
    lazy => 1,
    default => sub { shift->_prereq_type eq 'requires' ? 1 : 0 },
);

has default => (
    is => 'ro', isa => Bool,
    predicate => '_has_default',
    # NO DEFAULT
);

has check_prereqs => (
    is => 'ro', isa => Bool,
    default => 1,
);

has _prereq_phase => (
    is => 'ro', isa => NonEmptySimpleStr,
    lazy => 1,
    default  => 'runtime',
);

has _prereq_type => (
    is => 'ro', isa => NonEmptySimpleStr,
    lazy => 1,
    default => 'requires',
);

has _prereqs => (
    is => 'ro', isa => HashRef[NonEmptySimpleStr],
    lazy => 1,
    default => sub { {} },
    traits => ['Hash'],
    handles => { _prereq_modules => 'keys', _prereq_version => 'get' },
);

sub mvp_aliases { +{ -relationship => '-type', -load_prereqs => '-check_prereqs' } }

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    my @private = grep { /^_/ } keys %$args;
    confess "Invalid options: @private" if @private;

    # pull these out so they don't become part of our prereq list
    my ($zilla, $plugin_name) = delete @{$args}{qw(zilla plugin_name)};

    my %opts = (
        map { exists $args->{$_} ? ( substr($_, 1) => delete($args->{$_}) ) : () }
        qw(-name -description -always_recommend -always_suggest -require_develop -prompt -default -check_prereqs -phase -type));
    $opts{type} //= delete $args->{'-relationship'} if defined $args->{'-relationship'};

    my @other_options = grep { /^-/ } keys %$args;
    delete @{$args}{@other_options};
    warn "[OptionalFeature] warning: unrecognized option(s): @other_options" if @other_options;

    # handle magic plugin names
    if ((not $opts{name} or not $opts{phase} or not $opts{type})
            # plugin comes from a bundle
        and $plugin_name !~ m! (?: \A | / ) OptionalFeature \z !x)
    {
        $opts{name} ||= $plugin_name;

        if ($opts{name} =~ / -
                (Build|Test|Runtime|Configure|Develop)
                (Requires|Recommends|Suggests|Conflicts)?
            \z/xp)
        {
            $opts{name} = ${^PREMATCH};
            $opts{phase} ||= lc($1) if $1;
            $opts{type} = lc($2) if $2;
        }
    }

    confess 'optional features may not use the configure phase'
        if $opts{phase} and $opts{phase} eq 'configure';

    $opts{_prereq_phase} = delete $opts{phase} if exists $opts{phase};
    $opts{_prereq_type} = delete $opts{type} if exists $opts{type};

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        %opts,
        _prereqs => $args,
    };
};

has _dynamicprereqs_prompt => (
    is => 'ro', isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $phase = $self->_prereq_phase;
        my $function = $phase eq 'runtime' ? 'requires'
            : $phase eq 'test' ? 'test_requires'
            : $phase eq 'build' ? 'build_requires'
            : $self->log_fatal("illegal phase $phase");
        $self->log_fatal('prompts are only used for the \'requires\' type')
            if $self->_prereq_type ne 'requires';

        (my $description = $self->description) =~ s/'/\\'/g;

        my $prompt = "prompt('install $description? "
                . ($self->default ? "[Y/n]', 'Y'" : "[y/N]', 'N'" )
                . ') =~ /^y/i';
        my @directives = map {
            my $version = $self->_prereq_version($_);
            $function . "('$_'" . ($version ? ", '$version'" : '') . ')'
        } sort $self->_prereq_modules;

        my $require_clause = !$self->check_prereqs ? ''
            : (join(' && ', map {
                my $version = $self->_prereq_version($_);
                "has_module('$_'" . ($version ? ", '$version'" : '') . ')'
            } sort $self->_prereq_modules
        ) . "\n    || ");

        [
            @directives > 1
                ? (
                    'if (' . $require_clause . $prompt . ') {',   # to mollify vim
                    (map { '  ' . $_ . ';' } @directives),
                    '}',
                  )
                : ( @directives , '  if ' . $require_clause . $prompt . ';' )
        ];
    },
);

# package-scoped singleton to track the OptionalFeature instance that manages all the dynamic prereqs
my $master_plugin;
sub __clear_master_plugin { undef $master_plugin } # for testing

sub before_build
{
    my $self = shift;

    if ($self->prompt and not $master_plugin)
    {
        # because [DynamicPrereqs] inserts Makefile.PL content in reverse
        # order to when it was called, we make just one [OptionalFeature]
        # plugin will create and add all DynamicPrereqs plugins, so the order
        # of the prompts is in the same order as the dist.ini declarations and
        # the corresponding metadata.

        $master_plugin = $self;

        my $plugin = use_module('Dist::Zilla::Plugin::DynamicPrereqs')->new(
            zilla => $self->zilla,
            plugin_name => 'via OptionalFeature',
            # if we require 0.018, we can s/raw/body/.
            raw => [
                join("\n",
                    map {
                        join("\n", $_->prompt ? @{ $_->_dynamicprereqs_prompt } : ())
                    } grep { $_->isa(__PACKAGE__) } @{ $self->zilla->plugins },
                )
            ],
        );

        push @{ $self->zilla->plugins }, $plugin;
    }
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ } qw(name description )),
        (map { $_ => ($self->$_ ? 1 : 0) } qw(always_recommend always_suggest require_develop prompt)),
        $self->prompt ? ( check_prereqs => $self->check_prereqs ) : (),
        # FIXME: YAML::Tiny does not handle leading - properly yet
        # (map { defined $self->$_ ? ( '-' . $_ => $self->$_ ) : () }
        (map { defined $self->$_ ? ( $_ => $self->$_ ) : () } qw(default)),
        phase => $self->_prereq_phase,
        type => $self->_prereq_type,
        prereqs => $self->_prereqs,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub register_prereqs
{
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            phase => 'develop',
            type  => 'requires',
        },
        %{ $self->_prereqs },
    ) if $self->require_develop;

    foreach my $phase (qw(recommend suggest))
    {
        $self->zilla->register_prereqs(
            {
                phase => $self->_prereq_phase,
                type  => $phase . 's',
            },
            %{ $self->_prereqs },
        ) if $self->${\"always_$phase"};
    }

    return;
}

sub metadata
{
    my $self = shift;

    # this might be relaxed in the future -- see
    # https://github.com/Perl-Toolchain-Gang/cpan-meta/issues/28
    # but this is the current v2.0 spec - regexp lifted from Test::CPAN::Meta::JSON::Version
    $self->log_fatal('invalid syntax for optional feature name \'' .  $self->name . '\'')
        if $self->name !~ /^([a-z][_a-z]+)$/i;

    return {
        # dynamic_config is NOT set, on purpose -- normally the CPAN client
        # does the user interrogation and merging of prereqs, not Makefile.PL/Build.PL
        optional_features => {
            $self->name => {
                description => $self->description,
                # we don't know which way this will/should default in the spec if omitted,
                # so we only include it if the user explicitly sets it
                $self->_has_default ? ( x_default => $self->default ) : (),
                prereqs => { $self->_prereq_phase => { $self->_prereq_type => $self->_prereqs } },
            },
        },
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OptionalFeature - Specify prerequisites for optional features in your distribution

=head1 VERSION

version 0.023

=head1 SYNOPSIS

In your F<dist.ini>:

    [OptionalFeature / XS_Support]
    -description = XS implementation (faster, requires a compiler)
    -prompt = 1
    Foo::Bar::XS = 1.002

=head1 DESCRIPTION

This plugin provides a mechanism for specifying prerequisites for optional
features in metadata, which should cause CPAN clients to interactively prompt
you regarding these features at install time (assuming interactivity is turned
on: e.g. C<< cpanm --interactive Foo::Bar >>).

The feature I<name> and I<description> are required. The name can be extracted
from the plugin name.

You can specify requirements for different phases and relationships with:

    [OptionalFeature / Feature_name]
    -description = description
    -phase = test
    -relationship = requires
    Fitz::Fotz    = 1.23
    Text::SoundEx = 3

If not provided, C<-phase> defaults to C<runtime>, and C<-relationship> to
C<requires>.

To specify feature requirements for multiple phases, provide them as separate
plugin configurations (keeping the feature name and description constant):

    [OptionalFeature / Feature_name]
    -description = description
    -phase = runtime
    Foo::Bar = 0

    [OptionalFeature / Feature_name]
    -description = description
    -phase = test
    Foo::Baz = 0

B<NOTE>: this doesn't seem to work properly with L<CPAN::Meta::Merge> (used in L<Dist::Zilla> since version 5.022).

It is possible that future versions of this plugin may allow a more compact
way of providing sophisticated prerequisite specifications.

If the plugin name is the CamelCase concatenation of a phase and relationship
(or just a relationship), it will set those parameters implicitly.  If you use
a custom name, but it does not specify the relationship, and you didn't
specify either or both of C<-phase> or C<-relationship>, these values default
to C<runtime> and C<requires> respectively.

The example below is equivalent to the synopsis example above, except for the
name of the resulting plugin:

    [OptionalFeature]
    -name = XS_Support
    -description = XS implementation (faster, requires a compiler)
    -phase = runtime
    -relationship = requires
    Foo::Bar::XS = 1.002

B<NOTE>: It is advised that you only specify I<one> prerequisite for a given
feature -- and if necessary, create a separate distribution to encapsulate the
code needed to make that feature work (along with all of its dependencies).
This allows external projects to declare a prerequisite not just on your
distribution, but also a particular feature of that distribution.

=for Pod::Coverage mvp_aliases BUILD before_build metadata register_prereqs

=head1 PROMPTING

At the moment it doesn't appear that any CPAN clients properly support
C<optional_feature> metadata and interactively prompt the user with the
information therein.  Therefore, prompting is added directly to F<Makefile.PL>
when the C<-relationship> is C<requires>. (It doesn't make much sense to
prompt for C<recommends> or C<suggests> features, so prompting is omitted
here.)  You can also enable or disable this explicitly with the C<-prompt> option.
The prompt feature can only be used with F<Makefile.PL>. If a F<Build.PL> is
detected in the build and C<=prompt> is set, the build will fail.

As with any other interactive features, the installing user can bypass the
prompts with C<PERL_MM_USE_DEFAULT=1>.  You may want to set this when running
C<dzil build>.

=head1 CONFIGURATION OPTIONS

=head2 C<-name>

The name of the optional feature, to be presented to the user. Can also be
extracted from the plugin name.

=head2 C<-description>

The description of the optional feature, to be presented to the user.
Defaults to the feature name, if not provided.

=head2 C<-always_recommend>

If set with a true value, the prerequisites are added to the distribution's
metadata as recommended prerequisites (e.g. L<cpanminus> will install
recommendations with C<--with-recommends>, even when running
non-interactively).

Defaults to C<false>, but I recommend you turn this on.

=head2 C<-always_suggest>

(Available since version 0.022)

If set with a true value, the prerequisites are added to the distribution's
metadata as suggested prerequisites.

Defaults to the inverse of C<-always_recommend>.

=head2 C<-require_develop>

(Available since version 0.011)

If set with a true value, the prerequisites are added to the distribution's
metadata as develop requires prerequisites (e.g. L<cpanminus> will install
recommendations with C<--with-develop>, even when running
non-interactively).

Defaults to C<true>.

=head2 C<-prompt>

(Available since version 0.017)

If set with a true value, F<Makefile.PL> is modified to include interactive
prompts.

Default is C<true> if C<-relationship> is C<requires>.
C<false> otherwise.

=head2 C<-check_prereqs>

(Available since version 0.021 as -load_prereqs, 0.022 as its present name)

If set, and C<-prompt> is also set, the prerequisites to be added by the feature
are checked for in the Perl installation; if the requirements are already met,
then the feature is automatically added.

Default is C<true>.

=head2 C<-default>

(Available since version 0.006)

If set with a true value, non-interactive installs will automatically
fold the feature's prerequisites into the regular prerequisites.

=for stopwords miyagawa

Note that at the time of this feature's creation (September 2013), there is no
compliant CPAN client yet, as it invents a new C<x_default> field in metadata
under C<optional_feature> (thanks, miyagawa!)

=head2 C<-phase>

The phase of the prequisite(s). Should be one of: build, test, runtime,
or develop.

Default: C<runtime>

=head2 C<-relationship> (or C<-type>)

The relationship of the prequisite(s). Should be one of: requires, recommends,
suggests, or conflicts.

Default: C<requires>

=head1 SEE ALSO

=over 4

=item *

L<CPAN::Meta::Spec/optional_features>

=item *

L<Module::Install::API/features, feature (Module::Install::Metadata)>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OptionalFeature>
(or L<bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-OptionalFeature@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Kent Fredric

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
