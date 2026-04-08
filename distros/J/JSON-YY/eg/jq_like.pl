#!/usr/bin/env perl
# mini jq-style CLI JSON processor using JSON::YY Doc API
#
# usage:
#   echo '{"a":1}' | perl eg/jq_like.pl /a
#   echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' | perl eg/jq_like.pl /users/0/name
#   perl eg/jq_like.pl /users file.json
#   perl eg/jq_like.pl --set /key=value file.json
#   perl eg/jq_like.pl --del /key file.json
#   perl eg/jq_like.pl --type /key file.json
#   perl eg/jq_like.pl --paths file.json
#   perl eg/jq_like.pl --keys /obj file.json
#   perl eg/jq_like.pl --find /arr /name Alice file.json
use strict;
use warnings;
use JSON::YY ':doc';

my @args = @ARGV;
my $cmd = 'get';  # default

# parse flags
if (@args && $args[0] =~ /^--(\w+)/) {
    $cmd = $1;
    shift @args;
}

# read input
my $doc;
if (@args && -f $args[-1]) {
    $doc = jread pop @args;
} else {
    my $json = do { local $/; <STDIN> };
    $doc = jdoc $json;
}

if ($cmd eq 'get') {
    my $path = $args[0] // '';
    if (jis_obj $doc, $path or jis_arr $doc, $path) {
        print jpp $doc, $path;
    } else {
        print jgetp $doc, $path, "\n";
    }
}
elsif ($cmd eq 'set') {
    my $expr = $args[0] // die "usage: --set /path=value\n";
    my ($path, $val) = split /=/, $expr, 2;
    jset $doc, $path, $val;
    print jpp $doc, "";
}
elsif ($cmd eq 'del') {
    my $path = $args[0] // die "usage: --del /path\n";
    jdel $doc, $path;
    print jpp $doc, "";
}
elsif ($cmd eq 'type') {
    my $path = $args[0] // '';
    print jtype $doc, $path, "\n";
}
elsif ($cmd eq 'paths') {
    my $path = $args[0] // '';
    print "$_\n" for jpaths $doc, $path;
}
elsif ($cmd eq 'keys') {
    my $path = $args[0] // '';
    print "$_\n" for jkeys $doc, $path;
}
elsif ($cmd eq 'len') {
    my $path = $args[0] // '';
    print jlen $doc, $path, "\n";
}
elsif ($cmd eq 'find') {
    my ($arr_path, $key, $val) = @args;
    my $found = jfind $doc, $arr_path, $key, $val;
    if (defined $found) {
        print jpp $found, "";
    } else {
        print "null\n";
    }
}
else {
    die "unknown command: --$cmd\n";
}
