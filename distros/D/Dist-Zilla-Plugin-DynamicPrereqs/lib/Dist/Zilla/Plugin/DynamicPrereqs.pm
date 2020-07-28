use strict;
use warnings;
package Dist::Zilla::Plugin::DynamicPrereqs; # git description: v0.037-6-gfad5320
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Specify dynamic (user-side) prerequisites for your distribution
# KEYWORDS: plugin distribution metadata MYMETA prerequisites Makefile.PL dynamic

our $VERSION = '0.038';

use Moose;
with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::ModuleMetadata',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::TextTemplate',
;
use List::Util 1.45 qw(first notall any uniq);
use Module::Runtime 'module_notional_filename';
use Try::Tiny;
use Path::Tiny;
use File::ShareDir;
use namespace::autoclean;
use Term::ANSIColor 3.00 'colored';

has raw => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { raw => 'elements' },
    lazy => 1,
    default => sub {
        my $self = shift;

        my @lines;
        if (my $filename = $self->raw_from_file)
        {
            my $file = first { $_->name eq $filename } @{ $self->zilla->files };
            $self->log_fatal([ 'no such file in build: %s' ], $filename) if not $file;
            $self->zilla->prune_file($file);
            try {
                @lines = split(/\n/, $file->content);
            }
            catch {
                $self->log_fatal($_);
            };
        }

        $self->log('no content found in -raw/-body!') if not @lines;
        return \@lines;
    },
);

has raw_from_file => (
    is => 'ro', isa => 'Str',
);

has $_ => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { $_ => 'elements' },
    lazy => 1,
    default => sub { [] },
) foreach qw(include_subs conditions);

sub mvp_multivalue_args { qw(raw include_subs conditions) }

sub mvp_aliases { +{
    '-raw' => 'raw',
    '-delimiter' => 'delimiter',
    '-raw_from_file' => 'raw_from_file',
    '-include_sub' => 'include_subs',
    '-condition' => 'conditions',
    '-body' => 'raw',
    '-body_from_file' => 'raw_from_file',
    'body_from_file' => 'raw_from_file',
} }

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    my $delimiter = delete $args->{delimiter};
    if (defined $delimiter and length($delimiter))
    {
        s/^\Q$delimiter\E// foreach @{$args->{raw}};
    }

    return $args;
};

sub BUILD
{
    my ($self, $args) = @_;

    $self->log_fatal('[MakeMaker::Awesome] must be at least version 0.19 to be used with [DynamicPrereqs]')
        if $INC{module_notional_filename('Dist::Zilla::Plugin::MakeMaker::Awesome')}
            and not eval { Dist::Zilla::Plugin::MakeMaker::Awesome->VERSION('0.19') };

    my %extra_args = %$args;
    delete @extra_args{ map $_->name, $self->meta->get_all_attributes };
    if (my @keys = keys %extra_args)
    {
        $self->log('Warning: unrecognized argument' . (@keys > 1 ? 's' : '')
                . ' (' . join(', ', @keys) . ') passed. Perhaps you need to upgrade?');
    }
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub metadata { return +{ dynamic_config => 1 } }

sub after_build
{
    my $self = shift;
    $self->log_fatal('Build.PL detected - dynamic prereqs will not be added to it!')
        if first { $_->name eq 'Build.PL' } @{ $self->zilla->files };
}

# track which subs have already been included by some other instance
my %included_subs;

sub munge_files
{
    my $self = shift;

    my $file = first { $_->name eq 'Makefile.PL' } @{$self->zilla->files};
    $self->log_fatal('No Makefile.PL found! Is [MakeMaker] at least version 5.022?') if not $file;

    my $content = $file->content;

    $self->log_debug('Inserting dynamic prereq into Makefile.PL...');

    # we insert our code just *before* this bit in Makefile.PL
    my $insertion_breadcrumb = "\n\nunless ( eval { ExtUtils::MakeMaker";

    # insert after declarations for BOTH %WriteMakefileArgs, %FallbackPrereqs.
    # TODO: if marker cannot be found, fall back to looking for just
    # %WriteMakefileArgs -- this requires modifying the content too.
    $self->log_fatal('failed to find position in Makefile.PL to munge!')
        if $content !~ m/\Q$insertion_breadcrumb/mg;

    my $pos = pos($content) - length($insertion_breadcrumb);

    my $code = join("\n", $self->raw);
    if (my $conditions = join(' && ', $self->conditions))
    {
        $code = "if ($conditions) {\n"
            . $code . "\n"
            . '}' . "\n";
    }

    $content = substr($content, 0, $pos)
        . "\n"
        . $self->_header . "\n"
        . $code . "\n"
        . substr($content, $pos);

    $content =~ s/\n+\z/\n/;

    $content .= $self->_sub_definitions;

    $file->content($content);
    return;
}

has _header => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        '# inserted by ' . blessed($self) . ' ' . $self->VERSION;
    },
);

