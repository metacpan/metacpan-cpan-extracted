#!perl -T

package First;

use File::Spec;
use File::PlainPath qw(path -separator -);

our $path = path 'foo-bar+foo-bar+foo';


package Second;

use File::Spec;
use File::PlainPath qw(path -separator +);

our $path = path 'foo-bar+foo-bar+foo';


package test_packages;

use Test::More;

is($First::path, File::Spec->catfile('foo', 'bar+foo', 'bar+foo'));
is($Second::path, File::Spec->catfile('foo-bar', 'foo-bar', 'foo'));

done_testing;
