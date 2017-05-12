
use strict;
use Test::More tests => 30;

BEGIN { use_ok( 'MIME::Fast' ); }

can_ok('MIME::Fast::Message', 'get_content_type');

pass("module loaded");

#
# Testing message parsing
# ---------------------------------------

# open a file
if (!open(M,"<test.eml")) {
  fail("Can not open test.eml: $!");
} else {
  pass("file test.eml is opened");
}

# create a stream
my $str = new MIME::Fast::Stream(\*M);
isa_ok($str, 'MIME::Fast::Stream');

my $msg = MIME::Fast::Parser::construct_message($str);
isa_ok($msg, 'MIME::Fast::Message');

undef $msg;
pass("Message destruction works");

my $parser = new MIME::Fast::Parser();
isa_ok($parser, 'MIME::Fast::Parser');

undef $str;
seek(M, 0, 0) || die "$!";
$str = new MIME::Fast::Stream(\*M);

#
# Testing parsing and header callback
# ---------------------------------------

$parser->init_with_stream($str);
$parser->set_header_regex ('^F', sub {
    cmp_ok($_[1],'=~',/^From/,"From: header found");
    # print 'REGEX -' . join(":",@_) . "-\n";
  }, ' test regex header');

#sub x {
#  print 'REGEX: ' . join(":",@_) . ":\n";
#};

#$parser->set_header_regex ('^F', \&x,
#  ' test regex header');

$msg = $parser->construct_message();
isa_ok($msg, 'MIME::Fast::Message');
isa_ok($msg, 'MIME::Fast::Object');

my $part = $msg->get_mime_part;
isa_ok($part, 'MIME::Fast::MultiPart');

isnt($msg->get_header('X-Subject'),undef,'get arbitrary header');

$part = $part->get_part(0,0);
isa_ok($part, 'MIME::Fast::Part');

$part->set_content_md5("dummy");
my $md5sum = $part->get_content_md5();
cmp_ok($md5sum, 'eq', 'dummy', 'Setting Content-MD5 to dummy variable');

$part->set_content_md5();
my $md5sum = $part->get_content_md5();
cmp_ok($md5sum, 'eq', 'zmJi1SLBO1X0WArn5p8Keg==', 'Calculate Content-MD5');

is(MIME::Fast::Part::encoding_to_string($part->get_encoding), 'quoted-printable');

#
# Testing tied message header
# ---------------------------------------

my %header;
tie %header, 'MIME::Fast::Hash::Header', $msg;
isa_ok(\%header, 'HASH');

$header{'From'} = 'John Doe <john@domain>';
undef $header{'X-Info'};
if (is($header{'X-Info'},undef)) {
  # diag('deleting message hash header ok');
} else {
  diag('Can not delete message header from tied hash');
}

$header{'X-Info'} = 'Normal one arbitrary header';
$header{'X-Info'} = ['This is','Multiline X-Info header'];
isa_ok($header{'X-Info'},'ARRAY') || diag('Can not get two headers as an ARRAY');

cmp_ok(scalar(@{$header{'X-Info'}}),'==',2,'setting header hash');

undef $header{'To'};

untie %header;
# you have to untie %header before undef, otherwise you would empty message headers 

undef %header; # headers in a message are untouched - just a tied hash

is($msg->get_header('X-Info'), 'Multiline X-Info header');


#
# Testing calling subroutines
# ---------------------------------------

sub test_part {
  isa_ok($_[0], 'MIME::Fast::Object');
  is($_[1],'test data');
}

$msg->get_mime_part->foreach('test_part', 'test data');

undef $msg;
pass("Message destruction works");

undef $str;
pass("Stream destruction works");

if (!close(M)) {
  fail("closing filehandle fails!");
} else {
  pass("closing filehandle works");
}

#
# Testing misc utils function
# ---------------------------------------

# Mime::Fast::Param
my $param = new MIME::Fast::Param("charset=\"iso8859-2\"");
isa_ok($param, 'MIME::Fast::Param');

my $content = "Content-Type: text/html";
$param->write_to_string(1, $content);

is($content,'Content-Type: text/html; charset=iso8859-2', 'Param::write_to_string works');

undef $param;
pass("Param destruction works");

