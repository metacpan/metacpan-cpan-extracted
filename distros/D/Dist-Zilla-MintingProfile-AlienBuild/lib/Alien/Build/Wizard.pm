use strict;
use warnings;
use 5.022;

package Alien::Build::Wizard 0.03 {

  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::StrictConstructor;
  use experimental qw( signatures postderef );
  use Data::Section::Simple qw( get_data_section );
  use Alien::Build::Wizard::Detect;
  use Alien::Build::Wizard::Questions qw( :all );
  use namespace::autoclean;

  # ABSTRACT: Alien distribution creation wizard

  has detect => (
    is       => 'ro',
    isa      => 'Alien::Build::Wizard::Detect',
    lazy     => 1,
    default => sub ($self) {
      for(1..20)
      {
        my $url = $self->chrome->ask(QUESTION_URL);

        if($url eq '')
        {
          $self->chrome->say("URL is required");
          next;
        }

        my $detect = eval { Alien::Build::Wizard::Detect->new( uri => $url ) };
        if(my $error = $@)
        {
          $self->chrome->say("there appears to have been a problem fetching or detecting that tarball.");
          $self->chrome->say("$error");
        }
        else
        {
          return $detect;
        }
      }
      die "Bailing unable to get good input";
    },
  );

  has chrome => (
    is      => 'ro',
    isa     => 'Alien::Build::Wizard::Chrome',
    lazy    => 1,
    default => sub ($self) {
      require Alien::Build::Wizard::Chrome;
      Alien::Build::Wizard::Chrome->new;
    },
  );

  has class_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      $self->chrome->ask(QUESTION_CLASS_NAME, 'Alien::' . $self->detect->name);
    },
  );

  has start_url => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub ($self) {
      if($self->latest)
      {
        my $url = $self->detect->uri->clone;
        my $path = $url->path;
        $path =~ s{/[^/]*?$}{};
        $url->path($path);
        return $url;
      }
      else
      {
        return $self->detect->uri;
      }
    },
  );

  has human_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      $self->chrome->ask(QUESTION_HUMAN_NAME, $self->detect->name);
    },
  );

  has pkg_names => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub ($self) {
      [split /\s+/, $self->chrome->ask(QUESTION_PKG_NAMES, join ' ', $self->detect->pkg_config->@*)];
    },
  );

  has extract_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      my $basename = Path::Tiny->new($self->detect->uri->path)->basename;

      # tar format is usually .tar or .tar.gz .tar.bz2 etc.
      if($basename =~ /\.(tar(\..*)?)$/)
      {
        return $1;
      }
      # non-greedy to only get the last . for non tars
      elsif($basename =~ /\.(.*?)$/)
      {
        return $1;
      }
      # fallback on .fixme, user will probably have to update
      else
      {
        return 'fixme';
      }
    },
  );

  has build_type => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      my @types = $self->detect->build_type->@*;
      if(@types == 0)
      {
        $self->chrome->say("Unable to detect build system used by the package.  You can select manual to specify the build commands directly, or select one of the standard build systems");
      }
      elsif(@types == 1)
      {
        $self->chrome->say("The build system was detected as $types[0]; that is probably correct");
      }
      else
      {
        $self->chrome->say("Multiple build systems were detected in the tarball; select the most reliable one of: @types");
      }
      my $default = $types[0];
      scalar $self->chrome->choose(QUESTION_BUILD_SYSTEM, ['manual','autoconf','cmake','make'], \@types);
    },
  );

  has alien_types => (
    is      => 'ro',
    isa     => 'HashRef[Int]',
    lazy    => 1,
    default => sub ($self) {
      while(1)
      {
        my @types = $self->chrome->choose(QUESTION_ALIEN_TYPE, ['tool','xs','ffi'], ['xs']);
        unless(@types)
        {
          $self->chrome->say("You must select at least one type");
          next;
        }
        my %answer = map { $_ => 1 } @types;
        return \%answer;
      }
    }
  );

  has latest => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub ($self) {
      my $value = $self->chrome->choose(QUESTION_LATEST, ['latest','specific'], ['latest']);
      $value eq 'latest' ? 1 : 0;
    },
  );

  has prefix => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
      my $path = $self->detect->uri->path;
      my($file) = $path =~ /\/([^\/]*?)$/;
      my($prefix) = $file =~ /^([^-^\.]+)/;
      $prefix;
    }
  );

  sub generate_content ($self)
  {
    my %files;

    require Template;
    my $tt = Template->new(
      FILTERS => {
        regex_escape => sub ($text) { $text =~ s/\./\\./gr },
      },
    );

    my $pod = sub ($name) { "=$name" };

    {
      my $pm = 'lib/' . $self->class_name . ".pm";
      $pm =~ s{::}{/};
      my $template = get_data_section 'Module.pm';
      $template =~ s/\s+$/\n/;
      die "no template Module.pm" unless $template;
      $tt->process(\$template, { wizard => $self, pod => $pod }, \($files{$pm} = '')) or die $tt->error;
    }

    foreach my $path (qw( alienfile t/basic.t ))
    {
      my $template = get_data_section $path;
      $template =~ s/\s+$/\n/;
      die "no template $path" unless $template;
      $tt->process(\$template, { wizard => $self, pod => $pod }, \($files{$path} = '')) or die $tt->error;
    }

    \%files;
  }

}

package Alien::Build::Wizard;

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Wizard - Alien distribution creation wizard

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 % perldoc Dist::Zilla::MintingProfile::AlienBuild