has _sub_definitions => (
    is => 'ro', isa => 'Str',
    lazy => 1, builder => '_build__sub_definitions',
);

sub _build__sub_definitions
{
    my $self = shift;

    my @include_subs = grep +(not exists $included_subs{$_}), $self->_all_required_subs;
    return '' if not @include_subs;

    my $content;
    $content .= "\n" . $self->_header if not keys %included_subs;

    if (my @missing_subs = grep !-f path($self->_include_sub_root, $_), @include_subs)
    {
        $self->log_fatal(
            @missing_subs > 1
                ? [ 'no definitions available for subs %s!', join(', ', map "'".$_."'", @missing_subs) ]
                : [ 'no definition available for sub \'%s\'!', $missing_subs[0] ]
        );
    }

    # On consultation with ribasushi I agree that we cannot let authors
    # use some sub definitions without copious danger tape.
    $self->_warn_include_subs(@include_subs);

    my @sub_definitions = map path($self->_include_sub_root, $_)->slurp_utf8, @include_subs;
    $content .= "\n"
        . $self->fill_in_string(
            join("\n", @sub_definitions),
            {
                dist => \($self->zilla),
                plugin => \$self,
            },
        );
    @included_subs{@include_subs} = (() x @include_subs);

    return $content;
}


my %sub_prereqs = (
    can_cc => {
        'Config' => '0',                # core since perl 5.00307
    },
    can_run => {
        'File::Spec' => '0',            # core since perl 5.00405
        'Config' => '0',                # core since perl 5.00307
    },
    parse_args => {
        'Text::ParseWords' => '0',      # core since perl 5.000
    },
    has_module => {
        'Module::Metadata' => '0',      # core since perl 5.013009
        'CPAN::Meta::Requirements' => '2.120620',   # core since perl 5.015007
    },
    is_miniperl => {
        'DynaLoader' => '0',            # core since perl 5.000
    },
);

# instead of including these dependencies in configure-requires, we inline
# them right into the distribution in inc/.
my %sub_inc_dependencies = (
    can_xs => {
        'ExtUtils::HasCompiler' => '0.014',
    },
);

sub gather_files {
    my $self = shift;

    foreach my $required_sub ($self->_all_required_subs)
    {
        # FIXME: update %included_subs earlier to account for other coexisting
        # plugins, or running two instances of the plugin will try to do this twice.
        my $include_modules = $sub_inc_dependencies{$required_sub} || {};
        foreach my $module (keys %$include_modules)
        {
            (my $path = $module) =~ s{::}{/}g;
            $path = path('inc', $path . '.pm');
            my $cpath = $path->canonpath;

            my $file = first { $_->name eq $path or $_->name eq $cpath } @{ $self->zilla->files };
            if (not $file)
            {
                $self->log([ 'inlining %s into inc/', $module ]);
                my $installed_filename = Module::Metadata->find_module_by_name($module)
                    or $self->log_fatal([ 'Can\'t locate %s', $module ]);

                $file = Dist::Zilla::File::OnDisk->new({ name => $installed_filename });
                $file->name($path->stringify);
                $self->add_file($file);
            }
            $self->log_fatal([ 'failed to find %s in files', $module ]) if not $file;

            if (defined $include_modules->{$module} and $include_modules->{$module} > 0)
            {
                # check that the file we got actually satisfies our dependency
                my $mmd = $self->module_metadata_for_file($file);
                $self->log_fatal([ '%s version %s required--only found version %s',
                        $module, $include_modules->{$module},
                        (defined $mmd->version ? $mmd->version->stringify : 'undef') ])
                    if ($mmd->version || 0) < $include_modules->{$module};
            }
        }
    }
}

