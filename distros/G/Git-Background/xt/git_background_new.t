#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw(.. t lib) );

use Local::Test::TempDir qw(tempdir);

use Git::Background 0.003;

note(q{new( { invalid_argument => 17 } )});
{
    like( exception { Git::Background->new( { invalid_argument => 17 } ) }, qr{\QUnknown argument: 'invalid_argument'\E}, 'new throws an exception for an invalid argument' );
}

note(q{new( { invalid_argument => 17, another_arg => 1 } )});
{
    like( exception { Git::Background->new( { invalid_argument => 17, another_arg => 1 } ) }, qr{\QUnknown arguments: 'another_arg', 'invalid_argument'\E}, 'new throws an exception for invalid arguments' );
}

note(q{new( $dir, { dir => $dir } )});
{
    my $dir = tempdir();
    like( exception { Git::Background->new( $dir, { dir => $dir } ); }, qr{\A\QCannot specify dir as positional argument and in argument hash\E}, 'throws an exception if dir is specified twice' );
}

note(q{to many/wrong arguments});
{
    my $dir = tempdir();
    like( exception { Git::Background->new( $dir, { fatal => 0, git => 'my-git' }, 'hello world' ) }, qr{\Qusage: new( [DIR], [ARGS] )\E}, 'new throws an exception with to many arguments' );
    like( exception { Git::Background->new( $dir, 'hello world' ) }, qr{\Qusage: new( [DIR], [ARGS] )\E}, 'new throws an exception with wrong argument' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
