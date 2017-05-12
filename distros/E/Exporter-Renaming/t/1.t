#!perl

# We use "require()" and "->import" in these tests to emulate
# "use" at run-time

# work around perl buglet: if new Exporter is used with old Carp
# Carp attributes errors wrongly

BEGIN {
    $Carp::Internal{Exporter}++;
    $Carp::Internal{'Exporter::Heavy'}++;
}

use Test::More;
my $n_tests;

### Function of Exporter::Renaming::import (and unimport)
{{ # '{{' means block isn't indented

require Exporter;
my $ex_im = \ &Exporter::import;
use_ok('Exporter::Renaming');
my $new_im = \ &Exporter::import;
ok( $ex_im != $new_im, 'Exporter::import changed');
Exporter::Renaming->import;
ok( $new_im == \ &Exporter::import, 'Exporter::import unchanged');
Exporter::Renaming->unimport; # equiv to no Exporter::Renaming
ok( $ex_im == \ &Exporter::import, 'Exporter::import reset');
Exporter::Renaming->import; # leave switched on for subsequent tests
ok( $new_im == \ &Exporter::import, 'Exporter::import changed again');

BEGIN { $n_tests += 5 }
}}

### Basic renaming (excecised with standard module File::Find)
# File::Find does secondary imports, so this is summarily tested here
# as well
{{

require File::Find;
eval { # catch import dying (first time only)
    File::Find->import( Renaming => [ find => 'search']);
};
like( $@, qr/^$/, 'import successful');
ok( \ &search == \ &File::Find::find, 'find renamed to search');
undef *search;
die unless defined &File::Find::find;

# Combine with standard import
File::Find->import( Renaming => [ find => 'search'], 'finddepth');
ok( \ &finddepth == \ &File::Find::finddepth, 'finddepth imported');
ok( \ &search == \ &File::Find::find, 'find renamed to search');
undef *search; undef *finddepth;

# multiple import
File::Find->import( Renaming => [ find => 'woohoo', find => 'weehee']);
ok( \ &woohoo == \ &File::Find::find, 'find renamed to woohoo');
ok( \ &weehee == \ &File::Find::find, 'find renamed to weehee');
undef *woohoo; undef *weehee;

# import under original name as default
File::Find->import( Renaming => [ find => undef]);
ok( \ &find == \ &File::Find::find, 'find not renamed');

# [rt.cpan.org #56367] renaming on export_to_import() too
# (2010-04-23)
# must also override export_to_level().  (used by Benchmark)
use Benchmark ();
eval { Benchmark->import(Renaming => [ timethis => 'howfast' ], 'cmpthese') };
ok(!length $@, 'export_to_level survived');
ok(\ &Benchmark::timethis == \ &howfast, "Benchmark::timethis renamed to howfast");
ok(\ &Benchmark::cmpthese == \ &cmpthese, "Benchmark::cmpthese imported");

# [rt.cpan.org #56368] modules capturing import vs "no Exporter::Renaming"
# example uses the Roman module, skip if not present

Exporter::Renaming->import; # make sure we're active
my $have_roman = eval { require Roman };
SKIP: {
    skip 'needs Roman module', 1 unless $have_roman;

    Exporter::Renaming->unimport;
    eval { Roman->import('Roman') };
    ok(!length $@, 'Roman unhurt');
    Exporter::Renaming->import; # switch back on
}

BEGIN { $n_tests += 11 }
}}

### Handling Exporter errors
{{

# normal import of non-existent symbol
my $error_line = __LINE__ + 2;
eval {
    File::Find->import( 'gibsnich');
};
like( $@, qr/line $error_line/, 'direct Exporter error message');

# renaming non-existent symbol
$error_line = __LINE__ + 2;
eval {
    File::Find->import( Renaming => [ gibsnich => 'wirdnix'] );
};
like( $@, qr/line $error_line/, 'indirect Exporter error message');

BEGIN { $n_tests += 2 }
}}

### own error handling
{{

# odd number of renaming elements
my $error_line = __LINE__ + 1; # check location once
eval { File::Find->import( Renaming => [ 'xxx', 'yyy', 'zzz']) };
like( $@, qr/line $error_line/, 'error location');
like( $@, qr/odd number/i, 'odd number');

# invalid type char
eval { File::Find->import( Renaming => [ '+xxx' => 'yyy']) };
like( $@, qr/invalid type/i, 'invalid type old');

eval { File::Find->import( Renaming => [ 'xxx' => '+yyy']) };
like( $@, qr/invalid type/i, 'invalid type new');

# different type chars
eval { File::Find->import( Renaming => [ '%xxx' => '$yyy']) };
like( $@, qr/different types/i, 'different types');

# invalid name
eval { File::Find->import( Renaming => [ 'xxx' => 'yy y']) };
like( $@, qr/invalid name/i, 'invalid name');

# multiple renamings
eval { File::Find->import( Renaming => [ 'xxx' => 'yyy', 'zzz' => 'yyy']) };
like( $@, qr/multiple renamings/i, 'multiple renamings');

BEGIN { $n_tests += 7 }
}}

### For the following tests we want a pseudo-module that exports
# all types of symbols.  We call it SampleMod.

BEGIN {
    package SampleMod;

    require Exporter;
    our @ISA = qw( Exporter);
    our @EXPORT_OK = qw( code $scalar @array %hash *glob);

    sub code { 123 }
    our $scalar = 123;
    our @array = ( 123, 456);
    our %hash = ( 123 => 456);
    sub glob { 456 }
    our $glob = 456;
    our @glob = ( 456, 789);
    our %glob = ( 456 => 789);
}

### full functional test (check all types)
{{
our ($scalar, @array, %hash, $glob, @glob, %glob);
SampleMod->import( Renaming => [
    code => 'code',
    scalar => '$scalar',
    array => '@array',
    hash => '%hash',
    glob => '*glob',
]);
is( code(), 123, 'code');
is( $scalar, 123, 'scalar');
is( "@array", '123 456', 'array');
is( $hash{ 123}, 456, 'hash');

is( $glob, 456, 'glob/scalar');
is( "@glob", '456 789', 'glob/array');
is( $glob{ 456}, 789, 'glob/hash');

BEGIN { $n_tests += 7 }
}}

### handling of type-character
{{

# dollar right
undef *scalar;
SampleMod->import( Renaming => [ 'scalar' => '$scalar']);
is( $scalar, 123, 'dollar right');

# dollar left
undef *scalar;
SampleMod->import( Renaming => [ '$scalar' => 'scalar']);
is( $scalar, 123, 'dollar left');

# two dollars
undef *scalar;
SampleMod->import( Renaming => [ '$scalar' => '$scalar']);
is( $scalar, 123, 'two dollars');

BEGIN { $n_tests += 3 }
}}

BEGIN { plan tests => $n_tests }
