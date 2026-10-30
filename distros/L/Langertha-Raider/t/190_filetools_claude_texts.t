#!/usr/bin/env perl
# ABSTRACT: The file tools answer as Claude Code's Read, Write, Edit and MultiEdit do (ADR 0023)

use strict;
use warnings;
use utf8;
use Test2::V0;
use MIME::Base64 qw( decode_base64 );
use Path::Tiny;

use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::FileTools::ReadState;

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->child('root')->realpath;
$root->mkpath;
$root = $root->realpath;

my $state  = Langertha::Raider::FileTools::ReadState->new;
my $sees   = 1;
my $server = build_file_tools_server( root => "$root", read_state => $state, sees_images => sub { $sees }, reads_pdf => sub { $sees } );

sub run_tool {
  my ( $name, $args ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  die "no tool $name" unless $tool;
  my $r = $tool->code->( $tool, $args );
  return ( join( "\n", map { $_->{text} // '' } @{ $r->{content} } ), $r->{isError} ? 1 : 0, $r );
}

my $NOTE = ' (file state is current in your context — no need to Read it back)';

subtest 'write_file: created, then updated' => sub {
  my ( $text, $err ) = run_tool( write_file => { path => 'w/new.txt', content => "eins\n" } );
  is [ $text, $err ], [ 'File created successfully at: '.$root->child('w/new.txt').$NOTE, 0 ], 'a new file';
  ( $text, $err ) = run_tool( write_file => { path => 'w/new.txt', content => "zwei\n" } );
  is [ $text, $err ], [ 'The file '.$root->child('w/new.txt').' has been updated successfully.'.$NOTE, 0 ],
    'what the tool wrote counts as read: it may write again';
  is $root->child('w/new.txt')->slurp_utf8, "zwei\n", 'written';
  ( $text, $err ) = run_tool( write_file => { path => 'w', content => 'x' } );
  is [ $text, $err ], [ '<tool_use_error>'.$root->child('w').' is a directory, not a file. To create a file inside it, '
    .'include the file name in path.</tool_use_error>', 1 ], 'a directory';
};

subtest 'read before write' => sub {
  $root->child('r/old.txt')->touchpath->spew_utf8("alt\n");
  my $not_read = '<tool_use_error>File has not been read yet. Read it first before writing to it.</tool_use_error>';
  is [ ( run_tool( write_file => { path => 'r/old.txt', content => "neu\n" } ) )[0, 1] ], [ $not_read, 1 ], 'write_file';
  is [ ( run_tool( edit_file => { path => 'r/old.txt', old_string => 'alt', new_string => 'neu' } ) )[0, 1] ], [ $not_read, 1 ],
    'edit_file';
  is [ ( run_tool( multi_edit => { path => 'r/old.txt', edits => [ { old_string => 'alt', new_string => 'neu' } ] } ) )[0, 1] ],
    [ $not_read, 1 ], 'multi_edit';
  is $root->child('r/old.txt')->slurp_utf8, "alt\n", 'nothing written';

  run_tool( read_file => { path => 'r/old.txt', offset => 1, limit => 1 } );
  my ( $text, $err ) = run_tool( edit_file => { path => 'r/old.txt', old_string => 'alt', new_string => 'neu' } );
  is $err, 0, 'a read with offset and limit counts as read, as in Claude Code' or diag $text;

  ( $text, $err ) = run_tool( edit_file => { path => 'r/old.txt', old_string => 'neu', new_string => 'neuer' } );
  is $err, 0, 'the tool\'s own edit counts as read: a second edit without a new read';

  # Changed on disk behind the tools' back: another size, a later mtime.
  $root->child('r/old.txt')->spew_utf8("von außen geändert\n");
  utime time + 5, time + 5, $root->child('r/old.txt')->stringify;
  ( $text, $err ) = run_tool( edit_file => { path => 'r/old.txt', old_string => 'außen', new_string => 'innen' } );
  is [ $text, $err ], [ '<tool_use_error>File has been modified since read, either by the user or by a linter. '
    .'Read it again before attempting to write it.</tool_use_error>', 1 ], 'modified since read';
  run_tool( read_file => { path => 'r/old.txt' } );
  ( $text, $err ) = run_tool( edit_file => { path => 'r/old.txt', old_string => 'außen', new_string => 'innen' } );
  is $err, 0, 'read again: may edit';
  is $root->child('r/old.txt')->slurp_utf8, "von innen geändert\n", 'edited';

  # A whole read: touching the file without changing it is no change.
  utime time + 10, time + 10, $root->child('r/old.txt')->stringify;
  ( $text, $err ) = run_tool( edit_file => { path => 'r/old.txt', old_string => 'innen', new_string => 'oben' } );
  is $err, 0, 'only the mtime changed, the bytes did not' or diag $text;

  $state->clear;
  is [ ( run_tool( write_file => { path => 'r/old.txt', content => "x\n" } ) )[0, 1] ], [ $not_read, 1 ],
    'cleared (a new run): read again first';
};

subtest 'edit_file texts' => sub {
  $root->child('e.txt')->spew_utf8("a b a\n");
  run_tool( read_file => { path => 'e.txt' } );
  my @same = run_tool( edit_file => { path => 'e.txt', old_string => 'a', new_string => 'a' } );
  is [ @same[0, 1] ], [ '<tool_use_error>No changes to make: old_string and new_string are exactly the same.</tool_use_error>', 1 ],
    'old equals new';
  my @twice = run_tool( edit_file => { path => 'e.txt', old_string => 'a', new_string => 'x' } );
  is [ @twice[0, 1] ], [ '<tool_use_error>Found 2 matches of the string to replace, but replace_all is false. To replace all '
    ."occurrences, set replace_all to true. To replace only one occurrence, please provide more context to uniquely identify the instance.\nString: a</tool_use_error>", 1 ],
    'not unique';
  my @none = run_tool( edit_file => { path => 'e.txt', old_string => 'zz', new_string => 'x' } );
  is [ @none[0, 1] ], [ "<tool_use_error>String to replace not found in file.\nString: zz</tool_use_error>", 1 ], 'not found';
  my @all = run_tool( edit_file => { path => 'e.txt', old_string => 'a', new_string => 'x', replace_all => 1 } );
  is [ @all[0, 1] ], [ 'The file '.$root->child('e.txt').' has been updated. All occurrences were successfully replaced.'.$NOTE, 0 ],
    'replace_all';
  is $root->child('e.txt')->slurp_utf8, "x b x\n", 'every occurrence';
  my @missing = run_tool( edit_file => { path => 'nope.txt', old_string => 'a', new_string => 'b' } );
  is [ @missing[0, 1] ], [ '<tool_use_error>File does not exist. Note: your current working directory is '.$root.'.</tool_use_error>', 1 ],
    'a missing file';
  my @create = run_tool( edit_file => { path => 'made/by-edit.txt', old_string => '', new_string => "neu\n" } );
  is $create[1], 0, 'an empty old_string creates a file';
  is $root->child('made/by-edit.txt')->slurp_utf8, "neu\n", '... with new_string';
  my @exists = run_tool( edit_file => { path => 'e.txt', old_string => '', new_string => 'x' } );
  is [ @exists[0, 1] ], [ '<tool_use_error>Cannot create new file - file already exists.</tool_use_error>', 1 ],
    'not over a file with content';
};

subtest multi_edit => sub {
  $root->child('m.txt')->spew_utf8("one\ntwo\nthree\n");
  run_tool( read_file => { path => 'm.txt' } );
  my ( $text, $err ) = run_tool( multi_edit => { path => 'm.txt', edits => [
    { old_string => 'one', new_string => '1' },
    { old_string => "1\ntwo", new_string => '1+2' },      # sees the first edit
    { old_string => 'e', new_string => 'E', replace_all => 1 },
  ] } );
  is $err, 0, 'applies' or diag $text;
  is $root->child('m.txt')->slurp_utf8, "1+2\nthrEE\n", 'one after the other, on the content in memory';
  is $text, 'Applied 3 edits to '.$root->child('m.txt').":\n"
    .qq{1. Replaced "one" with "1"\n2. Replaced "1\ntwo" with "1+2"\n3. Replaced "e" with "E"}.$NOTE,
    'Claude Code\'s MultiEdit result';

  ( $text, $err ) = run_tool( multi_edit => { path => 'm.txt', edits => [
    { old_string => 'thrEE', new_string => 'drei' },
    { old_string => 'vier', new_string => '4' },
  ] } );
  is [ $text, $err ], [ "<tool_use_error>Edit 2 of 2 failed, no edit was applied: String to replace not found in file.\nString: vier</tool_use_error>", 1 ],
    'a failing edit names its number';
  is $root->child('m.txt')->slurp_utf8, "1+2\nthrEE\n", 'atomic: the first edit was not written either';

  ( $text, $err ) = run_tool( multi_edit => { path => 'm.txt', edits => [
    { old_string => 'thrEE', new_string => 'x' }, { old_string => 'x', new_string => 'thrEE' },
  ] } );
  is [ $text, $err ], [ '<tool_use_error>Original and edited file match exactly. Failed to apply edit.</tool_use_error>', 1 ],
    'edits that cancel out';
  ( $text, $err ) = run_tool( multi_edit => { path => 'm.txt', edits => [] } );
  is $err, 1, 'no edits';
  ( $text, $err ) = run_tool( multi_edit => { path => 'mm/new.txt', edits => [
    { old_string => '', new_string => "a\n" }, { old_string => 'a', new_string => 'b' },
  ] } );
  is $err, 0, 'an empty first old_string creates the file' or diag $text;
  is $root->child('mm/new.txt')->slurp_utf8, "b\n", '... and the next edits apply to it';
};

subtest 'read_file: cat -n, offset, limit' => sub {
  $root->child('n.txt')->spew_utf8( join( '', map { "line $_\n" } 1 .. 5 ) );
  my ( $text, $err ) = run_tool( read_file => { path => 'n.txt' } );
  is [ $text, $err ], [ "1\tline 1\n2\tline 2\n3\tline 3\n4\tline 4\n5\tline 5\n6\t", 0 ],
    'number, tab, line; the empty piece after the last newline too, as Claude Code shows it';
  ( $text ) = run_tool( read_file => { path => 'n.txt', offset => 2, limit => 2 } );
  is $text, "2\tline 2\n3\tline 3", 'offset is 1-based, limit counts lines';
  ( $text, $err ) = run_tool( read_file => { path => 'n.txt', offset => 9 } );
  is [ $text, $err ], [ '<system-reminder>Warning: the file exists but is shorter than the provided offset (9). '
    .'The file has 6 lines.</system-reminder>', 0 ], 'offset behind the end';
  $root->child('empty.txt')->spew('');
  is [ ( run_tool( read_file => { path => 'empty.txt' } ) )[0, 1] ],
    [ '<system-reminder>Warning: the file exists but the contents are empty.</system-reminder>', 0 ], 'empty file';

  $root->child('long.txt')->spew_utf8( join( '', map { "l$_\n" } 1 .. 2100 ) );
  ( $text ) = run_tool( read_file => { path => 'long.txt' } );
  my @lines = split /\n/, $text;
  is $lines[1999], "2000\tl2000", '2000 lines by default';
  unlike $text, qr/^2001\t/m, 'and no more';
  like $text, qr/\[Truncated: PARTIAL view — \Q$root\E\/long\.txt: showing lines 1-2000 of 2101 total\. Call read_file with offset=2001/,
    'says where the rest is';
  ( $text ) = run_tool( read_file => { path => 'long.txt', offset => 2001, limit => 200 } );
  like $text, qr/\A2001\tl2001\n/, 'the next page';
  unlike $text, qr/Truncated/, 'an explicit limit is no cut';

  $root->child('wide.txt')->spew_utf8( ( 'x' x 2500 )."\n" );
  ( $text ) = run_tool( read_file => { path => 'wide.txt' } );
  is length( ( split /\n/, $text )[0] ), length("1\t") + 2000 + length('... [truncated]'), 'a long line is cut at 2000 characters';
  like $text, qr/x\.\.\. \[truncated\]\n/, '... and says so';
};

subtest 'read_file: refusals' => sub {
  $root->child('docs/setup-guide.md')->touchpath->spew_utf8("x\n");
  my @missing = run_tool( read_file => { path => 'docs/setup-guide.txt' } );
  is [ @missing[0, 1] ], [ 'File does not exist. Note: your current working directory is '.$root.'. Did you mean '
    .$root->child('docs/setup-guide.md').'?', 1 ], 'missing, with a name that differs only in the extension';
  is [ ( run_tool( read_file => { path => 'nothing-like-it' } ) )[0, 1] ],
    [ 'File does not exist. Note: your current working directory is '.$root.'.', 1 ], 'missing';
  is [ ( run_tool( read_file => { path => 'docs' } ) )[0, 1] ],
    [ "EISDIR: illegal operation on a directory, read '".$root->child('docs')."'", 1 ], 'a directory';
  $root->child('a.zip')->spew_raw("PK\x03\x04");
  is [ ( run_tool( read_file => { path => 'a.zip' } ) )[0, 1] ], [ '<tool_use_error>This tool cannot read binary files. The file appears '
    .'to be a binary .zip file. Use a skill for this file type if one is available, or a shell command or script that can read '
    .'the format.</tool_use_error>', 1 ], 'a binary extension';
  $root->child('blob')->spew_raw("ab\0cd");
  my @blob = run_tool( read_file => { path => 'blob' } );
  is $blob[1], 1, 'NUL bytes: binary';
  like $blob[0], qr/appears to be a binary file\./, '... named without an extension';
  $root->child('big.txt')->spew( 'y' x ( 300 * 1024 ) );
  is [ ( run_tool( read_file => { path => 'big.txt' } ) )[0, 1] ], [ 'File content (300KB) exceeds maximum allowed size (256KB). '
    .'Use offset and limit parameters to read specific portions of the file, or search for specific content instead of reading '
    .'the whole file.', 1 ], 'too big to read whole';
  is ( ( run_tool( read_file => { path => 'big.txt', limit => 1 } ) )[1], 0, 'with limit it reads' );
};

subtest 'read_file: images, PDF, notebooks' => sub {
  my $png = "\x89PNG\r\n\x1a\n".( "\0" x 20 );
  $root->child('pic.png')->spew_raw($png);
  $sees = 1;
  my ( $text, $err, $r ) = run_tool( read_file => { path => 'pic.png' } );
  is $err, 0, 'an image the model can see';
  is $r->{content}[0]{type}, 'image', 'image content';
  is $r->{content}[0]{mimeType}, 'image/png', 'with its type';
  is decode_base64( $r->{content}[0]{data} ), $png, 'and its bytes';
  ok $state->has_read( "".$root->child('pic.png') ), 'counts as read';

  $root->child('doc.pdf')->spew_raw("%PDF-1.4\n%%EOF\n");
  ( $text, $err, $r ) = run_tool( read_file => { path => 'doc.pdf' } );
  is $err, 0, 'a PDF';
  like $text, qr/\APDF file read: \Q$root\E\/doc\.pdf \(15 bytes\)/, 'Claude Code\'s line first';
  is $r->{content}[1]{resource}{mimeType}, 'application/pdf', 'then the document as a resource blob';

  $sees = 0;
  ( $text, $err ) = run_tool( read_file => { path => 'pic.png' } );
  is $err, 1, 'a model that cannot see images: refused';
  like $text, qr/\A<tool_use_error>This model cannot see images: \Q$root\E\/pic\.png was not read\./, 'saying why';
  ( $text, $err ) = run_tool( read_file => { path => 'doc.pdf' } );
  like $text, qr/This model cannot see PDF files/, 'PDF as well';

  $root->child('nb.ipynb')->spew_utf8(<<'EOJ');
{ "metadata": { "language_info": { "name": "python" } },
  "cells": [
    { "id": "c1", "cell_type": "markdown", "source": [ "# Title\n", "text" ] },
    { "id": "c2", "cell_type": "code", "source": "print(1)", "outputs": [ { "output_type": "stream", "text": [ "1\n" ] } ] }
  ] }
EOJ
  ( $text, $err ) = run_tool( read_file => { path => 'nb.ipynb' } );
  is [ $text, $err ], [ qq{<cell id="c1"><cell_type>markdown</cell_type># Title\ntext</cell id="c1">\n}
    .qq{<cell id="c2">print(1)</cell id="c2">\n1\n}, 0 ], 'a notebook as its cells, with outputs';
  $root->child('bad.ipynb')->spew_utf8('{ "cells": 3 }');
  like( ( run_tool( read_file => { path => 'bad.ipynb' } ) )[0], qr/\ANotebook file is not a valid Jupyter notebook/, 'not a notebook' );
};

subtest 'list_files' => sub {
  my @missing = run_tool( list_files => { path => 'no-such-dir' } );
  is [ @missing[0, 1] ], [ 'Directory does not exist. Note: your current working directory is '.$root.'.', 1 ], 'missing';
  my @file = run_tool( list_files => { path => 'e.txt' } );
  is [ @file[0, 1] ], [ $root->child('e.txt').' is a file, not a directory. Use read_file to read it.', 1 ], 'a file';
  like( ( run_tool( list_files => { path => 'docs' } ) )[0], qr/\Asetup-guide\.md\z/, 'a directory' );
};

done_testing;
