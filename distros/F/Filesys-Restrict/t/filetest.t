#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use File::Temp ();

use Filesys::Restrict;

my $tempdir = File::Temp::tempdir();

my $good_dir = "$tempdir/good";

mkdir $good_dir;

{
    my $check = Filesys::Restrict::create( sub {
        my $path = $_[1];

        return $path =~ m<\A\Q$good_dir\E/>;
    } );

    my @flags = qw(r w x o R W X O e z s f d l p S b c u g k T B M A C);

    for my $flag (@flags) {

        # Perl warns if you -l $filehandle.
        if ($flag ne 'l') {
            lives_ok(
                sub { die if !eval "-$flag *STDOUT; 1" },
                "-$flag on filehandle",
            );
        }

        lives_ok(
            sub { die if !eval "-$flag '$good_dir/what'; 1" },
            "-$flag on approved path",
        );

        throws_ok(
            sub { die if !eval "-$flag '$tempdir/what'; 1" },
            'Filesys::Restrict::X::Forbidden',
            "-$flag on forbidden path",
        );
    }
}

done_testing;