=head1 DESCRIPTION

This class is private.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::MintingProfile::AlienBuild>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ Module.pm
package [% wizard.class_name %];

use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

1;

[% pod('head1') %] NAME

[% wizard.class_name %] - Find or build [% wizard.human_name %]

[% pod('head1') %] SYNOPSIS
[%- IF wizard.alien_types.xs %]

From L<ExtUtils::MakeMaker>:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();
 
 WriteMakefile(
   Alien::Base::Wrapper->new('[% wizard.class_name %]')->mm_args2(
     NAME => 'FOO::XS',
     ...
   ),
 );

From L<Module::Build>:

 use Module::Build;
 use Alien::Base::Wrapper qw( [% wizard.class_name %] !export );
 use [% wizard.class_name %];
 
 my $build = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Base::Wrapper' => '0',
     '[% wizard.class_name %]' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );
 
 $build->create_build_script;

From L<Inline::C> / L<Inline::CPP> script:

 use Inline 0.56 with => '[% wizard.class_name %]';

From L<Dist::Zilla>

 [@Filter]
 -bundle = @Basic
 -remove = MakeMaker
 
 [Prereqs / ConfigureRequires]
 [% wizard.class_name %] = 0
 
 [MakeMaker::Awesome]
 header = use Alien::Base::Wrapper qw( [% wizard.class_name %] !export );
 WriteMakefile_arg = Alien::Base::Wrapper->mm_args
[%- END %]
[%- IF wizard.alien_types.ffi %]

From L<FFI::Platypus>:

 use FFI::Platypus;
 use [% wizard.class_name %];
 
 my $ffi = FFI::Platypus->new(
   lib => [ [% wizard.class_name %]->dynamic_libs ],
 );
[%- END %]
[%- IF wizard.alien_types.tool %]

Command line tool:

 use [% wizard.class_name %];
 use Env qw( @PATH );
 
 unshift @PATH, [% wizard.class_name %]->bin_dir;
[%- END %]

[% pod('head1') %] DESCRIPTION

This distribution provides [% wizard.human_name %] so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of [% wizard.human_name %] on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

[% pod('head1') %] SEE ALSO

[% pod('over') %] 4

[% pod('item') %] L<Alien>

Documentation on the Alien concept itself.

[% pod('item') %] L<Alien::Base>

The base class for this Alien.

[% pod('item') %] L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

[% pod('back') %]

[% pod('cut') %]

@@ alienfile
use alienfile;

[% IF wizard.pkg_names.size > 0 -%]
plugin PkgConfig => [% IF wizard.pkg_names.size > 1 %][[% FOREACH name IN wizard.pkg_names %]'[% name %]'[% UNLESS loop.last %], [% END %][% END %]][% ELSE %]'[% wizard.pkg_names.0 %]'[% END %];
[% ELSE -%]
# replace this with your own system probe.
# See Alien::Build::Plugin::Probe and
# Alien::Build::Plugin::PkgConfig for common
# probe plugins.
probe sub { 'share' }
[% END -%]

share {
  start_url '[% wizard.start_url %]';
[% IF wizard.latest -%]
  plugin Download => (
    filter  => qr/^[% wizard.prefix %].*[% wizard.extract_format | regex_escape %]$/,
    version => qr/([0-9\.]+)/,
  );
[% ELSE -%]
  plugin Download => ();
[% END -%]
[% IF wizard.extract_format == 'fixme' -%]

  # archive format was not detected, see
  # https://metacpan.org/pod/Alien::Build::Plugin::Extract::Negotiate
  # for valid formats.
[% END -%]
  plugin Extract => '[% wizard.extract_format %]';
[% IF wizard.built_type == 'manual' -%]
  build [
    # TODO
    # See https://metacpan.org/pod/alienfile#build
  ]
[% ELSIF wizard.build_type == 'autoconf' -%]
  plugin 'Build::Autoconf';
[% IF wizard.alien_types.tool AND wizard.alien_types.ffi -%]
  build [
    '%{configure} --enable-static --disable-shared',
    '%{make}',
    '%{make install',
  ];
  ffi {
    build [
      '%{configure} --disabled-static --enabled-shared',
      '%{make}',
      '%{make install',
    ];
  }
[% ELSE -%]
  build [
    '%{configure} --[% IF wizard.alien_types.xs %]enable[% ELSE %]disable[% END %]-static --[% IF wizard.alien_types.ffi %]enable[% ELSE %]disable[% END %]-shared',
    '%{make}',
    '%{make} install',
  ];
[% END -%]
[% ELSIF wizard.build_type == 'cmake' -%]
  plugin 'Build::CMake';
  build [
    ['%{cmake}', @{ meta->prop->{plugin_build_cmake}->{args} }, '%{.install.extract}'],
    '%{make}',
    '%{make} install',
  ];
[% ELSIF wizard.build_type == 'make' -%]
  build [
    # NOTE: you will probably need to set a PREFIX and possibly DISTDIR
    # https://metacpan.org/pod/Alien::Build#prefix1
    # https://metacpan.org/pod/Alien::Build#destdir
    '%{make}',
    '%{make} install',
  ];
[% END -%]
  plugin 'Gather::IsolateDynamic';
}

@@ t/basic.t
use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use [% wizard.class_name %];

alien_diag '[% wizard.class_name %]';
alien_ok '[% wizard.class_name %]';

done_testing;
