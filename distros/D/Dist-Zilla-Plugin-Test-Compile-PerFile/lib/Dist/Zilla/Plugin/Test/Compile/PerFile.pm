use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Compile::PerFile;

our $VERSION = '0.004000';

# ABSTRACT: Create a single .t for each compilable file in a distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use B ();

BEGIN {
  ## no critic (ProhibitCallsToUnexportedSubs)
  *_HAVE_PERLSTRING = defined &B::perlstring ? sub() { 1 } : sub() { 0 };
}
use Moose qw( with around has );
use MooseX::LazyRequire;

with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::TextTemplate';

use Path::Tiny qw(path);
use File::ShareDir qw(dist_dir);
use Moose::Util::TypeConstraints qw(enum);

## no critic (ProhibitPackageVars)
our %path_translators;

$path_translators{base64_filter} = sub {
  my ($file) = @_;
  $file =~ s/[^-[:alnum:]_]+/_/msxg;
  return $file;
};

$path_translators{mimic_source} = sub {
  my ($file) = @_;
  return $file;
};

##
#
# This really example code, because this notation is so unrecommended, as Colons in file names
# are highly non-portable.
#
# Edit this to = 1 if you're 100% serious you want this.
#
##

if (0) {
  $path_translators{module_names} = sub {
    my ($file) = @_;
    return $file if $file !~ /\Alib\//msx;
    return $file if $file !~ /[.]pm\z/msx;
    $file =~ s{\Alib/}{}msx;
    $file =~ s{[.]pm\z}{}msx;
    $file =~ s{/}{::}msxg;
    $file = 'module/' . $file;
    return $file;
  };
}

our %templates = ();

{
  my $dist_dir     = dist_dir('Dist-Zilla-Plugin-Test-Compile-PerFile');
  my $template_dir = path($dist_dir);
  for my $file ( $template_dir->children ) {
    next if $file =~ /\A[.]/msx;    # Skip hidden files
    next if -d $file;               # Skip directories
    $templates{ $file->basename } = $file;
  }
}

around mvp_multivalue_args => sub {
  my ( $orig, $self, @args ) = @_;
  return ( 'finder', 'file', 'skip', $self->$orig(@args) );
};

around mvp_aliases => sub {
  my ( $orig, $self, @args ) = @_;
  my $hash = $self->$orig(@args);
  $hash = {} if not defined $hash;
  $hash->{files} = 'file';
  return $hash;
};

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{finder}          = $self->finder if $self->has_finder;
  $localconf->{xt_mode}         = $self->xt_mode;
  $localconf->{prefix}          = $self->prefix;
  $localconf->{file}            = [ sort @{ $self->file } ];
  $localconf->{skip}            = $self->skip;
  $localconf->{path_translator} = $self->path_translator;
  $localconf->{test_template}   = $self->test_template;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};









sub BUILD {
  my ($self) = @_;
  return if $self->has_file;
  return if $self->has_finder;
  $self->_finder_objects;
  return;
}













has xt_mode => ( is => ro =>, isa => Bool =>, lazy_build => 1 );













has prefix => ( is => ro =>, isa => Str =>, lazy_build => 1 );


















has file => ( is => ro =>, isa => 'ArrayRef[Str]', lazy_build => 1, );











has skip => ( is => ro =>, isa => 'ArrayRef[Str]', lazy_build => 1, );














has finder => ( is => ro =>, isa => 'ArrayRef[Str]', lazy_required => 1, predicate => 'has_finder' );



































































has path_translator => ( is => ro =>, isa => enum( [ sort keys %path_translators ] ), lazy_build => 1 );
































has test_template => ( is => ro =>, isa => enum( [ sort keys %templates ] ), lazy_build => 1 );

