#
# This file is part of Dist-Zilla-Plugin-Test-Compile
#
# This software is copyright (c) 2009 by Jérôme Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
package Dist::Zilla::Plugin::Test::Compile; # git description: v2.056-4-g5817fa6
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Common tests to check syntax of your modules, using only core modules
# KEYWORDS: plugin test compile verify validate load modules scripts

our $VERSION = '2.057';

use Moose;
use Path::Tiny;
use Sub::Exporter::ForMethods 'method_installer'; # method_installer returns a sub.
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use Dist::Zilla::Dist::Builder ();

with (
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        method          => 'found_module_files',
        finder_arg_names => [ 'module_finder' ],
        default_finders => [ ':InstallModules' ],
    },
    'Dist::Zilla::Role::FileFinderUser' => {
        method          => 'found_script_files',
        finder_arg_names => [ 'script_finder' ],
        default_finders => [
            eval { Dist::Zilla::Dist::Builder->VERSION('5.038'); 1 }
                ? ':PerlExecFiles'
                : ':ExecFiles'
        ],
    },
    'Dist::Zilla::Role::PrereqSource',
);

use Moose::Util::TypeConstraints qw(enum role_type);
use namespace::autoclean;

# -- attributes

has fake_home     => ( is=>'ro', isa=>'Bool', default=>0 );
has needs_display => ( is=>'ro', isa=>'Bool', default=>0 );
has fail_on_warning => ( is=>'ro', isa=>enum([qw(none author all)]), default=>'author' );
has bail_out_on_fail => ( is=>'ro', isa=>'Bool', default=>0 );
has xt_mode => ( is=>'ro', isa=>'Bool', default=>0 );

has filename => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { return ($_[0]->xt_mode ? 'xt/author' : 't') . '/00-compile.t' },
);

has phase => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { return $_[0]->xt_mode ? 'develop' : 'test' },
);

sub mvp_multivalue_args { qw(skips files switches) }
sub mvp_aliases { return { skip => 'skips', file => 'files', switch => 'switches' } }

has skips => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { skips => 'sort' },
    lazy => 1,
    default => sub { [] },
);

has files => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { files => 'sort' },
    lazy => 1,
    default => sub { [] },
);

has switches => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { switches => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has _test_more_version => (
    is => 'ro', isa => 'Str',
    init_arg => undef,
    lazy => 1,
    default => sub { shift->bail_out_on_fail ? '0.94' : '0' },
);

# note that these two attributes could conceivably be settable via dist.ini,
# to avoid us using filefinders at all.
has _module_filenames  => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _module_filenames => 'sort' },
    lazy => 1,
    default => sub { [ map { $_->name } @{shift->found_module_files} ] },
);
has _script_filenames => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { _script_filenames => 'sort' },
    lazy => 1,
    default => sub { [ map { $_->name } @{shift->found_script_files} ] },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        module_finder => [ sort @{ $self->module_finder } ],
        script_finder => [ sort @{ $self->script_finder } ],
        skips => [ sort $self->skips ],
        (map { $_ => $self->$_ ? 1 : 0 } qw(fake_home needs_display bail_out_on_fail)),
        (map { $_ => $self->$_ } qw(filename fail_on_warning bail_out_on_fail phase)),
        switch => [ $self->switches ],
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

sub register_prereqs
{
    my $self = shift;

    return unless $self->phase;

    $self->zilla->register_prereqs(
        {
            phase => $self->phase,
            type  => 'requires',
        },
        'Test::More' => $self->_test_more_version,
        'File::Spec' => '0',
        'IPC::Open3' => 0,
        'IO::Handle' => 0,
        $self->fake_home ? ( 'File::Temp' => '0' ) : (),
    );
}

has _file => (
    is => 'rw', isa => role_type('Dist::Zilla::Role::File'),
);

sub gather_files
{
    my $self = shift;

    require Dist::Zilla::File::InMemory;

    $self->add_file( $self->_file(
        Dist::Zilla::File::InMemory->new(
            name => $self->filename,
            content => ${$self->section_data('test-compile')},
        ))
    );
    return;
}

