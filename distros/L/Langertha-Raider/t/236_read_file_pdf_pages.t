#!/usr/bin/env perl
# ABSTRACT: read_file reads PDF pages as text through pdftotext (poppler); big PDFs need a page range (ADR 0023)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Which ();

use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::FileTools::ReadState;

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->child('root');
$root->mkpath;
$root = $root->realpath;
$root->child('doc.pdf')->spew_raw("%PDF-1.4\nnot a real pdf, the stubs do not look\n");

# Stubs for pdfinfo and pdftotext in front of PATH: the page count comes from
# FAKE_PAGES, every page is the line "text of page N".
my $bin = $tmp->child('bin');
$bin->mkpath;
$bin->child('pdfinfo')->spew(<<'SH');
#!/bin/sh
[ -n "$FAKE_PAGES" ] || exit 1
echo "Title:          fake"
echo "Pages:          $FAKE_PAGES"
SH
$bin->child('pdftotext')->spew(<<'SH');
#!/bin/sh
[ -z "$FAKE_FAIL" ] || { echo "Syntax Error: Couldn't read xref table" >&2; exit 1; }
f=1; l=1
while [ $# -gt 0 ]; do
  case "$1" in -f) f=$2; shift 2;; -l) l=$2; shift 2;; *) shift;; esac
done
i=$f
while [ "$i" -le "$l" ]; do printf 'text of page %s\n\f' "$i"; i=$((i+1)); done
SH
chmod 0755, "$bin/pdfinfo", "$bin/pdftotext";
my $empty = $tmp->child('empty');
$empty->mkpath;

my $state  = Langertha::Raider::FileTools::ReadState->new;
my $sees   = 0;
my $server = build_file_tools_server( root => "$root", read_state => $state, sees_images => sub { $sees }, reads_pdf => sub { $sees } );

sub read_file {
  my ( $args ) = @_;
  my ($tool) = grep { $_->name eq 'read_file' } @{ $server->tools };
  my $r = $tool->code->( $tool, $args );
  return ( join( "\n", map { $_->{text} // '' } @{ $r->{content} } ), $r->{isError} ? 1 : 0, $r );
}
sub with_path (&;$) {
  my ( $code, $dir ) = @_;
  local $ENV{PATH} = defined $dir ? "$dir" : "$bin:$ENV{PATH}";
  return $code->();
}

my $pdf = $root->child('doc.pdf')->stringify;

subtest 'the pages parameter is part of the tool' => sub {
  my ($tool) = grep { $_->name eq 'read_file' } @{ $server->tools };
  is $tool->input_schema->{properties}{pages}{type}, 'string', 'pages: string';
  like $tool->description, qr/pages/, 'described';
};

subtest 'a page range comes back as text, also for a model that cannot see PDFs' => sub {
  local $ENV{FAKE_PAGES} = 40;
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '2-3' } ) };
  ok !$err, 'no error';
  like $text, qr/\APDF pages 2-3 of \Q$pdf\E:/, 'header names the pages';
  like $text, qr/Page 2:\ntext of page 2\n/, 'page 2';
  like $text, qr/Page 3:\ntext of page 3\n/, 'page 3';
  unlike $text, qr/page 4/, 'not page 4';
  ok $state->has_read($pdf), 'counts as read';

  ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '7' } ) };
  like $text, qr/Page 7:\ntext of page 7\n/, 'a single page';
  ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '39-' } ) };
  like $text, qr/Page 39:.*Page 40:\ntext of page 40/s, 'an open range runs to the last page';
  unlike $text, qr/page 41/, 'and stops there';
};

subtest 'bad ranges are refused with Claude Code words' => sub {
  local $ENV{FAKE_PAGES} = 40;
  for my $bad ( 'abc', '0', '5-2', '1,3', '-4' ) {
    my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => $bad } ) };
    is [ $err, $text ], [ 1, '<tool_use_error>Invalid pages parameter: "'.$bad.'". Use formats like "1-5", "3", or "10-20". Pages are 1-indexed.</tool_use_error>' ],
      'refused: '.$bad;
  }
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '1-21' } ) };
  is [ $err, $text ], [ 1, '<tool_use_error>Page range "1-21" exceeds maximum of 20 pages per request. Please use a smaller range.</tool_use_error>' ], 'over 20 pages';
  ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '1-20' } ) };
  ok !$err, '20 pages are fine';
  ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '41' } ) };
  is [ $err, $text ], [ 1, '<tool_use_error>Page 41 is beyond the end of the PDF, which has 40 pages.</tool_use_error>' ], 'past the end';
  ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '30-45' } ) };
  ok !$err, 'a range past the end is cut to the last page';
  unlike $text, qr/page 41/, 'no page 41';
};

