use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;

use Dist::Zilla::Util::FileGenerator;

run();
done_testing;
exit;

sub run {
    ok( Dist::Zilla::Util::FileGenerator->new( source => "moo", files => [] ) );
}
