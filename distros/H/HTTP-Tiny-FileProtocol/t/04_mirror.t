#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Temp;
use File::Basename;
use File::Spec;

use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';

my $file = File::Spec->rel2abs(
    File::Spec->catfile( dirname( __FILE__ ), 'test.txt' ),
);

my $mirrored = File::Temp->new->filename;
$http->mirror('file://' . $file, $mirrored);

ok -f $mirrored;
is -s $mirrored, -s $file;

is_string slurp( $mirrored ), slurp( $file );

unlink $mirrored;

done_testing();

sub slurp {
    my ($file) = @_;

    return if !-f $file || !-r _;

    my $content;
    {
        open my $fh, '<', $file;
        local $/;
        $content = <$fh>;
        close $fh;
    }

    return $content;
}
