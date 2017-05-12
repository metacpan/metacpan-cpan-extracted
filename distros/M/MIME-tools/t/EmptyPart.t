#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 6;

use MIME::Tools;

use lib "./t";
use Globby;

use MIME::Parser;


my $DIR = "./testout";
((-d $DIR) && (-w $DIR)) or die "no output directory $DIR";
unlink globby("$DIR/[a-z]*");

my $parser = MIME::Parser->new();
$parser->output_dir($DIR);

my $data = <<END;
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="foo"

--foo
--foo
--foo
--foo--
END

my $entity = $parser->parse_data($data);
ok($entity, 'Got an entity');
is($entity->mime_type, 'multipart/alternative');
is($entity->parts, 3, 'Got three parts');
is($entity->parts(0)->mime_type, 'text/plain');
is($entity->parts(1)->mime_type, 'text/plain');
is($entity->parts(2)->mime_type, 'text/plain');

