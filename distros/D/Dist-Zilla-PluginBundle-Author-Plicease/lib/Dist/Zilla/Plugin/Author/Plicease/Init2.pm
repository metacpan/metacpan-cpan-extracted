package Dist::Zilla::Plugin::Author::Plicease::Init2 2.46 {

  use 5.014;
  use Moose;
  use Dist::Zilla::File::InMemory;
  use Dist::Zilla::File::FromCode;
  use Sub::Exporter::ForMethods qw( method_installer );
  use Data::Section { installer => method_installer }, -setup;
  use Dist::Zilla::MintingProfile::Author::Plicease;
  use JSON::PP qw( encode_json );
  use Encode qw( encode_utf8 );

  # ABSTRACT: Dist::Zilla initialization tasks for Plicease


  with 'Dist::Zilla::Role::AfterMint';
  with 'Dist::Zilla::Role::ModuleMaker';
  with 'Dist::Zilla::Role::FileGatherer';
  with 'Dist::Zilla::Role::TextTemplate';

  our $chrome;

  sub chrome
  {
    return $chrome if defined $chrome;
    shift->zilla->chrome;
  }

  has abstract => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_str("abstract");
    },
  );

  has include_tests => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
      1,
    },
  );

  has type_dzil => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my $name = shift->zilla->name;
      $name =~ /^Dist-Zilla/ ? 1 : 0;
    },
  );

  has type_alien => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my $name = shift->zilla->name;
      my $alien = $name =~ /^Alien-[A-Za-z0-9]+$/ ? 1 : 0;
      $alien = 0 if $name =~ /^Alien-(Build|Base|Role)-/;
      $alien;
    },
  );

  has workflow => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
      my $self = shift;
      my @workflow;

      foreach my $workflow (qw( windows macos ))
      {
        push @workflow, $workflow if $self->chrome->prompt_yn("workflow $workflow?");
      }

      \@workflow;
    },
  );

  has perl_version => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      if(defined $ENV{V} && $ENV{V} =~ /^5\.([0-9]+)$/)
      {
        return sprintf '5.%03d', $1;
      }
      elsif(defined $ENV{V} && $ENV{V} =~ /^5\.([0-9]+)\.([0-9]+)$/)
      {
        return sprintf '5.%03d%03d', $1, $2;
      }
      else
      {
        if($self->type_dzil)
        {
          return '5.014';
        }
        else
        {
          return '5.008001';
        }
      }
    },
  );

  sub make_module
  {
    my($self, $arg) = @_;

    my $template_name;

    if($self->type_dzil)
    {
      $template_name = 'Dzil.pm';
    }
    elsif($self->type_alien)
    {
      $template_name = 'Alien.pm';
    }
    elsif($self->perl_version >= 5.020)
    {
      $template_name = 'P5020.pm';
    }
    elsif($self->perl_version >= 5.014)
    {
      $template_name = 'P5014.pm';
    }
    else
    {
      $template_name = 'Default.pm';
    }

    (my $filename = $arg->{name}) =~ s{::}{/}g;
    $self->gather_file_template($template_name => "lib/$filename.pm");
  }

  sub gather_files
  {
    my($self, $arg) = @_;

    $self->gather_file_dist_ini($arg);

    $self->gather_file_simple  ('.gitattributes');
    $self->gather_file_template('.gitignore');
    $self->gather_file_simple  ('.travis.yml');
    $self->gather_file_simple  ('alienfile') if $self->type_alien;
    $self->gather_file_simple  ('author.yml');
    $self->gather_file_simple  ('Changes');
    $self->gather_file_simple  ('perlcriticrc');
    $self->gather_file_template('t/main_class.t' => 't/' . lc($self->zilla->name =~ s/-/_/gr) . ".t" );
    $self->gather_file_simple  ('xt/author/critic.t');

    foreach my $workflow (@{ $self->workflow })
    {
      $self->gather_file_simple(".github/workflows/$workflow.yml");
    }
  }

  sub gather_file_simple
  {
    my($self, $filename) = @_;
    my $content = $self->section_data("dist/$filename");
    $self->log_fatal("no bundled file dist/$filename") unless $content;
    my $file = Dist::Zilla::File::InMemory->new({
      name    => $filename,
      content => $$content,
    });
    $self->add_file($file);
  }

  sub gather_file_template
  {
    my($self, $template_name, $filename) = @_;
    $filename //= $template_name;
    my $template = ${ $self->section_data("template/$template_name") };
    $self->log_fatal("no bundled template: template/$template_name") unless $template;
    my $content = $self->fill_in_string($template, {
      name         => $self->zilla->name,
      abstract     => $self->abstract,
      perl_version => $self->perl_version,
    }, {});
    my $file = Dist::Zilla::File::InMemory->new({
      name    => $filename,
      content => $content,
    });
    $self->add_file($file);
  }

  sub gather_file_dist_ini
  {
    my($self, $arg) = @_;

    my $zilla = $self->zilla;

    my $template = $self->section_data("template/dist.ini");

    my $stash = {
      name           => $zilla->name,
      copyright_year => (localtime)[5]+1900,
      version        => __PACKAGE__->VERSION // '2.41',
      release_tests  => $self->include_tests,
      github_user    => $self->github_user,
      version_plugin => ($self->perl_version >= 5.014 ? 'PkgVersion::Block' : 0),
      workflow       => $self->workflow,
    };

    my $code = sub {
      $self->fill_in_string($$template, $stash, {});
    };

    my $file = Dist::Zilla::File::FromCode->new({
      name => 'dist.ini',
      code => $code,
    });

    $self->add_file($file);
  }

  has github => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_yn("create github repo", { default => 1 });
    },
  );

  has github_login => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_str("github login", { default => 'plicease' });
    },
  );

  has github_user => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_str("github user/org", { default => 'plicease' });
    },
  );

  has github_private => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_yn("github private", { default => 0 });
    },
  );

  has github_pass => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->chrome->prompt_str("github pass", { noecho => 1 });
    },
  );

  has github_auth_token => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      $ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_GITHUB_OAUTH_TOKEN} // $ENV{GITHUB_OAUTH_TOKEN};
    },
  );

  sub after_mint
  {
    my($self, $opts) = @_;

    unless(eval { require Git::Wrapper })
    {
      $self->zilla->log("no Git::Wrapper, can't create repository");
      return;
    }

    my $git = Git::Wrapper->new($opts->{mint_root});
    $git->init;
    $git->commit({ 'allow-empty' => 1, message => "Start with a blank" });
    $git->add($opts->{mint_root});
    $git->commit({ message => "Initial structure" });

    unless(eval { require LWP::UserAgent; require HTTP::Request })
    {
      $self->zilla->log("no LWP, can't create github repo");
    }

    my $no_github = 1;

    if($self->github && !$ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB})
    {
      my $ua = LWP::UserAgent->new;
      my $org = $self->github_user ne $self->github_login
        ? $self->github_user
        : undef;
      my $url = $org ? "https://api.github.com/orgs/$org/repos" : 'https://api.github.com/user/repos';
      my $request = HTTP::Request->new(
        POST => $url,
      );

      my $data = encode_json({
        name               => $self->zilla->name,
        description        => $self->abstract,
        private            => (!$org && $self->github_private) ? JSON::PP::true : JSON::PP::false,
        has_projects       => JSON::PP::false,
        has_wiki           => JSON::PP::false,
        allow_squash_merge => JSON::PP::false,
      });
      $request->content($data);
      $request->header( 'Content-Length' => length encode_utf8 $data );
      if($self->github_auth_token)
      {
        $request->header( 'Authorization' => "token @{[ $self->github_auth_token ]}" );
      }
      else
      {
        $request->authorization_basic($self->github_login, $self->github_pass);
      }
      my $response = $ua->request($request);
      if($response->is_success)
      {
        $self->zilla->log("created repo at https://github.com/@{[ $self->github_user ]}/@{[ $self->zilla->name ]}");
        $no_github = 0;
      }
      else
      {
        $self->zilla->log("$url");
        $self->zilla->log("$data");
        $self->zilla->log("@{[ $response->code ]} @{[ $response->status_line ]}");
        $self->zilla->log("could not create a github repo!");
      }
    }

    $git->remote('add', 'origin', "git\@github.com:" . $self->github_user . '/' . $self->zilla->name . '.git');
    $git->push('origin', 'master') unless $no_github;

    return;
  }

  __PACKAGE__->meta->make_immutable;
}

