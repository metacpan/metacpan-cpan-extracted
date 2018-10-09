use strict;
use warnings;

use File::Spec ();
use File::Slurp;
use File::Temp qw(tempfile);
use IO::Handle ();
use Test::More;

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

# this code creates the object which has a stringified path
{
    package FileObject;
    use Exporter qw(import);
    use overload
        q[""] => \&stringify,
        fallback => 1;

    sub new { bless { path => $_[1] }, $_[0] }

    sub stringify { $_[0]->{path} }
}

plan tests => 3 ;

my (undef, $path) = tempfile('tempXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);
my $data = "random junk\n";

# create an object with an overloaded path
my $obj = FileObject->new($path);

isa_ok($obj, 'FileObject');
is("$obj", $path, "object stringifies to path");

write_file($obj, $data);
my $read = read_file($obj);
is($data, $read, 'read_file of stringified object');

unlink $path;
