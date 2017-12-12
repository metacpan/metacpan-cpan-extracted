#!/usr/bin/env perl

use Test::Most;

use Path::Tiny 0.018;

use_ok 'File::Rotate::Simple';

my $dir  = Path::Tiny->tempdir;
my $base = 'test.log';
my $file = path($dir, $base);

my $r = File::Rotate::Simple->new(
    file => "$file",
    );

isa_ok $r => 'File::Rotate::Simple';

subtest 'default accessors' => sub {
    is $r->file       => $file, 'file';
    is $r->if_missing => 1, 'if_missing';
    is $r->max        => 0, 'max';
    is $r->age        => 0, 'age';
    is $r->extension_format => '.%#', 'extension_format';
    is $r->replace_extension => undef, 'replace_extension';
    is $r->touch      => 0, 'touch';
};

my $last  = $file;


subtest "rotate with if_missing true and file not touched" => sub {

    my $max = 5;

    $file->touch;

    exist( $file );

    foreach my $index (1..$max) {

        diag_exist( $r, $max );

        my $rotated = path( $file . '.' . $index );

        not_exist( $rotated );

        note "rotate";

        $r->rotate;

        diag_exist( $r, $max );

        if ($index <= 2) {

            not_exist( $last );

            $last = $rotated;

            foreach my $i (0..$max) {

                if ($i == $index) {
                    exist( $r->_rotated_name( $i ) );
                }
                else {
                    not_exist( $r->_rotated_name( $i ) );
                }

            }
            exist( $rotated );

        }
        else {

            foreach my $i (0..$max) {

                if ($i == 2) {
                    exist( $r->_rotated_name( $i ) );
                }
                else {
                    not_exist( $r->_rotated_name( $i ) );
                }

            }

        }

    }


};


sub exist {
    my $file = path( shift );
    my $desc = "${file} exists";
    if (my $comment = shift) {
        $desc .= " (${comment})";
    }
    ok $file->exists, $desc;
}

sub not_exist {
    my $file = path( shift );
    my $desc = "${file} missing";
    if (my $comment = shift) {
        $desc .= " (${comment})";
    }
    ok !$file->exists, $desc;
}

sub diag_exist {
    my $obj = shift;
    my $index = shift;

    foreach my $sindex (0..$index) {

        my $sfile = $obj->_rotated_name($sindex);
        if ($sfile->exists) {
            note "${sfile} exists";
        }

    }


}

done_testing;
