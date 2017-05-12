#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 31;

use MIME::Tools;

use lib "./t";
use Globby;

use MIME::Parser;

# Set the counter, for filenames:
my $Counter = 0;

# Check and clear the output directory:
my $DIR = "./testout";
((-d $DIR) && (-w $DIR)) or die "no output directory $DIR";
unlink globby("$DIR/[a-z]*");


#------------------------------------------------------------
# BEGIN
#------------------------------------------------------------

my $parser;
my $entity;
my $msgno;
my $infile;
my $type;
my $enc;


#------------------------------------------------------------
package MyParser;
@MyParser::ISA = qw(MIME::Parser);
sub output_path {
    my ($parser, $head) = @_;

    # Get the recommended filename:
    my $filename = $head->recommended_filename;
    if (defined($filename) && $parser->evil_filename($filename)) {
##	diag("Parser.t: ignoring an evil recommended filename ($filename)");
	$filename = undef;      # forget it: it was evil
    }
    if (!defined($filename)) {  # either no name or an evil name
	++$Counter;
	$filename = "message-$Counter.dat";
    }

    # Get the output filename:
    my $outdir = $parser->output_dir;
    "$outdir/$filename";
}
package main;

#------------------------------------------------------------

$parser = new MyParser;
$parser->output_dir($DIR);

#------------------------------------------------------------
##diag("Read a nested multipart MIME message");
#------------------------------------------------------------
open IN, "./testmsgs/multi-nested.msg" or die "open: $!";
$entity = $parser->parse(\*IN);
ok($entity, "parse of nested multipart");

#------------------------------------------------------------
##diag("Check the various output files");
#------------------------------------------------------------
is(-s "$DIR/3d-vise.gif", 419, "vise gif size ok");
is(-s "$DIR/3d-eye.gif" , 357, "3d-eye gif size ok");
for $msgno (1..4) {
    ok(-s "$DIR/message-$msgno.dat", "message $msgno has a size");
}

#------------------------------------------------------------
##diag("Same message, but CRLF-terminated and no output path hook");
#------------------------------------------------------------
$parser = new MIME::Parser;
$parser->output_dir($DIR);
open IN, "./testmsgs/multi-nested2.msg" or die "open: $!";
$entity = $parser->parse(\*IN);
ok($entity, "parse of CRLF-terminated message");

#------------------------------------------------------------
##diag("Read a simple in-core MIME message, three ways");
#------------------------------------------------------------
my $data_scalar = <<EOF;
Content-type: text/html

<H1>This is test one.</H1>

EOF
my $data_scalarref = \$data_scalar;
my $data_arrayref  = [ map { "$_\n" } (split "\n", $data_scalar) ];

$parser->output_to_core('ALL');
foreach my $data_test ($data_scalar, $data_scalarref, $data_arrayref) {
    $entity = $parser->parse_data($data_test);
    isa_ok($entity, 'MIME::Entity');
    is($entity->head->mime_type, 'text/html', 'type is text/html');
}
$parser->output_to_core('NONE');


#------------------------------------------------------------
##diag("Simple message, in two parts");
#------------------------------------------------------------
$entity = $parser->parse_two("./testin/simple.msgh", "./testin/simple.msgb");
my $es = ($entity ? $entity->head->get('subject',0) : '');
like($es,  qr/^Request for Leave$/, "	parse of 2-part simple message (subj <$es>)");


# diag('new_tmpfile(), with real temp file');
{
	my $fh;
	eval {
		local $parser->{MP5_TmpToCore} = 0;
		$fh = $parser->new_tmpfile();
	};
	ok( ! $@, '->new_tmpfile() lives');
	ok( $fh->print("testing\n"), '->print on fh ok');

	ok( $fh->seek(0,0), '->seek on fh ok');
	my $line = <$fh>;
	is( $line, "testing\n", 'Read line back in OK');
}

# diag('new_tmpfile(), with in-core temp file');
{
	my $fh;
	eval {
		local $parser->{MP5_TmpToCore} = 1;
		$fh = $parser->new_tmpfile();
	};
	ok( ! $@, '->new_tmpfile() lives');
	ok( $fh->print("testing\n"), '->print on fh ok');

	ok( $fh->seek(0,0), '->seek on fh ok');
	my $line = <$fh>;
	is( $line, "testing\n", 'Read line back in OK');
}

# diag('new_tmpfile(), with temp files elsewhere');
{
	my $fh;
	eval {
		local $parser->{MP5_TmpDir} = $DIR;
		$fh = $parser->new_tmpfile();
	};
	ok( ! $@, '->new_tmpfile() lives');
	ok( $fh->print("testing\n"), '->print on fh ok');

	ok( $fh->seek(0,0), '->seek on fh ok');
	my $line = <$fh>;
	is( $line, "testing\n", 'Read line back in OK');
}

# diag('native_handle() on various things we might get');
{
	my $io_file_scalar = IO::File->new( do { my $foo = ''; \$foo }, '>:' );
	ok( MIME::Parser::Reader::native_handle( $io_file_scalar ), 'FH on scalar is OK');

	my $io_file_real   = IO::File->new_tmpfile();
	ok( MIME::Parser::Reader::native_handle( $io_file_real ), 'FH on real file is OK');

	my $globref   = \*STDOUT;
	ok( MIME::Parser::Reader::native_handle( $globref ), 'globref is OK');

}

# diag('tmp_recycling() exists again, as a no-op');
{
	my $rc = $parser->tmp_recycling(1);
	is( $rc, undef, 'tmp_recycling no-op method returned undef');
}
