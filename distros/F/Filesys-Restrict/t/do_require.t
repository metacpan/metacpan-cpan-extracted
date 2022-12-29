#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

plan skip_all => 'These probably are more headache than help.';

use File::Temp ();

use Filesys::Restrict;

my $tempdir = File::Temp::tempdir();

my $good_dir = "$tempdir/good";

mkdir $good_dir;

{
    {
        open my $fh, '>', "$good_dir/perl.pl";
        syswrite $fh, 'time()';
    }

    my $check = Filesys::Restrict::create( sub {
        my $path = $_[1];

        return $path =~ m<\A\Q$good_dir\E/>;
    } );

    lives_ok(
        sub { do "$good_dir/perl.pl" },
        'do w/ approved arg',
    );

    throws_ok(
        sub { do "$tempdir/perl.pl" },
        'Filesys::Restrict::X::Forbidden',
        'do w/ forbidden arg',
    );

    lives_ok(
        sub { require "$good_dir/perl.pl" },
        'require w/ approved arg',
    );

    throws_ok(
        sub { require "$tempdir/perl.pl" },
        'Filesys::Restrict::X::Forbidden',
        'require w/ forbidden arg',
    );
}

done_testing;