sub munge_file
{
    my ($self, $file) = @_;

    return unless $file == $self->_file;

    my @skips = map {; qr/$_/ } $self->skips;

    my @more_files = $self->files;

    # we strip the leading lib/, and convert win32 \ to /, so the %INC entry
    # is correct - to avoid potentially loading the file again later
    my @module_filenames = map { path($_)->relative('lib')->stringify } $self->_module_filenames;
    push @module_filenames, grep { /\.pm/i } @more_files if @more_files;

    @module_filenames = grep {
        (my $module = $_) =~ s{[/\\]}{::}g;
        $module =~ s/\.pm$//;
        not grep { $module =~ $_ } @skips
    } @module_filenames if @skips;

    # pod never returns true when loaded
    @module_filenames = grep { !/\.pod$/ } @module_filenames;

    my @script_filenames = $self->_script_filenames;
    push @script_filenames, grep { !/\.pm/i } @more_files if @more_files;

    $self->log_debug('adding module ' . $_) foreach @module_filenames;
    $self->log_debug('adding script ' . $_) foreach @script_filenames;

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                plugin => \$self,
                test_more_version => \($self->_test_more_version),
                module_filenames => \@module_filenames,
                script_filenames => \@script_filenames,
                fake_home => \($self->fake_home),
                needs_display => \($self->needs_display),
                bail_out_on_fail => \($self->bail_out_on_fail),
                fail_on_warning => \(
                    $self->fail_on_warning eq 'author' && $self->filename =~ m{^xt/author/}
                    ? 'all'
                    : $self->fail_on_warning),
                switches => \[$self->switches],
            }
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;

#pod =pod
#pod
#pod =for Pod::Coverage::TrustPod
#pod     mvp_multivalue_args
#pod     mvp_aliases
#pod     register_prereqs
#pod     gather_files
#pod     munge_file
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [Test::Compile]
#pod     skip      = Test$
#pod     fake_home = 1
#pod     needs_display = 1
#pod     fail_on_warning = author
#pod     bail_out_on_fail = 1
#pod     switch = -M-warnings=numeric    ; like "no warnings 'numeric'
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a L<Dist::Zilla> plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
#pod providing a test file (configurable, defaulting to F<t/00-compile.t>).
#pod
#pod This test will find all modules and scripts in your distribution, and try to
#pod compile them one by one. This means it's a bit slower than loading them
#pod all at once, but it will catch more errors.
#pod
#pod The generated test is guaranteed to only depend on modules that are available
#pod in core.  Most options only require perl 5.6.2; the C<bail_out_on_fail> option
#pod requires the version of L<Test::More> that shipped with perl 5.12 (but the
#pod test still runs on perl 5.6).
#pod
#pod This plugin accepts the following options:
#pod
#pod =head1 CONFIGURATION OPTIONS
#pod
#pod =head2 C<filename>
#pod
#pod The name of the generated file. Defaults to F<t/00-compile.t>
#pod
#pod =head2 C<phase>
#pod
#pod The phase for which to register prerequisites. Defaults
#pod to C<test>.  Setting this to a false value will disable prerequisite
#pod registration.
#pod
#pod =head2 C<skip>
#pod
#pod A regex to skip compile test for B<modules> matching it. The
#pod match is done against the module name (C<Foo::Bar>), not the file path
#pod (F<lib/Foo/Bar.pm>).  This option can be repeated to specify multiple regexes.
#pod
#pod =head2 C<file>
#pod
#pod A filename to also test, in addition to any files found
#pod earlier.  It will be tested as a module if it ends with C<.pm> or C<.PM>,
#pod and as a script otherwise.
#pod Module filenames should be relative to F<lib>; others should be relative to
#pod the base of the repository.
#pod This option can be repeated to specify multiple additional files.
#pod
#pod =head2 C<fake_home>
#pod
#pod =for stopwords cpantesters
#pod
#pod A boolean to indicate whether to fake C<< $ENV{HOME} >>.
#pod This may be needed if your module unilaterally creates stuff in the user's home directory:
#pod indeed, some cpantesters will smoke test your distribution with a read-only home
#pod directory. Defaults to false.
#pod
#pod =head2 C<needs_display>
#pod
#pod A boolean to indicate whether to skip the compile test
#pod on non-Win32 systems when C<< $ENV{DISPLAY} >> is not set. Defaults to false.
#pod
#pod =head2 C<fail_on_warning>
#pod
#pod A string to indicate when to add a test for
#pod warnings during compilation checks. Possible values are:
#pod
#pod =over 4
#pod
#pod =item * C<none>: do not test for warnings
#pod
#pod =item * C<author>: test for warnings only when AUTHOR_TESTING is set
#pod (default, and recommended)
#pod
#pod =item * C<all>: always test for warnings (not recommended, as this can prevent
#pod installation of modules when upstream dependencies exhibit warnings in a new
#pod Perl release)
#pod
#pod =back
#pod
#pod =head2 C<bail_out_on_fail>
#pod
#pod A boolean to indicate whether the test will BAIL_OUT
#pod of all subsequent tests when compilation failures are encountered. Defaults to false.
#pod
#pod =head2 C<module_finder>
#pod
#pod =for stopwords FileFinder
#pod
#pod This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
#pod modules to check.  The default value is C<:InstallModules>; this option can be
#pod used more than once.  F<.pod> files are always skipped.
#pod
#pod Other predefined finders are listed in
#pod L<Dist::Zilla::Role::FileFinderUser/default_finders>.
#pod You can define your own with the
#pod L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
#pod L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.
#pod
#pod =head2 C<script_finder>
#pod
#pod =for stopwords executables
#pod
#pod Just like C<module_finder>, but for finding scripts.  The default value is
#pod C<:PerlExecFiles> (when available; otherwise C<:ExecFiles>)
#pod -- see also L<Dist::Zilla::Plugin::ExecDir>, to make sure these
#pod files are properly marked as executables for the installer.
#pod
#pod =head2 C<xt_mode>
#pod
#pod When true, the default C<filename> becomes F<xt/author/00-compile.t> and the
#pod default C<dependency> phase becomes C<develop>.
#pod
#pod =head2 C<switch>
#pod
#pod Use this option to pass a command-line switch (e.g. C<-d:Confess>, C<-M-warnings=numeric>) to the command that
#pod tests the module or script. Can be used more than once.  See L<perlrun> for more on constructing these switches.
#pod
#pod =head1 RUNTIME ENVIRONMENT OPTIONS
#pod
#pod If the environment variable C<$PERL_COMPILE_TEST_DEBUG> is set to a true option when the test is run, the command
#pod to test each file will be printed as a C<diag>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Test::NeedsDisplay>
#pod * L<Test::Script>
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Compile - Common tests to check syntax of your modules, using only core modules

