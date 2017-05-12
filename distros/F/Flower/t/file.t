use Test::More tests => 12;

use File::Temp qw/tempfile/;
use_ok 'Flower::File';

eval { my $file = Flower::File->new(); };
ok ($@, "empty constructor not allowed");

eval { my $file = Flower::File->new({filename => '/tmp/foo', size => 1}); };
ok ($@ =~ /parent/, "require parent");

eval { my $file = Flower::File->new({parent => {}, size => 1 }); };
ok ($@ =~ /filename/, "require filename");

eval { my $file = Flower::File->new({parent => {}, filename => '/tmp/foo' }); };
ok ($@ =~ /size/, "require size");


my $file = Flower::File->new({parent => {}, filename => '/tmp/bar', size => 16384});
ok ($file, 'created a file');

ok ($file =~ /16k/i,          'stringification');
ok ($file =~ /\/tmp\/bar/,    'stringification');
ok ($file =~ /\w+\-\w+\-\w+/, 'stringification (uuid)');

my ($fh, $filename) = tempfile();
print $fh "x" x 4096;
close $fh;

my $file_local = Flower::File->new_from_local_file({filename => $filename,
                  path => './',
                  parent => {}});
ok ($file_local, 'exists');
ok ($file_local->size == 4096, 'right size');
ok ($file_local->nice_size eq '4K');

unlink $filename;