subtest 'without pages a PDF of more than 10 pages must be read by range' => sub {
  $sees = 1;
  local $ENV{FAKE_PAGES} = 11;
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf' } ) };
  is [ $err, $text ], [ 1, '<tool_use_error>This PDF has 11 pages, which is too many to read at once. Use the pages parameter '
    .'to read specific page ranges (e.g., pages: "1-5"). Maximum 20 pages per request.</tool_use_error>' ], 'refused';
  local $ENV{FAKE_PAGES} = 10;
  my $r;
  ( $text, $err, $r ) = with_path { read_file( { path => 'doc.pdf' } ) };
  ok !$err, '10 pages are read whole';
  is $r->{content}[1]{type}, 'resource', 'as a document';
  $sees = 0;
};

subtest 'a PDF without a page count (no pdfinfo) is read as before' => sub {
  $sees = 1;
  delete local $ENV{FAKE_PAGES};
  my ( $text, $err, $r ) = with_path { read_file( { path => 'doc.pdf' } ) };
  ok !$err, 'no count, no refusal';
  is $r->{content}[1]{resource}{mimeType}, 'application/pdf', 'sent whole';
  $sees = 0;
};

subtest 'without pdftotext the pages parameter says so' => sub {
  local $ENV{FAKE_PAGES} = 5;
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '1-2' } ) } $empty;
  is $err, 1, 'an error';
  like $text, qr/\A<tool_use_error>The pages parameter needs pdftotext, which is not installed\. Install poppler-utils/,
    'names the missing program and the package';
};

subtest 'a failing pdftotext is reported with its own message' => sub {
  local $ENV{FAKE_PAGES} = 5;
  local $ENV{FAKE_FAIL}  = 1;
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '1-2' } ) };
  is [ $err, $text ], [ 1, "Failed to read the PDF pages: Syntax Error: Couldn't read xref table" ], 'stderr of the program';
};

subtest 'too much text for one read is refused' => sub {
  local $ENV{FAKE_PAGES} = 5;
  $bin->child('pdftotext')->spew("#!/bin/sh\nhead -c 120000 /dev/zero | tr '\\0' 'x'\n");
  chmod 0755, "$bin/pdftotext";
  my ( $text, $err ) = with_path { read_file( { path => 'doc.pdf', pages => '1' } ) };
  is $err, 1, 'an error';
  like $text, qr/\APDF text \(\d+ tokens\) exceeds maximum allowed tokens \(25000\)\. Use a smaller page range\.\z/, 'the token limit';
};

subtest 'with the real pdftotext' => sub {
  my $real = do { local $ENV{PATH} = $ENV{PATH}; File::Which::which('pdftotext') };
  plan skip_all => 'pdftotext (poppler-utils) is not installed' unless $real && $real !~ /\Q$bin\E/;
  my $body = "BT /F1 18 Tf 20 100 Td (Hello Raider) Tj ET";
  my @objs = (
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
    "<< /Length ".length($body)." >>\nstream\n$body\nendstream",
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
  );
  my $file = "%PDF-1.4\n";
  my @off;
  for my $i ( 0 .. $#objs ) { push @off, length $file; $file .= ( $i + 1 )." 0 obj\n$objs[$i]\nendobj\n" }
  my $xref = length $file;
  $file .= "xref\n0 6\n0000000000 65535 f \n".join( '', map { sprintf "%010d 00000 n \n", $_ } @off )
    ."trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n";
  $root->child('real.pdf')->spew_raw($file);
  local $ENV{PATH} = join ':', grep { $_ ne "$bin" } split /:/, $ENV{PATH};
  my ( $text, $err ) = read_file( { path => 'real.pdf', pages => '1' } );
  ok !$err, 'no error' or diag $text;
  like $text, qr/Hello Raider/, 'the text of the page';
};

done_testing;
