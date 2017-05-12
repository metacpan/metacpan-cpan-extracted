#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

my ($fh, $file) = tempfile();

print $fh <<'EOT';
#!/usr/bin/perl
package My::Test;
use strict;
use warnings;

use Test::More;

use Fuckin::Lazy;

my $foo = { a => 1, b => 2 };
is_deeply(
    $foo,
    LAZY($foo),
    "Foo"
);

is_deeply($foo, LAZY($foo), "Foo");

is_deeply($foo, Fuckin'Lazy($foo), "Foo");

is_deeply($foo, Fuckin::Lazy($foo), "Foo");
EOT

close($fh);

require $file;

open($fh, '<', $file);
my $test = join '' => <$fh>;
is($test, <<'EOT', "Altered file");
#!/usr/bin/perl
package My::Test;
use strict;
use warnings;

use Test::More;

use Fuckin::Lazy;

my $foo = { a => 1, b => 2 };
is_deeply(
    $foo,
    {"a" => 1,"b" => 2},
    "Foo"
);

is_deeply($foo, {"a" => 1,"b" => 2}, "Foo");

is_deeply($foo, {"a" => 1,"b" => 2}, "Foo");

is_deeply($foo, {"a" => 1,"b" => 2}, "Foo");
EOT

done_testing;
