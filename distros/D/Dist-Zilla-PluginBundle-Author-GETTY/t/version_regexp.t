use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use Path::Tiny;

use Dist::Zilla::PluginBundle::Author::GETTY;

# A dist without $VERSION in its source gets its version from Git::NextVersion,
# the fallback version provider of @Git::VersionManager's
# RewriteVersion::Transitional. Git::NextVersion finds the last release by
# matching every git tag against its version_regexp, whose own default
# ^v(.+)$ only fits v-prefixed tags. The bundle's default tag_format is the
# bare %v, so unless the bundle derives a matching version_regexp from
# tag_format, such a dist never sees its own release tags and restarts at
# first_version (0.001) on every release.

# Git::NextVersion's own default, in effect when the bundle passes nothing.
my $NEXTVERSION_DEFAULT_REGEXP = '^v(.+)$';

sub rewrite_version_config {
  my (%payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { %payload },
  );
  $bundle->configure;
  my ($plugin) = grep {
    $_->[1] eq 'Dist::Zilla::Plugin::RewriteVersion::Transitional'
  } @{ $bundle->plugins };
  return $plugin ? $plugin->[2] : undef;
}

# The version Git::NextVersion would read out of $tag with the regexp that
# reaches it, or undef when the tag does not count as a release.
sub version_of_tag {
  my ($config, $tag) = @_;
  my $re = defined $config->{version_regexp}
    ? $config->{version_regexp}
    : $NEXTVERSION_DEFAULT_REGEXP;
  return $tag =~ /$re/ ? $1 : undef;
}

{
  my $config = rewrite_version_config();
  ok($config, 'RewriteVersion::Transitional was added');
  is(
    $config->{fallback_version_provider},
    'Git::NextVersion',
    'Git::NextVersion is the fallback version provider',
  );
  is(
    $config->{version_regexp},
    '^(\d[\d._]*)$',
    'default tag_format %v forwards a bare-version version_regexp',
  );
  is(version_of_tag($config, '1.005'), '1.005', 'bare release tag 1.005 is recognized');
  is(version_of_tag($config, '0.326'), '0.326', 'bare release tag 0.326 is recognized');
  for my $tag (qw( backup/foo backup/patrick-import-2026-09-22 v1.005 v1 )) {
    is(version_of_tag($config, $tag), undef, "$tag is not taken for a release");
  }
}

{
  my $config = rewrite_version_config(tag_format => 'v%v');
  is(
    $config->{version_regexp},
    '^v(\d[\d._]*)$',
    'tag_format v%v forwards a v-prefixed version_regexp',
  );
  is(version_of_tag($config, 'v1.005'), '1.005', 'v1.005 is recognized as 1.005');
  for my $tag (qw( 1.005 backup/foo )) {
    is(version_of_tag($config, $tag), undef, "$tag is not taken for a release under v%v");
  }
}

{
  my $config = rewrite_version_config(tag_format => 'v%v.0');
  is(
    $config->{version_regexp},
    '^v(\d[\d._]*)\.0$',
    'tag_format v%v.0 forwards a regexp with the literal suffix quoted',
  );
  is(version_of_tag($config, 'v1.005.0'), '1.005', 'v1.005.0 is recognized as 1.005');
  for my $tag (qw( v1.005 1.005 v1.005x0 )) {
    is(version_of_tag($config, $tag), undef, "$tag is not taken for a release under v%v.0");
  }
}

# A tag_format with another %-code has no clean regexp equivalent: pass
# nothing and leave Git::NextVersion on its own default.
{
  my $config = rewrite_version_config(tag_format => '%N-%v');
  ok(
    !exists $config->{version_regexp},
    'tag_format with another %-code forwards no version_regexp',
  );
}

# End to end: a real (local-only) git repo with release tags, a dist whose
# main module carries no $VERSION, and the version the assembled plugins
# actually determine.
subtest 'version from git tags for a dist without $VERSION' => sub {
  plan skip_all => 'Dist::Zilla::Tester not available'
    unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
  plan skip_all => 'git binary not available' unless can_run('git');

  # V overrides every version provider; it must not leak in from the caller.
  delete local $ENV{V};

  my $version_from_tags = sub {
    my ($tag_format, @tags) = @_;

    my $tempdir = tempdir(CLEANUP => 1);
    my $dist_dir = path($tempdir, 'dist');
    $dist_dir->mkpath;

    my $tag_format_line = defined $tag_format ? "tag_format = $tag_format\n" : '';
    $dist_dir->child('dist.ini')->spew(<<"CONF");
name = Version-Test
author = Test <test\@example.com>
license = Perl_5
copyright_holder = Test

[\@Author::GETTY]
no_github = 1
$tag_format_line
CONF

    $dist_dir->child('lib', 'Version', 'Test.pm')->parent->mkpath;
    $dist_dir->child('lib', 'Version', 'Test.pm')->spew("package Version::Test;\n1;\n");

    for my $args (
      [qw(init -q)],
      [qw(add -A)],
      ['-c', 'user.email=test@example.com', '-c', 'user.name=Test', 'commit', '-q', '-m', 'init'],
      map { [ 'tag', $_ ] } @tags,
    ) {
      system('git', '-C', "$dist_dir", @$args) == 0
        or die "git @{$args} failed in $dist_dir: $?";
    }

    my $tzil = Dist::Zilla::Tester->from_config({
      dist_root => "$dist_dir",
    }, {
      tempdir_root => $tempdir,
      chrome => Dist::Zilla::Chrome::Term->new,
    });

    # The main module (where RewriteVersion looks first) must be gathered.
    $_->gather_files for @{ $tzil->plugins_with(-FileGatherer) };

    my $version = $tzil->version;
    my ($rewrite) = grep {
      $_->isa('Dist::Zilla::Plugin::RewriteVersion::Transitional')
    } @{ $tzil->plugins };
    return ($version, $rewrite->_fallback_version_provider_obj);
  };

  {
    my ($version, $next_version) = $version_from_tags->(undef, qw( 1.004 1.005 backup/foo ));
    isa_ok($next_version, 'Dist::Zilla::Plugin::Git::NextVersion', 'fallback provider');
    like('1.005', $next_version->version_regexp, 'Git::NextVersion matches the bare tag 1.005');
    unlike('backup/foo', $next_version->version_regexp, 'Git::NextVersion ignores backup/foo');
    is($version, '1.006', 'bare tag_format: 1.005 is the last release, 1.006 the next');
  }

  {
    my ($version, $next_version) = $version_from_tags->('v%v', qw( v1.005 backup/foo ));
    like('v1.005', $next_version->version_regexp, 'Git::NextVersion matches the tag v1.005');
    is($version, '1.006', 'tag_format v%v: v1.005 is the last release, 1.006 the next');
  }
};

done_testing;