sub register_prereqs
{
    my $self = shift;
    foreach my $required_sub ($self->_all_required_subs)
    {
        my $configure_prereqs = $sub_prereqs{$required_sub} || {};
        $self->zilla->register_prereqs(
            {
                phase => 'configure',
                type  => 'requires',
            },
            %$configure_prereqs,
        ) if %$configure_prereqs;

        my $develop_prereqs = $sub_inc_dependencies{$required_sub} || {};
        $self->zilla->register_prereqs(
            {
                phase => 'develop',
                type  => 'requires',
            },
            %$develop_prereqs,
        ) if %$develop_prereqs;
    }
}

has _include_sub_root => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        path(File::ShareDir::module_dir($self->meta->name), 'include_subs')->stringify;
    },
);

# indicates subs that require other subs to be included
my %sub_dependencies = (
    can_cc => [ qw(can_run) ],
    can_run => [ qw(maybe_command) ],
    requires => [ qw(runtime_requires) ],
    runtime_requires => [ qw(_add_prereq) ],
    build_requires => [ qw(_add_prereq) ],
    test_requires => [ qw(_add_prereq) ],
    want_pp => [ qw(parse_args) ],
);

has _all_required_subs => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _all_required_subs => 'elements' },
    lazy => 1,
    default => sub {
        my $self = shift;
        my @code = ($self->conditions, $self->raw);
        my @subs_in_code = !@code ? () :
            grep {
                my $sub_name = $_;
                any { /\b$sub_name\b\(/ } @code
            } map $_->basename, path($self->_include_sub_root)->children;

        [ sort($self->_all_required_subs_for(uniq(
            $self->include_subs, @subs_in_code,
        ))) ];
    },
);

my %required_subs;
sub _all_required_subs_for
{
    my ($self, @subs) = @_;

    @required_subs{@subs} = (() x @subs);

    foreach my $sub (@subs)
    {
        my @subs = @{ $sub_dependencies{$sub} || [] };
        $self->_all_required_subs_for(@subs)
            if notall { exists $required_subs{$_} } @subs;
    }

    return keys %required_subs;
}

my %warn_include_sub = (
    can_xs => 1,
    can_cc => 1,
    can_run => 1,
);

