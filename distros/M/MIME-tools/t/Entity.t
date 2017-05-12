#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 39;

use MIME::Entity;
use MIME::Parser;

use lib qw( ./t );
use Globby;  # TODO: WTF?

my $line;
my $LINE;


#diag("Testing build()");
{local $SIG{__WARN__} = sub { die "caught warning: ",@_ };
 {   
     my $e = MIME::Entity->build(Path     => "./testin/short.txt");
     my $name = 'short.txt';
     my $got;
     
     #-----test------
     $got = $e->head->mime_attr('content-type.name');
     is($got, $name, 'Path: with no Filename, got default content-type.name');
     
     #-----test------
     $got = $e->head->mime_attr('content-disposition.filename');
     is($got, $name, 'Path: with no Filename, got default content-disp.filename');

     #-----test------
     $got = $e->head->recommended_filename;
     is($got, $name, 'Path: with no Filename, got default recommended filename');
 }
 { 
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/short.txt",
				 Filename => undef);
     my $got = $e->head->mime_attr('content-type.name');
     ok(!$got, 'Path: with explicitly undef Filename, got no filename');
     my $x = $e->stringify();
     my $version = $MIME::Entity::VERSION;
     my $desired = "Content-Type: text/plain\nContent-Disposition: inline\nContent-Transfer-Encoding: binary\nMIME-Version: 1.0\nX-Mailer: MIME-tools $version (Entity $version)\n\nDear «François Müller»,\n\nAs you requested, I have rewritten the MIME:: parser modules to support\nthe creation of MIME messages.\n\nEryq\n";
     is($x, $desired, 'Tested stringify');
 }

 { 
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/short.txt",
				 Filename => "foo.txt");
     my $got = $e->head->mime_attr('content-type.name');
     is($got, "foo.txt", "Path: verified explicit 'Filename'" );
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/sig"
				 );
     my $got = $e->head->mime_attr('content-type');
     is($got, 'text/plain', 'Type: default ok');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/sig",
				 Type     => "text/foo");
     my $got = $e->head->mime_attr('content-type');
     is($got, 'text/foo', 'Type: explicit ok');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/sig",
				 Encoding => '-SUGGEST');
     my $got = $e->head->mime_attr('content-transfer-encoding');
     is($got, '7bit', 'Encoding: -SUGGEST yields 7bit');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/short.txt",
				 Encoding => '-SUGGEST');
     my $got = $e->head->mime_attr('content-transfer-encoding');
     is($got, 'quoted-printable', 'Encoding: -SUGGEST yields qp');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Type     => 'image/gif',
				 Path     => "./testin/mime-sm.gif",
				 Encoding => '-SUGGEST');
     my $got = $e->head->mime_attr('content-transfer-encoding');
     is($got, 'base64', 'Encoding: -SUGGEST yields base64');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/short.txt"
				 );
     my $got = $e->head->mime_attr('content-type.charset');
     ok(!$got, 'Charset: default ok');
 }
 {
     #-----test------
     my $e = MIME::Entity->build(Path     => "./testin/short.txt",
				 Charset  => 'iso8859-1');
     my $got = $e->head->mime_attr('content-type.charset');
     is($got, 'iso8859-1', 'Charset: explicit');
 }

 {
     #-----test------
     my $croaked = 1;
     eval {
	     my $e = MIME::Entity->build(Type => 'message/rfc822',
					 Encoding => 'base64',
					 Data => "Subject: phooey\n\nBlat\n");
	     $croaked = 0;
     };
     ok($croaked, 'MIME::Entity->build croaked on message/rfc822 with base64 encoding');
     ok($@ =~ /can't have encoding base64 for message type message\/rfc822/,
	'and it croaked with expected error.');
 }

 {
     #-----test------
     my $croaked = 1;
     eval {
	     my $e = MIME::Entity->build(Type => 'message/global',
					 Encoding => 'base64',
					 Data => "Subject: phooey\n\nBlat\n");
	     $croaked = 0;
     };
     ok(!$croaked, 'MIME::Entity->build did not croak on message/global with base64 encoding');
 }
 {
     #-----test------
     my $croaked = 1;
     eval {
	     my $e = MIME::Entity->build(Type => 'multipart/ALTERNATIVE',
					 Encoding => 'base64',
					 Data => "Subject: phooey\n\nBlat\n");
	     $croaked = 0;
     };
     ok($croaked, 'MIME::Entity->build croaked on multipart/alternative with base64 encoding');
     ok($@ =~ /can't have encoding base64 for message type multipart\/ALTERNATIVE/,
	'and it croaked with expected error.');
 }
}

#diag("Create an entity");

# Create the top-level, and set up the mail headers in a couple
# of different ways:
my $top = MIME::Entity->build(Type  => "multipart/mixed",
			      -From => "me\@myhost.com",
			      -To   => "you\@yourhost.com");
$top->head->add('subject', "Hello, nurse!");
$top->preamble([]);
$top->epilogue([]);

# Attachment #0: a simple text document: 
attach $top  Path=>"./testin/short.txt";

# Attachment #1: a GIF file:
attach $top  Path        => "./testin/mime-sm.gif",
             Type        => "image/gif",
             Encoding    => "base64",
	     Disposition => "attachment";

