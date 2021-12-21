#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use File::Temp qw(:seekable);

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use Git::Background;

{
    my $fh = File::Temp->new( DIR => tempdir() );
    print {$fh} "hello\nworld";

    my @data = Git::Background::_slurp($fh);
    is_deeply( \@data, [ 'hello', 'world' ], '_slurp slurps' );
}

{
    my $fh = File::Temp->new( DIR => tempdir() );

    my @data = Git::Background::_slurp($fh);
    is_deeply( \@data, [], '_slurp slurps' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
