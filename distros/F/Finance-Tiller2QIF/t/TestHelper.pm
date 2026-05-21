# package Test::Helper;

# NAME Test::Helper

# Routines for testing Tiller2QIF

use 5.034;
use feature qw/postderef signatures/;

use Test2::API qw/test2_stack/;
# use Path::Tiny;
# use Exporter 'import';


# our @EXPORT = qw(test_pass);

my $tmpdir = 't/tmp';
mkdir $tmpdir unless -d $tmpdir;

my $file_counter = 0;
sub uniqfile ( $base, $ext ) {
  $file_counter++;
  return "$tmpdir/${base}_$file_counter.$ext";
}

sub freshmap ( $mapfile, @lines ) {
  path($mapfile)->spew_utf8( join( "\n", @lines ) . "\n" );
}

sub test_pass {
    my $hub = test2_stack()->top;
    return !$hub->failed;
}

sub freshdb ($newdb) {
  unlink $newdb if -e $newdb;
  Finance::Tiller2QIF::Util::InitDB($newdb);
  Mojo::SQLite->new($newdb)->options({ sqlite_unicode => 1 })->db;
}

sub freshcsv ( $csvfile, @lines ) {
  # put header at the front
  unshift @lines,
'Date,Transaction ID,Account,Amount,Description,Full Description,Category';
  push @lines, '';
  path($csvfile)->spew_utf8( join( "\n", @lines ) );
}

1;