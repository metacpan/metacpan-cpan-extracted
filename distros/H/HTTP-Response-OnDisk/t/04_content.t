
use strict;
use Test::More (tests => 9);
use HTTP::Response::OnDisk;

my $dir = Path::Class::Dir->new('t/data');
my $r = HTTP::Response::OnDisk->new(200, "OK", undef, undef,
    { dir => $dir }
);

ok($r);
ok(-d $dir, "storage directory is created");
isa_ok($r->storage, 'File::Temp');
ok(-f $r->storage->filename);

my @data = (
    "abcdefghijklmnopqrstuvwxyz",
    "0123456789"
);

for my $data (@data) {
    eval { $r->add_content($data) };
    ok(!$@);
}

is( join('', @data), $r->content );

# Make sure content truncate works
$r->content("foobar");

is( "foobar", $r->content );

my $file = $r->storage->filename;
undef $r; # trigger cleanup

ok(! -e $file, "temporary file cleaned up");

END {
    $dir->remove;
}
