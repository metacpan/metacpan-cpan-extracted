# -*- perl -*-

# t/05_attachment.t - check module for attachment handling

use Test::Most tests => 34 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Path::Class::File;

my $pc_file = Path::Class::File->new('t/testfile.txt');

my $attachment1 = Mail::Builder::Attachment->new('t/testfile.txt');
my $attachment2 = Mail::Builder::Attachment->new({ file => $pc_file });
my $attachment3 = Mail::Builder::Attachment->new({ file => $pc_file->openr });
my $attachment4 = Mail::Builder::Attachment->new(\'File content');
my $attachment5 = Mail::Builder::Attachment->new('t/testfile.pdf','document.pdf');

isa_ok ($attachment1, 'Mail::Builder::Attachment');
isa_ok ($attachment2, 'Mail::Builder::Attachment');
isa_ok ($attachment3, 'Mail::Builder::Attachment');
isa_ok ($attachment4, 'Mail::Builder::Attachment');
isa_ok ($attachment5, 'Mail::Builder::Attachment');

is($attachment1->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment2->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment3->filecontent,'This is a test file for the attachment test!','Content ok');
is($attachment4->filecontent,'File content','Content ok');

like($attachment1->filename,qr't[\\\/]testfile\.txt$','Filename ok');
like($attachment2->filename,qr't[\\\/]testfile\.txt$','Filename ok');
is($attachment3->filename,undef,'Filename missing ok');
is($attachment4->filename,undef,'Filename missing ok');
like($attachment5->filename,qr't[\\\/]testfile\.pdf$','Filename ok');

isa_ok($attachment1->filename,'Path::Class::File');
isa_ok($attachment2->filename,'Path::Class::File');
isa_ok($attachment5->filename,'Path::Class::File');

is($attachment1->mimetype,'text/plain','MIME type ok');
is($attachment2->mimetype,'text/plain','MIME type ok');
is($attachment3->mimetype,'application/octet-stream','Fallback MIME type ok');
is($attachment4->mimetype,'application/octet-stream','Fallback MIME type ok');
is($attachment5->mimetype,'application/pdf','MIME type ok');

$attachment3->mimetype('text/plain');
is($attachment3->mimetype,'text/plain','MIME type ok');
is($attachment3->has_cache,'','Has no cache set');
throws_ok { $attachment4->mimetype('brokenmime') } qr/pass the type constraint because: 'brokenmime' is not a valid MIME-type/, 'Broken mimetype not accepted';

throws_ok { $attachment3->serialize } qr/Could not determine the attachment name automatically/,'Name check works';
$attachment3->name('testattachment.txt');
my $serialized_attachment3 = $attachment3->serialize;
isa_ok($serialized_attachment3,'MIME::Entity');
is($serialized_attachment3->mime_type,'text/plain','MIME type set');
is($serialized_attachment3->head->get('Content-Disposition'),qq[attachment; filename="testattachment.txt"\n],'Content-Disposition set');
is($serialized_attachment3->head->get('Content-Transfer-Encoding'),qq[base64\n],'Encoding set');
like($serialized_attachment3->stringify,qr/VGhpcyBpcyBhIHRlc3QgZmlsZSBmb3IgdGhlIGF0dGFjaG1lbnQgdGVzdCE=/,'Content encoded');

is($attachment3->has_cache,1,'Has cache set');
isa_ok($attachment3->cache,'MIME::Entity');

$attachment3->name('test.txt');
is($attachment3->has_cache,'','Has no cache set');
