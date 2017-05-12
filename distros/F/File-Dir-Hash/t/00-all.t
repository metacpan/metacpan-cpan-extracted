#!/usr/bin/perl
use File::Dir::Hash;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Digest::MD5 qw(md5_hex);

{
    note "Using pattern [1,2,2,4]";
    my $dir = tempdir(CLEANUP => 1);
    note "Created temporary directory $dir";
    
    my $h = File::Dir::Hash->new(
        pattern => [1,2,2,4],
        basedir => $dir,
        hash_func => sub { shift }
    );
    my $filename = 'ABCDEFGHIJKLMN';
    
    my $result = $h->genpath($filename, 1);
    $result = File::Spec->abs2rel($result,$dir);
    my @components = File::Spec->splitdir($result);
    #shift @components unless $components[0];
    is($components[0], 'A', "First component ($components[1]) - (one char)");
    is($components[1], 'BC', "Second component ($components[2]) - (two chars)");
    is($components[2], 'DE', "Third component ($components[3]) - (two chars)");
    is($components[3], 'FGHI', "Fourth component ($components[4]) - (four chars)");
    
    pop @components;
        
    ok(-d File::Spec->catfile($dir, @components), "Directory exists with mkdir");
    my $dest = File::Spec->catfile($dir, @components, $filename);
    
    $h->hash_func(\&md5_hex);
    $h->pattern([1,1]);
    note "using pattern [1,1]";
    $filename  = 'foobarbaz';
    my $hash = md5_hex($filename);
    
    $result = $h->genpath($filename, 0);
    $result = File::Spec->abs2rel($result, $dir);
    
    @components = File::Spec->splitdir($result);
    is($components[0], substr($hash, 0, 1), "First digit");
    is($components[1], substr($hash, 1, 1), "Second digit");
    
}


done_testing();