=head1 VERSION

version 2.057

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Compile]
    skip      = Test$
    fake_home = 1
    needs_display = 1
    fail_on_warning = author
    bail_out_on_fail = 1
    switch = -M-warnings=numeric    ; like "no warnings 'numeric'

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
providing a test file (configurable, defaulting to F<t/00-compile.t>).

This test will find all modules and scripts in your distribution, and try to
compile them one by one. This means it's a bit slower than loading them
all at once, but it will catch more errors.

The generated test is guaranteed to only depend on modules that are available
in core.  Most options only require perl 5.6.2; the C<bail_out_on_fail> option
requires the version of L<Test::More> that shipped with perl 5.12 (but the
test still runs on perl 5.6).

This plugin accepts the following options:

=for Pod::Coverage::TrustPod mvp_multivalue_args
    mvp_aliases
    register_prereqs
    gather_files
    munge_file

=head1 CONFIGURATION OPTIONS

=head2 C<filename>

The name of the generated file. Defaults to F<t/00-compile.t>

=head2 C<phase>

The phase for which to register prerequisites. Defaults
to C<test>.  Setting this to a false value will disable prerequisite
registration.

=head2 C<skip>

A regex to skip compile test for B<modules> matching it. The
match is done against the module name (C<Foo::Bar>), not the file path
(F<lib/Foo/Bar.pm>).  This option can be repeated to specify multiple regexes.

=head2 C<file>

A filename to also test, in addition to any files found
earlier.  It will be tested as a module if it ends with C<.pm> or C<.PM>,
and as a script otherwise.
Module filenames should be relative to F<lib>; others should be relative to
the base of the repository.
This option can be repeated to specify multiple additional files.

=head2 C<fake_home>

=for stopwords cpantesters

A boolean to indicate whether to fake C<< $ENV{HOME} >>.
This may be needed if your module unilaterally creates stuff in the user's home directory:
indeed, some cpantesters will smoke test your distribution with a read-only home
directory. Defaults to false.

=head2 C<needs_display>

