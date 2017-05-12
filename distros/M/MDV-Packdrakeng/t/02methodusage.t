#!/usr/bin/perl

# $Id: 02methodusage.t 225630 2007-08-09 11:44:45Z nanardon $

use strict;
use Test::More tests => 6;
use Digest::MD5;

use_ok('MDV::Packdrakeng');

SKIP: {
    eval "use Compress::Zlib";
    skip "Compress::Zlib not availlable", 5 if($@);

use_ok('MDV::Packdrakeng::zlib');

{
my $pack = MDV::Packdrakeng->new(
    archive => "packtest-cat.cz", compress => 'gzip', uncompress => 'gzip', noargs => 1,
    extern => 0,
);
like($pack->method_info(), '/^internal/', "use internal methods");
}
unlink("packtest-cat.cz");

{
my $pack = MDV::Packdrakeng->new(
    archive => "packtest-cat.cz", compress => 'gzip', uncompress => 'gzip', noargs => 1,
    extern => 1,
);
like($pack->method_info(), '/^external/', "use external methods");
}

{
my $pack = MDV::Packdrakeng->open(archive => "packtest-cat.cz", extern => 0,);
like($pack->method_info(), '/^internal/', "use internal methods");
}

{
my $pack = MDV::Packdrakeng->open(archive => "packtest-cat.cz", extern => 1,);
like($pack->method_info(), '/^external/', "use external methods");
}

unlink("packtest-cat.cz");

} # skip
