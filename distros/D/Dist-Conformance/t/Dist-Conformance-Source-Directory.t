#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();

use Dist::Conformance::Source::Directory();

subtest new => sub {
    like( dies { Dist::Conformance::Source::Directory->new }, qr/directory\ is\ required/, 'directory is required' );
};

subtest root => sub {
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    is( Dist::Conformance::Source::Directory->new( directory => $dir )->root->to_string, $dir, 'the directory itself' );
    like( dies { Dist::Conformance::Source::Directory->new( directory => '/bogus/standards' )->root }, qr/\/bogus\/standards\ does\ not\ exist/, 'a missing directory is named' );
};

subtest describe => sub {
    is( Dist::Conformance::Source::Directory->new( directory => '/bogus/std' )->describe,                '/bogus/std',            'the directory' );
    is( Dist::Conformance::Source::Directory->new( directory => '/bogus/std', path => 'p/q' )->describe, '/bogus/std (path p/q)', 'and the path inside it' );
};

done_testing;
