package Dist::Maker::Template::DefaultMB;
use utf8;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker::Util qw(run_command);

extends 'Dist::Maker::Base';
with    'Dist::Maker::Template';

sub dist_init {
    my($self, $meta) = @_;
    chdir $meta->{distdir} or return;

    eval {
        $self->run_command($^X, 'Build.PL');
        $self->run_command('./Build', 'distmeta');
        $self->run_command('./Build', 'manifest');
    };
    chdir '..';
    die $@ if $@;
    return;
}

sub distribution {
    # empty expression <: :> is used
    # in order to avoid to confuse PAUSE indexers
    return <<'DIST';
@@ Build.PL
#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license        => 'perl',
    dynamic_config => 0,
    # dist_abstract  => 'XXX',

    build_requires     => {
        'Test::More'     => '0.98',
        'Test::Requires' => '0.06',
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        perl         => '5.008001',
        # 'parent'     => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => '<: $dist.path :>',
    module_name => '<: $dist.module :>',

    # script_files => [''],

    test_files           => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme      => 1,
);
$build->create_build_script;

@@ Changes

Revision history for Perl extension <: $dist.module :>

NEXT <<SET RELEASE DATE HERE>>
    - original version; created by <: $software // 'Dist::Maker' :>
      at <: localtime() :>.

@@ .gitignore
<: $dist :>-*
.*
!.git*
!.shipit
!.dimconfig
inc/
*.o
*.obj
*.bs
*.def
Build
_build/*
*blib
MYMETA.*
*.out
*.bak
*.old
*~
*.swp
ppport.h
nytprof*
cover_db*
*.gcda
*.gcno
*.gcov
*.stackdump
: block gitignore { }
@@ .shipit
steps = FindVersion, ChangeAllVersions, CheckChangeLog, DistTest, Commit, Tag, MakeDist, UploadCPAN

git.tagpattern = %v
git.push_to = origin

CheckChangeLog.files = Changes

@@ MANIFEST.SKIP
#!include_default

# skip author's files
\bauthor\b

\.bs$
\.o(?:|bj|ld|ut)$
^nytprof
^MYMETA\.

: block manifest_skip { }
@@ lib/<: $dist.path :>.pm
package <: $dist.module :>;
use 5.008_001;
: block module_header -> {
use strict;
use warnings;
: }

our $<: :>VERSION = '<: $module.initial_version :>';

: block module_code -> { }

: block module_footer -> {
1;
: }
__END__

<: :>=head1 NAME

<: $dist.module :> - Perl extension to do something

=head1 VERSION

This document describes <: $dist.module :> version <: $module.initial_version :>.

=head1 SYNOPSIS

: block synopsis {
    use <: $dist.module :>;
: }

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<: $user.name :> E<lt><: $user.email :>E<gt>

=head1 LICENSE AND COPYRIGHT

: block copyright -> {
Copyright (c) <: localtime().year :>, <: $user.name :>. All rights reserved.
: }

: block license -> {
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
: }

=cut

@@ t/000_load.t
#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok '<: $dist.module :>';
}

: block load_t_testing_info {
diag "Testing <: $dist.module :>/$<: $dist.module :>::VERSION";
: }
@@ t/001_basic.t
#!perl -w
use strict;
use Test::More;

use <: $dist.module :>;

# test <: $dist.module :> here
: block basic_t_tests -> {
pass;
: }

done_testing;
@@ xt/pod.t
#!perl -w
use strict;
use Test::More;
eval q{use Test::Pod 1.14};
plan skip_all => 'Test::Pod 1.14 required for testing POD'
    if $@;

all_pod_files_ok();

@@ xt/podspell.t
#!perl -w
use strict;
use Test::More;

eval q{ use Test::Spelling };
plan skip_all => q{Test::Spelling is not available.}
    if $@;

my @stopwords;
while(my $line = <DATA>) {
    $line =~ s/ \# [^\n]+ //xms;
    push @stopwords, $line =~ /(\w+)/g;
}
add_stopwords(@stopwords);

$ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
<: $user.name :>
<: $user.email :>
<: $dist.module :>

# computer terms
API
APIs
arrayrefs
arity
Changelog
codebase
committer
committers
compat
cpan
datetimes
dec
definedness
destructor
destructors
destructuring
dev
DWIM
GitHub
hashrefs
hotspots
immutabilize
immutabilizes
immutabilized
inline
inlines
invocant
invocant's
irc
IRC
isa
JSON
login
namespace
namespaced
namespaces
namespacing
OO
OOP
ORM
overridable
parameterizable
parameterization
parameterize
parameterized
parameterizes
params
pluggable
prechecking
prepends
rebase
rebased
rebasing
reblesses
refactored
refactoring
rethrows
RT
runtime
serializer
stacktrace
subclassable
subname
subtyping
TODO
unblessed
unexport
unimporting
Unported
unsets
unsettable
utils
whitelist
Whitelist
workflow
XS
MacOS
MacOSX
CLI
HTTP

versa # vice versa
ish   # something-ish
ness  # something-ness
pre   # pre-something
maint # co-maint

: block podcoverage_t {
@@ xt/podcoverage.t
#!perl -w
use Test::More;
eval q{use Test::Pod::Coverage 1.04};
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage'
    if $@;

all_pod_coverage_ok({
    also_private => [qw(unimport BUILD DEMOLISH init_meta)],
});
: } # podcoverage_t

: block podsynopsis_t {
@@ xt/podsynopsis.t
#!perl -w
use strict;
use Test::More;
eval q{use Test::Synopsis};
plan skip_all => 'Test::Synopsis required for testing SYNOPSIS'
    if $@;
all_synopsis_ok();
: } # podsynopsis_t

: block perlcritic_t {
@@ xt/perlcritic.t
use strict;
use Test::More;
eval q{
    use Perl::Critic 1.105;
    use Test::Perl::Critic -profile => \do { local $/; <DATA> };
};
plan skip_all => "Test::Perl::Critic is not available." if $@;
all_critic_ok('lib');
__DATA__

exclude=ProhibitStringyEval ProhibitExplicitReturnUndef RequireBarewordIncludes

[TestingAndDebugging::ProhibitNoStrict]
allow=refs

[TestingAndDebugging::RequireUseStrict]
: my $mooselike = [
:    "Mouse", "Mouse::Role", "Mouse::Exporter", "Mouse::Util",
:    "Mouse::Util::TypeConstraints",
:    "Moose", "Moose::Role", "Moose::Exporter",
:    "Moose::Util::TypeConstraints",
:    "Any::Moose"];
equivalent_modules = <: $mooselike.join(" ") :>

[TestingAndDebugging::RequireUseWarnings]
equivalent_modules = <: $mooselike.join(" ") :>
: } # perlcritic_t

@@ author/requires.cpanm
# for <: $dist :>
# Makefile.PL
: block author_requires_cpanm_configure_requires -> {
Module::Install
Module::Install::AuthorTests
Module::Install::Repository
: }

# author's tests
: block author_requires_cpanm_test_requires -> {
Test::Pod
Test::Pod::Coverage
Test::Spelling
Test::Perl::Critic
Test::Synopsis
: }

# Release tools
: block author_requires_cpanm_release_tools -> {
ShipIt
ShipIt::Step::ChangeAllVersions
CPAN::Uploader
: }

@@ EXTRA_FILES
: # hook spaces to add files
: block extra_files -> { }
DIST
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::Default - The default distribution template

=cut
