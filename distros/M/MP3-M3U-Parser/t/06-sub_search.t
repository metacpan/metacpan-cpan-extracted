#!/usr/bin/env perl -w
use strict;
use warnings;
use Carp       qw( croak   );
use Test::More qw( no_plan );
use File::Spec;

use MP3::M3U::Parser;

my $file = '06_sub_search.html';

unlink $file if -e $file;

my $parser = MyParser->new(
                -search => 'fred mer'
            );

$parser->parse(
    File::Spec->catfile( qw/ t data test.m3u / )
);

$parser->export(
    -format    => 'html',
    -file      => $file,
    -overwrite => 1,
);

ok(1, 'Some test');

package MyParser;
use base qw( MP3::M3U::Parser );

sub _search { ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self   = shift;
    my $path   = shift;
    my $id3    = shift;
    my $search = $self->{search_string};
    return 0 if ! $id3 && ! $path;
    my @search = split m{ \s+ }xms, $search;
    my %c      = (id3 => 0, path => 0);
    foreach my $s ( @search ) {
        $c{id3 }++ if $id3  =~ m{$s}xmsi;
        $c{path}++ if $path =~ m{$s}xmsi;
    }
    return 1 if $c{id3} == @search || $c{path} == @search;
    return 0;
}
