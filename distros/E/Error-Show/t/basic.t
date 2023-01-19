use strict;
use warnings;
use feature ":all";
use Test::More;

use Error::Show;

use File::Basename qw<dirname>;
my $file=__FILE__;

$@=undef;
my $dir=dirname $file;
my $context;


# Test context is empty stirng when no error
eval {
  require "./$dir/syntax-ok.pl";
};
$context=Error::Show::context;
ok $context eq "", "Implicit Error variable";

$context=Error::Show::context $@;
ok $context eq "", "Explicit Error variable";

$context=Error::Show::context error=>$@;
ok $context eq "", "KV Error variable";

# Test context is empty stirng when no error
$@=undef;
eval {
  require "./$dir/syntax-warning.pl";
};
$context=Error::Show::context;
ok $context eq "", "Implicit Error variable";

$context=Error::Show::context $@;
ok $context eq "", "Explicit Error variable";

$context=Error::Show::context error=>$@;
ok $context eq "", "KV Error variable";

# Test context is not empty istring when with error
$@=undef;
eval {
  require "./$dir/syntax-error.pl";

};
$context=Error::Show::context;
ok $context ne "", "Implicit Error variable";

$context=Error::Show::context $@;
ok $context ne "", "Explicit Error variable";

$context=Error::Show::context error=>$@;
ok $context ne "", "KV Error variable";

done_testing;
