use strict;
use warnings;
package Dist::Zilla::Plugin::PromptIfStale; # git description: v0.053-7-g31c70ff
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Check at build/release time if modules are out of date
# KEYWORDS: prerequisites upstream dependencies modules metadata update stale

our $VERSION = '0.054';

use Moose;
with 'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::BeforeRelease';

use Moose::Util::TypeConstraints 'enum';
use List::Util 1.45 qw(none any uniq);
use version;
use Moose::Util 'find_meta';
use Path::Tiny;
use Cwd;
use CPAN::DistnameInfo;
use HTTP::Tiny;
use YAML::Tiny;
use Module::Metadata 1.000023;
use Encode ();
use namespace::autoclean;

sub mvp_multivalue_args { qw(modules skip) }
sub mvp_aliases { {
    module => 'modules',
    check_all => 'check_all_plugins',
} }

has phase => (
    is => 'ro',
    isa => enum([qw(build release)]),
    default => 'release',
);

has modules => (
    isa => 'ArrayRef[Str]',
    traits => [ 'Array' ],
    handles => { _raw_modules => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has check_authordeps => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has check_all_plugins => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has check_all_prereqs => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has skip => (
    isa => 'ArrayRef[Str]',
    traits => [ 'Array' ],
    handles => { skip => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has fatal => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has index_base_url => (
    is => 'ro', isa => 'Str',
);

has run_under_travis => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ ? 1 : 0 } qw(check_all_plugins check_all_prereqs run_under_travis)),
        phase => $self->phase,
        skip => [ sort $self->skip ],
        modules => [ sort $self->_raw_modules ],
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub before_build
{
    my $self = shift;

    if (not $ENV{PROMPTIFSTALE_REALLY_RUN_TESTS}
        and $ENV{CONTINUOUS_INTEGRATION} and not $self->run_under_travis)
    {
        $self->log_debug('travis detected: skipping checks...');
        return;
    }

    if ($self->phase eq 'build')
    {
        my @extra_modules = $self->_modules_extra;
        my @modules = (
            @extra_modules,
            $self->check_authordeps ? $self->_authordeps : (),
            $self->check_all_plugins ? $self->_modules_plugin : (),
        );

        $self->log([ 'checking for stale %s...', join(', ',
            @extra_modules ? 'modules' : (),
            $self->check_authordeps ? 'authordeps' : (),
            $self->check_all_plugins ? 'plugins' : ())
        ]);
        $self->_check_modules(sort(uniq(@modules))) if @modules;
    }
}

sub after_build
{
    my $self = shift;

    return if not $ENV{PROMPTIFSTALE_REALLY_RUN_TESTS}
        and $ENV{CONTINUOUS_INTEGRATION} and not $self->run_under_travis;

    if ($self->phase eq 'build' and $self->check_all_prereqs)
    {
        if (my @modules = $self->_modules_prereq) {
            $self->log('checking for stale prerequisites...');
            $self->_check_modules(sort(uniq(@modules)));
        }
    }
}

sub before_release
{
    my $self = shift;
    if ($self->phase eq 'release')
    {
        my @extra_modules = $self->_modules_extra;
        my @modules = (
            @extra_modules,
            $self->check_authordeps ? $self->_authordeps : (),
            $self->check_all_plugins ? $self->_modules_plugin : (),
            $self->check_all_prereqs ? $self->_modules_prereq : (),
        );

        $self->log([ 'checking for stale %s...', join(', ',
            @extra_modules ? 'modules' : (),
            $self->check_authordeps ? 'authordeps' : (),
            $self->check_all_plugins ? 'plugins' : (),
            $self->check_all_prereqs ? 'prerequisites' : ())
        ]);

        $self->_check_modules(sort(uniq(@modules))) if @modules;
    }
}

# a package-scoped singleton variable that tracks the module names that have
# already been checked for, so other instances of this plugin do not duplicate
# the check.
my %already_checked;
sub __clear_already_checked { %already_checked = () } # for testing

# module name to absolute filename where the file can be found
my %module_to_filename;

sub stale_modules
{
    my ($self, @modules) = @_;

    require Module::CoreList;
    Module::CoreList->VERSION('5.20151213');

    my $cwd = getcwd();
    my $cwd_volume = path($cwd)->volume;

    my (@stale_modules, @errors);
    foreach my $module (sort(uniq(@modules)))
    {
        $already_checked{$module}++ if $module eq 'perl';
        next if $already_checked{$module};

        # these core modules should be indexed, but aren't
        if (any { $module eq $_ } qw(Config DB Errno Pod::Functions))
        {
            $self->log_debug([ 'skipping core module: %s', $module ]);
            $already_checked{$module}++;
            next;
        }

        my $path = Module::Metadata->find_module_by_name($module);
        if (not $path)
        {
            $already_checked{$module}++;
            push @stale_modules, $module;
            push @errors, $module . ' is not installed.';
            next;
        }

        $module_to_filename{$module} = $path;

        # ignore modules in the dist currently being built
        if (path($path)->volume eq $cwd_volume)
        {
            my $relative_path = path($path)->relative($cwd);
            if ($relative_path !~ m/^\.\./)
            {
                $already_checked{$module}++;
                $self->log_debug([ '%s provided locally (at %s); skipping version check',
                    $module, $relative_path->stringify ]);
                next;
            }
        }

        my $indexed_version = $self->_indexed_version($module, !!(@modules > 5));
        my $local_version = Module::Metadata->new_from_file($module_to_filename{$module})->version;

        $self->log_debug([ 'comparing indexed vs. local version for %s: indexed=%s; local version=%s',
            $module, sub { ($indexed_version // 'undef') . '' }, sub { ($local_version // 'undef') . '' } ]);

        if (not defined $indexed_version)
        {
            $already_checked{$module}++;
            push @stale_modules, $module;
            push @errors, $module . ' is not indexed.';
            next;
        }

        if (defined $local_version
            and $local_version < $indexed_version)
        {
            $already_checked{$module}++;

            if (Module::CoreList::is_core($module) and not $self->_is_duallifed($module))
            {
                $self->log_debug([ 'core module %s is indexed at version %s but you only have %s installed. You need to update your perl to get the latest version.',
                    $module, sub { ($indexed_version // 'undef') . '' }, sub { ($local_version // 'undef') . '' } ]);
            }
            else
            {
                push @stale_modules, $module;
                push @errors,
                    $module . ' is indexed at version ' . $indexed_version
                        . ' but you only have ' . $local_version . ' installed.';
            }

            next;
        }
    }

    return [ sort @stale_modules ], [ sort @errors ];
}

sub _check_modules
{
    my ($self, @modules) = @_;

    my ($stale_modules, $errors) = $self->stale_modules(@modules);

    return if not @$errors;

    my $message = @$errors > 1
        ? join("\n    ", 'Issues found:', @$errors)
        : $errors->[0];

    # just issue a warning if not being run interactively (e.g. |cpanm, travis)
    if (($ENV{CONTINUOUS_INTEGRATION} and not $ENV{HARNESS_ACTIVE})
        or not (-t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))))
    {
        $self->log($message . "\n" . 'To remedy, do: cpanm ' . join(' ', @$stale_modules));
        return;
    }

    my $continue;
    if ($self->fatal)
    {
        $self->log($message);
    }
    else
    {
        $continue = $self->zilla->chrome->prompt_yn(
            $message . (@$errors > 1 ? "\n" : ' ') . 'Continue anyway?',
            { default => 0 },
        );
    }

    $self->log_fatal('Aborting ' . $self->phase . "\n"
        . 'To remedy, do: cpanm ' . join(' ', @$stale_modules)) if not $continue;
}

has _authordeps => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _authordeps => 'elements' },
    lazy => 1,
    default => sub {
        my $self = shift;
        require Dist::Zilla::Util::AuthorDeps;
        Dist::Zilla::Util::AuthorDeps->VERSION(5.021);
        my @skip = $self->skip;
        [
            grep { my $module = $_; none { $module eq $_ } @skip }
            uniq(
                map { (%$_)[0] }
                    @{ Dist::Zilla::Util::AuthorDeps::extract_author_deps('.') }
            )
        ];
    },
);

has _modules_plugin => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _modules_plugin => 'elements' },
    lazy => 1,
    default => sub {
        my $self = shift;
        my @skip = $self->skip;
        [
            grep { my $module = $_; none { $module eq $_ } @skip }
            uniq(
                map { find_meta($_)->name } @{ $self->zilla->plugins }
            )
        ];
    },
);

has _modules_prereq => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _modules_prereq => 'elements' },
    lazy => 1,
    default => sub {
        my $self = shift;
        my $prereqs = $self->zilla->prereqs->as_string_hash;
        my @skip = $self->skip;
        [
            grep { my $module = $_; none { $module eq $_ } @skip }
            map { keys %$_ }
            grep { defined }
            map { @{$_}{qw(requires recommends suggests)} }
            grep { defined }
            values %$prereqs
        ];
    },
);

sub _modules_extra
{
    my $self = shift;
    my @skip = $self->skip;
    grep { my $module = $_; none { $module eq $_ } @skip } $self->_raw_modules;
}

# this ought to be in Module::CoreList -- TODO :)
sub _is_duallifed
{
    my ($self, $module) = @_;

    return if not Module::CoreList::is_core($module);

    # Module::CoreList doesn't tell us this information at all right now - for
    # blead-upstream dual-lifed modules, and non-dual-lifed modules, it
    # returns all the same data points. :(  Right now all we can do is query
    # the index and see what dist it belongs to -- luckily, it still lists the
    # cpan dist for dual-lifed modules that are more recent in core than on
    # CPAN (e.g. Carp in June 2014 is 1.34 in 5.20.0 but 1.3301 on cpan).

    my $url = 'http://cpanmetadb.plackperl.org/v1.0/package/' . $module;
    $self->log_debug([ 'fetching %s', $url ]);
    my $res = HTTP::Tiny->new->get($url);
    $self->log('could not query the index?'), return undef if not $res->{success};

    my $data = $res->{content};

    require HTTP::Headers;
    if (my $charset = HTTP::Headers->new(%{ $res->{headers} })->content_type_charset)
    {
        $data = Encode::decode($charset, $data, Encode::FB_CROAK);
    }
    $self->log_debug([ 'got response: %s', $data ]);

    my $payload = YAML::Tiny->read_string($data);

    $self->log('invalid payload returned?'), return undef unless $payload;
    $self->log_debug([ '%s not indexed', $module ]), return undef if not defined $payload->[0]{distfile};
    return CPAN::DistnameInfo->new($payload->[0]{distfile})->dist ne 'perl';
}

my $packages;
sub _indexed_version
{
    my ($self, $module, $combined) = @_;

    # we download 02packages if we have several modules to query at once, or
    # if we were given a different URL to use -- otherwise, we perform an API
    # hit for just this one module's data
    return $combined || $packages || $self->_has_index_base_url
        ? $self->_indexed_version_via_02packages($module)
        : $self->_indexed_version_via_query($module);
}

# I bet this is available somewhere as a module?
sub _indexed_version_via_query
{
    my ($self, $module) = @_;

    die 'should not be here - get 02packages instead' if $self->_has_index_base_url;
    die 'no module?' if not $module;

    my $url = 'http://cpanmetadb.plackperl.org/v1.0/package/' . $module;
    $self->log_debug([ 'fetching %s', $url ]);
    my $res = HTTP::Tiny->new->get($url);
    $self->log('could not query the index?'), return undef if not $res->{success};

    my $data = $res->{content};

    require HTTP::Headers;
    if (my $charset = HTTP::Headers->new(%{ $res->{headers} })->content_type_charset)
    {
        $data = Encode::decode($charset, $data, Encode::FB_CROAK);
    }
    $self->log_debug([ 'got response: %s', $data ]);

    my $payload = YAML::Tiny->read_string($data);

    $self->log('invalid payload returned?'), return undef unless $payload;
    $self->log_debug([ '%s not indexed', $module ]), return undef if not defined $payload->[0]{version};
    version->parse($payload->[0]{version});
}

# TODO: it would be AWESOME to provide this to multiple plugins via a role
# even better would be to save the file somewhere semi-permanent and
# keep it refreshed with a Last-Modified header - or share cpanm's copy?
sub _get_packages
{
    my $self = shift;
    return $packages if $packages;

    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    my $filename = '02packages.details.txt.gz';
    my $path = $tempdir->child($filename);

    # We don't set this via an attribute default because we want to
    # distinguish the case where this was not set at all.
    my $base = $self->index_base_url || $ENV{CPAN_INDEX_BASE_URL} || 'http://www.cpan.org';

    my $url = $base . '/modules/' . $filename;
    $self->log_debug([ 'fetching %s', $url ]);
    my $response = HTTP::Tiny->new->mirror($url, $path);
    $self->log('could not fetch the index - network down?'), return undef if not $response->{success};

    require Parse::CPAN::Packages::Fast;
    $packages = Parse::CPAN::Packages::Fast->new($path->stringify);
}

sub _has_index_base_url {
    my $self = shift;
    return $self->index_base_url || $ENV{CPAN_INDEX_BASE_URL};
}

sub _indexed_version_via_02packages
{
    my ($self, $module) = @_;

    die 'no module?' if not $module;
    my $packages = $self->_get_packages;
    return undef if not $packages;
    my $package = $packages->package($module);
    return undef if not $package;
    version->parse($package->version);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PromptIfStale - Check at build/release time if modules are out of date

=head1 VERSION

version 0.054

=head1 SYNOPSIS

In your F<dist.ini>:

    [PromptIfStale]
    phase = build
    module = Dist::Zilla
    module = Dist::Zilla::PluginBundle::Author::ME

or:

    [PromptIfStale]
    check_all_plugins = 1

=head1 DESCRIPTION

C<[PromptIfStale]> is a C<BeforeBuild> or C<BeforeRelease> plugin that compares the
locally-installed version of a module(s) with the latest indexed version,
prompting to abort the build process if a discrepancy is found.

Note that there is no effect on the built dist -- all actions are taken at
build time.

=head1 CONFIGURATION OPTIONS

=head2 C<phase>

Indicates whether the checks are performed at I<build> or I<release> time
(defaults to I<release>).

(Remember that you can use different settings for different phases by employing
this plugin twice, with different names.)

=head2 C<module>

The name of a module to check for. Can be provided more than once.

=head2 C<check_authordeps>

=for stopwords authordeps

A boolean, defaulting to false, indicating that all authordeps in F<dist.ini>
(like what is done by C<< dzil authordeps >>) should be checked.

As long as this option is not explicitly set to false, a check is always made
for authordeps being installed (but the indexed version is not checked). This
serves as a fast way to guard against a build blowing up later through the
inadvertent lack of fulfillment of an explicit C<< ; authordep >> declaration.

=head2 C<check_all_plugins>

A boolean, defaulting to false, indicating that all plugins being used to
build this distribution should be checked.

=head2 C<check_all_prereqs>

A boolean, defaulting to false, indicating that all prerequisites in the
distribution metadata should be checked. The modules are a merged list taken
from all phases (C<configure>, C<build>, C<runtime>, C<test> and C<develop>) ,
and the C<requires>, C<recommends> and C<suggests> types.

=head2 C<skip>

The name of a module to exempt from checking. Can be provided more than once.

=head2 C<fatal>

A boolean, defaulting to false, indicating that missing prereqs will result in
an immediate abort of the build/release process, without prompting.

=head2 C<index_base_url>

=for stopwords darkpan

When provided, uses this base URL to fetch F<02packages.details.txt.gz>
instead of the default C<http://www.cpan.org>.  Use this when your
distribution uses prerequisites found only in your darkpan-like server.

You can also set this temporary from the command line by setting the
C<CPAN_INDEX_BASE_URL> environment variable.

=head2 C<run_under_travis>

It is possible to detect when a build is being run via L<Travis Continuous Integration|https://travis-ci.org/>.
Since version 0.035, Travis builds act like other non-interactive builds, where missing modules result in a warning
instead of a prompt. As of version 0.050, stale checks are only performed for the build phase on Travis builds when
C<run_under_travis> is set to a true value.

The default value is false.

=for Pod::Coverage mvp_multivalue_args mvp_aliases before_build after_build before_release

=head1 METHODS

=head2 stale_modules

Given a list of modules to check, returns

=over 4

=item *

a list reference of modules that are stale (not installed or the version is not at least the latest indexed version

=item *

a list reference of error messages describing the issues found

=back

=head1 SEE ALSO

=over 4

=item *

the L<[EnsureNotStale]|Dist::Zilla::Plugin::EnsureNotStale> plugin in this distribution

=item *

the L<dzil stale|Dist::Zilla::App::Command::stale> command in this distribution

=item *

L<Dist::Zilla::Plugin::Prereqs::MatchInstalled>, L<Dist::Zilla::Plugin::Prereqs::MatchInstalled::All>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PromptIfStale>
(or L<bug-Dist-Zilla-Plugin-PromptIfStale@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-PromptIfStale@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Dave Rolsky Olivier Mengué

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
