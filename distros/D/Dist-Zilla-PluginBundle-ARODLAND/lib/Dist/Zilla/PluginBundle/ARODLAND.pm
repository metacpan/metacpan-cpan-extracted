package Dist::Zilla::PluginBundle::ARODLAND;
# ABSTRACT: Use L<Dist::Zilla> like ARODLAND does
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY
our $VERSION = '0.09'; # VERSION

use 5.10.0;
use Moose;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::Plugin::Authority;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::AutoVersion;
use Dist::Zilla::Plugin::Git::NextVersion;
#use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::OurPkgVersion;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::ReadmeFromPod;

sub bundle_config {
  my ($self, $section) = @_;

  my $config = $section->{payload};

  my $dist = $config->{dist} // die "You must supply a dist name\n";
  my $github_user = $config->{github_user} // "arodland";

  my $authority = $config->{authority};
  my $bugtracker = $config->{bugtracker} // "rt";
  my $homepage = $config->{homepage};
  my $repository_url = $config->{repository_url};
  my $repository_web = $config->{repository_web};

  my $no_a_pre = $config->{no_AutoPrereqs} // 0;
  my $install_plugin = $config->{install_plugin} // "mbtiny";
  $install_plugin = lc $install_plugin;
  my $nextrelease_format = $config->{nextrelease_format} // "Version %v: %{yyyy-MM-dd}d";

  my $nextversion = $config->{nextversion} // "git"; # git, autoversion, manual
  my $tag_message = $config->{git_tag_message};
  my $version_regexp = $config->{git_version_regexp};
  my $autoversion_major = $config->{autoversion_major};

  my $compat = $config->{compat} || $VERSION;

  my ($tracker, $tracker_mailto, $webpage, $repo_url, $repo_web);

  given ($bugtracker) {
    when ('github') {
      $tracker = "http://github.com/$github_user/$dist/issues";
    }
    when ('rt') {
      $tracker = "https://rt.cpan.org/Public/Dist/Display.html?Name=$dist";
      $tracker_mailto = "bug-${dist}\@rt.cpan.org";
    }
    default {
      $tracker = $bugtracker;
    }
  }

  given ($repository_url) {
    when (not defined) {
      $repo_web = "http://github.com/$github_user/$dist";
      $repo_url = "git://github.com/$github_user/$dist.git";
    }
    default {
      $repo_web = $repository_web;
      $repo_url = $repository_url;
    }
  }

  given ($homepage) {
    when (not defined) {
      $webpage = "http://metacpan.org/release/$dist";
    } default {
      $webpage = $homepage;
    }
  }

  my @plugins = Dist::Zilla::PluginBundle::Basic->bundle_config({
      name => $section->{name} . '/@Basic',
      payload => { },
  });

  if ($install_plugin ne 'makemaker') {
    @plugins = grep { $_->[1] ne 'Dist::Zilla::Plugin::MakeMaker' } @plugins;
  }

  @plugins = grep { $_->[1] ne 'Dist::Zilla::Plugin::GatherDir' } @plugins;

  my @no_index_dirs = grep { -d $_ } qw( inc t xt utils example examples );

  my $prefix = 'Dist::Zilla::Plugin::';
  push @plugins, map {[ "$section->{name}/$_->[0]" => "$prefix$_->[0]" => $_->[1] ]}
  (
    ($no_a_pre
      ? ()
      : ([ AutoPrereqs => { } ])
    ),
    ($compat <= 0.02
      ? ([ PkgVersion => { } ])
      : ([ OurPkgVersion => { } ])
    ),
    (@no_index_dirs
      ? ([ MetaNoIndex => { directory => [ @no_index_dirs ] } ])
      : ()
    ),
    [
      MetaResources => {
        homepage => $webpage,
        'bugtracker.web' => $tracker,
        'bugtracker.mailto' => $tracker_mailto,
        'repository.type' => 'git',
        'repository.url' => $repo_url,
        'repository.web' => $repo_web,
        license => 'http://dev.perl.org/licenses/',
      }
    ],
    [
      Authority => {
        (defined $authority
          ? (authority => $authority)
          : ()
        ),
        do_metadata => 1,
        do_munging => 1,
        ($compat <= 0.02
          ? ()
          : (locate_comment => 1)
        ),
      }
    ],
    [
      NextRelease => {
        format => $nextrelease_format,
      }
    ],
    [
      ReadmeFromPod => { }
    ],
    [
      CopyFilesFromBuild => {
        copy => 'README',
      }
    ],
    [
      GatherDir => { }
    ],
    ($install_plugin eq 'modulebuild_optionalxs'
      ? ([ 'ModuleBuild::OptionalXS' => { } ])
      : ()
    ),
    ($install_plugin eq 'mbtiny'
      ? ([ 'ModuleBuildTiny' => { } ])
      : ()
    ),
    [
      MetaJSON => { }
    ],
#    [ CheckChangesHasContent => { } ],
  );

  given ($nextversion) {
    when ('git') {
      push @plugins, [ "$section->{name}/Git::NextVersion", "Dist::Zilla::Plugin::Git::NextVersion",
        {
          first_version => '0.01',
          ( $version_regexp
            ? (version_regexp => $version_regexp)
            : (version_regexp => '^(\d.*)$')
          ),
        }
      ];
    } when ('autoversion') {
      push @plugins, [ "$section->{name}/AutoVersion", "Dist::Zilla::Plugin::AutoVersion",
        { 
          ( $autoversion_major
            ? (major => $autoversion_major)
            : (major => 0)
          ),
        }
      ];
    } when ('manual') {
      # Manual versioning
    } default {
      die "Unknown 'nextversion'\n";
    }
  };

  push @plugins, Dist::Zilla::PluginBundle::Git->bundle_config({
      name    => "$section->{name}/\@Git",
      payload => {
        tag_format => '%v',
        ( $tag_message
          ? (tag_message => $tag_message)
          : ()
        ),
        allow_dirty => ['dist.ini', 'README', 'Changes'],
        changelog => 'Changes',
        commit_msg => 'Release v%v%n%n%c',
        push_to => 'origin',
      },
  });

  return @plugins;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::ARODLAND - Use L<Dist::Zilla> like ARODLAND does

=head1 VERSION

version 0.09

=head1 DESCRIPTION

This is the plugin bundle that ARODLAND uses. Use it as:

    [@ARODLAND]

    ;; Same as 'name' earlier in the dist.ini
    dist = My-Dist
    ;; If you're not me
    github_user = joebloe
    ;; Bugtracker: github or rt (or URL)
    bugtracker = rt
    ;; custom homepage / repository
    homepage = http://www.myawesomeproject.com/
    repository = http://git.myawesomeproject.com/coolstuff.git
    ;; disable certain features so you can do it better on your own
    no_AutoPrereqs = 1
    ;; defaults to the username from your [%PAUSE] or ~/.pause
    authority = cpan:ARODLAND

It's equvalent to

    [@Basic]
    
    [AutoPrereqs] ;; Unless no_AutoPrereqs is set
    [OurPkgVersion]
    [MetaJSON]
    
    [MetaNoIndex]
    ;; Only added if these directories exist
    directory = inc
    directory = t
    directory = xt
    directory = utils
    directory = example
    directory = examples
     
    [MetaResources]
    ;; $github_user is 'arodland' by default
    homepage   = http://search.cpan.org/dist/$dist/
    bugtracker.mailto = bug-$dist@rt.cpan.org
    bugtracker.web = https://rt.cpan.org/Public/Dist/Display.html?Name=$dist
    repository.web = http://github.com/$github_user/$dist
    repository.url = git://github.com/$github_user/$dist.git
    repository.type = git
    license    = http://dev.perl.org/licenses/ 
    
    [Authority]
    authority = cpan:YOURNAME ; if provided
    do_metadata = 1
    do_munging = 1
    locate_comment = 1
    
    [NextRelease]
    format = Version %v: %{yyyy-MM-dd}d

    [CheckChangesHasContent]

    [Git::NextVersion] ;; if nextversion is set to 'git'
    
    [AutoVersion] ;; if nextversion is set to 'autoversion'

    [ModuleBuildTiny] ;; by default

    [MakeMaker] ;; if install_plugin is 'makemaker'

    [ModuleBuild::OptionalXS] ;; if install_plugin is 'modulebuild_optionalxs'

    [MetaJSON]

    [@Git]
    allow_dirty = dist.ini
    allow_dirty = README
    allow_dirty = Changes
    changelog = Changes
    commit_msg = Release v%v%n%n%c
    push_to = origin

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
