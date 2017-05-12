use Test::Simple 'no_plan';
use lib './lib';
use LEOCHARRE::Dev::Distribution;
use strict;



my $d = LEOCHARRE::Dev::Distribution->new({ abs_path => './' });
ok $d;

ok $d->abs_path;
ok $d->abs_makefile;
ok $d->abs_manifest;
ok $d->ls_manifest;


my $v = $d->code_manifest;
ok $v;
#ok( $v, "manifest: \n\n$v\n");

$v = $d->version_from;
ok $v, "version from $v";


$v = $d->name;
ok $v, "name $v";
