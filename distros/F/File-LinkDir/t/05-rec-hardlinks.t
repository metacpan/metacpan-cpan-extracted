use strict;
use warnings;
use lib 'lib';
use Test::More tests => 37;

use Cwd qw<abs_path>;
use File::Find;

use File::LinkDir;

my $source = abs_path( 't/tests/src' );
my $dest   = abs_path( 't/tests/dest' );

my $fld = File::LinkDir->new(
    source      => $source,
    dest        => $dest,
    recursive   => 1,
    hard        => 1,
);

$fld->run();

chdir $source or die "Couldn't chdir to '$source'\n";

find( { wanted => sub { recursive( $source, $dest ) }, no_chdir => 1 }, $source );

rmdir "$dest/a";

sub recursive
{
    my ( $source, $dest ) = @_;

    my $file = $File::Find::name;
    $file =~ s{^$source/}{};

    if ( ! -d $file && ! -d "$dest/$file" )
    {
        ok( -f "$dest/$file", "$dest/$file is a file (hard link)" );
        ok( ( stat "$dest/$file" )[1] == ( stat "$source/$file" )[1], "destination and source share an inode" );
        unlink "$dest/$file";
    }
    elsif ( $file ne $source )
    {
       ok( -d "$dest/$file", "$dest/$file directory exists" );
    }
}


