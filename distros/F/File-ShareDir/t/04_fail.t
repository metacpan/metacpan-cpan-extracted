#!perl

use strict;
use warnings;

use Cwd            ('abs_path');
use File::Basename ('dirname');
use File::Path     ('make_path', 'remove_tree');
use File::Spec     ();
use POSIX;
use Test::More;

sub dies
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $code    = shift;
    my $pattern = shift;
    my $message = shift || 'Code dies as expected';
    my $rv      = eval { &$code() };
    my $err     = $@;
    like($err, $pattern, $message);
}

use File::ShareDir ':ALL';

my $testlib = File::Spec->catdir(abs_path(dirname($0)), "lib");
unshift @INC, $testlib;

use_ok("ShareDir::TestClass");

my $fh;
my $testautolib     = File::Spec->catdir($testlib,     "auto");
my $testsharedirold = File::Spec->catdir($testautolib, qw(ShareDir TestClass));

END { remove_tree($testautolib); }

remove_tree($testautolib);
make_path($testautolib, {mode => 0700});
sysopen($fh, File::Spec->catfile($testautolib, qw(noread.txt)), O_RDWR | O_CREAT, 0100) or diag("$!");
close($fh);

my $NO_PERMISSION_CHECK = -r File::Spec->catfile($testautolib, qw(noread.txt));

dies(sub { File::ShareDir::_DIST("ShareDir::TestClass") }, qr/Not a valid distribution name/, "Not a valid distribution name");
dies(
    sub {
        File::ShareDir::_FILE(File::Spec->catfile($testsharedirold, "file.txt"));
    },
    qr/Cannot use absolute file name/,
    "Cannot use absolute file name"
);

dies(sub { module_dir() },   qr/Not a valid module name/, 'No params to module_dir dies');
dies(sub { module_dir('') }, qr/Not a valid module name/, 'Null param to module_dir dies');
dies(
    sub { module_dir('File::ShareDir::Bad') },
    qr/Module 'File::ShareDir::Bad' is not loaded/,
    'Getting module dir for known non-existent module dies',
);
# test from RT#125582
dies(
    sub { dist_file('File-ShareDir', 'file/name.txt'); },
    qr,Failed to find shared file 'file/name.txt' for dist 'File-ShareDir',,
    "Getting non-existent file dies"
);

remove_tree($testautolib);

dies(sub { my $dist_dir = dist_dir('ShareDir-TestClass'); }, qr/Failed to find share dir for dist/, "No module directory");
dies(sub { my $module_dir = module_dir('ShareDir::TestClass'); }, qr/No such directory/, "Old module directory but file");

make_path(dirname($testsharedirold), {mode => 0700});
make_path($testsharedirold,          {mode => 0100});

SKIP:
{
    skip("Root always has read permissions", 1) if $NO_PERMISSION_CHECK;
    dies(
        sub { my $module_dir = module_dir('ShareDir::TestClass'); },
        qr/No read permission/,
        "New module directory without read permission"
    );
}

my $testsharedirnew = File::Spec->catdir($testautolib, qw(share dist ShareDir-TestClass));
make_path(dirname($testsharedirnew), {mode => 0700});
make_path($testsharedirnew,          {mode => 0100});

SKIP:
{
    skip("Root always has read permissions", 1) if $NO_PERMISSION_CHECK;
    dies(
        sub { my $dist_dir = dist_dir('ShareDir-TestClass'); },
        qr/but no read permissions/,
        "New module directory without read permission"
    );
}

remove_tree($testautolib);
open($fh, ">", $testsharedirold);
close($fh);

dies(sub { my $module_dir = module_dir('ShareDir::TestClass'); }, qr/No such directory/, "Old module directory but file");
dies(sub { my $dist_dir = dist_dir('ShareDir-TestClass'); }, qr/Failed to find share dir for dist/,
    "Old dist directory but file");
dies(
    sub { my $dist_file = dist_file('ShareDir-TestClass', 'noread.txt'); },
    qr/Failed to find shared file/,
    "Old dist directory but file"
);

remove_tree($testautolib);
make_path($testsharedirold, {mode => 0700});

sysopen($fh, File::Spec->catfile($testsharedirold, qw(noread.txt)), O_RDWR | O_CREAT, 0200) or diag("$!");
print $fh "Moep\n";
close($fh);

SKIP:
{
    skip("Root always has read permissions", 3) if $NO_PERMISSION_CHECK;
    dies(sub { my $dist_file = dist_file('ShareDir-TestClass', 'noread.txt'); }, qr/No read permission/, "Unreadable dist_file");
    dies(
        sub { my $module_file = module_file('ShareDir::TestClass', 'noread.txt'); },
        qr/No read permission/,
        "Unreadable module_file"
    );
    dies(
        sub { my $class_file = class_file('ShareDir::TestClass', 'noread.txt'); },
        qr/cannot be read, no read permissions/,
        "Unreadable class_file"
    );
}

dies(
    sub { my $module_file = module_file('ShareDir::TestClass', 'noehere.txt'); },
    qr/does not exist in module dir/,
    "Unavailable module_file"
);

dies(
    sub { my $class_file = class_file('ShareDir::TestClass', 'noehere.txt'); },
    qr/does not exist in class or parent shared files/,
    "Unavailable class_file"
);

make_path(File::Spec->catdir($testsharedirold, "weird.dir"), {mode => 0700});
dies(sub { my $dist_file = dist_file('ShareDir-TestClass', 'weird.dir'); }, qr/No such file/, "Dir instead of file");

eval <<EOM;
package Module::WithOut::File;

sub new { return bless {}, __PACKAGE__ }

1;
EOM
$INC{'Module/WithOut/File.pm'} = '1';

dies(sub { my $module_dir = module_dir('Module::WithOut::File'); }, qr/Failed to find base dir/, "No really a loaded module ...");

SCOPE:
{
    my @TEST_INC = @INC;
    local @INC = (undef, Module::WithOut::File->new(), @TEST_INC);
    my $dist_dir = dist_dir('ShareDir-TestClass');
    ok($dist_dir, "Found dist_dir even with weird \@INC");
}

dies(
    sub { File::ShareDir::_DIST(Module::WithOut::File->new()) },
    qr/Not a valid distribution name/,
    "Object instead of distribution"
);
dies(sub { File::ShareDir::_FILE(Module::WithOut::File->new()) }, qr/Did not pass a file name/, "Did not pass a file name");

done_testing;