sub _quoted {
  no warnings 'numeric';
  ## no critic (ProhibitBitwiseOperators,ProhibitCallsToUndeclaredSubs)
  ## no critic (ProhibitCallsToUnexportedSubs,ProhibitUnusedVarsStricter)
  !defined $_[0]
    ? 'undef()'
    : ( length( ( my $dummy = q[] ) & $_[0] ) && 0 + $_[0] eq $_[0] && $_[0] * 0 == 0 ) ? $_[0]    # numeric detection
    : _HAVE_PERLSTRING ? B::perlstring( $_[0] )
    :                    qq["\Q$_[0]\E"];
}

sub _generate_file {
  my ( $self, $name, $file ) = @_;
  my $relpath = ( $file =~ /\Alib\/(.*)\z/msx ? $1 : q[./] . $file );

  $self->log_debug("relpath for $file is: $relpath");

  my $code = sub {
    return $self->fill_in_string(
      $self->_test_template_content,
      {
        file              => $file,
        relpath           => $relpath,
        plugin_module     => $self->meta->name,
        plugin_name       => $self->plugin_name,
        plugin_version    => ( $self->VERSION ? $self->VERSION : '<self>' ),
        test_more_version => '0.89',
        quoted            => \&_quoted,
      },
    );
  };
  return Dist::Zilla::File::FromCode->new(
    name             => $name,
    code_return_type => 'text',
    code             => $code,
  );
}











sub gather_files {
  my ($self) = @_;
  require Dist::Zilla::File::FromCode;

  my $prefix = $self->prefix;
  $prefix =~ s{/?\z}{/}msx;

  my $translator = $self->_path_translator;

  if ( not @{ $self->file } ) {
    $self->log_debug('Did not find any files to add tests for, did you add any files yet?');
    return;
  }
  my $skiplist = {};
  for my $skip ( @{ $self->skip } ) {
    $skiplist->{$skip} = 1;
  }
  for my $file ( @{ $self->file } ) {
    if ( exists $skiplist->{$file} ) {
      $self->log_debug("Skipping compile test generation for $file");
      next;
    }
    my $name = sprintf q[%s%s.t], $prefix, $translator->($file);
    $self->log_debug("Adding $name for $file");
    $self->add_file( $self->_generate_file( $name, $file ) );
  }
  return;
}

has _path_translator       => ( is => ro =>, isa => CodeRef =>, lazy_build => 1, init_arg => undef );
has _test_template         => ( is => ro =>, isa => Defined =>, lazy_build => 1, init_arg => undef );
has _test_template_content => ( is => ro =>, isa => Defined =>, lazy_build => 1, init_arg => undef );
has _finder_objects => ( is => ro =>, isa => 'ArrayRef', lazy_build => 1, init_arg => undef );

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;

sub _build_xt_mode {
  return;
}

sub _build_prefix {
  my ($self) = @_;
  if ( $self->xt_mode ) {
    return 'xt/author/00-compile';
  }
  return 't/00-compile';
}

sub _build_path_translator {
  my ( undef, ) = @_;
  return 'base64_filter';
}

sub _build__path_translator {
  my ($self) = @_;
  my $translator = $self->path_translator;
  return $path_translators{$translator};
}

sub _build_test_template {
  return '01-basic.t.tpl';
}

sub _build__test_template {
  my ($self) = @_;
  my $template = $self->test_template;
  return $templates{$template};
}

sub _build__test_template_content {
  my ($self) = @_;
  my $template = $self->_test_template;
  return $template->slurp_utf8;
}

sub _build_file {
  my ($self) = @_;
  return [ map { $_->name } @{ $self->_found_files } ];
}

sub _build_skip {
  return [];
}

sub _build__finder_objects {
  my ($self) = @_;
  if ( $self->has_finder ) {
    my @out;
    for my $finder ( @{ $self->finder } ) {
      my $plugin = $self->zilla->plugin_named($finder);
      if ( not $plugin ) {
        $self->log_fatal("no plugin named $finder found");
      }
      if ( not $plugin->does('Dist::Zilla::Role::FileFinder') ) {
        $self->log_fatal("plugin $finder is not a FileFinder");
      }
      push @out, $plugin;
    }
    return \@out;
  }
  return [ $self->_vivify_installmodules_pm_finder ];
}