# Attachment #2: a document we'll create manually:
my $attach = new MIME::Entity;
$attach->head(new MIME::Head ["X-Origin: fake\n",
			      "Content-transfer-encoding: quoted-printable\n",
			      "Content-type: text/plain\n"]);
$attach->bodyhandle(new MIME::Body::Scalar);
my $io = $attach->bodyhandle->open("w");
$io->print(<<EOF
This  is the first line.
This is the middle.
This is the last.
EOF
);
$io->close;
$top->add_part($attach);

# Attachment #3: a document we'll create, not-so-manually:
$LINE = "This is the first and last line, with no CR at the end.";
$attach = attach $top Data=>$LINE;

#-----test------
unlink globby("testout/entity.msg*");

#diag("Check body");

my $bodylines = $top->parts(0)->body;
is( ref $bodylines, 'ARRAY', '->body returns an array reference');
is( scalar @$bodylines, 6, '... of the correct size');

my $preamble_str = join '', @{$top->preamble || []};
my $epilogue_str = join '', @{$top->epilogue || []};

#diag("Output msg1 to explicit filehandle glob");
open TMP, ">testout/entity.msg1" or die "open: $!";
$top->print(\*TMP);
close TMP;
#-----test------
ok(-s "testout/entity.msg1", 
       "wrote msg1 to filehandle glob");

#diag("Output msg2 to selected filehandle");
open TMP, ">testout/entity.msg2" or die "open: $!";
my $oldfh = select TMP;
$top->print;
select $oldfh;
close TMP;
#-----test------
ok(-s "testout/entity.msg2", 
       "write msg2 to selected filehandle");

#diag("Compare");
# Same?
is(-s "testout/entity.msg1", -s "testout/entity.msg2",
	"message files are same length");

#diag("Parse it back in, to check syntax");
my $parser = new MIME::Parser;
$parser->output_dir("testout");
open IN, "./testout/entity.msg1" or die "open: $!";
$top = $parser->parse(\*IN);
#diag($parser->results->msgs);

#-----test------
ok($top, "parsed msg1 back in");

my $preamble_str2 = join '', @{$top->preamble || []};
my $epilogue_str2 = join '', @{$top->epilogue || []};
#-----test------
is($preamble_str, $preamble_str2, 'preamble strings match');

#-----test------
is($epilogue_str, $epilogue_str2, "epilogue strings match");

#diag("Check the number of parts");
is($top->parts, 4,
       "number of parts is correct (4)");

#diag("Check attachment 1 [the GIF]");
my $gif_real = (-s "./testin/mime-sm.gif");
my $gif_this = (-s "./testout/mime-sm.gif");
#-----test------
is($gif_real, $gif_this,
	"GIF is right size (real = $gif_real, this = $gif_this)");
my $part = ($top->parts)[1];
#-----test------
is($part->head->mime_type, 'image/gif', "GIF has correct MIME type");

#diag("Check attachment 3 [the short message]");
$part = ($top->parts)[3];
$io = $part->bodyhandle->open("r");
$line = ($io->getline);
$io->close;
#-----test------
is($line, $LINE, 
	"getline gets correct value (IO = $io, <$line>, <$LINE>)");
#-----test------
is($part->head->mime_type, 'text/plain', 
	"MIME type okay");
#-----test------
is($part->head->mime_encoding, 'binary',
	"MIME encoding okay");

#diag("Write it out, and compare");
open TMP, ">testout/entity.msg3" or die "open: $!";
$top->print(\*TMP);
close TMP;
#-----test------
is(-s 'testout/entity.msg2', -s 'testout/entity.msg3', 'msg2 same size as msg3');

#diag("Duplicate");
my $dup = $top->dup;
open TMP, ">testout/entity.dup3" or die "open: $!";
$dup->print(\*TMP);
close TMP;
my $msg3_s = -s "testout/entity.msg3";
my $dup3_s = -s "testout/entity.dup3";
#-----test------
is($msg3_s, $dup3_s,
	"msg3 size ($msg3_s) is same as dup3 size ($dup3_s)");

#diag("Test signing");
$top->sign(File=>"./testin/sig");
$top->remove_sig;
$top->sign(File=>"./testin/sig2", Remove=>56);
$top->sign(File=>"./testin/sig3");

#diag("Write it out again, after synching");
$top->sync_headers(Nonstandard=>'ERASE',
		   Length=>'COMPUTE');	
open TMP, ">testout/entity.msg4" or die "open: $!";
$top->print(\*TMP);
close TMP;

## Test that parts() replacement works
my @newparts = $top->parts;
pop @newparts;
$top->parts( \@newparts );

is($top->parts, 3, "number of parts is correct (3)");

$bodylines = $top->parts(0)->body;
is( ref $bodylines, 'ARRAY', '->body returns an array reference');
is( scalar @$bodylines, 12, '... of the correct size (12 incl. signature)');

$part = ($top->parts)[1];
#-----test------
is($part->head->mime_type, 'image/gif', "GIF has correct MIME type");

#diag("Purge the files");
$top->purge;
#-----test------
ok(!-e "./testout/mime-sm.gif", "purge worked");

1;