sub _warn_include_subs
{
    my ($self, @include_subs) = @_;

    $self->log(colored('Use ' . $_ . ' with great care! Please consult the documentation!', 'bright_yellow'))
        foreach grep exists $warn_include_sub{$_}, @include_subs;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DynamicPrereqs - Specify dynamic (user-side) prerequisites for your distribution

=head1 VERSION

version 0.038

=head1 SYNOPSIS

In your F<dist.ini>:

    [DynamicPrereqs]
    -condition = has_module('Role::Tiny')
    -condition = !want_pp()
    -condition = can_xs()
    -body = requires('Role::Tiny', '1.003000')

or:

    [DynamicPrereqs]
    -delimiter = |
    -raw = |test_requires('Devel::Cover')
    -raw = |    if $ENV{EXTENDED_TESTING} or is_smoker();

or:

    [DynamicPrereqs]
    -raw_from_file = Makefile.args      # code snippet in this file

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that inserts code into your F<Makefile.PL> to
indicate dynamic (installer-side) prerequisites.

Code is inserted immediately after the declarations for C<%WriteMakefileArgs>
and C<%FallbackPrereqs>, before they are conditionally modified (when an older
L<ExtUtils::MakeMaker> is installed).  This gives you an opportunity to add to
the C<WriteMakefile> arguments: C<PREREQ_PM>, C<BUILD_REQUIRES>, and
C<TEST_REQUIRES>, and therefore modify the prerequisites in the user's
F<MYMETA.yml> and F<MYMETA.json> based on conditions found on the user's system.

The C<dynamic_config> field in L<metadata|CPAN::Meta::Spec/dynamic_config> is
already set for you.

=for stopwords usecase

You could potentially use this plugin for performing other modifications in
F<Makefile.PL> other than user-side prerequisite modifications, but I can't
think of a situation where this makes sense. Contact me if you have any ideas!

Only F<Makefile.PL> modification is supported at this time. This author
considers the use of L<Module::Build> to be questionable in all circumstances,
and L<Module::Build::Tiny> does not (yet?) support dynamic configuration.

=head1 BE VIGILANT!

You are urged to check the generated F<Makefile.PL> for sanity, and to run it
at least once to validate its syntax. Although every effort is made to
generate valid and correct code, mistakes can happen, so verification is
needed before shipping.

Please also see the other warnings later in this document.

=head1 CONFIGURATION OPTIONS

=head2 C<-raw>

=head2 C<-body>

The code to be inserted; must be valid and complete perl statements. You can
reference and modify the already-declared C<%WriteMakefileArgs> and
C<%FallbackPrereqs> variables, as inserted into F<Makefile.PL> by
L<Dist::Zilla::Plugin::MakeMaker> and subclasses (e.g.
L<Dist::Zilla::Plugin::MakeMaker::Awesome> since L<Dist::Zilla> C<5.001>.

This option can be used more than once; lines are added in the order in which they are provided.

If you use external libraries in the code you are inserting, you B<must> add
these modules to C<configure_requires> prereqs in metadata (e.g. via
C<[Prereqs / ConfigureRequires]> in your F<dist.ini>).

C<-body> first became available in version 0.018.

=for Pod::Coverage mvp_multivalue_args mvp_aliases BUILD metadata after_build munge_files register_prereqs gather_files

=head2 C<-delimiter>

(Available since version 0.007)

A string, usually a single character, which is stripped from the beginning of
all C<-raw>/C<-body> lines. This is because the INI file format strips all leading
whitespace from option values, so including this character at the front allows
you to use leading whitespace in an option string, so you can indent blocks of
code properly.

=head2 C<-raw_from_file>

(Available since version 0.010)

=head2 C<-body_from_file>

(Available since version 0.018)

A filename that contains the code to be inserted; must be valid and complete
perl statements, as with C<-raw>/C<-body> above.  This file must be part of the build,
but it is pruned from the built distribution.

=head2 C<-condition>

(Available since version 0.014)

=for stopwords ANDed

A perl expression to be included in the condition statement in the
F<Makefile.PL>.  Multiple C<-condition>s can be provided, in which case they
are ANDed together to form the final condition statement. (You must
appropriately parenthesize each of your conditions to ensure correct order of
operations.)  Any use of recognized subroutines will cause their definitions
to be included automatically (see L<AVAILABLE SUBROUTINE DEFINITIONS>, below).

When combined with C<-raw>/C<-body> lines, the condition is placed first in a C<if>
statement, and the C<-raw>/C<-body> lines are contained as the body of the block. For example:

    [DynamicPrereqs]
    -condition = "$]" > '5.020'
    -body = requires('Role::Tiny', '1.003000')

results in the F<Makefile.PL> snippet (note that whitespace is not added, in
case this affects the parsing:

    if ("$]" > '5.020') {
    requires('Role::Tiny', '1.003000')
    }

=head2 C<-include_sub>

(Available since version 0.010; rendered unnecessary in 0.016 (all definitions
are now included automatically, when used).

=head1 AVAILABLE SUBROUTINE DEFINITIONS

A number of helper subroutines are available for use within your code inserted
via C<-body>, C<-body_from_file>, C<-raw>, C<-raw_from_file>, or C<-condition> clauses. When used, their
definition(s) will be included automatically in F<Makefile.PL> (as well as
those of any other subroutines I<they> call); necessary prerequisite modules
will be added to C<configure requires> metadata.

Unless otherwise noted, these all became available in version 0.010.
Available subs are:

=over 4

=item *

C<prompt_default_yes($message)> - takes a string (appending "[Y/n]" to it), returns a boolean; see L<ExtUtils::MakeMaker/prompt>

=item *

C<prompt_default_no($message)> - takes a string (appending "[y/N]" to it), returns a boolean; see L<ExtUtils::MakeMaker/prompt>

=item *

C<parse_args()> - returns the hashref of options that were passed as arguments to C<perl Makefile.PL>

=item *

C<can_xs()> - XS capability testing via L<ExtUtils::HasCompiler> (don't forget to also check C<want_pp>!) Available in this form since 0.029.

=item *

C<can_cc()> - can we locate a (the) C compiler

=item *

C<can_run()> - check if we can run some command

=item *

C<is_miniperl()> - returns true if the current perl is miniperl (this may affect your ability to run XS code) Available since 0.033.

=item *

C<can_use($module [, $version ])> - checks if a module (optionally, at a specified version) can be loaded. (If you don't want to load the module, you should use C<< has_module >>, see below.)

=for stopwords backcompat

=item *

C<has_module($module [, $version_or_range ])> - checks if a module (optionally, at a specified version or matching a L<version range|CPAN::Meta::Spec/version_ranges>) is available in C<%INC>. Does not load the module, so is safe to use with modules that have side effects when loaded.  When passed a second argument, returns true or false; otherwise, returns undef or the module's C<$VERSION>. Note that for extremely simple usecases (module has no side effects when loading, and no explicit version is needed), it can be simpler and more backcompat-friendly to simply do: C<< eval { require Foo::Bar } >>. (Current API available since version 0.015.)

=item *

C<is_smoker()> - is the installation on a smoker machine?

=item *

C<is_interactive()> - is the installation in an interactive terminal?

=item *

C<is_trial()> - is the release a -TRIAL or _XXX-versioned release?

=item *

C<is_os($os, ...)> - true if the OS is any of those listed

=item *

C<isnt_os($os, ...)> - true if the OS is none of those listed

=item *

C<maybe_command> - actually a monkeypatch to C<< MM->maybe_command >> (please keep using the fully-qualified form) to work in Cygwin

=item *

C<runtime_requires($module [, $version ])> - adds the module to runtime prereqs (as a shorthand for editing the hashes in F<Makefile.PL> directly). Added in 0.016.

=item *

C<requires($module [, $version ])> - alias for C<runtime_requires>. Added in 0.016.

=item *

C<build_requires($module [, $version ])> - adds the module to build prereqs (as a shorthand for editing the hashes in F<Makefile.PL> directly). Added in 0.016.

=item *

C<test_requires($module [, $version ])> - adds the module to test prereqs (as a shorthand for editing the hashes in F<Makefile.PL> directly). Added in 0.016.

=item *

C<want_pp> - true if the user or CPAN client explicitly specified PUREPERL_ONLY (indicating that no XS-requiring modules or code should be installed)

=back

=head1 WARNING: INCOMPLETE SUBROUTINE IMPLEMENTATIONS!

The implementations for some subroutines (in particular, C<can_xs>, C<can_cc>
and C<can_run> are still works in progress, incompatible with some architectures and
cannot yet be considered a suitable generic solution. Until we are more
confident in their implementations, a warning will be printed (to the distribution author)
upon use, and
their use B<is not advised> without prior consultation with the author and
other members of the Perl Toolchain Gang
(see L<C<#toolchain> on C<irc.perl.org>|irc://irc.perl.org/#toolchain>).

=head1 WARNING: UNSTABLE API!

=for stopwords DarkPAN metacpan

This plugin is still undergoing active development, and the interfaces B<will>
change and grow as I work through the proper way to do various things.  As I
make changes, I will be using
L<metacpan's reverse dependencies list|https://metacpan.org/requires/distribution/Dist-Zilla-Plugin-DynamicPrereqs>
and L<http://grep.cpan.me> to find and fix any
upstream users, but I obviously cannot do this for DarkPAN users. Regardless,
please contact me (see below) and I will keep you directly advised of
interface changes.

Future planned features:

=for stopwords CPANFile

=over 4

=item *

better compiler detection and conditional XS code inclusion

=item *

interoperability with the L<[CPANFile]|Dist::Zilla::Plugin::CPANFile> plugin (generation of dynamic prerequisites into a F<cpanfile>)

=item *

something like C<is_perl_at_least('5.008001')> for testing C<$]>

=item *

inlining of sub content for some checks, to allow constant folding (e.g. C<$^O> and C<$]> checks)

=back

=head1 LIMITATIONS

It is not possible, given the current features of L<ExtUtils::MakeMaker>, to have dynamic prerequisites using the
C<recommends>, C<suggests> or C<conflicts> types. (This is because these get added via the C<META_ADD> or
C<META_MERGE> Makefile arguments, and these are ignored for the generation of F<MYMETA.json>.)

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::MakeMaker>

=item *

L<ExtUtils::MakeMaker/Using Attributes and Parameters>

=item *

L<Dist::Zilla::Plugin::OSPrereqs>

=item *

L<Dist::Zilla::Plugin::PerlVersionPrereqs>

=item *

L<Module::Install::Can>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-DynamicPrereqs>
(or L<bug-Dist-Zilla-Plugin-DynamicPrereqs@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-DynamicPrereqs@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.freenode.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Graham Ollis

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
