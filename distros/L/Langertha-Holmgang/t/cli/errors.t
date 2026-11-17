#!/usr/bin/env perl
# holmgang: a relayed error reaches stderr without the Perl location and without
# host detail beyond the path the user gave; the exit code stays 2 (k41).
# Invented suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Tiny qw( path );

use Holmgang::CLI qw( cli good_suite );

my $root = Path::Tiny->tempdir;
my $good = good_suite( id => 'err-fan', root => $root );
my $dir  = Path::Tiny->tempdir;

# exit 2, the message on stderr, the path the user gave in it, no location
sub clean_error {
  my ( $name, $argv, $says, $path ) = @_;
  my ( $code, undef, $err ) = cli(@$argv);
  is( $code, 2, $name.': exit 2' );
  like( $err, $says, '... said on stderr' );
  like( $err, qr/\Q$path\E/, '... naming the path as given' ) if defined $path;
  unlike( $err, qr/ line \d+/, '... no "line N"' );
  unlike( $err, qr{\blib/\S*\.p[ml]\b}, '... no Perl file' );
  unlike( $err, qr/\@INC (?:contains|entries checked)|<path>/, '... no module search path' );
  return $err;
}

{
  my $file = $dir->child( 'no', 'such', 'dir', 'run.json' );
  my $err = clean_error( 'an unwritable --report path',
    [ run => '--suite', $good, '--target', 'mock-solution', '--report', "$file" ],
    qr/^holmgang: report \Q$file\E not written: No such file or directory$/m, "$file" );
  unlike( $err, qr/\Q$file\E\d/, '... not the temporary file next to it' );
}

clean_error( 'a missing report file',
  [ report => "$dir/missing.json" ],
  qr{^holmgang: report \Q$dir\E/missing\.json does not read: No such file or directory$}m, "$dir/missing.json" );

clean_error( 'a directory as report file',
  [ report => "$dir" ],
  qr/^holmgang: report \Q$dir\E does not read: Is a directory$/m, "$dir" );

{
  my $bad = $dir->child('bad.json');
  $bad->spew_utf8('{nope');
  clean_error( 'a report file with invalid JSON',
    [ report => "$bad" ], qr/does not read: .*is not JSON: .*character offset 1/, "$bad" );
}

{
  my $junk = $dir->child('junk.json');
  $junk->spew_utf8('{"not":"a report"}');
  clean_error( 'a JSON file that is no report',
    [ report => "$junk" ], qr/does not read: .*is not a Holmgang report$/m, "$junk" );
  my $short = $dir->child('short.json');
  $short->spew_utf8('{"holmgang_report":1}');
  clean_error( 'a report with a missing field',
    [ report => "$short" ], qr/does not read: .*finished_at is missing$/m, "$short" );
}

{
  # the same suite with two repeat counts: the reports conflict
  my ( $one, $two ) = map { $dir->child("rep$_.json") } 1, 2;
  is( ( cli( run => '--suite', $good, '--target', 'mock-solution', '--repeat', $_->[0], '--report', "$_->[1]" ) )[0], 0,
    'setup: report with repeat '.$_->[0] ) for [ 1, $one ], [ 2, $two ];
  clean_error( 'reports that conflict',
    [ report => "$one", "$two" ], qr/^holmgang: reports do not evaluate: .*repeat 1 and 2/m );
}

clean_error( 'a --suite that is no suite directory',
  [ report => "$dir/rep1.json", '--suite', "$dir/nowhere" ], qr/not a suite directory/, "$dir/nowhere" );

clean_error( 'an engine that is not installed',
  [ run => '--suite', $good, '--target', 'NoSuchEngineAnywhere' ],
  qr/^holmgang: target NoSuchEngineAnywhere does not build: Can't locate Langertha\/Engine\/NoSuchEngineAnywhere/m );

done_testing;
