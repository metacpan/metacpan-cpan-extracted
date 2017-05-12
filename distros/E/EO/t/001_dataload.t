# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'EO::Data' ); }

my $object = EO::Data->new ();
isa_ok ($object, 'EO::Data');
__END__


use EO::Data;

EO::Path

$request

my $data = EO::Data->new
    (
     content => 'data',
     mime => EO::Data::Mime->new('text/plain'),
     );


my $file = EO::Storage::File->new(uri => '/foo/new');


$data->storage($file);
$data->add_storage($file);
$data->save();

my $file = EO::Storage::File->new(uri => '/foo/existing');

my $data = $file->data();
$data->content('foo');
$data->save();







