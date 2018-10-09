use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);
use File::Slurp qw(read_file write_file);
use Scalar::Util qw(blessed);
use Test::More ;

plan tests => 12;

# the following mimics the parts from Path::Class causing
# problems with File::Slurp
{
    package FileObject;
    use strict;
    use warnings;
    use overload
        q[""] => \&stringify, fallback => 1;

    sub new {
        return bless { path => $_[1] }, $_[0]
    }

    sub stringify {
        return $_[0]->{path}
    }
}

my $path = temp_file_path();
my $data = "random junk\n";

# create an object
my $obj = FileObject->new($path);
isa_ok($obj, 'FileObject');
is("$obj", $path, "check that the object correctly stringifies");
ok(!($obj && ref($obj) && blessed($obj) && $obj->isa('GLOB')), "FileObject isn't a glob");
ok(!($obj && ref($obj) && blessed($obj) && $obj->isa('IO')), "FileObject isn't an IO");

my $io = IO::Handle->new();
isa_ok($io, 'IO::Handle');
ok($io && ref($io) && blessed($io) && $io->isa('GLOB'), "IO::Handle is a glob");
ok(!($io && ref($io) && blessed($io) && $io->isa('IO')), "IO::Handle isn't an IO");

SKIP: {
    open(FH, '<', $0) or skip 3, "Can't open $0: $!";
    my $fh = *FH{IO};
    my $glob = *FH{GLOB};
    ok($fh && ref($fh) && blessed($fh) && $fh->isa('IO'), '$fh is an IO');
    ok(!($glob && ref($glob) && blessed($glob) && $glob->isa('GLOB')), '$glob is an GLOB');
}

SKIP: {
    # write something to that file
    open(FILE, '>', "$obj") or skip 4, "can't write to '$path': $!";
    print FILE $data;
    close(FILE);

    # pass it to read_file()
    my ($res, $warn, $err) = trap_function(\&read_file, $obj);
    is($res, $data, "read_file: file object: right content");
    ok(!$warn, "read_file: file object: no warnings!");
    ok(!$err, "read_file: file object: no exceptions!");
}

unlink $path;
