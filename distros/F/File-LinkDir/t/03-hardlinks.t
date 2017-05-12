#!perl

use Test::More tests => 19;

use Cwd qw<abs_path>;

use File::LinkDir;

my $source = abs_path( 't/tests/src' );
my $dest   = abs_path( 't/tests/dest' );

my $fld = File::LinkDir->new(
    source  => $source,
    dest    => $dest,
    hard    => 1,
);

$fld->run();

opendir my $dir_handle, $source or die "Can't open the dir $source: $!; aborted";

while ( defined ( my $file = readdir $dir_handle ) )
{
    next if $file =~ /^\.{1,2}$/;
    if ( -d "$source/$file" )
    {
       ok( ! -e "$dest/$file", "$dest/$file does not exist" );
    }
    else
    {
        ok( -f "$dest/$file", "$dest/$file is a file (hard link)" );
        ok( ( stat "$dest/$file" )[1] == ( stat "$source/$file" )[1], "destination and source share an inode" );
        unlink "$dest/$file"; # clean up after ourselves
    }
}


