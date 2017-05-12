# -*- perl -*-

# t/06_image.t - check module for inline image handling

use Test::Most tests => 22 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Path::Class::File;

my $pc_file = Path::Class::File->new('t/testfile.gif');

my $image1 = Mail::Builder::Image->new('t/testfile.gif');
my $image2 = Mail::Builder::Image->new({ file => $pc_file });
my $image3 = Mail::Builder::Image->new({ file => $pc_file->openr });
my $image4 = Mail::Builder::Image->new('t/testfile.gif','test4','image/gif');

isa_ok ($image1, 'Mail::Builder::Image');
isa_ok ($image2, 'Mail::Builder::Image');
isa_ok ($image3, 'Mail::Builder::Image');
isa_ok ($image4, 'Mail::Builder::Image');

like($image1->filename,qr't[\\\/]testfile\.gif$','Filename ok');
like($image2->filename,qr't[\\\/]testfile\.gif$','Filename ok');
is($image3->filename,undef,'Filename missing ok');
like($image4->filename,qr't[\\\/]testfile\.gif$','Filename missing ok');

isa_ok($image1->filename,'Path::Class::File');
isa_ok($image2->filename,'Path::Class::File');

is($image1->mimetype,'image/gif','MIME type ok');
is($image2->mimetype,'image/gif','MIME type ok');
is($image3->mimetype,'image/gif','Auto MIME type ok');
is($image4->mimetype,'image/gif','Set MIME type ok');

$image3->mimetype('image/png');
is($image3->mimetype,'image/png','MIME type ok');
throws_ok { $image4->mimetype('text/plain') } qr/pass the type constraint because: 'text\/plain' is not a valid image MIME-type/, 'Broken mimetype not accepted';

throws_ok { $image3->serialize } qr/Could not determine the image id automatically/,'Id check works';
$image3->id('test3');
my $serialized_image3 = $image3->serialize;
isa_ok($serialized_image3,'MIME::Entity');
is($serialized_image3->mime_type,'image/png','MIME type set');
is($serialized_image3->head->get('Content-Disposition'),qq[inline\n],'Content-Disposition set');
is($serialized_image3->head->get('Content-Transfer-Encoding'),qq[base64\n],'Encoding set');
like($serialized_image3->stringify,qr/R0lGODlhEAAFAIAAAP\/\/\/wAAACwAAAAAEAAFAAACEoxhAXiJq/,'Content encoded');
