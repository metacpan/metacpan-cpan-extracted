use strict;
use warnings;

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Exception::Class ( 'Test::Generated::Exception' => {} );
use Test::PreloadedException;

is(
    $INC{'Test/Generated/Exception.pm'},
    $INC{'Exception/Class.pm'},
    '%INC entry for a generated class points at Exception/Class.pm',
);

isnt(
    $INC{q{Test/PreloadedException.pm}},
    $INC{q{Exception/Class.pm}},
    '%INC entry for a class defined in a real module file is not overwritten',
);

# require always joins the module part of the path with "/", but the lib dir from FindBin may use
# backslashes on Windows, so we only match the part that require builds.
like(
    $INC{q{Test/PreloadedException.pm}},
    qr{/Test/PreloadedException\.pm\z},
    q{%INC entry for a class defined in a real module file points at that file},
);

is(
    Test::PreloadedException->description,
    'preloaded',
    'class defined in a real module file works',
);

is(
    Test::PreloadedException->VERSION,
    42,
    'version defined in module is preserved',
);

done_testing();
