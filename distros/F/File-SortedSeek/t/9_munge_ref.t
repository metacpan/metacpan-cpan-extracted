use strict;
use Test;

BEGIN { plan tests => 2 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### test passing munge subrefs ####################

# write a test file that will need munging
open TEST, ">$file" or die "Can't write test file $!\n";
$line = 'AAAA';
for ( 0 .. 1000 ) {
    print TEST "Just|Another|Perl|Hacker|$_|$line\n";
    $line++;
}
close TEST;

open TEST, "<$file" or die "Can't open test file $!\n";

# munge the number out of the file and find that record
sub munge_num {
    my $line = shift || return undef;
  return ($line =~ m/(\d+)\|\w+$/) ? $1 : undef;
}

$tell = File::SortedSeek::numeric( *TEST, 42, \&munge_num );
chomp ( $line = <TEST> );
ok($line, 'Just|Another|Perl|Hacker|42|AABQ');

# munge a string out of the file and find that record
sub munge_string {
    my $line = shift || return undef;
  return ($line =~ m/\|(\w+)$/) ? $1 : undef;
}

$tell = File::SortedSeek::alphabetic( *TEST, 'ABBA', \&munge_string );
chomp ( $line = <TEST> );
ok( $line, 'Just|Another|Perl|Hacker|702|ABBA' );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