1;

package Dist::Zilla::Plugin::Author::Plicease::Init2;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Init2 - Dist::Zilla initialization tasks for Plicease

=head1 VERSION

version 2.46

=head1 DESCRIPTION

Create a dist in plicease style.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012,2013,2014,2015,2016,2017,2018,2019,2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__


__[ dist/alienfile ]__
use alienfile;
plugin 'PkgConfig' => 'libfoo';
share {
  plugin Download => (
    url => 'http://...',
    filter => qr/*\.tar\.gz$/,
    version => qr/([0-9\.]+)/,
  );
  plugin Extract => 'tar.gz';
  plugin 'Build::Autoconf';
};


__[ dist/author.yml ]__
---
pod_spelling_system:
  skip: 0
  # list of words that are spelled correctly
  # (regardless of what spell check thinks)
  # or stuff that I like to spell incorrectly
  # intentionally
  stopwords: []

pod_coverage:
  skip: 0
  # format is "Class#method" or "Class",regex allowed
  # for either Class or method.
  private: []


__[ dist/.travis.yml ]__
language: minimal
dist: xenial
services:
  - docker
before_install:
  - curl https://raw.githubusercontent.com/plicease/cip/master/bin/travis-bootstrap | bash
  - cip before-install
install:
  - cip diag
  - cip install
script:
  - cip script
jobs:
  include:
    - env: CIP_TAG=static
    - env: CIP_TAG=5.31
    - env: CIP_TAG=5.30
    - env: CIP_TAG=5.28
    - env: CIP_TAG=5.26
    - env: CIP_TAG=5.24
    - env: CIP_TAG=5.22
    - env: CIP_TAG=5.20
    - env: CIP_TAG=5.18
    - env: CIP_TAG=5.16
    - env: CIP_TAG=5.14
    - env: CIP_TAG=5.12
    - env: CIP_TAG=5.10
    - env: CIP_TAG=5.8
cache:
  directories:
    - "$HOME/.cip"


__[ dist/perlcriticrc ]__
severity = 1
only = 1

[Freenode::ArrayAssignAref]
[Freenode::BarewordFilehandles]
[Freenode::ConditionalDeclarations]
[Freenode::ConditionalImplicitReturn]
[Freenode::DeprecatedFeatures]
[Freenode::DiscouragedModules]
[Freenode::DollarAB]
[Freenode::Each]
[Freenode::EmptyReturn]
[Freenode::IndirectObjectNotation]
[Freenode::LexicalForeachIterator]
[Freenode::LoopOnHash]
[Freenode::ModPerl]
[Freenode::OpenArgs]
[Freenode::OverloadOptions]
[Freenode::POSIXImports]
[Freenode::PackageMatchesFilename]
[Freenode::PreferredAlternatives]
[Freenode::StrictWarnings]
extra_importers = Test2::V0
[Freenode::Threads]
[Freenode::Wantarray]
[Freenode::WarningsSwitch]
[Freenode::WhileDiamondDefaultAssignment]

[BuiltinFunctions::ProhibitBooleanGrep]
[BuiltinFunctions::ProhibitStringyEval]
[BuiltinFunctions::ProhibitStringySplit]
[BuiltinFunctions::ProhibitVoidGrep]
[BuiltinFunctions::ProhibitVoidMap]
[ClassHierarchies::ProhibitExplicitISA]
[ClassHierarchies::ProhibitOneArgBless]
[CodeLayout::ProhibitHardTabs]
allow_leading_tabs = 0
[CodeLayout::ProhibitTrailingWhitespace]
[CodeLayout::RequireConsistentNewlines]
[ControlStructures::ProhibitLabelsWithSpecialBlockNames]
[ControlStructures::ProhibitMutatingListFunctions]
[ControlStructures::ProhibitUnreachableCode]
[InputOutput::ProhibitBarewordFileHandles]
[InputOutput::ProhibitJoinedReadline]
[InputOutput::ProhibitTwoArgOpen]
[Miscellanea::ProhibitFormats]
[Miscellanea::ProhibitUselessNoCritic]
[Modules::ProhibitConditionalUseStatements]
;[Modules::RequireEndWithOne]
[Modules::RequireNoMatchVarsWithUseEnglish]
[Objects::ProhibitIndirectSyntax]
[RegularExpressions::ProhibitUselessTopic]
[Subroutines::ProhibitNestedSubs]
[ValuesAndExpressions::ProhibitLeadingZeros]
[ValuesAndExpressions::ProhibitMixedBooleanOperators]
[ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator]
[ValuesAndExpressions::RequireUpperCaseHeredocTerminator]
[Variables::ProhibitPerl4PackageNames]
[Variables::ProhibitUnusedVariables]


__[ dist/xt/author/critic.t ]__
use Test2::Require::Module 'Test2::Tools::PerlCritic';
use Test2::Require::Module 'Perl::Critic';
use Test2::Require::Module 'Perl::Critic::Freenode';
use Test2::V0;
use Perl::Critic;
use Test2::Tools::PerlCritic;

my $critic = Perl::Critic->new(
  -profile => 'perlcriticrc',
);

perl_critic_ok ['lib','t'], $critic;

done_testing;


__[ dist/.gitattributes ]__
*.pm linguist-language=Perl
*.t linguist-language=Perl
*.h linguist-language=C


__[ dist/Changes ]__
Revision history for {{$dist->name}}},

{{$NEXT}}
  - initial version


__[ template/dist.ini ]__
name             = {{$name}}
author           = Graham Ollis <plicease@cpan.org>
license          = Perl_5
copyright_holder = Graham Ollis
copyright_year   = {{$copyright_year}}
version          = 0.01

[@Author::Plicease]
:version       = {{$version}}
travis_status  = 1
release_tests  = {{$release_tests}}
installer      = Author::Plicease::MakeMaker
github_user    = {{$github_user}}
test2_v0       = 1
{{

  my $extra = '';

  foreach my $wf (@workflow)
  {
    $extra .= "workflow       = $wf\n";
  }

  $extra .= "version_plugin = $version_plugin\n" if $version_plugin;

  $extra;

}}
[Author::Plicease::Core]

[Author::Plicease::Upload]
cpan = 0


__[ template/.gitignore ]__
{{ $name }}-*
/.build/
*.swp


__[ template/t/main_class.t ]__
use Test2::V0 -no_srand => 1;
use {{ $name =~ s/-/::/gr }};

ok 1, 'todo';

done_testing;


__[ template/Default.pm ]__
package {{ $name =~ s/-/::/gr }};

use strict;
use warnings;
use {{ $perl_version }};

# ABSTRACT: {{ $abstract }}
# VERSION

1;


__[ template/Alien.pm ]__
package {{ $name =~ s/-/::/gr }};

use strict;
use warnings;
use {{ $perl_version }};
use base qw( Alien::Base );

# ABSTRACT: {{ $abstract }}
# VERSION

1;


__[ template/Dzil.pm ]__
use strict;
use warnings;
use {{ $perl_version }}

package {{ $name =~ s/-/::/gr }} {

  use Moose;
  use namespace::autoclean;

  # ABSTRACT: {{ $abstract }}

  __PACKAGE__->meta->make_immutable;
}

1;


__[ template/P5014.pm ]__
use strict;
use warnings;
use {{ $perl_version }};

package {{ $name =~ s/-/::/gr }} {

  # ABSTRACT: {{ $abstract }}
}

1;


__[ template/P5020.pm ]__
use strict;
use warnings;
use {{ $perl_version }};
use experimental qw( postderef );

package {{ $name =~ s/-/::/gr }} {

  # ABSTRACT: {{ $abstract }}
}

1;


__[ dist/.github/workflows/windows.yml ]__
name: windows

on:
  push:
    branches:
      - '*'
    tags-ignore:
      - '*'
  pull_request:

env:
  PERL5LIB: c:\cx\lib\perl5
  PERL_LOCAL_LIB_ROOT: c:/cx
  PERL_MB_OPT: --install_base C:/cx
  PERL_MM_OPT: INSTALL_BASE=C:/cx

jobs:
  perl:

    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v2

      - name: Prepare for cache
        run: |
          perl -V > perlversion.txt
          ls -l perlversion.txt

      - name: Cache CPAN modules
        uses: actions/cache@v1
        env:
          cache-name: cache-cpan-modules
        with:
          path: c:\cx
          key: ${{ runner.os }}-build-${{ hashFiles('perlversion.txt') }}
          restore-keys: |
            ${{ runner.os }}-build-${{ hashFiles('perlversion.txt') }}

      - name: Set up Perl
        run: |
          choco install strawberryperl
          echo "##[add-path]C:\cx\bin;C:\strawberry\c\bin;C:\strawberry\perl\site\bin;C:\strawberry\perl\bin"
      - name: perl -V
        run: perl -V
      - name: Install Static Dependencies
        run: |
          cpanm -n Dist::Zilla
          dzil authordeps --missing | cpanm -n
          dzil listdeps --missing   | cpanm -n
      - name: Install Dynamic Dependencies
        run: dzil run --no-build 'cpanm --installdeps .'
      - name: Run Tests
        run: dzil test -v


__[ dist/.github/workflows/macos.yml ]__
name: macos

on:
  push:
    branches:
      - '*'
    tags-ignore:
      - '*'
  pull_request:

env:
  PERL5LIB: /Users/runner/perl5/lib/perl5
  PERL_LOCAL_LIB_ROOT: /Users/runner/perl5
  PERL_MB_OPT: --install_base /Users/runner/perl5
  PERL_MM_OPT: INSTALL_BASE=/Users/runner/perl5

jobs:
  perl:

    runs-on: macOS-latest

    steps:
      - uses: actions/checkout@v2

      - name: Set up Perl
        run: |
          brew install perl
          curl https://cpanmin.us | perl - App::cpanminus -n
          echo "##[add-path]/Users/runner/perl5/bin"

      - name: perl -V
        run: perl -V

      - name: Prepare for cache
        run: |
          perl -V > perlversion.txt
          ls -l perlversion.txt

      - name: Cache CPAN modules
        uses: actions/cache@v1
        with:
          path: ~/perl5
          key: ${{ runner.os }}-build-${{ hashFiles('perlversion.txt') }}
          restore-keys: |
            ${{ runner.os }}-build-${{ hashFiles('perlversion.txt') }}

      - name: Install Static Dependencies
        run: |
          cpanm -n Dist::Zilla
          dzil authordeps --missing | cpanm -n
          dzil listdeps --missing   | cpanm -n
      - name: Install Dynamic Dependencies
        run: dzil run --no-build 'cpanm --installdeps .'
      - name: Run Tests
        run: dzil test -v
