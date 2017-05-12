use strict;
use warnings;

use Test::More 0.88 tests => 9;

use lib 't';
use Util qw(:DEFAULT zilla_version);

init_test(corpus => 'version-default');

## shortcut for new tester object
sub new_zilla_version {
  new_zilla_from_repo;
  zilla_version;
}

## Tests start here

# with no tags and no initialization, should get default
is( new_zilla_version, "0.001", "works with no commits" );

$git->add(".");
$git->commit({ message => 'import' });

# with no tags and no initialization, should get default
is( new_zilla_version, "0.001", "default is 0.001" );

# initialize it
{
    local $ENV{V} = "1.23";
    is( new_zilla_version, "1.23", "initialized with \$ENV{V}" );
}

# add a tag that doesn't match the regex
$git->tag("revert-me-later");
ok( (grep { /revert-me-later/ } $git->tag), "wrote revert-me-later tag" );
{
    is( new_zilla_version, "0.001", "default is 0.001" );
}

# tag it
$git->tag("v1.2.3");
ok( (grep { /v1\.2\.3/ } $git->tag), "wrote v1.2.3 tag" );

{
    is( new_zilla_version, "1.2.4", "initialized from last tag" );
}

# tag it
$git->tag("v1.23");
ok( (grep { /v1\.23/ } $git->tag), "wrote v1.23 tag" );

{
    is( new_zilla_version, "1.24", "initialized from last tag" );
}



done_testing;
