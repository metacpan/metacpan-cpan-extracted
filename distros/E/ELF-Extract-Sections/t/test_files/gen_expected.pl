#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Path::Iterator::Rule;
use YAML::XS;
use Path::Tiny qw( path );
use lib "$FindBin::Bin/../../lib";
use ELF::Extract::Sections;

my $exclude = Path::Iterator::Rule->new->name( "*.pl", "*.yaml" );
my $iter = Path::Iterator::Rule->new->file->not($exclude)->iter("$FindBin::Bin");
while ( my $file = $iter->() ) {
    my $f        = path($file);
    my $yamlfile = path( $file . ".yaml" );

    my $scanner = ELF::Extract::Sections->new( file => $f );
    my $d = {};
    for ( values %{ $scanner->sections } ) {
        $d->{ $_->name } = {
            size   => $_->size,
            offset => $_->offset,
        };
    }
    my $fh = $yamlfile->openw;
    print $fh YAML::XS::Dump($d);
}
