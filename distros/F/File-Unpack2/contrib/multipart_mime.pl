#! /usr/bin/perl
#
# multipart/* - handler for File::Unpack2
#
# 2012 (C) jw@suse.de, distribute under GPLv2
#
# my russian test.mht example uses \r\n to seperate header from body.
# Not sure if it is valid, but we should handle that correctly.

use MIME::Parser;
use Data::Dumper;

my $from = shift || die "usage: $0 INPUTFILE [OUTDIR]\n";
my $outdir = shift || "multipart_dir";

my $parser = new MIME::Parser;
$parser->output_under($outdir);
# $parser->output_dir($outdir);
# $parser->tmp_dir($outdir)
$parser->output_prefix("msg");

### Automatically attempt to RFC 2047-decode the MIME headers?
$parser->decode_headers(0);             ### default is false, not advisable

### Parse contained "message/rfc822" objects as nested MIME streams?
$parser->extract_nested_messages(1);    ### default is true

### Look for uuencode in "text" messages, and extract it?
$parser->extract_uuencode(1);           ### default is false

### Should we forgive normally-fatal errors?
$parser->ignore_errors(1);              ### default is true

### Ultra-tolerant mechanism:
my $entity = eval { $entity = $parser->parse_open($from) };
my $error = ($@ || $parser->last_error);

$entity->dump_skeleton;          # for debugging

die Dumper $entity, $error;
