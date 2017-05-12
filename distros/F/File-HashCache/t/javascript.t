# Copyright © 2009-2013 David Caldwell.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;

use Test::More tests => 18;
use File::HashCache::JavaScript;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);
use Errno ();

my $dir = tempdir();
sub file_with_contents($$) {
    my $name = "$dir/$_[0]";
    write_file($name, $_[1]) or die "$name: $!";
    $name
}

my $cache_dir = 'js-test-cache';
my $jsh = File::HashCache::JavaScript->new(cache_dir => $cache_dir);

my $filea = file_with_contents("a.js", <<EOF);
var a=1;
var b=2;
var c=3;
EOF

my $hasheda = $jsh->hash($filea);
is($hasheda, 'a-e14548d326ca1e7f05661a9b3d68419b.js',                    'hashed filename');
ok(-f "$cache_dir/a-e14548d326ca1e7f05661a9b3d68419b.js",                'hashed file was written');
ok(-f "$cache_dir/cache.json",                                           'cache file was written');

my $filea1 = file_with_contents("a1.js", <<EOF);
var d=4;
var e=5;
var f=6;
EOF

my $hashedconcat = $jsh->hash($filea, $filea1);
is($hashedconcat, 'a-a1-9af38f623fcaaa6ecf3b2f859fb7321d.js',            'concatenated filename');
ok(-f "$cache_dir/a-e14548d326ca1e7f05661a9b3d68419b.js",                'concatenated file was written');


# Old, consider removing:
my $fileb = file_with_contents("b.js", <<EOF);
#include "$filea"
var d=1;
var e=2;
var f=3;
EOF

my $hashedb = $jsh->hash($fileb);
is($hashedb, 'b-20b3d0cc5dc4a21c95c15e17a3c20942.js',                    'hashed filename w/include');
ok(-f "$cache_dir/b-20b3d0cc5dc4a21c95c15e17a3c20942.js",                'hashed file w/include was written');

# Old, consider removing:
my $filec = file_with_contents("c.js", <<EOF);
#include "nonexistent file"
var d=1;
var e=2;
var f=3;
EOF

eval { $jsh->hash($filec) };
ok($! == Errno::ENOENT,                                                  'could not find include file');

sleep(1); # Weak! mtime must not be very high resolution.
write_file($filea, <<EOF);
var a=-1;
var b=-2;
var c=-3;
EOF
my $hasheda2 = $jsh->hash($filea);
my $hashedb2 = $jsh->hash($fileb);
is($hasheda2, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                    'mtime cache invalidation');
is($hashedb2, 'b-845e47b03551efc670490ab228698f49.js',                    'mtime cache invalidation on included file');

my $old_moda = -M "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js";
my $old_modb = -M "$cache_dir/b-845e47b03551efc670490ab228698f49.js";
sleep(1); # Stupid mtime again
my $jsh2 = File::HashCache::JavaScript->new(cache_dir => $cache_dir);
my $hasheda3 = $jsh2->hash($filea);
my $hashedb3 = $jsh2->hash($fileb);
is($hasheda3, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                      'used json.cache');
is($hashedb3, 'b-845e47b03551efc670490ab228698f49.js',                      'used json.cache on included file');
ok($old_moda == -M "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js",      'used json.cache to know not to rebuild minified file');
ok($old_modb == -M "$cache_dir/b-845e47b03551efc670490ab228698f49.js",      'used json.cache to know not to rebuild minified file w/include');

unlink("$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js");
my $hasheda4 = $jsh2->hash($filea);
is($hasheda4, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                      'handled unlinked cached file');
ok(-f "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js",                   'hashed file was written after unlink');

sleep 1; # More stupid mtime granularity issues
utime time, time, $filea, $fileb;
my $jsh3 = File::HashCache::JavaScript->new(cache_dir => $cache_dir, process_js => undef);
my $hasheda5 = $jsh3->hash($filea);
my $hashedc5 = $jsh3->hash($filec);
is($hasheda5, 'a-e5e2606994e336bc588e0bd7ae509d95.js',                      'non minified js');
is($hashedc5, 'c-b94c3a6f8bd54964984f8805524a406b.js',                      'non minified, non included file');
