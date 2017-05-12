
# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 12;
use Data::Dumper;
BEGIN { use_ok( 'EO::File' ); }

eval {
    my $file = EO::File->new(path => '/doesntexistanywhere/null');
    $file->load();
};
isa_ok($@, 'EO::Error::File');
isa_ok($@, 'EO::Error::File::NotFound');
like($@, qr/file not found/);
is($@->filename, '/doesntexistanywhere/null', "right filename");

eval {
    my $file = EO::File->new(path => '/');
    $file->load();
};
isa_ok($@, 'EO::Error::File');
isa_ok($@, 'EO::Error::File::IsDirectory');
like($@, qr/path is a directory/);



my $file = EO::File->new->path('t/baz');

my $data = $file->load();
is($data->content,'FOOOOOBAAAAAR');
is(${$data->content_ref},'FOOOOOBAAAAAR');

$data->content('hi');
is($data->content,'hi');

undef $file;
undef $data;

my $path = Path::Class::File->new('t/test.txt');

$file = EO::File->new(path => $path);
$data = EO::Data->new()->content("content");

$data->storage($file);
$data->save();

{

    my $file2 = EO::File->new(path => $path);
    my $data2 = $file2->load();
    is($data2->content, "content");
}
$file->unlink();
undef($file);

__END__
EO::Data


EO::Data::Type::FileExtension
EO::Data::Type::Mime
EO::Data::ByteCount
EO::DateTime

EO::Storage
EO::File






