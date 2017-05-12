use strict;
use warnings;

use Test::More 0.88 tests => 6;

use lib 't';
use Util qw(:DEFAULT zilla_version);

init_test(corpus => 'version-regexp');

## shortcut for new tester object
sub new_zilla_version {
  new_zilla_from_repo;
  zilla_version;
}

## Tests start here

$git->add(".");
$git->commit({ message => 'import' });

# with no tags and no initialization, should get default
is( new_zilla_version, "0.01", "default is 0.01" ); # set in dist.ini

# initialize it
{
  local $ENV{V} = "1.23";
  is( new_zilla_version, "1.23", "initialized with \$ENV{V}" );
}

# tag it
$git->tag("release-v1.2.3");
ok( (grep { /release-v1\.2\.3/ } $git->tag), "wrote v1.2.3 tag" );

{
  is( new_zilla_version, "v1.2.4", "initialized from last tag" );
}

# tag it
$git->tag("release-1.23");
ok( (grep { /release-1\.23/ } $git->tag), "wrote v1.23 tag" );

{
  is( new_zilla_version, "1.24", "initialized from last tag" );
}


done_testing;
