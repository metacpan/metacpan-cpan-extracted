#!/usr/bin/env perl

# Copyright (c) 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

my $has_sha1 = eval { require Digest::SHA1; 1 };

plan tests => $has_sha1 ? 7 : 5;

use_ok('Mail::Pyzor::SHA');

if ($has_sha1) {
    my $path = `$^X -MDigest::SHA1 -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA.pm"} || q<>'`;
    is( $path, q<>, 'didn’t load Digest::SHA if Digest::SHA1 is already loaded.' );
    ok( !$?, '… and succeeded' );
}

my $path = `$^X -MDigest::SHA -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA1.pm"} || q<>'`;
is( $path, q<>, 'didn’t load Digest::SHA1 if Digest::SHA is already loaded.' );
ok( !$?, '… and succeeded' );

if ($has_sha1) {
    diag "== This install has Digest::SHA1.";

    my $path = `$^X -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA1.pm"} || q<>'`;
    like( $path, qr<SHA1>, 'loaded Digest::SHA1 if nothing is already loaded.' );
    ok( !$?, '… and succeeded' );
}
else {
    diag "== This install does not have Digest::SHA1.";

    my $path = `$^X -MMail::Pyzor::SHA -e'Mail::Pyzor::SHA::sha1(123); print \$INC{"Digest/SHA.pm"} || q<>'`;
    like( $path, qr<SHA>, 'loaded Digest::SHA if nothing is loaded and nothing else available.' );
    ok( !$?, '… and succeeded' );
}