A boolean to indicate whether to skip the compile test
on non-Win32 systems when C<< $ENV{DISPLAY} >> is not set. Defaults to false.

=head2 C<fail_on_warning>

A string to indicate when to add a test for
warnings during compilation checks. Possible values are:

=over 4

=item * C<none>: do not test for warnings

=item * C<author>: test for warnings only when AUTHOR_TESTING is set
(default, and recommended)

=item * C<all>: always test for warnings (not recommended, as this can prevent
installation of modules when upstream dependencies exhibit warnings in a new
Perl release)

=back

=head2 C<bail_out_on_fail>

A boolean to indicate whether the test will BAIL_OUT
of all subsequent tests when compilation failures are encountered. Defaults to false.

=head2 C<module_finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
modules to check.  The default value is C<:InstallModules>; this option can be
used more than once.  F<.pod> files are always skipped.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.

=head2 C<script_finder>

=for stopwords executables

Just like C<module_finder>, but for finding scripts.  The default value is
C<:PerlExecFiles> (when available; otherwise C<:ExecFiles>)
-- see also L<Dist::Zilla::Plugin::ExecDir>, to make sure these
files are properly marked as executables for the installer.

=head2 C<xt_mode>

When true, the default C<filename> becomes F<xt/author/00-compile.t> and the
default C<dependency> phase becomes C<develop>.

=head2 C<switch>

Use this option to pass a command-line switch (e.g. C<-d:Confess>, C<-M-warnings=numeric>) to the command that
tests the module or script. Can be used more than once.  See L<perlrun> for more on constructing these switches.

=head1 RUNTIME ENVIRONMENT OPTIONS

If the environment variable C<$PERL_COMPILE_TEST_DEBUG> is set to a true option when the test is run, the command
to test each file will be printed as a C<diag>.

=head1 SEE ALSO

=over 4

=item *

L<Test::NeedsDisplay>

=item *

L<Test::Script>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Compile>
(or L<bug-Dist-Zilla-Plugin-Test-Compile@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Compile@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Ahmad M. Zawawi Olivier Mengué Kent Fredric Jesse Luehrs David Golden Randy Stauner Harley Pig Graham Knop fayland Peter Shangov Chris Weyl Ricardo SIGNES Marcel Gruenauer

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

David Golden <dagolden@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Harley Pig <harleypig@gmail.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

fayland <fayland@gmail.com>

=item *

Peter Shangov <pshangov@yahoo.com>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jérôme Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ test-compile ]___
use 5.006;
use strict;
use warnings;

# this test was generated with {{ ref $plugin }} {{ $plugin->VERSION }}

use Test::More{{ $test_more_version ? " $test_more_version" : '' }};
{{
    $needs_display ? <<'CODE' : ''
# Skip all tests if you need a display for this test and $ENV{DISPLAY} is not set
if (not $ENV{DISPLAY} and $^O ne 'MSWin32') {
    plan skip_all => 'Needs DISPLAY';
}
CODE
}}
plan tests => {{
    my $count = @module_filenames + @script_filenames;
    $count += 1 if $fail_on_warning eq 'all';
    $count .= ' + ($ENV{AUTHOR_TESTING} ? 1 : 0)' if $fail_on_warning eq 'author';
    $count;
}};

my @module_files = (
{{ join(",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } sort @module_filenames) }}
);

{{
    @script_filenames
        ? 'my @scripts = (' . "\n"
          . join(",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } sort @script_filenames)
          . "\n" . ');'
        : ''
}}

{{
    $fake_home ? <<'CODE' : '# no fake home requested';
# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );
CODE
}}

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
{{ @$switches ? '    ' . join(' ', map { q{'} . $_ . q{',} } @$switches) . "\n" : '' }});

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

{{
    @script_filenames ? <<'CODE' : '';
foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }

CODE
}}

{{
($fail_on_warning ne 'none'
    ? q{is(scalar(@warnings), 0, 'no warnings found')} . "\n"
        . q{    or diag 'got warnings: ', }
        . ( $test_more_version > 0.82
            ? q{explain(\@warnings)}
            : q{( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) )}
          )
    : '# no warning checks')
.
($fail_on_warning eq 'author'
    ? ' if $ENV{AUTHOR_TESTING};'
    : ';')
}}

{{
$bail_out_on_fail
    ? 'BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;'
    : '';
}}
