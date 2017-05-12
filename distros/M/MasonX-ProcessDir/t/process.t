#!perl
use MasonX::ProcessDir;
use Cwd qw(realpath);
use File::Basename;
use File::Copy::Recursive qw(dircopy);
use File::Find::Wanted;
use File::Path qw(remove_tree);
use File::Slurp;
use File::Temp qw(tempdir);
use Test::More;
use strict;
use warnings;

my $root_dir   = tempdir( 'template-any-processdir-XXXX', TMPDIR => 1, CLEANUP => 1 );
my $source_dir = "$root_dir/source";
my $dest_dir   = "$root_dir/dest";

sub try {
    dircopy( "t/source", $source_dir );

    my $pd = MasonX::ProcessDir->new(
        source_dir      => $source_dir,
        dest_dir        => $dest_dir,
        readme_filename => 'readme.txt',
        mason_options   => { data_dir => "$root_dir/.mason_data_dir" },
    );
    $pd->process_dir();

    is( trim( scalar( read_file("$dest_dir/two") ) ),  "TWO PLUS TWO EQUALS 4",   "two" );
    is( trim( scalar( read_file("$dest_dir/four") ) ), "FOUR PLUS FOUR EQUALS 8", "four" );
    ok( -f "$dest_dir/readme.txt",      "readme" );
    ok( -d "$root_dir/.mason_data_dir", "mason_options" );

    my @dest_files = find_wanted( sub { -f }, $dest_dir );
    is( scalar(@dest_files), 3, "3 files generated" );
}

sub trim {
    my $str = shift;
    for ($str) { s/^\s+//; s/\s+$// }
    return $str;
}

try();
done_testing();