sub _vivify_installmodules_pm_finder {
  my ($self) = @_;
  my $name = $self->plugin_name;
  $name .= '/AUTOVIV/:InstallModulesPM';
  if ( my $plugin = $self->zilla->plugin_named($name) ) {
    return $plugin;
  }
  require Dist::Zilla::Plugin::FinderCode;
  my $plugin = Dist::Zilla::Plugin::FinderCode->new(
    {
      plugin_name => $name,
      zilla       => $self->zilla,
      style       => 'grep',
      code        => sub {
        my ( $file, $self ) = @_;
        local $_ = $file->name;
        ## no critic (RegularExpressions)
        return 1 if m{\Alib/} and m{\.(pm)$};
        return 1 if $_ eq $self->zilla->main_module;
        return;
      },
    },
  );
  push @{ $self->zilla->plugins }, $plugin;
  return $plugin;
}

sub _found_files {
  my ($self) = @_;
  my %by_name;
  for my $plugin ( @{ $self->_finder_objects } ) {
    for my $file ( @{ $plugin->find_files } ) {
      $by_name{ $file->name } = $file;
    }
  }
  return [ values %by_name ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Compile::PerFile - Create a single .t for each compilable file in a distribution

=head1 VERSION

version 0.004000

=head1 SYNOPSIS

    ; in dist.ini
    [Test::Compile::PerFile]

=head1 DESCRIPTION

This module is inspired by its earlier sibling L<< C<[Test::Compile]>|Dist::Zilla::Plugin::Test::Compile >>.

Test::Compile is awesome, however, in the process of its development, we discovered it might be useful
to run compilation tests in parallel.

This lead to the realization that implementing said functions are kinda messy.

However, a further realization is, that parallelism should not be codified in the test itself, because platform parallelism is
rather not very portable, so parallelism should only be enabled when asked for.

And this lead to the realization that C<prove> and C<Test::Harness> B<ALREADY> implement parallelism, and B<ALREADY> provide a
safe way for platforms to indicate parallelism is wanted.

Which means implementing another layer of parallelism is unwanted and unproductive effort ( which may be also filled with messy
parallelism-induced bugs )

So, here is the Test::Compile model based on how development is currently proceeding.

    prove
      \ ----- 00_compile.t
     |           \ ----- Compile Module 1
     |           \ ----- Compile Module 2
     |
     \ ----- 01_basic.t

That may be fine for some people, but this approach has several fundamental limits:

=over 4

=item 1. Sub-Tasks of compile don't get load balanced by the master harness.

=item 2. Parallelism is developer side, not deployment side governed.

=item 3. This approach means C<prove -s> will have no impact.

=item 4. This approach means C<prove -j> will have no impact.

=item 5. This approach inhibits other features of C<prove> such as the C<--state=slow>

=back

So this variation aims to employ one test file per module, to leverage C<prove> power.

One initial concern cropped up on the notion of having excessive numbers of C<perl> instances, e.g:

    prove
      \ ----- 00_compile/01_Module_1.t
     |           \ ----- Compile Module 1
     |
      \ ----- 00_compile/02_Module_2.t
     |           \ ----- Compile Module 2
     |
     \ ----- 01_basic.t

If we were to implement it this way, we'd have the fun overhead of having to spawn B<2> C<perl> instances
per module tested, which on C<Win32>, would roughly double the test time and give nothing in return.

However, B<Most> of the reason for having a C<perl> process per compile, was to separate the modules from each other
to assure they could be loaded independently.

So because we already have a basically empty compile-state per test, we can reduce the number of C<perl> processes to as many
modules as we have.

    prove
      \ ----- 00_compile/01_Module_1.t
     |
      \ ----- 00_compile/02_Module_2.t
     |
     \ ----- 01_basic.t

Granted, there is still some bleed here, because doing it like this means you have some modules preloaded prior to compiling the
module in question, namely, that C<Test::*> will be in scope.

However, "testing these modules compile without C<Test::> loaded" is not the real purpose of the compile tests,
the compile tests are to make sure the modules load.

So this is an acceptable caveat for this module, and if you wish to be distinct from C<Test::*>, then you're encouraged to use the
much more proven C<[Test::Compile]>.

Though we may eventually provide an option to spawn additional C<perl> processes to more closely mimic C<Test::*>'s behaviour,
the cost of doing so should not be understated, and as this module exist to attempt to improve efficiency of tests, not to
decrease them, that would be an approach counter-productive to this modules purpose.

=head1 METHODS

=head2 C<gather_files>

This plugin operates B<ONLY> during C<gather_files>, unlike other plugins which have multiple phase involvement, this only
happens at this phase.

The intrinsic dependence of this plugin on other files in your dist, means that in order for it to generate a test for any given
file, the test itself must be included B<after> that file is gathered.

=head1 ATTRIBUTES

=head2 C<xt_mode>

I<optional> B<< C<Bool> >>

    xt_mode = 1

If set, C<prefix> defaults to C<xt/author/00-compile>

I<Default> is B<NOT SET>

=head2 C<prefix>

I<optional> B<< C<Str> >>

    prefix = t/99-compilerthingys

If set, sets the prefix path for generated tests to go in.

I<Defaults> to C<t/00-compile>

=head2 C<file>

I<optional> B<< C<multivalue_arg> >> B<< C<ArrayRef[Str]> >>

B<< C<mvp_aliases> >>: C<files>

    file = lib/Foo.pm
    file = lib/Bar.pm
    files = lib/Quux.pm
    file = script/whatever.pl

Specifies the list of source files to generate compile tests for.

I<If not specified>, defaults are populated from the file finder C<finder>

=head2 C<skip>

I<optional> B<< C<multivalue_arg> >> B<< C<ArrayRef[Str]> >>

    skip = lib/Foo.pm

Specifies the list of source files to skip compile tests for.

=head2 C<finder>

I<optional> B<< C<multivalue_arg> >> B<< C<ArrayRef[Str]> >>

    finder = :InstallModules

Specifies a L<< C<FileFinder>|Dist::Zilla::Role::FileFinder >> plugin name
to query for a list of files to build compile tests for.

I<If not specified>, a custom one is autovivified, and matches only C<*.pm> in C<lib/>

=head2 C<path_translator>

I<optional> B<< C<Str> >>

A Name of a routine to translate source paths ( i.e: Paths to modules/scripts that are to be compiled )
into test file names.

I<Default> is C<base64_filter>

Supported Values:

=over 4

=item * C<base64_filter>

Paths are L<< mangled so that they contain only base64 web-safe elements|http://tools.ietf.org/html/rfc3548#section-4 >>

That is to say, if you were building tests for a distribution with this layout:

    lib/Foo/Bar.pm
    lib/Foo.pm
    lib/Foo_Quux.pm

That the generated test files will be in the C<prefix> directory named:

    lib_Foo_Bar_pm.t
    lib_Foo_pm.t
    lib_Foo_Quux.t

This is the default, but not necessarily the most sane if you have unusual file naming.

    lib/Foo/Bar.pm
    lib/Foo_Bar.pm

This configuration will not work with this translator.

=item * C<mimic_source>

This is mostly a 1:1 mapping, it doesn't translate source names in any way, other than prefixing and suffixing,
which is standard regardless of translation chosen.

    lib/Foo/Bar.pm
    lib/Foo.pm
    lib/Foo_Quux.pm

Will emit a prefix directory populated as such

    lib/Foo/Bar.pm.t
    lib/Foo.pm.t
    lib/Foo_Quux.pm.t

Indeed, if you had a death wish, you could set C<prefix = lib> and your final layout would be:

    lib/Foo/Bar.pm
    lib/Foo/Bar.pm.t
    lib/Foo.pm
    lib/Foo.pm.t
    lib/Foo_Quux.pm
    lib/Foo_Quux.pm.t

Though this is not advised, and is only given for an example.

=back

=head2 C<test_template>

Contains the string of the template file you wish to use as a reference point.

Unlike most plugins, which use L<< C<Data::Section>|Data::Section >> to provide their templates,
this plugin uses a L<< C<File::ShareDir> C<dist_dir>|File::ShareDir >> to distribute templates.

This means there will always be a predetermined list of templates shipped by this plugin,
however, if you wish to modify these templates and store them with a non-colliding name, for your personal convenience,
you are entirely free to so.

As such, this field takes as its parameter, the name of any file that happened to be in the C<dist_dir> at compile time.

Provided Templates:

=over 4

=item * C<01-basic.t.tpl>

A very basic standard template, which C<use>'s C<Test::More>, does a C<requires_ok($file)> for the requested file, and nothing
else.

=item * C<02-raw-require.t.tpl>

A minimalist spartan C<require_ok> implementation, but without using C<Test::More>. Subsequently faster under Test2 and can expose
more issues where modules have implicit C<use>

=back

=for Pod::Coverage BUILD

=head1 Other Important Differences to Test::Compile

=head2 Finders useful, but not required

C<[Test::Compile::PerFile]> supports providing an arbitrary list of files to generate compile tests

    [Test::Compile::PerFile]
    file = lib/Foo.pm
    file = lib/Quux.pm

Using this will supersede using finders to find things.

=head2 Single finder only, not multiple

C<[Test::Compile]> supports 2 finder keys, C<module_finder> and C<script_finder>.

This module only supports one key, C<finder>, and it is expected
that if you want to test 2 different sets of files, you'll create a separate instance for that:

    -[Test::Compile]
    -module_finder = Foo
    -script_finder = bar
    +[Test::Compile::PerFile / module compile tests]
    +finder = Foo
    +[Test::Compile::PerFile / script compile tests]
    +finder = bar

This is harder to do with C<[Test::Compile]>, because you'd have to declare a separate file name for it to work,
where-as C<[Test::Compile::PerFile]> generates a unique file name for each source it tests.

Collisions are still possible, but harder to hit by accident.

=head2 File Oriented, not Module Oriented

Under the hood, C<Test::Compile> is really file oriented too, it just doesn't give that impression on the box.

It just seemed fundamentally less complex to deal only in file paths for this module, as it gives
no illusions as to what it can, and cannot do.

( For example, by being clearly file oriented, there's no ambiguity of how it will behave when a file name and a module name are
miss-matching in some way, by simply not caring about the latter , it will also never attempt to probe and load modules that can't
be automatically resolved to files )

=head1 Performance

A rough comparison on the C<dzil> git tree, with C<HARNESS_OPTIONS=j4:c> where C<4> is the number of logical C<CPUs> I have:

    Test::Compile -            Files= 42, Tests=577, 57 wallclock secs ( 0.32 usr  0.11 sys + 109.29 cusr 11.13 csys = 120.85 CPU)
    Test::Compile::PerFile -   Files=176, Tests=576, 44 wallclock secs ( 0.83 usr  0.39 sys + 127.34 cusr 13.27 csys = 141.83 CPU)

So a 20% saving for a 300% growth in file count, a 500k growth in unpacked tar size, and a 4k growth in C<tar.gz> size.

Hmm, that's a pretty serious trade off. Might not really be worth the savings.

Though, comparing compile tests alone:

    # Test::Compile
    prove -j4lr --timer t/00-compile.t
    Files=1, Tests=135, 41 wallclock secs ( 0.07 usr  0.01 sys + 36.82 cusr  3.58 csys = 40.48 CPU)

    # Test::Compile::PerFile
    prove -j4lr --timer t/00-compile/
    Files=135, Tests=135, 22 wallclock secs ( 0.58 usr  0.32 sys + 64.45 cusr  6.74 csys = 72.09 CPU)

That's not bad, considering that although I have 4 logical C<CPUs>, that's really just 2 physical C<CPUs> with hyper-threading ;)

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
