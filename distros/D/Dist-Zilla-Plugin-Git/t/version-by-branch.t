use strict;
use warnings;

use Test::DZil qw(dist_ini);

use Path::Tiny qw(path);
use Test::More 0.88;            # done_testing
use Test::Fatal;

use lib 't';
use Util qw(:DEFAULT zilla_version);

skip_unless_git_version('1.6.1'); # need --simplify-by-decoration

plan tests => 31;

init_test(
  add_files => {
    Changes => "Just getting started\n",
    'dist.ini' => dist_ini(
      {qw(
        name              Foo
        author            foobar
        license           Perl_5
        abstract          Test-Library
        copyright_holder  foobar
        copyright_year    2009
      )},
      [ 'Git::NextVersion', { version_by_branch => 1 } ],
      'FakeRelease',
    ),
  }, # end add_files
);

#---------------------------------------------------------------------
## shortcut for new tester object

my $cache = '.gitnxtver_cache';

sub _new_zilla {
  my ($rev, $tag) = @_;

  my %test_config;

  if ($rev) {
    my ($sha) = $git->rev_parse($rev);
    $test_config{add_files}{"source/$cache"} = "$sha $tag\n";
  }

  new_zilla_from_repo(\%test_config);
}

sub _zilla_version {
  _new_zilla(@_);
  zilla_version;
}

# Check the contents (or absence) of .gitnxtver_cache:
sub head_last_ver
{
  my ($last_ver) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  if (defined $last_ver) {
    my ($head) = $git->rev_parse('HEAD');

    is(slurp_text_file("source/$cache"), "$head $last_ver\n",
       "cache file contains $last_ver");
  } else {
    ok( !-f path($zilla->root)->child($cache), "no cache file created");
  }
} # end head_last_ver

# with no tags and no initialization, should get default
is( _zilla_version, "0.001", "works with no commits" );
head_last_ver(undef);

$git->add(".");
$git->commit({ message => 'import' });

# with no tags and no initialization, should get default
is( _zilla_version, "0.001", "default is 0.001" );
head_last_ver(undef);

# initialize it using V=
{
    local $ENV{V} = "1.23";
    is( _zilla_version, "1.23", "initialized with \$ENV{V}" );
    head_last_ver(undef);
}

# add a tag that doesn't match the regex
$git->tag("revert-me-later");
ok( (grep { /revert-me-later/ } $git->tag), "wrote revert-me-later tag" );

is( _zilla_version, "0.001", "default is 0.001" );
head_last_ver(undef);

# tag 1.2.3
append_and_add(Changes => "1.2.3 now\n");
$git->commit({ message => 'committing 1.2.3'});
$git->tag("v1.2.3");
ok( (grep { /v1\.2\.3/ } $git->tag), "wrote v1.2.3 tag" );

is( _zilla_version, "1.2.4", "initialized from last tag" );
head_last_ver("1.2.3");

# make a dev branch
$git->checkout(qw(-b dev));

# tag first dev release 1.3.0
append_and_add(Changes => "1.3.0 dev release\n");
$git->commit({ message => 'committing 1.3.0'});
$git->tag("v1.3.0");
ok( (grep { /v1\.3\.0/ } $git->tag), "wrote v1.3.0 tag" );

is( _zilla_version, "1.3.1", "initialized from 1.3.0 tag" );
head_last_ver("1.3.0");

# go back to master branch
$git->checkout(qw(master));

is( _zilla_version, "1.2.4", "initialized from 1.2.3 tag on master" );
head_last_ver("1.2.3");

# tag stable 1.2.4
append_and_add(Changes => "1.2.4 stable release\n");
$git->commit({ message => 'committing 1.2.4 on master'});
$git->tag("v1.2.4");
ok( (grep { /v1\.2\.4/ } $git->tag), "wrote v1.2.4 tag" );

is( _zilla_version, "1.2.5", "initialized from 1.2.4 tag" );
head_last_ver("1.2.4");

# go back to dev branch
$git->checkout(qw(dev));

append_and_add(Changes => "1.3.1 in progress\n");
$git->commit({ message => 'committing 1.3.1 change'});

is( _zilla_version, "1.3.1", "using dev branch 1.3.0 tag" );
head_last_ver("1.3.0");

# go back to master branch
$git->checkout(qw(master));

append_and_add(Changes => "1.2.5 still in progress\n");
$git->commit({ message => 'committing 1.2.5 change'});

is( _zilla_version, "1.2.5", "using master branch 1.2.4 tag" );
head_last_ver("1.2.4");

# see if it reads the cache
is( _zilla_version(qw(HEAD 1.2.6)), "1.2.7", "using (fake) cached 1.2.6 tag" );
head_last_ver("1.2.6");

# see if it ignores a stale cache
is( _zilla_version(qw(HEAD~1 1.2.6)), "1.2.5",
    "ignoring stale cached 1.2.6 tag" );
head_last_ver("1.2.4");

# see if it catches a duplicate version
_new_zilla(qw(HEAD 1.2.3));
is(
    exception { $zilla->build },
    undef,
    "builds with duplicate version",
);
is( $zilla->version, "1.2.4", "version is duplicate" );
like(
    exception { $zilla->release },
    qr/version 1\.2\.4 has already been tagged/,
    "don't release duplicate version",
);

#keep_tempdir;

done_testing;
