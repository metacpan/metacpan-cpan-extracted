#!/usr/bin/env perl -w
use strict;
use warnings;
use IO::File;
use Carp       qw( croak   );
use Test::More qw( no_plan );
use File::Spec;

use MP3::M3U::Parser;

my $file = '07_scalar_xml.xml';

unlink $file if -e $file;

my $output = q{};
my $parser = MP3::M3U::Parser->new(
                -seconds => 'format'
            );
$parser->parse(
    File::Spec->catfile( qw/ t data test.m3u / )
);
$parser->export(
    -format   => 'xml',
    -toscalar => \$output
);

my $fh = IO::File->new;
$fh->open( $file, '>' ) or croak "I can not open file: $!";
print {$fh} $output or croak "I can't print to FH: $!";
$fh->close;

ok(1, 'Some test');
