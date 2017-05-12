#!perl

use Test::More tests => 20;

use Cwd qw<abs_path>;

use File::LinkDir;

my $source = abs_path( 't/tests/src' );
my $dest   = abs_path( 't/tests/dest' );

my $fld = File::LinkDir->new(
    source => $source,
    dest   => $dest,
);

$fld->run();

opendir my $dir_handle, $source or die "Can't open the dir $source: $!; aborted";

while ( defined ( my $file = readdir $dir_handle ) )
{
    next if $file =~ /^\.{1,2}$/;

    ok( -l "$dest/$file", "$dest/$file is a symlink" );
    ok( readlink "$dest/$file" eq "$source/$file", "destination is linked to the source file" );
    unlink "$dest/$file"; # clean up after ourselves
}


