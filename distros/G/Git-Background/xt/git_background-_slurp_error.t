#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;

use File::Temp qw(:seekable);

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw(.. t lib) );

use Local::Test::TempDir qw(tempdir);

use Git::Background;

{
    my $fh   = File::Temp->new( DIR => tempdir() );
    my $mock = Test::MockModule->new('File::Temp');
    $mock->mock( 'seek', 0 );

    like( exception { Git::Background::_slurp($fh) }, qr{\A\QCannot seek\E}, '... throws an error if file cannot be seeked' );
}

{
    my $fh   = File::Temp->new( DIR => tempdir() );
    my $mock = Test::MockModule->new('File::Temp');
    $mock->mock( 'error', 1 );

    like( exception { Git::Background::_slurp($fh) }, qr{\A\QCannot read\E}, '... throws an error if file cannot be read' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
