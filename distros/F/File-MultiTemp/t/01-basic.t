use v5.14;
use Test::Most;

use Scalar::Util qw/ openhandle refaddr /;

use File::MultiTemp;

my $files = File::MultiTemp->new(
    suffix => '.txt',
    template => 'file-KEY-XXXX', # There must be a minimum of 4 Xs
    unlink => 1,
    init => sub {
        my ($key, $path, $fh) = @_;
        my $tmp  = $path->cached_temp;
        my $name = $tmp->filename;
        like $name, qr/file-${key}/, 'filename has key';
        like $name, qr/\.txt$/, 'filename has key';
        say {$fh} $key;
    },
);

isa_ok($files, "File::MultiTemp");

ok openhandle( $files->file_handle("WWW") ), "open filehandle (new file)";

ok my $x = $files->file("XXX"), "file method";

ok exists $files->_files->{XXX}, "has key";

ok my $y = $files->file("XXX"), "file method";
is refaddr($x), refaddr($y), "returns same object";

ok openhandle( $files->file_handle("XXX") ), "open filehandle";

ok close( $files->file_handle("XXX") ), "forcibly close filehandle";

ok my $fh = $files->file_handle("XXX"), "re-opened file handle";
say {$fh} "ZZZ";

ok $files->file("YYY"), "file method";

ok openhandle( $files->file_handle("YYY") ), "open filehandle";

$files->close;

my $keys = $files->keys;
cmp_deeply $keys, set(qw/ WWW XXX YYY /), "keys";

my %found = map { $_ => 1 } (@$keys, 'ZZZ');

for my $file ( @{ $files->files } ) {
    my @lines = $file->lines( { chomp => 1 } );
    delete @found{@lines};
}

is_deeply \%found, { }, 'all expected lines';

done_testing;
