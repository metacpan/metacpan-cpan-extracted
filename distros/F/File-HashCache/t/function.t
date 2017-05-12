# Copyright © 2009-2013 David Caldwell.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;

use Test::More tests => 17;
use File::HashCache;
use JavaScript::Minifier::XS;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);

my $dir = tempdir();
sub file_with_contents($$) {
    my $name = "$dir/$_[0]";
    write_file($name, $_[1]) or die "$name: $!";
    $name
}

my $cache_dir = 'hc-test-cache';
my $hc = File::HashCache->new(cache_dir => $cache_dir,
                              process_js => \&JavaScript::Minifier::XS::minify);

my $filex = file_with_contents("a0.xxx", <<EOF);
var a=9;
var b=8;
var c=7;
EOF

my $hasheda0 = $hc->hash($filex);
is($hasheda0, 'a0-a3c8839aef9ac1205e5373c6f24c57f1.xxx',                 'unprocessed filename');
ok(-f "$cache_dir/a0-a3c8839aef9ac1205e5373c6f24c57f1.xxx",              'unprocessed file was written');
ok(-f "$cache_dir/cache.json",                                           'cache file was written');

my $filea = file_with_contents("a.js", <<EOF);
var a=1;
var b=2;
var c=3;
EOF

my $hasheda = $hc->hash($filea);
is($hasheda, 'a-e14548d326ca1e7f05661a9b3d68419b.js',                    'hashed filename');
ok(-f "$cache_dir/a-e14548d326ca1e7f05661a9b3d68419b.js",                'hashed file was written');
ok(-f "$cache_dir/cache.json",                                           'cache file was written');

my $fileb = file_with_contents("b.js", <<EOF);
var d=4;
var e=5;
var f=6;
EOF

my $hashedconcat = $hc->hash($filea, $fileb);
is($hashedconcat, 'a-b-9af38f623fcaaa6ecf3b2f859fb7321d.js',             'concatenated filename');
ok(-f "$cache_dir/a-b-9af38f623fcaaa6ecf3b2f859fb7321d.js",              'concatenated file was written');

eval { $hc->hash($filex, $filea, $fileb); };
like($@, qr/extentions should be the same/,                              'could not concatenate different extensions');

sleep(1); # Weak! mtime must not be very high resolution.
write_file($filea, <<EOF);
var a=-1;
var b=-2;
var c=-3;
EOF
my $hasheda2 = $hc->hash($filea);
my $hashedb2 = $hc->hash($filea, $fileb);
is($hasheda2, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                   'mtime cache invalidation');
is($hashedb2, 'a-b-cc7a78b276002fdaf217e4c131a63658.js',                 'mtime cache invalidation on concated file');

my $old_moda = -M "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js";
my $old_modb = -M "$cache_dir/a-b-cc7a78b276002fdaf217e4c131a63658.js";
sleep(1); # Stupid mtime again
my $hc2 = File::HashCache->new(cache_dir => $cache_dir,
                               process_js => \&JavaScript::Minifier::XS::minify);
my $hasheda3 = $hc2->hash($filea);
my $hashedb3 = $hc2->hash($filea, $fileb);
is($hasheda3, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                      'used json.cache');
is($hashedb3, 'a-b-cc7a78b276002fdaf217e4c131a63658.js',                    'used json.cache on included file');
ok($old_moda == -M "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js",      'used json.cache to know not to rebuild minified file');
ok($old_modb == -M "$cache_dir/a-b-cc7a78b276002fdaf217e4c131a63658.js",    'used json.cache to know not to rebuild minified file w/include');

unlink("$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js");
my $hasheda4 = $hc2->hash($filea);
is($hasheda4, 'a-61dbd4778883c6e1e4d174a3e0092683.js',                      'handled unlinked cached file');
ok(-f "$cache_dir/a-61dbd4778883c6e1e4d174a3e0092683.js",                   'hashed file was written after unlink');
